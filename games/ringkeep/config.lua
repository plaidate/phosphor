-- Ringkeep tunables and harness flags.

C = {
    SCREEN_W = 400,
    SCREEN_H = 240,
    DT = 1 / 30,
    CX = 200, CY = 120, -- the keep sits at screen center

    -- the ship (Rubble feel: crank 1:1, thrust with momentum and drag)
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

    -- the keep: three concentric rotating shield rings around the core
    RING_RADII = { 58, 44, 30 },   -- outer first; shots meet the outer ring first
    RING_SEGS = 12,                -- arc segments per ring
    RING_BAND = 2.5,               -- half-thickness of a shield band
    RING_SPEEDS = { 26, -40, 54 }, -- deg/s; alternating directions, inner fastest
    CORE_R = 8,

    -- the fireball (homing, outrunnable, expires)
    FB_SPEED = 150,
    FB_SPEED_MAX = 200,
    FB_TURN = 150,         -- homing steer rate, deg/s
    FB_LIFE = 4.0,
    FB_R = 7,
    FB_COOLDOWN = 1.5,     -- breath between fireballs

    -- mines: circulate along the outer ring, then peel off and chase
    MINE_COUNT = 2,
    MINE_R = 5,
    MINE_ORBIT = 65,       -- deg/s along the ring
    MINE_CHASE = 78,       -- px/s when chasing
    MINE_CHASE_MAX = 130,
    MINE_PEEL_MIN = 3.0,   -- seconds riding the ring before peeling off
    MINE_PEEL_VAR = 4.0,
    MINE_RESPAWN = 3.0,

    -- pacing: everything speeds up each time the core falls
    WAVE_SPEEDUP = 1.18,
    MAX_SPEED_MUL = 2.4,

    PTS_SEGMENT = 10,
    PTS_MINE = 100,
    PTS_CORE = 1500,

    START_LIVES = 3,
    MAX_LIVES = 8,
    RESPAWN_R_MIN = 100,   -- respawn this far from the keep
    RESPAWN_R_MAX = 125,
}
