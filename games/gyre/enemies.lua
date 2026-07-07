-- The squadrons: drones swoop in from the center along spline paths, fall
-- back to the rotating hub formation, and take turns diving at the rim.
-- After enough runs they flee the stage. Chance-stage drones just fly
-- their pattern and leave. Satellites and laser ships (events.lua) ride
-- the same entity list so shots, rams and cleanup treat everyone alike.

Enemies = {}

local function pathSpeed(base)
    return base + (G.stage - 1) * C.SPEED_STAGE
end

function Enemies.reset()
    G.enemies = {}
    G.bullets = {}
    G.attackT = C.ATTACK_INTERVAL
    G.resetSlots()
end

-- ---- spawning -------------------------------------------------------------

local function newEnemy(etype, path, after)
    local e = {
        type = etype,
        state = "path",
        path = path,
        t = 0,
        after = after,
        x = path.pts[1],
        y = path.pts[2],
        heading = 0,
        runs = 0,
        ammo = 0,
        fireT = 0.4 + math.random(),
        delayT = 0,
        hitR = C.HIT_DRONE,
        points = C.PTS_DRONE,
    }
    G.enemies[#G.enemies + 1] = e
    return e
end

function Enemies.spawnDrone(kind, th, s, delay)
    local e = newEnemy("drone", Paths.entry(kind, th, s, pathSpeed(C.ENTRY_SPEED)), "form")
    e.kind = "entry"
    e.mirror = s
    e.delayT = delay or 0
    e.slot = G.freeSlot()
    if not e.slot then e.after = "gone" end
    e.ammo = 1 -- one opportunist shot on the way in
    return e
end

function Enemies.spawnChance(kind, th, s, delay, squad)
    local e = newEnemy("chance", Paths.chanceRun(kind, th, s, pathSpeed(C.ENTRY_SPEED) * 1.15), "gone")
    e.kind = "chance"
    e.mirror = s
    e.delayT = delay or 0
    e.squad = squad
    e.points = C.PTS_CHANCE
    return e
end

-- events.lua spawns satellites/laser ships through this
function Enemies.spawnSpecial(etype, path, after)
    return newEnemy(etype, path, after)
end

-- ---- dying and leaving ----------------------------------------------------

local function removeAt(i)
    local e = G.enemies[i]
    G.releaseSlot(e.slot)
    table.remove(G.enemies, i)
    return e
end

function Enemies.killAt(i)
    local e = removeAt(i)
    local pts = e.points
    if e.type == "drone" and e.kind == "attack" then pts = C.PTS_DIVER end
    G.addScore(pts)
    G.boom(e.x, e.y, 12)
    Harness.count("kills")
    if e.type == "chance" then
        Sfx.blip(500 + (G.chanceCombo or 0) * 90)
        G.chanceCombo = (G.chanceCombo or 0) + 1
        Stage.chanceResolved(e, true)
    elseif e.type == "sat" then
        Events.satKilled(e)
    elseif e.type == "laser" then
        Events.laserKilled(e)
        Sfx.boom(2)
    else
        Sfx.boom(1)
    end
    return e
end

-- shot down the player mid-run: divers glide home without firing
function Enemies.recallAttackers()
    for _, e in ipairs(G.enemies) do
        e.pending = nil
        if e.state == "path" and e.kind == "attack" then
            local sa, sr = 0, 0.5
            if e.slot then sa, sr = G.slotPos(e.slot) end
            e.path = Paths.recall(e.x, e.y, sa, sr, pathSpeed(C.ENTRY_SPEED))
            e.t = 0
            e.kind = "recall"
            e.ammo = 0
        end
    end
end

-- stage stalled out: the formation gives up and flies off one by one
function Enemies.leaveAll()
    local d = 0
    for _, e in ipairs(G.enemies) do
        if e.state == "form" or e.state == "settle" then
            e.pending = "leave"
            e.delayT = d
            d = d + 0.25
        end
    end
end

-- ---- the attack scheduler -------------------------------------------------

local function launchAttack(e, delay)
    e.pending = "attack"
    e.delayT = delay
end

local function pickAttackers()
    local formed = {}
    for _, e in ipairs(G.enemies) do
        if e.type == "drone" and e.state == "form" and not e.pending then
            formed[#formed + 1] = e
        end
    end
    if #formed == 0 then return end
    local leader = formed[math.random(#formed)]
    launchAttack(leader, 0)
    -- wingmates: nearest formation drones chase the leader down the same lane
    local chain = math.min(1 + G.stage // 3, 3)
    local la = Vec.angleOf(leader.x, leader.y)
    table.sort(formed, function(a, b)
        return math.abs(Vec.angleDiff(la, Vec.angleOf(a.x, a.y)))
            < math.abs(Vec.angleDiff(la, Vec.angleOf(b.x, b.y)))
    end)
    local n = 1
    for _, e in ipairs(formed) do
        if n >= chain then break end
        if e ~= leader then
            launchAttack(e, n * 0.32)
            n = n + 1
        end
    end
end

local function updateScheduler(dt)
    if G.chance then return end
    G.attackT = G.attackT - dt
    if G.attackT <= 0 then
        G.attackT = math.max(C.ATTACK_INTERVAL - (G.stage - 1) * C.ATTACK_STAGE, C.ATTACK_MIN)
        pickAttackers()
    end
end

-- ---- per-enemy updates ----------------------------------------------------

local function fireBullet(e, err)
    local px, py = G.unit(G.player.a + (math.random() - 0.5) * (err or 12), 1)
    local dx, dy = Vec.norm(px - e.x, py - e.y)
    local v = C.EBULLET_SPEED + (G.stage - 1) * C.EBULLET_STAGE
    G.bullets[#G.bullets + 1] = { x = e.x, y = e.y, vx = dx * v, vy = dy * v }
    Sfx.blip(240)
end

Enemies.fireBullet = fireBullet -- events.lua reuses it for satellites

local function startPending(e)
    if e.pending == "attack" then
        local sa, sr = 0, 0.4
        if e.slot then sa, sr = G.slotPos(e.slot) end
        e.path = Paths.attack(e.x, e.y, G.player.a,
            math.random() < 0.5 and 1 or -1, sa, sr, pathSpeed(C.ATTACK_SPEED))
        e.t = 0
        e.state = "path"
        e.kind = "attack"
        e.ammo = C.DIVE_AMMO
        e.runs = e.runs + 1
        Harness.count("dives")
    elseif e.pending == "leave" then
        e.path = Paths.leave(e.x, e.y, math.random() < 0.5 and 1 or -1, pathSpeed(C.ATTACK_SPEED))
        e.t = 0
        e.state = "path"
        e.kind = "flee"
        e.after = "gone"
    end
    e.pending = nil
end

local function pathDone(e)
    if e.after == "hold" or e.after == "beam" then
        e.state = e.after
        return false
    end
    if e.after == "form" then
        if e.runs >= C.RUNS_BEFORE_LEAVE then
            e.pending = "leave"
            e.delayT = 0
            startPending(e)
            return false
        end
        e.state = "settle"
        e.settleT = C.SETTLE_TIME
        e.fx, e.fy = e.x, e.y
        return false
    end
    return true -- "gone": remove
end

local function updateOne(e, dt)
    if e.pending then
        e.delayT = e.delayT - dt
        if e.delayT <= 0 then startPending(e) end
    end

    if e.state == "path" then
        if e.delayT > 0 and not e.pending then
            e.delayT = e.delayT - dt
            return false
        end
        e.t = e.t + dt / e.path.dur
        local nx, ny = Paths.eval(e.path.pts, math.min(e.t, 1))
        if nx ~= e.x or ny ~= e.y then
            e.heading = Vec.angleOf(nx - e.x, ny - e.y)
        end
        e.x, e.y = nx, ny
        -- divers and entering drones take aimed potshots mid-flight
        if e.ammo > 0 and G.player.alive and e.t > 0.25 and e.t < 0.8 then
            e.fireT = e.fireT - dt
            if e.fireT <= 0 and math.random() < (0.5 + G.stage * 0.05) * dt * 4 then
                e.fireT = 0.55
                e.ammo = e.ammo - 1
                fireBullet(e)
            end
        end
        if e.t >= 1 then return pathDone(e) end
    elseif e.state == "settle" then
        e.settleT = e.settleT - dt
        local sa, sr = G.slotPos(e.slot)
        local tx, ty = G.unit(sa, sr)
        local k = 1 - math.max(e.settleT, 0) / C.SETTLE_TIME
        e.x = Vec.lerp(e.fx, tx, k)
        e.y = Vec.lerp(e.fy, ty, k)
        e.heading = Vec.angleOf(e.x, e.y)
        if e.settleT <= 0 then e.state = "form" end
    elseif e.state == "form" then
        local sa, sr = G.slotPos(e.slot)
        e.x, e.y = G.unit(sa, sr)
        e.heading = sa
    elseif e.state == "hold" or e.state == "beam" then
        Events.updateSpecial(e, dt) -- satellites and laser ships
    end
    return false
end

function Enemies.update(dt)
    updateScheduler(dt)
    for i = #G.enemies, 1, -1 do
        local e = G.enemies[i]
        if updateOne(e, dt) then
            removeAt(i)
            if e.type == "chance" then Stage.chanceResolved(e, false) end
            if e.type == "sat" then Events.satGone(e) end
            if e.type == "laser" then Events.laserGone(e) end
            Harness.count("left")
        end
    end

    -- enemy bullets fly straight at where the ship was
    for i = #G.bullets, 1, -1 do
        local b = G.bullets[i]
        b.x = b.x + b.vx * dt
        b.y = b.y + b.vy * dt
        local r = Vec.len(b.x, b.y)
        if r > 1.3 then
            table.remove(G.bullets, i)
        elseif r > 0.85 and G.player.alive and G.player.invulnT <= 0 then
            local bx, by = G.px(b.x, b.y)
            local px, py = G.polarPx(G.player.a, 1)
            local d = C.HIT_BULLET + C.HIT_PLAYER * 0.5
            if (bx - px) ^ 2 + (by - py) ^ 2 < d * d then
                table.remove(G.bullets, i)
                Player.kill() -- resets G.bullets: stop iterating the old list
                break
            end
        end
    end
end

-- ---- collisions -----------------------------------------------------------

function Enemies.collide()
    -- player shots vs everything hittable
    for si = #G.shots, 1, -1 do
        local s = G.shots[si]
        local sx, sy = G.polarPx(s.a, s.r)
        for ei = #G.enemies, 1, -1 do
            local e = G.enemies[ei]
            if e.delayT <= 0 or e.state ~= "path" then
                local ex, ey = G.px(e.x, e.y)
                local hr = e.hitR * G.scaleAt(Vec.len(e.x, e.y)) + 2.5
                if (sx - ex) ^ 2 + (sy - ey) ^ 2 < hr * hr then
                    table.remove(G.shots, si)
                    Enemies.killAt(ei)
                    break
                end
            end
        end
    end

    -- rammed at the rim: both ships go up (chance stages are harmless)
    local p = G.player
    if p.alive and p.invulnT <= 0 and not G.chance then
        local px, py = G.polarPx(p.a, 1)
        for ei = #G.enemies, 1, -1 do
            local e = G.enemies[ei]
            if Vec.len(e.x, e.y) > 0.86 then
                local ex, ey = G.px(e.x, e.y)
                local hr = e.hitR * G.scaleAt(Vec.len(e.x, e.y)) * 0.8 + C.HIT_PLAYER
                if (px - ex) ^ 2 + (py - ey) ^ 2 < hr * hr then
                    Enemies.killAt(ei)
                    Player.kill()
                    break
                end
            end
        end
    end
end
