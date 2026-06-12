-- Gravity Wells tunables.

C = {
    DT = 1 / 30,

    -- the ship (shared by both scales)
    CRANK_RATIO = 1.0,   -- degrees of ship turn per degree of crank
    DPAD_TURN = 220,     -- degrees per second
    THRUST = 110,        -- px/s^2
    SHIP_R = 5,          -- collision radius
    FUEL_MAX = 100,
    FUEL_BURN = 7,       -- fuel per second of thrust

    -- bullets
    MAX_SHOTS = 4,
    SHOT_SPEED = 260,
    SHOT_LIFE = 0.9,
    FIRE_COOLDOWN = 0.16,

    -- system view: the star and its planets
    STAR_X = 200, STAR_Y = 120,
    STAR_R = 11,
    STAR_G = 26,          -- px/s^2 toward the star, always on
    STAR_G_PER_SYS = 7,   -- extra pull per system beyond the first
    EDGE_MARGIN = 16,     -- soft boundary: a gentle pull keeps you in bounds
    EDGE_PULL = 130,
    SYS_MAX_SPEED = 150,

    -- planet missions
    WORLD_W = 800,        -- ~2 screens wide
    PLANET_G = 30,        -- px/s^2 downward (reversed on the odd planet)
    PLANET_G_PER_SYS = 8,
    MIS_MAX_SPEED = 180,
    BEAM_LEN = 46,        -- tractor beam reach below the ship
    BEAM_HALF_W = 9,
    TANK_FUEL = 30,
    BUNKERS = 4,
    TANKS = 3,
    BUNKER_RANGE = 250,
    BUNKER_CD_MIN = 1.6,
    BUNKER_CD_MAX = 2.9,
    BUNKER_SHOT_SPEED = 95,
    MAX_ESHOTS = 8,
    REACTOR_TIME = 8,     -- seconds to escape once the reactor is hit

    -- scoring
    PTS_BUNKER = 250,
    PTS_TANK = 50,
    PTS_REACTOR_HIT = 500,
    PTS_CLEAR = 1000,
    PTS_REACTOR_ESCAPE = 2500,
    PTS_REACTOR_ESCAPE_PER_SYS = 500,

    START_SHIPS = 3,
    EXTRA_LIFE_AT = 10000,
}
