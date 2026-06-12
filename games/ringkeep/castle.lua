-- The keep: three rotating shield rings, the tracking core, its homing
-- fireball, and the two mines that ride the rings then peel off to hunt.

Castle = {}

local clamp = Util.clamp

local SEG_ARC <const> = 360 / C.RING_SEGS

-- ------------------------------------------------------------------- helpers

local function distFromCore(x, y)
    return Vec.len(x - C.CX, y - C.CY)
end

-- which segment of `ring` covers world angle `angleDeg`, and is it alive?
local function segAt(ring, angleDeg)
    local a = (angleDeg - ring.rot) % 360
    local idx = math.floor(a / SEG_ARC) + 1
    if idx > C.RING_SEGS then idx = C.RING_SEGS end
    return ring.segs[idx], idx
end

-- ---------------------------------------------------------------- ring setup

local function newMine()
    return {
        state = "orbit", -- "orbit" | "chase" | "dead"
        ang = math.random() * 360,
        x = 0, y = 0,
        spin = math.random(90, 220),
        drawAng = 0,
        peelT = C.MINE_PEEL_MIN + math.random() * C.MINE_PEEL_VAR,
        respawnT = 0,
    }
end

-- full reset (new game / new wave): rings whole, mines back on patrol
function Castle.reset()
    G.rings = {}
    for i, r in ipairs(C.RING_RADII) do
        local segs = {}
        for j = 1, C.RING_SEGS do segs[j] = true end
        G.rings[i] = {
            r = r,
            rot = math.random() * 360,
            speed = C.RING_SPEEDS[i],
            segs = segs,
            alive = C.RING_SEGS,
        }
    end
    G.fireball = nil
    G.fbCool = C.FB_COOLDOWN
    G.mines = {}
    for _ = 1, C.MINE_COUNT do
        G.mines[#G.mines + 1] = newMine()
    end
end

-- ------------------------------------------------------------------ updating

-- rotation only: also drives the title-screen backdrop
function Castle.spinRings(dt)
    for _, ring in ipairs(G.rings) do
        ring.rot = (ring.rot + ring.speed * G.speedMul * dt) % 360
    end
end

-- the core sees the player only through gaps in every ring outside them
local function lineOfSight(s)
    local d = distFromCore(s.x, s.y)
    local ang = Vec.angleOf(s.x - C.CX, s.y - C.CY)
    for _, ring in ipairs(G.rings) do
        if ring.alive > 0 and ring.r < d then
            if segAt(ring, ang) then return false end
        end
    end
    return true
end

local function launchFireball(s)
    local a = Vec.angleOf(s.x - C.CX, s.y - C.CY)
    local speed = math.min(C.FB_SPEED * G.speedMul, C.FB_SPEED_MAX)
    G.fireball = {
        x = C.CX, y = C.CY,
        ang = a, speed = speed,
        life = C.FB_LIFE,
        spin = 0,
    }
    Sfx.descend()
end

local function fireballGone()
    G.fireball = nil
    G.fbCool = C.FB_COOLDOWN
end

local function updateFireball(dt)
    local f = G.fireball
    if not f then
        if G.fbCool > 0 then G.fbCool = G.fbCool - dt end
        local s = G.ship
        if s and s.alive and G.fbCool <= 0 and lineOfSight(s) then
            launchFireball(s)
        end
        return
    end

    f.life = f.life - dt
    if f.life <= 0 then
        G.burst(f.x, f.y, 6)
        Sfx.boom(1)
        fireballGone()
        return
    end

    -- home on the player, but only so fast: a straight run outruns it
    local s = G.ship
    if s and s.alive then
        local dx, dy = G.wrapDelta(f.x, f.y, s.x, s.y)
        local want = Vec.angleOf(dx, dy)
        local turn = clamp(Vec.angleDiff(f.ang, want), -C.FB_TURN * dt, C.FB_TURN * dt)
        f.ang = f.ang + turn
    end
    local rad = math.rad(f.ang)
    f.x, f.y = Util.wrap(f.x + math.cos(rad) * f.speed * dt, f.y + math.sin(rad) * f.speed * dt)
    f.spin = f.spin + 320 * dt
    if Attract.frame % 6 == 0 then Sfx.sirenTick(520) end
end

local function updateMines(dt)
    local outerR = C.RING_RADII[1]
    for _, m in ipairs(G.mines) do
        if m.state == "dead" then
            m.respawnT = m.respawnT - dt
            if m.respawnT <= 0 then
                local fresh = newMine()
                for k, v in pairs(fresh) do m[k] = v end
            end
        elseif m.state == "orbit" then
            m.ang = (m.ang + C.MINE_ORBIT * G.speedMul * dt) % 360
            local rad = math.rad(m.ang)
            m.x = C.CX + math.cos(rad) * outerR
            m.y = C.CY + math.sin(rad) * outerR
            if G.ship and G.ship.alive then
                m.peelT = m.peelT - dt
                if m.peelT <= 0 then m.state = "chase" end
            end
        else -- chase
            local s = G.ship
            if s and s.alive then
                local dx, dy = G.wrapDelta(m.x, m.y, s.x, s.y)
                local nx, ny = Vec.norm(dx, dy)
                local speed = math.min(C.MINE_CHASE * G.speedMul, C.MINE_CHASE_MAX)
                m.x, m.y = Util.wrap(m.x + nx * speed * dt, m.y + ny * speed * dt)
            end
        end
        m.drawAng = m.drawAng + m.spin * dt
    end
end

function Castle.update(dt)
    Castle.spinRings(dt)
    local s = G.ship
    if s and s.alive then
        G.coreAim = Vec.angleOf(s.x - C.CX, s.y - C.CY)
    end
    updateFireball(dt)
    updateMines(dt)
end

-- mines stand down when the player dies; the fireball loses its quarry too
function Castle.onShipDeath()
    for _, m in ipairs(G.mines) do
        if m.state == "chase" then
            m.state = "orbit"
            m.ang = Vec.angleOf(m.x - C.CX, m.y - C.CY)
            m.peelT = C.MINE_PEEL_MIN + math.random() * C.MINE_PEEL_VAR
        end
    end
    if G.fireball then fireballGone() end
end

-- --------------------------------------------------------------- destruction

local function killSegment(ring, idx, ang)
    ring.segs[idx] = false
    ring.alive = ring.alive - 1
    local rad = math.rad(ang)
    G.burst(C.CX + math.cos(rad) * ring.r, C.CY + math.sin(rad) * ring.r, 6)
    Sfx.boom(1)
    G.addScore(C.PTS_SEGMENT)
    Harness.count("segments")
end

local function killMine(m)
    G.burst(m.x, m.y, 8)
    G.addDebris(m.x, m.y, 3)
    Sfx.boom(2)
    G.addScore(C.PTS_MINE)
    Harness.count("mines")
    m.state = "dead"
    m.respawnT = C.MINE_RESPAWN
end

local function killCore()
    G.addScore(C.PTS_CORE)
    G.burst(C.CX, C.CY, 24, 110)
    G.addDebris(C.CX, C.CY, 10)
    Fx.flash(0.25)
    Sfx.bigBoom()
    Sfx.fanfare()
    Harness.count("cores")

    -- an extra life for every keep brought down
    if G.lives < C.MAX_LIVES then G.lives = G.lives + 1 end

    -- next wave: rings regenerate, everything quickens
    G.wave = G.wave + 1
    G.speedMul = math.min(G.speedMul * C.WAVE_SPEEDUP, C.MAX_SPEED_MUL)
    Castle.reset()
    Harness.count("waves")

    -- a breath to escape the regenerated rings if we were close in
    if G.ship and G.ship.alive then
        G.ship.invuln = math.max(G.ship.invuln, 2.0)
    end
end

-- ---------------------------------------------------------------- collisions

function Castle.collide()
    -- player shots vs mines, shield rings (outermost band crossed first,
    -- since a shot covers at most one ring spacing per frame), and the core
    for si = #G.shots, 1, -1 do
        local b = G.shots[si]
        local hit = false

        for _, m in ipairs(G.mines) do
            if m.state ~= "dead"
                and Field.dist2(b.x, b.y, m.x, m.y) < (C.MINE_R + 2) * (C.MINE_R + 2) then
                killMine(m)
                hit = true
                break
            end
        end

        local nd = distFromCore(b.x, b.y)
        if not hit then
            for _, ring in ipairs(G.rings) do
                if ring.alive > 0 then
                    local crossed = (b.pd - ring.r) * (nd - ring.r) <= 0
                        or math.abs(nd - ring.r) <= C.RING_BAND
                    if crossed then
                        local ang = Vec.angleOf(b.x - C.CX, b.y - C.CY)
                        local alive, idx = segAt(ring, ang)
                        if alive then
                            killSegment(ring, idx, ang)
                            hit = true
                            break
                        end
                    end
                end
            end
        end

        if not hit and nd < C.CORE_R + 2 then
            killCore()
            hit = true
        end

        b.pd = nd
        if hit then table.remove(G.shots, si) end
    end

    -- everything vs the ship
    local s = G.ship
    if not (s and s.alive) or s.invuln > 0 then return end

    local sd = distFromCore(s.x, s.y)
    local sAng = Vec.angleOf(s.x - C.CX, s.y - C.CY)
    for _, ring in ipairs(G.rings) do
        if ring.alive > 0
            and math.abs(sd - ring.r) < C.SHIP_R + C.RING_BAND
            and segAt(ring, sAng) then
            Ship.kill()
            return
        end
    end
    if sd < C.CORE_R + C.SHIP_R then
        Ship.kill()
        return
    end

    local f = G.fireball
    if f and Field.dist2(s.x, s.y, f.x, f.y) < (C.FB_R + C.SHIP_R) * (C.FB_R + C.SHIP_R) then
        G.burst(f.x, f.y, 6)
        fireballGone()
        Ship.kill()
        return
    end

    for _, m in ipairs(G.mines) do
        if m.state ~= "dead"
            and Field.dist2(s.x, s.y, m.x, m.y) < (C.MINE_R + C.SHIP_R) * (C.MINE_R + C.SHIP_R) then
            G.burst(m.x, m.y, 6)
            m.state = "dead"
            m.respawnT = C.MINE_RESPAWN
            Ship.kill()
            return
        end
    end
end
