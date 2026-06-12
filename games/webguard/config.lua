-- Webguard tunables and shared game state.

C = {
    DT = 1 / 30,

    -- the web
    CX = 200, CY = 120,
    SPOKES = 8,
    RINGS = { 27, 54, 81, 108 },
    R_OUT = 108,

    -- the spider
    PLAYER_SPEED = 95,     -- px/s, free 8-way movement
    PLAYER_R = 5,
    EDGE_MARGIN = 6,       -- keep this far inside the outer ring
    CRANK_RATIO = 1.0,     -- degrees of aim per degree of crank
    AIM_LEN = 15,          -- aim indicator line length

    -- shots
    FIRE_COOLDOWN = 1 / 7, -- autofire ~7/s while A or B held
    SHOT_SPEED = 250,
    MAX_SHOTS = 8,

    -- chasers: head straight for the spider
    CHASER_SPEED = 34,
    CHASER_R = 6,
    PTS_CHASER = 150,

    -- layers: wander the web, depositing eggs at intersections
    LAYER_SPEED = 42,
    LAYER_R = 6,
    PTS_LAYER = 200,
    LAY_COOLDOWN = 2.4,
    MAX_EGGS = 10,

    -- eggs: pulse, then hatch into chasers
    EGG_R = 4,
    EGG_HATCH = 6.0,
    PTS_EGG = 50,

    -- bombers: drift across, burst into 4 radial fragments
    BOMBER_SPEED = 52,
    BOMBER_R = 7,
    BOMBER_FUSE = 3.6,
    PTS_BOMBER = 300,
    FRAG_SPEED = 115,
    FRAG_R = 2,

    SPAWN_GAP = 1.15,      -- seconds between rim arrivals (shrinks per wave)

    START_LIVES = 3,
    EXTRA_LIFE_AT = 20000,
    INVULN = 2.2,
}

G = {
    score = 0,
    lives = C.START_LIVES,
    nextLifeAt = C.EXTRA_LIFE_AT,
    wave = 0,
    speedScale = 1,
    player = nil,
    shots = {},
    chasers = {},
    layers = {},
    bombers = {},
    eggs = {},
    frags = {},
    spawnQ = {},
    spawnT = 0,
    respawnT = 0,
    waveT = 0,
    bannerT = 0,
}

-- plain (non-wrapping) squared distance; the web does not wrap
function G.dist2(ax, ay, bx, by)
    local dx, dy = ax - bx, ay - by
    return dx * dx + dy * dy
end

function G.addScore(n)
    G.score = G.score + n
    Harness.count("scorePts", n)
    if G.score >= G.nextLifeAt and G.lives < 8 then
        G.lives = G.lives + 1
        G.nextLifeAt = G.nextLifeAt + C.EXTRA_LIFE_AT
        Sfx.fanfare()
    end
end
