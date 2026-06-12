-- Touchdown controls: the crank accumulates into a 0-100% throttle,
-- left/right tilts the lander, B is a full burn. The smoke autopilot
-- steers to the nearest pad and rides the glide slope down.

Input = {}

local clamp = Util.clamp

Harness.autopilot = function()
    local l = G.lander
    if not l or l.dead or G.mode ~= "fly" then return 0, 0, false end
    local dt = Attract.dt

    -- nearest pad by horizontal distance
    local best, bestD
    for _, p in ipairs(G.pads or {}) do
        local d = math.abs((p.x1 + p.x2) / 2 - l.x)
        if not best or d < bestD then best, bestD = p, d end
    end
    if not best then return 0, 0, false end

    local cx = (best.x1 + best.x2) / 2
    local dx = cx - l.x
    local alt = best.y - (l.y + C.FOOT_Y)

    -- steer: chase a horizontal speed that closes dx, gentler near the deck
    local wantVx = clamp(dx * 0.5, -26, 26)
    if alt < 36 then wantVx = clamp(dx * 0.35, -9, 9) end
    local wantTilt = clamp((wantVx - l.vx) * 3.5, -46, 46)
    if alt < 18 then wantTilt = 0 end -- level off before touchdown
    local turn = clamp(wantTilt - l.tilt, -C.TURN_RATE * dt, C.TURN_RATE * dt)

    -- glide slope: sink at ~alt/3, capped; hold high until lined up
    local wantVy = math.min(20, math.max(alt, 0) / 3)
    if math.abs(dx) > 30 and alt < 60 then wantVy = 2 end
    local dThrottle = clamp((l.vy - wantVy) * 9, -140, 140) * dt
    local burn = (l.vy - wantVy) > 22

    return turn, dThrottle, burn
end

-- returns: turnDegrees, throttleDelta (%), fullBurn
function Input.gather()
    if Harness.enabled and Harness.autopilot then
        return Harness.autopilot()
    end

    local dThrottle = playdate.getCrankChange() * C.CRANK_THROTTLE
    local turn = 0
    if playdate.buttonIsPressed(playdate.kButtonLeft) then
        turn = turn - C.TURN_RATE * Attract.dt
    end
    if playdate.buttonIsPressed(playdate.kButtonRight) then
        turn = turn + C.TURN_RATE * Attract.dt
    end
    local burn = playdate.buttonIsPressed(playdate.kButtonB)
    return turn, dThrottle, burn
end
