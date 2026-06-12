-- Trenchfire shared state and scoring. The "ship" is the camera: the player
-- steers a screen-space crosshair and the camera chases it laterally (rail
-- movement). Shields are the lives.

G = {
    score = 0,
    shields = C.START_SHIELDS,
    level = 1,
    phase = "approach", -- "approach" | "towers" | "trench"

    camX = 0, camY = 26, camZ = 0,
    crossX = 200, crossY = 120,
    throttle = 0.45,    -- 0..1, set by the crank

    fireT = 0,          -- laser cooldown
    invulnT = 0,        -- grace after a shield loss
    scrapeT = 0,        -- grace between wall scrapes

    fighters = {},      -- approach craft (world pos + swoop params)
    towers = {},        -- ground turrets
    hardpoints = {},    -- trench wall guns
    fireballs = {},     -- slow enemy shots, shootable for points
    lasers = {},        -- { t, x, y } screen-space corner-beam flashes
    braces = {},        -- trench overhead brace z positions

    trenchEnd = 0,
    spawned = 0, quota = 0, spawnT = 0,
    nextTowerZ = 0,

    banner = nil, bannerT = 0,
}

-- throttle-driven score multiplier: idle 1x .. full crank 3x
function G.mult()
    return 1 + (C.MULT_MAX - 1) * G.throttle
end

function G.addScore(base)
    G.score = G.score + math.floor(base * G.mult() + 0.5)
end

function G.setBanner(text, t)
    G.banner, G.bannerT = text, t or 1.6
end
