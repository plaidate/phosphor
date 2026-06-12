-- Night Vector controls: the crank IS the steering wheel, 1:1 into wheel
-- angle and clamped at the lock stops; d-pad left/right as a fallback.
-- A accelerates, B brakes (up/down work too). The smoke autopilot steers on
-- centerline error plus lookahead curvature, runs flat-out below 140 kph,
-- and brakes for sharp curves and for traffic ahead in its lane.

Input = {}

local clamp = Util.clamp

Harness.autopilot = function()
    local c = G.car
    if not c or c.crashT > 0 then return 0, false, false end

    local kph = c.speed * 3.6
    local hErr = Vec.angleDiff(Road.point(c.seg + 2).h, c.yaw) -- + = nosing right
    local curve = Road.curveAhead(c.seg, 2, 9)                 -- deg/segment

    -- pick a lane: swing out for slower traffic ahead, unless lights are coming
    local lane = C.LANE
    local blocked, oncomingNear = false, false
    for _, t in ipairs(G.traffic) do
        local ds = t.s - c.s
        if t.dir == 1 and ds > 0 and ds < 70 and math.abs(t.lat - C.LANE) < 1.8 then
            blocked = true
        end
        if t.dir == -1 and ds > 0 and ds < 140 then
            oncomingNear = true
        end
    end
    if blocked and not oncomingNear then lane = -C.LANE end

    -- wheel: lateral error + heading damping + the wheel angle that holds the arc
    local latErr = c.lat - lane
    local holdArc = curve / (C.STEER_GAIN * C.SEG)
    local damp = 110 / math.max(c.speed, 8)
    local want = clamp(-latErr * 5 - hErr * damp + holdArc, -C.WHEEL_MAX, C.WHEEL_MAX)
    local wd = clamp(want - c.wheel, -300 * C.DT, 300 * C.DT)

    -- throttle: flat-out below 140; ease toward a curve-shaped limit above
    local limit = 178 - math.abs(curve) * 38
    local accel = kph < 140 or kph < limit
    local brake = kph > limit + 6
    if blocked and oncomingNear then -- boxed in: match pace, don't ram
        brake = c.speed > 15
        accel = c.speed < 13
    end
    if brake then accel = false end
    return wd, accel, brake
end

-- returns: wheelDelta (degrees), accel, brake
function Input.gather()
    if Harness.enabled and Harness.autopilot then
        return Harness.autopilot()
    end

    local wd = playdate.getCrankChange() * C.CRANK_RATIO
    if playdate.buttonIsPressed(playdate.kButtonLeft) then
        wd = wd - C.DPAD_WHEEL * C.DT
    end
    if playdate.buttonIsPressed(playdate.kButtonRight) then
        wd = wd + C.DPAD_WHEEL * C.DT
    end
    local accel = playdate.buttonIsPressed(playdate.kButtonA)
        or playdate.buttonIsPressed(playdate.kButtonUp)
    local brake = playdate.buttonIsPressed(playdate.kButtonB)
        or playdate.buttonIsPressed(playdate.kButtonDown)
    return wd, accel, brake
end
