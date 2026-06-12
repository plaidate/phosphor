-- Night Vector: the player's car and the traffic it shares the night with.
-- The car drives freely in the XZ plane (the wheel yaws it by wheel x speed)
-- and is continuously located against the road centerline; traffic lives in
-- road coordinates (s along, lat across) and is unrolled to world space only
-- to draw and to collide.

local clamp = Util.clamp

Car = {}

function Car.new()
    local p = Road.point(1)
    return {
        x = p.x + p.fz * C.LANE, z = p.z - p.fx * C.LANE,
        yaw = p.h, wheel = 0, speed = 0,
        seg = 1, along = 0, lat = C.LANE,
        s = 0,        -- current distance along the centerline
        dist = 0,     -- farthest distance reached (the score odometer)
        crashT = 0,
        offroad = false,
    }
end

function Car.crash()
    local c = G.car
    if c.crashT > 0 then return end
    c.crashT = C.CRASH_TIME
    c.speed = 0
    G.cars = G.cars - 1
    G.shake = 0
    Harness.count("crashes")
    Fx.flash(0.3)
    Fx.burst(Proj.cx, Proj.cy + 10, 18, 110)
    Fx.debris(Proj.cx, Proj.cy + 10, 14, 80)
    Sfx.bigBoom()
end

-- After a wreck: back on the centerline lane, stopped, facing down-road,
-- with the traffic immediately around us towed away.
function Car.placeOnRoad()
    local c = G.car
    local p = Road.point(c.seg)
    c.x = p.x + p.fz * C.LANE
    c.z = p.z - p.fx * C.LANE
    c.yaw = p.h
    c.wheel, c.speed = 0, 0
    c.along, c.lat = 0, C.LANE
    c.s = (c.seg - 1) * C.SEG
    c.offroad = false
    c.crashT = 0
    for i = #G.traffic, 1, -1 do
        if math.abs(G.traffic[i].s - c.s) < 100 then
            table.remove(G.traffic, i)
        end
    end
end

local function checkObstacles(c)
    -- obstacles stand at least a metre off the shoulder, so skip the test
    -- unless we are out among them
    if math.abs(c.lat) <= C.HALF_W + 0.8 then return end
    for i = math.max(1, c.seg - 1), c.seg + 2 do
        local p = Road.point(i)
        local o = p.obs
        if o then
            local ox = p.x + p.fz * o.off * o.side
            local oz = p.z - p.fx * o.off * o.side
            local dx, dz = c.x - ox, c.z - oz
            if dx * dx + dz * dz < C.OBS_R * C.OBS_R then
                Car.crash()
                return
            end
        end
    end
end

function Car.update(dt, wheelD, accel, brake)
    local c = G.car
    c.wheel = clamp(c.wheel + wheelD, -C.WHEEL_MAX, C.WHEEL_MAX)

    if c.crashT > 0 then
        c.crashT = c.crashT - dt
        if c.crashT <= 0 then
            if G.cars <= 0 then
                G.dead = true
            else
                Car.placeOnRoad()
            end
        end
        return
    end

    local a = (accel and C.ACCEL or 0) - (brake and C.BRAKE or 0) - C.DRAG * c.speed
    c.speed = clamp(c.speed + a * dt, 0, C.MAX_SPEED)

    -- the wheel yaws the car in proportion to speed
    c.yaw = c.yaw + c.wheel * c.speed * C.STEER_GAIN * dt
    local r = math.rad(c.yaw)
    c.x = c.x + math.sin(r) * c.speed * dt
    c.z = c.z + math.cos(r) * c.speed * dt

    c.seg, c.along, c.lat = Road.locate(c.seg, c.x, c.z)
    c.s = (c.seg - 1) * C.SEG + c.along
    if c.s > c.dist then c.dist = c.s end

    if math.abs(c.lat) > C.HALF_W then
        if not c.offroad then
            c.offroad = true
            Harness.count("offroads")
            Sfx.boom(1)
        end
        c.speed = c.speed * (1 - math.min(C.OFFROAD_DRAG * dt, 0.9))
        G.shake = math.min(3, 0.6 + c.speed * 0.05)
        if Attract.frame % 4 == 0 and c.speed > 3 then Sfx.thrustTick() end
    else
        c.offroad = false
        G.shake = 0
    end

    checkObstacles(c)
end

local function spawnOne(c)
    local dir = math.random() < 0.5 and 1 or -1
    local s = c.s + C.SPAWN_AHEAD + math.random() * 100
    for _, t in ipairs(G.traffic) do
        if t.dir == dir and math.abs(t.s - s) < 40 then return end -- no stacking
    end
    local vr = dir == 1 and C.SAME_V or C.ONCOMING_V
    G.traffic[#G.traffic + 1] = {
        s = s,
        lat = dir == 1 and C.LANE or -C.LANE, -- keep right; oncoming keeps theirs
        dir = dir,
        v = vr[1] + math.random() * (vr[2] - vr[1]),
        passed = false,
    }
end

function Car.updateTraffic(dt)
    local c = G.car
    G.spawnT = G.spawnT - dt
    if G.spawnT <= 0 and #G.traffic < C.TRAFFIC_MAX then
        G.spawnT = C.SPAWN_EVERY
        spawnOne(c)
    end
    for i = #G.traffic, 1, -1 do
        local t = G.traffic[i]
        t.s = t.s + t.dir * t.v * dt
        if t.s < c.s - C.DESPAWN_BEHIND or t.s > c.s + C.DESPAWN_AHEAD then
            table.remove(G.traffic, i)
        else
            if t.dir == 1 and not t.passed and t.s < c.s - 5 then
                t.passed = true
                G.addScore(C.PTS_OVERTAKE)
                Harness.count("overtakes")
                Sfx.blip(990)
            end
            if c.crashT <= 0 and math.abs(t.s - c.s) < C.HIT_LEN
                and math.abs(t.lat - c.lat) < C.CAR_R then
                Car.crash()
            end
        end
    end
end
