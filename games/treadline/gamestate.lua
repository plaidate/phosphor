-- Treadline: shared state. The player is a hull heading plus a turret
-- offset; the camera looks where the turret points.

G = {
    px = 0, pz = 0,    -- hull position on the plain
    hullYaw = 0,       -- hull heading, degrees (0 = +Z)
    turretOff = 0,     -- turret relative to hull, degrees, wrapped to +-180
    pvx = 0, pvz = 0,  -- hull velocity last frame (enemy lead calc)

    score = 0,
    lives = 3,
    nextLifeAt = 15000,
    kills = 0,         -- enemy aim error shrinks with this
    spawnN = 0,        -- every 3rd spawn is a skimmer

    shell = nil,       -- the one live player shell
    eShell = nil,      -- the one live enemy shell
    enemy = nil,       -- one hostile at a time
    spawnT = 2,        -- countdown to the next spawn
    pingT = 0,         -- radar ping countdown

    dead = false,      -- between a hit and the respawn
    respawnT = 0,
    invuln = 0,
    crackT = 0,        -- cracked-screen overlay seconds left

    ambYaw = 0,        -- title-screen camera spin
}

function G.viewYaw()
    return G.hullYaw + G.turretOff
end

function G.addScore(n)
    G.score = G.score + n
    if G.score >= G.nextLifeAt and G.lives < C.MAX_LIVES then
        G.lives = G.lives + 1
        G.nextLifeAt = G.nextLifeAt + C.EXTRA_LIFE_AT
        Sfx.fanfare({ 659, 769, 879, 989 })
    end
end
