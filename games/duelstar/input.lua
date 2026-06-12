-- Duelstar controls: crank turns the ship 1:1, d-pad fallback; B or up
-- thrusts, A fires, down is hyperspace. The smoke autopilot duels the
-- rival with a gravity-aware lead and bails out of sun captures.

Input = {}

local clamp = Util.clamp

Harness.autopilot = function()
    local p, r = G.player, G.rival
    if G.phase ~= "fight" or not (p and p.alive and r and r.alive) then
        return 0, false, false, false
    end

    -- sun-capture imminent: jump
    local steps = Ships.sunDanger(p)
    if steps and steps <= 8 then
        return 0, false, false, true
    end

    local lead, dist = Ships.leadAngle(p, r)
    local offLead = math.abs(Vec.angleDiff(p.angle, lead))
    local want, thrust = lead, false
    if steps then
        -- falling sunward: burn outward, biased prograde
        want = Vec.angleOf(p.x - C.SUN_X, p.y - C.SUN_Y) + Ships.tangentSide(p) * 40
        thrust = true
    elseif dist > 160 then
        thrust = offLead < 60 -- close toward mid-range
    elseif dist < 60 then
        want = lead + 150 -- too close: peel away
        thrust = true
    end

    local turn = clamp(Vec.angleDiff(p.angle, want), -C.DPAD_TURN * C.DT, C.DPAD_TURN * C.DT)
    local fire = offLead < 25
    return turn, thrust, fire, false
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
