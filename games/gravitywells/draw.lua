-- Gravity Wells rendering: the system view (spinning star, dotted orbits,
-- planets with distinct surface squiggles), the side-view mission (terrain,
-- bunkers, tanks, reactor, tractor beam), and the Beams HUD.

local gfx <const> = playdate.graphics

Draw = {}

local clamp = Util.clamp

local SHIP <const> = Shapes.new({
    { 8, 0, -6, -5, -3.5, 0, -6, 5, 8, 0 },
})
local FLAME <const> = Shapes.new({
    { -4, -2.5, -9, 0, -4, 2.5 },
})

local STAR_OUT <const> = Shapes.gon(C.STAR_R + 4, 14, C.STAR_R - 4)
local STAR_IN <const> = Shapes.gon(6, 8)

local function circlePts(cx, cy, r, n)
    local poly = {}
    for i = 0, n do
        local a = i / n * 2 * math.pi
        poly[#poly + 1] = cx + math.cos(a) * r
        poly[#poly + 1] = cy + math.sin(a) * r
    end
    return poly
end

-- one distinct surface squiggle per planet kind
local SQUIG <const> = {
    -- 1: zigzag mountain band
    Shapes.new({ { -11, 4, -6, -3, -2, 3, 3, -4, 8, 2, 11, -1 } }),
    -- 2: twin craters
    Shapes.new({ circlePts(-5, -4, 3.5, 8), circlePts(4, 4, 2.5, 8) }),
    -- 3: latitude stripes
    Shapes.new({ { -13, -6, 10, -6 }, { -15, 0, 15, 0 }, { -10, 6, 13, 6 } }),
    -- 4: spiral storm
    (function()
        local poly = {}
        for i = 0, 12 do
            local a = i * 0.55
            local r = 1.5 + i * 0.95
            poly[#poly + 1] = math.cos(a) * r
            poly[#poly + 1] = math.sin(a) * r
        end
        return Shapes.new({ poly })
    end)(),
}

local ARROW <const> = Shapes.new({
    { 0, 4, 0, -4 }, { -3, -1, 0, -4, 3, -1 },
})

local BUNKER <const> = Shapes.new({
    { -8, 0, -5, -7, 5, -7, 8, 0, -8, 0 },
    { 0, -7, 0, -11 },
    { -2, -11, 2, -11 },
})

local TANK <const> = Shapes.new({
    { -4, 0, -4, -6, -2, -9, 2, -9, 4, -6, 4, 0, -4, 0 },
    { -4, -6, 4, -6 },
})

local REACTOR_OUT <const> = Shapes.gon(8, 4)
local REACTOR_IN <const> = Shapes.gon(4.5, 4)

local function drawShip(ox)
    local s = G.ship
    if not s or not s.alive then return end
    if s.invuln > 0 and Attract.frame % 4 < 2 then return end
    Shapes.draw(SHIP, s.x + ox, s.y, s.angle)
    if s.thrusting and Attract.frame % 2 == 0 then
        Shapes.draw(FLAME, s.x + ox, s.y, s.angle)
    end
end

local function drawShots(ox)
    for _, b in ipairs(G.shots) do
        gfx.fillRect(b.x + ox - 1, b.y - 1, 2, 2)
    end
end

-- ---------------------------------------------------------------- system

function Draw.system(withShip)
    -- dotted orbit rings
    for _, p in ipairs(G.planets) do
        for a = 0, 350, 12 do
            local r = math.rad(a)
            gfx.drawPixel(C.STAR_X + math.cos(r) * p.orbitR,
                C.STAR_Y + math.sin(r) * p.orbitR)
        end
    end

    -- the star, spinning both ways
    Shapes.draw(STAR_OUT, C.STAR_X, C.STAR_Y, Attract.frame * 1.1)
    Shapes.draw(STAR_IN, C.STAR_X, C.STAR_Y, -Attract.frame * 2.3)

    for _, p in ipairs(G.planets) do
        Shapes.draw(p.ring, p.x, p.y, 0)
        if p.cleared then
            -- husk: outline only, a dead dot at the core
            gfx.fillRect(p.x - 1, p.y - 1, 2, 2)
        else
            Shapes.draw(SQUIG[p.kind], p.x, p.y, 0)
            if p.revGrav and G.system >= 2 then
                Shapes.draw(ARROW, p.x, p.y - p.r - 8, 0)
            end
        end
    end

    if withShip then
        drawShip(0)
        drawShots(0)
    end
end

-- --------------------------------------------------------------- mission

function Draw.mission()
    local m = G.m
    if not m then return end
    local ox = -G.camX
    local lo, hi = G.camX - 2, G.camX + Field.W + 2

    -- terrain
    local pts = m.pts
    for i = 3, #pts - 1, 2 do
        local x0, x1 = pts[i - 2], pts[i]
        if x1 >= lo and x0 <= hi then
            gfx.drawLine(x0 + ox, pts[i - 1], x1 + ox, pts[i + 1])
        end
    end

    -- the way out: a dotted ceiling line
    if Attract.frame % 2 == 0 or m.defDown or m.reactorT then
        for x = 4, Field.W - 4, 12 do
            gfx.drawPixel(x, 6)
        end
    end

    for _, b in ipairs(m.bunkers) do
        if b.alive and b.x >= lo and b.x <= hi then
            Shapes.draw(BUNKER, b.x + ox, b.y, 0)
        end
    end
    for _, t in ipairs(m.tanks) do
        if t.alive and t.x >= lo and t.x <= hi then
            Shapes.draw(TANK, t.x + ox, t.y, 0)
        end
    end

    local r = m.reactor
    if r.x >= lo and r.x <= hi then
        if not (m.reactorT and Attract.frame % 4 < 2) then
            Shapes.draw(REACTOR_OUT, r.x + ox, r.y, Attract.frame * 2)
            Shapes.draw(REACTOR_IN, r.x + ox, r.y, -Attract.frame * 4)
        end
    end

    for _, e in ipairs(m.eshots) do
        gfx.fillRect(e.x + ox - 1, e.y - 1, 2, 2)
    end

    -- tractor beam
    local s = G.ship
    if m.beamOn and s and s.alive then
        local bx = s.x + ox
        gfx.drawLine(bx - 2, s.y + 4, bx - C.BEAM_HALF_W, s.y + C.BEAM_LEN)
        gfx.drawLine(bx + 2, s.y + 4, bx + C.BEAM_HALF_W, s.y + C.BEAM_LEN)
        if Attract.frame % 2 == 0 then
            gfx.drawLine(bx - C.BEAM_HALF_W, s.y + C.BEAM_LEN,
                bx + C.BEAM_HALF_W, s.y + C.BEAM_LEN)
        end
    end

    drawShip(ox)
    drawShots(ox)

    if m.reactorT and Attract.frame % 8 < 6 then
        Beams.print("ESCAPE " .. math.ceil(m.reactorT), Field.W / 2, 26, 12,
            { align = "center", weight = 2 })
    end
end

-- ------------------------------------------------------------------- HUD

local function fuelBar(x, y)
    local w, h = 72, 7
    gfx.drawRect(x, y, w, h)
    local fill = math.floor(clamp(G.fuel / C.FUEL_MAX, 0, 1) * (w - 2))
    if fill > 0 and not (G.fuel < 25 and Attract.frame % 8 < 4) then
        gfx.fillRect(x + 1, y + 1, fill, h - 2)
    end
    Beams.print("FUEL", x + w + 6, y, 6)
end

function Draw.hud()
    Beams.print(tostring(G.score), 10, 8, 12, { weight = 1 })
    Beams.print("SYS " .. G.system, Field.W / 2, 8, 8, { align = "center" })
    for i = 1, math.min(G.ships, 8) do
        Shapes.draw(SHIP, Field.W - 14 * i, 14, -90, 0.8)
    end
    fuelBar(10, 26)
end

function Draw.play()
    if G.view == "system" then
        Draw.system(true)
    else
        Draw.mission()
    end
    Draw.hud()
    if G.msg then
        Beams.print(G.msg, Field.W / 2, 62, 10, { align = "center", weight = 1 })
    end
end

-- the title screen's backdrop: the system turning over, no ship
function Draw.ambient()
    Draw.system(false)
end
