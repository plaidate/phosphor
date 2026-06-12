-- Tunables. Gameplay numbers carried over from the verified Tempest-style
-- build; new entries cover the Phosphor rework (flip animation, starting
-- level select, warp visuals).

C = {
    DT = 1 / 30,

    -- the claw
    CRANK_DEG_PER_LANE = 22.5, -- one full crank revolution = one full circuit of 16 lanes
    DPAD_LANES_PER_SEC = 9,
    FIRE_COOLDOWN = 0.11,
    MAX_SHOTS = 8,

    -- depth is z in [0,1]: 0 = far end of the well, 1 = the rim
    SHOT_SPEED = 2.4,        -- player shots, z per second (downward)
    WARP_SHOT_SPEED = 3.4,
    ESHOT_BASE_SPEED = 0.5,  -- enemy shots, z per second (upward)

    WARP_DURATION = 2.0,     -- seconds to fly down the well
    FAR_SCALE = 0.14,        -- screen scale of the far end

    FLIP_ANIM = 0.2,         -- seconds a flipper takes to cartwheel one lane

    START_LIVES = 3,
    MAX_LIVES = 6,
    EXTRA_LIFE_AT = 20000,

    -- starting-level select on the title screen (deeper start = bonus points)
    START_LEVELS = { 1, 3, 5, 7 },
    START_BONUS = { 0, 6000, 16000, 30000 },

    -- points
    PTS_FLIPPER = 150,
    PTS_TANKER = 100,
    PTS_SPIKER = 50,
    PTS_FUSEBALL = 250,
    PTS_FUSEBALL_RIM = 500,
    PTS_PULSAR = 200,
    PTS_SPIKE_HIT = 1,
}
