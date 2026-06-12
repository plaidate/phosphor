-- Border Circuit: tunables. An arena-race shooter — the track is the
-- gutter between the outer walls and the central HUD barrier.

C = {
    DT = 1 / 30,

    -- the ship: frictionless coasting, crank steering
    CRANK_RATIO = 1.0,   -- degrees of ship turn per degree of crank
    DPAD_TURN = 240,     -- degrees per second (d-pad fallback)
    THRUST = 220,        -- px/s^2
    MAX_SPEED = 250,
    SHIP_R = 5,
    SHIP_BOUNCE = 0.78,  -- wall elasticity for the ship (slightly lossy)

    -- bullets (they bounce too, at full elasticity)
    MAX_SHOTS = 4,
    SHOT_SPEED = 300,
    SHOT_LIFE = 1.3,
    FIRE_COOLDOWN = 0.15,

    -- geometry: outer walls and the central barrier that holds the HUD
    ARENA = { x1 = 4, y1 = 4, x2 = 396, y2 = 236 },
    BAR = { x1 = 110, y1 = 80, x2 = 290, y2 = 160 },   -- 180 x 80, centered

    -- drones: diamond ships that circulate and accelerate over time
    DRONE_R = 7,
    DRONE_V0 = 50,       -- + per-wave bonus
    DRONE_WAVE_V = 8,
    DRONE_VMAX = 150,
    DRONE_ACCEL = 4,     -- px/s gained per second alive
    DRONE_TURN = 220,    -- deg/s steering (scales up with speed)
    ESHOT_SPEED = 150,
    ESHOT_LIFE = 2.0,

    -- mine layers: slow, drop photon mines as they go around
    LAYER_R = 8,
    LAYER_V = 36,
    LAYERS_PER_WAVE = 2,
    MINE_EVERY = 1.7,    -- seconds between drops
    MINE_R = 5,
    MINE_ARM = 1.0,      -- seconds before a dropped mine goes live
    MAX_MINES = 10,

    -- scoring
    PTS_DRONE_BASE = 200,   -- first drone of a wave; later kills step up
    PTS_DRONE_STEP = 50,
    PTS_DRONE_CAP = 250,
    PTS_LAYER = 200,        -- a layer that already finished its circuit
    PTS_LAYER_BONUS = 500,  -- shot before it finishes its circuit
    PTS_MINE = 350,

    START_LIVES = 3,
    EXTRA_LIFE_AT = 40000,
}
