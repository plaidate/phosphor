-- Open Geometry Wars: the bestiary and all combat collisions. Each enemy is
-- a light table with a kind tag; Enemies.update runs the per-kind AI, the
-- black-hole gravity field, shot/ship collisions, and deaths (geom drops,
-- particle bursts, and the type-specific spawns — spinners shed tiny
-- spinners, black holes burst into protons).

Enemies = {}

local clamp = Util.clamp

local DEF = {
    grunt   = C.GRUNT,
    wander  = C.WANDER,
    spinner = C.SPINNER,
    tiny    = C.TINY,
    weaver  = C.WEAVER,
    hole    = C.HOLE,
    proton  = C.PROTON,
}

-- create an enemy; `warn` true gives it the telegraph delay, false = instant
function Enemies.spawn(kind, x, y, warn)
    local d = DEF[kind]
    local e = {
        kind = kind, x = x, y = y, vx = 0, vy = 0,
        r = d.r, points = d.points,
        warn = warn and C.SPAWN_WARN or 0,
        anim = math.random() * 6.28,
        heading = math.random() * 360,
    }
    if kind == "hole" then e.hp = d.hp; e.grow = 0 end
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

-- bounce a drifter off the field edges
local function bounce(e)
    if e.x < e.r then e.x, e.vx = e.r, math.abs(e.vx) end
    if e.x > Field.W - e.r then e.x, e.vx = Field.W - e.r, -math.abs(e.vx) end
    if e.y < e.r then e.y, e.vy = e.r, math.abs(e.vy) end
    if e.y > Field.H - e.r then e.y, e.vy = Field.H - e.r, -math.abs(e.vy) end
end

local function updateOne(e, dt)
    e.anim = e.anim + dt * 4
    local k = e.kind
    if k == "grunt" then
        steer(e, C.GRUNT.speed, 400, dt)
        integrate(e, dt)
    elseif k == "wander" then
        if math.random() < 0.03 then e.heading = e.heading + math.random(-90, 90) end
        local hx, hy = Vec.fromAngle(e.heading, C.WANDER.speed)
        e.vx, e.vy = hx, hy
        integrate(e, dt)
        bounce(e)
    elseif k == "spinner" then
        steer(e, C.SPINNER.speed, 600, dt)
        integrate(e, dt)
    elseif k == "tiny" then
        steer(e, C.TINY.speed, 300, dt)
        integrate(e, dt)
    elseif k == "weaver" then
        steer(e, C.WEAVER.speed, 500, dt)
        -- dodge the nearest oncoming shot
        local s = G.ship
        for _, b in ipairs(G.shots) do
            local dx, dy = b.x - e.x, b.y - e.y
            if dx * dx + dy * dy < 45 * 45 then
                e.vx = e.vx - dy * 0.05
                e.vy = e.vy + dx * 0.05
                break
            end
        end
        local sp = Vec.len(e.vx, e.vy)
        if sp > C.WEAVER.speed then e.vx, e.vy = e.vx / sp * C.WEAVER.speed, e.vy / sp * C.WEAVER.speed end
        integrate(e, dt)
        bounce(e)
    elseif k == "proton" then
        steer(e, C.PROTON.speed, 500, dt)
        integrate(e, dt)
    elseif k == "hole" then
        steer(e, C.HOLE.speed, 80, dt)
        integrate(e, dt)
        bounce(e)
        e.grow = (e.grow or 0) + dt
        -- the signature deep well: drag the lattice into the hole every frame
        local pull = 120 + math.sin(e.anim) * 40
        Grid.pull(e.x, e.y, pull, 130)
        -- gravity on the ship, enemies, and geoms
        local g = C.HOLE.speed
        local s = G.ship
        if s.alive then
            local dx, dy = e.x - s.x, e.y - s.y
            local d2 = dx * dx + dy * dy
            if d2 < 140 * 140 and d2 > 1 then
                local d = math.sqrt(d2)
                local f = 2600 / d2
                s.vx = s.vx + dx / d * f
                s.vy = s.vy + dy / d * f
            end
        end
        for _, o in ipairs(G.enemies) do
            if o ~= e and o.warn <= 0 then
                local dx, dy = e.x - o.x, e.y - o.y
                local d2 = dx * dx + dy * dy
                if d2 < 110 * 110 and d2 > 1 then
                    local d = math.sqrt(d2)
                    o.vx = o.vx + dx / d * 1800 / d2
                    o.vy = o.vy + dy / d * 1800 / d2
                end
            end
        end
        for _, gm in ipairs(G.geoms) do
            local dx, dy = e.x - gm.x, e.y - gm.y
            gm.vx = gm.vx + dx * 0.04
            gm.vy = gm.vy + dy * 0.04
        end
    end
end

local function dropGeom(x, y)
    if #G.geoms > 60 then return end
    G.geoms[#G.geoms + 1] = {
        x = x, y = y,
        vx = (math.random() - 0.5) * 40,
        vy = (math.random() - 0.5) * 40,
        spin = math.random() * 360,
    }
end

-- remove enemy at index i. byPlayer: award score + drop a geom + spawn kids.
local function die(i, byPlayer)
    local e = G.enemies[i]
    table.remove(G.enemies, i)
    Fx.burst(e.x, e.y, e.kind == "hole" and 70 or 24, 150)
    Grid.push(e.x, e.y, e.kind == "hole" and 420 or 120, e.kind == "hole" and 140 or 50)
    if byPlayer then
        G.addScore(e.points)
        dropGeom(e.x, e.y)
        Harness.count("kills")
    end
    if e.kind == "spinner" then
        for _ = 1, 2 do
            local t = Enemies.spawn("tiny", e.x, e.y, false)
            local a = math.random() * 360
            t.vx, t.vy = Vec.fromAngle(a, C.TINY.speed)
        end
    elseif e.kind == "hole" then
        Sfx.zapSweep()
        for j = 1, 6 do
            local p = Enemies.spawn("proton", e.x, e.y, false)
            p.vx, p.vy = Vec.fromAngle(j * 60, 120)
        end
    else
        Sfx.boom(1)
    end
end

function Enemies.update(dt)
    local list = G.enemies
    for i = #list, 1, -1 do
        local e = list[i]
        if e.warn > 0 then
            e.warn = e.warn - dt
        else
            updateOne(e, dt)
        end
    end

    -- shots vs enemies
    local shots = G.shots
    for si = #shots, 1, -1 do
        local b = shots[si]
        local hit = false
        for ei = #list, 1, -1 do
            local e = list[ei]
            if e.warn <= 0 then
                local rr = e.r + 3
                local dx, dy = b.x - e.x, b.y - e.y
                if dx * dx + dy * dy < rr * rr then
                    if e.kind == "hole" then
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

    -- enemies vs ship
    local s = G.ship
    if s.alive and s.invuln <= 0 then
        for ei = 1, #list do
            local e = list[ei]
            if e.warn <= 0 then
                local rr = e.r + C.SHIP_R
                if Vec.len(e.x - s.x, e.y - s.y) < rr then
                    Player.kill()
                    break
                end
            end
        end
    end
end

-- the expanding smart-bomb shock front clears everything it sweeps over
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

function Enemies.updateGeoms(dt)
    local s = G.ship
    local list = G.geoms
    for i = #list, 1, -1 do
        local gm = list[i]
        gm.spin = gm.spin + dt * 200
        if s.alive then
            local dx, dy = s.x - gm.x, s.y - gm.y
            local d = Vec.len(dx, dy)
            if d < C.GEOM_PICKUP then
                table.remove(list, i)
                G.collectGeom()
                goto continue
            elseif d < C.GEOM_MAGNET then
                gm.vx = gm.vx + dx / d * 700 * dt
                gm.vy = gm.vy + dy / d * 700 * dt
            end
        end
        gm.vx, gm.vy = gm.vx * C.GEOM_DRAG, gm.vy * C.GEOM_DRAG
        gm.x = clamp(gm.x + gm.vx * dt, 4, Field.W - 4)
        gm.y = clamp(gm.y + gm.vy * dt, 4, Field.H - 4)
        ::continue::
    end
end
