-- Gyre controls: the crank IS the ship — one revolution flies one full
-- orbit of the rim; d-pad fallback. A or B fires. The smoke autopilot
-- dodges whatever is closing on the rim and otherwise chases the juiciest
-- target around the tube, trigger held.

Input = {}

local clamp = Util.clamp

local function sgn(v)
    return v >= 0 and 1 or -1
end

Harness.autopilot = function()
    local p = G.player
    local maxStep = C.DPAD_DEG_PER_SEC * C.DT

    -- 1) survival: steer off anything about to cross our orbit
    local dodge = 0
    for _, b in ipairs(G.bullets) do
        if Vec.len(b.x, b.y) > 0.68 then
            local d = Vec.angleDiff(p.a, Vec.angleOf(b.x, b.y))
            if math.abs(d) < 18 then dodge = dodge - sgn(d) end
        end
    end
    for _, m in ipairs(G.meteors) do
        if m.r > 0.6 then
            local d = Vec.angleDiff(p.a, m.a)
            if math.abs(d) < 20 then dodge = dodge - sgn(d) end
        end
    end
    if G.beam and G.beam.active then
        local d = Vec.angleDiff(p.a, G.beam.a)
        if math.abs(d) < 26 then dodge = dodge - sgn(d) * 2 end
    end
    for _, e in ipairs(G.enemies) do
        if e.kind == "attack" and Vec.len(e.x, e.y) > 0.8 then
            local d = Vec.angleDiff(p.a, Vec.angleOf(e.x, e.y))
            if math.abs(d) < 14 then dodge = dodge - sgn(d) end
        end
    end
    if dodge ~= 0 then
        return clamp(dodge, -1, 1) * maxStep, true
    end

    -- 2) offense: swing toward the best target (favor whatever is out deep)
    local bestScore, bestA = -math.huge, nil
    for _, e in ipairs(G.enemies) do
        if e.delayT <= 0 then
            local ea = Vec.angleOf(e.x, e.y)
            local d = math.abs(Vec.angleDiff(p.a, ea))
            local s = Vec.len(e.x, e.y) * 2 - d / 90
            if s > bestScore then
                bestScore, bestA = s, ea
            end
        end
    end
    -- fire only when roughly on target, like a human would — otherwise the
    -- bot sweeps every squad out of the sky before a formation ever forms
    local move, fire = 0, false
    if bestA then
        local d = Vec.angleDiff(p.a, bestA)
        move = clamp(d, -maxStep, maxStep)
        fire = math.abs(d) < 30
    end
    -- periodic cease-fire so squads reach the hub and dive back out: the
    -- formation/attack-run half of the game never runs against a bot that
    -- shoots everything down on entry
    if G.time % 22 < 9 then fire = false end
    return move, fire
end

-- returns: moveDeg (ship degrees this frame), fire
function Input.gather()
    if Harness.enabled and Harness.autopilot then
        return Harness.autopilot()
    end

    local move = playdate.getCrankChange()
    if playdate.buttonIsPressed(playdate.kButtonLeft) then
        move = move + C.DPAD_DEG_PER_SEC * C.DT
    end
    if playdate.buttonIsPressed(playdate.kButtonRight) then
        move = move - C.DPAD_DEG_PER_SEC * C.DT
    end

    local fire = playdate.buttonIsPressed(playdate.kButtonA)
        or playdate.buttonIsPressed(playdate.kButtonB)
    return move, fire
end
