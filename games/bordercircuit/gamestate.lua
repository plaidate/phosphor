-- Border Circuit: shared state. The arena never wraps — everything lives
-- in the gutter between the outer walls and the central HUD barrier.

G = {
    score = 0,
    lives = C.START_LIVES,
    nextLifeAt = C.EXTRA_LIFE_AT,
    wave = 0,
    ship = nil,
    shots = {},      -- player bullets (they bounce)
    eshots = {},     -- drone bullets (they bounce too)
    drones = {},
    layers = {},
    mines = {},      -- persist across waves
    respawnT = 0,
    waveT = 0,
    droneKills = 0,  -- this wave; drives the 200/250 escalation
}

function G.addScore(n)
    G.score = G.score + n
    Harness.count("scorePts", n)
    if G.score >= G.nextLifeAt and G.lives < 8 then
        G.lives = G.lives + 1
        G.nextLifeAt = G.nextLifeAt + C.EXTRA_LIFE_AT
        Sfx.fanfare()
    end
end
