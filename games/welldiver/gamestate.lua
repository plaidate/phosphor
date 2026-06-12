-- Welldiver: shared state. Explosion effects route to the library's Fx pool.

G = {
    mode = "play",     -- play-state submode: "play" | "warp"
    score = 0,
    lives = C.START_LIVES,
    nextLifeAt = C.EXTRA_LIFE_AT,
    level = 1,
    startIdx = 1,      -- index into C.START_LEVELS, chosen on the title screen
    well = nil,        -- current well geometry (see wells.lua)
    player = nil,      -- the claw (see player.lua)
    enemies = {},
    spawnQ = {},       -- { t, type } countdowns
    pShots = {},       -- { lane, z }
    eShots = {},       -- { lane, z, spin }
    spikes = {},       -- [lane 0-indexed] = height (z from the far end)
    zapsUsed = 0,
    zapBolt = 0,       -- seconds of lightning-down-every-lane left to draw
    warpZ = 1,         -- camera depth during the warp (1 = rim, 0 = through)
    warpE = nil,       -- perspective exponent override during warp
    warpStreaks = {},  -- radiating star streaks during the warp
    warpRings = {},    -- well outlines rushing out of the depths
    ringT = 0,         -- countdown to the next warp ring
    rechargeT = 0,     -- "SUPERZAPPER RECHARGE" banner timer
    respawnT = 0,
    beatT = 0,
}

-- signed shortest distance from lane a to lane b
function G.laneDelta(a, b, lanes, closed)
    local d = b - a
    if closed then
        d = (d + lanes / 2) % lanes - lanes / 2
    end
    return d
end

function G.addScore(n)
    G.score = G.score + n
    if G.score >= G.nextLifeAt and G.lives < C.MAX_LIVES then
        G.lives = G.lives + 1
        G.nextLifeAt = G.nextLifeAt + C.EXTRA_LIFE_AT
        Sfx.fanfare({ 659, 769, 879, 989 })
    end
end

function G.burst(x, y, n)
    Fx.burst(x, y, n)
end
