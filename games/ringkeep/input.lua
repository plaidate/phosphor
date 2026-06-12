-- Ringkeep controls: crank spins the ship 1:1, d-pad fallback; B or up
-- thrusts, A fires. The smoke autopilot rides a firing lane outside the
-- rings, pours shots into the keep, and burst-thrusts away from hunters.

Input = {}

local clamp = Util.clamp

Harness.autopilot = function()
    local s = G.ship
    if not (s and s.alive) then return 0, false, true end
    local thrust = false

    -- nearest live threat: the fireball, or any mine off its leash
    local thX, thY, thD = nil, nil, math.huge
    if G.fireball then
        local d = Field.dist2(s.x, s.y, G.fireball.x, G.fireball.y)
        if d < thD then thD, thX, thY = d, G.fireball.x, G.fireball.y end
    end
    for _, m in ipairs(G.mines) do
        if m.state == "chase" then
            local d = Field.dist2(s.x, s.y, m.x, m.y)
            if d < thD then thD, thX, thY = d, m.x, m.y end
        end
    end

    local want
    if thX and thD < 60 * 60 then
        -- evade: face dead away and burn; a straight run outruns everything
        local dx, dy = G.wrapDelta(thX, thY, s.x, s.y)
        want = Vec.angleOf(dx, dy)
        thrust = true
    else
        -- hold the mid lane outside the rings: tangent travel blended with
        -- a radial correction, thrusting only when roughly facing it
        local rx, ry = s.x - C.CX, s.y - C.CY
        local nx, ny, rd = Vec.norm(rx, ry)
        local orbitR = C.RING_RADII[1] + 26
        local err = orbitR - rd -- +ve means we sit inside the lane
        local speed = Vec.len(s.vx, s.vy)
        if math.abs(err) > 18 or speed < 35 then
            local k = clamp(err / 25, -1.4, 1.4)
            want = Vec.angleOf(-ny + nx * k, nx + ny * k)
            thrust = math.abs(Vec.angleDiff(s.angle, want)) < 40
        else
            -- in the lane: train the guns on the keep (whatever shield
            -- segment stands in the way takes the hit)
            want = Vec.angleOf(C.CX - s.x, C.CY - s.y)
        end
    end

    local turn = clamp(Vec.angleDiff(s.angle, want),
        -C.DPAD_TURN * Attract.dt, C.DPAD_TURN * Attract.dt)
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
