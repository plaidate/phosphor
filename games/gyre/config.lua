-- Tunables. The playfield is polar: the player rides a circle of radius RIM
-- around the screen center, enemies live at (angle, r) with r=1 at the rim.
-- Depth is faked by scaling everything toward MIN_SCALE at the center.

C = {
    DT = 1 / 30,

    CX = 200,
    CY = 120,
    RIM = 104,        -- px radius of the player's orbit
    MIN_SCALE = 0.22, -- draw scale at the center of the tube

    -- the ship
    CRANK_RATIO = 1.0, -- ship degrees per crank degree (one rev = one orbit)
    DPAD_DEG_PER_SEC = 250,
    FIRE_COOLDOWN = 0.15,
    MAX_VOLLEYS = 3,   -- player shots in flight (volleys; twin counts as one)
    SHOT_SPEED = 1.9,  -- player shots, r per second (inward)
    TWIN_SPREAD = 3.5, -- degrees between twin-cannon barrels

    -- enemies
    ENTRY_SPEED = 0.52,  -- path units (rim radii) per second
    ATTACK_SPEED = 0.66,
    SPEED_STAGE = 0.02,  -- speed added per stage
    ATTACK_INTERVAL = 3.4,
    ATTACK_MIN = 1.4,
    ATTACK_STAGE = 0.16, -- interval shed per stage
    RUNS_BEFORE_LEAVE = 3,
    STALL_TIMEOUT = 26,  -- s of full formation idling before they fly off
    EBULLET_SPEED = 0.4, -- enemy bullets, units/sec
    EBULLET_STAGE = 0.016,
    DIVE_AMMO = 2,       -- bullets per attack run

    -- the hub formation (rings of slots near the center)
    FORM_SPIN = 13, -- deg/sec
    SETTLE_TIME = 0.35,

    -- waves
    SQUAD_SIZE = 4,
    SQUAD_STAGGER = 0.28, -- s between ships of a chain
    SQUAD_GAP = 1.7,      -- s between squads

    -- events
    METEOR_FROM_STAGE = 2,
    METEOR_INTERVAL = 7.5,
    METEOR_SPEED = 0.3,
    SAT_HOLD = 9,     -- s the satellite trio lingers
    SAT_R = 0.82,
    LASER_FROM_STAGE = 4,
    LASER_TIME = 8,   -- s the beam pair sweeps
    LASER_WARMUP = 0.9,
    LASER_SWEEP = 26, -- deg/sec, + 2 per stage

    -- chance stages
    CHANCE_SQUADS = 4,
    CHANCE_SIZE = 8,

    START_LIVES = 3,
    MAX_LIVES = 6,
    EXTRA_LIFE_EVERY = 60000,
    RESPAWN_TIME = 1.5,
    INVULN_TIME = 2.2,

    WARPS_PER_PLANET = 3,
    PLANETS = { "NEPTUNE", "URANUS", "SATURN", "JUPITER", "MARS", "EARTH" },

    -- points
    PTS_DRONE = 50,   -- in formation / entering
    PTS_DIVER = 100,  -- mid attack run
    PTS_SAT = { 500, 1000, 1500 },
    PTS_LASER = 300,
    PTS_CHANCE = 100,
    PTS_CHANCE_SQUAD = 1500,
    PTS_CHANCE_ALL = 5000,

    -- hit radii in px at scale 1
    HIT_DRONE = 9,
    HIT_SAT = 10,
    HIT_LASER = 9,
    HIT_METEOR = 11,
    HIT_PLAYER = 8,
    HIT_BULLET = 8,
}
