-- Tunables and harness flags.

C = {
    SCREEN_W = 400,
    SCREEN_H = 240,
    DT = 1 / 30,

    -- the ship
    CRANK_RATIO = 1.0,     -- degrees of ship turn per degree of crank
    DPAD_TURN = 240,       -- degrees per second
    THRUST = 230,          -- px/s^2
    DRAG = 0.992,          -- per frame
    MAX_SPEED = 210,
    SHIP_R = 5,            -- collision radius

    -- bullets
    MAX_SHOTS = 4,
    SHOT_SPEED = 290,
    SHOT_LIFE = 0.85,
    FIRE_COOLDOWN = 0.14,

    -- rocks: radius, speed range, score per size class
    ROCKS = {
        large = { r = 20, vmin = 22, vmax = 45, points = 20 },
        medium = { r = 11, vmin = 40, vmax = 75, points = 50 },
        small = { r = 6, vmin = 65, vmax = 110, points = 100 },
    },

    -- saucers
    SAUCER_EVERY = 18,     -- seconds between visits (shrinks with score)
    SAUCER_SPEED = 55,
    SAUCER_SHOT_SPEED = 160,
    PTS_SAUCER_BIG = 200,
    PTS_SAUCER_SMALL = 1000,

    HYPERSPACE_DOOM = 6,   -- 1-in-N chance the jump kills you

    START_LIVES = 3,
    EXTRA_LIFE_AT = 10000,
    START_ROCKS = 4,       -- +2 per wave, capped
    MAX_START_ROCKS = 11,
}

