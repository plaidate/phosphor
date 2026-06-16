-- Treadline — first-person vector tank combat for Playdate (Phosphor).
-- An original implementation of the 1980 arcade classic's design.
-- D-pad drives the treads (up/down both, left/right pivot, combine for an
-- arc); the crank slews the turret and the view; A or B fires. One hostile
-- stalks at a time — every third spawn is a ramming skimmer.

import "lib"

import "config"
import "gamestate"
import "world"
import "tanks"
import "input"
import "draw"

local function startGame()
    G.score, G.lives, G.nextLifeAt = 0, C.START_LIVES, C.EXTRA_LIFE_AT
    G.kills, G.spawnN = 0, 0
    G.px, G.pz, G.hullYaw, G.turretOff = 0, 0, 0, 0
    G.pvx, G.pvz = 0, 0
    G.shell, G.eShell, G.enemy = nil, nil, nil
    G.spawnT, G.pingT = 1.5, 0
    G.dead, G.respawnT, G.invuln, G.crackT = false, 0, 0, 0
    World.scatter()
    Harness.count("games")
end

local function updatePlay(dt)
    local drive, turn, crank, fire = Input.gather()

    if G.dead then
        G.respawnT = G.respawnT - dt
        if G.respawnT <= 0 then
            if G.lives <= 0 then
                G.shell, G.eShell = nil, nil
                Harness.count("gameovers")
                Attract.gameOver()
                return
            end
            Tanks.respawnPlayer()
        end
    else
        Tanks.movePlayer(drive, turn, crank, dt)
        if fire then Tanks.fire() end
    end

    if G.invuln > 0 then G.invuln = G.invuln - dt end
    if G.crackT > 0 then G.crackT = G.crackT - dt end

    Tanks.updateShells(dt)
    Tanks.updateEnemy(dt)
    World.recycle()
    World.updateFrags(dt)
end

local function ambient(dt)
    G.ambYaw = (G.ambYaw + dt * 9) % 360
    World.updateFrags(dt)
end

Harness.shotPath = "build/treadline-shot.png"

Harness.extra = function(t)
    t.state = Attract.state
    t.score = G.score
    t.lives = G.lives
end

Attract.setup({
    title = "TREADLINE",
    controls = {
        "D-PAD - DRIVE THE TREADS",
        "CRANK - SLEW TURRET",
        "A OR B - FIRE",
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

-- the title screen pans across a live battlefield
World.scatter()
