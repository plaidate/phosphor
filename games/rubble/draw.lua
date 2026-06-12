-- Rubble rendering: library shapes and beam text.

local gfx <const> = playdate.graphics

Draw = {}

local SHIP <const> = Shapes.new({
    { 8, 0, -6, -5, -3.5, 0, -6, 5, 8, 0 },
})
local FLAME <const> = Shapes.new({
    { -4, -2.5, -9, 0, -4, 2.5 },
})
local SAUCER <const> = Shapes.new({
    { -10, 0, 10, 0 },
    { -10, 0, -4.5, -5, 4.5, -5, 10, 0, 4.5, 5, -4.5, 5, -10, 0 },
    { -3, -5, -1.8, -9, 1.8, -9, 3, -5 },
})

function Draw.ship()
    local ship = G.ship
    if not ship or not ship.alive then return end
    if ship.invuln > 0 and Attract.frame % 4 < 2 then return end
    Shapes.drawWrapped(SHIP, ship.x, ship.y, ship.angle, 1, 10)
    if ship.thrusting and Attract.frame % 2 == 0 then
        Shapes.drawWrapped(FLAME, ship.x, ship.y, ship.angle, 1, 10)
    end
end

function Draw.rocks()
    for _, r in ipairs(G.rocks) do
        Shapes.drawWrapped(r.shape, r.x, r.y, r.angle, 1, r.r + 4)
    end
end

function Draw.saucer()
    local s = G.saucer
    if not s then return end
    Shapes.draw(SAUCER, s.x, s.y, 0, s.r / 10)
end

function Draw.shots()
    for _, b in ipairs(G.shots) do
        gfx.fillRect(b.x - 1, b.y - 1, 2, 2)
    end
    for _, b in ipairs(G.saucerShots) do
        gfx.fillRect(b.x - 1, b.y - 1, 2, 2)
    end
end

function Draw.hud()
    Beams.print(tostring(G.score), 10, 8, 12, { weight = 1 })
    Beams.print(tostring(Attract.high), Field.W / 2, 8, 8, { align = "center" })
    for i = 1, math.min(G.lives, 8) do
        Shapes.draw(SHIP, Field.W - 14 * i, 14, -90, 0.9)
    end
end

function Draw.play()
    Draw.rocks()
    Draw.saucer()
    Draw.ship()
    Draw.shots()
    Draw.hud()
end

-- the title screen's drifting backdrop
function Draw.ambient()
    Draw.rocks()
end
