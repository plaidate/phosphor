-- Webguard rendering: every model is polylines on black, text is Beams.

local gfx <const> = playdate.graphics

Draw = {}

-- the spider, facing +x (rotated to the aim direction)
local SPIDER <const> = Shapes.new({
    { 2.5, 0, 1.2, -1.8, -1.2, -1.8, -2.5, 0, -1.2, 1.8, 1.2, 1.8, 2.5, 0 },
    { -2.5, 0, -4, -1.5, -5.5, 0, -4, 1.5, -2.5, 0 }, -- abdomen
    { 1.5, -1.5, 3.5, -4, 5.5, -4.5 },
    { 0.5, -1.8, 1.5, -4.5, 2.5, -6 },
    { -0.5, -1.8, -1.5, -4.5, -2.8, -5.8 },
    { -1.5, -1.5, -3.5, -4, -5.5, -4.5 },
    { 1.5, 1.5, 3.5, 4, 5.5, 4.5 },
    { 0.5, 1.8, 1.5, 4.5, 2.5, 6 },
    { -0.5, 1.8, -1.5, 4.5, -2.8, 5.8 },
    { -1.5, 1.5, -3.5, 4, -5.5, 4.5 },
})

local CHASER <const> = Shapes.gon(C.CHASER_R, 8, C.CHASER_R * 0.45) -- spiky mite
local LAYER <const> = Shapes.new({
    { 7, 0, 0, -5, -7, 0, 0, 5, 7, 0 },
    { 3, -2, 5, -5 }, { 3, 2, 5, 5 },
    { -3, -2, -5, -5 }, { -3, 2, -5, 5 },
})
local BOMBER <const> = Shapes.new({
    Shapes.gon(C.BOMBER_R, 6)[1],
    Shapes.gon(C.BOMBER_R * 0.45, 6)[1],
})

function Draw.spider()
    local p = G.player
    if not p or not p.alive then return end
    if p.invuln > 0 and Attract.frame % 4 < 2 then return end
    Shapes.draw(SPIDER, p.x, p.y, p.aim, 1)
    -- the aim line, out from the spider's fangs
    local dx, dy = Vec.fromAngle(p.aim, 1)
    gfx.drawLine(p.x + dx * 7, p.y + dy * 7,
        p.x + dx * (7 + C.AIM_LEN), p.y + dy * (7 + C.AIM_LEN))
end

function Draw.enemies()
    for _, e in ipairs(G.chasers) do
        Shapes.draw(CHASER, e.x, e.y, e.angle, 1)
    end
    for _, l in ipairs(G.layers) do
        Shapes.draw(LAYER, l.x, l.y, l.angle, 1)
    end
    for _, b in ipairs(G.bombers) do
        -- flicker fast as the fuse runs down
        if b.fuse > 1.0 or Attract.frame % 2 == 0 then
            Shapes.draw(BOMBER, b.x, b.y, b.angle, 1)
        end
    end
    for _, e in ipairs(G.eggs) do
        -- pulse harder as hatching nears
        local urgency = e.t / C.EGG_HATCH
        local r = C.EGG_R + math.sin(e.t * (4 + urgency * 14)) * (0.8 + urgency * 1.6)
        gfx.drawCircleAtPoint(e.x, e.y, math.max(1.5, r))
    end
    for _, f in ipairs(G.frags) do
        gfx.fillRect(f.x - C.FRAG_R, f.y - C.FRAG_R, C.FRAG_R * 2, C.FRAG_R * 2)
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
    for i = 1, math.min(G.lives, 8) do
        Shapes.draw(SPIDER, Field.W - 16 * i, 14, -90, 0.8)
    end
    Beams.print("WAVE " .. G.wave, Field.W - 10, Field.H - 18, 8, { align = "right" })
    if G.bannerT > 0 and Attract.frame % 8 < 6 then
        Beams.print("WAVE " .. G.wave, C.CX, 50, 18, { align = "center", weight = 2 })
    end
end

function Draw.play()
    Web.draw()
    Draw.enemies()
    Draw.spider()
    Draw.shots()
    Draw.hud()
end

-- the title screen's backdrop: the empty web, still shimmering
function Draw.ambient()
    Web.draw()
end
