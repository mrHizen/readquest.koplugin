--[[--
Dữ liệu & hàm tiện ích cho ReadQuest (hỗ trợ đa ngôn ngữ & bản địa hóa văn hóa).
]]

local I18N = require("readquest_i18n")

local Core = {}

Core.VERSION = "2.4"
Core.BASE_EXP = 10
Core.ACH_EXP = 150
Core.BOSS_END_RATIO = 0.97
Core.MILESTONES = { 0.25, 0.5, 0.75, 0.9 }

Core.DEFAULT_CFG = {
    lang = "auto",      -- auto | vi | en | fr | ja | zh | ko
    min_secs = 10,
    max_secs = 600,
    goal = 20,
    toast = true,
    toast_detail = true,
    toast_secs = 2,
    status_bar = true,
}

-- { cấp tối thiểu, biểu tượng }
Core.TITLES = {
    { 1, "rank1" }, { 5, "rank2" }, { 10, "rank3" }, { 15, "rank4" },
    { 25, "rank5" }, { 35, "rank6" }, { 45, "rank7" }, { 55, "rank8" },
}

Core.RARITY_ICON = { common = "rar_common", rare = "rar_rare", epic = "rar_epic", legend = "rar_legend" }

function Core.today_str() return os.date("%Y-%m-%d") end
function Core.yesterday_str() return os.date("%Y-%m-%d", os.time() - 86400) end

function Core.fmtNum(n)
    local s = tostring(math.floor(n or 0))
    local out = s:reverse():gsub("(%d%d%d)", "%1."):reverse()
    return (out:gsub("^%.", ""))
end

function Core.fmtTime(secs, lang)
    secs = math.floor(secs or 0)
    local h = math.floor(secs / 3600)
    local m = math.floor((secs % 3600) / 60)
    if h > 0 then return I18N.t(lang, "time_hm", h, m) end
    return I18N.t(lang, "time_m", m)
end

function Core.fmtTimeShort(secs, lang)
    secs = math.floor(secs or 0)
    local h = math.floor(secs / 3600)
    local m = math.floor((secs % 3600) / 60)
    if h > 0 then return I18N.t(lang, "time_hm_short", h, m) end
    return I18N.t(lang, "time_m_short", m)
end

function Core.shortDate(d)
    local y, m, dd = tostring(d or ""):match("(%d+)-(%d+)-(%d+)")
    if not y then return tostring(d or "") end
    return string.format("%s/%s/%s", dd, m, y:sub(3))
end

function Core.shorten(s, max)
    s = tostring(s or "")
    local chars = {}
    for ch in s:gmatch("[\1-\127\194-\244][\128-\191]*") do chars[#chars + 1] = ch end
    if #chars <= max then return s end
    return table.concat(chars, "", 1, max - 1) .. "…"
end

function Core.hashStr(s)
    local h = 0
    for i = 1, #s do h = (h * 31 + s:byte(i)) % 1000003 end
    return h
end

function Core.bossName(title, lang)
    title = tostring(title or "?")
    local prefixes = I18N.bossPrefixList(lang)
    local prefix = prefixes[Core.hashStr(title) % #prefixes + 1]
    return prefix .. " «" .. Core.shorten(title, 34) .. "»"
end

function Core.bossVariant(title)
    return Core.hashStr(tostring(title or "?")) % 3 + 1
end

function Core.bossMinPages(total)
    return math.min(15, math.max(3, math.ceil(total * 0.05)))
end

function Core.expNeed(lv) return 300 + 50 * lv + 5 * lv * lv end

function Core.levelInfo(exp)
    local lv, rem = 1, exp
    while rem >= Core.expNeed(lv) do
        rem = rem - Core.expNeed(lv)
        lv = lv + 1
    end
    return lv, rem, Core.expNeed(lv)
end

function Core.titleIndex(lv)
    local idx = 1
    for i, t in ipairs(Core.TITLES) do
        if lv >= t[1] then idx = i end
    end
    return idx
end

function Core.titleOf(lv, lang)
    return I18N.titleName(lang, Core.titleIndex(lv))
end

function Core.titleIcon(lv)
    return Core.TITLES[Core.titleIndex(lv)][2]
end

function Core.rollLoot(ratio, lang)
    ratio = math.max(0, math.min(1, ratio or 0))
    local r = math.random()
    local legend = 0.01 + 0.04 * ratio
    local epic = legend + 0.09 + 0.10 * ratio
    local rare = epic + 0.30 + 0.10 * ratio
    local rarity = "common"
    if r < legend then rarity = "legend"
    elseif r < epic then rarity = "epic"
    elseif r < rare then rarity = "rare" end
    local pool = I18N.lootPool(lang, rarity)
    local idx = math.random(#pool)
    return { name = pool[idx], idx = idx, rarity = rarity }
end

function Core.lootDisplayName(item, lang)
    if item and item.idx and item.rarity then
        local pool = I18N.lootPool(lang, item.rarity)
        if pool[item.idx] then return pool[item.idx] end
    end
    return item and item.name or "?"
end

function Core.countRarity(st, rarity)
    local n = 0
    for _, it in ipairs(st.loot) do
        if it.rarity == rarity then n = n + 1 end
    end
    return n
end

Core.ACHIEVEMENTS = {
    { id = "first",    icon = "ach_first",    test = function(s) return s.pages >= 1 end },
    { id = "p100",     icon = "ach_p100",     test = function(s) return s.pages >= 100 end },
    { id = "p1000",    icon = "ach_p1000",    test = function(s) return s.pages >= 1000 end },
    { id = "p5000",    icon = "ach_p5000",    test = function(s) return s.pages >= 5000 end },
    { id = "boss1",    icon = "ach_boss1",    test = function(s) return s.defeated >= 1 end },
    { id = "boss5",    icon = "ach_boss5",    test = function(s) return s.defeated >= 5 end },
    { id = "boss20",   icon = "ach_boss20",   test = function(s) return s.defeated >= 20 end },
    { id = "streak3",  icon = "ach_streak3",  test = function(s) return s.best_streak >= 3 end },
    { id = "streak7",  icon = "ach_streak7",  test = function(s) return s.best_streak >= 7 end },
    { id = "streak30", icon = "ach_streak30", test = function(s) return s.best_streak >= 30 end },
    { id = "lv10",     icon = "rank3",        test = function(s) return (Core.levelInfo(s.exp)) >= 10 end },
    { id = "lv25",     icon = "rank5",        test = function(s) return (Core.levelInfo(s.exp)) >= 25 end },
    { id = "night",    icon = "ach_night",    test = function(s) return s.night_pages >= 30 end },
    { id = "dawn",     icon = "ach_dawn",     test = function(s) return s.dawn_pages >= 30 end },
    { id = "legend",   icon = "ach_legend",   test = function(s) return Core.countRarity(s, "legend") >= 1 end },
}

-- Lấy thông tin thành tựu mới nhất đã đạt được (icon, id, date)
function Core.latestAchievement(st)
    if not (st and type(st.ach) == "table") then return nil end
    -- Ưu tiên thành tựu vừa mở gần nhất theo thứ tự thời gian / danh sách
    if st.last_ach_id then
        for _, a in ipairs(Core.ACHIEVEMENTS) do
            if a.id == st.last_ach_id and st.ach[a.id] then
                return a
            end
        end
    end
    local best_a, best_date = nil, ""
    for _, a in ipairs(Core.ACHIEVEMENTS) do
        local d = st.ach[a.id]
        if d then
            if type(d) == "string" and d >= best_date then
                best_date = d
                best_a = a
            elseif not best_a then
                best_a = a
            end
        end
    end
    return best_a
end

function Core.countAch(st)
    local n = 0
    for _ in pairs(st.ach) do n = n + 1 end
    return n
end

function Core.normalize(st)
    if type(st) ~= "table" then st = {} end
    local numbers = { "exp", "pages", "seconds", "streak", "best_streak",
                      "defeated", "night_pages", "dawn_pages" }
    for _, k in ipairs(numbers) do st[k] = tonumber(st[k]) or 0 end
    st.last_goal_date = type(st.last_goal_date) == "string" and st.last_goal_date or ""
    st.last_ach_id = type(st.last_ach_id) == "string" and st.last_ach_id or nil
    if type(st.today) ~= "table" then st.today = {} end
    st.today.date = st.today.date or ""
    st.today.pages = tonumber(st.today.pages) or 0
    st.today.done = st.today.done and true or false
    if type(st.bosses) ~= "table" then st.bosses = {} end
    if type(st.loot) ~= "table" then st.loot = {} end
    if type(st.ach) ~= "table" then st.ach = {} end
    if type(st.cfg) ~= "table" then st.cfg = {} end
    for k, v in pairs(Core.DEFAULT_CFG) do
        if st.cfg[k] == nil then st.cfg[k] = v end
    end
    if (tonumber(st.cfg.ver) or 1) < 2 then
        st.cfg.toast = true
        st.cfg.ver = 2
    end
    return st
end

return Core
