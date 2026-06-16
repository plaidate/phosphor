-- Power-up drops. A killed enemy may leave a labelled token that drifts down;
-- catch it with the fighter to bank cash or upgrade. Names mirror Warblade's
-- bonus kit (money, weapon, shield, armor, extra, autofire, rapid, multiply).

Bonuses = {}

-- key, glyph (one char from the beam font), weight, apply()
local TYPES = {
    { key = "money",  glyph = "C", weight = 30, apply = function() G.addCash(C.CASH_PER_MONEY) end },
    { key = "weapon", glyph = "P", weight = 16, apply = function() G.spread = math.min(C.MAX_SPREAD, G.spread + 1) end },
    { key = "rate",   glyph = "R", weight = 12, apply = function() G.rateLvl = math.min(6, G.rateLvl + 1) end },
    { key = "shield", glyph = "S", weight = 10, apply = function() G.shieldT = C.SHIELD_TIME end },
    { key = "armor",  glyph = "A", weight = 9,  apply = function() G.armor = math.min(3, G.armor + 1) end },
    { key = "mult",   glyph = "X", weight = 8,  apply = function() G.multT = C.MULT_TIME end },
    { key = "auto",   glyph = "F", weight = 6,  apply = function() G.autofire = true end },
    { key = "life",   glyph = "1", weight = 3,  apply = function() G.addLife() end },
}

local TOTAL = 0
for _, t in ipairs(TYPES) do TOTAL = TOTAL + t.weight end

local function pick()
    local r = math.random() * TOTAL
    for _, t in ipairs(TYPES) do
        r = r - t.weight
        if r <= 0 then return t end
    end
    return TYPES[1]
end

function Bonuses.maybeDrop(x, y)
    if math.random() > C.BONUS_CHANCE then return end
    local t = pick()
    G.bonuses[#G.bonuses + 1] = { x = x, y = y, key = t.key, glyph = t.glyph, apply = t.apply }
    Harness.count("drops")
end

function Bonuses.update(dt)
    local s = G.ship
    for i = #G.bonuses, 1, -1 do
        local b = G.bonuses[i]
        b.y = b.y + C.BONUS_VY * dt
        if b.y > Field.H + 12 then
            table.remove(G.bonuses, i)
        elseif s and s.alive and math.abs(b.x - s.x) < C.BONUS_R + C.SHIP_HALF
            and math.abs(b.y - s.y) < C.BONUS_R then
            b.apply()
            Sfx.warble()
            Harness.count("pickups")
            table.remove(G.bonuses, i)
        end
    end
end
