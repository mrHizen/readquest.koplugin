--[[--
Giao diện đa ngôn ngữ cho ReadQuest: tự vẽ toàn bộ bằng Blitbuffer.
]]

local Device = require("device")
local Font = require("ui/font")
local Geom = require("ui/geometry")
local GestureRange = require("ui/gesturerange")
local InfoMessage = require("ui/widget/infomessage")
local InputContainer = require("ui/widget/container/inputcontainer")
local TextBoxWidget = require("ui/widget/textboxwidget")
local TextWidget = require("ui/widget/textwidget")
local UIManager = require("ui/uimanager")
local WidgetContainer = require("ui/widget/container/widgetcontainer")

local Core = require("readquest_core")
local I18N = require("readquest_i18n")
local Icons = require("readquest_icons")

local COL = Icons.COL
local Screen = Device.screen
local floor, max, min = math.floor, math.max, math.min

local function dp(n) return Screen:scaleBySize(n) end
local function clamp(v, a, b) return max(a, min(b, v)) end

local function paint(bb, x, y, w, h, col)
    if w > 0 and h > 0 then bb:paintRect(x, y, w, h, col) end
end

local function fillRound(bb, x, y, w, h, r, col)
    if w <= 0 or h <= 0 then return end
    r = max(0, min(r, floor(min(w, h) / 2)))
    if r == 0 then
        paint(bb, x, y, w, h, col)
        return
    end
    for i = 0, r - 1 do
        local dy = r - i - 0.5
        local inset = r - floor(math.sqrt(r * r - dy * dy) + 0.5)
        paint(bb, x + inset, y + i, w - 2 * inset, 1, col)
        paint(bb, x + inset, y + h - 1 - i, w - 2 * inset, 1, col)
    end
    paint(bb, x, y + r, w, h - 2 * r, col)
end

local function fillCircle(bb, cx, cy, r, col)
    for dy = -r, r do
        local dx = floor(math.sqrt(r * r - dy * dy) + 0.5)
        paint(bb, cx - dx, cy + dy, 2 * dx + 1, 1, col)
    end
end

local function drawItem(bb, it)
    local t = it.t
    if t == "rect" then
        paint(bb, it.x, it.y, it.w, it.h, COL[it.c])
    elseif t == "round" then
        fillRound(bb, it.x, it.y, it.w, it.h, it.r, COL[it.c])
    elseif t == "frame" then
        fillRound(bb, it.x, it.y, it.w, it.h, it.r, COL[it.c])
        fillRound(bb, it.x + it.th, it.y + it.th, it.w - 2 * it.th, it.h - 2 * it.th,
                  max(0, it.r - it.th), COL[it.fill])
    elseif t == "circle" then
        fillCircle(bb, it.x, it.y, it.r, COL[it.c])
    elseif t == "text" then
        it.tw:paintTo(bb, it.x, it.y)
    elseif t == "icon" then
        Icons.draw(bb, it.name, it.x, it.y, it.size, it.mono)
    end
end

-- ---------------------------------------------------------------------
-- Canvas
-- ---------------------------------------------------------------------
local Canvas = InputContainer:extend{ modal = true }

function Canvas:freeScene()
    for _, it in ipairs(self.items or {}) do
        if it.tw and it.tw.free then pcall(it.tw.free, it.tw) end
    end
end

function Canvas:resetScene()
    self:freeScene()
    self.items = {}
    self.hits = {}
end

function Canvas:add(it) self.items[#self.items + 1] = it end

function Canvas:fill(x, y, w, h, c)
    self:add{ t = "rect", x = floor(x), y = floor(y), w = floor(w), h = floor(h), c = c or "k" }
end

function Canvas:round(x, y, w, h, r, c)
    self:add{ t = "round", x = floor(x), y = floor(y), w = floor(w), h = floor(h), r = floor(r), c = c or "k" }
end

function Canvas:frame(x, y, w, h, r, th, fill, c)
    self:add{ t = "frame", x = floor(x), y = floor(y), w = floor(w), h = floor(h), r = floor(r),
              th = th or 2, fill = fill or "w", c = c or "k" }
end

function Canvas:circle(cx, cy, r, c)
    self:add{ t = "circle", x = floor(cx), y = floor(cy), r = floor(r), c = c or "k" }
end

function Canvas:icon(x, y, size, name, mono)
    self:add{ t = "icon", x = floor(x), y = floor(y), size = floor(size), name = name, mono = mono }
end

function Canvas:hit(x, y, w, h, fn)
    self.hits[#self.hits + 1] = { x = floor(x), y = floor(y), w = floor(w), h = floor(h), fn = fn }
end

function Canvas:text(x, y, str, size, o)
    o = o or {}
    local tw = TextWidget:new{
        text = tostring(str or ""),
        face = Font:getFace(o.bold and "tfont" or "cfont", size),
        fgcolor = COL[o.c or "k"],
        max_width = o.maxw,
    }
    local sz = tw:getSize()
    local w, h = sz.w, sz.h
    local px, py = x, y
    if o.boxw then
        if o.align == "center" then px = x + (o.boxw - w) / 2
        elseif o.align == "right" then px = x + o.boxw - w end
    end
    if o.boxh then py = y + (o.boxh - h) / 2 end
    self:add{ t = "text", tw = tw, x = floor(px), y = floor(py) }
    return w, h
end

function Canvas:para(x, y, w, str, size, o)
    o = o or {}
    local tb = TextBoxWidget:new{
        text = tostring(str or ""),
        face = Font:getFace(o.bold and "tfont" or "cfont", size),
        width = floor(w),
        alignment = o.align or "left",
        fgcolor = COL[o.c or "k"],
    }
    local h = tb:getSize().h
    self:add{ t = "text", tw = tb, x = floor(x), y = floor(y) }
    return h
end

function Canvas.measurePara(str, size, w, bold)
    local tb = TextBoxWidget:new{
        text = tostring(str or ""),
        face = Font:getFace(bold and "tfont" or "cfont", size),
        width = floor(w),
    }
    local h = tb:getSize().h
    if tb.free then pcall(tb.free, tb) end
    return h
end

function Canvas:bar(x, y, w, h, frac)
    frac = clamp(frac or 0, 0, 1)
    local th = max(2, dp(1))
    self:frame(x, y, w, h, floor(h / 2), th, "w", "k")
    local g = th + 2
    local ix, iy, iw, ih = x + g, y + g, w - 2 * g, h - 2 * g
    local fw = floor(iw * frac)
    if fw > 0 and ih > 0 then
        self:round(ix, iy, fw, ih, floor(ih / 2), "k")
    end
end

function Canvas:button(x, y, w, h, label, fn, o)
    o = o or {}
    local style = o.style or "outline"
    local r = o.r or dp(12)
    local fg = "k"
    if style == "solid" then
        self:round(x, y, w, h, r, "k")
        fg = "w"
    elseif style == "disabled" then
        self:frame(x, y, w, h, r, 2, "w", "m")
        fg = "m"
    else
        self:frame(x, y, w, h, r, 2, "w", "k")
    end
    self:text(x + dp(6), y, label, o.size or 18,
        { bold = o.bold, c = fg, align = "center", boxw = w - dp(12), boxh = h, maxw = w - dp(12) })
    if fn and style ~= "disabled" then self:hit(x, y, w, h, fn) end
end

function Canvas:paintTo(bb)
    for _, it in ipairs(self.items or {}) do
        local ok, err = pcall(drawItem, bb, it)
        if not ok then self.paint_err = tostring(err) end
    end
end

function Canvas:onTapScreen(arg, ges)
    local p = ges and ges.pos
    if p then
        for i = #self.hits, 1, -1 do
            local h = self.hits[i]
            if p.x >= h.x and p.x < h.x + h.w and p.y >= h.y and p.y < h.y + h.h then
                local ok, err = pcall(h.fn)
                if not ok then
                    UIManager:show(InfoMessage:new{ text = "Error: " .. tostring(err) })
                end
                return true
            end
        end
    end
    return self:onTapEmpty(p)
end

function Canvas:onTapEmpty() return true end

function Canvas:onCloseWidget()
    self:freeScene()
    self.items = {}
end

-- ---------------------------------------------------------------------
-- Hub
-- ---------------------------------------------------------------------
local Hub = Canvas:extend{ screen = "home", page = 1, inv_tab = 1 }

function Hub:t(key, ...)
    return self.plugin:t(key, ...)
end

function Hub:lang()
    return self.plugin:lang()
end

function Hub:init()
    self.W, self.H = Screen:getWidth(), Screen:getHeight()
    self.M = dp(14)
    self.dimen = Geom:new{ x = 0, y = 0, w = self.W, h = self.H }
    local full = Geom:new{ x = 0, y = 0, w = self.W, h = self.H }
    self.ges_events = {
        TapScreen = { GestureRange:new{ ges = "tap", range = full } },
        SwipeScreen = { GestureRange:new{ ges = "swipe", range = full } },
    }
    if Device:hasKeys() then
        self.key_events = { Back = { { Device.input.group.Back } } }
    end
    self.items, self.hits = {}, {}
    self:rebuild()
end

function Hub:rebuild()
    self:resetScene()
    self:fill(0, 0, self.W, self.H, "w")
    local builder = self["build_" .. tostring(self.screen)] or self.build_home
    local ok, err = pcall(builder, self)
    if not ok then
        self:resetScene()
        self:fill(0, 0, self.W, self.H, "w")
        self:para(self.M, self.M, self.W - 2 * self.M,
            self:t("render_error", tostring(self.screen), tostring(err)), 16)
        self:button(self.M, self.H - self.M - dp(50), self.W - 2 * self.M, dp(50), self:t("close"),
            function() self:close() end, { style = "solid" })
    end
end

function Hub:refresh(kind)
    self:rebuild()
    UIManager:setDirty(self, kind or "ui")
end

function Hub:go(screen, page)
    self.screen = screen
    self.page = page or 1
    self.confirm_reset = false
    self:refresh("partial")
end

function Hub:close()
    UIManager:close(self, "flashui")
    if self.on_close then
        local cb = self.on_close
        self.on_close = nil
        cb()
    end
end

function Hub:onBack()
    if self.screen ~= "home" then self:go("home") else self:close() end
    return true
end

function Hub:nextPage()
    if self.npages and self.page < self.npages then
        self.page = self.page + 1
        self:refresh("partial")
    end
end

function Hub:prevPage()
    if self.page > 1 then
        self.page = self.page - 1
        self:refresh("partial")
    end
end

function Hub:onSwipeScreen(arg, ges)
    local d = ges and ges.direction
    if d == "west" then
        self:nextPage()
    elseif d == "east" then
        if self.page > 1 then self:prevPage()
        elseif self.screen ~= "home" then self:go("home") end
    end
    return true
end

function Hub:header(title, with_back)
    local W, M = self.W, self.M
    local hh = dp(54)
    self.hh = hh
    local isz = dp(26)
    local x = M
    if with_back then
        self:icon(M, (hh - isz) / 2, isz, "back")
        self:hit(0, 0, dp(70), hh, function() self:go("home") end)
        x = M + isz + dp(12)
    else
        self:icon(M, (hh - dp(30)) / 2, dp(30), "star")
        x = M + dp(30) + dp(12)
    end
    self:text(x, 0, title, 23, { bold = true, boxh = hh, maxw = W - x - M - dp(50) })
    self:icon(W - M - isz, (hh - isz) / 2, isz, "close")
    self:hit(W - dp(70), 0, dp(70), hh, function() self:close() end)
    self:fill(0, hh, W, 2, "k")
end

function Hub:pager()
    local W, M = self.W, self.M
    local bh = dp(46)
    local y = self.H - M - bh
    local bw = dp(116)
    local np = self.npages or 1
    self:button(M, y, bw, bh, self:t("prev"), function() self:prevPage() end,
        { style = self.page > 1 and "outline" or "disabled" })
    self:button(W - M - bw, y, bw, bh, self:t("next"), function() self:nextPage() end,
        { style = self.page < np and "outline" or "disabled" })
    self:text(M + bw, y, self:t("page_of", self.page, np), 17,
        { align = "center", boxw = W - 2 * M - 2 * bw, boxh = bh, c = "d" })
end

function Hub:listRow(y, rh, row)
    local M = self.M
    local cw = self.W - 2 * M
    self:frame(M, y, cw, rh, dp(14), row.dim and 1 or 2)
    local isz = min(dp(50), rh - dp(14))
    self:icon(M + dp(12), y + (rh - isz) / 2, isz, row.icon, row.mono)
    local tx = M + dp(12) + isz + dp(14)
    local rw = 0
    if row.right then rw = dp(78) elseif row.lock then rw = dp(40) end
    local tw = M + cw - dp(12) - rw - tx
    local ty = y + (rh - dp(46)) / 2
    self:text(tx, ty, row.title, 18, { bold = true, c = row.dim and "d" or "k", maxw = tw })
    if row.sub then self:text(tx, ty + dp(26), row.sub, 14, { c = "d", maxw = tw }) end
    if row.right then
        self:text(M + cw - dp(12) - rw, y, row.right, 14,
            { align = "right", boxw = rw, boxh = rh, c = "d" })
    end
    if row.lock then
        self:icon(M + cw - dp(12) - dp(24), y + (rh - dp(24)) / 2, dp(24), "lock", "m")
    end
end

-- --- màn hình chính -----------------------------------------------------
function Hub:build_home()
    local P, W, M = self.plugin, self.W, self.M
    local st = P.state
    local lang = self:lang()
    P:rollDay()
    self:header(self:t("app_title"), false)
    local cw = W - 2 * M
    local gap = dp(10)
    local y = self.hh + M

    -- thẻ nhân vật
    local lv, rem, need = Core.levelInfo(st.exp)
    local ti = Core.titleIndex(lv)
    local hero_h = dp(122)
    self:frame(M, y, cw, hero_h, dp(16), 2)
    local S = dp(94)
    self:icon(M + dp(12), y + (hero_h - S) / 2, S, Core.TITLES[ti][2])
    local tx = M + dp(12) + S + dp(16)
    local tw = M + cw - dp(14) - tx
    self:text(tx, y + dp(10), I18N.titleName(lang, ti), 27, { bold = true, maxw = tw })
    self:text(tx, y + dp(50), self:t("level_fmt", lv), 19, { maxw = tw })
    self:text(tx, y + dp(52), self:t("total_exp_fmt", Core.fmtNum(st.exp)), 14,
        { align = "right", boxw = tw, c = "d" })
    self:bar(tx, y + dp(80), tw, dp(13), rem / need)
    self:text(tx, y + dp(97), self:t("exp_prog_fmt", Core.fmtNum(rem), Core.fmtNum(need)), 14,
        { maxw = tw })
    self:hit(M, y, cw, hero_h, function() self:go("ranks") end)
    y = y + hero_h + gap

    -- nhiệm vụ ngày
    local goal = max(1, st.cfg.goal)
    local streak = P:effectiveStreak()
    local q_h = dp(100)
    self:frame(M, y, cw, q_h, dp(16), 2)
    self:icon(M + dp(12), y + dp(12), dp(36), "flame", streak == 0 and "m" or nil)
    self:text(M + dp(58), y + dp(12), self:t("daily_quest"), 20, { bold = true, boxh = dp(36) })
    self:text(M + dp(12), y + dp(12), self:t("streak_fmt", streak), 16,
        { bold = true, align = "right", boxw = cw - dp(24), boxh = dp(36) })
    self:bar(M + dp(12), y + dp(58), cw - dp(24), dp(14), st.today.pages / goal)
    self:text(M + dp(12), y + dp(76), self:t("pages_prog_fmt", st.today.pages, goal), 15)
    local right = st.today.done and self:t("completed") or self:t("pages_left_fmt", max(0, goal - st.today.pages))
    self:text(M + dp(12), y + dp(76), right, 15,
        { align = "right", boxw = cw - dp(24), c = "d" })
    y = y + q_h + gap

    -- thống kê
    local s_h = dp(66)
    self:frame(M, y, cw, s_h, dp(16), 2)
    local colw = cw / 3
    local stats = {
        { "book", Core.fmtNum(st.pages), self:t("stat_pages") },
        { "clock", Core.fmtTimeShort(st.seconds, lang), self:t("stat_time") },
        { "skull", tostring(st.defeated), self:t("stat_bosses") },
    }
    for i, s in ipairs(stats) do
        local cx = M + (i - 1) * colw
        if i > 1 then self:fill(cx, y + dp(12), 2, s_h - dp(24), "m") end
        self:icon(cx + dp(12), y + (s_h - dp(30)) / 2, dp(30), s[1])
        self:text(cx + dp(50), y + dp(9), s[2], 20, { bold = true, maxw = colw - dp(58) })
        self:text(cx + dp(50), y + dp(36), s[3], 13, { c = "d", maxw = colw - dp(58) })
    end
    y = y + s_h + gap

    -- lưới 6 ô
    local has_doc = P.ui.document ~= nil
    local tiles = {
        { "boss", self:t("tile_boss"), has_doc and self:t("tile_boss_sub") or self:t("tile_boss_empty"), "monster1", not has_doc },
        { "ach", self:t("tile_ach"), self:t("tile_ach_sub", Core.countAch(st), #Core.ACHIEVEMENTS), "trophy" },
        { "inv", self:t("tile_inv"), self:t("tile_inv_sub", #st.loot, st.defeated), "chest" },
        { "ranks", self:t("tile_ranks"), I18N.titleName(lang, ti), Core.TITLES[ti][2] },
        { "settings", self:t("tile_settings"), self:t("tile_settings_sub"), "gear" },
        { "help", self:t("tile_help"), self:t("tile_help_sub"), "bulb" },
    }
    local avail = self.H - y - M
    local th = clamp(floor((avail - 2 * gap) / 3), dp(64), dp(124))
    local tw2 = (cw - gap) / 2
    for i, t in ipairs(tiles) do
        local col, row = (i - 1) % 2, floor((i - 1) / 2)
        local x = M + col * (tw2 + gap)
        local ty = y + row * (th + gap)
        self:frame(x, ty, tw2, th, dp(16), 2)
        local isz = min(dp(56), th - dp(26))
        self:icon(x + dp(14), ty + (th - isz) / 2, isz, t[4], t[5] and "m" or nil)
        local lx = x + dp(14) + isz + dp(12)
        local lw = x + tw2 - dp(10) - lx
        self:text(lx, ty + floor(th / 2) - dp(27), t[2], 20, { bold = true, maxw = lw })
        self:text(lx, ty + floor(th / 2) + dp(2), t[3], 14, { c = "d", maxw = lw })
        self:hit(x, ty, tw2, th, function() self:go(t[1]) end)
    end
end

-- --- boss -----------------------------------------------------------------
function Hub:build_boss()
    local P, W, M = self.plugin, self.W, self.M
    local lang = self:lang()
    self:header(self:t("boss_screen_title"), true)
    local cw = W - 2 * M
    local y = self.hh + M
    local info = P:bossInfo()

    if not info then
        local S = dp(130)
        self:icon((W - S) / 2, y + dp(50), S, "monster1", "m")
        local py = y + dp(50) + S + dp(24)
        py = py + self:para(M + dp(20), py, cw - dp(40), self:t("boss_none_title"), 23,
            { bold = true, align = "center" }) + dp(10)
        self:para(M + dp(20), py, cw - dp(40), self:t("boss_none_desc"), 17, { align = "center", c = "d" })
        return
    end

    local card_h = dp(144)
    self:frame(M, y, cw, card_h, dp(16), 2)
    local S = dp(106)
    self:icon(M + dp(14), y + (card_h - S) / 2, S, "monster" .. info.variant, info.defeated and "m" or nil)
    local tx = M + dp(14) + S + dp(16)
    local tw = M + cw - dp(14) - tx
    local h1 = self:para(tx, y + dp(16), tw, Core.bossName(info.title, lang), 21, { bold = true })
    self:text(tx, y + dp(16) + h1 + dp(4), info.defeated and self:t("boss_defeated") or self:t("boss_waiting"), 15,
        { c = "d", maxw = tw })
    y = y + card_h + dp(14)

    local pct = floor(info.hp * 100 + 0.5)
    self:text(M, y, self:t("hp_left"), 18, { bold = true })
    self:text(M, y, pct .. "%", 18, { bold = true, align = "right", boxw = cw })
    y = y + dp(32)
    self:bar(M, y, cw, dp(24), info.hp)
    y = y + dp(32)
    self:text(M, y, self:t("boss_page_fmt", info.page, info.total), 15, { c = "d" })
    y = y + dp(34)

    local gap = dp(10)
    local bw = (cw - gap) / 2
    local bh = dp(74)
    local boxes = {
        { tostring(info.credited), self:t("pages_slashed") },
        { tostring(info.need), self:t("min_pages_boss") },
    }
    for i, b in ipairs(boxes) do
        local bx = M + (i - 1) * (bw + gap)
        self:frame(bx, y, bw, bh, dp(14), 2)
        self:text(bx, y + dp(8), b[1], 26, { bold = true, align = "center", boxw = bw })
        self:text(bx + dp(6), y + dp(46), b[2], 13, { c = "d", align = "center", boxw = bw - dp(12), maxw = bw - dp(12) })
    end
    y = y + bh + dp(14)

    if info.defeated then
        self:frame(M, y, cw, dp(64), dp(14), 2)
        self:icon(M + dp(12), y + dp(10), dp(44), "skull", "m")
        self:text(M + dp(70), y, self:t("boss_defeated_date", Core.shortDate(info.date)), 17,
            { bold = true, boxh = dp(64), maxw = cw - dp(84) })
        y = y + dp(64)
    else
        local prog = min(1, info.credited / max(1, info.need))
        self:text(M, y, self:t("boss_cond"), 17, { bold = true })
        self:text(M, y, self:t("boss_cond_prog", min(info.credited, info.need), info.need), 15,
            { align = "right", boxw = cw, c = "d" })
        y = y + dp(28)
        self:bar(M, y, cw, dp(14), prog)
        y = y + dp(26)
        y = y + self:para(M, y, cw, self:t("boss_cond_desc", floor(Core.BOSS_END_RATIO * 100)), 15, { c = "d" })
    end

    y = y + dp(18)
    if y + dp(100) < self.H - M then
        self:text(M, y, self:t("possible_loot"), 17, { bold = true })
        y = y + dp(32)
        local colw = cw / 4
        for i, r in ipairs({ "common", "rare", "epic", "legend" }) do
            local cx = M + (i - 1) * colw
            self:icon(cx + (colw - dp(48)) / 2, y, dp(48), Core.RARITY_ICON[r])
            self:text(cx, y + dp(54), I18N.rarityLabel(lang, r), 14, { align = "center", boxw = colw, c = "d" })
        end
    end
end

-- --- thành tựu ------------------------------------------------------------
function Hub:build_ach()
    local P, W, M = self.plugin, self.W, self.M
    local st = P.state
    local lang = self:lang()
    local ACH = Core.ACHIEVEMENTS
    self:header(self:t("tile_ach"), true)
    local cw = W - 2 * M
    local y = self.hh + M

    local sum_h = dp(74)
    self:frame(M, y, cw, sum_h, dp(16), 2)
    self:icon(M + dp(14), y + (sum_h - dp(46)) / 2, dp(46), "trophy")
    local n = Core.countAch(st)
    self:text(M + dp(74), y + dp(10), self:t("ach_unlocked_fmt", n, #ACH), 19,
        { bold = true, maxw = cw - dp(90) })
    self:bar(M + dp(74), y + dp(44), cw - dp(90), dp(14), n / #ACH)
    y = y + sum_h + dp(10)

    local rh, g = dp(68), dp(8)
    local bottom = self.H - self.M - dp(46) - dp(10)
    local per = max(1, floor((bottom - y + g) / (rh + g)))
    self.npages = max(1, math.ceil(#ACH / per))
    self.page = clamp(self.page, 1, self.npages)
    local first = (self.page - 1) * per + 1
    local last = min(#ACH, first + per - 1)
    for i = first, last do
        local a = ACH[i]
        local got = st.ach[a.id]
        local aname, adesc = I18N.achInfo(lang, a.id)
        self:listRow(y + (i - first) * (rh + g), rh, {
            icon = a.icon, mono = (not got) and "m" or nil, title = aname, sub = adesc,
            dim = not got, right = got and Core.shortDate(got) or nil, lock = not got,
        })
    end
    self:pager()
end

-- --- kho đồ & chiến tích --------------------------------------------------
function Hub:build_inv()
    local P, W, M = self.plugin, self.W, self.M
    local st = P.state
    local lang = self:lang()
    self:header(self:t("inv_title"), true)
    local cw = W - 2 * M
    local y = self.hh + M

    local won, fighting = {}, {}
    for _, b in pairs(st.bosses) do
        if b.defeated then
            won[#won + 1] = b
        elseif (b.pages or 0) > 0 then
            fighting[#fighting + 1] = b
        end
    end
    table.sort(won, function(a, b) return (a.date or "") > (b.date or "") end)
    table.sort(fighting, function(a, b) return (a.pages or 0) > (b.pages or 0) end)

    local tabs = {
        self:t("tab_loot", #st.loot),
        self:t("tab_won", #won),
        self:t("tab_fighting", #fighting),
    }
    local tg = dp(8)
    local tw = (cw - 2 * tg) / 3
    for i, label in ipairs(tabs) do
        self:button(M + (i - 1) * (tw + tg), y, tw, dp(46), label,
            function() self.inv_tab = i; self.page = 1; self:refresh("partial") end,
            { style = (self.inv_tab == i) and "solid" or "outline", size = 16, bold = true })
    end
    y = y + dp(46) + dp(12)

    local rows = {}
    if self.inv_tab == 1 then
        for i = #st.loot, 1, -1 do
            local it = st.loot[i]
            rows[#rows + 1] = {
                icon = Core.RARITY_ICON[it.rarity] or "rar_common",
                title = Core.lootDisplayName(it, lang),
                sub = self:t("loot_from", Core.shorten(it.from or "?", 28), Core.shortDate(it.date)),
                right = I18N.rarityLabel(lang, it.rarity),
            }
        end
    elseif self.inv_tab == 2 then
        for _, b in ipairs(won) do
            rows[#rows + 1] = {
                icon = "monster\" .. Core.bossVariant(b.title), mono = \"m",
                title = Core.bossName(b.title, lang),
                sub = self:t("won_sub", Core.shortDate(b.date), b.pages or 0),
            }
        end
    else
        for _, b in ipairs(fighting) do
            rows[#rows + 1] = {
                icon = "monster" .. Core.bossVariant(b.title),
                title = Core.bossName(b.title, lang),
                sub = self:t("fighting_sub", b.pages or 0),
            }
        end
    end

    if #rows == 0 then
        local S = dp(90)
        local icon = ({ "chest", "skull", "monster1" })[self.inv_tab]
        self:icon((W - S) / 2, y + dp(60), S, icon, "m")
        local msg = ({ self:t("empty_loot"), self:t("empty_won"), self:t("empty_fighting") })[self.inv_tab]
        self:para(M + dp(20), y + dp(60) + S + dp(16), cw - dp(40), msg, 17, { align = "center", c = "d" })
        self.npages = 1
        return
    end

    local rh, g = dp(64), dp(8)
    local bottom = self.H - self.M - dp(46) - dp(10)
    local per = max(1, floor((bottom - y + g) / (rh + g)))
    self.npages = max(1, math.ceil(#rows / per))
    self.page = clamp(self.page, 1, self.npages)
    local first = (self.page - 1) * per + 1
    local last = min(#rows, first + per - 1)
    for i = first, last do
        self:listRow(y + (i - first) * (rh + g), rh, rows[i])
    end
    self:pager()
end

-- --- danh hiệu ------------------------------------------------------------
function Hub:build_ranks()
    local P, W, M = self.plugin, self.W, self.M
    local st = P.state
    local lang = self:lang()
    self:header(self:t("tile_ranks"), true)
    local cw = W - 2 * M
    local y = self.hh + M
    local lv = Core.levelInfo(st.exp)
    local cur = Core.titleIndex(lv)
    local n = #Core.TITLES
    local g = dp(8)
    local avail = self.H - y - M
    local rh = clamp(floor((avail - (n - 1) * g) / n), dp(58), dp(86))
    for i, t in ipairs(Core.TITLES) do
        local ry = y + (i - 1) * (rh + g)
        local reached = i <= cur
        self:frame(M, ry, cw, rh, dp(14), (i == cur) and 4 or 2)
        local isz = rh - dp(14)
        self:icon(M + dp(12), ry + dp(7), isz, t[2], (not reached) and "m" or nil)
        local tx = M + dp(12) + isz + dp(16)
        self:text(tx, ry + floor(rh / 2) - dp(26), I18N.titleName(lang, i), 21, { bold = true, c = reached and "k" or "d" })
        self:text(tx, ry + floor(rh / 2) + dp(2), self:t("from_level_fmt", t[1]), 14, { c = "d" })
        if i == cur then
            local pw, ph = dp(104), dp(32)
            local px = M + cw - dp(14) - pw
            self:round(px, ry + (rh - ph) / 2, pw, ph, ph / 2, "k")
            self:text(px, ry + (rh - ph) / 2, self:t("you_are_here"), 13,
                { bold = true, c = "w", align = "center", boxw = pw, boxh = ph })
        elseif reached then
            self:text(M, ry, self:t("reached"), 14, { c = "d", align = "right", boxw = cw - dp(16), boxh = rh })
        else
            self:icon(M + cw - dp(14) - dp(24), ry + (rh - dp(24)) / 2, dp(24), "lock", "m")
        end
    end
end

-- --- cài đặt --------------------------------------------------------------
function Hub:build_settings()
    local P, W, M = self.plugin, self.W, self.M
    local cfg = P.state.cfg
    local lang = self:lang()
    self:header(self:t("tile_settings"), true)
    local cw = W - 2 * M
    local y = self.hh + M
    local rh, g = dp(58), dp(7)

    local function touch()
        P.dirty = true
        P:save()
        if P.refreshStatusBar then P:refreshStatusBar() end
        self:refresh("ui")
    end

    local function cycleLang()
        local order = I18N.LANG_ORDER
        local cur = cfg.lang or "auto"
        local next_idx = 1
        for i, code in ipairs(order) do
            if code == cur then
                next_idx = (i % #order) + 1
                break
            end
        end
        cfg.lang = order[next_idx]
        touch()
    end

    local rows = {
        { kind = "lang", label = self:t("set_lang"), sub = self:t("set_lang_sub") },
        { kind = "toggle", label = self:t("set_statusbar"), sub = self:t("set_statusbar_sub"), key = "status_bar" },
        { kind = "toggle", label = self:t("set_toast"), sub = self:t("set_toast_sub"), key = "toast" },
        { kind = "step", label = self:t("set_toast_secs"), sub = self:t("set_toast_secs_sub"), key = "toast_secs", vmin = 1, vmax = 5, step = 1, unit = self:t("unit_sec") },
        { kind = "step", label = self:t("set_min_secs"), sub = self:t("set_min_secs_sub"), key = "min_secs", vmin = 3, vmax = 60, step = 1, unit = self:t("unit_sec") },
        { kind = "step", label = self:t("set_goal"), sub = self:t("set_goal_sub"), key = "goal", vmin = 5, vmax = 300, step = 5, unit = self:t("unit_page") },
    }

    for i, r in ipairs(rows) do
        local ry = y + (i - 1) * (rh + g)
        self:frame(M, ry, cw, rh, dp(14), 2)
        local ctrl_w = (r.kind == "toggle") and dp(76) or dp(176)
        local lw = cw - dp(14) - ctrl_w - dp(20)
        self:text(M + dp(14), ry + dp(8), r.label, 17, { bold = true, maxw = lw })
        self:text(M + dp(14), ry + dp(34), r.sub, 12, { c = "d", maxw = lw })
        local cx = M + cw - dp(14) - ctrl_w
        if r.kind == "lang" then
            local bh = dp(38)
            local by = ry + (rh - bh) / 2
            local lbl = I18N.langOptionLabel(lang, cfg.lang or "auto")
            self:button(cx, by, ctrl_w, bh, lbl, cycleLang, { size = 14, bold = true })
            self:hit(M, ry, cw, rh, cycleLang)
        elseif r.kind == "toggle" then
            local on = cfg[r.key] and true or false
            local pw, ph = dp(58), dp(30)
            local px, py = cx + ctrl_w - pw, ry + (rh - ph) / 2
            if on then
                self:round(px, py, pw, ph, ph / 2, "k")
                self:circle(px + pw - ph / 2, py + ph / 2, ph / 2 - dp(4), "w")
            else
                self:frame(px, py, pw, ph, ph / 2, 3, "w", "k")
                self:circle(px + ph / 2, py + ph / 2, ph / 2 - dp(7), "k")
            end
            self:hit(M, ry, cw, rh, function() cfg[r.key] = not cfg[r.key]; touch() end)
        else
            local bs = dp(40)
            local vy = ry + (rh - bs) / 2
            local vw = ctrl_w - 2 * bs - dp(8)
            local v = tonumber(cfg[r.key]) or r.vmin
            self:button(cx, vy, bs, bs, "−", function()
                cfg[r.key] = max(r.vmin, v - r.step); touch()
            end, { size = 24, bold = true, style = v > r.vmin and "outline" or "disabled" })
            self:text(cx + bs + dp(4), vy, v .. r.unit, 16,
                { bold = true, align = "center", boxw = vw, boxh = bs, maxw = vw })
            self:button(cx + bs + dp(8) + vw, vy, bs, bs, "+", function()
                cfg[r.key] = min(r.vmax, v + r.step); touch()
            end, { size = 24, bold = true, style = v < r.vmax and "outline" or "disabled" })
        end
    end

    local by = y + #rows * (rh + g) + dp(4)
    local bh = dp(48)
    if self.confirm_reset then
        self:button(M, by, cw, bh, self:t("reset_confirm"), function()
            P:resetAll()
            self.confirm_reset = false
            self:go("home")
        end, { style = "solid", bold = true, size = 16 })
        self:text(M, by + bh + dp(4), self:t("reset_hint"), 12,
            { c = "d", align = "center", boxw = cw })
    else
        self:button(M, by, cw, bh, self:t("reset_btn"), function()
            self.confirm_reset = true
            self:refresh("ui")
        end, { size = 16 })
    end
    self:text(M, self.H - M - dp(20), self:t("version_fmt", Core.VERSION), 12,
        { c = "d", align = "center", boxw = cw })
end

function Hub:onTapEmpty()
    if self.confirm_reset then
        self.confirm_reset = false
        self:refresh("ui")
    end
    return true
end

-- --- cách chơi ------------------------------------------------------------
function Hub:build_help()
    local P, W, M = self.plugin, self.W, self.M
    local cfg = P.state.cfg
    local lang = self:lang()
    self:header(self:t("tile_help"), true)
    local cw = W - 2 * M
    local y0 = self.hh + M

    local rank_chain = {}
    for i = 1, #Core.TITLES do
        rank_chain[#rank_chain + 1] = I18N.titleName(lang, i)
    end

    local entries = {
        { "star", self:t("help_exp_t"), self:t("help_exp_d", cfg.min_secs, Core.BASE_EXP) },
        { "flame", self:t("help_streak_t"), self:t("help_streak_d") },
        { "monster1", self:t("help_boss_t"), self:t("help_boss_d") },
        { "chest", self:t("help_loot_t"), self:t("help_loot_d") },
        { "rank5", self:t("help_rank_t"), table.concat(rank_chain, " → ") .. "." },
        { "bulb", self:t("help_tip_t"), self:t("help_tip_d") },
    }

    local isz = dp(44)
    local pad = dp(14)
    local tx_w = cw - 2 * pad - isz - dp(14)
    local g = dp(10)
    local bottom = self.H - self.M - dp(46) - dp(10)

    local pages, cur, used = {}, {}, 0
    for _, e in ipairs(entries) do
        local h = 2 * pad + dp(28) + Canvas.measurePara(e[3], 15, tx_w) + dp(4)
        h = max(h, 2 * pad + isz)
        e.h = h
        if #cur > 0 and used + h + g > bottom - y0 then
            pages[#pages + 1] = cur
            cur, used = {}, 0
        end
        cur[#cur + 1] = e
        used = used + h + g
    end
    if #cur > 0 then pages[#pages + 1] = cur end

    self.npages = max(1, #pages)
    self.page = clamp(self.page, 1, self.npages)
    local y = y0
    for _, e in ipairs(pages[self.page] or {}) do
        self:frame(M, y, cw, e.h, dp(14), 2)
        self:icon(M + pad, y + pad, isz, e[1])
        local tx = M + pad + isz + dp(14)
        self:text(tx, y + pad - dp(2), e[2], 19, { bold = true, maxw = tx_w })
        self:para(tx, y + pad + dp(28), tx_w, e[3], 15, { c = "d" })
        y = y + e.h + g
    end
    self:pager()
end

-- ---------------------------------------------------------------------
-- Popup chúc mừng
-- ---------------------------------------------------------------------
local Popup = Canvas:extend{}

function Popup:init()
    local sw, sh = Screen:getWidth(), Screen:getHeight()
    local e = self.entry
    local lang = self.lang or "vi"
    self.items, self.hits = {}, {}
    local cw = floor(sw * 0.86)
    local pad = dp(20)
    local inner = cw - 2 * pad
    local isz = dp(108)
    local gsz = dp(70)
    local btn_h = dp(38)
    local btn_w = min(inner, dp(190))

    local ht = Canvas.measurePara(e.title, 25, inner, true)
    local hs = e.sub and Canvas.measurePara(e.sub, 20, inner, true) or 0
    local hn = e.note and Canvas.measurePara(e.note, 16, inner) or 0
    local hint_h = dp(22)
    local ch = pad + isz + dp(14) + ht
        + (hs > 0 and (dp(6) + hs) or 0)
        + (hn > 0 and (dp(10) + hn) or 0)
        + dp(12) + btn_h + dp(10) + hint_h + pad
    local cx, cy = floor((sw - cw) / 2), floor((sh - ch) / 2)
    self.dimen = Geom:new{ x = cx, y = cy, w = cw, h = ch }
    self.ges_events = {
        TapScreen = { GestureRange:new{ ges = "tap", range = Geom:new{ x = 0, y = 0, w = sw, h = sh } } },
    }

    self:frame(cx, cy, cw, ch, dp(20), 4)
    self:frame(cx + dp(8), cy + dp(8), cw - dp(16), ch - dp(16), dp(14), 1)

    local y = cy + pad
    if e.icon2 then
        local total = isz + dp(16) + gsz
        local ix = cx + (cw - total) / 2
        self:icon(ix, y, isz, e.icon)
        self:icon(ix + isz + dp(16), y + (isz - gsz) / 2, gsz, e.icon2)
    else
        self:icon(cx + (cw - isz) / 2, y, isz, e.icon)
    end
    y = y + isz + dp(14)
    y = y + self:para(cx + pad, y, inner, e.title, 25, { bold = true, align = "center" })
    if e.sub then
        y = y + dp(6)
        y = y + self:para(cx + pad, y, inner, e.sub, 20, { bold = true, align = "center", c = "d" })
    end
    if e.note then
        y = y + dp(10)
        y = y + self:para(cx + pad, y, inner, e.note, 16, { align = "center" })
    end
    y = y + dp(12)
    local shot_label = (lang == "en") and "Screenshot" or "Chụp màn hình"
    self:button(cx + floor((cw - btn_w) / 2), y, btn_w, btn_h, shot_label, function()
        self:takeScreenshot()
    end, { size = 15, bold = true })
    self:text(cx, y + btn_h + dp(10), I18N.t(lang, "tap_continue"), 13,
        { c = "d", align = "center", boxw = cw })
end

function Popup:takeScreenshot()
    pcall(function()
        local Event = require("ui/event")
        UIManager:sendEvent(Event:new("Screenshot"))
    end)
end

function Popup:dismiss()
    if self.dismissed then return end
    self.dismissed = true
    if self.timer then UIManager:unschedule(self.timer) end
    UIManager:close(self, "partial", self.dimen)
    if self.on_close then
        local cb = self.on_close
        self.on_close = nil
        cb()
    end
end

function Popup:onTapEmpty()
    self:dismiss()
    return true
end

-- ---------------------------------------------------------------------
-- Toast "+10 EXP" góc phải dưới
-- ---------------------------------------------------------------------
local Toast = WidgetContainer:extend{ toast = true }

function Toast:init()
    local sw, sh = Screen:getWidth(), Screen:getHeight()
    local padx, pady = dp(7), dp(3)
    local isz = dp(15)
    self.main_tw = TextWidget:new{
        text = tostring(self.text or ""), face = Font:getFace("tfont", 14), fgcolor = COL.k,
    }
    local mw, mh = self.main_tw:getSize().w, self.main_tw:getSize().h
    local dw, dh = 0, 0
    if self.detail and self.detail ~= "" then
        self.detail_tw = TextWidget:new{
            text = tostring(self.detail), face = Font:getFace("cfont", 13), fgcolor = COL.d,
            max_width = floor(sw * 0.7),
        }
        dw, dh = self.detail_tw:getSize().w, self.detail_tw:getSize().h
    end
    self.isz = isz
    self.padx, self.pady = padx, pady
    self.mw, self.mh, self.dw, self.dh = mw, mh, dw, dh
    local w = padx + isz + dp(4) + mw + (dw > 0 and (dp(8) + dw) or 0) + padx
    local h = max(mh, dh, isz) + 2 * pady
    self.dimen = Geom:new{ x = sw - w - dp(3), y = sh - h - dp(2), w = w, h = h }
end

function Toast:paintTo(bb)
    local d = self.dimen
    local x, y, w, h = d.x, d.y, d.w, d.h
    bb:paintRect(x, y, w, h, COL.w)
    bb:paintRect(x, y, w, 1, COL.k)
    bb:paintRect(x, y, 1, h, COL.k)
    local ix = x + self.padx
    Icons.draw(bb, "star", ix, y + floor((h - self.isz) / 2), self.isz)
    local tx = ix + self.isz + dp(4)
    self.main_tw:paintTo(bb, tx, y + floor((h - self.mh) / 2))
    if self.detail_tw then
        self.detail_tw:paintTo(bb, tx + self.mw + dp(8), y + floor((h - self.dh) / 2))
    end
end

function Toast:onCloseWidget()
    if self.main_tw and self.main_tw.free then pcall(self.main_tw.free, self.main_tw) end
    if self.detail_tw and self.detail_tw.free then pcall(self.detail_tw.free, self.detail_tw) end
end

return { Hub = Hub, Popup = Popup, Toast = Toast, Canvas = Canvas }
