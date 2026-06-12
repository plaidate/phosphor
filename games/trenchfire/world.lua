-- Trenchfire world: phase setup and simulation — fighter swoop patterns,
-- ground towers, trench hardpoints, fireballs, wall scrapes, laser hit
-- resolution, and the fortress port. All shot aiming is done in screen
-- space against the current Proj camera.

World = {}

local clamp = Util.clamp

function World.speed()
    return (C.SPEED_MIN + (C.SPEED_MAX - C.SPEED_MIN) * G.throttle)
        * (1 + C.LEVEL_SPEED * (G.level - 1))
end

function World.latRange()
    if G.phase == "trench" then return C.TRENCH_W - 3 end
    return C.LAT_RANGE
end

function World.vertRange()
    if G.phase == "trench" then return 5, C.TRENCH_H - 6 end
    return C.VERT_LO, C.VERT_HI
end

-- phases ---------------------------------------------------------------

local function layTrench()
    G.trenchEnd = C.TRENCH_LEN + 150 * (G.level - 1)
    G.hardpoints = {}
    local every = math.max(110, C.HARDPOINT_EVERY - 12 * (G.level - 1))
    local z = 260
    while z < G.trenchEnd - 220 do
        local side = (math.random() < 0.5) and -1 or 1
        G.hardpoints[#G.hardpoints + 1] = {
            x = side * (C.TRENCH_W - 1),
            y = 8 + math.random() * (C.TRENCH_H - 20),
            z = z + math.random(-30, 30),
            side = side,
            cool = 0.5 + math.random() * 2,
            r = 6, aimY = 0, pts = C.PTS_HARDPOINT, kind = "hardpoints",
        }
        z = z + every
    end
    G.braces = {}
    local bz = 200
    while bz < G.trenchEnd - 120 do
        G.braces[#G.braces + 1] = bz
        bz = bz + C.BRACE_EVERY
    end
end

function World.startPhase(phase)
    G.phase = phase
    G.camZ = 0
    G.fireballs, G.fighters, G.towers, G.hardpoints = {}, {}, {}, {}
    if phase == "approach" then
        G.spawned = 0
        G.quota = C.FIGHTER_QUOTA + 2 * (G.level - 1)
        G.spawnT = 0.5
        G.setBanner("FIGHTERS INBOUND")
    elseif phase == "towers" then
        G.nextTowerZ = 320
        G.setBanner("TOWER FIELD")
    else
        layTrench()
        G.setBanner("TRENCH RUN")
    end
end

function World.startLevel(level)
    G.level = level
    World.startPhase("approach")
end

-- fireballs ------------------------------------------------------------

-- slow shot aimed at where the ship will roughly be; closing rate is the
-- shot's own speed plus the ship's forward speed
function World.spawnFireball(x, y, z)
    if #G.fireballs >= C.FB_MAX + math.floor(G.level / 2) then return end
    local spd = C.FB_SPEED + World.speed() * 0.5 + 5 * (G.level - 1)
    local dz = z - G.camZ
    local T = math.max(dz / (spd + World.speed() * 0.5), 0.4)
    local dx = G.camX + (math.random() - 0.5) * 14 - x
    local dy = G.camY + (math.random() - 0.5) * 10 - y
    local dzz = G.camZ + World.speed() * T - z
    local l = math.sqrt(dx * dx + dy * dy + dzz * dzz)
    if l < 1 then return end
    G.fireballs[#G.fireballs + 1] = {
        x = x, y = y, z = z,
        vx = dx / l * spd, vy = dy / l * spd, vz = dzz / l * spd,
        r = C.FB_R, aimY = 0, pts = C.PTS_FIREBALL, kind = "fireballs",
    }
    Sfx.blip(280)
end

local function updateFireballs(dt)
    for i = #G.fireballs, 1, -1 do
        local f = G.fireballs[i]
        f.x, f.y, f.z = f.x + f.vx * dt, f.y + f.vy * dt, f.z + f.vz * dt
        local dz = f.z - G.camZ
        if dz < Proj.near then
            if math.abs(f.x - G.camX) < C.HIT_R and math.abs(f.y - G.camY) < C.HIT_R then
                World.playerHit()
            end
            table.remove(G.fireballs, i)
        elseif dz > 900 then
            table.remove(G.fireballs, i)
        end
    end
end

-- fighters (approach) ----------------------------------------------------

local function spawnFighter()
    G.spawned = G.spawned + 1
    G.fighters[#G.fighters + 1] = {
        t = math.random() * 6,
        dz = C.FIGHTER_SPAWN_Z + math.random(0, 120),
        close = 70 + math.random(50) + 8 * G.level, -- approach rate
        cx = math.random(-55, 55), cy = 18 + math.random(22),
        ax = 30 + math.random(55), ay = 10 + math.random(22),
        w1 = 0.9 + math.random() * 1.3, w2 = 0.7 + math.random() * 1.1,
        x = 0, y = 26, z = 0, yaw = 0,
        cool = 0.8 + math.random() * 1.2,
        r = 9, aimY = 0, pts = C.PTS_FIGHTER, kind = "fighters",
    }
end

local function updateFighters(dt)
    if G.phase == "approach" and G.spawned < G.quota then
        local active = math.min(C.FIGHTER_ACTIVE + (G.level - 1) // 2, 4)
        G.spawnT = G.spawnT - dt
        if #G.fighters < active and G.spawnT <= 0 then
            G.spawnT = 0.7
            spawnFighter()
        end
    end
    for i = #G.fighters, 1, -1 do
        local f = G.fighters[i]
        f.t = f.t + dt
        f.dz = f.dz - f.close * dt
        f.x = f.cx + math.sin(f.t * f.w1) * f.ax
        f.y = f.cy + math.sin(f.t * f.w2 + 1.7) * f.ay
        f.z = G.camZ + f.dz
        f.yaw = math.cos(f.t * f.w1) * 38 -- banking with the swoop
        f.cool = f.cool - dt
        if f.cool <= 0 and f.dz > 130 and f.dz < 430 then
            f.cool = clamp(1.6 - 0.07 * G.level, 0.7, 1.6) + math.random()
            World.spawnFireball(f.x, f.y, f.z)
        end
        if f.dz < 24 then
            table.remove(G.fighters, i) -- swooped past us, no points
        end
    end
end

-- towers ----------------------------------------------------------------

local function updateTowers(dt)
    if G.phase == "towers" then
        local every = math.max(95, C.TOWER_EVERY - 10 * (G.level - 1))
        while G.nextTowerZ < G.camZ + 750 and G.nextTowerZ < C.TOWERS_LEN + 350 do
            G.towers[#G.towers + 1] = {
                x = math.random(-110, 110), y = 0, z = G.nextTowerZ,
                cool = 0.6 + math.random() * 1.6,
                r = 9, aimY = C.TOWER_H * 0.55, pts = C.PTS_TOWER, kind = "towers",
            }
            G.nextTowerZ = G.nextTowerZ + every * (0.6 + math.random() * 0.8)
        end
    end
    for i = #G.towers, 1, -1 do
        local tw = G.towers[i]
        local dz = tw.z - G.camZ
        tw.cool = tw.cool - dt
        if tw.cool <= 0 and dz > 70 and dz < 520 then
            tw.cool = clamp(2.2 - 0.12 * G.level, 0.9, 2.2) * (0.7 + math.random() * 0.6)
            World.spawnFireball(tw.x, tw.y + C.TOWER_H, tw.z)
        end
        if dz < 6 then table.remove(G.towers, i) end
    end
end

-- trench hardpoints -------------------------------------------------------

local function updateHardpoints(dt)
    for i = #G.hardpoints, 1, -1 do
        local h = G.hardpoints[i]
        local dz = h.z - G.camZ
        h.cool = h.cool - dt
        if h.cool <= 0 and dz > 50 and dz < 460 then
            h.cool = clamp(2.0 - 0.1 * G.level, 0.8, 2.0) * (0.7 + math.random() * 0.6)
            World.spawnFireball(h.x - h.side * 3, h.y, h.z)
        end
        if dz < 2 then table.remove(G.hardpoints, i) end
    end
end

-- damage ------------------------------------------------------------------

function World.playerHit()
    if G.invulnT > 0 then return end
    G.invulnT = C.INVULN
    G.shields = G.shields - 1
    Harness.count("hits")
    Fx.flash(0.12)
    Fx.debris(G.crossX, G.crossY, 6)
    Sfx.boom(2)
    if G.shields <= 0 then
        Sfx.bigBoom()
        Fx.flash(0.4)
        Harness.count("gameovers")
        Attract.gameOver()
    end
end

local function updateScrape(dt)
    if G.phase ~= "trench" then return end
    if G.scrapeT > 0 then
        G.scrapeT = G.scrapeT - dt
        return
    end
    if math.abs(G.camX) > C.TRENCH_W - 7 then
        G.scrapeT = C.SCRAPE_COOLDOWN
        G.camX = G.camX * 0.55 -- kicked back toward the centerline
        G.crossX = G.crossX + (Proj.cx - G.crossX) * 0.5
        Sfx.thrustTick()
        World.playerHit()
    end
end

-- firing --------------------------------------------------------------------

local function killAt(list, idx, e, sx, sy)
    table.remove(list, idx)
    G.addScore(e.pts)
    Harness.count(e.kind)
    Fx.burst(sx, sy, e.kind == "fireballs" and 6 or 12)
    if e.kind == "towers" or e.kind == "hardpoints" then
        Fx.debris(sx, sy, 6)
    end
    Sfx.boom(e.kind == "fireballs" and 1 or 2)
end

local function fortressDown(sx, sy)
    G.addScore(C.PTS_FORTRESS)
    G.shields = math.min(G.shields + 1, C.MAX_SHIELDS)
    Harness.count("fortresses")
    Harness.count("levels")
    Fx.flash(0.5)
    Fx.burst(sx, sy, 24, 130)
    Fx.debris(sx, sy, 14)
    Sfx.bigBoom()
    Sfx.fanfare()
    World.startLevel(G.level + 1)
    G.setBanner("FORTRESS DESTROYED +1 SHIELD", 2.4)
end

-- one trigger pull: corner beams converge on the crosshair; the nearest
-- projected target under it takes the hit. The fortress port is checked
-- first when in range.
function World.fire()
    if G.fireT > 0 then return end
    G.fireT = C.FIRE_COOLDOWN
    G.lasers[#G.lasers + 1] = { t = C.LASER_LIFE, x = G.crossX, y = G.crossY }
    Harness.count("shots")
    Sfx.pew(960)

    if G.phase == "trench" then
        local dz = G.trenchEnd - G.camZ
        if dz > 10 and dz < C.PORT_RANGE then
            local px, py = Proj.point(0, C.PORT_Y, G.trenchEnd)
            if px then
                local k = Proj.focal / dz
                if math.abs(G.crossX - px) < C.PORT_W * k + 5
                    and math.abs(G.crossY - py) < C.PORT_H * k + 5 then
                    fortressDown(px, py)
                    return
                end
            end
        end
    end

    local bestZ, bestList, bestIdx, bestSx, bestSy = math.huge
    local function consider(list)
        for i, e in ipairs(list) do
            local sx, sy, z = Proj.point(e.x, e.y + e.aimY, e.z)
            if sx and z < bestZ then
                local rad = e.r * Proj.focal / z + C.AIM_ASSIST
                local dx, dy = G.crossX - sx, G.crossY - sy
                if dx * dx + dy * dy < rad * rad then
                    bestZ, bestList, bestIdx, bestSx, bestSy = z, list, i, sx, sy
                end
            end
        end
    end
    consider(G.fireballs)
    consider(G.fighters)
    consider(G.towers)
    consider(G.hardpoints)
    if bestList then
        killAt(bestList, bestIdx, bestList[bestIdx], bestSx, bestSy)
    end
end

-- per-frame -------------------------------------------------------------------

function World.update(dt)
    if G.invulnT > 0 then G.invulnT = G.invulnT - dt end
    if G.bannerT > 0 then G.bannerT = G.bannerT - dt end
    for i = #G.lasers, 1, -1 do
        local l = G.lasers[i]
        l.t = l.t - dt
        if l.t <= 0 then table.remove(G.lasers, i) end
    end

    updateFighters(dt)
    updateTowers(dt)
    updateHardpoints(dt)
    updateFireballs(dt)
    updateScrape(dt)
    if Attract.state ~= "play" then return end -- died this frame

    if G.phase == "approach" then
        if G.spawned >= G.quota and #G.fighters == 0 then
            World.startPhase("towers")
        end
    elseif G.phase == "towers" then
        if G.camZ > C.TOWERS_LEN then
            World.startPhase("trench")
        end
    else
        if G.camZ > G.trenchEnd - 36 then
            -- overshot the port: pull up and come around for another pass
            G.camZ = 0
            layTrench()
            G.setBanner("MISSED - COME AROUND")
            Sfx.descend()
        end
    end
end
