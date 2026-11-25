--[[--
Dữ liệu & hàm tiện ích cho ReadQuest (hỗ trợ đa ngôn ngữ & bản địa hóa văn hóa).
]]

local I18N = require("readquest_i18n")

local Core = {}

Core.VERSION = "2.5.2"
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
    session_summary = true,
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

local function newPeriodBucket()
    return {
        pages = 0,
        seconds = 0,
        exp = 0,
        hours = {},
        books = {},
    }
end

local function normalizeBucket(b)
    if type(b) ~= "table" then b = {} end
    b.pages = tonumber(b.pages) or 0
    b.seconds = tonumber(b.seconds) or 0
    b.exp = tonumber(b.exp) or 0
    if type(b.hours) ~= "table" then b.hours = {} end
    for h = 0, 23 do b.hours[h] = tonumber(b.hours[h]) or 0 end
    if type(b.books) ~= "table" then b.books = {} end
    for k, v in pairs(b.books) do
        if type(v) == "table" then
            b.books[k] = {
                title = tostring(v.title or k),
                pages = tonumber(v.pages) or 0,
                seconds = tonumber(v.seconds) or 0,
                exp = tonumber(v.exp) or 0,
                hours = type(v.hours) == "table" and v.hours or {},
            }
            for h = 0, 23 do
                b.books[k].hours[h] = tonumber(b.books[k].hours[h]) or 0
            end
        else
            b.books[k] = {
                title = tostring(k),
                pages = tonumber(v) or 0,
                seconds = 0,
                exp = 0,
                hours = {},
            }
        end
    end
    return b
end

function Core.recordHistory(st, opts)
    opts = opts or {}
    local ym = os.date("%Y-%m")
    local yr = os.date("%Y")
    local hr = tonumber(os.date("%H")) or 12
    st.months = st.months or {}
    st.years = st.years or {}
    st.months[ym] = normalizeBucket(st.months[ym])
    st.years[yr] = normalizeBucket(st.years[yr])

    local pages = tonumber(opts.pages) or 0
    local secs = tonumber(opts.seconds) or 0
    local exp = tonumber(opts.exp) or 0
    local bkey = opts.book_key
    local btitle = opts.book_title

    for _, bucket in ipairs({ st.months[ym], st.years[yr] }) do
        bucket.pages = bucket.pages + pages
        bucket.seconds = bucket.seconds + secs
        bucket.exp = bucket.exp + exp
        if pages > 0 or secs > 0 then
            bucket.hours[hr] = (bucket.hours[hr] or 0) + math.max(1, pages)
        end
        if bkey and (pages > 0 or secs > 0 or exp > 0) then
            local bk = bucket.books[bkey] or {
                title = btitle or bkey, pages = 0, seconds = 0, exp = 0, hours = {},
            }
            bk.title = btitle or bk.title
            bk.pages = (tonumber(bk.pages) or 0) + pages
            bk.seconds = (tonumber(bk.seconds) or 0) + secs
            bk.exp = (tonumber(bk.exp) or 0) + exp
            bk.hours = bk.hours or {}
            if pages > 0 or secs > 0 then
                bk.hours[hr] = (tonumber(bk.hours[hr]) or 0) + math.max(1, pages)
            end
            bucket.books[bkey] = bk
        end
    end
end

function Core.formatSlotRange(hr)
    hr = tonumber(hr)
    if not hr then return "--" end
    local h1 = hr % 24
    local h2 = (hr + 1) % 24
    return string.format("%02d:00–%02d:00", h1, h2)
end

function Core.computeRecap(st, mode, key)
    mode = (mode == "year") and "year" or "month"
    local now_ym = os.date("%Y-%m")
    local now_yr = os.date("%Y")
    local target_key = key or (mode == "year" and now_yr or now_ym)

    local bucket
    if mode == "year" then
        bucket = st.years and st.years[target_key]
    else
        bucket = st.months and st.months[target_key]
    end

    local top_book, top_pages = nil, 0
    local best_hour, best_hour_score = nil, 0
    local total_pages, total_seconds, total_exp = 0, 0, 0
    local books = {}

    if type(bucket) == "table" then
        total_pages = tonumber(bucket.pages) or 0
        total_seconds = tonumber(bucket.seconds) or 0
        total_exp = tonumber(bucket.exp) or 0
        if type(bucket.books) == "table" then
            for key_id, bk in pairs(bucket.books) do
                local p = tonumber(bk.pages) or 0
                local secs = tonumber(bk.seconds) or 0
                local exp = tonumber(bk.exp) or 0
                local title = tostring(bk.title or key_id)
                local book_hours = bk.hours or {}
                local book_best_hour, book_best_score = nil, 0
                for h = 0, 23 do
                    local score = tonumber(book_hours[h]) or 0
                    if score > book_best_score then
                        book_best_hour, book_best_score = h, score
                    end
                end
                local boss = st.bosses and st.bosses[key_id] or nil
                books[#books + 1] = {
                    key = key_id,
                    title = title,
                    pages = p,
                    seconds = secs,
                    exp = exp,
                    best_hour = book_best_hour,
                    best_slot = book_best_hour ~= nil and Core.formatSlotRange(book_best_hour) or nil,
                    defeated = boss and boss.defeated and true or false,
                    defeated_date = boss and boss.date or nil,
                    lifetime_pages = boss and (tonumber(boss.pages) or 0) or p,
                }
                if p > top_pages then
                    top_pages, top_book = p, title
                end
            end
        end
        if type(bucket.hours) == "table" then
            for h = 0, 23 do
                local score = tonumber(bucket.hours[h]) or 0
                if score > best_hour_score then
                    best_hour_score, best_hour = score, h
                end
            end
        end
    end

    -- Older saves may predate the per-book period history. Do not invent time
    -- data, but keep their tracked titles visible in the current-period recap.
    if total_pages == 0 and total_seconds == 0
        and target_key == (mode == "year" and now_yr or now_ym)
        and #books == 0 and type(st.bosses) == "table" then
        for key_id, boss in pairs(st.bosses) do
            local p = tonumber(boss.pages) or 0
            if p > 0 or boss.defeated then
                books[#books + 1] = {
                    key = key_id,
                    title = tostring(boss.title or key_id),
                    pages = p,
                    seconds = 0,
                    exp = 0,
                    best_hour = nil,
                    best_slot = nil,
                    defeated = boss.defeated and true or false,
                    defeated_date = boss.date,
                    lifetime_pages = p,
                }
                if p > top_pages then top_pages, top_book = p, tostring(boss.title or key_id) end
            end
        end
        if #books > 0 then
            total_pages = tonumber(st.pages) or 0
            total_seconds = tonumber(st.seconds) or 0
            total_exp = tonumber(st.exp) or 0
        end
    end

    table.sort(books, function(a, b)
        if a.pages ~= b.pages then return a.pages > b.pages end
        if a.seconds ~= b.seconds then return a.seconds > b.seconds end
        return tostring(a.title):lower() < tostring(b.title):lower()
    end)

    local prefix = mode == "year" and tostring(target_key) or tostring(target_key)
    local achievement_count, defeated_count = 0, 0
    for _, date in pairs(st.ach or {}) do
        if type(date) == "string" and date:sub(1, #prefix) == prefix then
            achievement_count = achievement_count + 1
        end
    end
    for _, boss in pairs(st.bosses or {}) do
        local date = boss and boss.date
        if boss and boss.defeated and type(date) == "string" and date:sub(1, #prefix) == prefix then
            defeated_count = defeated_count + 1
        end
    end

    local best_streak = tonumber(st.best_streak) or tonumber(st.streak) or 0
    return {
        mode = mode,
        period = target_key,
        top_book = top_book,
        top_book_pages = top_pages,
        books = books,
        book_count = #books,
        achievement_count = achievement_count,
        defeated_count = defeated_count,
        total_seconds = total_seconds,
        total_hours = total_seconds / 3600,
        total_pages = total_pages,
        total_exp = total_exp,
        best_hour = best_hour,
        best_slot = best_hour ~= nil and Core.formatSlotRange(best_hour) or nil,
        best_streak = best_streak,
    }
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
    if type(st.months) ~= "table" then st.months = {} end
    for k, v in pairs(st.months) do st.months[k] = normalizeBucket(v) end
    if type(st.years) ~= "table" then st.years = {} end
    for k, v in pairs(st.years) do st.years[k] = normalizeBucket(v) end
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
