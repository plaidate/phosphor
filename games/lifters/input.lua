-- Lifters controls: crank spins the ship 1:1, d-pad fallback; B or up
-- thrusts, A fires. The smoke autopilot plays the real game: stop the
-- raider closest to making off with the fuel.

Input = {}

local clamp = Util.clamp

Harness.autopilot = function()
    local s = G.ship
    local turn, thrust = 0, false
    if s and s.alive then
        -- draggers outrank everything, the one nearest its escape edge first;
        -- otherwise hunt whichever raider is closest to the ship
        local tx, ty, best = nil, nil, math.huge
        for _, rd in ipairs(G.raiders) do
            if rd.delay <= 0 then
                local urgency
                if rd.state == "drag" then
                    local edgeD = math.min(rd.x, Field.W - rd.x, rd.y, Field.H - rd.y)
                    urgency = edgeD - 1e6
                else
                    urgency = G.dist2(s.x, s.y, rd.x, rd.y)
                end
                if urgency < best then
                    best, tx, ty = urgency, rd.x, rd.y
                end
            end
        end
        if tx then
            local want = Vec.angleOf(tx - s.x, ty - s.y)
            local diff = Vec.angleDiff(s.angle, want)
            turn = clamp(diff, -C.DPAD_TURN * Attract.dt, C.DPAD_TURN * Attract.dt)
            -- burst thrust toward the mark once roughly lined up
            thrust = math.abs(diff) < 55 and math.random() < 0.3
        end
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
