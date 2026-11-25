--[[--
ReadQuest 2.4 — KOReader RPG Reading Plugin
]]

local DataStorage = require("datastorage")
local Device = require("device")
local Dispatcher = require("dispatcher")
local InfoMessage = require("ui/widget/infomessage")
local LuaSettings = require("luasettings")
local UIManager = require("ui/uimanager")
local WidgetContainer = require("ui/widget/container/widgetcontainer")

local Core = require("readquest_core")
local I18N = require("readquest_i18n")
local Icons = require("readquest_icons")
local UI = require("readquest_ui")

local SETTINGS_FILE = DataStorage:getSettingsDir() .. "/readquest.lua"

-- Đưa plugin ra trực tiếp menu "Công cụ" (tools) thay vì "Công cụ khác" (more_tools)
local function registerInToolsMenu()
    for _, modname in ipairs({ "ui/elements/reader_menu_order", "ui/elements/filemanager_menu_order" }) do
        local ok, order = pcall(require, modname)
        if ok and type(order) == "table" and type(order.tools) == "table" then
            local exists = false
            for _, k in ipairs(order.tools) do
                if k == "readquest" then exists = true break end
            end
            if not exists then
                table.insert(order.tools, "readquest")
            end
        end
    end
end

local ReadQuest = WidgetContainer:extend{
    name = "readquest",
    is_doc_only = false,
}

function ReadQuest:lang()
    return I18N.resolveLang(self.state and self.state.cfg and self.state.cfg.lang)
end

function ReadQuest:t(key, ...)
    return I18N.t(self:lang(), key, ...)
end

function ReadQuest:init()
    math.randomseed(os.time())
    self.pending = {}
    self.popq = {}
    self.dirty = false
    self.last_page, self.last_time = nil, nil
    self:load()
    self:onDispatcherRegisterActions()
    registerInToolsMenu()
    if self.ui and self.ui.menu then
        self.ui.menu:registerToMainMenu(self)
    end
    self:hookStatusBar()
end

function ReadQuest:onDispatcherRegisterActions()
    Dispatcher:registerAction("readquest_profile", {
        category = "none\", event = \"ReadQuestProfile",
        title = self:t("action_profile"), general = true,
    })
    Dispatcher:registerAction("readquest_boss", {
        category = "none\", event = \"ReadQuestBoss",
        title = self:t("action_boss"), reader = true,
    })
end

function ReadQuest:onReadQuestProfile()
    self:openHub("home")
    return true
end

function ReadQuest:onReadQuestBoss()
    self:openHub("boss")
    return true
end

function ReadQuest:addToMainMenu(menu_items)
    registerInToolsMenu()
    menu_items.readquest = {
        text_func = function()
            return self:t("app_title")
        end,
        sorting_hint = "tools",
        callback = function()
            self:openHub("home")
        end,
    }
end

-- --- lưu / nạp ---------------------------------------------------------
function ReadQuest:load()
    self.settings = LuaSettings:open(SETTINGS_FILE)
    self.state = Core.normalize(self.settings:readSetting("state"))
end

function ReadQuest:save()
    if not (self.settings and self.state) then return end
    if not self.dirty then return end
    self.settings:saveSetting("state", self.state)
    self.settings:flush()
    self.dirty = false
end

function ReadQuest:resetAll()
    local cfg = self.state.cfg
    self.state = Core.normalize({ cfg = cfg })
    self.dirty = true
    self:save()
    self:refreshStatusBar()
end

function ReadQuest:onFlushSettings() self:save() end

function ReadQuest:onSuspend()
    self:hideToast()
    self:save()
end

function ReadQuest:onResume() self.last_time = os.time() end

-- --- tích hợp thanh trạng thái (ReaderFooter) & SimpleUI / ZenOS --------
function ReadQuest:getStatusText()
    if not (self.state and self.state.cfg and self.state.cfg.status_bar) then
        return nil
    end
    local lv, rem, need = Core.levelInfo(self.state.exp)
    local pct = math.floor(rem / need * 100)
    local title = Core.titleOf(lv, self:lang())
    return string.format("Lv.%d %s (%s/%s • %d%%)", lv, title, Core.fmtNum(rem), Core.fmtNum(need), pct)
end

function ReadQuest:getShortStatusText()
    if not (self.state and self.state.cfg and self.state.cfg.status_bar) then
        return nil
    end
    local lv, rem, need = Core.levelInfo(self.state.exp)
    local pct = math.floor(rem / need * 100)
    return string.format("Lv.%d (%d%%)", lv, pct)
end

function ReadQuest:getStatusIcons()
    if not (self.state and self.state.cfg and self.state.cfg.status_bar) then
        return nil, nil
    end
    local lv = Core.levelInfo(self.state.exp)
    local rank_icon = Core.titleIcon(lv)
    local latest_ach = Core.latestAchievement(self.state)
    local ach_icon = latest_ach and latest_ach.icon or nil
    return rank_icon, ach_icon
end

function ReadQuest:getStatusText()
    if not (self.state and self.state.cfg and self.state.cfg.status_bar) then
        return nil
    end
    local lv, rem, need = Core.levelInfo(self.state.exp)
    local pct = math.floor(rem / need * 100)
    local title = Core.titleOf(lv, self:lang())
    return string.format("Lv.%d %s (%s/%s • %d%%)", lv, title, Core.fmtNum(rem), Core.fmtNum(need), pct)
end

function ReadQuest:getShortStatusText()
    if not (self.state and self.state.cfg and self.state.cfg.status_bar) then
        return nil
    end
    local lv, rem, need = Core.levelInfo(self.state.exp)
    local pct = math.floor(rem / need * 100)
    return string.format("Lv.%d (%d%%)", lv, pct)
end

function ReadQuest:getStatusIcons()
    if not (self.state and self.state.cfg and self.state.cfg.status_bar) then
        return nil, nil
    end
    local lv = Core.levelInfo(self.state.exp)
    local rank_icon = Core.titleIcon(lv)
    local latest_ach = Core.latestAchievement(self.state)
    local ach_icon = latest_ach and latest_ach.icon or nil
    return rank_icon, ach_icon
end

function ReadQuest:hookStatusBar()
    if self._footer_hooked then return end
    local footer = self.ui and self.ui.view and self.ui.view.footer
    if not footer then return end
    self._footer_hooked = true

    -- 1. Đăng ký vào additional_footer_content (nếu bản KOReader hỗ trợ)
    if type(footer.addAdditionalFooterContent) == "function" then
        pcall(function()
            footer:addAdditionalFooterContent(function()
                return self:getStatusText()
            end)
        end)
    end

    -- 2. Móc nối getStatusText của ReaderFooter để chỉ hiển thị text cấp độ & tiến độ
    if type(footer.getStatusText) == "function" then
        local orig_getStatusText = footer.getStatusText
        footer.getStatusText = function(f_self, ...)
            local res = orig_getStatusText(f_self, ...)
            local rq_txt = self:getStatusText()
            if rq_txt and rq_txt ~= "" then
                if res and res ~= "" then
                    return res .. "  |  " .. rq_txt
                end
                return rq_txt
            end
            return res
        end
    end

    -- 3. Xuất API toàn cục & sự kiện cho SimpleUI / ZenOS
    _G.ReadQuestStatus = function() return self:getStatusText() end
    _G.ReadQuestShortStatus = function() return self:getShortStatusText() end
    _G.ReadQuestIcons = function() return self:getStatusIcons() end
end
function ReadQuest:refreshStatusBar()
    local lv, rem, need = Core.levelInfo(self.state.exp)
    local pct = math.floor(rem / need * 100)
    local rank_icon, ach_icon = self:getStatusIcons()
    UIManager:broadcastEvent(require("ui/event"):new("ReadQuestUpdated", {
        level = lv,
        title = Core.titleOf(lv, self:lang()),
        exp = self.state.exp,
        rem = rem,
        need = need,
        pct = pct,
        rank_icon = rank_icon,
        latest_ach_icon = ach_icon,
        text = self:getStatusText(),
        short_text = self:getShortStatusText(),
    }))
    local footer = self.ui and self.ui.view and self.ui.view.footer
    if footer then
        if type(footer.onUpdateFooter) == "function" then
            pcall(function() footer:onUpdateFooter(true) end)
        elseif type(footer.updateFooter) == "function" then
            pcall(function() footer:updateFooter(true) end)
        end
    end
end

function ReadQuest:onReaderReady()
    self.last_page = nil
    self.last_time = os.time()
    self:hookStatusBar()
    self:refreshStatusBar()
end

function ReadQuest:onCloseDocument()
    self:hideToast()
    self.popq, self.pending = {}, {}
    if self.popup then pcall(function() self.popup:dismiss() end) end
    local ok, status = pcall(function()
        local summary = self.ui.doc_settings and self.ui.doc_settings:readSetting("summary")
        return summary and summary.status
    end)
    if ok and status == "complete" then
        local book = self:currentBook(false)
        if book and not book.defeated then
            self:withLevelCheck(function() self:checkBoss(nil, true) end)
        end
    end
    self:save()
end

-- --- mở giao diện ------------------------------------------------------
function ReadQuest:openHub(screen)
    if self.hub then return end
    self:hideToast()
    if not self.ui.document then self:load() end
    local ok, hub = pcall(function()
        return UI.Hub:new{ plugin = self, screen = screen or "home" }
    end)
    if not ok or not hub then
        UIManager:show(InfoMessage:new{ text = self:t("ui_error", tostring(hub)) })
        return
    end
    self.hub = hub
    hub.on_close = function()
        self.hub = nil
        self:save()
    end
    UIManager:show(hub, "flashui")
end

-- --- ngày & chuỗi ------------------------------------------------------
function ReadQuest:rollDay()
    local st = self.state
    local d = Core.today_str()
    if st.today.date ~= d then
        st.today = { date = d, pages = 0, done = false }
        self.dirty = true
    end
end

function ReadQuest:effectiveStreak()
    local st = self.state
    if st.last_goal_date == Core.today_str() or st.last_goal_date == Core.yesterday_str() then
        return st.streak
    end
    return 0
end

-- --- thông tin sách ----------------------------------------------------
function ReadQuest:totalPages()
    local doc = self.ui.document
    if not doc then return nil end
    local ok, n = pcall(function() return doc:getPageCount() end)
    if ok and type(n) == "number" and n > 0 then return n end
    return nil
end

function ReadQuest:curPage()
    if self.last_page then return self.last_page end
    local ui = self.ui
    if ui.paging and ui.paging.current_page then return ui.paging.current_page end
    if ui.rolling and ui.rolling.current_page then return ui.rolling.current_page end
    if ui.document then
        local ok, p = pcall(function() return ui.document:getCurrentPage() end)
        if ok and type(p) == "number" then return p end
    end
    return nil
end

function ReadQuest:bookTitle()
    local doc = self.ui.document
    local title
    local ok, props = pcall(function() return doc:getProps() end)
    if ok and type(props) == "table" then title = props.title end
    if (not title or title == "") and self.ui.doc_settings then
        local dp = self.ui.doc_settings:readSetting("doc_props")
        if type(dp) == "table" then title = dp.title end
    end
    if not title or title == "" then
        title = (doc.file or "?"):match("([^/]+)$") or "?"
        title = title:gsub("%.[^.]+$", "")
    end
    return title
end

function ReadQuest:currentBook(create)
    local doc = self.ui.document
    if not (doc and doc.file) then return nil end
    local books = self.state.bosses
    local b = books[doc.file]
    if not b and create then
        b = { title = self:bookTitle(), pages = 0, defeated = false, ms = 0, first = Core.today_str() }
        books[doc.file] = b
    end
    return b
end

function ReadQuest:bossInfo()
    if not self.ui.document then return nil end
    local total = self:totalPages() or 1
    local page = math.max(1, math.min(self:curPage() or 1, total))
    local book = self:currentBook(false)
    local title = book and book.title or self:bookTitle()
    local defeated = book and book.defeated or false
    return {
        title = title, total = total, page = page,
        credited = book and book.pages or 0,
        defeated = defeated, date = book and book.date,
        hp = defeated and 0 or math.max(0, 1 - page / total),
        need = Core.bossMinPages(total),
        variant = Core.bossVariant(title),
    }
end

-- --- thông báo nhỏ góc phải dưới (+EXP) ---------------------------------
function ReadQuest:showToast(main, detail)
    self:hideToast()
    local ok, t = pcall(function() return UI.Toast:new{ text = main, detail = detail } end)
    if not ok or not t then return end
    self._toast = t
    UIManager:show(t, "ui", t.dimen)
    local secs = tonumber(self.state.cfg.toast_secs) or 2
    self._toast_timer = function() self:hideToast() end
    UIManager:scheduleIn(secs, self._toast_timer)
end

function ReadQuest:hideToast()
    if self._toast_timer then
        UIManager:unschedule(self._toast_timer)
        self._toast_timer = nil
    end
    local t = self._toast
    if t then
        self._toast = nil
        pcall(function() UIManager:close(t, "partial", t.dimen) end)
    end
end

-- --- bảng chúc mừng ----------------------------------------------------
function ReadQuest:push(entry, front)
    if front then table.insert(self.pending, 1, entry) else table.insert(self.pending, entry) end
end

function ReadQuest:flushMessages()
    if #self.pending == 0 then return end
    for _, e in ipairs(self.pending) do table.insert(self.popq, e) end
    self.pending = {}
    UIManager:scheduleIn(0.7, function() self:nextPopup() end)
end

function ReadQuest:nextPopup()
    if self.popup or #self.popq == 0 then return end
    local e = table.remove(self.popq, 1)
    local ok, p = pcall(function() return UI.Popup:new{ entry = e, lang = self:lang() } end)
    if not ok or not p then
        UIManager:show(InfoMessage:new{
            text = tostring(e.title) .. "\n" .. tostring(e.sub or "") .. "\n" .. tostring(e.note or ""),
            timeout = 5,
        })
        UIManager:scheduleIn(0.5, function() self:nextPopup() end)
        return
    end
    self.popup = p
    p.on_close = function()
        self.popup = nil
        UIManager:scheduleIn(0.4, function() self:nextPopup() end)
    end
    p.timer = function() p:dismiss() end
    UIManager:show(p, "ui", p.dimen)
    UIManager:scheduleIn(e.timeout or 7, p.timer)
end

function ReadQuest:withLevelCheck(fn)
    local st = self.state
    local lang = self:lang()
    local lv0 = Core.levelInfo(st.exp)
    fn()
    self:checkAchievements()
    local lv1 = Core.levelInfo(st.exp)
    if lv1 > lv0 then
        local promoted = Core.titleIndex(lv1) ~= Core.titleIndex(lv0)
        self:push({
            icon = Core.titleIcon(lv1),
            title = self:t("pop_levelup", lv1),
            sub = Core.titleOf(lv1, lang),
            note = promoted and self:t("pop_promoted") or nil,
        }, true)
    end
    self.dirty = true
    self:refreshStatusBar()
    if #self.pending > 0 then
        self:save()
        self:flushMessages()
    end
end

function ReadQuest:checkAchievements()
    local st = self.state
    local lang = self:lang()
    for _ = 1, 4 do
        local changed = false
        for _, a in ipairs(Core.ACHIEVEMENTS) do
            if not st.ach[a.id] and a.test(st) then
                st.ach[a.id] = Core.today_str()
                st.last_ach_id = a.id
                st.exp = st.exp + Core.ACH_EXP
                local aname, adesc = I18N.achInfo(lang, a.id)
                self:push({
                    icon = a.icon, title = self:t("pop_ach"), sub = aname,
                    note = string.format("%s\n+%d EXP", adesc, Core.ACH_EXP),
                })
                changed = true
            end
        end
        if not changed then break end
    end
end

-- --- cốt lõi: tính EXP cho mỗi trang -----------------------------------
function ReadQuest:onPageUpdate(pageno)
    if not (self.ui.document and type(pageno) == "number") then return end
    local now = os.time()
    local last_page, last_time = self.last_page, self.last_time
    self.last_page, self.last_time = pageno, now

    if last_page and last_time then
        local dt = now - last_time
        local step = pageno - last_page
        local cfg = self.state.cfg
        if step >= 1 and step <= 2 and dt >= cfg.min_secs and dt <= cfg.max_secs then
            self:creditPage(dt, pageno)
        end
    end
    self:maybeDefeatBoss(pageno)
end

function ReadQuest:creditPage(dt, pageno)
    local st = self.state
    local lang = self:lang()
    self:rollDay()
    local gain, milestone
    self:withLevelCheck(function()
        local streak = self:effectiveStreak()
        gain = math.floor(Core.BASE_EXP * (1 + 0.05 * math.min(streak, 10)) + 0.5)
        st.exp = st.exp + gain
        st.pages = st.pages + 1
        st.seconds = st.seconds + dt
        st.today.pages = st.today.pages + 1

        local hour = tonumber(os.date("%H")) or 12
        if hour < 5 then
            st.night_pages = st.night_pages + 1
        elseif hour < 7 then
            st.dawn_pages = st.dawn_pages + 1
        end

        local book = self:currentBook(true)
        if book then
            book.pages = book.pages + 1
            milestone = self:bossMilestone(book, pageno)
        end

        if not st.today.done and st.today.pages >= st.cfg.goal then
            self:completeDaily()
        end
    end)

    if st.cfg.toast and gain then
        local lv, rem, need = Core.levelInfo(st.exp)
        local detail
        if st.cfg.toast_detail then
            detail = self:t("toast_detail_fmt", lv, math.floor(rem / need * 100))
        end
        if milestone then
            detail = (detail and (detail .. "  •  ") or "") .. milestone
        end
        self:showToast("+" .. gain .. " EXP", detail)
    end
    if st.pages % 10 == 0 then self:save() end
end

function ReadQuest:completeDaily()
    local st = self.state
    local d, y = Core.today_str(), Core.yesterday_str()
    st.today.done = true
    if st.last_goal_date == y then
        st.streak = st.streak + 1
    elseif st.last_goal_date ~= d then
        st.streak = 1
    end
    st.last_goal_date = d
    st.best_streak = math.max(st.best_streak, st.streak)
    local bonus = 100 + 10 * math.min(st.streak, 30)
    st.exp = st.exp + bonus
    self:push({
        icon = "flame", title = self:t("pop_daily"),
        sub = self:t("streak_fmt", st.streak),
        note = self:t("pop_daily_note", st.today.pages, bonus),
    })
end

-- --- boss --------------------------------------------------------------
function ReadQuest:bossMilestone(book, pageno)
    if book.defeated then return nil end
    local total = self:totalPages()
    if not total then return nil end
    local pct = pageno / total
    local hit
    for _, m in ipairs(Core.MILESTONES) do
        if pct >= m and (book.ms or 0) < m then hit = m end
    end
    if hit then
        book.ms = hit
        return self:t("boss_hp_toast", math.floor((1 - hit) * 100 + 0.5))
    end
    return nil
end

function ReadQuest:maybeDefeatBoss(pageno)
    local book = self:currentBook(false)
    if not book or book.defeated then return end
    local total = self:totalPages()
    if not total then return end
    if pageno / total >= Core.BOSS_END_RATIO and book.pages >= Core.bossMinPages(total) then
        self:withLevelCheck(function() self:checkBoss(pageno, false) end)
    end
end

function ReadQuest:checkBoss(pageno, force)
    local book = self:currentBook(false)
    if not book or book.defeated then return false end
    local total = self:totalPages() or 1
    if book.pages < Core.bossMinPages(total) then return false end
    if not force then
        if not pageno or pageno / total < Core.BOSS_END_RATIO then return false end
    end

    local st = self.state
    local lang = self:lang()
    book.defeated = true
    book.date = Core.today_str()
    st.defeated = st.defeated + 1

    local bonus = 200 + book.pages * 5
    st.exp = st.exp + bonus
    local item = Core.rollLoot(book.pages / total, lang)
    item.from = book.title
    item.date = Core.today_str()
    table.insert(st.loot, item)

    self:push({
        icon = "monster" .. Core.bossVariant(book.title),
        icon2 = Core.RARITY_ICON[item.rarity],
        title = self:t("pop_boss"),
        sub = Core.bossName(book.title, lang),
        note = self:t("pop_boss_note", bonus, I18N.rarityLabel(lang, item.rarity), item.name),
    })
    return true
end

return ReadQuest
