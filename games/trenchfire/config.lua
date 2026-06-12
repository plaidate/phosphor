-- Trenchfire tunables. Each level cycles three phases: APPROACH (fighter
-- waves swooping in from the distance), TOWERS (gun towers on the ground
-- grid), TRENCH (the canyon run ending at the fortress port). Distances are
-- world units; the crank throttle scales ship speed between SPEED_MIN/MAX
-- and drives the score multiplier.

C = {
    DT = 1 / 30,

    -- crosshair + lasers
    CROSS_SPEED = 175,     -- px/s under the d-pad
    CROSS_MARGIN = 18,     -- crosshair screen clamp
    FIRE_COOLDOWN = 0.24,  -- ~4 shots/s
    LASER_LIFE = 0.09,     -- seconds a corner beam stays on screen
    AIM_ASSIST = 13,       -- px of slack added to every projected target

    -- the ship is the camera: it eases toward the crosshair laterally
    EASE = 5.5,            -- per-second exponential chase rate
    LAT_RANGE = 70,        -- world half-range of lateral drift (open phases)
    VERT_LO = 8, VERT_HI = 48,
    SPEED_MIN = 70, SPEED_MAX = 175,
    LEVEL_SPEED = 0.07,    -- +7% ship speed per level
    MULT_MAX = 3,          -- full throttle = 3x score

    -- shields are the lives
    START_SHIELDS = 6, MAX_SHIELDS = 9,
    HIT_R = 13,            -- fireball-vs-ship box half-size, world units
    INVULN = 0.9,          -- grace after any shield loss
    SCRAPE_COOLDOWN = 0.7, -- extra grace between trench-wall scrapes

    -- approach phase
    FIGHTER_QUOTA = 5,     -- +2 per level
    FIGHTER_ACTIVE = 2,    -- +1 per 2 levels, capped at 4
    FIGHTER_SPAWN_Z = 520,

    -- towers phase
    TOWERS_LEN = 1400,
    TOWER_EVERY = 150,     -- mean spacing, shrinks with level
    TOWER_H = 30,

    -- trench phase
    TRENCH_LEN = 1700,     -- +150 per level
    TRENCH_W = 46,         -- half-width
    TRENCH_H = 54,
    RIB_EVERY = 60,        -- wall rectangle spacing
    BRACE_EVERY = 240,     -- overhead cross-braces
    HARDPOINT_EVERY = 190, -- shrinks with level
    PORT_Y = 18,           -- port window center height on the end wall
    PORT_W = 8, PORT_H = 6, -- port half-sizes (it is small; timing matters)
    PORT_RANGE = 330,      -- max distance a shot can reach the port

    -- fireballs
    FB_SPEED = 70,         -- own speed; ship speed adds to the closing rate
    FB_MAX = 7,            -- live cap, +1 per 2 levels
    FB_R = 3,

    -- points (all scaled by the throttle multiplier)
    PTS_FIGHTER = 200,
    PTS_TOWER = 250,
    PTS_HARDPOINT = 150,
    PTS_FIREBALL = 50,
    PTS_FORTRESS = 5000,
}
