-- Rubble — vector rock-blasting for Playdate (Phosphor package).
-- An original implementation of the 1979 arcade classic's design.
-- Crank spins the ship 1:1; B/up thrusts, A fires, down = hyperspace.

import "lib"

import "config"
import "gamestate"
import "ship"
import "rocks"
import "input"
import "draw"

local clamp = Util.clamp

local function startGame()
    G.score = 0
    G.lives = C.START_LIVES
    G.nextLifeAt = C.EXTRA_LIFE_AT
    G.wave = 0
    G.rocks, G.shots, G.saucerShots = {}, {}, {}
    G.saucer = nil
    G.saucerT = C.SAUCER_EVERY
    G.ship = Ship.new()
    G.respawnT, G.waveT, G.beatT = 0, 0, 0
    Rocks.spawnWave()
    Harness.count("games")
end

local function updateHeartbeat(dt)
    G.beatT = G.beatT - dt
    if G.beatT <= 0 then
        G.beatT = clamp(0.25 + #G.rocks * 0.09, 0.3, 1.2)
        Sfx.beat()
    end
end

local function updatePlay(dt)
    local turn, thrust, fire, hyper = Input.gather()

    if G.ship.alive then
        Ship.update(turn, thrust, fire, hyper)
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

    Rocks.update()
    Rocks.updateSaucer()
    Rocks.updateSaucerShots()
    Ship.updateShots()
    Rocks.collide()
    updateHeartbeat(dt)

    if #G.rocks == 0 and not G.saucer then
        G.waveT = G.waveT + dt
        if G.waveT > 2 then
            G.waveT = 0
            Rocks.spawnWave()
            Harness.count("waves")
        end
    end
end

local function ambient(dt)
    if #G.rocks == 0 then
        for _ = 1, 5 do
            Rocks.add("large", math.random(0, Field.W), math.random(0, Field.H))
        end
    end
    Rocks.update()
end

Harness.shotPath = "/Users/sdwfrost/Projects/playdate/phosphor/build/rubble-shot.png"

Harness.extra = function(t)
    t.state = Attract.state
    t.score = G.score
    t.lives = G.lives
    t.wave = G.wave
    t.rocks = #G.rocks
end

Attract.setup({
    title = "RUBBLE",
    controls = {
        "CRANK - SPIN SHIP",
        "B OR UP - THRUST",
        "A - FIRE   DOWN - HYPERSPACE",
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
