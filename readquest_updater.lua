--[[--
ReadQuest updater: checks published GitHub Releases and installs a validated ZIP.
It supports semantic version tags and resolves non-semantic tags from plugin source metadata.
]]

local ConfirmBox = require("ui/widget/confirmbox")
local InfoMessage = require("ui/widget/infomessage")
local UIManager = require("ui/uimanager")
local DataStorage = require("datastorage")
local Core = require("readquest_core")
local I18N = require("readquest_i18n")

local Updater = {}
local REPO = "mrHizen/readquest.koplugin"
local API_LATEST = "https://api.github.com/repos/" .. REPO .. "/releases/latest"
local RAW_BASE = "https://raw.githubusercontent.com/" .. REPO .. "/"
local USER_AGENT = "KOReader-ReadQuest/" .. tostring(Core.VERSION)
local busy = false

local source_path = debug.getinfo(1, "S").source or ""
if source_path:sub(1, 1) == "@" then source_path = source_path:sub(2) end
local PLUGIN_DIR = source_path:match("^(.*)/[^/]+$")
if not PLUGIN_DIR or PLUGIN_DIR == "" then
    PLUGIN_DIR = DataStorage:getDataDir() .. "/plugins/readquest.koplugin"
end

local function tr(plugin, key, ...)
    local lang = plugin and plugin.lang and plugin:lang() or nil
    return I18N.t(lang, key, ...)
end

local function notify(plugin, message, timeout)
    UIManager:show(InfoMessage:new{ text = message, timeout = timeout or 4 })
end

local function parseVersion(version)
    local raw = tostring(version or ""):gsub("^v", "")
    local numeric = raw:match("^(%d[%d%.]*)")
    if not numeric then return nil end
    local parts = {}
    for token in numeric:gmatch("(%d+)") do
        parts[#parts + 1] = tonumber(token) or 0
    end
    if #parts == 0 then return nil end
    return parts
end

local function isNewer(candidate, installed)
    local a, b = parseVersion(candidate), parseVersion(installed)
    if not a or not b then return false end
    for i = 1, math.max(#a, #b) do
        local av, bv = a[i] or 0, b[i] or 0
        if av > bv then return true end
        if av < bv then return false end
    end
    return false
end

local function request(url, sink, timeout_kind)
    local http = require("socket/http")
    local socket = require("socket")
    local socketutil = require("socketutil")
    local block_timeout, total_timeout
    if timeout_kind == "file" then
        block_timeout = socketutil.FILE_BLOCK_TIMEOUT or socketutil.LARGE_BLOCK_TIMEOUT
        total_timeout = socketutil.FILE_TOTAL_TIMEOUT or socketutil.LARGE_TOTAL_TIMEOUT
    else
        block_timeout = socketutil.LARGE_BLOCK_TIMEOUT
        total_timeout = socketutil.LARGE_TOTAL_TIMEOUT
    end
    socketutil:set_timeout(block_timeout, total_timeout)
    local ok, code, headers, status = pcall(function()
        return socket.skip(1, http.request{
            url = url,
            method = "GET",
            headers = {
                ["User-Agent"] = USER_AGENT,
                ["Accept"] = "application/vnd.github+json",
                ["X-GitHub-Api-Version"] = "2022-11-28",
            },
            sink = sink,
            redirect = true,
        })
    end)
    pcall(function() socketutil:reset_timeout() end)
    if not ok then return nil, tostring(code) end
    if code ~= 200 then
        return nil, "HTTP " .. tostring(code) .. (status and (" " .. tostring(status)) or "")
    end
    return true, headers
end

local function getLatestRelease()
    local json = require("json")
    local ltn12 = require("ltn12")
    local chunks = {}
    local ok, err = request(API_LATEST, ltn12.sink.table(chunks), "small")
    if not ok then return nil, err end
    local raw = table.concat(chunks)
    local decoded, release = pcall(json.decode, raw)
    if not decoded or type(release) ~= "table" then
        return nil, "Invalid GitHub response"
    end
    if release.message then return nil, tostring(release.message) end
    return release
end

local function urlEncodeSegment(value)
    return tostring(value or ""):gsub("([^%w%-%._~])", function(ch)
        return string.format("%%%02X", string.byte(ch))
    end)
end

local function readRemoteText(url)
    local ltn12 = require("ltn12")
    local chunks = {}
    local ok, err = request(url, ltn12.sink.table(chunks), "small")
    if not ok then return nil, err end
    return table.concat(chunks)
end

local function versionFromSource(source)
    if type(source) ~= "string" then return nil end
    local version = source:match('Core%.VERSION%s*=%s*"([^"\r\n]+)"')
        or source:match("Core%.VERSION%s*=%s*'([^'\r\n]+)'")
        or source:match('version%s*=%s*"([^"\r\n]+)"')
        or source:match("version%s*=%s*'([^'\r\n]+)'")
    if version and parseVersion(version) then return version end
    return nil
end

-- Release tags are not always semantic versions (the repository's first tag was
-- simply "readquest"). Resolve the actual plugin version from the files at that
-- tag instead of rejecting an otherwise valid GitHub Release.
local function getReleaseVersion(release)
    local tag = tostring(release.tag_name or "")
    if parseVersion(tag) then return tag:gsub("^v", "") end
    if tag == "" then return nil, "Release has no tag" end

    local encoded_tag = urlEncodeSegment(tag)
    local core_url = RAW_BASE .. encoded_tag .. "/readquest_core.lua"
    local core_text = readRemoteText(core_url)
    local version = versionFromSource(core_text)
    if version then return version end

    local meta_url = RAW_BASE .. encoded_tag .. "/_meta.lua"
    local meta_text = readRemoteText(meta_url)
    version = versionFromSource(meta_text)
    if version then return version end

    -- Last resort: accept an explicit version in the Release title.
    local title = tostring(release.name or "")
    local title_version = title:match("[vV](%d[%d%.]*)")
    if title_version and parseVersion(title_version) then return title_version end
    return nil, "Cannot determine plugin version from release tag " .. tag
end

local function readPluginVersion(directory)
    local core_file = io.open(directory .. "/readquest_core.lua", "rb")
    if core_file then
        local source = core_file:read("*a")
        core_file:close()
        local version = versionFromSource(source)
        if version then return version end
    end
    local meta_file = io.open(directory .. "/_meta.lua", "rb")
    if meta_file then
        local source = meta_file:read("*a")
        meta_file:close()
        local version = versionFromSource(source)
        if version then return version end
    end
    return nil
end

local function download(url, destination)
    local ltn12 = require("ltn12")
    local file, err = io.open(destination, "wb")
    if not file then return false, err or "Cannot create download file" end
    local ok, req_err = request(url, ltn12.sink.file(file), "file")
    pcall(function() file:close() end)
    if not ok then
        pcall(os.remove, destination)
        return false, req_err
    end
    local check = io.open(destination, "rb")
    if not check then return false, "Downloaded file is missing" end
    local signature = check:read(4)
    check:close()
    if signature ~= "PK\003\004" and signature ~= "PK\005\006" and signature ~= "PK\007\008" then
        pcall(os.remove, destination)
        return false, "The downloaded file is not a ZIP archive"
    end
    return true
end

local function makeDir(path, lfs)
    local mode = lfs.attributes(path, "mode")
    if mode == "directory" then return true end
    local ok, err = lfs.mkdir(path)
    if not ok and lfs.attributes(path, "mode") ~= "directory" then
        return false, err or "Cannot create directory: " .. path
    end
    return true
end

local function removeTree(path, lfs)
    local mode = lfs.attributes(path, "mode")
    if not mode then return true end
    if mode == "directory" then
        for name in lfs.dir(path) do
            if name ~= "." and name ~= ".." then
                local ok, err = removeTree(path .. "/" .. name, lfs)
                if not ok then return false, err end
            end
        end
        local ok, err = lfs.rmdir(path)
        if not ok then return false, err or ("Cannot remove directory: " .. path) end
        return true
    end
    local ok, err = os.remove(path)
    if not ok then return false, err or ("Cannot remove file: " .. path) end
    return true
end

local ALLOWED_FILES = {
    ["_meta.lua"] = true,
    ["main.lua"] = true,
    ["readquest_core.lua"] = true,
    ["readquest_i18n.lua"] = true,
    ["readquest_icons.lua"] = true,
    ["readquest_ui.lua"] = true,
    ["readquest_updater.lua"] = true,
}

local REQUIRED_FILES = {
    "_meta.lua",
    "main.lua",
    "readquest_core.lua",
    "readquest_i18n.lua",
    "readquest_icons.lua",
    "readquest_ui.lua",
    "readquest_updater.lua",
}

local function safeRelativePath(archive_path)
    if type(archive_path) ~= "string" then return nil end
    local path = archive_path:gsub("\\", "/")
    if path:sub(1, 1) == "/" or path:find("%z") then return nil end
    local rel = path:match("^[^/]+/(.+)$") or path
    if rel == "" or rel:find("/", 1, true) or rel == "." or rel == ".." then return nil end
    if rel:find("..", 1, true) then return nil end
    if not ALLOWED_FILES[rel] then return nil end
    return rel
end

local function extractToStage(zip_path, stage_dir)
    local Archiver = require("ffi/archiver")
    if not (Archiver and Archiver.Reader) then return false, "KOReader archive reader is unavailable" end
    local arc = Archiver.Reader:new()
    if not arc:open(zip_path) then
        local err = arc.err or "Cannot open ZIP archive"
        arc:close()
        return false, err
    end

    local extracted = {}
    local extraction_error
    for entry in arc:iterate() do
        local rel = safeRelativePath(entry.path)
        if rel then
            local ok = arc:extractToPath(entry.path, stage_dir .. "/" .. rel)
            if not ok then
                extraction_error = arc.err or ("Cannot extract " .. rel)
                break
            end
            extracted[rel] = true
        end
    end
    arc:close()
    if extraction_error then return false, extraction_error end

    for _, filename in ipairs(REQUIRED_FILES) do
        if not extracted[filename] then
            return false, "ZIP is missing " .. filename
        end
        local path = stage_dir .. "/" .. filename
        local chunk, err = loadfile(path)
        if not chunk then return false, filename .. ": " .. tostring(err) end
    end
    return true
end

local function getArchiveURL(release)
    local assets = release.assets or {}
    local fallback
    for _, asset in ipairs(assets) do
        local name = tostring(asset.name or ""):lower()
        local url = asset.browser_download_url
        if url and name:match("%.zip$") then
            if name:find("readquest", 1, true) then return url end
            fallback = fallback or url
        end
    end
    return fallback or release.zipball_url
end

local function installArchive(plugin, release, zip_url)
    if busy then return end
    busy = true
    local function fail(message)
        busy = false
        notify(plugin, tr(plugin, "update_failed", tostring(message)), 6)
    end

    local ok_lfs, lfs = pcall(require, "libs/libkoreader-lfs")
    if not ok_lfs then
        fail(lfs)
        return
    end

    local cache_dir = DataStorage:getSettingsDir() .. "/readquest_update"
    local stage_dir = PLUGIN_DIR .. ".update-stage"
    local backup_dir = PLUGIN_DIR .. ".update-backup"
    local zip_path = cache_dir .. "/readquest-update.zip"

    local ok, err = makeDir(cache_dir, lfs)
    if not ok then
        fail(err)
        return
    end
    local clean_stage, clean_stage_err = removeTree(stage_dir, lfs)
    if not clean_stage then
        fail(clean_stage_err)
        return
    end
    local clean_backup, clean_backup_err = removeTree(backup_dir, lfs)
    if not clean_backup then
        fail(clean_backup_err)
        return
    end
    ok, err = makeDir(stage_dir, lfs)
    if not ok then
        fail(err)
        return
    end

    notify(plugin, tr(plugin, "update_downloading"), 2)
    UIManager:scheduleIn(0.1, function()
        local downloaded, dl_err = download(zip_url, zip_path)
        if not downloaded then
            removeTree(stage_dir, lfs)
            fail(dl_err)
            return
        end

        local extracted, extract_err = extractToStage(zip_path, stage_dir)
        pcall(os.remove, zip_path)
        if not extracted then
            removeTree(stage_dir, lfs)
            fail(extract_err)
            return
        end

        -- Validate the version inside the downloaded ZIP as well as the Release
        -- metadata. This prevents a stale/mislabelled asset from downgrading the
        -- installed plugin even when the GitHub tag itself looks newer.
        local package_version = readPluginVersion(stage_dir)
        if not package_version then
            removeTree(stage_dir, lfs)
            fail("Cannot read version from downloaded plugin ZIP")
            return
        end
        if not isNewer(package_version, Core.VERSION) then
            removeTree(stage_dir, lfs)
            fail("Downloaded ZIP version " .. package_version .. " is not newer than installed " .. tostring(Core.VERSION))
            return
        end

        -- Atomic directory swap: keep the old plugin until the staged copy is valid.
        local moved_old, move_err = os.rename(PLUGIN_DIR, backup_dir)
        if not moved_old then
            removeTree(stage_dir, lfs)
            fail(move_err or "Cannot back up current plugin")
            return
        end
        local moved_new, install_err = os.rename(stage_dir, PLUGIN_DIR)
        if not moved_new then
            local restored, restore_err = os.rename(backup_dir, PLUGIN_DIR)
            removeTree(stage_dir, lfs)
            local detail = tostring(install_err or "Cannot activate update")
            if not restored then detail = detail .. "; rollback failed: " .. tostring(restore_err) end
            fail(detail)
            return
        end

        removeTree(backup_dir, lfs)
        if plugin and plugin.state then
            plugin.state.update = {
                release_id = release.id,
                tag_name = release.tag_name,
                installed_at = os.time(),
            }
            plugin.dirty = true
            if plugin.save then pcall(plugin.save, plugin) end
        end

        busy = false
        local version = tostring(release.tag_name or release.name or "")
        UIManager:show(ConfirmBox:new{
            text = tr(plugin, "update_success", version),
            ok_text = tr(plugin, "update_restart"),
            ok_callback = function() UIManager:restartKOReader() end,
        })
    end)
end

local function gateOnConnection(plugin, retry)
    local ok, NetworkMgr = pcall(require, "ui/network/manager")
    if not ok or type(NetworkMgr.isConnected) ~= "function" then return false end
    if NetworkMgr:isConnected() then return false end
    if type(NetworkMgr.runWhenConnected) == "function" then
        NetworkMgr:runWhenConnected(function()
            if NetworkMgr:isConnected() then retry() end
        end)
        return true
    end
    return false
end

function Updater.check(plugin)
    if busy then return end
    if gateOnConnection(plugin, function() Updater.check(plugin) end) then return end
    busy = true
    notify(plugin, tr(plugin, "update_checking"), 2)
    UIManager:scheduleIn(0.1, function()
        local ok, release, err = pcall(getLatestRelease)
        busy = false
        if not ok then
            notify(plugin, tr(plugin, "update_failed", tostring(release)), 6)
            return
        end
        if not release then
            notify(plugin, tr(plugin, "update_failed", tostring(err)), 6)
            return
        end
        if release.draft or release.prerelease or type(release.tag_name) ~= "string" then
            notify(plugin, tr(plugin, "update_no_release"), 5)
            return
        end

        local version_call_ok, version, version_err = pcall(getReleaseVersion, release)
        if not version_call_ok then
            version_err = version
            version = nil
        end
        if not version or not parseVersion(version) then
            notify(plugin, tr(plugin, "update_unversioned_release", tostring(release.tag_name or "?"), tostring(version_err or "unknown")), 7)
            return
        end
        if not isNewer(version, Core.VERSION) then
            if isNewer(Core.VERSION, version) then
                notify(plugin, tr(plugin, "update_release_older", version, Core.VERSION), 7)
            else
                notify(plugin, tr(plugin, "update_current", Core.VERSION), 4)
            end
            return
        end

        local zip_url = getArchiveURL(release)
        if not zip_url then
            notify(plugin, tr(plugin, "update_failed", "Release has no ZIP download"), 5)
            return
        end
        local notes = tostring(release.body or "")
        notes = notes:gsub("\r", ""):gsub("#+%s*", ""):gsub("%*%*(.-)%*%*", "%1")
        notes = notes:gsub("`(.-)`", "%1")
        notes = notes:gsub("%s+$", "")
        if #notes > 650 then notes = notes:sub(1, 647) .. "…" end
        if notes == "" then notes = tostring(release.name or "") end
        UIManager:show(ConfirmBox:new{
            text = tr(plugin, "update_found", version, notes),
            ok_text = tr(plugin, "update_install"),
            ok_callback = function() installArchive(plugin, release, zip_url) end,
        })
    end)
end

return Updater
