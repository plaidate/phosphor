-- The between-wave shop — Warblade's signature. Spend cash banked from drops
-- on upgrades. Up/Down (or crank) moves the cursor, A buys, B leaves; it also
-- auto-closes after a dwell so the game always advances (and runs headless).

Shop = {}

local function canSpread() return G.spread < C.MAX_SPREAD end
local function canArmor() return G.armor < 3 end

local ITEMS = {
    { name = "SPEED +",  price = 50,   ok = function() return G.speedLvl < 4 end,
      buy = function() G.speedLvl = G.speedLvl + 1 end },
    { name = "BULLET +", price = 75,   ok = canSpread,
      buy = function() G.spread = G.spread + 1 end },
    { name = "RATE +",   price = 100,  ok = function() return G.rateLvl < 6 end,
      buy = function() G.rateLvl = G.rateLvl + 1 end },
    { name = "SHIELD",   price = 200,  ok = function() return true end,
      buy = function() G.shieldT = C.SHIELD_TIME end },
    { name = "AUTOFIRE", price = 350,  ok = function() return not G.autofire end,
      buy = function() G.autofire = true end },
    { name = "ARMOR",    price = 500,  ok = canArmor,
      buy = function() G.armor = G.armor + 1 end },
    { name = "BOMB",     price = 800,  ok = function() return G.bombs < 5 end,
      buy = function() G.bombs = G.bombs + 1 end },
    { name = "EXTRA LIFE", price = 1500, ok = function() return G.lives < C.MAX_LIVES end,
      buy = function() G.lives = G.lives + 1 end },
}

Shop.items = ITEMS
Shop.cursor = 1
Shop.t = 0
Shop.msg = ""

function Shop.enter()
    Shop.cursor = 1
    Shop.t = 0
    Shop.msg = ""
end

local function buy()
    local it = ITEMS[Shop.cursor]
    if not it.ok() then
        Shop.msg = "MAXED"
    elseif G.cash < it.price then
        Shop.msg = "NO CASH"
        Sfx.boom(1)
    else
        G.cash = G.cash - it.price
        it.buy()
        Shop.msg = "BOUGHT"
        Sfx.fanfare({ 660, 880 }, 0.07)
        Harness.count("bought")
    end
end

-- returns true once the shop should close and the next wave should begin
function Shop.update(dt)
    Shop.t = Shop.t + dt
    if Shop.t < C.SHOP_MIN then return false end

    if Harness.enabled then
        -- headless: buy what we can afford, then leave promptly
        if Shop.t > 0.6 then
            for i = #ITEMS, 1, -1 do
                if ITEMS[i].ok() and G.cash >= ITEMS[i].price then
                    Shop.cursor = i; buy(); break
                end
            end
            return true
        end
        return false
    end

    if playdate.buttonJustPressed(playdate.kButtonUp) then
        Shop.cursor = (Shop.cursor - 2) % #ITEMS + 1
    elseif playdate.buttonJustPressed(playdate.kButtonDown) then
        Shop.cursor = Shop.cursor % #ITEMS + 1
    end
    local crank = playdate.getCrankChange()
    if crank > 25 then Shop.cursor = Shop.cursor % #ITEMS + 1 end
    if crank < -25 then Shop.cursor = (Shop.cursor - 2) % #ITEMS + 1 end

    if playdate.buttonJustPressed(playdate.kButtonA) then buy() end
    if playdate.buttonJustPressed(playdate.kButtonB) then return true end
    if Shop.t > C.SHOP_DWELL then return true end
    return false
end
