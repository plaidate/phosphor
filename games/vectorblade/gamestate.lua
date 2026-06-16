-- Vectorblade shared state. G holds the live game; mode drives the in-play
-- state machine that Attract's single "play" state delegates to.
--
-- mode: "intro"  enemies fly in to the formation grid
--       "battle" formation breathes, enemies dive and fire
--       "cleared" brief wave-clear tally
--       "shop"   spend cash between waves

G = {
    score = 0,
    cash = 0,
    lives = C.START_LIVES,
    nextLifeAt = C.EXTRA_LIFE_AT,
    level = 1,
    mode = "intro",

    ship = nil,
    shots = {},       -- player bullets
    enemies = {},     -- formation + divers
    eshots = {},      -- enemy bullets
    bonuses = {},     -- falling pickups
    boss = nil,

    -- weapon / upgrade state
    spread = C.START_SPREAD,
    rateLvl = 0,
    speedLvl = 0,
    autofire = false,
    armor = 0,
    bombs = 0,
    shieldT = 0,
    multT = 0,

    -- timers
    swayT = 0,
    attackT = 0,
    clearT = 0,
    respawnT = 0,
}

function G.addScore(n)
    n = n * (G.multT > 0 and 2 or 1)
    G.score = G.score + n
    Harness.count("scorePts", n)
    if G.score >= G.nextLifeAt and G.lives < C.MAX_LIVES then
        G.lives = G.lives + 1
        G.nextLifeAt = G.nextLifeAt + C.EXTRA_LIFE_AT
        Sfx.fanfare()
    end
end

function G.addCash(n)
    G.cash = G.cash + n
    Harness.count("cash", n)
end

function G.addLife()
    if G.lives < C.MAX_LIVES then G.lives = G.lives + 1 end
    Sfx.fanfare()
end

-- concurrent divers allowed, climbs gently with level (Galaga sends one or
-- two early, then swarms)
function G.maxDivers()
    return math.min(2 + math.floor(G.level / 2), C.MAX_DIVERS + 4)
end
