-- Gravity Wells — vector gravity-thrust missions for Playdate (Phosphor
-- package). An original implementation of the 1982 arcade classic's design.
-- A lethal star anchors the system view; dive into each planet's well for a
-- side-scrolling raid: beam up fuel, blast the bunkers, and if you're brave,
-- hole the reactor and outrun the 8-second blast. Clear all four wells and
-- a heavier system awaits — where one planet's gravity points the wrong way.

import "lib"

import "config"
import "gamestate"
import "ship"
import "system"
import "mission"
import "input"
import "draw"

local function startGame()
    G.score = 0
    G.ships = C.START_SHIPS
    G.nextLifeAt = C.EXTRA_LIFE_AT
    G.system = 1
    G.fuel = C.FUEL_MAX
    G.fuelOut = false
    G.shots = {}
    G.msg, G.msgT = nil, 0
    G.deadT = 0
    G.curPlanet, G.m = nil, nil
    System.newPlanets()
    System.respawn()
    Harness.count("games")
end

local function updatePlay(dt)
    if G.msgT > 0 then
        G.msgT = G.msgT - dt
        if G.msgT <= 0 then G.msg = nil end
    end

    local s = G.ship
    if s and not s.alive then
        G.deadT = G.deadT - dt
        if G.deadT <= 0 then
            if G.ships <= 0 then
                Harness.count("gameovers")
                Attract.gameOver()
                return
            end
            if G.view == "mission" then Mission.abandon() end
            G.fuel = C.FUEL_MAX -- every ship launches with a full tank
            G.fuelOut = false
            System.respawn()
        end
    end

    if G.view == "system" then
        System.update(dt)
    else
        Mission.update(dt)
    end
end

local function ambient(_dt)
    if #G.planets == 0 then
        System.newPlanets()
    end
end

Harness.shotPath = "phosphor/build/gravitywells-shot.png"

Harness.extra = function(t)
    t.state = Attract.state
    t.view = G.view
    t.score = G.score
    t.fuel = math.floor(G.fuel)
    t.ships = G.ships
    t.system = G.system
end

Attract.setup({
    title = "GRAVITY WELLS",
    controls = {
        "CRANK - ROTATE   B/UP - THRUST",
        "A - FIRE   DOWN - TRACTOR BEAM",
        "RAID THE WELLS  AVOID THE STAR",
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
