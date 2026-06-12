-- Duelstar — vector space duel for Playdate (Phosphor package).
-- An original implementation of the 1977-style two-ship gravity duel:
-- you vs the RIVAL around a killing sun, first to five rounds.
-- Crank turns the ship 1:1; B/up thrusts, A fires, down = hyperspace.

import "lib"

import "config"
import "gamestate"
import "ships"
import "rival"
import "input"
import "draw"

local function spawnShips()
    -- opposite sides of the sun, noses at each other, tangential velocity
    -- so neither ship starts in a death dive
    local a = math.random() * 360
    local ax, ay = Vec.fromAngle(a, C.SPAWN_DIST)
    local v = math.sqrt(C.GRAV_MU / C.SPAWN_DIST) * 0.85
    local tvx, tvy = Vec.fromAngle(a + 90, v)
    G.player = Ships.new("player", C.SUN_X + ax, C.SUN_Y + ay, tvx, tvy, a + 180)
    G.rival = Ships.new("rival", C.SUN_X - ax, C.SUN_Y - ay, -tvx, -tvy, a)
end

local function nextRound()
    G.round = G.round + 1
    G.pShots, G.rShots = {}, {}
    spawnShips()
    Rival.newBrain()
    G.phase = "fight"
    G.msg = nil
    G.introT = C.INTRO_TIME
end

local function startGame()
    G.score = 0
    G.pWins, G.rWins = 0, 0
    G.round = 0
    nextRound()
    Harness.count("games")
end

local function endRound(winner)
    G.phase = "between"
    G.phaseT = C.ROUND_PAUSE
    if winner == "player" then
        G.pWins = G.pWins + 1
        G.addScore(C.PTS_ROUND)
        Harness.count("rounds")
        G.msg = G.pWins >= C.WINS_TO_MATCH and "MATCH TO YOU" or "ROUND TO YOU"
        Sfx.fanfare()
    elseif winner == "rival" then
        G.rWins = G.rWins + 1
        Harness.count("roundLosses")
        G.msg = G.rWins >= C.WINS_TO_MATCH and "MATCH TO RIVAL" or "ROUND TO RIVAL"
        Sfx.descend()
    else
        G.msg = "DEAD HEAT" -- mutual destruction: no tally, fight again
        Sfx.descend()
    end
end

local function updatePlay(dt)
    if G.introT > 0 then G.introT = G.introT - dt end

    if G.phase == "between" then
        Ships.drift(G.player)
        Ships.drift(G.rival)
        Ships.updateShots(G.pShots)
        Ships.updateShots(G.rShots)
        G.phaseT = G.phaseT - dt
        if G.phaseT <= 0 then
            if G.pWins >= C.WINS_TO_MATCH then
                G.addScore(C.PTS_MATCH)
                Harness.count("matches")
                Harness.count("gameovers")
                Attract.gameOver()
            elseif G.rWins >= C.WINS_TO_MATCH then
                Harness.count("gameovers")
                Attract.gameOver()
            else
                nextRound()
            end
        end
        return
    end

    local turn, thrust, fire, hyper = Input.gather()
    Ships.control(G.player, turn, thrust, fire, hyper, G.pShots)

    local rt, rth, rf, rh = Rival.think()
    Ships.control(G.rival, rt, rth, rf, rh, G.rShots)

    Ships.updateShots(G.pShots)
    Ships.updateShots(G.rShots)
    Ships.collide()

    local pDead, rDead = not G.player.alive, not G.rival.alive
    if pDead or rDead then
        local winner
        if pDead and rDead then
            winner = nil
        elseif pDead then
            winner = "rival"
        else
            winner = "player"
        end
        endRound(winner)
    end
end

Harness.shotPath = "phosphor/build/duelstar-shot.png"

Harness.extra = function(t)
    t.state = Attract.state
    t.score = G.score
    t.pWins = G.pWins
    t.rWins = G.rWins
end

Attract.setup({
    title = "DUELSTAR",
    controls = {
        "CRANK - TURN SHIP",
        "B OR UP - THRUST   A - FIRE",
        "DOWN - HYPERSPACE",
        "FIRST TO 5 ROUNDS",
    },
    hooks = {
        start = startGame,
        update = updatePlay,
        draw = Draw.play,
        drawAmbient = Draw.ambient,
        score = function() return G.score end,
    },
})
