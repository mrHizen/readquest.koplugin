--[[--
Bộ biểu tượng vẽ bằng code cho Đọc Sách Luyện Cấp.
Mọi hình đều dựng từ Blitbuffer:paintRect (không cần file ảnh), toạ độ 0..100.
]]

local Blitbuffer = require("ffi/blitbuffer")

local BLACK = Blitbuffer.COLOR_BLACK
local WHITE = Blitbuffer.COLOR_WHITE

local function gray(level, fallback)
    if Blitbuffer.Color8 then
        local ok, c = pcall(Blitbuffer.Color8, math.floor(level * 255 + 0.5))
        if ok and c then return c end
    end
    return fallback
end

-- k = đen, w = trắng, d = xám đậm, m = xám vừa, l = xám nhạt
local COL = {
    k = BLACK,
    w = WHITE,
    d = gray(0.28, BLACK),
    m = gray(0.55, BLACK),
    l = gray(0.88, WHITE),
}

local floor, sqrt, max, min = math.floor, math.sqrt, math.max, math.min
local function ipx(v) return floor(v + 0.5) end

-- ---------------------------------------------------------------------
-- Painter: các hình cơ bản, có phép co giãn/dịch (with)
-- ---------------------------------------------------------------------
local Painter = {}
Painter.__index = Painter

function Painter:new(bb, x, y, size, mono)
    return setmetatable({ bb = bb, x = x, y = y, k = size / 100, mono = mono,
                          tx = 0, ty = 0, sc = 1 }, Painter)
end

function Painter:col(c)
    c = c or "k"
    if c == "k" and self.mono then c = self.mono end
    return COL[c] or BLACK
end

function Painter:X(x) return self.x + self.k * (x * self.sc + self.tx) end
function Painter:Y(y) return self.y + self.k * (y * self.sc + self.ty) end
function Painter:L(len) return self.k * len * self.sc end

function Painter:with(tx, ty, sc, fn)
    local otx, oty, osc = self.tx, self.ty, self.sc
    self.tx = tx * osc + otx
    self.ty = ty * osc + oty
    self.sc = sc * osc
    fn(self)
    self.tx, self.ty, self.sc = otx, oty, osc
end

function Painter:rect(x, y, w, h, c)
    local x1, y1 = ipx(self:X(x)), ipx(self:Y(y))
    local x2, y2 = ipx(self:X(x + w)), ipx(self:Y(y + h))
    self.bb:paintRect(x1, y1, max(1, x2 - x1), max(1, y2 - y1), self:col(c))
end

function Painter:circle(cx, cy, r, c)
    local R = max(1, ipx(self:L(r)))
    local CX, CY = ipx(self:X(cx)), ipx(self:Y(cy))
    local col = self:col(c)
    for dy = -R, R do
        local dx = floor(sqrt(R * R - dy * dy) + 0.5)
        self.bb:paintRect(CX - dx, CY + dy, 2 * dx + 1, 1, col)
    end
end

function Painter:ring(cx, cy, r, t, c)
    local R = max(1, ipx(self:L(r)))
    local T = max(1, ipx(self:L(t)))
    local Ri = R - T
    local CX, CY = ipx(self:X(cx)), ipx(self:Y(cy))
    local col = self:col(c)
    for dy = -R, R do
        local dxo = floor(sqrt(R * R - dy * dy) + 0.5)
        if Ri > 0 and math.abs(dy) < Ri then
            local dxi = floor(sqrt(Ri * Ri - dy * dy) + 0.5)
            local w = dxo - dxi
            if w > 0 then
                self.bb:paintRect(CX - dxo, CY + dy, w, 1, col)
                self.bb:paintRect(CX + dxi + 1, CY + dy, w, 1, col)
            end
        else
            self.bb:paintRect(CX - dxo, CY + dy, 2 * dxo + 1, 1, col)
        end
    end
end

function Painter:ellipse(cx, cy, rx, ry, c)
    local RX, RY = max(1, ipx(self:L(rx))), max(1, ipx(self:L(ry)))
    local CX, CY = ipx(self:X(cx)), ipx(self:Y(cy))
    local col = self:col(c)
    for dy = -RY, RY do
        local t = 1 - (dy / RY) * (dy / RY)
        local dx = floor(RX * sqrt(max(0, t)) + 0.5)
        self.bb:paintRect(CX - dx, CY + dy, 2 * dx + 1, 1, col)
    end
end

function Painter:line(x1, y1, x2, y2, t, c)
    local ax, ay = self:X(x1), self:Y(y1)
    local bx, by = self:X(x2), self:Y(y2)
    local T = max(1, ipx(self:L(t)))
    local n = max(1, floor(max(math.abs(bx - ax), math.abs(by - ay))))
    local col = self:col(c)
    local half = T / 2
    for i = 0, n do
        local px = ax + (bx - ax) * i / n
        local py = ay + (by - ay) * i / n
        self.bb:paintRect(ipx(px - half), ipx(py - half), T, T, col)
    end
end

-- Đa giác đặc (quét từng hàng, quy tắc chẵn-lẻ)
function Painter:poly(pts, c)
    local n = floor(#pts / 2)
    if n < 3 then return end
    local xs, ys = {}, {}
    local miny, maxy = math.huge, -math.huge
    for i = 1, n do
        xs[i] = self:X(pts[2 * i - 1])
        ys[i] = self:Y(pts[2 * i])
        miny = min(miny, ys[i])
        maxy = max(maxy, ys[i])
    end
    local col = self:col(c)
    for y = floor(miny), math.ceil(maxy) do
        local sy = y + 0.5
        local cross = {}
        for i = 1, n do
            local j = (i % n) + 1
            local y1, y2 = ys[i], ys[j]
            if (y1 <= sy and y2 > sy) or (y2 <= sy and y1 > sy) then
                cross[#cross + 1] = xs[i] + (sy - y1) * (xs[j] - xs[i]) / (y2 - y1)
            end
        end
        table.sort(cross)
        for i = 1, #cross - 1, 2 do
            local xa, xb = ipx(cross[i]), ipx(cross[i + 1])
            if xb > xa then self.bb:paintRect(xa, y, xb - xa, 1, col) end
        end
    end
end

local function sparkle(P, cx, cy, r, c)
    local q = r * 0.28
    P:poly({ cx, cy - r, cx + q, cy - q, cx + r, cy, cx + q, cy + q,
             cx, cy + r, cx - q, cy + q, cx - r, cy, cx - q, cy - q }, c)
end

local function starPoly(P, cx, cy, ro, ri, c)
    local pts = {}
    for i = 0, 9 do
        local r = (i % 2 == 0) and ro or ri
        local a = -math.pi / 2 + i * math.pi / 5
        pts[#pts + 1] = cx + r * math.cos(a)
        pts[#pts + 1] = cy + r * math.sin(a)
    end
    P:poly(pts, c)
end

-- ---------------------------------------------------------------------
-- Ký hiệu (toạ độ 0..100)
-- ---------------------------------------------------------------------
local function sym_book(P)
    P:poly({ 10, 26, 47, 34, 47, 72, 10, 64 })
    P:poly({ 90, 26, 53, 34, 53, 72, 90, 64 })
    for i = 0, 2 do
        local dy = i * 9
        P:line(18, 38 + dy, 40, 42 + dy, 3.5, "w")
        P:line(82, 38 + dy, 60, 42 + dy, 3.5, "w")
    end
    P:poly({ 6, 68, 47, 77, 53, 77, 94, 68, 94, 75, 53, 84, 47, 84, 6, 75 })
end

local function sym_brush(P)
    P:line(84, 10, 46, 50, 9)                    -- cán bút
    P:line(46, 50, 39, 57, 13, "d")              -- khoen
    P:poly({ 30, 50, 46, 66, 12, 90 })           -- đầu lông
    P:rect(58, 74, 34, 16)                       -- nghiên mực
    P:ellipse(75, 80, 12, 3.5, "w")
end

local function sym_scroll(P)
    P:rect(14, 22, 72, 10); P:circle(14, 27, 7); P:circle(86, 27, 7)
    P:rect(14, 68, 72, 10); P:circle(14, 73, 7); P:circle(86, 73, 7)
    P:rect(20, 32, 3, 36); P:rect(77, 32, 3, 36)
    P:line(30, 42, 70, 42, 4); P:line(30, 52, 70, 52, 4); P:line(30, 62, 56, 62, 4)
end

local function sym_cap(P)
    P:poly({ 50, 16, 96, 38, 50, 60, 4, 38 })
    P:poly({ 22, 52, 50, 66, 78, 52, 78, 76, 50, 90, 22, 76 })
    P:line(88, 41, 88, 72, 3.5)
    P:circle(88, 76, 6)
end

local function sym_seal(P)
    P:circle(50, 22, 13)
    P:rect(43, 24, 14, 24)
    P:rect(12, 46, 76, 42)
    P:rect(19, 53, 62, 28, "w")
    P:line(50, 56, 50, 78, 5); P:line(29, 67, 71, 67, 5)
end

local function sym_flower(P)
    local pts = {}
    for i = 0, 4 do
        local a = -math.pi / 2 + i * 2 * math.pi / 5
        pts[#pts + 1] = { 50 + 27 * math.cos(a), 50 + 27 * math.sin(a) }
    end
    for _, p in ipairs(pts) do P:circle(p[1], p[2], 18) end
    for _, p in ipairs(pts) do P:circle(p[1], p[2], 11, "w") end
    P:circle(50, 50, 14)
    P:circle(50, 50, 5, "w")
end

local function sym_eye(P)
    P:line(12, 26, 50, 12, 5); P:line(50, 12, 88, 26, 5)
    P:ellipse(50, 56, 46, 27)
    P:ellipse(50, 56, 39, 20, "w")
    P:circle(50, 56, 17)
    P:circle(43, 49, 5, "w")
end

local function sym_crown(P)
    P:poly({ 10, 76, 6, 32, 30, 54, 50, 22, 70, 54, 94, 32, 90, 76 })
    P:rect(10, 78, 80, 10)
    P:circle(50, 62, 6, "w"); P:circle(28, 66, 4, "w"); P:circle(72, 66, 4, "w")
    P:circle(6, 28, 5); P:circle(50, 18, 6); P:circle(94, 28, 5)
end

local function skull(P)
    P:circle(50, 42, 31)
    P:rect(30, 58, 40, 28)
    P:circle(37, 44, 9, "w"); P:circle(63, 44, 9, "w")
    P:poly({ 50, 52, 43, 66, 57, 66 }, "w")
    P:line(40, 74, 40, 86, 3.5, "w"); P:line(50, 74, 50, 86, 3.5, "w"); P:line(60, 74, 60, 86, 3.5, "w")
end

local function flame(P)
    P:poly({ 50, 4, 60, 22, 76, 40, 84, 60, 76, 82, 60, 94, 40, 94, 24, 82, 16, 62, 24, 44,
             34, 52, 38, 32, 46, 20 })
    P:poly({ 50, 48, 62, 66, 60, 80, 50, 88, 40, 80, 38, 66 }, "w")
    P:poly({ 50, 66, 57, 77, 50, 84, 43, 77 })
end

local function sword(P)
    P:poly({ 38, 70, 30, 62, 66, 26, 84, 14, 74, 34 })
    P:line(24, 56, 44, 76, 7)                     -- chắn kiếm
    P:line(34, 66, 20, 80, 6)                     -- chuôi
    P:circle(17, 83, 6)
end

local function monster(P, variant)
    if variant == 1 then
        P:poly({ 24, 40, 12, 8, 42, 30 }); P:poly({ 76, 40, 88, 8, 58, 30 })
        P:ellipse(50, 58, 34, 32)
        P:poly({ 28, 50, 47, 58, 30, 63 }, "w"); P:poly({ 72, 50, 53, 58, 70, 63 }, "w")
        P:circle(40, 58, 3.5); P:circle(60, 58, 3.5)
        P:poly({ 30, 72, 70, 72, 62, 86, 38, 86 }, "w")
        P:line(41, 72, 41, 86, 3); P:line(50, 72, 50, 86, 3); P:line(59, 72, 59, 86, 3)
    elseif variant == 2 then
        P:ellipse(50, 56, 38, 36)
        P:poly({ 22, 32, 14, 8, 36, 22 }); P:poly({ 78, 32, 86, 8, 64, 22 })
        P:circle(50, 48, 17, "w"); P:circle(50, 48, 8)
        P:circle(46, 44, 3, "w")
        P:poly({ 24, 72, 34, 66, 42, 76, 50, 66, 58, 76, 66, 66, 76, 72, 76, 80, 24, 80 }, "w")
    else
        P:poly({ 14, 50, 14, 14, 30, 34, 42, 8, 50, 30, 58, 8, 70, 34, 86, 14, 86, 50 })
        P:ellipse(50, 62, 36, 30)
        P:circle(36, 58, 9, "w"); P:circle(64, 58, 9, "w")
        P:circle(36, 58, 4); P:circle(64, 58, 4)
        P:poly({ 32, 76, 68, 76, 50, 90 }, "w")
        P:poly({ 40, 76, 44, 76, 42, 83 }); P:poly({ 56, 76, 60, 76, 58, 83 })
    end
end

local function badge(P, tier)
    P:ring(50, 50, 45, tier >= 6 and 5 or 4)
    if tier >= 3 then P:ring(50, 50, 38, 2) end
    if tier >= 6 then
        P:circle(50, 5, 5); P:circle(95, 50, 5); P:circle(50, 95, 5); P:circle(5, 50, 5)
    end
end

-- ---------------------------------------------------------------------
-- Bảng biểu tượng
-- ---------------------------------------------------------------------
local I = {}

-- 8 huy hiệu danh hiệu
local RANK_SYMS = { sym_book, sym_brush, sym_scroll, sym_cap, sym_seal, sym_flower, sym_eye, sym_crown }
for i, sym in ipairs(RANK_SYMS) do
    I["rank" .. i] = function(P)
        badge(P, i)
        P:with(18, 18, 0.64, sym)
    end
end

-- thành tựu
I.ach_first = sword
I.ach_p100 = function(P)
    P:rect(26, 14, 48, 72)
    P:rect(33, 24, 34, 16, "w")
    P:line(39, 32, 61, 32, 3.5)
    P:line(26, 58, 74, 58, 3, "w"); P:line(26, 66, 74, 66, 3, "w")
end
local function bookRow(P, x, y, w)
    P:rect(x, y, w, 15)
    P:line(x + 7, y + 3, x + 7, y + 12, 2.5, "w")
    P:line(x + 12, y + 3, x + 12, y + 12, 2.5, "w")
end
I.ach_p1000 = function(P)
    bookRow(P, 14, 66, 72); bookRow(P, 22, 49, 60); bookRow(P, 12, 32, 66)
    P:line(30, 22, 70, 22, 3)
end
I.ach_p5000 = function(P)
    bookRow(P, 12, 74, 76); bookRow(P, 20, 59, 62); bookRow(P, 14, 44, 70); bookRow(P, 24, 29, 54)
    starPoly(P, 50, 14, 13, 5.5)
end
I.ach_boss1 = skull
I.ach_boss5 = function(P)
    P:line(22, 22, 78, 78, 9)
    P:line(78, 22, 22, 78, 9)
    P:line(54, 82, 84, 52, 7); P:line(16, 52, 46, 82, 7)
    P:circle(84, 84, 6); P:circle(16, 84, 6)
end
I.ach_boss20 = function(P)
    P:with(12, 22, 0.76, skull)
    P:poly({ 26, 30, 21, 6, 38, 19, 50, 2, 62, 19, 79, 6, 74, 30 })
    P:rect(26, 31, 48, 6)
end
I.ach_streak3 = flame
I.ach_streak7 = function(P)
    P:rect(38, 46, 24, 40)
    P:line(38, 58, 38, 66, 3, "w")
    P:rect(24, 86, 52, 7)
    P:line(50, 40, 50, 47, 3)
    P:poly({ 50, 6, 60, 20, 63, 32, 56, 42, 44, 42, 37, 32, 40, 20 })
    P:poly({ 50, 24, 56, 34, 50, 40, 44, 34 }, "w")
end
I.ach_streak30 = function(P)
    P:rect(10, 18, 80, 72)
    P:rect(18, 44, 64, 38, "w")
    P:rect(26, 6, 8, 20); P:rect(66, 6, 8, 20)
    for r = 0, 1 do
        for c = 0, 2 do
            P:rect(24 + c * 20, 50 + r * 16, 14, 11)
        end
    end
end
I.ach_night = function(P)
    P:circle(44, 54, 34)
    P:circle(62, 42, 29, "w")
    sparkle(P, 78, 22, 14); sparkle(P, 88, 58, 8); sparkle(P, 62, 82, 6)
end
I.ach_dawn = function(P)
    P:circle(50, 64, 26)
    P:rect(0, 64, 100, 40, "w")
    P:rect(6, 64, 88, 6)
    for i = 0, 6 do
        local a = math.pi + i * math.pi / 6
        P:line(50 + 35 * math.cos(a), 64 + 35 * math.sin(a),
               50 + 47 * math.cos(a), 64 + 47 * math.sin(a), 5)
    end
    P:line(24, 80, 76, 80, 4)
end
I.ach_legend = function(P)
    P:with(0, 8, 0.9, sym_brush)
    sparkle(P, 76, 22, 14); sparkle(P, 92, 46, 8); sparkle(P, 52, 12, 6)
end

-- biểu tượng chung
I.star = function(P) starPoly(P, 50, 54, 46, 19) end
I.flame = flame
I.book = sym_book
I.skull = skull
I.clock = function(P)
    P:ring(50, 50, 44, 8)
    P:line(50, 50, 50, 24, 6); P:line(50, 50, 69, 60, 6)
    P:circle(50, 50, 6)
end
I.monster1 = function(P) monster(P, 1) end
I.monster2 = function(P) monster(P, 2) end
I.monster3 = function(P) monster(P, 3) end

-- độ hiếm
I.rar_common = function(P) P:ring(50, 50, 36, 9); P:circle(50, 50, 11) end
I.rar_rare = function(P)
    P:poly({ 50, 8, 90, 50, 50, 92, 10, 50 })
    P:poly({ 50, 26, 72, 50, 50, 74, 28, 50 }, "w")
end
I.rar_epic = function(P)
    P:poly({ 50, 8, 90, 50, 50, 92, 10, 50 })
    P:line(10, 50, 90, 50, 3.5, "w")
    P:line(50, 8, 30, 50, 3.5, "w"); P:line(50, 8, 70, 50, 3.5, "w")
    P:line(30, 50, 50, 92, 3.5, "w"); P:line(70, 50, 50, 92, 3.5, "w")
end
I.rar_legend = function(P)
    P:ring(50, 50, 46, 4)
    starPoly(P, 50, 54, 36, 15)
end

-- giao diện
I.lock = function(P)
    P:ring(50, 38, 20, 8)
    P:rect(24, 44, 52, 42)
    P:circle(50, 62, 6, "w"); P:rect(47, 62, 6, 14, "w")
end
I.gear = function(P)
    for i = 0, 7 do
        local a = i * math.pi / 4
        P:line(50 + 29 * math.cos(a), 50 + 29 * math.sin(a),
               50 + 43 * math.cos(a), 50 + 43 * math.sin(a), 14)
    end
    P:ring(50, 50, 35, 14)
end
I.trophy = function(P)
    P:ring(22, 30, 13, 5); P:ring(78, 30, 13, 5)
    P:poly({ 24, 12, 76, 12, 70, 46, 58, 60, 42, 60, 30, 46 })
    P:rect(44, 58, 12, 16); P:rect(30, 74, 40, 10); P:rect(22, 84, 56, 7)
    P:line(38, 22, 38, 40, 4, "w")
end
I.chest = function(P)
    P:rect(10, 46, 80, 42)
    P:ellipse(50, 48, 40, 24)
    P:line(10, 56, 90, 56, 3.5, "w")
    P:rect(41, 52, 18, 20, "w")
    P:circle(50, 60, 4); P:rect(48, 60, 4, 8)
end
I.bulb = function(P)
    P:ring(50, 42, 23, 6)
    for _, d in ipairs({ -150, -120, -90, -60, -30 }) do
        local a = d * math.pi / 180
        P:line(50 + 31 * math.cos(a), 42 + 31 * math.sin(a),
               50 + 41 * math.cos(a), 42 + 41 * math.sin(a), 4.5)
    end
    P:poly({ 36, 62, 64, 62, 60, 78, 40, 78 })
    P:rect(40, 80, 20, 6); P:rect(44, 88, 12, 6)
    P:line(44, 44, 50, 54, 3.5); P:line(50, 54, 56, 44, 3.5)
end
I.back = function(P)
    P:line(64, 18, 34, 50, 10); P:line(34, 50, 64, 82, 10)
end
I.close = function(P)
    P:line(22, 22, 78, 78, 10); P:line(78, 22, 22, 78, 10)
end
I.plus = function(P) P:rect(12, 42, 76, 16); P:rect(42, 12, 16, 76) end
I.minus = function(P) P:rect(12, 42, 76, 16) end

local Icons = { COL = COL, Painter = Painter, defs = I }

function Icons.has(name) return I[name] ~= nil end

function Icons.draw(bb, name, x, y, size, mono)
    local f = I[name]
    if not f then return end
    local P = Painter:new(bb, x, y, size, mono)
    f(P)
end

return Icons
