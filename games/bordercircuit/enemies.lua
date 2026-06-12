-- The opposition: drone ships that circulate the track and accelerate,
-- mine layers that seed it with photon mines, and everyone's bullets.

Enemies = {}

local clamp = Util.clamp

-- plain euclidean distance: the arena has walls, never wrap-aware math
local function dist2(ax, ay, bx, by)
    local dx, dy = ax - bx, ay - by
    return dx * dx + dy * dy
end

-- steer e's velocity toward its current waypoint, advance the waypoint
-- when reached, move, and keep it on the track via the bounce physics
local function steer(e, dt, speed, turnRate)
    local tx, ty = Arena.waypoint(e.wp)
    if Vec.len(tx - e.x, ty - e.y) < 24 then
        e.wp = e.wp + e.dir
        e.passes = e.passes + 1
        tx, ty = Arena.waypoint(e.wp)
    end
    local cur = Vec.angleOf(e.vx, e.vy)
    local want = Vec.angleOf(tx - e.x, ty - e.y)
    local turn = clamp(Vec.angleDiff(cur, want), -turnRate * dt, turnRate * dt)
    e.vx, e.vy = Vec.fromAngle(cur + turn, speed)
    e.x = e.x + e.vx * dt
    e.y = e.y + e.vy * dt
    Arena.bounce(e, e.r, 1)
end

-- ------------------------------------------------------------------ spawning

function Enemies.addDrone(x, y, dir, speed, wpIndex)
    local a = math.random() * 360
    G.drones[#G.drones + 1] = {
        x = x, y = y,
        vx = 0, vy = 0,
        r = C.DRONE_R,
        speed = speed,
        dir = dir,
        wp = wpIndex + dir,
        passes = 0,
        fireT = 1.5 + math.random() * 2.5,
    }
    local d = G.drones[#G.drones]
    d.vx, d.vy = Vec.fromAngle(a, speed) -- steer() will swing it onto the track
end

local function addLayer(x, y, dir, wpIndex)
    G.layers[#G.layers + 1] = {
        x = x, y = y,
        vx = 0, vy = 0,
        r = C.LAYER_R,
        dir = dir,
        wp = wpIndex + dir,
        passes = 0,
        circuitDone = false,
        mineT = C.MINE_EVERY * (0.5 + math.random() * 0.5),
    }
end

-- pick a circuit corner at least 90px from the ship
local function spawnCorner()
    local ok = {}
    for k = 1, 4 do
        local x, y = Arena.waypoint(k)
        if not G.ship or dist2(x, y, G.ship.x, G.ship.y) > 90 * 90 then
            ok[#ok + 1] = k
        end
    end
    if #ok == 0 then ok = { 1, 2 } end
    return ok[math.random(#ok)]
end

function Enemies.spawnWave()
    G.wave = G.wave + 1
    G.droneKills = 0
    G.waveT = 0
    local v0 = math.min(C.DRONE_V0 + (G.wave - 1) * C.DRONE_WAVE_V, C.DRONE_VMAX)
    local n = clamp(3 + G.wave, 4, 6)
    for i = 1, n do
        local k = spawnCorner()
        local x, y = Arena.waypoint(k)
        local dir = (i % 2 == 0) and 1 or -1
        Enemies.addDrone(x + math.random(-14, 14), y + math.random(-10, 10), dir, v0, k)
    end
    for i = 1, C.LAYERS_PER_WAVE do
        local k = spawnCorner()
        local x, y = Arena.waypoint(k)
        addLayer(x, y, (i % 2 == 0) and 1 or -1, k)
    end
    Sfx.warble()
    Harness.count("waves")
end

-- ------------------------------------------------------------------- updates

function Enemies.updateDrones(dt)
    for _, d in ipairs(G.drones) do
        d.speed = math.min(C.DRONE_VMAX, d.speed + C.DRONE_ACCEL * dt)
        local turnRate = C.DRONE_TURN * (0.5 + d.speed / C.DRONE_VMAX)
        steer(d, dt, d.speed, turnRate)

        d.fireT = d.fireT - dt
        if d.fireT <= 0 then
            d.fireT = 1.6 + math.random() * 2.4
            local s = G.ship
            if s and s.alive and math.random() < 0.6 then
                local a = Vec.angleOf(s.x - d.x, s.y - d.y) + (math.random() - 0.5) * 12
                local vx, vy = Vec.fromAngle(a, C.ESHOT_SPEED)
                G.eshots[#G.eshots + 1] = {
                    x = d.x, y = d.y, vx = vx, vy = vy, life = C.ESHOT_LIFE,
                }
                Sfx.pew(420)
            end
        end
    end
end

function Enemies.updateLayers(dt)
    for _, l in ipairs(G.layers) do
        steer(l, dt, C.LAYER_V, 180)
        if l.passes >= 4 then l.circuitDone = true end

        l.mineT = l.mineT - dt
        if l.mineT <= 0 then
            l.mineT = C.MINE_EVERY
            if #G.mines < C.MAX_MINES then
                G.mines[#G.mines + 1] = {
                    x = l.x, y = l.y, r = C.MINE_R, armT = C.MINE_ARM,
                }
                Sfx.blip(330)
            end
        end
    end
end

function Enemies.updateMines(dt)
    for _, m in ipairs(G.mines) do
        if m.armT > 0 then
            m.armT = m.armT - dt
            if m.armT <= 0 then Sfx.blip(520) end
        end
    end
end

function Enemies.updateEshots(dt)
    for i = #G.eshots, 1, -1 do
        local b = G.eshots[i]
        b.life = b.life - dt
        if b.life <= 0 then
            table.remove(G.eshots, i)
        else
            b.x = b.x + b.vx * dt
            b.y = b.y + b.vy * dt
            if Arena.bounce(b, 2, 1) then
                Arena.spark(b.x, b.y)
            end
        end
    end
end

function Enemies.update(dt)
    Enemies.updateDrones(dt)
    Enemies.updateLayers(dt)
    Enemies.updateMines(dt)
    Enemies.updateEshots(dt)
end

-- --------------------------------------------------------------- collisions

local function killDrone(i)
    local d = G.drones[i]
    table.remove(G.drones, i)
    local pts = math.min(C.PTS_DRONE_BASE + G.droneKills * C.PTS_DRONE_STEP, C.PTS_DRONE_CAP)
    G.droneKills = G.droneKills + 1
    G.addScore(pts)
    Fx.burst(d.x, d.y, 7)
    Fx.debris(d.x, d.y, 3)
    Sfx.boom(2)
    Harness.count("drones")
end

local function killLayer(i)
    local l = G.layers[i]
    table.remove(G.layers, i)
    G.addScore(l.circuitDone and C.PTS_LAYER or C.PTS_LAYER_BONUS)
    Fx.burst(l.x, l.y, 8)
    Fx.debris(l.x, l.y, 4)
    Sfx.boom(3)
    Harness.count("layers")
end

local function killMine(i)
    local m = G.mines[i]
    table.remove(G.mines, i)
    G.addScore(C.PTS_MINE)
    Fx.burst(m.x, m.y, 6)
    Sfx.boom(1)
    Harness.count("minesShot")
end

function Enemies.collide()
    -- player shots vs drones, layers, mines (armed or not)
    for i = #G.shots, 1, -1 do
        local b = G.shots[i]
        local hit = false
        for j = #G.drones, 1, -1 do
            local d = G.drones[j]
            if dist2(b.x, b.y, d.x, d.y) < (d.r + 2) * (d.r + 2) then
                killDrone(j)
                hit = true
                break
            end
        end
        if not hit then
            for j = #G.layers, 1, -1 do
                local l = G.layers[j]
                if dist2(b.x, b.y, l.x, l.y) < (l.r + 2) * (l.r + 2) then
                    killLayer(j)
                    hit = true
                    break
                end
            end
        end
        if not hit then
            for j = #G.mines, 1, -1 do
                local m = G.mines[j]
                if dist2(b.x, b.y, m.x, m.y) < (m.r + 2) * (m.r + 2) then
                    killMine(j)
                    hit = true
                    break
                end
            end
        end
        if hit then table.remove(G.shots, i) end
    end

    -- touch anything = death
    local s = G.ship
    if not (s and s.alive) or s.invuln > 0 then return end
    for _, d in ipairs(G.drones) do
        if dist2(s.x, s.y, d.x, d.y) < (s.r + d.r) * (s.r + d.r) then
            Ship.kill()
            return
        end
    end
    for _, l in ipairs(G.layers) do
        if dist2(s.x, s.y, l.x, l.y) < (s.r + l.r) * (s.r + l.r) then
            Ship.kill()
            return
        end
    end
    for _, m in ipairs(G.mines) do
        if m.armT <= 0 and dist2(s.x, s.y, m.x, m.y) < (s.r + m.r) * (s.r + m.r) then
            Ship.kill()
            return
        end
    end
    for i = #G.eshots, 1, -1 do
        local b = G.eshots[i]
        if dist2(s.x, s.y, b.x, b.y) < (s.r + 2) * (s.r + 2) then
            table.remove(G.eshots, i)
            Ship.kill()
            return
        end
    end
end
