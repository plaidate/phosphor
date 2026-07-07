-- The ship: rotation, thrust with momentum, firing, hyperspace, dying.

Ship = {}

local clamp = Util.clamp

function Ship.new()
    return {
        x = C.SCREEN_W / 2, y = C.SCREEN_H / 2,
        vx = 0, vy = 0,
        angle = -90, -- pointing up; degrees, 0 = right
        thrusting = false,
        fireT = 0,
        invuln = 2.2,
        alive = true,
    }
end

function Ship.dirVector()
    local rad = math.rad(G.ship.angle)
    return math.cos(rad), math.sin(rad)
end

function Ship.update(turn, thrust, fire, hyper)
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
        local speed = Vec.len(s.vx, s.vy)
        if speed > C.MAX_SPEED then
            s.vx = s.vx * C.MAX_SPEED / speed
            s.vy = s.vy * C.MAX_SPEED / speed
        end
        if Attract.frame % 4 == 0 then Sfx.thrustTick() end
    end

    s.vx = s.vx * C.DRAG
    s.vy = s.vy * C.DRAG
    s.x, s.y = Util.wrap(s.x + s.vx * C.DT, s.y + s.vy * C.DT)

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

    if hyper then
        Sfx.warble()
        if math.random(C.HYPERSPACE_DOOM) == 1 then
            Ship.kill(true) -- materialized inside a rock, the legend says
        else
            s.x = math.random(20, C.SCREEN_W - 20)
            s.y = math.random(20, C.SCREEN_H - 20)
            s.vx, s.vy = 0, 0
            s.invuln = 0.8
        end
    end
end

function Ship.kill(force)
    local s = G.ship
    if not s.alive or (s.invuln > 0 and not force) then return end
    s.alive = false
    G.lives = G.lives - 1
    G.respawnT = 2
    G.addDebris(s.x, s.y, 6)
    G.burst(s.x, s.y, 10)
    Sfx.bigBoom()
end

function Ship.respawn()
    -- wait for the center to be clear-ish
    for _, r in ipairs(G.rocks) do
        if Util.dist2(r.x, r.y, C.SCREEN_W / 2, C.SCREEN_H / 2) < 60 * 60 then
            G.respawnT = 0.5
            return false
        end
    end
    G.ship = Ship.new()
    return true
end

function Ship.updateShots()
    for i = #G.shots, 1, -1 do
        local b = G.shots[i]
        b.life = b.life - C.DT
        if b.life <= 0 then
            table.remove(G.shots, i)
        else
            b.x, b.y = Util.wrap(b.x + b.vx * C.DT, b.y + b.vy * C.DT)
        end
    end
end
