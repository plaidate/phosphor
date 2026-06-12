-- Rubble: shared state. Explosion effects route to the library's Fx pool.

G = {
    score = 0,
    lives = C.START_LIVES,
    nextLifeAt = C.EXTRA_LIFE_AT,
    wave = 0,
    ship = nil,
    rocks = {},
    shots = {},
    saucer = nil,
    saucerShots = {},
    saucerT = C.SAUCER_EVERY,
    respawnT = 0,
    waveT = 0,
    beatT = 0,
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

function G.burst(x, y, n)
    Fx.burst(x, y, n)
end

function G.addDebris(x, y, n)
    Fx.debris(x, y, n)
end
