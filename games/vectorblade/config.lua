-- Vectorblade tunables and harness flags. Everything tweakable lives here.
-- A Galaga / Warblade-style fixed shooter: the fighter holds the bottom of
-- the field, the crank is its spinner, and waves fly in, form up, and dive.

C = {
    SCREEN_W = 400,
    SCREEN_H = 240,
    DT = 1 / 30,

    -- the fighter
    SHIP_Y = 220,          -- fixed vertical line the ship rides
    SHIP_HALF = 9,         -- half-width (collision + clamp margin)
    CRANK_RATIO = 0.95,    -- px of travel per degree of crank
    DPAD_SPEED = 240,      -- px/s for the d-pad fallback
    MOVE_BONUS = 70,       -- extra px/s per SPEED upgrade (crank + dpad)

    -- weapon
    SHOT_SPEED = 420,      -- px/s upward
    SHOT_SPEED_BONUS = 110,-- per RATE upgrade
    FIRE_COOLDOWN = 0.22,  -- s between volleys
    FIRE_COOLDOWN_MIN = 0.07,
    SPREAD_GAP = 6,        -- px between barrels of a multi-shot volley
    SPREAD_FAN = 60,       -- px/s sideways spread for >2 barrels
    MAX_SPREAD = 6,        -- max simultaneous barrels
    SHOT_LEN = 7,

    -- enemy formation grid
    FORM_COLS = 8,
    FORM_ROWS = 5,
    FORM_X0 = 46,
    FORM_DX = 44,
    FORM_Y0 = 30,
    FORM_DY = 17,
    SWAY_AMP = 26,         -- px the whole formation breathes sideways
    SWAY_SPEED = 0.7,      -- rad/s

    -- enemies
    ENEMY_R = 9,           -- collision radius
    FLYIN_TIME = 1.3,      -- s for an enemy to reach its slot
    DIVE_VY = 120,         -- px/s downward when diving
    DIVE_HOMING = 65,      -- px/s sideways pull toward the player
    DIVE_WIGGLE = 70,      -- px sideways sine amplitude
    ENEMY_SHOT_SPEED = 150,
    ATTACK_BASE = 1.6,     -- s between dive launches (level 1)
    ATTACK_MIN = 0.45,     -- floor as levels climb
    MAX_DIVERS = 4,        -- concurrent divers cap (grows with level)

    -- bosses (every BOSS_EVERY levels)
    BOSS_EVERY = 5,
    BOSS_HP = 40,          -- +20 per boss appearance
    BOSS_SPEED = 50,
    BOSS_FIRE = 1.1,       -- s between boss volleys

    -- bonus drops
    BONUS_VY = 55,         -- px/s the pickup falls
    BONUS_CHANCE = 0.16,   -- per-kill chance of a drop
    BONUS_R = 12,
    SHIELD_TIME = 7,
    MULT_TIME = 8,
    CASH_PER_MONEY = 50,

    -- scoring
    PTS = { drone = 100, wedge = 150, tie = 250, bird = 400 },
    PTS_BOSS = 25000,

    -- economy / lives
    START_LIVES = 3,
    MAX_LIVES = 9,
    EXTRA_LIFE_AT = 20000,
    START_SPREAD = 1,
    START_CASH = 0,

    -- shop
    SHOP_DWELL = 12,       -- s the shop stays open before auto-advancing
    SHOP_MIN = 1.2,        -- s before input is read (lets the screen settle)
}

-- naval ranks awarded at game over, by score threshold (from Vectorblade).
C.RANKS = {
    { 0, "ENSIGN" },
    { 20000, "LIEUTENANT" },
    { 50000, "COMMANDER" },
    { 90000, "CAPTAIN" },
    { 140000, "ADMIRAL" },
    { 200000, "ADMIRAL 1 BRONZE STAR" },
    { 270000, "ADMIRAL 2 BRONZE STARS" },
    { 350000, "ADMIRAL 3 BRONZE STARS" },
    { 440000, "ADMIRAL 1 SILVER STAR" },
    { 540000, "ADMIRAL 2 SILVER STARS" },
    { 740000, "ADMIRAL 3 SILVER STARS" },
    { 1040000, "GREAT DEFENDER" },
}

function C.rankFor(score)
    local name = C.RANKS[1][2]
    for _, r in ipairs(C.RANKS) do
        if score >= r[1] then name = r[2] else break end
    end
    return name
end
