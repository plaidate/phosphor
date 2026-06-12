-- Trenchfire controls: d-pad steers the crosshair, crank is the throttle
-- lever (accumulated, 0..1), A or B holds the trigger. The smoke autopilot
-- tracks the nearest threat (fireballs first — they are shootable), holds
-- mid throttle, and in the trench centers up then snipes the port the
-- moment it comes into range.

Input = {}

local clamp = Util.clamp

Harness.autopilot = function()
    local tx, ty = Proj.cx, Proj.cy
    local found = false

    -- nearest on-screen fireball, any phase
    local bz = math.huge
    for _, f in ipairs(G.fireballs) do
        local sx, sy, z = Proj.point(f.x, f.y, f.z)
        if sx and z < bz and sx > 12 and sx < 388 and sy > 12 and sy < 228 then
            bz, tx, ty, found = z, sx, sy, true
        end
    end

    if G.phase == "trench" then
        local dz = G.trenchEnd - G.camZ
        if dz > 10 and dz < C.PORT_RANGE * 1.15 then
            -- the port outranks everything: line up and snipe
            local px, py = Proj.point(0, C.PORT_Y, G.trenchEnd)
            if px then tx, ty = px, py end
        elseif not found then
            tx, ty = Proj.cx, Proj.cy - 12 -- ride the centerline
        end
    elseif not found then
        local bz2 = math.huge
        local function scan(list)
            for _, e in ipairs(list) do
                local sx, sy, z = Proj.point(e.x, e.y + e.aimY, e.z)
                if sx and z < bz2 and sx > 8 and sx < 392 and sy > 8 and sy < 232 then
                    bz2, tx, ty = z, sx, sy
                end
            end
        end
        scan(G.fighters)
        scan(G.towers)
        scan(G.hardpoints)
    end

    local mx = clamp((tx - G.crossX) / 12, -1, 1)
    local my = clamp((ty - G.crossY) / 12, -1, 1)
    return mx, my, true, 0.5
end

-- returns: moveX (-1..1), moveY (-1..1), fire, throttle (0..1)
function Input.gather()
    if Harness.enabled and Harness.autopilot then
        return Harness.autopilot()
    end

    local mx, my = 0, 0
    if playdate.buttonIsPressed(playdate.kButtonLeft) then mx = mx - 1 end
    if playdate.buttonIsPressed(playdate.kButtonRight) then mx = mx + 1 end
    if playdate.buttonIsPressed(playdate.kButtonUp) then my = my - 1 end
    if playdate.buttonIsPressed(playdate.kButtonDown) then my = my + 1 end

    local fire = playdate.buttonIsPressed(playdate.kButtonA)
        or playdate.buttonIsPressed(playdate.kButtonB)
    local throttle = clamp(G.throttle + playdate.getCrankChange() / 300, 0, 1)
    return mx, my, fire, throttle
end
