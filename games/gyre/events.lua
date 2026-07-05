-- Mid-stage events: the satellite trio (destroy all three for twin
-- cannons), indestructible meteors tumbling out of the deep, and the
-- laser pair — two linked ships straddling the rim whose beam sweeps
-- around the tube after the player.

Events = {}

local clamp = Util.clamp

function Events.reset()
    G.meteors = {}
    G.beam = nil
    G.satKills = 0
    G.satsAlive = 0
end

-- ---- satellites -----------------------------------------------------------

function Events.spawnSatellites()
    local base = (G.player.a + 180) % 360
    G.satKills = 0
    G.satsAlive = 3
    for i = 1, 3 do
        local off = (i - 2) * 16
        local p = {}
        local rad = math.rad(base + off)
        p[1], p[2] = math.cos(rad) * 0.04, math.sin(rad) * 0.04
        local mid = math.rad(base + off - 30)
        p[3], p[4] = math.cos(mid) * 0.5, math.sin(mid) * 0.5
        p[5], p[6] = math.cos(rad) * C.SAT_R, math.sin(rad) * C.SAT_R
        local e = Enemies.spawnSpecial("sat", Paths.make(p, 0.6), "hold")
        e.delayT = (i - 1) * 0.3
        e.holdA = base + off
        e.holdT = C.SAT_HOLD + (i - 1) * 0.3
        e.drift = 14
        e.hitR = C.HIT_SAT
        e.points = 0 -- scored as a chain in satKilled
        e.fireT = 1.2 + i * 0.5
    end
    G.pop("SATELLITES", 1.2)
    Sfx.warble()
    Harness.count("satWaves")
end

local function updateSat(e, dt)
    e.holdT = e.holdT - dt
    -- drift around the rim, chasing the player's side of the tube
    local d = Vec.angleDiff(e.holdA, G.player.a)
    e.holdA = e.holdA + clamp(d, -1, 1) * e.drift * dt
    local r = C.SAT_R * (1 + 0.04 * math.sin(G.time * 3))
    e.x, e.y = G.unit(e.holdA, r)
    e.heading = e.holdA + 90
    if G.player.alive then
        e.fireT = e.fireT - dt
        if e.fireT <= 0 then
            e.fireT = 1.6 + math.random()
            Enemies.fireBullet(e, 8)
        end
    end
    if e.holdT <= 0 then
        -- dives back into the hub and is gone
        e.pending = "leave"
        e.delayT = 0
    end
end

function Events.satKilled(e)
    G.satKills = G.satKills + 1
    G.satsAlive = G.satsAlive - 1
    local pts = C.PTS_SAT[clamp(G.satKills, 1, #C.PTS_SAT)]
    G.addScore(pts)
    G.pop("+" .. pts, 0.9)
    Sfx.boom(2)
    Harness.count("satKills")
    if G.satKills >= 3 then
        G.player.twin = true
        G.pop("TWIN CANNONS", 1.8)
        Sfx.fanfare({ 523, 659, 784, 1047 }, 0.08)
        Harness.count("twins")
    end
end

function Events.satGone(e)
    G.satsAlive = math.max(G.satsAlive - 1, 0)
end

-- ---- meteors ---------------------------------------------------------------

function Events.spawnMeteor()
    G.meteors[#G.meteors + 1] = {
        a = math.random() * 360,
        va = (math.random() - 0.5) * 16,
        r = 0.03,
        spin = math.random() * 360,
        spinV = (math.random() < 0.5 and -1 or 1) * (60 + math.random(120)),
        shape = Shapes.blob(C.HIT_METEOR, 9),
    }
    Harness.count("meteors")
end

local function updateMeteors(dt)
    local p = G.player
    for i = #G.meteors, 1, -1 do
        local m = G.meteors[i]
        m.r = m.r + C.METEOR_SPEED * (1 + G.stage * 0.03) * dt
        m.a = m.a + m.va * dt
        m.spin = m.spin + m.spinV * dt
        if m.r > 1.3 then
            table.remove(G.meteors, i)
            Harness.count("meteorsPassed")
        elseif m.r > 0.82 and m.r < 1.12 and p.alive and p.invulnT <= 0 and not G.chance then
            local mx, my = G.polarPx(m.a, m.r)
            local px, py = G.polarPx(p.a, 1)
            local hr = C.HIT_METEOR * G.scaleAt(m.r) + C.HIT_PLAYER * 0.7
            if (mx - px) ^ 2 + (my - py) ^ 2 < hr * hr then
                Player.kill()
            end
        end
    end
end

-- ---- the laser pair ---------------------------------------------------------

function Events.spawnLaser()
    local base = (G.player.a + 180) % 360
    local pair = {}
    for i = 1, 2 do
        local rr = (i == 1) and 1.05 or 0.76
        local p = {}
        p[1], p[2] = 0.03, 0
        local mid = math.rad(base + (i == 1 and 35 or -35))
        p[3], p[4] = math.cos(mid) * rr * 0.55, math.sin(mid) * rr * 0.55
        local rad = math.rad(base)
        p[5], p[6] = math.cos(rad) * rr, math.sin(rad) * rr
        local e = Enemies.spawnSpecial("laser", Paths.make(p, 0.65), "beam")
        e.beamR = rr
        e.hitR = C.HIT_LASER
        e.points = C.PTS_LASER
        pair[i] = e
    end
    pair[1].partner, pair[2].partner = pair[2], pair[1]
    pair[1].lead = true
    G.beam = { a = base, t = 0, active = false }
    G.pop("LASER PAIR", 1.2)
    Sfx.warble()
    Harness.count("lasers")
end

local function updateLaser(e, dt)
    local b = G.beam
    if not b then
        e.pending = e.pending or "leave"
        e.delayT = 0
        return
    end
    if e.lead then
        b.t = b.t + dt
        if not b.active and b.t >= C.LASER_WARMUP then
            b.active = true
            Sfx.zapSweep()
        end
        if b.active then
            -- the beam hunts the player around the tube
            local d = Vec.angleDiff(b.a, G.player.a)
            local rate = C.LASER_SWEEP + G.stage * 2
            b.a = (b.a + clamp(d, -1, 1) * math.min(rate, math.abs(d) / C.DT) * dt) % 360
        end
        if b.t > C.LASER_WARMUP + C.LASER_TIME then
            G.beam = nil
        end
    end
    e.x, e.y = G.unit(b.a, e.beamR)
    e.heading = b.a
end

function Events.laserKilled(e)
    G.beam = nil
    Harness.count("laserKills")
end

function Events.laserGone(e)
    if e.lead then G.beam = nil end
end

-- called from Enemies.updateOne for "hold"/"beam" states
function Events.updateSpecial(e, dt)
    if e.type == "sat" then
        updateSat(e, dt)
    elseif e.type == "laser" then
        updateLaser(e, dt)
    end
end

function Events.update(dt)
    updateMeteors(dt)
    -- the beam itself: radial, so it kills anyone parked on its angle
    local b = G.beam
    local p = G.player
    if b and b.active and p.alive and p.invulnT <= 0 then
        if math.abs(Vec.angleDiff(b.a, p.a)) < 3.5 then
            Player.kill()
        end
    end
end
