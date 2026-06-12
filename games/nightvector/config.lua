-- Night Vector tunables. Distances in metres, speeds in m/s (HUD shows kph).

C = {
    DT = 1 / 30,

    -- the road
    SEG = 10,             -- metres per centerline segment
    DRAW_SEGS = 30,       -- segments rendered ahead: the headlight throw
    HALF_W = 4,           -- road half-width
    LANE = 2,             -- lane centre offset from the centerline
    POST_H = 0.8,         -- roadside edge posts
    CURV_MAX = 3.0,       -- deg of heading change per segment at the limit
    CURV_SLEW = 0.22,     -- deg/segment of curvature change (keeps it smooth)
    CURV_HOLD = { 8, 26 },-- segments a curvature target holds
    HILL_MAX = 0.5,       -- m of rise per segment at the limit (5% grade)
    HILL_SLEW = 0.04,
    HILL_HOLD = { 12, 34 },
    OBSTACLE_P = 0.16,    -- chance a segment grows a roadside tree/sign

    -- the car
    MAX_SPEED = 50,       -- m/s = 180 kph
    ACCEL = 10,           -- m/s^2 at full throttle
    BRAKE = 22,
    DRAG = 0.2,           -- linear, /s: terminal velocity = ACCEL/DRAG
    CRANK_RATIO = 1.0,    -- wheel degrees per crank degree
    DPAD_WHEEL = 170,     -- wheel deg/s on the d-pad fallback
    WHEEL_MAX = 110,      -- the wheel's lock stop, degrees
    STEER_GAIN = 0.022,   -- yaw deg/s per (wheel deg x m/s)
    EYE = 1.1,            -- camera height above the tarmac

    OFFROAD_DRAG = 1.7,   -- /s, violent scrubbing in the dirt
    CAR_R = 1.5,          -- lateral collision half-width vs traffic
    HIT_LEN = 3.2,        -- longitudinal collision half-length vs traffic
    OBS_R = 1.4,          -- obstacle collision radius
    CRASH_TIME = 3,
    START_CARS = 3,

    -- traffic
    TRAFFIC_MAX = 6,
    SPAWN_EVERY = 2.4,    -- seconds between spawn attempts
    SPAWN_AHEAD = 340,
    DESPAWN_BEHIND = 70,
    DESPAWN_AHEAD = 480,
    SAME_V = { 13, 23 },     -- same-direction traffic, m/s
    ONCOMING_V = { 15, 26 },

    -- the clock. 1 km flat-out at 180 kph takes 20 s and a standing start
    -- costs ~6 more, so leg one gets headroom and the bonus carries an
    -- early-level grace that decays to a hard +18 by level 8.
    CK_M = 1000,          -- checkpoint spacing
    TIME_START = SMOKE_BUILD and 60 or 32, -- the smoke bot drives timidly; humans get the real clock
    TIME_BONUS = 18,      -- per checkpoint, the late-game floor
    TIME_GRACE = 8,       -- extra seconds at level 1, minus one per level

    PTS_100M = 10,
    PTS_OVERTAKE = 200,
}
