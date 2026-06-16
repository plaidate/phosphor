-- Open Geometry Wars rendering. The warping grid is drawn faint (a 50%
-- pattern) so the bright 2px combat layer reads over it; enemies are simple
-- spinning vector glyphs.

local gfx <const> = playdate.graphics

Draw = {}

local SHIP <const> = Shapes.new({
    { 9, 0, -6, -6, -3, 0, -6, 6, 9, 0 },
})

local GLYPH = {
    grunt   = Shapes.gon(8, 4),          -- diamond
    wander  = Shapes.gon(8, 4),          -- square (drawn at 45°)
    spinner = Shapes.gon(9, 10, 4),      -- five-point star
    tiny    = Shapes.gon(6, 6, 2.5),     -- small burr
    weaver  = Shapes.gon(7, 6),          -- hexagon
    proton  = Shapes.gon(4, 8),          -- bright dot
}

-- grey 50% pattern for the background lattice
local GRID_PAT <const> = { 0xAA, 0x55, 0xAA, 0x55, 0xAA, 0x55, 0xAA, 0x55 }

local function drawEnemy(e)
    if e.warn > 0 then
        -- telegraph: a shrinking, flashing diamond that closes on the spawn
        if Attract.frame % 4 < 2 then return end
        local rad = e.r + e.warn * 40
        gfx.setLineWidth(1)
        Shapes.draw(GLYPH[e.kind] or GLYPH.grunt, e.x, e.y, 0, rad / e.r)
        return
    end
    gfx.setLineWidth(2)
    local k = e.kind
    if k == "hole" then
        local r = e.r + math.sin(e.anim) * 3
        gfx.drawCircleAtPoint(e.x, e.y, r)
        gfx.drawCircleAtPoint(e.x, e.y, r * 0.55)
        -- swirling spokes
        for i = 0, 3 do
            local a = e.anim + i * 1.57
            gfx.drawLine(e.x, e.y, e.x + math.cos(a) * r, e.y + math.sin(a) * r)
        end
    elseif k == "grunt" then
        local s = 1 + 0.18 * math.sin(e.anim * 3)
        Shapes.draw(GLYPH.grunt, e.x, e.y, math.deg(e.anim) * 0.5, s)
    elseif k == "wander" then
        Shapes.draw(GLYPH.wander, e.x, e.y, math.deg(e.anim) + 45, 1)
    elseif k == "spinner" then
        Shapes.draw(GLYPH.spinner, e.x, e.y, math.deg(e.anim) * 1.4, 1)
    elseif k == "tiny" then
        Shapes.draw(GLYPH.tiny, e.x, e.y, math.deg(e.anim) * 2, 1)
    elseif k == "weaver" then
        Shapes.draw(GLYPH.weaver, e.x, e.y, math.deg(e.anim), 1)
    elseif k == "proton" then
        Shapes.draw(GLYPH.proton, e.x, e.y, math.deg(e.anim), 1)
    end
end

function Draw.grid()
    gfx.setPattern(GRID_PAT)
    gfx.setLineWidth(1)
    Grid.draw()
    gfx.setColor(gfx.kColorWhite)
end

function Draw.geoms()
    gfx.setLineWidth(1)
    for _, gm in ipairs(G.geoms) do
        Shapes.draw(Shapes.gon(C.GEOM_R, 4), gm.x, gm.y, gm.spin, 1)
    end
end

function Draw.enemies()
    for _, e in ipairs(G.enemies) do drawEnemy(e) end
    gfx.setLineWidth(1)
end

function Draw.shots()
    for _, b in ipairs(G.shots) do
        local lx, ly = Vec.norm(b.vx, b.vy)
        gfx.setLineWidth(2)
        gfx.drawLine(b.x, b.y, b.x - lx * 5, b.y - ly * 5)
    end
    gfx.setLineWidth(1)
end

function Draw.ship()
    local s = G.ship
    if not s or not s.alive then return end
    if s.invuln > 0 and Attract.frame % 4 < 2 then
        -- still draw the shield ring while blinking the hull off
    else
        gfx.setLineWidth(2)
        Shapes.draw(SHIP, s.x, s.y, s.aim, 1)
        gfx.setLineWidth(1)
    end
    if s.invuln > 0 then
        gfx.drawCircleAtPoint(s.x, s.y, C.SHIP_R + 4)
    end
end

function Draw.bomb()
    local w = G.bombWave
    if not w then return end
    gfx.setLineWidth(2)
    gfx.drawCircleAtPoint(w.x, w.y, w.r)
    gfx.setLineWidth(1)
end

function Draw.hud()
    Beams.print(tostring(G.score), 8, 6, 12, { weight = 1 })
    if G.mult > 1 then
        Beams.print("X" .. G.mult, 8, 22, 9)
    end
    Beams.print("HIGH " .. Attract.high, Field.W / 2, 6, 8, { align = "center" })
    Beams.print("LIVES " .. G.lives, Field.W - 8, 6, 8, { align = "right" })
    Beams.print("BOMB " .. G.bombs, Field.W - 8, 18, 8, { align = "right" })
end

function Draw.play()
    Draw.grid()
    Draw.geoms()
    Draw.bomb()
    Draw.enemies()
    Draw.shots()
    Draw.ship()
    Draw.hud()
end

-- title/game-over backdrop: the live, drifting grid and wandering glyphs
function Draw.ambient()
    Draw.grid()
    Draw.enemies()
end
