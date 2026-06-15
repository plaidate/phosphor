-- Elite controls, mapped from the NES scheme (see SetKeyLogger in the source
-- library): on the NES the d-pad rolls (left/right) and pitches (up/down), A
-- fires, and holding B turns up/down into throttle. Phosphor swaps roll onto
-- the crank — its signature control — and keeps the rest faithful:
--
--   CRANK            roll       (LEFT/RIGHT on the d-pad also rolls)
--   UP / DOWN        pitch
--   A                fire front laser
--   B + UP / DOWN    throttle up / down

Input = {}

local clamp = Util.clamp
local pd <const> = playdate

local function len3(x, y, z) return math.sqrt(x * x + y * y + z * z) end

-- The smoke autopilot: roll to put the current target on the vertical centre
-- line, pitch to bring it to the middle, fire when it is in the reticle, and
-- ease off the throttle to dock once the system is clear.
Harness.autopilot = function()
    G.fireMissile, G.useECM, G.useBomb = false, false, false
    -- choose a target: nearest pirate, else the station to dock
    local target, bestd = nil, math.huge
    for _, o in ipairs(G.objs) do
        if o.kind == "pirate" then
            local d = len3(o.pos.x, o.pos.y, o.pos.z)
            if d < bestd then bestd, target = d, o end
        end
    end
    local docking = false
    if not target and G.station then target, docking = G.station, true end

    local roll, pitch, fire = 0, 0, false
    if target then
        local p = target.pos
        if p.z <= 0 then
            -- behind us: pitch hard to swing it back into view
            pitch = C.PITCH_RATE
        else
            local sx, sy = Proj.point(p.x, p.y, p.z)
            if sx then
                local dx, dy = sx - Proj.cx, sy - Proj.cy
                -- Roll the target onto the nearest vertical (top if it's above,
                -- bottom if below), then pitch it down/up to the centre. Pitch
                -- only bites once the target is near that vertical axis, so the
                -- two axes don't fight. (+roll spins the view clockwise and
                -- +pitch lifts targets up the screen — see the probe in README.)
                local a = math.atan(dy, dx)
                local goal = (dy <= 0) and -math.pi / 2 or math.pi / 2
                local ea = a - goal
                while ea > math.pi do ea = ea - 2 * math.pi end
                while ea < -math.pi do ea = ea + 2 * math.pi end
                roll = clamp(-ea * 1.6, -1, 1) * C.ROLL_RATE
                local aligned = 1 - clamp(math.abs(dx) / 45, 0, 1)
                pitch = clamp(dy * 0.04, -1, 1) * aligned * C.PITCH_RATE
                if dx * dx + dy * dy < (C.LASER_HIT_PX * 1.4) ^ 2 then
                    fire = not docking
                    -- occasionally loose a missile at a lined-up hostile
                    if fire and G.missiles > 0 and math.random() < 0.01 then
                        G.fireMissile = true
                    end
                end
            end
        end
        -- throttle: charge hostiles, crawl in to dock
        local want = docking and C.SPEED_DOCK * 0.8 or C.SPEED_CRUISE
        G.speed = G.speed + clamp(want - G.speed, -C.SPEED_STEP * 0.5, C.SPEED_STEP * 0.5)
    end
    return roll, pitch, fire
end

-- returns: roll (rad/s), pitch (rad/s), fire. Throttle is applied to G.speed
-- here since it integrates over time.
function Input.gather()
    if Harness.enabled and Harness.autopilot then
        return Harness.autopilot()
    end

    local dt = Attract.dt
    local bHeld = pd.buttonIsPressed(pd.kButtonB)

    local roll = pd.getCrankChange() * C.CRANK_ROLL / dt
    local pitch = 0
    local fire = false
    G.fireMissile, G.useECM, G.useBomb = false, false, false

    if bHeld then
        -- B is the secondary-functions modifier (throttle + weapons)
        if pd.buttonIsPressed(pd.kButtonUp) then G.speed = G.speed + C.SPEED_STEP * dt end
        if pd.buttonIsPressed(pd.kButtonDown) then G.speed = G.speed - C.SPEED_STEP * dt end
        if pd.buttonJustPressed(pd.kButtonA) then G.fireMissile = true end
        if pd.buttonJustPressed(pd.kButtonLeft) then G.useECM = true end
        if pd.buttonJustPressed(pd.kButtonRight) then G.useBomb = true end
    else
        -- left/right roll (crank too); up = climb (nose up); A fires the laser
        if pd.buttonIsPressed(pd.kButtonLeft) then roll = roll - C.ROLL_RATE end
        if pd.buttonIsPressed(pd.kButtonRight) then roll = roll + C.ROLL_RATE end
        if pd.buttonIsPressed(pd.kButtonUp) then pitch = pitch - C.PITCH_RATE end
        if pd.buttonIsPressed(pd.kButtonDown) then pitch = pitch + C.PITCH_RATE end
        fire = pd.buttonIsPressed(pd.kButtonA)
    end
    G.speed = clamp(G.speed, 0, C.SPEED_MAX)
    return roll, pitch, fire
end
