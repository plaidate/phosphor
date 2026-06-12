-- Welldiver — vector tube diving for Playdate (Phosphor package).
-- An original implementation of the 1981 arcade classic's design.
-- The crank is the spinner: one revolution sweeps the claw around all 16
-- lanes. B fires, A triggers the Superzapper. Clear the well, dive to the
-- next one — pick a deeper starting level on the title for bonus points.

import "lib"

import "config"
import "gamestate"
import "wells"
import "player"
import "enemies"
import "shots"
import "input"
import "draw"

local clamp = Util.clamp

local function setupLevel(level)
    G.level = level
    G.well = Wells.forLevel(level)
    G.player = Player.new()
    G.enemies, G.pShots, G.eShots = {}, {}, {}
    G.spawnQ = {}
    G.spikes = {}
    G.zapsUsed = 0
    G.zapBolt = 0
    G.warpE = nil
    G.warpStreaks, G.warpRings = {}, {}
    Enemies.queueWave(level)
end

local function startGame()
    G.score = C.START_BONUS[G.startIdx]
    G.lives = C.START_LIVES
    G.nextLifeAt = C.EXTRA_LIFE_AT
    G.respawnT, G.rechargeT, G.beatT = 0, 0, 0
    G.mode = "play"
    setupLevel(C.START_LEVELS[G.startIdx])
    Harness.count("games")
    Sfx.fanfare({ 523, 784, 1047 }, 0.09)
end

local function gameOver()
    G.warpE = nil
    G.mode = "play"
    Harness.count("gameovers")
    Attract.gameOver()
end

local function startWarp()
    G.mode = "warp"
    G.warpZ = 1
    G.ringT = 0
    G.pShots, G.eShots = {}, {}
    G.warpStreaks, G.warpRings = {}, {}
    Harness.count("waves")
    Sfx.fanfare({ 330, 460, 590, 720, 850, 980 }, 0.1)
end

local function finishWarp()
    setupLevel(G.level + 1)
    G.mode = "play"
    G.rechargeT = 1.4
    Sfx.fanfare({ 523, 784, 1047 }, 0.09)
end

-- the cabinet heartbeat, quickening as the well fills
local function heartbeat(dt)
    G.beatT = G.beatT - dt
    if G.beatT <= 0 then
        G.beatT = clamp(1.25 - G.level * 0.04 - #G.enemies * 0.05, 0.4, 1.25)
        Sfx.beat()
    end
end

local function updatePlay(dt)
    local move, fire, zap = Input.gather()
    if G.rechargeT > 0 then G.rechargeT = G.rechargeT - dt end
    if G.zapBolt > 0 then G.zapBolt = G.zapBolt - dt end

    if G.player.alive then
        Player.move(move)
        if G.player.fireT > 0 then G.player.fireT = G.player.fireT - dt end
        if fire then Player.fire() end
        if zap then Player.superzap() end
    else
        G.respawnT = G.respawnT - dt
        if G.respawnT <= 0 then
            if G.lives <= 0 then
                gameOver()
                return
            end
            Player.respawn()
        end
    end

    Enemies.updateSpawnQ()
    Enemies.update()
    Enemies.updateShots()
    Shots.update(C.SHOT_SPEED)
    heartbeat(dt)

    -- wave cleared: fly down the well (spikes permitting)
    if G.player.alive and #G.enemies == 0 and #G.spawnQ == 0 then
        startWarp()
    end
end

local function updateWarpFx(dt)
    -- star streaks radiating from the depths
    if #G.warpStreaks < 70 then
        for _ = 1, 2 do
            G.warpStreaks[#G.warpStreaks + 1] = {
                a = math.random() * math.pi * 2,
                d = 6 + math.random(20),
                v = 160 + math.random(240),
            }
        end
    end
    for i = #G.warpStreaks, 1, -1 do
        local s = G.warpStreaks[i]
        s.v = s.v * 1.05
        s.d = s.d + s.v * dt
        if s.d > 260 then table.remove(G.warpStreaks, i) end
    end

    -- well outlines rushing outward past the camera
    G.ringT = G.ringT - dt
    if G.ringT <= 0 then
        G.ringT = 0.22
        G.warpRings[#G.warpRings + 1] = { z = 0.02 }
    end
    for i = #G.warpRings, 1, -1 do
        local r = G.warpRings[i]
        r.z = r.z + 0.9 * dt
        if r.z >= 1 then table.remove(G.warpRings, i) end
    end
end

local function updateWarp(dt)
    local move, fire = Input.gather()
    Player.move(move)
    if G.player.fireT > 0 then G.player.fireT = G.player.fireT - dt end
    if fire then Player.fire() end

    G.warpZ = G.warpZ - dt / C.WARP_DURATION
    G.warpE = 0.08 + 1.52 * math.max(G.warpZ, 0) ^ 1.5

    updateWarpFx(dt)
    Shots.update(C.WARP_SHOT_SPEED)

    -- a spike taller than our depth is a hull breach
    local lane = Player.lane()
    if (G.spikes[lane] or 0) >= G.warpZ and G.warpZ > 0 then
        G.lives = G.lives - 1
        G.spikes[lane] = 0 -- the wreck clears the lane
        local x, y = Wells.laneCenter(G.well, lane, G.warpZ)
        G.burst(x, y, 12)
        Fx.debris(x, y, 8)
        Harness.count("warpDeaths")
        Sfx.descend()
        if G.lives <= 0 then
            gameOver()
            return
        end
    end

    if G.warpZ <= 0 then
        finishWarp()
    end
end

local function updateGame(dt)
    if G.mode == "warp" then
        updateWarp(dt)
    else
        updatePlay(dt)
    end
end

-- starting-level select, live on the title screen: crank or left/right
local selAccum = 0
local function ambient(dt)
    if Attract.state ~= "title" or Harness.enabled then return end
    selAccum = selAccum + playdate.getCrankChange()
    local idx = G.startIdx
    while selAccum >= 60 do
        selAccum = selAccum - 60
        idx = idx + 1
    end
    while selAccum <= -60 do
        selAccum = selAccum + 60
        idx = idx - 1
    end
    if playdate.buttonJustPressed(playdate.kButtonRight) then idx = idx + 1 end
    if playdate.buttonJustPressed(playdate.kButtonLeft) then idx = idx - 1 end
    idx = clamp(idx, 1, #C.START_LEVELS)
    if idx ~= G.startIdx then
        G.startIdx = idx
        Sfx.blip(440 + idx * 110)
    end
end

Harness.shotPath = "phosphor/build/welldiver-shot.png"

Harness.extra = function(t)
    t.state = Attract.state
    t.mode = G.mode
    t.score = G.score
    t.level = G.level
end

-- the title screen draws a well behind the logo
G.well = Wells.forLevel(1)
G.player = Player.new()

Attract.setup({
    title = "WELLDIVER",
    controls = {
        "CRANK - SPIN THE CLAW",
        "B - FIRE   A - SUPERZAPPER",
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
