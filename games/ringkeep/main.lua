-- Ringkeep — vector ring-fortress siege for Playdate (Phosphor package).
-- An original implementation of the 1980 arcade ring-fortress design:
-- three spinning shield rings guard a tracking core that breathes fire
-- through the gaps. Crank spins the ship 1:1; B/up thrusts, A fires.

import "lib"

import "config"
import "gamestate"
import "ship"
import "castle"
import "input"
import "draw"

local function startGame()
    G.score = 0
    G.lives = C.START_LIVES
    G.wave = 1
    G.speedMul = 1.0
    G.shots = {}
    G.respawnT = 0
    Castle.reset()
    Ship.respawn() -- a safe stand-off berth outside the rings
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

    Castle.update(dt)
    Ship.updateShots()
    Castle.collide()
end

-- behind the title and game-over cards the keep just keeps turning
local function ambient(dt)
    if #G.rings == 0 then Castle.reset() end
    Castle.spinRings(dt)
end

Harness.shotPath = "build/ringkeep-shot.png"

Harness.extra = function(t)
    t.state = Attract.state
    t.score = G.score
    t.lives = G.lives
    t.wave = G.wave
end

Attract.setup({
    title = "RINGKEEP",
    controls = {
        "CRANK - SPIN SHIP",
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
