-- Touchdown: shared state. Fuel and landers persist across landings; the
-- terrain regenerates after every safe touchdown.

G = {
    score = 0,
    landers = C.START_LANDERS,
    fuel = C.FUEL_MAX,
    fuelOut = false,
    lander = nil,
    terrain = nil, -- flat polyline {x1,y1,x2,y2,...} across the screen
    pads = nil,    -- { {x1,x2,y,mult}, ... }
    mode = "fly",  -- "fly" | "landed" | "crashed"
    modeT = 0,
    msg = nil,
}

function G.addScore(n)
    G.score = G.score + n
    Harness.count("scorePts", n)
end
