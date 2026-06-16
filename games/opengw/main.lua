-- Open Geometry Wars — a Phosphor port of the twin-stick grid shooter.
-- D-pad flies the ship, the crank is an absolute aim dial (autofire is always
-- on), B drops a smart bomb. The arena is a warping spring grid that the
-- ship, your shots, bombs, and gravity wells dent and ripple. An original
-- implementation built on the shared cabinet; source design in opengw/.

import "lib"

import "config"
import "gamestate"
import "player"
import "enemies"
import "spawner"
import "input"
import "draw"

Grid.init({ spacing = C.GRID_SPACING })

local function startGame()
    G.score = 0
    G.lives = C.START_LIVES
    G.bombs = C.START_BOMBS
    G.mult, G.killCounter = 1, 0
    G.lifeCounter, G.bombCounter, G.weaponCounter = 0, 0, 0
    G.weapon = 0
    G.shots, G.enemies = {}, {}
    G.bombWave = nil
    G.bombT, G.respawnT = 0, 0
    G.ship = Player.new()
    Grid.reset()
    Spawner.reset()
    for _ = 1, 4 do
        local x, y = math.random(40, Field.W - 40), math.random(40, Field.H - 40)
        Enemies.spawn("grunt", x, y, true)
    end
    Harness.count("games")
end

local function updateBomb(dt)
    if G.bombT > 0 then G.bombT = G.bombT - dt end
    local w = G.bombWave
    if w then
        w.r = w.r + C.BOMB_GROW * dt
        Grid.push(w.x, w.y, 200, w.r)
        Enemies.bombDamage(w)
        if w.r > C.BOMB_RADIUS then G.bombWave = nil end
    end
end

local function updatePlay(dt)
    local mvx, mvy, aim, bomb = Input.gather()

    if G.ship.alive then
        Player.update(dt, mvx, mvy, aim, bomb)
    else
        G.respawnT = G.respawnT - dt
        if G.respawnT <= 0 then
            if G.lives <= 0 then
                Harness.count("gameovers")
                Attract.gameOver()
                return
            end
            Player.respawn()
        end
    end

    Player.updateShots(dt)
    Spawner.update(dt)
    Enemies.update(dt)
    updateBomb(dt)
    Grid.update(dt)
end

-- title / game-over backdrop: keep the grid breathing and a few drifters
-- loose. The ship sits dead at centre so enemy AI has a (harmless) target.
local function ambient(dt)
    G.ship = G.ship or Player.new()
    G.ship.alive = false
    G.shots = {}
    if #G.enemies < 5 then
        local x, y = math.random(30, Field.W - 30), math.random(30, Field.H - 30)
        Enemies.spawn("wander", x, y, false)
    end
    Enemies.update(dt)
    Grid.update(dt)
    if Attract.frame % 50 == 0 then
        Grid.push(math.random(0, Field.W), math.random(0, Field.H), 260, 90)
    end
end

Harness.shotPath = "phosphor/build/opengw-shot.png"

Harness.extra = function(t)
    t.state = Attract.state
    t.score = G.score
    t.lives = G.lives
    t.bombs = G.bombs
    t.mult = G.mult
    t.enemies = #G.enemies
end

Attract.setup({
    title = "GEOMETRY WARS",
    controls = {
        "D-PAD - FLY",
        "CRANK - AIM (AUTOFIRE)",
        "B - SMART BOMB",
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
