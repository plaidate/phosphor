-- Open Geometry Wars (Phosphor port): tunables. Everything in screen pixels;
-- speeds are per-second and scaled by Attract.dt in the sim.

C = {
    DT = 1 / 30,

    GRID_SPACING = 32,

    -- the ship
    START_LIVES = 3,
    START_BOMBS = 3,
    SHIP_R = 6,             -- collision radius
    MOVE_ACCEL = 900,       -- px/s^2 from the d-pad
    MOVE_MAX = 150,         -- px/s top speed
    MOVE_DRAG = 0.90,       -- per frame when no input
    SPAWN_INVULN = 2.2,     -- seconds of shield after (re)spawn
    RESPAWN_DELAY = 1.2,

    -- autofire
    FIRE_COOLDOWN = 0.10,   -- seconds between volleys
    SHOT_SPEED = 360,       -- px/s
    SHOT_LIFE = 1.1,        -- seconds
    SHOT_SPREAD = 5,        -- degrees between the twin barrels
    MAX_SHOTS = 28,

    -- bombs
    BOMB_RADIUS = 320,      -- final clear radius
    BOMB_GROW = 700,        -- px/s the shock ring expands
    BOMB_COOLDOWN = 0.6,

    -- enemies (radius, speed px/s, points). Behaviour lives in enemies.lua.
    MAX_ENEMIES = 40,
    MIN_SPAWN_DIST = 90,    -- keep spawns away from the player
    SPAWN_WARN = 0.6,       -- telegraph time before an enemy goes live

    GRUNT  = { r = 8,  speed = 70,  points = 50 },
    WANDER = { r = 8,  speed = 55,  points = 25 },
    SPINNER= { r = 8,  speed = 95,  points = 100 },
    TINY   = { r = 6,  speed = 80,  points = 50 },
    WEAVER = { r = 7,  speed = 115, points = 100 },
    HOLE   = { r = 11, speed = 26,  points = 75, hp = 12 },
    PROTON = { r = 4,  speed = 150, points = 50 },

    -- geoms (multiplier pickups dropped by kills)
    GEOM_R = 3,
    GEOM_MAGNET = 60,       -- px: pulled to the ship inside this
    GEOM_PICKUP = 11,
    GEOM_DRAG = 0.92,
    MAX_MULT = 20,

    -- difficulty: spawnIndex climbs with time, gating types and target count
    SPAWN_RAMP = 1 / 60,    -- index units per second (max meaningful ~40)
    EXTRA_LIFE_AT = 75000,
}
