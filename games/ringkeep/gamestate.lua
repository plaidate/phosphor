-- Ringkeep: shared state. Effects route to the library's Fx pool.

G = {
    score = 0,
    lives = C.START_LIVES,
    wave = 1,
    speedMul = 1.0,    -- global pace; rises every time the core falls
    ship = nil,
    shots = {},
    rings = {},        -- built by Castle.reset
    coreAim = 0,       -- the core's turret tracks the player
    fireball = nil,
    fbCool = 0,
    mines = {},
    respawnT = 0,
}

function G.addScore(n)
    G.score = G.score + n
    Harness.count("scorePts", n)
end

function G.burst(x, y, n)
    Fx.burst(x, y, n)
end

function G.addDebris(x, y, n)
    Fx.debris(x, y, n)
end

-- shortest wrapped delta from (ax,ay) to (bx,by): chasers steer through edges
function G.wrapDelta(ax, ay, bx, by)
    local dx, dy = bx - ax, by - ay
    if dx > Field.W / 2 then dx = dx - Field.W elseif dx < -Field.W / 2 then dx = dx + Field.W end
    if dy > Field.H / 2 then dy = dy - Field.H elseif dy < -Field.H / 2 then dy = dy + Field.H end
    return dx, dy
end
