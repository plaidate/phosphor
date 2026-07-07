-- The web's invaders. Everything enters at the rim: chasers crawl in
-- along a spoke then hunt the spider; layers wander intersection to
-- intersection leaving pulsing eggs that hatch into chasers; bombers
-- drift across and burst into four radial fragments on death or timer.

Enemies = {}

local function radiusOf(e)
    return math.sqrt(G.dist2(e.x, e.y, C.CX, C.CY))
end

-- --------------------------------------------------------------- spawning

function Enemies.addChaser(x, y, phase, spoke)
    G.chasers[#G.chasers + 1] = {
        x = x, y = y,
        phase = phase, -- "enter" (crawl inward on spoke) | "hunt"
        spoke = spoke or 0,
        angle = math.random(0, 359),
        spin = math.random(-160, 160),
    }
end

local function spawnChaser()
    local s = math.random(0, C.SPOKES - 1)
    local dx, dy = Vec.fromAngle(Web.spokeAngle(s), C.R_OUT)
    Enemies.addChaser(C.CX + dx, C.CY + dy, "enter", s)
end

local function spawnLayer()
    local s = math.random(0, C.SPOKES - 1)
    local dx, dy = Vec.fromAngle(Web.spokeAngle(s), C.R_OUT)
    G.layers[#G.layers + 1] = {
        x = C.CX + dx, y = C.CY + dy,
        ring = #C.RINGS, spoke = s, -- crawling in to this node first
        layT = C.LAY_COOLDOWN * (0.5 + math.random() * 0.5),
        angle = Web.spokeAngle(s) + 180,
    }
end

local function spawnBomber()
    -- enters anywhere on the rim, drifts across past the hub
    local a = math.random() * 360
    local dx, dy = Vec.fromAngle(a, 1)
    local x, y = C.CX + dx * C.R_OUT, C.CY + dy * C.R_OUT
    local tx = C.CX + math.random(-36, 36)
    local ty = C.CY + math.random(-36, 36)
    local vx, vy = Vec.norm(tx - x, ty - y)
    local v = C.BOMBER_SPEED * G.speedScale
    G.bombers[#G.bombers + 1] = {
        x = x, y = y,
        vx = vx * v, vy = vy * v,
        fuse = C.BOMBER_FUSE,
        angle = 0, spin = math.random(40, 90) * (math.random() < 0.5 and -1 or 1),
    }
end

local SPAWNERS <const> = {
    chaser = spawnChaser,
    layer = spawnLayer,
    bomber = spawnBomber,
}

function Enemies.nextWave()
    G.wave = G.wave + 1
    G.bannerT = 2.0
    G.speedScale = math.min(1 + (G.wave - 1) * 0.07, 1.8)
    local q = {}
    for _ = 1, math.min(2 + G.wave, 9) do q[#q + 1] = "chaser" end
    for _ = 1, math.min(1 + math.floor(G.wave / 2), 4) do q[#q + 1] = "layer" end
    for _ = 1, math.min(math.floor(G.wave / 2), 4) do q[#q + 1] = "bomber" end
    -- shuffle so each wave's rim arrivals mix
    for i = #q, 2, -1 do
        local j = math.random(i)
        q[i], q[j] = q[j], q[i]
    end
    G.spawnQ = q
    G.spawnT = 1.2
    Harness.count("waves")
    Sfx.zapSweep()
end

local function updateSpawning()
    if #G.spawnQ == 0 then return end
    G.spawnT = G.spawnT - C.DT
    if G.spawnT <= 0 then
        G.spawnT = math.max(0.4, C.SPAWN_GAP - (G.wave - 1) * 0.07)
        local kind = table.remove(G.spawnQ, 1)
        SPAWNERS[kind]()
        Sfx.blip(440)
    end
end

function Enemies.cleared()
    return #G.spawnQ == 0 and #G.chasers == 0 and #G.layers == 0
        and #G.bombers == 0 and #G.eggs == 0
end

-- ---------------------------------------------------------------- chasers

local function updateChasers()
    local p = G.player
    local v = C.CHASER_SPEED * G.speedScale * C.DT
    for _, e in ipairs(G.chasers) do
        e.angle = e.angle + e.spin * C.DT
        if e.phase == "enter" then
            -- crawl inward along the spawn spoke
            local dx, dy = Vec.norm(C.CX - e.x, C.CY - e.y)
            e.x = e.x + dx * v
            e.y = e.y + dy * v
            if radiusOf(e) <= C.RINGS[3] then e.phase = "hunt" end
        elseif p and p.alive then
            local dx, dy = Vec.norm(p.x - e.x, p.y - e.y)
            e.x = e.x + dx * v
            e.y = e.y + dy * v
        else
            -- spider down: back off toward the rim, clear the hub
            local dx, dy, r = Vec.norm(e.x - C.CX, e.y - C.CY)
            if r < C.R_OUT - 12 then
                e.x = e.x + dx * v * 0.6
                e.y = e.y + dy * v * 0.6
            end
        end
    end
end

-- ----------------------------------------------------------------- layers

local function tryLayEgg(l)
    if l.layT > 0 or #G.eggs >= C.MAX_EGGS then return end
    local node = Web.node(l.ring, l.spoke)
    for _, e in ipairs(G.eggs) do
        if G.dist2(e.x, e.y, node.x, node.y) < 16 then return end
    end
    G.eggs[#G.eggs + 1] = { x = node.x, y = node.y, t = 0 }
    l.layT = C.LAY_COOLDOWN
    Harness.count("eggs")
    Sfx.blip(880)
end

local function updateLayers()
    local v = C.LAYER_SPEED * G.speedScale * C.DT
    for _, l in ipairs(G.layers) do
        if l.layT > 0 then l.layT = l.layT - C.DT end
        local node = Web.node(l.ring, l.spoke)
        local dx, dy, d = Vec.norm(node.x - l.x, node.y - l.y)
        if d <= v + 0.5 then
            l.x, l.y = node.x, node.y
            tryLayEgg(l)
            l.ring, l.spoke = Web.neighbor(l.ring, l.spoke)
        else
            l.x = l.x + dx * v
            l.y = l.y + dy * v
            l.angle = Vec.angleOf(dx, dy)
        end
    end
end

-- ------------------------------------------------------------------- eggs

local function updateEggs()
    for i = #G.eggs, 1, -1 do
        local e = G.eggs[i]
        e.t = e.t + C.DT
        if e.t >= C.EGG_HATCH then
            table.remove(G.eggs, i)
            Enemies.addChaser(e.x, e.y, "hunt")
            Fx.burst(e.x, e.y, 4)
            Harness.count("hatched")
            Sfx.warble()
        end
    end
end

-- ---------------------------------------------------------------- bombers

local function explodeBomber(b)
    local base = math.random() * 90
    for k = 0, 3 do
        local dx, dy = Vec.fromAngle(base + k * 90, 1)
        G.frags[#G.frags + 1] = {
            x = b.x, y = b.y,
            vx = dx * C.FRAG_SPEED, vy = dy * C.FRAG_SPEED,
        }
    end
    Fx.burst(b.x, b.y, 8)
    Fx.debris(b.x, b.y, 3)
    Sfx.boom(2)
end

local function updateBombers()
    for i = #G.bombers, 1, -1 do
        local b = G.bombers[i]
        b.fuse = b.fuse - C.DT
        b.x = b.x + b.vx * C.DT
        b.y = b.y + b.vy * C.DT
        b.angle = b.angle + b.spin * C.DT
        if b.fuse <= 0 or radiusOf(b) > C.R_OUT + 10 then
            table.remove(G.bombers, i)
            explodeBomber(b)
        end
    end
end

local function updateFrags()
    for i = #G.frags, 1, -1 do
        local f = G.frags[i]
        f.x = f.x + f.vx * C.DT
        f.y = f.y + f.vy * C.DT
        if G.dist2(f.x, f.y, C.CX, C.CY) > (C.R_OUT + 6) * (C.R_OUT + 6) then
            table.remove(G.frags, i)
        end
    end
end

function Enemies.update()
    updateSpawning()
    updateChasers()
    updateLayers()
    updateEggs()
    updateBombers()
    updateFrags()
end

-- -------------------------------------------------------------- collisions

local function shotKill(b, list, i, r, pts)
    local e = list[i]
    if G.dist2(b.x, b.y, e.x, e.y) >= (r + 2) * (r + 2) then return false end
    table.remove(list, i)
    G.addScore(pts)
    Fx.burst(e.x, e.y, 6)
    Harness.count("kills")
    Sfx.boom(1)
    return true
end

function Enemies.collide()
    -- spider shots vs everything that can be shot
    for si = #G.shots, 1, -1 do
        local b = G.shots[si]
        local hit = false
        for i = #G.chasers, 1, -1 do
            if shotKill(b, G.chasers, i, C.CHASER_R, C.PTS_CHASER) then hit = true break end
        end
        if not hit then
            for i = #G.layers, 1, -1 do
                if shotKill(b, G.layers, i, C.LAYER_R, C.PTS_LAYER) then hit = true break end
            end
        end
        if not hit then
            for i = #G.bombers, 1, -1 do
                local bomber = G.bombers[i]
                if shotKill(b, G.bombers, i, C.BOMBER_R, C.PTS_BOMBER) then
                    explodeBomber(bomber)
                    hit = true
                    break
                end
            end
        end
        if not hit then
            for i = #G.eggs, 1, -1 do
                if shotKill(b, G.eggs, i, C.EGG_R, C.PTS_EGG) then hit = true break end
            end
        end
        if hit then table.remove(G.shots, si) end
    end

    -- anything touching the spider kills it
    local p = G.player
    if not (p and p.alive) or p.invuln > 0 then return end
    local function touches(list, r)
        local rr = (r + C.PLAYER_R) * (r + C.PLAYER_R)
        for _, e in ipairs(list) do
            if G.dist2(p.x, p.y, e.x, e.y) < rr then return true end
        end
        return false
    end
    if touches(G.chasers, C.CHASER_R)
        or touches(G.layers, C.LAYER_R)
        or touches(G.bombers, C.BOMBER_R)
        or touches(G.frags, C.FRAG_R) then
        Player.kill()
    end
end
