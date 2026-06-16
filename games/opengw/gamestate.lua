-- Open Geometry Wars: shared live state and scoring.

G = {
    score = 0,
    lives = C.START_LIVES,
    bombs = C.START_BOMBS,
    nextLifeAt = C.EXTRA_LIFE_AT,
    mult = 1,
    geomsForNext = 0,       -- geoms collected toward the next multiplier step

    ship = nil,
    shots = {},
    enemies = {},
    geoms = {},

    spawnIndex = 0,
    spawnT = 0,
    respawnT = 0,
    bombT = 0,
    shieldShake = 0,        -- decays; nudges the grid around the shield
}

function G.addScore(n)
    G.score = G.score + n * G.mult
    Harness.count("scorePts", n * G.mult)
    if G.score >= G.nextLifeAt then
        G.lives = G.lives + 1
        G.nextLifeAt = G.nextLifeAt + C.EXTRA_LIFE_AT
        Sfx.fanfare()
    end
end

-- multiplier climbs one step per few geoms, faster than GW but readable here
function G.collectGeom()
    G.geomsForNext = G.geomsForNext + 1
    if G.geomsForNext >= 4 and G.mult < C.MAX_MULT then
        G.geomsForNext = 0
        G.mult = G.mult + 1
        Sfx.blip(440 + G.mult * 40)
    else
        Sfx.pew(1400)
    end
    Harness.count("geoms")
end

function G.loseMultiplier()
    G.mult = 1
    G.geomsForNext = 0
end
