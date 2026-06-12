-- Trenchfire — wireframe rail assault for Playdate (Phosphor package).
-- An original implementation of the 1983 arcade rail-shooter's design:
-- assault on the fortress canyon. D-pad steers the crosshair (the ship
-- chases it on rails), crank is the throttle (faster = higher score
-- multiplier), A/B fires corner lasers converging on the crosshair.
-- Survive fighters, the tower field, then thread the trench and put a
-- shot through the fortress port. Shields are the lives.

import "lib"

import "config"
import "gamestate"
import "world"
import "input"
import "draw"

local clamp = Util.clamp

local function startGame()
    G.score = 0
    G.shields = C.START_SHIELDS
    G.camX, G.camY = 0, 26
    G.crossX, G.crossY = Proj.cx, Proj.cy
    G.throttle = 0.45
    G.fireT, G.invulnT, G.scrapeT = 0, 0, 0
    G.lasers = {}
    World.startLevel(1)
    Harness.count("games")
    Sfx.fanfare({ 523, 784, 1047 }, 0.09)
end

local function updatePlay(dt)
    local mx, my, fire, throttle = Input.gather()
    G.throttle = throttle or G.throttle

    -- crosshair under the d-pad, clamped to the screen
    G.crossX = clamp(G.crossX + mx * C.CROSS_SPEED * dt, C.CROSS_MARGIN, Field.W - C.CROSS_MARGIN)
    G.crossY = clamp(G.crossY + my * C.CROSS_SPEED * dt, C.CROSS_MARGIN, Field.H - C.CROSS_MARGIN)

    -- the ship eases toward where the crosshair points (rail movement)
    local lo, hi = World.vertRange()
    local wantX = (G.crossX - Proj.cx) / (Field.W / 2) * World.latRange()
    local wantY = (lo + hi) / 2 - (G.crossY - Proj.cy) / (Field.H / 2) * (hi - lo) / 2
    local e = 1 - math.exp(-C.EASE * dt)
    G.camX = G.camX + (wantX - G.camX) * e
    G.camY = G.camY + (wantY - G.camY) * e
    G.camZ = G.camZ + World.speed() * dt
    Proj.setCamera(G.camX, G.camY, G.camZ, 0, 0)

    if G.fireT > 0 then G.fireT = G.fireT - dt end
    if fire then World.fire() end

    World.update(dt)
end

Harness.shotPath = "phosphor/build/trenchfire-shot.png"

Harness.extra = function(t)
    t.state = Attract.state
    t.score = G.score
    t.shields = G.shields
    t.level = G.level
    t.phase = G.phase
end

Attract.setup({
    title = "TRENCHFIRE",
    controls = {
        "D-PAD - CROSSHAIR",
        "CRANK - THROTTLE",
        "A OR B - FIRE",
    },
    hooks = {
        start = startGame,
        update = updatePlay,
        draw = Draw.play,
        ambient = Draw.tickAmbient,
        drawAmbient = Draw.ambient,
        score = function() return G.score end,
    },
})
