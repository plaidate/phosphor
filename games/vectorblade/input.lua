-- Fighter controls: the crank is the cabinet spinner (slides the ship), the
-- d-pad is a fallback, A fires, B drops a smart bomb. The smoke autopilot
-- chases drops, lines up on targets, dodges fire, and holds the trigger.

Input = {}

local clamp = Util.clamp

Harness.autopilot = function()
    local s = G.ship
    if not s or not s.alive then return 0, true, false end

    -- find the most urgent danger: a diver or bullet low and near in x
    local danger
    for _, e in ipairs(G.enemies) do
        if e.state == "dive" and e.y > s.y - 130 and math.abs(e.x - s.x) < 40 then
            danger = e.x
        end
    end
    for _, b in ipairs(G.eshots) do
        if b.vy > 0 and b.y > s.y - 110 and b.y < s.y and math.abs(b.x - s.x) < 14 then
            danger = b.x
        end
    end

    local target
    if danger then
        -- flee to whichever side has more room
        target = (danger > Field.W / 2) and (danger - 70) or (danger + 70)
    else
        -- grab the lowest falling bonus if there is one
        local by = -1
        for _, b in ipairs(G.bonuses) do
            if b.y > by then by, target = b.y, b.x end
        end
        -- else sit under formation/boss and keep firing up
        if not target then
            local best = math.huge
            for _, e in ipairs(G.enemies) do
                if e.state ~= "dive" then
                    local d = math.abs(e.x - s.x)
                    if d < best then best, target = d, e.x end
                end
            end
            if G.boss then target = G.boss.x end
            target = target or s.x
        end
    end

    local maxStep = C.DPAD_SPEED * C.DT
    local dx = clamp(target - s.x, -maxStep, maxStep)
    local bomb = (#G.enemies > 8 and math.random() < 0.02) and G.bombs > 0
    return dx, true, bomb
end

-- returns: dx (px of travel this frame), fire, bomb
function Input.gather()
    if Harness.enabled and Harness.autopilot then
        return Harness.autopilot()
    end

    local mul = 1 + G.speedLvl * 0.12
    local dx = playdate.getCrankChange() * C.CRANK_RATIO * mul
    local dpad = (C.DPAD_SPEED + G.speedLvl * C.MOVE_BONUS) * C.DT
    if playdate.buttonIsPressed(playdate.kButtonLeft) then dx = dx - dpad end
    if playdate.buttonIsPressed(playdate.kButtonRight) then dx = dx + dpad end

    local fire = playdate.buttonIsPressed(playdate.kButtonA)
    local bomb = playdate.buttonJustPressed(playdate.kButtonB)
    return dx, fire, bomb
end
