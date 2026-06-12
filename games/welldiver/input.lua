-- Welldiver controls: the crank is the spinner — one revolution sweeps the
-- claw around all 16 lanes; d-pad fallback. B fires, A superzaps. The smoke
-- autopilot faces the deepest threat, never stops shooting, zaps a crowded
-- rim, and steers for a spike-free lane during the warp.

Input = {}

local clamp = Util.clamp

Harness.autopilot = function()
    local w = G.well
    local me = Player.lane()
    local target = me

    if G.mode == "warp" then
        -- nearest spike-free lane
        local bestD = math.huge
        for l = 0, w.lanes - 1 do
            if (G.spikes[l] or 0) <= 0.02 then
                local d = math.abs(G.laneDelta(me, l, w.lanes, w.closed))
                if d < bestD then
                    bestD, target = d, l
                end
            end
        end
    else
        -- the enemy nearest the rim; spikes as a fallback target
        local bz = -1
        for _, e in ipairs(G.enemies) do
            if e.z > bz then
                bz, target = e.z, e.lane
            end
        end
        if bz < 0 then
            for l = 0, w.lanes - 1 do
                if (G.spikes[l] or 0) > 0.02 then
                    target = l
                    break
                end
            end
        end
    end

    -- zap when the rim is getting crowded
    local zap = false
    if G.zapsUsed == 0 then
        local atRim = 0
        for _, e in ipairs(G.enemies) do
            if e.z > 0.9 then atRim = atRim + 1 end
        end
        zap = atRim >= 3
    end

    local d = G.laneDelta(me, target, w.lanes, w.closed)
    return clamp(d, -1, 1) * C.DPAD_LANES_PER_SEC * C.DT, true, zap
end

-- returns: moveDelta (lanes), fire, zap
function Input.gather()
    if Harness.enabled and Harness.autopilot then
        return Harness.autopilot()
    end

    local delta = playdate.getCrankChange() / C.CRANK_DEG_PER_LANE
    if playdate.buttonIsPressed(playdate.kButtonLeft) then
        delta = delta - C.DPAD_LANES_PER_SEC * C.DT
    end
    if playdate.buttonIsPressed(playdate.kButtonRight) then
        delta = delta + C.DPAD_LANES_PER_SEC * C.DT
    end

    local fire = playdate.buttonIsPressed(playdate.kButtonB)
    local zap = playdate.buttonJustPressed(playdate.kButtonA)
    return delta, fire, zap
end
