-- Elite — vector space combat and trading for Playdate (Phosphor package).
-- An original implementation of the 1984 classic's flight model: the player is
-- the camera at the origin and the whole universe rotates and slides around
-- them. Controls follow the NES port (crank rolls, d-pad pitches, A fires,
-- B + up/down is the throttle).
--
-- Playdate SDK reference (CoreLibs, playdate.* API, the Simulator):
--   https://sdk.play.date/3.0.6/Inside%20Playdate.html

import "lib"

import "config"
import "ships"
import "galaxy"
import "trade"
import "gamestate"
import "world"
import "input"
import "draw"
import "docked"

local function startGame()
    World.reset()
end

local function updatePlay(dt)
    if G.docked then
        Docked.update(dt)
        return
    end
    local roll, pitch, fire = Input.gather()
    G.roll, G.pitch, G.firing = roll, pitch, fire
    World.update(dt)
    if G.destroyed then
        Harness.count("gameovers")
        Attract.gameOver()
    end
end

local function drawPlay()
    if G.docked then
        Docked.draw()
    else
        Draw.play()
    end
end

Harness.shotPath = "/Users/lshsf3/Projects/playdate/phosphor/build/elite-shot.png"

Harness.extra = function(t)
    t.state = Attract.state
    t.score = G.score
    t.system = G.sysName
    t.galaxy = G.galaxyNum
    t.fuel = G.fuel
    t.kills = G.kills
    t.pirates = G.pirates
    t.energy = math.floor(G.energy)
    t.speed = math.floor(G.speed)
end

-- the player sits at the origin looking down +Z; objects move around them
Proj.cx = 200
Proj.cy = C.VIEW_CY
Proj.focal = C.FOCAL
Proj.setCamera(0, 0, 0, 0, 0)

Attract.setup({
    title = "ELITE",
    controls = {
        "CRANK - ROLL   UP/DOWN - PITCH",
        "A - FIRE LASER",
        "B + UP/DOWN - THROTTLE   DOCK TO JUMP",
    },
    hooks = {
        start = startGame,
        update = updatePlay,
        draw = drawPlay,
        drawAmbient = Draw.ambient,
        score = function() return G.score end,
    },
})
