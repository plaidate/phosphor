-- Tunables. World units are meters; the camera rides the turret at 1.2m.

C = {
    DT = 1 / 30,

    -- player tank
    CAM_Y = 1.2,
    DRIVE_SPEED = 7,      -- m/s, both treads forward
    REVERSE_SPEED = 4.5,
    PIVOT_RATE = 70,      -- deg/s turning in place
    ARC_RATE = 30,        -- deg/s while driving (gentle arc)
    CRANK_RATIO = 1.0,    -- crank degrees -> turret degrees
    PLAYER_R = 1.5,

    -- shells (one live per side)
    SHELL_SPEED = 42,
    SHELL_LIFE = 2.0,
    ESHELL_SPEED = 26,
    ESHELL_LIFE = 2.6,

    -- obstacles
    OBSTACLES = 14,
    OB_FAR = 95,          -- recycle past this range

    -- enemies
    ENEMY_SPAWN_MIN = 42,
    ENEMY_SPAWN_MAX = 60,
    TANK_SPEED = 5,
    TANK_TURN = 55,       -- deg/s
    STALK_DIST = 25,      -- closes to this, then circles
    TANK_FIRE_CD = 2.6,
    AIM_BASE_ERR = 14,    -- degrees of lead error...
    AIM_ERR_STEP = 2.2,   -- ...shrinking per kill...
    AIM_MIN_ERR = 1.5,    -- ...down to this floor
    SKIMMER_SPEED = 13,
    SKIMMER_R = 1.6,

    START_LIVES = 3,
    MAX_LIVES = 6,
    EXTRA_LIFE_AT = 15000,
    PTS_TANK = 1000,
    PTS_SKIMMER = 2500,

    RADAR_RANGE = 70,     -- meters across the scope radius
}
