-- Open Geometry Wars: the full bestiary and all combat collisions. Each enemy
-- is a light table tagged by kind; Enemies.update runs the per-kind AI, the
-- black-hole gravity field, shot/ship collisions, and deaths. Chasers scale
-- with G.aggro. Deaths drive G.registerKill (the kill-count multiplier) and
-- the type-specific spawns: spinners shed tiny spinners, holes burst into
-- protons, snakes and repulsors scatter line debris.

Enemies = {}

local DEF = {
    grunt = C.GRUNT, wander = C.WANDER, spinner = C.SPINNER, tiny = C.TINY,
    weaver = C.WEAVER, hole = C.HOLE, proton = C.PROTON, mayfly = C.MAYFLY,
    snake = C.SNAKE, repulsor = C.REPULSOR,
}

function Enemies.spawn(kind, x, y, warn)
    local d = DEF[kind]
    local e = {
        kind = kind, x = x, y = y, vx = 0, vy = 0,
        r = d.r, points = d.points,
        warn = warn and C.SPAWN_WARN or 0,
        anim = math.random() * 6.28,
        heading = math.random() * 360,
    }
    if kind == "hole" then
        e.hp = d.hp
    elseif kind == "snake" then
        e.trail = {}
        for _ = 1, d.segs * d.seglag + 2 do e.trail[#e.trail + 1] = { x = x, y = y } end
        e.tx, e.ty = math.random(20, Field.W - 20), math.random(20, Field.H - 20)
    elseif kind == "repulsor" then
        e.hp = d.hp
        e.facing = math.random() * 360
        e.ai = "think"
        e.aiT = 0.4
        e.shieldPhase = 0
        e.shieldUp = true
    elseif kind == "mayfly" then
        e.flipT = math.random() * 0.5
        e.wing = 0
    end
    G.enemies[#G.enemies + 1] = e
    if warn then Harness.count("spawns") end
    return e
end

local function toPlayer(e)
    local s = G.ship
    local dx, dy = s.x - e.x, s.y - e.y
    local d = Vec.len(dx, dy)
    if d < 1e-3 then return 0, 0, 0 end
    return dx / d, dy / d, d
end

local function steer(e, speed, accel, dt)
    speed = speed * G.aggro
    local nx, ny = toPlayer(e)
    e.vx = e.vx + nx * accel * dt
    e.vy = e.vy + ny * accel * dt
    local sp = Vec.len(e.vx, e.vy)
    if sp > speed then e.vx, e.vy = e.vx / sp * speed, e.vy / sp * speed end
end

local function integrate(e, dt)
    e.x = e.x + e.vx * dt
    e.y = e.y + e.vy * dt
end

local function bounce(e)
    if e.x < e.r then e.x, e.vx = e.r, math.abs(e.vx) end
    if e.x > Field.W - e.r then e.x, e.vx = Field.W - e.r, -math.abs(e.vx) end
    if e.y < e.r then e.y, e.vy = e.r, math.abs(e.vy) end
    if e.y > Field.H - e.r then e.y, e.vy = Field.H - e.r, -math.abs(e.vy) end
end

-- the repulsor shoves frontal shots away instead of taking the hit
local function repulse(e, dt)
    local rad = e.r + 22
    for _, b in ipairs(G.shots) do
        local dx, dy = b.x - e.x, b.y - e.y
        if dx * dx + dy * dy < rad * rad then
            local toShot = Vec.angleOf(dx, dy)
            if math.abs(Vec.angleDiff(e.facing, toShot)) < C.REPULSOR.deflect then
                local sp = Vec.len(b.vx, b.vy)
                b.vx, b.vy = Vec.fromAngle(toShot, sp) -- redirect outward
                if math.random() < 0.3 then Fx.debris(b.x, b.y, 1, 30) end
            end
        end
    end
end

local function updateOne(e, dt)
    e.anim = e.anim + dt * 4
    local k = e.kind
    if k == "grunt" then
        steer(e, C.GRUNT.speed, 400, dt); integrate(e, dt)
    elseif k == "wander" then
        if math.random() < 0.03 then e.heading = e.heading + math.random(-90, 90) end
        e.vx, e.vy = Vec.fromAngle(e.heading, C.WANDER.speed)
        integrate(e, dt); bounce(e)
    elseif k == "spinner" then
        steer(e, C.SPINNER.speed, 600, dt); integrate(e, dt)
    elseif k == "tiny" then
        steer(e, C.TINY.speed, 300, dt); integrate(e, dt)
    elseif k == "proton" then
        steer(e, C.PROTON.speed, 500, dt); integrate(e, dt)
    elseif k == "mayfly" then
        steer(e, C.MAYFLY.speed, 350, dt)
        e.vx, e.vy = e.vx * 0.96, e.vy * 0.96
        integrate(e, dt); bounce(e)
        e.flipT = e.flipT - dt
        if e.flipT <= 0 then e.flipT = 0.5; e.wing = 1 - (e.wing or 0) end
    elseif k == "weaver" then
        steer(e, C.WEAVER.speed, 500, dt)
        for _, b in ipairs(G.shots) do
            local dx, dy = b.x - e.x, b.y - e.y
            if dx * dx + dy * dy < 45 * 45 then
                e.vx, e.vy = e.vx - dy * 0.05, e.vy + dx * 0.05
                break
            end
        end
        local sp = Vec.len(e.vx, e.vy)
        local mx = C.WEAVER.speed * G.aggro
        if sp > mx then e.vx, e.vy = e.vx / sp * mx, e.vy / sp * mx end
        integrate(e, dt); bounce(e)
    elseif k == "snake" then
        -- head seeks a roaming waypoint; the body trails behind it
        local dx, dy, d = e.tx - e.x, e.ty - e.y, 0
        d = Vec.len(dx, dy)
        if d < 24 then e.tx, e.ty = math.random(20, Field.W - 20), math.random(20, Field.H - 20) end
        local sp = C.SNAKE.speed * G.aggro
        if d > 1 then e.vx, e.vy = dx / d * sp, dy / d * sp end
        integrate(e, dt); bounce(e)
        table.insert(e.trail, 1, { x = e.x, y = e.y })
        while #e.trail > C.SNAKE.segs * C.SNAKE.seglag + 2 do table.remove(e.trail) end
    elseif k == "repulsor" then
        e.shieldPhase = e.shieldPhase + dt * 3
        e.aiT = e.aiT - dt
        local nx, ny, d = toPlayer(e)
        local want = Vec.angleOf(nx, ny)
        local diff = Vec.angleDiff(e.facing, want)
        if e.ai == "think" then
            e.vx, e.vy = e.vx * 0.92, e.vy * 0.92
            if e.aiT <= 0 then e.ai, e.aiT = "aim", 1.2 end
        elseif e.ai == "aim" then
            e.facing = e.facing + diff * 0.08
            e.vx, e.vy = e.vx * 0.95, e.vy * 0.95
            if math.abs(diff) < 8 or e.aiT <= 0 then e.ai, e.aiT = "charge", 0.7 end
        else -- charge
            e.facing = e.facing + diff * 0.05
            local fx, fy = Vec.fromAngle(e.facing, 1)
            e.vx, e.vy = e.vx + fx * 500 * dt, e.vy + fy * 500 * dt
            local sp = Vec.len(e.vx, e.vy)
            local mx = C.REPULSOR.speed * G.aggro
            if sp > mx then e.vx, e.vy = e.vx / sp * mx, e.vy / sp * mx end
            if e.aiT <= 0 then e.ai, e.aiT = "think", 0.4 end
        end
        integrate(e, dt); bounce(e)
        if e.shieldUp then repulse(e, dt) end
    elseif k == "hole" then
        steer(e, C.HOLE.speed, 80, dt); integrate(e, dt); bounce(e)
        local pull = 120 + math.sin(e.anim) * 40
        Grid.pull(e.x, e.y, pull, 130)
        local s = G.ship
        if s.alive then
            local dx, dy = e.x - s.x, e.y - s.y
            local d2 = dx * dx + dy * dy
            if d2 < 140 * 140 and d2 > 1 then
                local d = math.sqrt(d2)
                s.vx, s.vy = s.vx + dx / d * 2600 / d2, s.vy + dy / d * 2600 / d2
            end
        end
        for _, o in ipairs(G.enemies) do
            if o ~= e and o.warn <= 0 then
                local dx, dy = e.x - o.x, e.y - o.y
                local d2 = dx * dx + dy * dy
                if d2 < 110 * 110 and d2 > 1 then
                    local d = math.sqrt(d2)
                    o.vx, o.vy = o.vx + dx / d * 1800 / d2, o.vy + dy / d * 1800 / d2
                end
            end
        end
    end
end

-- remove enemy at index i. byPlayer awards score + counts toward the multiplier.
local function die(i, byPlayer)
    local e = G.enemies[i]
    table.remove(G.enemies, i)
    Fx.burst(e.x, e.y, (e.kind == "hole" or e.kind == "snake") and 70 or 24, 150)
    Grid.push(e.x, e.y, (e.kind == "hole") and 420 or 120, (e.kind == "hole") and 140 or 50)
    if byPlayer then
        G.addScore(e.points)
        G.registerKill()
    end
    if e.kind == "spinner" then
        for _ = 1, 2 do
            local t = Enemies.spawn("tiny", e.x, e.y, false)
            t.vx, t.vy = Vec.fromAngle(math.random() * 360, C.TINY.speed)
        end
    elseif e.kind == "hole" then
        Sfx.zapSweep()
        for j = 1, 6 do
            local p = Enemies.spawn("proton", e.x, e.y, false)
            p.vx, p.vy = Vec.fromAngle(j * 60, 120)
        end
    elseif e.kind == "snake" then
        Fx.debris(e.x, e.y, 12)
        Sfx.boom(2)
    elseif e.kind == "repulsor" then
        Fx.debris(e.x, e.y, 8)
        Sfx.boom(2)
    else
        Sfx.boom(1)
    end
end

function Enemies.update(dt)
    local list = G.enemies
    for i = #list, 1, -1 do
        local e = list[i]
        if e.warn > 0 then e.warn = e.warn - dt else updateOne(e, dt) end
    end

    -- shots vs enemies (snake: head only; repulsor: front shots are deflected
    -- in updateOne, so only body hits reach here)
    local shots = G.shots
    for si = #shots, 1, -1 do
        local b = shots[si]
        local hit = false
        for ei = #list, 1, -1 do
            local e = list[ei]
            if e.warn <= 0 then
                local rr = e.r + 3
                if (b.x - e.x) ^ 2 + (b.y - e.y) ^ 2 < rr * rr then
                    if e.kind == "hole" or e.kind == "repulsor" then
                        e.hp = e.hp - 1
                        Fx.burst(b.x, b.y, 4, 90)
                        if e.hp <= 0 then die(ei, true) end
                    else
                        die(ei, true)
                    end
                    hit = true
                    break
                end
            end
        end
        if hit then table.remove(shots, si) end
    end

    -- enemies vs ship (snake body segments are dangerous too)
    local s = G.ship
    if s.alive and s.invuln <= 0 then
        for ei = 1, #list do
            local e = list[ei]
            if e.warn <= 0 and Enemies.hitsShip(e, s) then
                Player.kill(); break
            end
        end
    end
end

function Enemies.hitsShip(e, s)
    local rr = e.r + C.SHIP_R
    if Vec.len(e.x - s.x, e.y - s.y) < rr then return true end
    if e.kind == "snake" then
        local sr = e.r * 0.7 + C.SHIP_R
        for j = 1, C.SNAKE.segs do
            local p = e.trail[j * C.SNAKE.seglag]
            if p and Vec.len(p.x - s.x, p.y - s.y) < sr then return true end
        end
    end
    return false
end

function Enemies.bombDamage(wave)
    local list = G.enemies
    for i = #list, 1, -1 do
        local e = list[i]
        if e.warn <= 0 and Vec.len(e.x - wave.x, e.y - wave.y) < wave.r then
            G.addScore(e.points)
            die(i, false)
        end
    end
end
