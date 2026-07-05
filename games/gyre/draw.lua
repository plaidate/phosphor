-- Rendering: the star tunnel, every ship scaled by tube depth, the beam,
-- HUD in the side margins the circle leaves free, and the banner/popup
-- text. All beam lines, all Beams stroke font.

local gfx <const> = playdate.graphics

Draw = {}

-- models point down +x (their heading)
local SHIP = {
    { 10, 0, -6, 6, -3, 0, -6, -6, 10, 0 },
    { -3, 0, -7, 0 },
}
local DRONE = {
    { 7, 0, -2, 5, -7, 7, -3, 1, -3, -1, -7, -7, -2, -5, 7, 0 },
}
local CHANCE_DRONE = {
    { 7, 0, -3, 5, 0, 0, -3, -5, 7, 0 },
}
local SAT = {
    { 5, 0, 2.5, 4.5, -2.5, 4.5, -5, 0, -2.5, -4.5, 2.5, -4.5, 5, 0 },
    { -9, 3, -5, 3, -5, -3, -9, -3, -9, 3 },
    { 9, 3, 5, 3, 5, -3, 9, -3, 9, 3 },
}
local LASERSHIP = {
    { 6, 0, -4, 6, -1, 0, -4, -6, 6, 0 },
    { 3, 3, 8, 5 },
    { 3, -3, 8, -5 },
}

local function drawEnemy(e)
    if e.state == "path" and e.delayT > 0 then return end
    local r = Vec.len(e.x, e.y)
    local x, y = G.px(e.x, e.y)
    local s = G.scaleAt(r)
    if e.type == "sat" then
        Shapes.draw(SAT, x, y, G.time * 90, s)
        -- the trio glints so you know it is worth something
        if math.floor(G.time * 6) % 2 == 0 then
            gfx.drawCircleAtPoint(x, y, 8 * s + 2)
        end
    elseif e.type == "laser" then
        Shapes.draw(LASERSHIP, x, y, e.heading, s)
    elseif e.type == "chance" then
        Shapes.draw(CHANCE_DRONE, x, y, e.heading, s)
    else
        Shapes.draw(DRONE, x, y, e.heading, s)
    end
end

local function drawBeam()
    local b = G.beam
    if not b then return end
    local e1, e2
    for _, e in ipairs(G.enemies) do
        if e.type == "laser" then
            if e.lead then e1 = e else e2 = e end
        end
    end
    if not (e1 and e2) then return end
    local x1, y1 = G.px(e1.x, e1.y)
    local x2, y2 = G.px(e2.x, e2.y)
    if b.active then
        gfx.setLineWidth(2)
        gfx.drawLine(x1, y1, x2, y2)
        gfx.setLineWidth(1)
    elseif math.floor(b.t * 10) % 2 == 0 then
        gfx.drawLine(x1, y1, x2, y2) -- warmup flicker
    end
end

local function drawPlayer()
    local p = G.player
    if not p.alive then return end
    if p.invulnT > 0 and Attract.frame % 4 < 2 then return end
    local x, y = G.polarPx(p.a, 1)
    Shapes.draw(SHIP, x, y, p.a + 180, 1)
    if p.twin then
        Shapes.draw({ { -2, 0, 4, 0 } }, x, y, p.a + 90, 1)
    end
end

local function drawHud()
    Beams.print("SCORE", 8, 8, 7)
    Beams.print(tostring(G.score), 8, 20, 10)
    for i = 1, math.min(G.lives - 1, 5) do
        Shapes.draw(SHIP, 14 + (i - 1) * 16, 44, -90, 0.7)
    end
    if G.player.twin then Beams.print("TWIN", 8, 56, 7) end

    Beams.print("HIGH", 392, 8, 7, { align = "right" })
    Beams.print(tostring(math.max(Attract.high, G.score)), 392, 20, 10, { align = "right" })
    Beams.print("STAGE " .. G.stage, 392, 220, 7, { align = "right" })
    if G.chance then
        Beams.print("CHANCE", 8, 208, 7)
        Beams.print("HITS " .. (G.chanceHits or 0), 8, 220, 7)
    else
        Beams.print(C.PLANETS[G.planetIdx], 8, 220, 7)
    end
end

local function drawTexts()
    if G.bannerT > 0 then
        Beams.print(G.bannerText, C.CX, 78, 14, { align = "center", weight = 2 })
    end
    if G.popT > 0 then
        Beams.print(G.popText, C.CX, 168, 9, { align = "center" })
    end
end

-- the growing planet during an arrival warp
local function drawPlanet(k)
    local r = 6 + 44 * k
    gfx.drawCircleAtPoint(C.CX, C.CY, r)
    local name = C.PLANETS[G.planetIdx]
    if name == "SATURN" or name == "URANUS" then
        gfx.drawEllipseInRect(C.CX - r * 1.7, C.CY - r * 0.35, r * 3.4, r * 0.7)
    end
    Beams.print(name, C.CX, C.CY + r + 12, 9, { align = "center" })
end

function Draw.play()
    local warp = G.mode == "warp"
    Stars.draw(warp and 6 or 1)
    gfx.drawRect(0, 0, Field.W, Field.H)

    if warp and G.warpsLeft <= 0 then
        drawPlanet(1 - math.max(G.modeT, 0) / 2.2)
    end

    for _, e in ipairs(G.enemies) do drawEnemy(e) end
    drawBeam()

    for _, m in ipairs(G.meteors) do
        local x, y = G.polarPx(m.a, m.r)
        Shapes.draw(m.shape, x, y, m.spin, G.scaleAt(m.r))
    end

    for _, b in ipairs(G.bullets) do
        local x, y = G.px(b.x, b.y)
        gfx.fillCircleAtPoint(x, y, 1.5 * G.scaleAt(Vec.len(b.x, b.y)) + 0.5)
    end

    for _, s in ipairs(G.shots) do
        local x1, y1 = G.polarPx(s.a, s.r)
        local x2, y2 = G.polarPx(s.a, math.min(s.r + 0.06, 1))
        gfx.drawLine(x1, y1, x2, y2)
    end

    drawPlayer()
    drawHud()
    drawTexts()

    if G.mode == "tally" then
        Beams.print("CHANCE BONUS", C.CX, 100, 12, { align = "center", weight = 2 })
        Beams.print((G.chanceHits or 0) .. " HITS", C.CX, 126, 9, { align = "center" })
    end
end

-- behind the title and game-over cards: the tunnel keeps flowing
function Draw.ambient()
    Stars.draw(1)
end
