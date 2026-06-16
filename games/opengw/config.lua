-- Open Geometry Wars (Phosphor port): tunables. Everything in screen pixels;
-- speeds are per-second and scaled by Attract.dt in the sim. Numbers track
-- capehill/opengw, rescaled from its 133x89 arena to the 400x240 field.

C = {
    DT = 1 / 30,

    GRID_SPACING = 32,

    -- the ship
    START_LIVES = 5,
    START_BOMBS = 5,
    SHIP_R = 6,             -- collision radius
    MOVE_ACCEL = 900,       -- px/s^2 from the d-pad
    MOVE_MAX = 150,         -- px/s top speed
    MOVE_DRAG = 0.90,       -- per frame when no input
    SPAWN_INVULN = 2.2,     -- seconds of shield after (re)spawn (~250 frames)
    RESPAWN_DELAY = 1.2,

    -- weapons: three patterns, auto-switched every 10k points earned.
    -- cd = seconds between volleys, speed = px/s. Pattern shape is in player.lua.
    WEAPONS = {
        [0] = { cd = 0.10, speed = 300 }, -- twin spread
        [1] = { cd = 0.05, speed = 440 }, -- alternating dual / single
        [2] = { cd = 0.12, speed = 360 }, -- five-way fan
    },
    SHOT_LIFE = 1.1,        -- seconds
    MAX_SHOTS = 40,
    HOLE_HOMING_DIST = 75,  -- shots bend toward a black hole inside this
    HOLE_HOMING_RATE = 0.18,

    -- bombs
    BOMB_RADIUS = 320,      -- final clear radius
    BOMB_GROW = 700,        -- px/s the shock ring expands
    BOMB_COOLDOWN = 0.6,

    -- scoring / progression (kill-count multiplier, as in opengw)
    MULT_PER_KILLS = 25,    -- +1 multiplier each this many kills in a life
    MAX_MULT = 6,
    EXTRA_LIFE_AT = 75000,
    EXTRA_BOMB_AT = 100000,
    WEAPON_SWITCH_AT = 10000,

    -- enemies (radius, speed px/s, points). Behaviour lives in enemies.lua.
    MAX_ENEMIES = 48,
    MIN_SPAWN_DIST = 90,    -- keep spawns away from the player
    SPAWN_WARN = 0.6,       -- telegraph time before an enemy goes live

    GRUNT  = { r = 8,  speed = 70,  points = 50 },
    WANDER = { r = 8,  speed = 55,  points = 25 },
    SPINNER= { r = 8,  speed = 95,  points = 100 },
    TINY   = { r = 6,  speed = 80,  points = 50 },
    WEAVER = { r = 7,  speed = 115, points = 100 },
    HOLE   = { r = 11, speed = 26,  points = 50, hp = 12 },
    PROTON = { r = 4,  speed = 150, points = 50 },
    MAYFLY = { r = 7,  speed = 90,  points = 50 },
    SNAKE  = { r = 8,  speed = 78,  points = 50, segs = 14, seglag = 3 },
    REPULSOR = { r = 11, speed = 70, points = 100, deflect = 46, hp = 6 },

    -- difficulty: spawnIndex climbs with time, gating types and target count;
    -- aggression scales enemy speeds slowly upward, as in opengw.
    SPAWN_RAMP = 1 / 60,    -- index units per second (max meaningful ~40)
    AGGRO_RAMP = 0.012,     -- per second added to the 1.0 base
    AGGRO_MAX = 2.0,
}
