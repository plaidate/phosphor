-- Open Geometry Wars controls: the d-pad thrusts the ship, the crank is an
-- absolute aim dial (point it where the guns should fire — autofire is always
-- on), and B drops a smart bomb. The smoke autopilot aims at the nearest
-- threat, flees crowding, and bombs when swarmed.

Input = {}

-- nearest live enemy to the ship (or nil)
local function nearestEnemy()
    local s = G.ship
    local best, bd = nil, math.huge
    for _, e in ipairs(G.enemies) do
        if e.warn <= 0 then
            local d = Vec.len(e.x - s.x, e.y - s.y)
            if d < bd then bd, best = d, e end
        end
    end
    return best, bd
end

Harness.autopilot = function()
    local s = G.ship
    local mvx, mvy, aim, bomb = 0, 0, -90, false
    if s and s.alive then
        local e, d = nearestEnemy()
        if e then
            aim = Vec.angleOf(e.x - s.x, e.y - s.y)
            -- back away if it gets close; otherwise drift toward open space
            if d < 70 then
                mvx, mvy = Vec.norm(s.x - e.x, s.y - e.y)
            end
        end
        -- nudge toward arena centre to avoid pinning in corners
        if mvx == 0 and mvy == 0 then
            mvx, mvy = Vec.norm(Field.W / 2 - s.x, Field.H / 2 - s.y)
        end
        if #G.enemies > 12 and G.bombs > 0 and math.random() < 0.04 then bomb = true end
    end
    return mvx, mvy, aim, bomb
end

-- returns: moveX, moveY (normalised or 0), aimDegrees, bomb
function Input.gather()
    if Harness.enabled and Harness.autopilot then
        return Harness.autopilot()
    end

    local mx, my = 0, 0
    if playdate.buttonIsPressed(playdate.kButtonLeft) then mx = mx - 1 end
    if playdate.buttonIsPressed(playdate.kButtonRight) then mx = mx + 1 end
    if playdate.buttonIsPressed(playdate.kButtonUp) then my = my - 1 end
    if playdate.buttonIsPressed(playdate.kButtonDown) then my = my + 1 end
    if mx ~= 0 and my ~= 0 then
        mx, my = mx * 0.7071, my * 0.7071
    end

    -- absolute crank aim: crank 0 points up, clockwise = clockwise on screen
    local aim = playdate.getCrankPosition() - 90

    local bomb = playdate.buttonJustPressed(playdate.kButtonB)
        or playdate.buttonJustPressed(playdate.kButtonA)
    return mx, my, aim, bomb
end
