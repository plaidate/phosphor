-- Border Circuit controls: the crank steers the ship 1:1 (the original
-- cabinet used a spinner, so this is the historically right input), d-pad
-- left/right as fallback; B or up thrusts, A fires.
-- The smoke autopilot tracks the nearest enemy and never stops shooting.

Input = {}

local clamp = Util.clamp

Harness.autopilot = function()
    local s = G.ship
    local turn, thrust = 0, false
    if s and s.alive then
        local tx, ty, bestD = nil, nil, math.huge
        local function consider(e)
            local dx, dy = e.x - s.x, e.y - s.y
            local d = dx * dx + dy * dy
            if d < bestD then bestD, tx, ty = d, e.x, e.y end
        end
        for _, d in ipairs(G.drones) do consider(d) end
        for _, l in ipairs(G.layers) do consider(l) end
        for _, m in ipairs(G.mines) do consider(m) end
        if tx then
            local want = Vec.angleOf(tx - s.x, ty - s.y)
            turn = clamp(Vec.angleDiff(s.angle, want), -C.DPAD_TURN * Attract.dt, C.DPAD_TURN * Attract.dt)
        end
        thrust = math.random() < 0.10 -- short bursts; the rest is coasting
    end
    return turn, thrust, true
end

-- returns: turnDegrees, thrust, fire
function Input.gather()
    if Harness.enabled and Harness.autopilot then
        return Harness.autopilot()
    end

    local turn = playdate.getCrankChange() * C.CRANK_RATIO
    if playdate.buttonIsPressed(playdate.kButtonLeft) then
        turn = turn - C.DPAD_TURN * Attract.dt
    end
    if playdate.buttonIsPressed(playdate.kButtonRight) then
        turn = turn + C.DPAD_TURN * Attract.dt
    end

    local thrust = playdate.buttonIsPressed(playdate.kButtonB)
        or playdate.buttonIsPressed(playdate.kButtonUp)
    local fire = playdate.buttonIsPressed(playdate.kButtonA)
    return turn, thrust, fire
end
