-- Webguard controls: d-pad moves the spider freely, the crank aims the
-- firing line 1:1, and holding A or B autofires. The smoke autopilot
-- snipes the most urgent threat and kites away from chasers, mid-web.

Input = {}

local clamp = Util.clamp

Harness.autopilot = function()
    local p = G.player
    local mx, my, aimD = 0, 0, 0
    if p and p.alive then
        -- aim: eggs about to hatch first, then whatever is closest
        local tx, ty, bestD = nil, nil, math.huge
        for _, e in ipairs(G.eggs) do
            if e.t > C.EGG_HATCH - 1.6 then
                local d = G.dist2(p.x, p.y, e.x, e.y)
                if d < bestD then bestD, tx, ty = d, e.x, e.y end
            end
        end
        if not tx then
            local function scan(list)
                for _, e in ipairs(list) do
                    local d = G.dist2(p.x, p.y, e.x, e.y)
                    if d < bestD then bestD, tx, ty = d, e.x, e.y end
                end
            end
            scan(G.chasers)
            scan(G.bombers)
            scan(G.layers)
            scan(G.eggs)
        end
        if tx then
            local want = Vec.angleOf(tx - p.x, ty - p.y)
            aimD = clamp(Vec.angleDiff(p.aim, want), -28, 28)
        end

        -- kite: away from the nearest hunting chaser, drifting mid-web
        local nx, ny, nearD = nil, nil, math.huge
        for _, e in ipairs(G.chasers) do
            local d = G.dist2(p.x, p.y, e.x, e.y)
            if d < nearD then nearD, nx, ny = d, e.x, e.y end
        end
        for _, f in ipairs(G.frags) do
            local d = G.dist2(p.x, p.y, f.x, f.y)
            if d < nearD then nearD, nx, ny = d, f.x, f.y end
        end
        if nx and nearD < 80 * 80 then
            mx, my = Vec.norm(p.x - nx, p.y - ny)
        end
        -- gentle pull toward the middle rings
        local rx, ry, r = Vec.norm(p.x - C.CX, p.y - C.CY)
        local mid = (C.RINGS[2] + C.RINGS[3]) / 2
        local pull = clamp((mid - r) * 0.03, -0.8, 0.8)
        mx = mx + rx * pull
        my = my + ry * pull
    end
    return mx, my, aimD, true
end

-- returns: moveX, moveY, aimDeltaDegrees, fire
function Input.gather()
    if Harness.enabled and Harness.autopilot then
        return Harness.autopilot()
    end

    local mx, my = 0, 0
    if playdate.buttonIsPressed(playdate.kButtonLeft) then mx = mx - 1 end
    if playdate.buttonIsPressed(playdate.kButtonRight) then mx = mx + 1 end
    if playdate.buttonIsPressed(playdate.kButtonUp) then my = my - 1 end
    if playdate.buttonIsPressed(playdate.kButtonDown) then my = my + 1 end

    local aimD = playdate.getCrankChange() * C.CRANK_RATIO
    local fire = playdate.buttonIsPressed(playdate.kButtonA)
        or playdate.buttonIsPressed(playdate.kButtonB)
    return mx, my, aimD, fire
end
