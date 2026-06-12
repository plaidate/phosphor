-- Touchdown tunables.

C = {
    DT = 1 / 30,

    -- flight model
    GRAVITY = 22,               -- px/s^2 downward
    MAX_THRUST = 52,            -- px/s^2 along the ship's up axis at 100%
    CRANK_THROTTLE = 100 / 300, -- % of throttle per degree of crank
    TURN_RATE = 130,            -- deg/s of d-pad tilt
    MAX_TILT = 90,              -- tilt clamp, degrees either side

    -- fuel
    FUEL_MAX = 100,
    BURN_RATE = 7,              -- fuel/s at 100% throttle
    REFUEL_FRAC = 0.25,         -- fraction of tank refunded per safe landing

    -- what counts as a safe landing
    SAFE_VX = 12,
    SAFE_VY = 25,
    SAFE_TILT = 12,

    -- scoring
    BASE_SCORE = 50,
    START_LANDERS = 3,

    -- terrain
    TERRAIN_MIN_Y = 130,
    TERRAIN_MAX_Y = 226,
    PAD_SPECS = {               -- { width px, score multiplier }: narrower pays more
        { 44, 1 }, { 30, 2 }, { 20, 3 }, { 14, 5 },
    },

    -- lander geometry (model space; matches the shape in draw.lua)
    FOOT_X = 7,                 -- half the leg spread
    FOOT_Y = 8,                 -- feet sit this far below center
}
