-- Gravity Wells controls: crank rotates the ship 1:1 (d-pad fallback),
-- B or up thrusts, A fires, DOWN holds the tractor beam out. The smoke
-- autopilot flies to uncleared planets, hover-descends onto fuel and
-- bunkers, beams fuel, shoots back, and bugs out when the tank runs low.

Input = {}

local clamp = Util.clamp

local function steerTo(s, wantAngle, tol)
    local diff = Vec.angleDiff(s.angle, wantAngle)
    local turn = clamp(diff, -C.DPAD_TURN * Attract.dt, C.DPAD_TURN * Attract.dt)
    return turn, math.abs(diff) < (tol or 40)
end

local function systemPilot(s)
    local best, bd
    for _, p in ipairs(G.planets) do
        if not p.cleared then
            local d = (p.x - s.x) ^ 2 + (p.y - s.y) ^ 2
            if not bd or d < bd then best, bd = p, d end
        end
    end
    local tx, ty = best and best.x or 200, best and best.y or 40

    -- chase a velocity toward the target, plus a hard shove away from the star
    local nx, ny = Vec.norm(tx - s.x, ty - s.y)
    local wvx, wvy = nx * 65, ny * 65
    local rx, ry = s.x - C.STAR_X, s.y - C.STAR_Y
    local rd = Vec.len(rx, ry)
    if rd > 0 and rd < 75 then
        wvx = wvx + rx / rd * 110
        wvy = wvy + ry / rd * 110
    end
    local ax, ay = wvx - s.vx, wvy - s.vy
    local turn, aligned = steerTo(s, Vec.angleOf(ax, ay), 45)
    return turn, aligned and Vec.len(ax, ay) > 16, false, false
end

local function missionPilot(s)
    local m = G.m
    local g = Mission.gravity(m)

    -- beam whenever a live tank sits under us, whatever else is going on
    local beam = false
    for _, t in ipairs(m.tanks) do
        if t.alive and math.abs(t.x - s.x) < C.BEAM_HALF_W
            and t.y > s.y and t.y - s.y < C.BEAM_LEN + 6 then
            beam = true
        end
    end

    local escape = G.fuel < C.FUEL_MAX * 0.3 or m.reactorT ~= nil or m.defDown

    -- pick a target: fuel first when low, then this planet's strategy —
    -- odd wells go for the reactor, even wells grind the bunkers
    local target, kind
    if not escape then
        if G.fuel < 65 then
            local bd
            for _, t in ipairs(m.tanks) do
                if t.alive then
                    local d = (t.x - s.x) ^ 2 + (t.y - s.y) ^ 2
                    if not bd or d < bd then target, bd, kind = t, d, "tank" end
                end
            end
        end
        if not target then
            if m.kind % 2 == 1 and not m.reactor.hit then
                target, kind = m.reactor, "reactor"
            else
                local bd
                for _, b in ipairs(m.bunkers) do
                    if b.alive then
                        local d = (b.x - s.x) ^ 2 + (b.y - s.y) ^ 2
                        if not bd or d < bd then target, bd, kind = b, d, "bunker" end
                    end
                end
                if not target and not m.reactor.hit then
                    target, kind = m.reactor, "reactor"
                end
            end
        end
    end

    if escape or not target then
        local turn, aligned = steerTo(s, -90, 55)
        return turn, aligned and s.vy > -70, false, beam
    end

    local tx, ty = target.x, target.y
    local hoverY
    if kind == "tank" then hoverY = ty - C.BEAM_LEN + 10
    elseif kind == "reactor" then hoverY = 70 -- above the chamber mouth
    else hoverY = ty - 70 end

    -- hover controller: chase a velocity, cancel gravity
    local wvx = clamp((tx - s.x) * 0.8, -50, 50)
    local wvy = clamp((hoverY - s.y) * 0.9, -45, 35)
    local ax = (wvx - s.vx) * 1.5
    local ay = (wvy - s.vy) * 1.5 - g
    local amag = Vec.len(ax, ay)
    local dist = math.sqrt((tx - s.x) ^ 2 + (ty - s.y) ^ 2)

    -- stable enough: swing the nose onto the target and shoot
    if kind ~= "tank" and amag < 55 and dist < 230 then
        local turn, aimed = steerTo(s, Vec.angleOf(tx - s.x, ty - s.y), 10)
        return turn, false, aimed, beam
    end

    local turn, aligned = steerTo(s, Vec.angleOf(ax, ay), 40)
    return turn, aligned and amag > 14, false, beam
end

Harness.autopilot = function()
    local s = G.ship
    if not s or not s.alive then return 0, false, false, false end
    if G.view == "system" then
        return systemPilot(s)
    end
    return missionPilot(s)
end

-- returns: turnDegrees, thrust, fire, beam
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
    local beam = playdate.buttonIsPressed(playdate.kButtonDown)
    return turn, thrust, fire, beam
end
