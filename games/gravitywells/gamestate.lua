-- Gravity Wells: shared state across both scales. The ship, fuel, and shots
-- are global; each planet keeps its own persistent mission table.

G = {
    score = 0,
    ships = C.START_SHIPS,
    nextLifeAt = C.EXTRA_LIFE_AT,
    system = 1,
    fuel = C.FUEL_MAX,
    fuelOut = false,
    view = "system", -- "system" | "mission"
    ship = nil,
    shots = {},
    planets = {},    -- { {x,y,r,orbitR,kind,cleared,revGrav,mission}, ... }
    curPlanet = nil,
    m = nil,         -- current mission table (== curPlanet.mission)
    camX = 0,        -- mission camera (x only; the world is one screen tall)
    deadT = 0,
    msg = nil,
    msgT = 0,
}

function G.addScore(n)
    G.score = G.score + n
    Harness.count("scorePts", n)
    if G.score >= G.nextLifeAt and G.ships < 8 then
        G.ships = G.ships + 1
        G.nextLifeAt = G.nextLifeAt + C.EXTRA_LIFE_AT
        G.message("EXTRA SHIP", 2)
        Sfx.fanfare()
    end
end

function G.message(s, t)
    G.msg = s
    G.msgT = t or 2
end

-- Fx draws in screen space; convert mission world coords at emit time
function G.fxBurst(x, y, n)
    if G.view == "mission" then x = x - G.camX end
    Fx.burst(x, y, n)
end

function G.fxDebris(x, y, n)
    if G.view == "mission" then x = x - G.camX end
    Fx.debris(x, y, n)
end
