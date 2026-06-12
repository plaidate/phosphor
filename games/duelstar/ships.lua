-- Duelstar ships: two piece-built silhouettes sharing one physics core.
-- Each ship is a list of separate polyline pieces; a hit knocks a whole
-- piece off the outline (the classic damage look) and the last hit kills.
-- Also home to the sun's gravity, shots, and all combat collision.

Ships = {}

local clamp = Util.clamp

-- model-space pieces, nose along +x
local PIECES <const> = {
    player = {
        { 9, 0, -7, -6 },          -- port hull line
        { 9, 0, -7, 6 },           -- starboard hull line
        { -7, -6, -4, 0, -7, 6 },  -- engine crossbar
        { 3, -2, -1, 0, 3, 2 },    -- cockpit chevron
    },
    rival = {
        { 12, 0, -8, 0 },          -- needle spine
        { 4, -1, -9, -7, -5, 0 },  -- swept port wing
        { 4, 1, -9, 7, -5, 0 },    -- swept starboard wing
        { -8, -4, -4, 0, -8, 4 },  -- tail fork
    },
}

function Ships.new(kind, x, y, vx, vy, angle)
    local shape = {}
    for i, p in ipairs(PIECES[kind]) do shape[i] = p end
    return {
        kind = kind,
        x = x, y = y, vx = vx, vy = vy,
        angle = angle % 360,
        hp = C.HITS,
        shape = shape,
        alive = true,
        thrusting = false,
        invuln = C.SPAWN_INVULN,
        fireT = 0,
    }
end

-- sun pull at a point; capped so close passes slingshot instead of exploding
function Ships.gravity(x, y)
    local dx, dy = C.SUN_X - x, C.SUN_Y - y
    local d2 = dx * dx + dy * dy
    if d2 < 16 then return 0, 0 end
    local d = math.sqrt(d2)
    local a = math.min(C.GRAV_MU / d2, C.GRAV_MAX)
    return dx / d * a, dy / d * a
end

-- shortest wrapped vector from a to b
function Ships.wrapDelta(ax, ay, bx, by)
    local dx, dy = bx - ax, by - ay
    if dx > Field.W / 2 then dx = dx - Field.W elseif dx < -Field.W / 2 then dx = dx + Field.W end
    if dy > Field.H / 2 then dy = dy - Field.H elseif dy < -Field.H / 2 then dy = dy + Field.H end
    return dx, dy
end

-- +1 if s circles the sun counterclockwise (screen sense), else -1
function Ships.tangentSide(s)
    local rx, ry = s.x - C.SUN_X, s.y - C.SUN_Y
    return (rx * s.vy - ry * s.vx) >= 0 and 1 or -1
end

-- gravity-aware firing solution: aim at where the target will be over the
-- shot's flight time, minus where the shot itself will be bent. Returns
-- the aim angle (degrees) and the current wrapped distance.
function Ships.leadAngle(shooter, target)
    local dx, dy = Ships.wrapDelta(shooter.x, shooter.y, target.x, target.y)
    local d = Vec.len(dx, dy)
    local t = d / C.SHOT_SPEED
    local rvx, rvy = target.vx - shooter.vx, target.vy - shooter.vy
    local gx, gy = Ships.gravity(target.x, target.y)
    local sgx, sgy = Ships.gravity(shooter.x, shooter.y)
    local fx = dx + rvx * t + 0.5 * (gx - sgx) * t * t
    local fy = dy + rvy * t + 0.5 * (gy - sgy) * t * t
    return Vec.angleOf(fx, fy), d
end

-- coast the ship forward on gravity alone; returns frames until sun impact
-- within ~0.9s, or nil if the current path is safe
function Ships.sunDanger(s)
    local x, y, vx, vy = s.x, s.y, s.vx, s.vy
    local rr = C.SUN_KILL_R + C.SHIP_R
    rr = rr * rr
    for i = 1, 27 do
        local gx, gy = Ships.gravity(x, y)
        vx, vy = vx + gx * C.DT, vy + gy * C.DT
        x, y = x + vx * C.DT, y + vy * C.DT
        local dx, dy = x - C.SUN_X, y - C.SUN_Y
        if dx * dx + dy * dy < rr then return i end
    end
    return nil
end

-- one frame of piloted physics; turn in degrees, the rest booleans
function Ships.control(s, turn, thrust, fire, hyper, shots)
    if not s.alive then return end
    local dt = C.DT
    if s.invuln > 0 then s.invuln = s.invuln - dt end
    if s.fireT > 0 then s.fireT = s.fireT - dt end

    local lame = s.hp <= 1 -- one hit left: the ship handles worse
    s.angle = (s.angle + turn * (lame and C.LAME_TURN or 1)) % 360

    local dx, dy = Vec.fromAngle(s.angle)
    s.thrusting = thrust and true or false
    if thrust then
        local push = C.THRUST * (lame and C.LAME_THRUST or 1) * dt
        s.vx = s.vx + dx * push
        s.vy = s.vy + dy * push
        if s.kind == "player" and Attract.frame % 4 == 0 then Sfx.thrustTick() end
    end

    local gx, gy = Ships.gravity(s.x, s.y)
    s.vx = (s.vx + gx * dt) * C.DRAG
    s.vy = (s.vy + gy * dt) * C.DRAG
    local speed = Vec.len(s.vx, s.vy)
    if speed > C.MAX_SPEED then
        s.vx = s.vx * C.MAX_SPEED / speed
        s.vy = s.vy * C.MAX_SPEED / speed
    end
    s.x, s.y = Field.wrap(s.x + s.vx * dt, s.y + s.vy * dt)

    if fire and s.fireT <= 0 and #shots < C.MAX_SHOTS then
        s.fireT = C.FIRE_COOLDOWN
        shots[#shots + 1] = {
            x = s.x + dx * 10, y = s.y + dy * 10,
            vx = dx * C.SHOT_SPEED + s.vx,
            vy = dy * C.SHOT_SPEED + s.vy,
            life = C.SHOT_LIFE,
            trail = {},
        }
        Sfx.pew(s.kind == "player" and 880 or 520)
    end

    if hyper then
        Sfx.warble()
        if math.random(C.HYPERSPACE_DOOM) == 1 then
            Ships.kill(s) -- rematerialized inside the sun's corona, the legend says
        else
            local hx, hy
            repeat
                hx = math.random(20, Field.W - 20)
                hy = math.random(20, Field.H - 20)
            until Field.dist2(hx, hy, C.SUN_X, C.SUN_Y) > C.HYPER_MIN_SUN * C.HYPER_MIN_SUN
            s.x, s.y, s.vx, s.vy = hx, hy, 0, 0
            s.invuln = math.max(s.invuln, 0.8)
        end
    end
end

-- pilotless physics for the between-rounds pause
function Ships.drift(s)
    if not s or not s.alive then return end
    s.thrusting = false
    local gx, gy = Ships.gravity(s.x, s.y)
    s.vx, s.vy = s.vx + gx * C.DT, s.vy + gy * C.DT
    s.x, s.y = Field.wrap(s.x + s.vx * C.DT, s.y + s.vy * C.DT)
end

function Ships.updateShots(shots)
    for i = #shots, 1, -1 do
        local b = shots[i]
        b.life = b.life - C.DT
        if b.life <= 0 then
            table.remove(shots, i)
        else
            local t = b.trail
            table.insert(t, 1, b.y)
            table.insert(t, 1, b.x)
            if #t > C.TRAIL_LEN * 2 then
                table.remove(t)
                table.remove(t)
            end
            local gx, gy = Ships.gravity(b.x, b.y)
            b.vx, b.vy = b.vx + gx * C.DT, b.vy + gy * C.DT
            local nx, ny = Field.wrap(b.x + b.vx * C.DT, b.y + b.vy * C.DT)
            if math.abs(nx - b.x) > 60 or math.abs(ny - b.y) > 60 then
                b.trail = {} -- crossed the wrap seam; don't streak the screen
            end
            b.x, b.y = nx, ny
        end
    end
end

-- one hit: a random piece of the outline breaks away; the last hit kills.
-- Returns true if damage landed.
function Ships.hit(s)
    if not s.alive or s.invuln > 0 then return false end
    s.hp = s.hp - 1
    if s.hp <= 0 then
        Ships.kill(s)
    else
        table.remove(s.shape, math.random(#s.shape))
        s.invuln = C.HIT_INVULN
        Fx.debris(s.x, s.y, 3)
        Fx.burst(s.x, s.y, 4)
        Sfx.boom(1)
    end
    return true
end

function Ships.kill(s)
    if not s.alive then return end
    s.alive = false
    Fx.debris(s.x, s.y, 7)
    Fx.burst(s.x, s.y, 12)
    Sfx.bigBoom()
end

local function shotsVsShip(shots, ship, onHit)
    if not ship.alive or ship.invuln > 0 then return end
    local rr = (C.SHIP_R + C.SHOT_R) * (C.SHIP_R + C.SHOT_R)
    for i = #shots, 1, -1 do
        local b = shots[i]
        if Field.dist2(b.x, b.y, ship.x, ship.y) < rr then
            table.remove(shots, i)
            Fx.burst(b.x, b.y, 3)
            if Ships.hit(ship) and onHit then onHit() end
        end
    end
end

local function sunEatsShots(shots)
    local rr = (C.SUN_R + 2) * (C.SUN_R + 2)
    for i = #shots, 1, -1 do
        local b = shots[i]
        if Field.dist2(b.x, b.y, C.SUN_X, C.SUN_Y) < rr then
            Fx.burst(b.x, b.y, 3)
            table.remove(shots, i)
        end
    end
end

function Ships.collide()
    local p, r = G.player, G.rival

    shotsVsShip(G.pShots, r, function()
        G.addScore(C.PTS_HIT)
        Harness.count("hits")
    end)
    shotsVsShip(G.rShots, p, function()
        Harness.count("taken")
    end)
    sunEatsShots(G.pShots)
    sunEatsShots(G.rShots)

    -- the sun spares no one, blinking or not
    local rr = (C.SUN_KILL_R + C.SHIP_R) * (C.SUN_KILL_R + C.SHIP_R)
    if p.alive and Field.dist2(p.x, p.y, C.SUN_X, C.SUN_Y) < rr then Ships.kill(p) end
    if r.alive and Field.dist2(r.x, r.y, C.SUN_X, C.SUN_Y) < rr then Ships.kill(r) end

    -- hull to hull: both take a hit and bounce apart
    if p.alive and r.alive and Field.dist2(p.x, p.y, r.x, r.y) < (2 * C.SHIP_R) * (2 * C.SHIP_R) then
        local dx, dy = Ships.wrapDelta(p.x, p.y, r.x, r.y)
        local nx, ny = Vec.norm(dx, dy)
        p.vx, p.vy = p.vx - nx * 130, p.vy - ny * 130
        r.vx, r.vy = r.vx + nx * 130, r.vy + ny * 130
        Ships.hit(p)
        Ships.hit(r)
        Sfx.boom(2)
    end
end
