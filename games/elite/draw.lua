-- Elite rendering: the wireframe space view up top, the dashboard below.

local gfx <const> = playdate.graphics

Draw = {}

local CX <const> = 200
local VIEW_H <const> = C.VIEW_H

-- a sky of stars, kept as unit directions and spun with the universe so the
-- view has a sense of motion even in empty space
local stars = {}
local function initStars()
    stars = {}
    for _ = 1, 40 do
        local a = math.random() * math.pi * 2
        local z = math.random() * 2 - 1
        local r = math.sqrt(1 - z * z)
        stars[#stars + 1] = { x = r * math.cos(a), y = r * math.sin(a), z = z }
    end
end
initStars()

local function spinStars(R)
    for _, s in ipairs(stars) do
        s.x, s.y, s.z = Mat.mulVec(R, s.x, s.y, s.z)
    end
end

local function drawStars()
    local D = 8000
    for _, s in ipairs(stars) do
        if s.z > 0.05 then
            local sx, sy = Proj.point(s.x * D, s.y * D, s.z * D)
            if sx and sy < VIEW_H then gfx.drawPixel(sx, sy) end
        end
    end
end

local function len3(x, y, z) return math.sqrt(x * x + y * y + z * z) end

-- corner brackets around whatever sits in the reticle (the locked target)
local function drawLock()
    local best, bz = nil, math.huge
    for _, o in ipairs(G.objs) do
        if o.kind ~= "station" and o.pos.z > 0 and o.pos.z < bz then
            local sx, sy = Proj.point(o.pos.x, o.pos.y, o.pos.z)
            if sx then
                local dx, dy = sx - Proj.cx, sy - Proj.cy
                if dx * dx + dy * dy < C.LASER_HIT_PX * C.LASER_HIT_PX then
                    best, bz = { sx, sy }, o.pos.z
                end
            end
        end
    end
    if best then
        local x, y, s = best[1], best[2], 10
        for _, c in ipairs({ { -1, -1 }, { 1, -1 }, { -1, 1 }, { 1, 1 } }) do
            gfx.drawLine(x + c[1] * s, y + c[2] * s, x + c[1] * s, y + c[2] * (s - 4))
            gfx.drawLine(x + c[1] * s, y + c[2] * s, x + c[1] * (s - 4), y + c[2] * s)
        end
    end
end

local function drawReticle()
    gfx.drawLine(CX - 12, Proj.cy, CX - 4, Proj.cy)
    gfx.drawLine(CX + 4, Proj.cy, CX + 12, Proj.cy)
    gfx.drawLine(CX, Proj.cy - 12, CX, Proj.cy - 4)
    gfx.drawLine(CX, Proj.cy + 4, CX, Proj.cy + 12)
end

-- the sun (bright disc) and planet (wireframe globe), a far backdrop
local function drawBody(dir, fill)
    if dir.z <= 0.06 then return end
    local D, Rb = 12000, fill and 2400 or 2200
    local sx, sy = Proj.point(dir.x * D, dir.y * D, dir.z * D)
    if not sx then return end
    local r = Proj.focal * Rb / D
    if fill then
        gfx.fillCircleAtPoint(sx, sy, r)
    else
        gfx.drawCircleAtPoint(sx, sy, r)
        gfx.drawLine(sx - r, sy, sx + r, sy)
        gfx.drawLine(sx, sy - r, sx, sy + r)
    end
end

local function drawScene()
    gfx.setClipRect(1, 1, 398, VIEW_H - 1)
    drawStars()
    if G.sunDir then drawBody(G.sunDir, true) end
    if G.planetDir then drawBody(G.planetDir, false) end
    for _, o in ipairs(G.objs) do
        if o.pos.z > -o.r then
            local d = len3(o.pos.x, o.pos.y, o.pos.z)
            if d < 13000 then
                local s = Ships[o.mesh]
                if o.hitT then gfx.setLineWidth(2) end
                Proj.mesh(s.verts, s.edges, o.pos, o.m, 1)
                if o.hitT then gfx.setLineWidth(1) end
            end
        end
    end
    -- our own laser bolts, fired from the lower corners toward the reticle
    if G.laserT > 0 then
        gfx.drawLine(60, VIEW_H - 2, CX, Proj.cy)
        gfx.drawLine(340, VIEW_H - 2, CX, Proj.cy)
    end
    drawLock()
    drawReticle()
    gfx.clearClipRect()
end

-- The dashboard follows the original Elite panel (see newkind/scanner.bmp):
-- left bank FS AS FU CT LT AL, centre the elliptical scanner, right bank
-- SP RL DC and the four energy banks, with a compass to the station.

local GW <const> = 58   -- gauge bar width
local GH <const> = 5    -- gauge bar height
local LX <const> = 26   -- where the left/right bar starts after its 2-char label

-- a labelled gauge filled left-to-right (frac 0..1)
local function gauge(label, x, y, frac)
    Beams.print(label, x, y - 1, 7)
    local bx = x + LX
    gfx.drawRect(bx, y, GW, GH)
    local f = math.max(0, math.min(1, frac))
    if f > 0 then gfx.fillRect(bx + 1, y + 1, math.floor((GW - 2) * f), GH - 2) end
end

-- a centre-zero indicator (roll/pitch): a block that slides from the middle
local function gaugeC(label, x, y, val)
    Beams.print(label, x, y - 1, 7)
    local bx = x + LX
    gfx.drawRect(bx, y, GW, GH)
    local mid = bx + GW / 2
    local v = math.max(-1, math.min(1, val))
    local px = mid + v * (GW / 2 - 2)
    gfx.fillRect(math.min(mid, px), y + 1, math.max(2, math.abs(px - mid)), GH - 2)
end

local function drawScanner()
    local ox, oy, rx, ry = 200, 206, 86, 22
    gfx.drawEllipseInRect(ox - rx, oy - ry, rx * 2, ry * 2)
    gfx.drawEllipseInRect(ox - rx * 0.5, oy - ry * 0.5, rx, ry)
    gfx.drawLine(ox - rx, oy, ox + rx, oy)
    gfx.drawLine(ox, oy - ry, ox, oy + ry)
    local range = C.SCANNER_RANGE
    for _, o in ipairs(G.objs) do
        local d = len3(o.pos.x, o.pos.y, o.pos.z)
        if d < range then
            local nx = math.max(-1, math.min(1, o.pos.x / range))
            local nz = math.max(-1, math.min(1, o.pos.z / range))
            local bx = ox + nx * rx
            local by = oy - nz * ry
            local stalk = math.max(-1, math.min(1, o.pos.y / range)) * 18
            gfx.drawLine(bx, by, bx, by - stalk)
            if o.kind == "station" then
                gfx.drawRect(bx - 2, by - stalk - 2, 4, 4)
            else
                local m = (o.kind == "pirate") and 2 or 1
                gfx.fillRect(bx - m / 2, by - stalk - m / 2, m, m)
            end
        end
    end
end

-- compass dot showing the bearing to the station (filled = ahead, hollow = behind)
local function drawCompass()
    local cx, cy, r = 300, 178, 11
    gfx.drawEllipseInRect(cx - r, cy - r, r * 2, r * 2)
    if not G.station then return end
    local p = G.station.pos
    local l = len3(p.x, p.y, p.z)
    if l < 1 then return end
    local dx = math.max(-1, math.min(1, p.x / l))
    local dy = math.max(-1, math.min(1, p.y / l))
    local px, py = cx + dx * (r - 2), cy - dy * (r - 2)
    if p.z >= 0 then
        gfx.fillRect(px - 1.5, py - 1.5, 3, 3)
    else
        gfx.drawRect(px - 1, py - 1, 2, 2)
    end
end

function Draw.play()
    -- spin the starfield by the same rotation the world used this frame
    spinStars(Mat.mul(Mat.rx(-G.pitch * C.DT), Mat.rz(-G.roll * C.DT)))
    drawScene()

    -- HUD text over the view: system/rating left, score right
    Beams.print((G.sysName or ""):upper(), 5, 4, 8)
    Beams.print(G.rating(), 5, 15, 7)
    Beams.print("" .. G.score, 395, 4, 9, { align = "right" })
    if G.message then
        Beams.print(G.message, CX, 150, 8, { align = "center" })
    end

    -- dashboard
    gfx.drawLine(1, VIEW_H, 399, VIEW_H)
    local shF = G.shield / C.SHIELD_MAX
    local L = 167
    gauge("FS", 6, L, shF)
    gauge("AS", 6, L + 12, shF)
    gauge("FU", 6, L + 24, (G.fuel or C.FUEL_MAX) / C.FUEL_MAX)
    gauge("CT", 6, L + 36, G.cabinTemp or 0.12)
    gauge("LT", 6, L + 48, G.laserHeat / C.LASER_MAX_HEAT)
    gauge("AL", 6, L + 60, G.altitude or 1)

    local R, rx = 164, 318
    gauge("SP", rx, R, G.speed / C.SPEED_MAX)
    gaugeC("RL", rx, R + 11, G.roll / C.ROLL_RATE)
    gaugeC("DC", rx, R + 22, G.pitch / C.PITCH_RATE)
    -- four energy banks fill in sequence from the total energy
    local etot = G.energy / C.ENERGY_MAX * 4
    for k = 1, 4 do
        gauge("E" .. k, rx, R + 22 + k * 11, math.max(0, math.min(1, etot - (k - 1))))
    end

    drawScanner()
    drawCompass()

    -- struck: flash a heavy border around the view
    if G.hitFlash and G.hitFlash > 0 then
        gfx.setLineWidth(3)
        gfx.drawRect(2, 2, 396, VIEW_H - 4)
        gfx.setLineWidth(1)
    end
end

-- attract background: a lone ship turning against the stars
local ambM = Mat.identity()
function Draw.ambient()
    ambM = Mat.spinY(Mat.spinX(ambM, 0.004), 0.011)
    gfx.setClipRect(1, 1, 398, 200)
    -- drift the starfield slowly
    spinStars(Mat.ry(0.002))
    drawStars()
    Proj.mesh(Ships.cobra.verts, Ships.cobra.edges, { x = 0, y = 0, z = 360 }, ambM, 1)
    gfx.clearClipRect()
end
