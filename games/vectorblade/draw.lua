-- Vectorblade rendering: every actor is white beam line work, the HUD and
-- shop use the stroke font. Draw.play dispatches on the in-play mode.

local gfx <const> = playdate.graphics

Draw = {}

-- the fighter, nose up
local SHIP <const> = Shapes.new({
    { 0, -10, -4, -2, -8, 6, -3, 4, 0, 6, 3, 4, 8, 6, 4, -2, 0, -10 },
    { 0, -10, 0, -4 },
})

-- enemy silhouettes (roughly symmetric, drawn upright over the player)
local DRONE <const> = Shapes.new({ { 0, -6, 6, 0, 0, 6, -6, 0, 0, -6 }, { -6, 0, 6, 0 } })
local WEDGE <const> = Shapes.new({ { -7, -5, 7, -5, 0, 7, -7, -5 }, { -3, -1, 3, -1 } })
local TIE <const> = Shapes.new({
    { -8, -6, -8, 6 }, { 8, -6, 8, 6 },
    { -8, 0, -3, 0 }, { 8, 0, 3, 0 },
    { -3, -4, 3, -4, 3, 4, -3, 4, -3, -4 },
})
local BIRD <const> = Shapes.new({
    { 0, -7, 0, 5 },
    { 0, -3, -9, -6, -6, 2, 0, 4 },
    { 0, -3, 9, -6, 6, 2, 0, 4 },
})
local SHAPE = { drone = DRONE, wedge = WEDGE, tie = TIE, bird = BIRD }

local BOSS <const> = Shapes.new({
    { -30, 0, -18, -14, 18, -14, 30, 0, 18, 14, -18, 14, -30, 0 },
    { -18, -14, -12, -2, 12, -2, 18, -14 },
    { -10, 2, -10, 10, 10, 10, 10, 2 },        -- gun bay
    { -24, 0, -30, 6 }, { 24, 0, 30, 6 },       -- side turrets
    { 0, -14, 0, -20 },
})

function Draw.ship()
    local s = G.ship
    if not s or not s.alive then return end
    if s.invuln > 0 and Attract.frame % 4 < 2 then return end
    Shapes.draw(SHIP, s.x, s.y, 0, 1)
    if G.shieldT > 0 then
        gfx.drawCircleAtPoint(s.x, s.y, 14)
    end
end

function Draw.enemies()
    for _, e in ipairs(G.enemies) do
        local sh = SHAPE[e.kind] or DRONE
        local ang = (e.state == "dive") and 180 or 0
        Shapes.draw(sh, e.x, e.y, ang, 1)
    end
end

function Draw.boss()
    local b = G.boss
    if not b then return end
    if b.hitT and b.hitT > 0 and Attract.frame % 2 == 0 then
        gfx.setLineWidth(2)
    end
    Shapes.draw(BOSS, b.x, b.y, 0, 1)
    gfx.setLineWidth(1)
    -- HP bar
    local w = 60 * (b.hp / b.maxhp)
    gfx.drawRect(b.x - 30, b.y - 28, 60, 4)
    gfx.fillRect(b.x - 30, b.y - 28, w, 4)
end

function Draw.shots()
    for _, b in ipairs(G.shots) do
        gfx.drawLine(b.x, b.y, b.x, b.y - C.SHOT_LEN)
    end
    for _, b in ipairs(G.eshots) do
        gfx.fillRect(b.x - 1, b.y - 1, 3, 3)
    end
end

function Draw.bonuses()
    for _, b in ipairs(G.bonuses) do
        local r = C.BONUS_R
        gfx.drawRect(b.x - r, b.y - r, r * 2, r * 2)
        Beams.print(b.glyph, b.x, b.y - 5, 9, { align = "center" })
    end
end

function Draw.hud()
    Beams.print(tostring(G.score), 8, 6, 11, { weight = 1 })
    Beams.print("L" .. G.level, Field.W - 8, 6, 9, { align = "right" })
    Beams.print("CASH " .. G.cash, Field.W / 2, 6, 8, { align = "center" })
    -- lives along the bottom-left
    for i = 1, math.min(G.lives, C.MAX_LIVES) do
        Shapes.draw(SHIP, 12 + (i - 1) * 13, Field.H - 9, 0, 0.55)
    end
    -- weapon / kit readout bottom-right
    local kit = "WPN" .. G.spread
    if G.autofire then kit = kit .. " AF" end
    if G.armor > 0 then kit = kit .. " AR" .. G.armor end
    if G.bombs > 0 then kit = kit .. " B" .. G.bombs end
    Beams.print(kit, Field.W - 8, Field.H - 12, 8, { align = "right" })
    if G.multT > 0 then Beams.print("X2", Field.W / 2, Field.H - 12, 9, { align = "center" }) end
end

local function drawCleared()
    Beams.print("WAVE " .. G.level .. " CLEAR", Field.W / 2, 96, 16, { align = "center", weight = 2 })
    Beams.print("CASH " .. G.cash, Field.W / 2, 124, 10, { align = "center" })
end

local function drawShop()
    Beams.print("SHOP", Field.W / 2, 14, 16, { align = "center", weight = 2 })
    Beams.print("CASH " .. G.cash, Field.W / 2, 36, 10, { align = "center" })
    local y = 60
    for i, it in ipairs(Shop.items) do
        local label = it.name
        local row = label .. "  " .. it.price
        local x = 70
        if i == Shop.cursor then
            Beams.print(">", x - 16, y, 10)
            if not it.ok() then row = label .. "  --" end
        end
        Beams.print(row, x, y, 10, { weight = (i == Shop.cursor) and 2 or 1 })
        y = y + 20
    end
    Beams.print(Shop.msg, Field.W - 16, 60, 10, { align = "right" })
    Beams.print("A BUY   B PLAY", Field.W / 2, Field.H - 16, 8, { align = "center" })
end

function Draw.play()
    Draw.enemies()
    Draw.boss()
    Draw.bonuses()
    Draw.shots()
    Draw.ship()
    Draw.hud()
    if G.mode == "cleared" then
        drawCleared()
    elseif G.mode == "shop" then
        drawShop()
    end
end

-- title / game-over backdrop: a ghost formation breathing behind the chrome,
-- plus the earned rank on the game-over screen.
function Draw.ambient()
    Draw.enemies()
    Draw.boss()
    if Attract.state == "over" then
        Beams.print("RANK", Field.W / 2, 150, 9, { align = "center" })
        Beams.print(C.rankFor(G.score), Field.W / 2, 164, 11, { align = "center", weight = 2 })
    end
end
