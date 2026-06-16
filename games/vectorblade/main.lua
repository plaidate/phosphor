-- Vectorblade — a Phosphor port of Malban's Vectrex shooter, itself a take on
-- Deluxe Galaga / Warblade. The fighter holds the bottom of the field, the
-- crank is its spinner, A fires, B drops a smart bomb. Waves stream in along
-- curved paths, lock into a breathing formation, and peel off to dive and
-- fire. Kills drop power-ups; a shop sits between waves; a boss arrives every
-- fifth level; your score earns a naval rank. Built on the shared cabinet.

import "lib"

import "config"
import "gamestate"
import "player"
import "enemies"
import "bonuses"
import "shop"
import "input"
import "draw"

local function startLevel()
    G.swayT = 0
    G.shots, G.eshots = {}, {}
    if G.level % C.BOSS_EVERY == 0 then
        Enemies.spawnBoss(G.level)
        G.mode = "battle"
    else
        Enemies.spawnWave(G.level)
        G.mode = "intro"
    end
end

local function nextLevel()
    G.level = G.level + 1
    startLevel()
    Harness.count("levels")
end

local function startGame()
    G.score, G.cash = 0, C.START_CASH
    G.lives = C.START_LIVES
    G.nextLifeAt = C.EXTRA_LIFE_AT
    G.level = 1
    G.spread = C.START_SPREAD
    G.rateLvl, G.speedLvl = 0, 0
    G.autofire = false
    G.armor, G.bombs = 0, 0
    G.shieldT, G.multT = 0, 0
    G.respawnT = 0
    G.shots, G.enemies, G.eshots, G.bonuses = {}, {}, {}, {}
    G.boss = nil
    G.ship = Player.new()
    startLevel()
    Harness.count("games")
end

local function updatePlay(dt)
    -- fighter lifecycle (death / respawn / game over)
    if not G.ship.alive then
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

    if G.mode ~= "shop" then
        if G.ship.alive then
            local dx, fire, bomb = Input.gather()
            Player.update(dt, dx, fire, bomb)
        end
        Player.updateShots(dt)
        Bonuses.update(dt)
    end

    if G.mode == "intro" then
        if Enemies.updateFlyin(dt) then G.mode = "battle" end
        Enemies.collideShots()
        Enemies.collidePlayer()
    elseif G.mode == "battle" then
        Enemies.updateBattle(dt)
        Enemies.updateBoss(dt)
        Enemies.updateEShots(dt)
        Enemies.collideShots()
        Enemies.collidePlayer()
        if Enemies.cleared() then
            G.mode = "cleared"
            G.clearT = 0
            Sfx.fanfare()
        end
    elseif G.mode == "cleared" then
        Enemies.updateEShots(dt)
        G.clearT = G.clearT + dt
        if G.clearT > 1.8 then
            Shop.enter()
            G.mode = "shop"
        end
    elseif G.mode == "shop" then
        G.eshots = {}
        if Shop.update(dt) then nextLevel() end
    end
end

-- title / game-over backdrop: a ghost wave breathing behind the chrome
local function ambient(dt)
    if Enemies.cleared() then
        G.level = 3
        Enemies.spawnWave(3)
    end
    G.ship = G.ship or Player.new()
    G.ship.alive = false
    if Enemies.allFormed() then
        Enemies.updateBattle(dt)
    else
        Enemies.updateFlyin(dt)
    end
    Enemies.updateEShots(dt)
end

Harness.shotPath = "/Users/sdwfrost/Projects/playdate/phosphor/build/vectorblade-shot.png"

Harness.extra = function(t)
    t.state = Attract.state
    t.mode = G.mode
    t.score = G.score
    t.cash = G.cash
    t.lives = G.lives
    t.level = G.level
    t.enemies = #G.enemies
    t.spread = G.spread
end

Attract.setup({
    title = "VECTORBLADE",
    controls = {
        "CRANK - MOVE   A - FIRE",
        "B - SMART BOMB",
        "CATCH DROPS, SHOP BETWEEN WAVES",
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
