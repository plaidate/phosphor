-- Border Circuit — vector arena racing for Playdate (Phosphor package).
-- An original implementation of the 1981 arcade racer-shooter's design:
-- a walled track around a central scoreboard, a frictionless ship that
-- caroms off every border, drones that lap faster and faster, and mine
-- layers seeding the gutter behind them. Crank steers 1:1 (the cabinet
-- had a spinner); B/up thrusts, A fires, walls do the braking.

import "lib"

import "config"
import "gamestate"
import "arena"
import "ship"
import "enemies"
import "input"
import "draw"

local function startGame()
    G.score = 0
    G.lives = C.START_LIVES
    G.nextLifeAt = C.EXTRA_LIFE_AT
    G.wave = 0
    G.droneKills = 0
    G.shots, G.eshots = {}, {}
    G.drones, G.layers, G.mines = {}, {}, {}
    G.ship = Ship.new()
    G.respawnT, G.waveT = 0, 0
    Enemies.spawnWave()
    Harness.count("games")
end

local function updatePlay(dt)
    local turn, thrust, fire = Input.gather()

    if G.ship.alive then
        Ship.update(turn, thrust, fire)
    else
        G.respawnT = G.respawnT - dt
        if G.respawnT <= 0 then
            if G.lives <= 0 then
                Harness.count("gameovers")
                Attract.gameOver()
                return
            end
            Ship.respawn()
        end
    end

    Ship.updateShots()
    Enemies.update(dt)
    Enemies.collide()

    -- wave clears when the drones and layers are gone; mines stay put
    if #G.drones == 0 and #G.layers == 0 then
        G.waveT = G.waveT + dt
        if G.waveT > 2 then
            Enemies.spawnWave()
        end
    end
end

-- behind the title and game-over cards: drones lapping the track
local function ambient(dt)
    if #G.drones == 0 then
        for k = 1, 4 do
            local x, y = Arena.waypoint(k)
            Enemies.addDrone(x, y, math.random() < 0.5 and 1 or -1, C.DRONE_V0 + 30, k)
        end
    end
    Enemies.updateDrones(dt)
end

Harness.shotPath = "build/bordercircuit-shot.png"

Harness.extra = function(t)
    t.state = Attract.state
    t.score = G.score
    t.lives = G.lives
    t.wave = G.wave
end

Attract.setup({
    title = "BORDERCIRCUIT",
    controls = {
        "CRANK - STEER SHIP",
        "B OR UP - THRUST",
        "A - FIRE",
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
