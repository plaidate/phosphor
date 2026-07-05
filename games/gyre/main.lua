-- Gyre — vector orbit gunnery for Playdate (Phosphor package).
-- An original implementation of the 1983 tube-shooter's design: the ship
-- rides the rim of the screen (the crank flies it), squadrons swoop out
-- of the deep in looping chains, satellites carry the twin cannons, and
-- every third warp reaches a planet and a chance stage.

import "lib"

import "config"
import "gamestate"
import "stars"
import "paths"
import "player"
import "enemies"
import "events"
import "stage"
import "input"
import "draw"

local function warpBanner()
    local planet = C.PLANETS[G.planetIdx]
    if G.warpsLeft == 1 then
        return "1 WARP TO " .. planet
    end
    return G.warpsLeft .. " WARPS TO " .. planet
end

local function startGame()
    G.score = 0
    G.nextLifeAt = C.EXTRA_LIFE_EVERY
    G.lives = C.START_LIVES
    G.stage = 1
    G.planetIdx = 1
    G.warpsLeft = C.WARPS_PER_PLANET
    G.chance = false
    G.respawnT = 0
    G.player = Player.new()
    G.shots = {}
    Enemies.reset()
    Events.reset()
    Stars.init()
    Stage.begin(G.stage)
    G.mode = "intro"
    G.modeT = 1.8
    G.banner(warpBanner(), 1.8)
    Harness.count("games")
    Sfx.fanfare({ 523, 659, 784, 1047 }, 0.09)
end

local function gameOver()
    Harness.count("gameovers")
    Attract.gameOver()
end

local function controlPlayer(dt)
    local p = G.player
    if p.invulnT > 0 then p.invulnT = p.invulnT - dt end
    if p.fireT > 0 then p.fireT = p.fireT - dt end
    if p.alive then
        local move, fire = Input.gather()
        Player.move(move)
        if fire then Player.fire() end
    end
end

local function updatePlay(dt)
    controlPlayer(dt)
    local p = G.player

    Stage.update(dt)
    Enemies.update(dt)
    Events.update(dt)
    Player.updateShots(dt)
    Enemies.collide()

    if not p.alive then
        G.respawnT = G.respawnT - dt
        if G.respawnT <= 0 then
            if G.lives <= 0 then
                gameOver()
                return
            end
            Player.respawn()
        end
        return
    end

    if G.chance then
        if Stage.chanceOver() then
            if Stage.perfect >= C.CHANCE_SQUADS then
                G.addScore(C.PTS_CHANCE_ALL)
                G.pop("ALL PERFECT +" .. C.PTS_CHANCE_ALL, 2)
                Sfx.fanfare({ 523, 659, 784, 1047, 1319 }, 0.09)
            end
            G.mode = "tally"
            G.modeT = 2.4
            Harness.count("chances")
        end
    elseif Stage.isClear() then
        G.mode = "clear"
        G.modeT = 1.1
        Sfx.fanfare({ 659, 784, 988 }, 0.09)
        Harness.count("stageClears")
    end
end

local function startWarp()
    G.shots, G.bullets, G.meteors = {}, {}, {}
    G.beam = nil
    G.mode = "warp"
    G.modeT = 2.2
    Sfx.descend()
    Harness.count("warps")
end

local function afterWarp()
    G.stage = G.stage + 1
    if G.warpsLeft <= 0 then
        -- planet reached: the chance stage plays over it
        Stage.beginChance()
        G.mode = "intro"
        G.modeT = 2
        G.banner(C.PLANETS[G.planetIdx] .. " - CHANCE", 2)
        Sfx.fanfare({ 784, 988, 1175, 1568 }, 0.1)
        Harness.count("planets")
    else
        Stage.begin(G.stage)
        G.mode = "intro"
        G.modeT = 1.8
        G.banner(warpBanner(), 1.8)
    end
end

local function updateGame(dt)
    G.time = G.time + dt
    G.formA = (G.formA + C.FORM_SPIN * dt) % 360
    if G.bannerT > 0 then G.bannerT = G.bannerT - dt end
    if G.popT > 0 then G.popT = G.popT - dt end
    Stars.update(dt, G.mode == "warp" and 6 or 1)

    if G.mode == "play" then
        updatePlay(dt)
    else
        controlPlayer(dt)
        Player.updateShots(dt)
        G.modeT = G.modeT - dt
        if G.modeT <= 0 then
            if G.mode == "intro" then
                G.mode = "play"
            elseif G.mode == "clear" then
                G.warpsLeft = G.warpsLeft - 1
                startWarp()
            elseif G.mode == "warp" then
                afterWarp()
            elseif G.mode == "tally" then
                G.chance = false
                G.planetIdx = (G.planetIdx % #C.PLANETS) + 1
                G.warpsLeft = C.WARPS_PER_PLANET
                startWarp()
            end
        end
    end
end

local function ambient(dt)
    Stars.update(dt, 1)
end

Harness.shotPath = "build/gyre-shot.png"

Harness.extra = function(t)
    t.state = Attract.state
    t.mode = G.mode
    t.score = G.score
    t.stage = G.stage
    t.planet = G.planetIdx
    t.warpsLeft = G.warpsLeft
    t.chance = G.chance and 1 or 0
    t.enemies = G.enemies and #G.enemies or 0
    t.lives = G.lives
end

-- the title screen shows the tunnel flowing behind the logo
G.player = Player.new()
G.shots = {}
Enemies.reset()
Events.reset()
Stars.init()

Attract.setup({
    title = "GYRE",
    controls = {
        "CRANK - FLY THE RIM",
        "A OR B - FIRE",
    },
    hooks = {
        start = startGame,
        update = updateGame,
        draw = Draw.play,
        ambient = ambient,
        drawAmbient = Draw.ambient,
        score = function() return G.score end,
    },
})
