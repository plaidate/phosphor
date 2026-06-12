-- The lander: crank-set throttle, d-pad tilt, gravity, fuel, and the
-- touchdown/crash judgement against the terrain.

Lander = {}

local clamp = Util.clamp

function Lander.spawn()
    local dir = math.random() < 0.5 and -1 or 1
    G.lander = {
        x = dir > 0 and 30 or Field.W - 30,
        y = 26,
        vx = dir * (18 + math.random() * 14),
        vy = 6,
        tilt = 0,     -- degrees, 0 = upright, + leans right
        throttle = 0, -- 0..100 %
        thrust = 0,   -- fraction actually applied this frame
        dead = false,
    }
    G.mode = "fly"
    G.modeT = 0
    G.msg = nil
end

-- model-space point rotated by the lander's tilt, in screen space
local function pointAt(l, mx, my)
    local rad = math.rad(l.tilt)
    local c, s = math.cos(rad), math.sin(rad)
    return l.x + mx * c - my * s, l.y + mx * s + my * c
end

local HULL <const> = { { 0, -9 }, { -6, -2 }, { 6, -2 } }

local function land(pad)
    local l = G.lander
    l.y = pad.y - C.FOOT_Y
    l.tilt, l.vx, l.vy, l.throttle, l.thrust = 0, 0, 0, 0, 0

    local pts = C.BASE_SCORE * pad.mult + math.floor(G.fuel / 2)
    G.addScore(pts)
    G.fuel = math.min(G.fuel + C.FUEL_MAX * C.REFUEL_FRAC, C.FUEL_MAX)
    G.fuelOut = false
    G.mode = "landed"
    G.modeT = 2.4
    G.msg = "TOUCHDOWN X" .. pad.mult .. " +" .. pts
    Harness.count("landings")
    Sfx.fanfare()
end

local function crash()
    local l = G.lander
    l.dead = true
    l.thrust = 0
    G.landers = G.landers - 1
    G.mode = "crashed"
    G.modeT = 2.4
    G.msg = "CRASHED"
    Fx.debris(l.x, l.y, 9)
    Fx.burst(l.x, l.y, 12)
    Harness.count("crashes")
    Sfx.bigBoom()
end

local function checkContact()
    local l = G.lander
    local fx1, fy1 = pointAt(l, -C.FOOT_X, C.FOOT_Y)
    local fx2, fy2 = pointAt(l, C.FOOT_X, C.FOOT_Y)
    local feet = fy1 >= Terrain.heightAt(fx1) or fy2 >= Terrain.heightAt(fx2)

    local hull = false
    for _, m in ipairs(HULL) do
        local hx, hy = pointAt(l, m[1], m[2])
        if hy >= Terrain.heightAt(hx) then hull = true break end
    end
    if not (feet or hull) then return end

    local pad1, pad2 = Terrain.padUnder(fx1), Terrain.padUnder(fx2)
    local safe = not hull
        and pad1 ~= nil and pad1 == pad2
        and math.abs(l.vx) < C.SAFE_VX
        and l.vy < C.SAFE_VY and l.vy > -2
        and math.abs(l.tilt) < C.SAFE_TILT
    if safe then land(pad1) else crash() end
end

function Lander.update(turn, dThrottle, burn, dt)
    local l = G.lander
    l.tilt = clamp(l.tilt + turn, -C.MAX_TILT, C.MAX_TILT)
    l.throttle = clamp(l.throttle + dThrottle, 0, 100)

    local frac = burn and 1 or l.throttle / 100
    if G.fuel <= 0 then frac = 0 end
    l.thrust = frac
    if frac > 0 then
        G.fuel = math.max(G.fuel - C.BURN_RATE * frac * dt, 0)
        if G.fuel == 0 and not G.fuelOut then
            G.fuelOut = true
            Harness.count("fuelOuts")
            Sfx.descend()
        end
        local rad = math.rad(l.tilt)
        local a = C.MAX_THRUST * frac
        l.vx = l.vx + math.sin(rad) * a * dt
        l.vy = l.vy - math.cos(rad) * a * dt
        if Attract.frame % 3 == 0 then Sfx.thrustTick() end
    end

    l.vy = l.vy + C.GRAVITY * dt
    l.x = clamp(l.x + l.vx * dt, 6, Field.W - 6)
    if l.x <= 6 or l.x >= Field.W - 6 then l.vx = 0 end
    l.y = l.y + l.vy * dt
    if l.y < -40 then
        l.y = -40
        if l.vy < 0 then l.vy = 0 end
    end

    checkContact()
end

-- altitude of the feet above the ground directly below
function Lander.altitude()
    local l = G.lander
    if not l then return 0 end
    return math.max(0, Terrain.heightAt(l.x) - (l.y + C.FOOT_Y))
end
