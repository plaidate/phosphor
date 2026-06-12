-- Lifters — vector canister-theft defense for Playdate (Phosphor package).
-- An original implementation of the 1980 arcade raid's design.
-- Raiders fly in, latch onto your fuel canisters, and drag them off the
-- screen edge. Ships are unlimited; the game ends only when the last
-- canister is gone. Crank spins the ship 1:1; B/up thrusts, A fires.

import "lib"

import "gamestate"
import "ship"
import "raiders"
import "input"
import "draw"

local function spawnCanisters()
    G.canisters = {}
    local cx, cy = Field.W / 2, Field.H / 2
    for i = 0, C.CANISTERS - 1 do
        local col, row = i % 4, i // 4
        G.canisters[#G.canisters + 1] = {
            x = cx + (col - 1.5) * 22,
            y = cy + (row - 0.5) * 24,
            carrier = nil, -- raider currently dragging it
            claimed = nil, -- raider flying in to take it
            inPlay = true,
        }
    end
end

local function startGame()
    G.score = 0
    G.wave = 0
    G.raiders, G.shots, G.raiderShots = {}, {}, {}
    G.ship = Ship.new()
    G.respawnT, G.waveT = 0, 0
    G.sirenT = 0
    spawnCanisters()
    Raiders.spawnWave()
    Harness.count("games")
end

-- the theft alarm: a two-tone siren whenever fuel is being dragged
local function updateSiren(dt)
    local dragging = false
    for _, rd in ipairs(G.raiders) do
        if rd.state == "drag" then dragging = true break end
    end
    if not dragging then return end
    G.sirenT = G.sirenT - dt
    if G.sirenT <= 0 then
        G.sirenT = 0.34
        Sfx.sirenTick()
    end
end

local function updatePlay(dt)
    local turn, thrust, fire = Input.gather()

    if G.ship.alive then
        Ship.update(turn, thrust, fire)
    else
        -- ships are unlimited: dying only costs C.RESPAWN_T seconds
        G.respawnT = G.respawnT - dt
        if G.respawnT <= 0 then
            Ship.respawn()
        end
    end

    Raiders.update(dt)
    Raiders.updateShots(dt)
    Ship.updateShots()
    Raiders.collide()
    updateSiren(dt)

    -- the only way to lose: every canister stolen
    if G.canistersLeft() == 0 then
        Harness.count("gameovers")
        Attract.gameOver()
        return
    end

    -- seamless wave flow: the next raid scrambles moments after the last
    if #G.raiders == 0 then
        G.waveT = G.waveT + dt
        if G.waveT >= C.WAVE_GAP then
            G.waveT = 0
            Raiders.spawnWave()
        end
    else
        G.waveT = 0
    end
end

-- title/over backdrop: a loose patrol of raiders cruising the screen
local function ambient(dt)
    if #G.drift == 0 then
        local kinds = { "lifter", "lifter", "gunner", "rammer" }
        for i = 1, #kinds do
            G.drift[#G.drift + 1] = {
                x = math.random(0, Field.W),
                y = math.random(30, Field.H - 30),
                vx = (math.random() < 0.5 and -1 or 1) * (22 + math.random(28)),
                vy = math.random(-10, 10),
                kind = kinds[i],
            }
        end
    end
    for _, d in ipairs(G.drift) do
        d.x = d.x + d.vx * dt
        d.y = d.y + d.vy * dt
        if d.x < -20 then d.x = Field.W + 20 elseif d.x > Field.W + 20 then d.x = -20 end
        if d.y < -20 then d.y = Field.H + 20 elseif d.y > Field.H + 20 then d.y = -20 end
    end
end

Harness.shotPath = "phosphor/build/lifters-shot.png"

Harness.extra = function(t)
    t.state = Attract.state
    t.score = G.score
    t.canisters = G.canistersLeft()
    t.wave = G.wave
end

Attract.setup({
    title = "LIFTERS",
    controls = {
        "CRANK - SPIN SHIP",
        "B OR UP - THRUST   A - FIRE",
        "GUARD THE FUEL CANISTERS",
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
