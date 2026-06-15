-- Elite stock market: a faithful port of newkind/trade.c. Each system's prices
-- and quantities derive from its economy plus a per-visit random, exactly as in
-- the original. Prices and credits are both in tenths of a credit.

Trade = {}

-- name, base price, economy adjustment, base quantity, random mask, unit
-- (t = tonnes, kg, g). Cargo capacity counts tonnes only.
Trade.items = {
    { "Food",         19, -2,   6, 0x01, "t" },
    { "Textiles",     20, -1,  10, 0x03, "t" },
    { "Radioactives", 65, -3,   2, 0x07, "t" },
    { "Slaves",       40, -5, 226, 0x1F, "t" },
    { "Liquor/Wines", 83, -5, 251, 0x0F, "t" },
    { "Luxuries",    196,  8,  54, 0x03, "t" },
    { "Narcotics",   235, 29,   8, 0x78, "t" },
    { "Computers",   154, 14,  56, 0x03, "t" },
    { "Machinery",   117,  6,  40, 0x07, "t" },
    { "Alloys",       78,  1,  17, 0x1F, "t" },
    { "Firearms",    124, 13,  29, 0x07, "t" },
    { "Furs",        176, -9, 220, 0x3F, "t" },
    { "Minerals",     32, -1,  53, 0x03, "t" },
    { "Gold",         97, -1,  66, 0x07, "kg" },
    { "Platinum",    171, -2,  55, 0x1F, "kg" },
    { "Gem-Stones",   45, -1, 250, 0x0F, "g" },
    { "Alien Items",  53, 15, 192, 0x07, "t" },
}

Trade.N = #Trade.items
local ALIEN = 17

-- generate_stock_market: price/quantity from economy + market_rnd (trade.c:77)
function Trade.generate(econ, rnd)
    local m = {}
    for i = 1, Trade.N do
        local it = Trade.items[i]
        local mask = it[5]
        local price = (it[2] + (rnd & mask) + econ * it[3]) & 255
        local quant = (it[4] + (rnd & mask) - econ * it[3]) & 255
        if quant > 127 then quant = 0 end
        quant = quant & 63
        m[i] = { price = price * 4, qty = quant }
    end
    m[ALIEN].qty = 0 -- Alien Items are never for sale
    return m
end

-- tonnes of cargo currently held (kg/g goods don't take a tonne slot)
function Trade.cargoUsed()
    local t = 0
    for i = 1, Trade.N do
        if G.cargo[i] > 0 and Trade.items[i][6] == "t" then t = t + G.cargo[i] end
    end
    return t
end

function Trade.buy(i)
    local m = G.market[i]
    if m.qty <= 0 then return false end
    if G.credits < m.price then return false end
    if Trade.items[i][6] == "t" and Trade.cargoUsed() >= G.cargoBay then return false end
    G.credits = G.credits - m.price
    G.cargo[i] = G.cargo[i] + 1
    m.qty = m.qty - 1
    return true
end

function Trade.sell(i)
    if G.cargo[i] <= 0 then return false end
    local m = G.market[i]
    G.credits = G.credits + m.price
    G.cargo[i] = G.cargo[i] - 1
    m.qty = m.qty + 1
    return true
end
