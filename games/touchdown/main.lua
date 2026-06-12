-- Touchdown — vector lunar landing for Playdate (Phosphor package).
-- An original implementation of the 1979 arcade classic's design.
-- Crank sets the throttle 0-100%, left/right tilts, B is a full burn.
-- Land softly on a pad: narrower pads pay bigger multipliers.

import "lib"

import "config"
import "gamestate"
import "terrain"
import "lander"
import "input"
import "draw"

local function startGame()
    G.score = 0
    G.landers = C.START_LANDERS
    G.fuel = C.FUEL_MAX
    G.fuelOut = false
    Terrain.generate()
    Lander.spawn()
    Harness.count("games")
end

local function updatePlay(dt)
    if G.mode == "fly" then
        local turn, dThrottle, burn = Input.gather()
        Lander.update(turn, dThrottle, burn, dt)
    elseif G.mode == "landed" then
        G.modeT = G.modeT - dt
        if G.modeT <= 0 then
            Terrain.generate()
            Lander.spawn()
        end
    elseif G.mode == "crashed" then
        G.modeT = G.modeT - dt
        if G.modeT <= 0 then
            if G.landers <= 0 or G.fuel <= 0 then
                Harness.count("gameovers")
                Attract.gameOver()
                return
            end
            Lander.spawn()
        end
    end
end

local function ambient(_dt)
    if not G.terrain then Terrain.generate() end
end

Harness.shotPath = "phosphor/build/touchdown-shot.png"

Harness.extra = function(t)
    t.state = Attract.state
    t.score = G.score
    t.fuel = math.floor(G.fuel)
    t.landers = G.landers
end

Attract.setup({
    title = "TOUCHDOWN",
    controls = {
        "CRANK - THROTTLE",
        "LEFT/RIGHT - TILT",
        "B - FULL BURN",
    },
    hooks = {
        start = startGame,
        update = updatePlay,
        draw = Draw.play,
        ambient = ambient,
        drawAmbient = Draw.ambient,
        score = function() return G.score end,
    },
})
