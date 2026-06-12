-- Treadline controls: up/down drives both treads, left/right pivots the
-- hull (combined with up/down for a gentle arc), the crank slews the turret
-- and the view, A or B fires. The smoke autopilot tracks the nearest radar
-- blip with the turret, advances when far, fires inside 3 degrees, and
-- reverse-pivots for a new line when an obstacle masks the hostile.

Input = {}

local clamp = Util.clamp

Harness.autopilot = function()
    if G.dead then return 0, 0, 0, false end
    local drive, turn, crank, fire = 0, 0, 0, false
    local e = G.enemy
    if e then
        local dx, dz = e.x - G.px, e.z - G.pz
        local dist = Vec.len(dx, dz)
        local brg = World.bearing(dx, dz)
        local diff = Vec.angleDiff(G.viewYaw(), brg)
        crank = clamp(diff, -9, 9)
        local blocked = World.losBlocked(G.px, G.pz, e.x, e.z)
        if blocked then
            drive, turn = -1, 1 -- back out and pivot for a clear line
        elseif dist > 30 then
            local hd = Vec.angleDiff(G.hullYaw, brg)
            turn = (hd > 10 and 1) or (hd < -10 and -1) or 0
            drive = 1
        end
        if not blocked and math.abs(diff) < 3 and not G.shell then
            fire = true
        end
    else
        crank = 4 -- idle scan while the radar is clear
    end
    return drive, turn, crank, fire
end

-- returns: drive (-1/0/1), turn (-1/0/1), crank turret degrees, fire
function Input.gather()
    if Harness.enabled and Harness.autopilot then
        return Harness.autopilot()
    end

    local drive, turn = 0, 0
    if playdate.buttonIsPressed(playdate.kButtonUp) then
        drive = 1
    elseif playdate.buttonIsPressed(playdate.kButtonDown) then
        drive = -1
    end
    if playdate.buttonIsPressed(playdate.kButtonLeft) then
        turn = -1
    elseif playdate.buttonIsPressed(playdate.kButtonRight) then
        turn = 1
    end

    local crank = playdate.getCrankChange()
    local fire = playdate.buttonJustPressed(playdate.kButtonA)
        or playdate.buttonJustPressed(playdate.kButtonB)
    return drive, turn, crank, fire
end
