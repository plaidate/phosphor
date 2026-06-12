-- The ship: crank steering, frictionless coasting, lossy wall bounces,
-- and four live shots that ricochet around the track at full speed.

Ship = {}

local clamp = Util.clamp

-- plain euclidean distance: the arena has walls, never wrap-aware math
local function dist2(ax, ay, bx, by)
    local dx, dy = ax - bx, ay - by
    return dx * dx + dy * dy
end

function Ship.new(x, y)
    return {
        x = x or Arena.SPAWN_X, y = y or Arena.SPAWN_Y,
        vx = 0, vy = 0,
        angle = 0, -- facing along the home straight; degrees, 0 = right
        thrusting = false,
        fireT = 0,
        invuln = 2.2,
        alive = true,
        r = C.SHIP_R,
    }
end

function Ship.dirVector()
    local rad = math.rad(G.ship.angle)
    return math.cos(rad), math.sin(rad)
end

function Ship.update(turn, thrust, fire)
    local s = G.ship
    if not s.alive then return end

    if s.invuln > 0 then s.invuln = s.invuln - C.DT end
    if s.fireT > 0 then s.fireT = s.fireT - C.DT end

    s.angle = (s.angle + turn) % 360

    s.thrusting = thrust
    if thrust then
        local dx, dy = Ship.dirVector()
        s.vx = s.vx + dx * C.THRUST * C.DT
        s.vy = s.vy + dy * C.THRUST * C.DT
        local speed = math.sqrt(s.vx * s.vx + s.vy * s.vy)
        if speed > C.MAX_SPEED then
            s.vx = s.vx * C.MAX_SPEED / speed
            s.vy = s.vy * C.MAX_SPEED / speed
        end
        if Attract.frame % 4 == 0 then Sfx.thrustTick() end
    end

    -- no drag: the ship coasts until it hits something
    s.x = s.x + s.vx * C.DT
    s.y = s.y + s.vy * C.DT
    local ovx, ovy = s.vx, s.vy
    if Arena.bounce(s, C.SHIP_R, C.SHIP_BOUNCE) then
        -- spark and thump only on a real impact, not a wall graze
        if math.abs(s.vx - ovx) + math.abs(s.vy - ovy) > 30 then
            Arena.spark(s.x, s.y)
            Sfx.boom(1)
        end
    end

    if fire and s.fireT <= 0 and #G.shots < C.MAX_SHOTS then
        s.fireT = C.FIRE_COOLDOWN
        local dx, dy = Ship.dirVector()
        G.shots[#G.shots + 1] = {
            x = s.x + dx * 7, y = s.y + dy * 7,
            vx = dx * C.SHOT_SPEED + s.vx,
            vy = dy * C.SHOT_SPEED + s.vy,
            life = C.SHOT_LIFE,
        }
        Sfx.pew()
    end
end

function Ship.kill()
    local s = G.ship
    if not s.alive or s.invuln > 0 then return end
    s.alive = false
    G.lives = G.lives - 1
    G.respawnT = 2
    Fx.debris(s.x, s.y, 7)
    Fx.burst(s.x, s.y, 10)
    Sfx.bigBoom()
    Harness.count("deaths")
end

-- try a few spots along the bottom gutter until one is clear
local SPOTS <const> = { 0, -60, 60, -120, 120 }

function Ship.respawn()
    for _, off in ipairs(SPOTS) do
        local x, y = Arena.SPAWN_X + off, Arena.SPAWN_Y
        local clear = true
        for _, d in ipairs(G.drones) do
            if dist2(d.x, d.y, x, y) < 60 * 60 then clear = false break end
        end
        if clear then
            for _, l in ipairs(G.layers) do
                if dist2(l.x, l.y, x, y) < 60 * 60 then clear = false break end
            end
        end
        if clear then
            for _, m in ipairs(G.mines) do
                if dist2(m.x, m.y, x, y) < 28 * 28 then clear = false break end
            end
        end
        if clear then
            G.ship = Ship.new(x, y)
            return true
        end
    end
    G.respawnT = 0.5
    return false
end

function Ship.updateShots()
    for i = #G.shots, 1, -1 do
        local b = G.shots[i]
        b.life = b.life - C.DT
        if b.life <= 0 then
            table.remove(G.shots, i)
        else
            b.x = b.x + b.vx * C.DT
            b.y = b.y + b.vy * C.DT
            if Arena.bounce(b, 2, 1) then
                Arena.spark(b.x, b.y)
                Sfx.blip(220)
            end
        end
    end
end
