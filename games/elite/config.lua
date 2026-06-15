-- Elite tunables. Distances and the flight model are in "world units"; one
-- unit is one Elite ship-blueprint coordinate (a Sidewinder is ~70 across), so
-- the extracted ship meshes drop straight in at scale 1.

C = {
    SCREEN_W = 400,
    SCREEN_H = 240,
    DT = 1 / 30,

    -- the 3D space view fills the top; the dashboard sits below it
    VIEW_H = 162,        -- space view is rows 0..162
    VIEW_CY = 82,        -- projection centre (kept above the dashboard)
    FOCAL = 207,

    -- flight: the player sits at the origin and the universe moves around them
    ROLL_RATE = 2.4,     -- radians/sec at full d-pad/crank deflection
    PITCH_RATE = 1.7,    -- radians/sec
    CRANK_ROLL = 1 / 110, -- radians of roll per degree of crank
    SPEED_MAX = 1500,
    SPEED_CRUISE = 480,  -- speed a fresh launch settles at
    SPEED_STEP = 90,     -- throttle change per second while held
    SPEED_DOCK = 200,    -- must be at or below this to dock (else you crash)

    -- weapons
    LASER_RANGE = 6500,
    LASER_HIT_PX = 18,   -- screen-space reticle radius a target must fall within
    LASER_DPS = 64,      -- laser damage per second of continuous fire on target
    LASER_HEAT_RATE = 38, -- temperature gained per second of fire
    LASER_COOL_RATE = 26, -- temperature lost per second when not firing
    LASER_MAX_HEAT = 100,

    -- player condition
    ENERGY_MAX = 100,
    ENERGY_REGEN = 7,    -- per second
    SHIELD_MAX = 100,
    SHIELD_REGEN = 5,    -- per second, drawn from energy
    HULL_HITS = 3,       -- collisions the hull survives once shields are down

    -- enemy fire
    ENEMY_RANGE = 5000,
    ENEMY_FIRE_DOT = 0.96, -- how aligned a pirate must be to shoot (cos angle)
    ENEMY_DPS = 18,      -- damage per second of pirate fire that lands

    -- the universe
    SPAWN_Z = 3200,      -- nominal distance new contacts appear at
    SPAWN_SPREAD = 1400,
    SCANNER_RANGE = 9000, -- contacts beyond this drop off the scanner
    FUEL_MAX = 70,        -- 7.0 light years (Elite's standard tank)
    STATION_DIST = 6000, -- where the station sits when a system loads
    DOCK_RANGE = 700,    -- distance at which docking is evaluated

    -- pacing
    START_SHIPS = 3,     -- pirates in the first system
    EXTRA_LIFE_AT = 0,   -- (unused: condition is energy, not lives)
}

-- bounty / score per ship kind
C.BOUNTY = {
    sidewinder = 50,
    mamba = 100,
    viper = 60,
    cobra = 75,
    python = 200,
    thargoid = 500,
    asteroid = 5,
    canister = 10,
}

C.DOCK_BONUS = 150
