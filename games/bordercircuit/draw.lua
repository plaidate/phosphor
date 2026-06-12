-- Border Circuit rendering: the track, the HUD living inside the central
-- barrier like the cabinet's scoreboard, and every beam-drawn entity.

local gfx <const> = playdate.graphics

Draw = {}

local A <const> = C.ARENA
local B <const> = C.BAR

local SHIP <const> = Shapes.new({
    { 8, 0, -6, -5, -3.5, 0, -6, 5, 8, 0 },
})
local FLAME <const> = Shapes.new({
    { -4, -2.5, -9, 0, -4, 2.5 },
})
-- the drones are diamonds, with a cockpit strut
local DRONE <const> = Shapes.new({
    { 9, 0, 0, -6, -9, 0, 0, 6, 9, 0 },
    { -3, -4, -3, 4 },
})
-- the layers are slow pods with a tail dispenser
local LAYER <const> = Shapes.new({
    { 9, 0, 4, -6, -7, -5, -7, 5, 4, 6, 9, 0 },
    { -7, -2, -11, 0, -7, 2 },
})
local MINE <const> = Shapes.gon(C.MINE_R, 8, C.MINE_R * 0.45)

function Draw.track()
    gfx.drawRect(A.x1, A.y1, A.x2 - A.x1, A.y2 - A.y1)
    gfx.drawRect(B.x1, B.y1, B.x2 - B.x1, B.y2 - B.y1)
    gfx.drawRect(B.x1 + 3, B.y1 + 3, B.x2 - B.x1 - 6, B.y2 - B.y1 - 6)
end

function Draw.ship()
    local s = G.ship
    if not s or not s.alive then return end
    if s.invuln > 0 and Attract.frame % 4 < 2 then return end
    Shapes.draw(SHIP, s.x, s.y, s.angle)
    if s.thrusting and Attract.frame % 2 == 0 then
        Shapes.draw(FLAME, s.x, s.y, s.angle)
    end
end

function Draw.drones()
    for _, d in ipairs(G.drones) do
        Shapes.draw(DRONE, d.x, d.y, Vec.angleOf(d.vx, d.vy))
    end
end

function Draw.layers()
    for _, l in ipairs(G.layers) do
        Shapes.draw(LAYER, l.x, l.y, Vec.angleOf(l.vx, l.vy))
    end
end

function Draw.mines()
    for _, m in ipairs(G.mines) do
        if m.armT > 0 then
            -- still arming: small and blinking
            if Attract.frame % 4 < 2 then
                Shapes.draw(MINE, m.x, m.y, 0, 0.6)
            end
        else
            Shapes.draw(MINE, m.x, m.y, Attract.frame * 3)
        end
    end
end

function Draw.shots()
    for _, b in ipairs(G.shots) do
        gfx.fillRect(b.x - 1, b.y - 1, 2, 2)
    end
    for _, b in ipairs(G.eshots) do
        gfx.fillRect(b.x - 1, b.y - 1, 2, 2)
    end
end

-- the scoreboard lives inside the barrier, cabinet-style
function Draw.hud()
    local cx = (B.x1 + B.x2) / 2
    Beams.print("HIGH " .. Attract.high, cx, 87, 7, { align = "center" })
    Beams.print(tostring(G.score), cx, 98, 15, { align = "center", weight = 2 })
    local n = math.min(G.lives, 6)
    for i = 1, n do
        Shapes.draw(SHIP, cx + (i - (n + 1) / 2) * 16, 126, -90, 0.8)
    end
    Beams.print("WAVE " .. G.wave, cx, 140, 8, { align = "center" })
end

function Draw.play()
    Draw.track()
    Draw.hud()
    Draw.mines()
    Draw.drones()
    Draw.layers()
    Draw.ship()
    Draw.shots()
end

-- the title screen's backdrop: drones lapping the empty track
function Draw.ambient()
    Draw.drones()
end
