-- Ringkeep rendering: the spinning keep, its hunters, and beam text.

local gfx <const> = playdate.graphics

Draw = {}

local SHIP <const> = Shapes.new({
    { 8, 0, -6, -5, -3.5, 0, -6, 5, 8, 0 },
})
local FLAME <const> = Shapes.new({
    { -4, -2.5, -9, 0, -4, 2.5 },
})
local CORE <const> = Shapes.gon(C.CORE_R, 6)
local TURRET <const> = Shapes.new({
    { C.CORE_R - 2, 0, C.CORE_R + 5, 0 },
})
local FIREBALL <const> = Shapes.gon(C.FB_R, 8, C.FB_R * 0.45)
local MINE <const> = Shapes.new({
    { C.MINE_R, 0, 0, -C.MINE_R, -C.MINE_R, 0, 0, C.MINE_R, C.MINE_R, 0 },
    { -C.MINE_R, 0, C.MINE_R, 0 },
    { 0, -C.MINE_R, 0, C.MINE_R },
})

local SEG_ARC <const> = 360 / C.RING_SEGS
local SEG_GAP <const> = 3 -- degrees trimmed off each end, so segments read
local SEG_STEPS <const> = 4

local function drawRing(ring)
    if ring.alive == 0 then return end
    for i = 1, C.RING_SEGS do
        if ring.segs[i] then
            local a0 = ring.rot + (i - 1) * SEG_ARC + SEG_GAP
            local a1 = ring.rot + i * SEG_ARC - SEG_GAP
            local px, py
            for st = 0, SEG_STEPS do
                local a = math.rad(a0 + (a1 - a0) * st / SEG_STEPS)
                local x = C.CX + math.cos(a) * ring.r
                local y = C.CY + math.sin(a) * ring.r
                if px then gfx.drawLine(px, py, x, y) end
                px, py = x, y
            end
        end
    end
end

function Draw.keep()
    for _, ring in ipairs(G.rings) do
        drawRing(ring)
    end
    Shapes.draw(CORE, C.CX, C.CY, Attract.frame * 1.5)
    Shapes.draw(TURRET, C.CX, C.CY, G.coreAim)
end

function Draw.ship()
    local ship = G.ship
    if not ship or not ship.alive then return end
    if ship.invuln > 0 and Attract.frame % 4 < 2 then return end
    Shapes.drawWrapped(SHIP, ship.x, ship.y, ship.angle, 1, 10)
    if ship.thrusting and Attract.frame % 2 == 0 then
        Shapes.drawWrapped(FLAME, ship.x, ship.y, ship.angle, 1, 10)
    end
end

function Draw.hunters()
    local f = G.fireball
    if f then
        Shapes.drawWrapped(FIREBALL, f.x, f.y, f.spin, 1, C.FB_R + 2)
    end
    for _, m in ipairs(G.mines) do
        if m.state ~= "dead" then
            Shapes.drawWrapped(MINE, m.x, m.y, m.drawAng, 1, C.MINE_R + 2)
        end
    end
end

function Draw.shots()
    for _, b in ipairs(G.shots) do
        gfx.fillRect(b.x - 1, b.y - 1, 2, 2)
    end
end

function Draw.hud()
    Beams.print(tostring(G.score), 10, 8, 12, { weight = 1 })
    Beams.print(tostring(Attract.high), Field.W / 2, 8, 8, { align = "center" })
    for i = 1, math.min(G.lives, C.MAX_LIVES) do
        Shapes.draw(SHIP, Field.W - 14 * i, 14, -90, 0.9)
    end
    Beams.print("WAVE " .. G.wave, 10, Field.H - 16, 7)
end

function Draw.play()
    Draw.keep()
    Draw.hunters()
    Draw.ship()
    Draw.shots()
    Draw.hud()
end

-- the title screen's backdrop: the keep, turning over in the dark
function Draw.ambient()
    Draw.keep()
end
