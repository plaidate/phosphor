-- The ship: rotation, thrust with momentum, firing, dying, safe respawn.
-- Same feel as Rubble: crank spins 1:1, thrust carries, drag bleeds it off,
-- the screen wraps.

Ship = {}

local clamp = Util.clamp

function Ship.new(x, y)
    return {
        x = x or C.CX + 110, y = y or C.CY,
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
        local bx, by = s.x + dx * 7, s.y + dy * 7
        G.shots[#G.shots + 1] = {
            x = bx, y = by,
            vx = dx * C.SHOT_SPEED + s.vx,
            vy = dy * C.SHOT_SPEED + s.vy,
            life = C.SHOT_LIFE,
            pd = Vec.len(bx - C.CX, by - C.CY), -- radial distance, for ring crossings
        }
        Sfx.pew()
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
    Harness.count("deaths")
    Castle.onShipDeath()
end

-- respawn at a safe distance from the keep, clear of mines and fireball
function Ship.respawn()
    local x, y
    for _ = 1, 24 do
        local a = math.random() * math.pi * 2
        local rr = C.RESPAWN_R_MIN + math.random() * (C.RESPAWN_R_MAX - C.RESPAWN_R_MIN)
        x = clamp(C.CX + math.cos(a) * rr, 14, C.SCREEN_W - 14)
        y = clamp(C.CY + math.sin(a) * rr, 14, C.SCREEN_H - 14)
        local clear = true
        if G.fireball and Field.dist2(x, y, G.fireball.x, G.fireball.y) < 70 * 70 then
            clear = false
        end
        for _, m in ipairs(G.mines) do
            if m.state ~= "dead" and Field.dist2(x, y, m.x, m.y) < 60 * 60 then
                clear = false
            end
        end
        if clear then break end
    end
    G.ship = Ship.new(x, y)
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
