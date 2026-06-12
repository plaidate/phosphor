-- Lifters: tunables and shared state. The arena does not wrap — the fight
-- stays near the canister cluster, and the only clock that matters is how
-- much fuel is left on the ground.

C = {
    DT = 1 / 30,

    -- the ship (no wrap: gentle bounce keeps it in the arena)
    CRANK_RATIO = 1.0,   -- degrees of ship turn per degree of crank
    DPAD_TURN = 240,     -- degrees per second
    THRUST = 220,        -- px/s^2
    DRAG = 0.985,        -- per frame
    MAX_SPEED = 200,
    SHIP_R = 5,
    EDGE = 10,           -- bounce margin
    BOUNCE = 0.55,       -- velocity kept after an edge bounce
    HOME_X = 200,
    HOME_Y = 186,        -- respawn point, just south of the cluster
    RESPAWN_T = 2.0,
    INVULN_T = 2.2,

    -- bullets
    MAX_SHOTS = 4,
    SHOT_SPEED = 300,
    SHOT_LIFE = 0.8,
    FIRE_COOLDOWN = 0.13,

    -- the fuel canisters
    CANISTERS = 8,
    CAN_R = 5,

    -- raiders: kind -> speed, score, radius
    RAIDERS = {
        lifter = { speed = 55, points = 100, r = 8 },
        gunner = { speed = 50, points = 150, r = 8, fireEvery = 1.7 },
        rammer = { speed = 95, points = 200, r = 7 },
    },
    DRAG_SPEED = 30,         -- carrying a canister is slow work (+2/wave)
    DRAG_SPEED_MAX = 52,
    RAIDER_SHOT_SPEED = 145,
    RAIDER_SHOT_LIFE = 2.4,
    GUNNER_WAVE = 3,         -- gunners appear from this wave
    RAMMER_WAVE = 5,         -- rammers appear from this wave
    MAX_WAVE_RAIDERS = 5,    -- waves grow 3 -> 4 -> 5
    ENTER_STAGGER = 0.6,     -- seconds between raiders flying in
    WAVE_GAP = 1.4,          -- seconds before the next raid flies in
    SPEED_RAMP = 0.05,       -- raider speed bonus per wave, capped
    SPEED_RAMP_MAX = 1.5,
}

-- shared state
G = {
    score = 0,
    wave = 0,
    ship = nil,
    canisters = {},
    raiders = {},
    shots = {},
    raiderShots = {},
    respawnT = 0,
    waveT = 0,
    drift = {}, -- title/over backdrop raiders
}

function G.addScore(n)
    G.score = G.score + n
    Harness.count("scorePts", n)
end

-- plain (non-wrapping) squared distance — this arena has walls
function G.dist2(ax, ay, bx, by)
    local dx, dy = ax - bx, ay - by
    return dx * dx + dy * dy
end

-- canisters still in play (on the ground or being carried)
function G.canistersLeft()
    return #G.canisters
end
