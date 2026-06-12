-- Webguard — vector web-defense for Playdate (Phosphor package).
-- An original implementation of the 1983 arcade twin-stick design:
-- d-pad scuttles the spider around its web, the crank aims 1:1,
-- A or B holds autofire. Keep the web clear; mind the eggs.

import "lib"

import "config"
import "web"
import "player"
import "enemies"
import "input"
import "draw"

local function startGame()
    G.score = 0
    G.lives = C.START_LIVES
    G.nextLifeAt = C.EXTRA_LIFE_AT
    G.wave = 0
    G.speedScale = 1
    G.player = Player.new()
    G.shots, G.chasers, G.layers = {}, {}, {}
    G.bombers, G.eggs, G.frags = {}, {}, {}
    G.spawnQ, G.spawnT = {}, 0
    G.respawnT, G.waveT, G.bannerT = 0, 0, 0
    Enemies.nextWave()
    Harness.count("games")
end

local function updatePlay(dt)
    local mx, my, aimD, fire = Input.gather()

    if G.bannerT > 0 then G.bannerT = G.bannerT - dt end

    if G.player.alive then
        Player.update(mx, my, aimD, fire)
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

    Enemies.update()
    Player.updateShots()
    Enemies.collide()

    if Enemies.cleared() then
        G.waveT = G.waveT + dt
        if G.waveT > 2 then
            G.waveT = 0
            Enemies.nextWave()
        end
    end
end

Harness.shotPath = "/Users/sdwfrost/Projects/playdate/phosphor/build/webguard-shot.png"

Harness.extra = function(t)
    t.state = Attract.state
    t.score = G.score
    t.lives = G.lives
    t.wave = G.wave
end

Attract.setup({
    title = "WEBGUARD",
    controls = {
        "D-PAD - MOVE SPIDER",
        "CRANK - AIM",
        "HOLD A OR B - FIRE",
    },
    hooks = {
        start = startGame,
        update = updatePlay,
        draw = Draw.play,
        drawAmbient = Draw.ambient,
        score = function() return G.score end,
    },
})
