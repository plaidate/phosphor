-- Elite docked mode: when the player docks, the game stays in Attract's "play"
-- state but flips G.docked, and this module takes over update/draw with the
-- station screens — launch, galactic chart, market, equip ship, status,
-- inventory. Modelled on newkind/docked.c, condensed for the Playdate.

local gfx <const> = playdate.graphics
local pd <const> = playdate

Docked = {}

local MENU = { "LAUNCH", "CHART", "MARKET", "EQUIP SHIP", "STATUS", "INVENTORY" }

-- equipment for sale: label, key, price (tenths of Cr), a buy() that applies it
local EQUIP = {
    { "FUEL", "fuel", function() return (C.FUEL_MAX - G.fuel) * 2 end,
        function() G.fuel = C.FUEL_MAX end, function() return G.fuel >= C.FUEL_MAX end },
    { "MISSILE", "missile", function() return 300 end,
        function() G.missiles = G.missiles + 1 end, function() return G.missiles >= 4 end },
    { "LARGE CARGO BAY", "bay", function() return 4000 end,
        function() G.cargoBay = 35 end, function() return G.cargoBay >= 35 end },
    { "ECM SYSTEM", "ecm", function() return 6000 end,
        function() G.equip.ecm = true end, function() return G.equip.ecm end },
    { "FUEL SCOOPS", "scoop", function() return 5250 end,
        function() G.equip.scoop = true end, function() return G.equip.scoop end },
    { "ENERGY BOMB", "bomb", function() return 9000 end,
        function() G.equip.bomb = true end, function() return G.equip.bomb end },
    { "DOCKING COMPUTER", "dock", function() return 15000 end,
        function() G.equip.dockComp = true end, function() return G.equip.dockComp end },
    { "GALACTIC HYPERDRIVE", "ghyper", function() return 50000 end,
        function() G.equip.galHyper = true end, function() return G.equip.galHyper end },
}

local function cr(tenths) return string.format("%.1f", tenths / 10) end

-- systems reachable from here, nearest first, for the chart
local function buildChart()
    local here = G.systems[G.sysIndex + 1]
    local list = {}
    for i = 1, 256 do
        if i - 1 ~= G.sysIndex then
            local d = Galaxy.distance(here, G.systems[i])
            if d > 0 and d <= C.FUEL_MAX then list[#list + 1] = { idx = i - 1, dist = d } end
        end
    end
    table.sort(list, function(a, b) return a.dist < b.dist end)
    return list
end

function Docked.enter()
    G.docked = true
    G.dockScreen = "menu"
    G.cursor = 1
    G.marketRnd = math.random(0, 255)
    G.market = Trade.generate(G.planet.econ, G.marketRnd)
    G.chart = buildChart()
    G.dockT = 0
    G.smokeStep = 0
end

local function launch(targetIdx, dist)
    G.docked = false
    if targetIdx then
        G.fuel = math.max(0, G.fuel - dist)
        G.legalStatus = G.legalStatus // 2   -- a jump cools your record (Elite)
        Harness.count("jumps")
        World.enterSystem(targetIdx)
    end
    G.speed = C.SPEED_CRUISE
    -- relaunch puts the station behind you
    if G.station then G.station.pos = { x = 0, y = 0, z = -C.STATION_DIST } end
end

-- ---- input -------------------------------------------------------------

local function pressed(b) return pd.buttonJustPressed(b) end

local function updateMenu()
    if pressed(pd.kButtonUp) then G.cursor = math.max(1, G.cursor - 1) end
    if pressed(pd.kButtonDown) then G.cursor = math.min(#MENU, G.cursor + 1) end
    if pressed(pd.kButtonA) then
        local sel = MENU[G.cursor]
        if sel == "LAUNCH" then launch()
        elseif sel == "CHART" then G.dockScreen = "chart"; G.cursor = 1
        elseif sel == "MARKET" then G.dockScreen = "market"; G.cursor = 1
        elseif sel == "EQUIP SHIP" then G.dockScreen = "equip"; G.cursor = 1
        elseif sel == "STATUS" then G.dockScreen = "status"
        elseif sel == "INVENTORY" then G.dockScreen = "inventory" end
    end
end

local function updateList(n)
    if pressed(pd.kButtonUp) then G.cursor = math.max(1, G.cursor - 1) end
    if pressed(pd.kButtonDown) then G.cursor = math.min(n, G.cursor + 1) end
    if pressed(pd.kButtonB) then G.dockScreen = "menu"; G.cursor = 1; return true end
    return false
end

local function updateMarket()
    if updateList(Trade.N) then return end
    if pressed(pd.kButtonRight) then if Trade.buy(G.cursor) then Sfx.blip(200) end end
    if pressed(pd.kButtonLeft) then if Trade.sell(G.cursor) then Sfx.blip(150) end end
end

local function updateEquip()
    if updateList(#EQUIP) then return end
    if pressed(pd.kButtonA) then
        local e = EQUIP[G.cursor]
        if not e[5]() and G.credits >= e[3]() then
            G.credits = G.credits - e[3]()
            e[4]()
            Sfx.fanfare()
        end
    end
end

local function updateChart()
    if updateList(#G.chart) then return end
    if pressed(pd.kButtonA) and G.chart[G.cursor] then
        local t = G.chart[G.cursor]
        launch(t.idx, t.dist)
    end
end

-- a scripted pilot so headless smoke runs pass through the station screens
local CAPTURE = false -- when true, park on a station screen for a screenshot
local function smokeAuto(dt)
    G.dockT = G.dockT + dt
    if G.dockT < 1.5 then G.dockScreen = "menu"; return end
    G.dockScreen = "market"
    if G.dockT < 4 then Trade.buy(1); Trade.buy(5); Trade.buy(9) end
    if CAPTURE then return end
    if G.dockT < 15 then G.dockScreen = "chart"; return end
    if G.dockT < 18 then G.dockScreen = "status"; return end
    G.fuel = C.FUEL_MAX
    G.chart = buildChart()
    if #G.chart > 0 then launch(G.chart[1].idx, G.chart[1].dist) else launch() end
end

function Docked.update(dt)
    if Harness.enabled then smokeAuto(dt); return end
    local s = G.dockScreen
    if s == "menu" then updateMenu()
    elseif s == "market" then updateMarket()
    elseif s == "equip" then updateEquip()
    elseif s == "chart" then updateChart()
    else
        if pressed(pd.kButtonB) or pressed(pd.kButtonA) then G.dockScreen = "menu" end
    end
end

-- ---- drawing -----------------------------------------------------------

local function header(title)
    gfx.drawRect(0, 0, 400, 240)
    Beams.print(title, 200, 12, 12, { align = "center" })
    gfx.drawLine(8, 26, 392, 26)
    Beams.print("CASH " .. cr(G.credits) .. " CR", 392, 230, 8, { align = "right" })
end

local function row(text, x, y, sel)
    if sel then
        gfx.fillRect(x - 4, y - 1, 396 - x, 13)
        gfx.setColor(gfx.kColorBlack)        -- black text on the white highlight
        Beams.print(text, x, y, 9)
        gfx.setColor(gfx.kColorWhite)
    else
        Beams.print(text, x, y, 9)
    end
end

local function drawMenu()
    header(G.sysName:upper() .. " STATION")
    local y = 48
    for i, m in ipairs(MENU) do
        row(m, 150, y, i == G.cursor)
        y = y + 22
    end
end

local function drawMarket()
    header("MARKET: " .. G.sysName:upper())
    Beams.print("PRODUCT", 14, 30, 7)
    Beams.print("PRICE", 210, 30, 7)
    Beams.print("QTY", 285, 30, 7)
    Beams.print("HOLD", 345, 30, 7)
    local y = 42
    for i = 1, Trade.N do
        local it, m = Trade.items[i], G.market[i]
        local line = string.format("%-13s  %6s  %2d%s   %2d", it[1], cr(m.price), m.qty, it[6], G.cargo[i])
        row(line, 14, y, i == G.cursor)
        y = y + 11
    end
    Beams.print("RIGHT BUY   LEFT SELL   B BACK", 200, 232, 7, { align = "center" })
end

local function drawEquip()
    header("EQUIP SHIP")
    local y = 40
    for i, e in ipairs(EQUIP) do
        local owned = e[5]()
        local line = string.format("%-20s %8s", e[1], owned and "OWNED" or cr(e[3]()))
        row(line, 30, y, i == G.cursor)
        y = y + 18
    end
    Beams.print("A BUY   B BACK", 200, 232, 7, { align = "center" })
end

local function drawChart()
    header("GALACTIC CHART " .. G.galaxyNum)
    Beams.print("NEAREST SYSTEMS - FUEL " .. cr(G.fuel * 10), 200, 32, 7, { align = "center" })
    local y = 46
    local first = math.max(1, G.cursor - 7)
    for i = first, math.min(#G.chart, first + 13) do
        local c = G.chart[i]
        local seed = G.systems[c.idx + 1]
        local d = Galaxy.data(seed)
        local line = string.format("%-9s  %.1f LY  TL%d", Galaxy.name(seed), c.dist / 10, d.tech + 1)
        row(line, 60, y, i == G.cursor)
        y = y + 13
    end
    Beams.print("A JUMP   B BACK", 200, 232, 7, { align = "center" })
end

local function drawStatus()
    header("COMMANDER JAMESON")
    local L = 40
    local function line(k, v, y) Beams.print(k, 30, y, 8); Beams.print(v, 370, y, 8, { align = "right" }) end
    line("System", G.sysName:upper(), L)
    line("Galaxy", "" .. G.galaxyNum, L + 16)
    line("Fuel", cr(G.fuel * 10) .. " LY", L + 32)
    line("Cash", cr(G.credits) .. " CR", L + 48)
    line("Cargo bay", G.cargoBay .. "t", L + 64)
    line("Missiles", "" .. G.missiles, L + 80)
    line("Legal status", G.statusName(), L + 96)
    line("Rating", G.rating(), L + 112)
    line("Kills", "" .. G.kills, L + 128)
    local mt = ({ [0] = "None", [1] = "Hunt the Constrictor", [2] = "Complete" })[G.mission]
    line("Mission", mt or "None", L + 144)
    Beams.print("B BACK", 200, 232, 7, { align = "center" })
end

local function drawInventory()
    header("CARGO INVENTORY")
    Beams.print("Fuel  " .. cr(G.fuel * 10) .. " LY", 30, 36, 9)
    local y = 54
    local any = false
    for i = 1, Trade.N do
        if G.cargo[i] > 0 then
            Beams.print(string.format("%-14s %d%s", Trade.items[i][1], G.cargo[i], Trade.items[i][6]), 30, y, 9)
            y = y + 14; any = true
        end
    end
    if not any then Beams.print("Hold empty", 30, y, 9) end
    Beams.print("B BACK", 200, 232, 7, { align = "center" })
end

function Docked.draw()
    gfx.clear(gfx.kColorBlack)
    gfx.setColor(gfx.kColorWhite)
    local s = G.dockScreen
    if s == "market" then drawMarket()
    elseif s == "equip" then drawEquip()
    elseif s == "chart" then drawChart()
    elseif s == "status" then drawStatus()
    elseif s == "inventory" then drawInventory()
    else drawMenu() end
end
