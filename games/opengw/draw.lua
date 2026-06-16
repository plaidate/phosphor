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
    snake   = Shapes.new({ { 8, 0, -4, -5, -4, 5, 8, 0 } }), -- chevron head
}

local GRID_PAT <const> = { 0xAA, 0x55, 0xAA, 0x55, 0xAA, 0x55, 0xAA, 0x55 }

local function drawEnemy(e)
    if e.warn > 0 then
        if Attract.frame % 4 < 2 then return end
        gfx.setLineWidth(1)
        local g = GLYPH[e.kind] or GLYPH.grunt
        Shapes.draw(g, e.x, e.y, 0, (e.r + e.warn * 40) / e.r)
        return
    end
    gfx.setLineWidth(2)
    local k = e.kind
    if k == "hole" then
        local r = e.r + math.sin(e.anim) * 3
        gfx.drawCircleAtPoint(e.x, e.y, r)
        gfx.drawCircleAtPoint(e.x, e.y, r * 0.55)
        for i = 0, 3 do
            local a = e.anim + i * 1.57
            gfx.drawLine(e.x, e.y, e.x + math.cos(a) * r, e.y + math.sin(a) * r)
        end
    elseif k == "grunt" then
        Shapes.draw(GLYPH.grunt, e.x, e.y, math.deg(e.anim) * 0.5, 1 + 0.18 * math.sin(e.anim * 3))
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
    elseif k == "mayfly" then
        -- flapping wings: two strokes whose angle oscillates
        local face = Vec.angleOf(e.vx, e.vy)
        local flap = (e.wing == 1) and 22 or 52
        for _, sgn in ipairs({ -1, 1 }) do
            local wx, wy = Vec.fromAngle(face + sgn * flap, 9)
            gfx.drawLine(e.x, e.y, e.x + wx, e.y + wy)
            local tx, ty = Vec.fromAngle(face + sgn * (flap + 30), 6)
            gfx.drawLine(e.x + wx, e.y + wy, e.x + wx * 0.4 + tx, e.y + wy * 0.4 + ty)
        end
    elseif k == "snake" then
        for j = C.SNAKE.segs, 1, -1 do
            local p = e.trail[j * C.SNAKE.seglag]
            if p then
                local rad = e.r * 0.7 * (1 - j / (C.SNAKE.segs + 4))
                gfx.drawCircleAtPoint(p.x, p.y, math.max(2, rad))
            end
        end
        Shapes.draw(GLYPH.snake, e.x, e.y, Vec.angleOf(e.vx, e.vy), 1)
    elseif k == "repulsor" then
        gfx.drawCircleAtPoint(e.x, e.y, e.r)
        -- facing prong
        local fx, fy = Vec.fromAngle(e.facing, e.r + 5)
        gfx.drawLine(e.x, e.y, e.x + fx, e.y + fy)
        -- rotating shield arcs (three short strokes around the rim)
        if e.shieldUp then
            for i = 0, 2 do
                local a = e.shieldPhase + i * 2.094
                local r1 = e.r + 4
                local ax, ay = math.cos(a) * r1, math.sin(a) * r1
                local bx, by = math.cos(a + 0.5) * r1, math.sin(a + 0.5) * r1
                gfx.drawLine(e.x + ax, e.y + ay, e.x + bx, e.y + by)
            end
        end
    end
end

function Draw.grid()
    gfx.setPattern(GRID_PAT)
    gfx.setLineWidth(1)
    Grid.draw()
    gfx.setColor(gfx.kColorWhite)
end

function Draw.enemies()
    for _, e in ipairs(G.enemies) do drawEnemy(e) end
    gfx.setLineWidth(1)
end

function Draw.shots()
    gfx.setLineWidth(2)
    for _, b in ipairs(G.shots) do
        local lx, ly = Vec.norm(b.vx, b.vy)
        gfx.drawLine(b.x, b.y, b.x - lx * 5, b.y - ly * 5)
    end
    gfx.setLineWidth(1)
end

function Draw.ship()
    local s = G.ship
    if not s or not s.alive then return end
    if not (s.invuln > 0 and Attract.frame % 4 < 2) then
        gfx.setLineWidth(2)
        Shapes.draw(SHIP, s.x, s.y, s.aim, 1)
        gfx.setLineWidth(1)
    end
    if s.invuln > 0 then gfx.drawCircleAtPoint(s.x, s.y, C.SHIP_R + 4) end
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
    if G.mult > 1 then Beams.print("X" .. G.mult, 8, 22, 9) end
    Beams.print("HIGH " .. Attract.high, Field.W / 2, 6, 8, { align = "center" })
    Beams.print("LIVES " .. G.lives, Field.W - 8, 6, 8, { align = "right" })
    Beams.print("BOMB " .. G.bombs, Field.W - 8, 18, 8, { align = "right" })
    Beams.print("WPN " .. (G.weapon + 1), Field.W - 8, 30, 8, { align = "right" })
end

function Draw.play()
    Draw.grid()
    Draw.bomb()
    Draw.enemies()
    Draw.shots()
    Draw.ship()
    Draw.hud()
end

function Draw.ambient()
    Draw.grid()
    Draw.enemies()
end
