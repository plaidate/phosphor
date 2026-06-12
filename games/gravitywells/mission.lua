-- Gravity Wells, scale B: a side-view planet mission. Jagged terrain across
-- a world two screens wide, downward (or reversed) gravity, surface fuel
-- tanks lifted by a tractor beam (hold DOWN), bunkers firing aimed shots,
-- and a reactor at the bottom of a deep chamber: shoot it and get out
-- within 8 seconds. Exit upward to return to the system view; the planet is
-- marked cleared if every bunker is dead or the reactor blew behind you.

Mission = {}

local clamp = Util.clamp

local function shuffle(t)
    for i = #t, 2, -1 do
        local j = math.random(i)
        t[i], t[j] = t[j], t[i]
    end
end

-- ground height (world y) under x, linearly interpolated
function Mission.heightAt(m, x)
    local pts = m.pts
    if x <= pts[1] then return pts[2] end
    for i = 3, #pts - 1, 2 do
        if x <= pts[i] then
            local x0, y0 = pts[i - 2], pts[i - 1]
            local t = (x - x0) / math.max(pts[i] - x0, 1e-6)
            return y0 + (pts[i + 1] - y0) * t
        end
    end
    return pts[#pts]
end

function Mission.generate(p)
    local W = C.WORLD_W
    local m = {
        revGrav = p.revGrav or false,
        kind = p.kind,
        bunkers = {}, tanks = {}, eshots = {},
        t = 0, beamOn = false,
        reactorT = nil, defDown = false, escaped = false,
    }

    -- the deep chamber sits toward one end; you enter near the other
    local cx = (math.random(2) == 1) and math.random(140, 260)
        or math.random(W - 260, W - 140)
    m.entryX = (cx < W / 2) and (W - 170) or 170

    -- random-walk skyline, with the chamber shaft spliced in
    local pts, sites = {}, {}
    local x, y = 0, math.random(150, 200)
    pts[1], pts[2] = 0, y
    local placed = false
    while x < W do
        if not placed and x + 34 >= cx - 66 then
            local resume = math.random(150, 200)
            local seg = {
                cx - 66, y,    cx - 40, 104,  cx - 24, 104,
                cx - 17, 224,  cx + 17, 224,  cx + 24, 104,
                cx + 40, 104,  cx + 66, resume,
            }
            for i = 1, #seg do pts[#pts + 1] = seg[i] end
            x, y = cx + 66, resume
            placed = true
        else
            x = math.min(x + math.random(16, 34), W)
            y = clamp(y + math.random(-26, 26), 122, 214)
            pts[#pts + 1] = x
            pts[#pts + 1] = y
            if x > 40 and x < W - 40 then
                sites[#sites + 1] = { x = x, y = y }
            end
        end
    end
    m.pts = pts
    m.reactor = { x = cx, y = 216, hit = false }

    -- scatter bunkers and tanks on terrain vertices, spaced apart
    shuffle(sites)
    local chosen = {}
    local function take()
        for i, sv in ipairs(sites) do
            local ok = math.abs(sv.x - m.entryX) > 40
            if ok then
                for _, c in ipairs(chosen) do
                    if math.abs(c.x - sv.x) < 56 then ok = false break end
                end
            end
            if ok then
                table.remove(sites, i)
                chosen[#chosen + 1] = sv
                return sv
            end
        end
        local sv = table.remove(sites)
        if sv then chosen[#chosen + 1] = sv end
        return sv
    end
    for _ = 1, C.BUNKERS do
        local sv = take()
        if sv then
            m.bunkers[#m.bunkers + 1] = {
                x = sv.x, y = sv.y, alive = true,
                cd = 1 + math.random() * 2,
            }
        end
    end
    for _ = 1, C.TANKS do
        local sv = take()
        if sv then
            m.tanks[#m.tanks + 1] = { x = sv.x, y = sv.y, alive = true }
        end
    end
    return m
end

function Mission.gravity(m)
    local g = C.PLANET_G + (G.system - 1) * C.PLANET_G_PER_SYS
    return m.revGrav and -g or g
end

function Mission.enter(p)
    G.curPlanet = p
    if not p.mission then p.mission = Mission.generate(p) end
    local m = p.mission
    G.m = m
    m.t = 0
    m.eshots = {}
    m.beamOn = false
    G.view = "mission"
    local s = G.ship
    s.x, s.y = m.entryX, 16
    s.vx, s.vy = 0, m.revGrav and 50 or 26
    s.angle = 90
    s.invuln = 1.2
    G.camX = clamp(s.x - Field.W / 2, 0, C.WORLD_W - Field.W)
    Sfx.warble()
    G.message(m.revGrav and "REVERSED GRAVITY!" or ("DESCENT - WELL " .. p.kind), 1.8)
end

-- death cleanup: drop back to system view without credit
function Mission.abandon()
    local m = G.m
    if m then
        m.eshots = {}
        m.reactorT = nil
        m.reactor.hit = false
        m.beamOn = false
    end
    G.view = "system"
    G.shots = {}
end

function Mission.exit()
    local m, p, s = G.m, G.curPlanet, G.ship
    local bonus = 0
    if m.reactorT then -- out in time: the reactor blows behind you
        local rb = C.PTS_REACTOR_ESCAPE + (G.system - 1) * C.PTS_REACTOR_ESCAPE_PER_SYS
        bonus = bonus + rb
        m.reactorT = nil
        m.escaped = true
        G.message("REACTOR DESTROYED +" .. rb, 2.4)
        Sfx.fanfare()
    end
    local allDead = true
    for _, b in ipairs(m.bunkers) do
        if b.alive then allDead = false break end
    end
    if (m.escaped or allDead) and not p.cleared then
        p.cleared = true
        bonus = bonus + C.PTS_CLEAR
        Harness.count("planets")
        if not m.escaped then
            G.message("WELL CLEARED +" .. C.PTS_CLEAR, 2.2)
            Sfx.fanfare()
        end
    end
    if bonus > 0 then G.addScore(bonus) end

    m.eshots = {}
    m.beamOn = false
    G.view = "system"
    G.shots = {}
    -- reappear just outside the planet, drifting away from the star
    local nx, ny = Vec.norm(p.x - C.STAR_X, p.y - C.STAR_Y)
    s.x = p.x + nx * (p.r + 12)
    s.y = p.y + ny * (p.r + 12)
    s.vx, s.vy = nx * 55, ny * 55
    s.invuln = 1.5

    if System.allCleared() then
        System.nextSystem()
    end
end

local function collectTanks(m, s)
    for _, t in ipairs(m.tanks) do
        if t.alive and math.abs(t.x - s.x) < C.BEAM_HALF_W + 3
            and t.y > s.y and t.y - s.y <= C.BEAM_LEN + 8 then
            t.alive = false
            G.fuel = math.min(C.FUEL_MAX, G.fuel + C.TANK_FUEL)
            G.fuelOut = false
            G.addScore(C.PTS_TANK)
            Harness.count("tanks")
            G.fxBurst(t.x, t.y - 4, 6)
            Sfx.blip(880)
        end
    end
end

function Mission.update(dt)
    local m, s = G.m, G.ship
    m.t = m.t + dt
    local g = Mission.gravity(m)

    if s.alive then
        local turn, thrust, fire, beam = Input.gather()
        Ship.control(turn, thrust, fire, dt)
        s.vy = s.vy + g * dt
        Ship.integrate(dt, C.MIS_MAX_SPEED)

        if s.x < 6 then s.x = 6 if s.vx < 0 then s.vx = 0 end end
        if s.x > C.WORLD_W - 6 then s.x = C.WORLD_W - 6 if s.vx > 0 then s.vx = 0 end end

        -- out the top: back to the system view
        if s.y < 2 and m.t > 1.0 then
            Mission.exit()
            return
        end

        -- terrain and structures are hard
        if s.y + 4 >= Mission.heightAt(m, s.x) then
            Ship.kill(true)
        end
        if s.alive then
            for _, b in ipairs(m.bunkers) do
                if b.alive then
                    local dx, dy = s.x - b.x, s.y - (b.y - 5)
                    if dx * dx + dy * dy < 121 then Ship.kill(true) break end
                end
            end
        end

        m.beamOn = s.alive and beam or false
        if m.beamOn then collectTanks(m, s) end
    else
        m.beamOn = false
    end

    G.camX = clamp(s.x - Field.W / 2, 0, C.WORLD_W - Field.W)

    -- bunkers take aimed shots at the ship
    for _, b in ipairs(m.bunkers) do
        if b.alive and s.alive then
            b.cd = b.cd - dt
            local dx, dy = s.x - b.x, s.y - (b.y - 6)
            if b.cd <= 0 and dx * dx + dy * dy < C.BUNKER_RANGE * C.BUNKER_RANGE
                and #m.eshots < C.MAX_ESHOTS then
                b.cd = C.BUNKER_CD_MIN + math.random() * (C.BUNKER_CD_MAX - C.BUNKER_CD_MIN)
                local a = math.atan(dy, dx) + (math.random() - 0.5) * 0.2
                m.eshots[#m.eshots + 1] = {
                    x = b.x, y = b.y - 8,
                    vx = math.cos(a) * C.BUNKER_SHOT_SPEED,
                    vy = math.sin(a) * C.BUNKER_SHOT_SPEED,
                    t = 3.5,
                }
                Sfx.pew(330)
            end
        end
    end

    -- enemy shots
    for i = #m.eshots, 1, -1 do
        local e = m.eshots[i]
        e.t = e.t - dt
        e.x = e.x + e.vx * dt
        e.y = e.y + e.vy * dt
        local dead = e.t <= 0 or e.x < 0 or e.x > C.WORLD_W or e.y < 0
            or e.y >= Mission.heightAt(m, e.x)
        if not dead and s.alive and s.invuln <= 0 then
            local dx, dy = e.x - s.x, e.y - s.y
            if dx * dx + dy * dy < 49 then
                Ship.kill()
                dead = true
            end
        end
        if dead then table.remove(m.eshots, i) end
    end

    -- our shots vs terrain, bunkers, the reactor
    Ship.updateShots(dt, function(b)
        if b.x < 0 or b.x > C.WORLD_W then return true end
        if b.y >= Mission.heightAt(m, b.x) then return true end
        for _, bk in ipairs(m.bunkers) do
            if bk.alive then
                local dx, dy = b.x - bk.x, b.y - (bk.y - 5)
                if dx * dx + dy * dy < 100 then
                    bk.alive = false
                    G.addScore(C.PTS_BUNKER)
                    Harness.count("bunkers")
                    G.fxBurst(bk.x, bk.y - 4, 10)
                    G.fxDebris(bk.x, bk.y - 4, 5)
                    Sfx.boom(2)
                    local all = true
                    for _, o in ipairs(m.bunkers) do
                        if o.alive then all = false break end
                    end
                    if all and not m.defDown then
                        m.defDown = true
                        G.message("DEFENSES DOWN - ESCAPE!", 2.5)
                        Sfx.fanfare()
                    end
                    return true
                end
            end
        end
        local r = m.reactor
        if not r.hit then
            local dx, dy = b.x - r.x, b.y - r.y
            if dx * dx + dy * dy < 144 then
                r.hit = true
                m.reactorT = C.REACTOR_TIME
                m.sirenT = 0
                G.addScore(C.PTS_REACTOR_HIT)
                Harness.count("reactors")
                G.fxBurst(r.x, r.y, 14)
                Fx.flash(0.15)
                Sfx.zapSweep()
                G.message("REACTOR CRITICAL - ESCAPE!", 2.5)
                return true
            end
        end
        return false
    end)

    -- the reactor countdown
    if m.reactorT then
        m.reactorT = m.reactorT - dt
        m.sirenT = (m.sirenT or 0) - dt
        if m.sirenT <= 0 then
            m.sirenT = 0.45
            Sfx.sirenTick(520)
        end
        if m.reactorT <= 0 then
            m.reactorT = nil
            m.reactor.hit = false -- it survives if you don't
            Fx.flash(0.4)
            Sfx.bigBoom()
            G.message("CAUGHT IN THE BLAST", 2.2)
            if s.alive then Ship.kill(true) end
        end
    end
end
