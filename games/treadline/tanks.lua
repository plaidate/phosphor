-- Treadline combat: player treads + turret + shell, the hostile tank's
-- stalk/circle/aim AI (lead error shrinks per kill), and the skimmer —
-- a fast floating diamond that weaves in and rams.

Tanks = {}

local clamp = Util.clamp

-- ------------------------------------------------------------------- player

function Tanks.movePlayer(drive, turn, crank, dt)
    -- crank slews the turret (and the view) independently of the hull
    G.turretOff = (G.turretOff + crank * C.CRANK_RATIO + 180) % 360 - 180

    -- treads: pivot in place, or a gentler arc while driving
    local rate = (drive ~= 0) and C.ARC_RATE or C.PIVOT_RATE
    G.hullYaw = (G.hullYaw + turn * rate * dt) % 360

    G.pvx, G.pvz = 0, 0
    local sp = (drive > 0 and C.DRIVE_SPEED) or (drive < 0 and -C.REVERSE_SPEED) or 0
    if sp ~= 0 then
        local hx, hz = World.heading(G.hullYaw)
        local nx, nz = G.px + hx * sp * dt, G.pz + hz * sp * dt
        local blocked = World.hitsObstacle(nx, nz, C.PLAYER_R)
        if not blocked and G.enemy and G.enemy.kind == "tank"
            and Vec.len(nx - G.enemy.x, nz - G.enemy.z) < 3.4 then
            blocked = true
        end
        if not blocked then
            G.pvx, G.pvz = (nx - G.px) / dt, (nz - G.pz) / dt
            G.px, G.pz = nx, nz
        end
        if Attract.frame % 6 == 0 then Sfx.thrustTick() end
    end
end

function Tanks.fire()
    if G.shell or G.dead then return end
    local vy = G.viewYaw()
    local hx, hz = World.heading(vy)
    G.shell = {
        x = G.px + hx * 2.2, y = 1.05, z = G.pz + hz * 2.2,
        vx = hx * C.SHELL_SPEED, vz = hz * C.SHELL_SPEED,
        yaw = vy, life = C.SHELL_LIFE,
    }
    Harness.count("shots")
    Sfx.pew(990)
end

function Tanks.hitPlayer()
    G.lives = G.lives - 1
    Harness.count("deaths")
    Fx.flash(0.35)
    Sfx.bigBoom()
    Draw.crack()
    G.crackT = 2
    G.dead = true
    G.respawnT = 1.8
    G.shell = nil
end

function Tanks.respawnPlayer()
    G.dead = false
    G.invuln = 2
    G.eShell = nil
    -- shove the hostile back out so we don't wake up under its barrel
    local e = G.enemy
    if e then
        local hx, hz = World.heading(math.random(0, 359))
        e.x, e.z = G.px + hx * 50, G.pz + hz * 50
        e.state, e.fireT, e.t = "stalk", 2, 0
    end
end

-- ------------------------------------------------------------------- shells

local function puff(x, y, z, n)
    local sx, sy = Proj.point(x, y, z)
    if sx then Fx.burst(sx, sy, n or 6, 40) end
end

function Tanks.updateShells(dt)
    local s = G.shell
    if s then
        s.x, s.z = s.x + s.vx * dt, s.z + s.vz * dt
        s.life = s.life - dt
        local e = G.enemy
        if World.hitsObstacle(s.x, s.z, 0.3) then
            puff(s.x, s.y, s.z)
            Sfx.blip(220)
            G.shell = nil
        elseif e and Vec.len(s.x - e.x, s.z - e.z) < (e.kind == "skimmer" and 1.9 or 2.4) then
            G.shell = nil
            Tanks.killEnemy(e, true)
        elseif s.life <= 0 then
            G.shell = nil
        end
    end

    local es = G.eShell
    if es then
        es.x, es.z = es.x + es.vx * dt, es.z + es.vz * dt
        es.life = es.life - dt
        if World.hitsObstacle(es.x, es.z, 0.3) then
            puff(es.x, es.y, es.z)
            G.eShell = nil
        elseif not G.dead and G.invuln <= 0
            and Vec.len(es.x - G.px, es.z - G.pz) < C.PLAYER_R + 0.5 then
            G.eShell = nil
            Tanks.hitPlayer()
        elseif es.life <= 0 then
            G.eShell = nil
        end
    end
end

-- ------------------------------------------------------------------ enemies

function Tanks.spawnEnemy()
    G.spawnN = G.spawnN + 1
    local kind = (G.spawnN >= 3 and G.spawnN % 3 == 0) and "skimmer" or "tank"
    for _ = 1, 16 do
        local hx, hz = World.heading(math.random(0, 359))
        local d = C.ENEMY_SPAWN_MIN + math.random() * (C.ENEMY_SPAWN_MAX - C.ENEMY_SPAWN_MIN)
        local x, z = G.px + hx * d, G.pz + hz * d
        if not World.hitsObstacle(x, z, 2.5) then
            G.enemy = {
                kind = kind, x = x, z = z, y = 1.1,
                yaw = World.bearing(G.px - x, G.pz - z),
                state = "stalk", t = 0, fireT = 1.2, dir = 1,
                phase = math.random() * 6,
            }
            Sfx.warble()
            return
        end
    end
    G.spawnT = 0.4 -- crowded out there; try again shortly
end

function Tanks.killEnemy(e, scored)
    local sx, sy = Proj.point(e.x, e.y or 1, e.z)
    if sx then
        Fx.burst(sx, sy, 14)
        Fx.debris(sx, sy, 10)
    end
    World.fragBurst(e.x, e.y or 1, e.z, 9)
    Sfx.boom(3)
    if scored then
        if e.kind == "skimmer" then
            G.addScore(C.PTS_SKIMMER)
            Harness.count("skimmers")
        else
            G.addScore(C.PTS_TANK)
            Harness.count("tanks")
        end
        G.kills = G.kills + 1
    end
    G.enemy = nil
    G.eShell = nil
    G.spawnT = 1.6 + math.random() * 1.2
end

local function enemyFire(e, dist)
    -- lead the player's velocity, with an error that shrinks per kill
    local t = dist / C.ESHELL_SPEED
    local tx, tz = G.px + G.pvx * t, G.pz + G.pvz * t
    local err = math.max(C.AIM_MIN_ERR, C.AIM_BASE_ERR - G.kills * C.AIM_ERR_STEP)
    local aim = World.bearing(tx - e.x, tz - e.z) + (math.random() * 2 - 1) * err
    local hx, hz = World.heading(aim)
    G.eShell = {
        x = e.x + hx * 2.2, y = 1.1, z = e.z + hz * 2.2,
        vx = hx * C.ESHELL_SPEED, vz = hz * C.ESHELL_SPEED,
        yaw = aim, life = C.ESHELL_LIFE,
    }
    e.fireT = C.TANK_FIRE_CD
    Sfx.pew(440)
end

local function updateTank(e, dt, dist, brg)
    local diff = Vec.angleDiff(e.yaw, brg)
    e.fireT = math.max(0, e.fireT - dt)
    e.t = e.t - dt

    local want, speed = brg, 0
    if e.state == "stalk" then
        if math.abs(diff) < 40 then speed = C.TANK_SPEED end
        if dist < C.STALK_DIST then
            e.state = "circle"
            e.t = 2.5 + math.random() * 2.5
            e.dir = math.random() < 0.5 and -1 or 1
        end
    elseif e.state == "circle" then
        want = brg + 80 * e.dir
        speed = C.TANK_SPEED * 0.85
        if dist > C.STALK_DIST + 14 then e.state = "stalk" end
        if e.t <= 0 then
            e.state, e.t = "aim", 2.2
        end
    else -- aim: stop, swing the barrel on, shoot
        if e.t <= 0 then
            e.state, e.t, e.dir = "circle", 2 + math.random() * 2, -e.dir
        elseif math.abs(diff) < 4 and e.fireT <= 0 and dist < 55
            and not G.eShell and not G.dead
            and not World.losBlocked(e.x, e.z, G.px, G.pz) then
            enemyFire(e, dist)
        end
    end

    e.yaw = e.yaw + clamp(Vec.angleDiff(e.yaw, want), -C.TANK_TURN * dt, C.TANK_TURN * dt)

    if speed > 0 then
        local hx, hz = World.heading(e.yaw)
        local nx, nz = e.x + hx * speed * dt, e.z + hz * speed * dt
        if World.hitsObstacle(nx, nz, 2) then
            e.yaw = e.yaw + (e.dir or 1) * 90 * dt -- steer around it
        elseif Vec.len(nx - G.px, nz - G.pz) > 3.4 then
            e.x, e.z = nx, nz
        end
    end
end

local function updateSkimmer(e, dt, dist, brg)
    e.phase = e.phase + dt
    e.y = 1.1 + math.sin(e.phase * 3.2) * 0.5
    local want = brg + math.sin(e.phase * 2.6) * 55 -- erratic weave inward
    e.yaw = e.yaw + clamp(Vec.angleDiff(e.yaw, want), -160 * dt, 160 * dt)
    local hx, hz = World.heading(e.yaw)
    local nx, nz = e.x + hx * C.SKIMMER_SPEED * dt, e.z + hz * C.SKIMMER_SPEED * dt
    if World.hitsObstacle(nx, nz, 1.2) then
        e.yaw = e.yaw + 120 * dt
    else
        e.x, e.z = nx, nz
    end
    if dist < C.SKIMMER_R + C.PLAYER_R and not G.dead and G.invuln <= 0 then
        Tanks.killEnemy(e, false) -- a ram scores nothing
        Tanks.hitPlayer()
    end
end

function Tanks.updateEnemy(dt)
    local e = G.enemy
    if not e then
        G.spawnT = G.spawnT - dt
        if G.spawnT <= 0 then Tanks.spawnEnemy() end
        return
    end

    local dx, dz = G.px - e.x, G.pz - e.z
    local dist = Vec.len(dx, dz)
    local brg = World.bearing(dx, dz)

    -- radar ping quickens as the hostile closes
    G.pingT = G.pingT - dt
    if G.pingT <= 0 then
        G.pingT = clamp(dist / 30, 0.3, 1.4)
        Sfx.blip(1240)
    end

    if e.kind == "skimmer" then
        updateSkimmer(e, dt, dist, brg)
    else
        updateTank(e, dt, dist, brg)
    end
end
