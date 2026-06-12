-- Rubble controls: crank spins the ship 1:1, d-pad fallback; B or up
-- thrusts, A fires, down is hyperspace. The smoke autopilot hunts rocks.

Input = {}

local clamp = Util.clamp

Harness.autopilot = function()
    local ship = G.ship
    local turn, thrust, hyper = 0, false, false
    if ship and ship.alive then
        local tx, ty, bestD = nil, nil, math.huge
        for _, r in ipairs(G.rocks) do
            local d = Field.dist2(ship.x, ship.y, r.x, r.y)
            if d < bestD then bestD, tx, ty = d, r.x, r.y end
        end
        if G.saucer then
            local d = Field.dist2(ship.x, ship.y, G.saucer.x, G.saucer.y)
            if d < bestD then bestD, tx, ty = d, G.saucer.x, G.saucer.y end
        end
        if tx then
            local want = Vec.angleOf(tx - ship.x, ty - ship.y)
            turn = clamp(Vec.angleDiff(ship.angle, want), -C.DPAD_TURN * Attract.dt, C.DPAD_TURN * Attract.dt)
            if bestD < 24 * 24 then hyper = math.random() < 0.3 end
        end
        thrust = math.random() < 0.12
    end
    return turn, thrust, true, hyper
end

-- returns: turnDegrees, thrust, fire, hyper
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
    local hyper = playdate.buttonJustPressed(playdate.kButtonDown)
    return turn, thrust, fire, hyper
end
