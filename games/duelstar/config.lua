-- Duelstar tunables.

C = {
    DT = 1 / 30,

    -- ships
    CRANK_RATIO = 1.0,    -- degrees of ship turn per degree of crank
    DPAD_TURN = 220,      -- degrees per second (d-pad fallback / autopilot)
    THRUST = 160,         -- px/s^2
    DRAG = 0.998,         -- per frame
    MAX_SPEED = 240,
    SHIP_R = 6,           -- collision radius
    HITS = 3,             -- hits per round before a ship dies
    LAME_TURN = 0.6,      -- turn factor with one hit left
    LAME_THRUST = 0.7,    -- thrust factor with one hit left
    SPAWN_INVULN = 1.6,
    HIT_INVULN = 0.9,
    SPAWN_DIST = 95,      -- starting distance from the sun

    -- shots (gravity bends these too)
    MAX_SHOTS = 3,
    SHOT_SPEED = 175,
    SHOT_LIFE = 1.9,
    FIRE_COOLDOWN = 0.3,
    SHOT_R = 2,
    TRAIL_LEN = 6,        -- fading trail positions kept per shot

    -- the sun
    SUN_X = 200, SUN_Y = 120,
    SUN_R = 9,            -- drawn radius
    SUN_KILL_R = 13,      -- death radius for ships
    GRAV_MU = 230000,     -- accel = MU / dist^2, toward the sun
    GRAV_MAX = 420,       -- accel cap near the core

    HYPERSPACE_DOOM = 6,  -- 1-in-N chance the jump kills you
    HYPER_MIN_SUN = 70,   -- never rematerialize closer to the sun than this

    -- match structure
    WINS_TO_MATCH = 5,
    ROUND_PAUSE = 2.6,    -- seconds between rounds
    INTRO_TIME = 1.4,     -- "ROUND N" banner time

    -- scoring
    PTS_HIT = 500,
    PTS_ROUND = 2000,
    PTS_MATCH = 10000,

    -- rival AI
    AI_TURN = 200,            -- degrees per second at full skill
    AI_BASE_SKILL = 0.45,
    AI_SKILL_PER_WIN = 0.14,  -- skill gained per player round-win
    ORBIT_R = 80,             -- the orbiter's preferred sun distance
}
