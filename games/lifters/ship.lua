-- Lifters: the defending ship. Crank spins it 1:1, B/up thrusts with mild
-- drag, A fires. No wrap — the edges give a gentle bounce so the fight
-- stays near the canisters. Ships are unlimited: dying only costs time.

Ship = {}

function Ship.new()
    return {
        x = C.HOME_X, y = C.HOME_Y,
        vx = 0, vy = 0,
        angle = -90, -- pointing up; degrees, 0 = right
        thrusting = false,
        fireT = 0,
        invuln = C.INVULN_T,
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
        local speed = math.sqrt(s.vx * s.vx + s.vy * s.vy)
        if speed > C.MAX_SPEED then
            s.vx = s.vx * C.MAX_SPEED / speed
            s.vy = s.vy * C.MAX_SPEED / speed
        end
        if Attract.frame % 4 == 0 then Sfx.thrustTick() end
    end

    s.vx = s.vx * C.DRAG
    s.vy = s.vy * C.DRAG
    s.x = s.x + s.vx * C.DT
    s.y = s.y + s.vy * C.DT

    -- gentle bounce off the arena edges
    if s.x < C.EDGE then
        s.x, s.vx = C.EDGE, math.abs(s.vx) * C.BOUNCE
    elseif s.x > Field.W - C.EDGE then
        s.x, s.vx = Field.W - C.EDGE, -math.abs(s.vx) * C.BOUNCE
    end
    if s.y < C.EDGE then
        s.y, s.vy = C.EDGE, math.abs(s.vy) * C.BOUNCE
    elseif s.y > Field.H - C.EDGE then
        s.y, s.vy = Field.H - C.EDGE, -math.abs(s.vy) * C.BOUNCE
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
        Harness.count("shots")
    end
end

function Ship.kill()
    local s = G.ship
    if not s.alive or s.invuln > 0 then return end
    s.alive = false
    G.respawnT = C.RESPAWN_T
    Fx.debris(s.x, s.y, 6)
    Fx.burst(s.x, s.y, 10)
    Sfx.bigBoom()
    Harness.count("deaths")
end

function Ship.respawn()
    -- wait for the pad to be clear-ish of raiders
    for _, rd in ipairs(G.raiders) do
        if rd.delay <= 0 and G.dist2(rd.x, rd.y, C.HOME_X, C.HOME_Y) < 50 * 50 then
            G.respawnT = 0.4
            return
        end
    end
    G.ship = Ship.new()
    Sfx.blip()
end

function Ship.updateShots()
    for i = #G.shots, 1, -1 do
        local b = G.shots[i]
        b.life = b.life - C.DT
        b.x = b.x + b.vx * C.DT
        b.y = b.y + b.vy * C.DT
        if b.life <= 0 or b.x < 0 or b.x > Field.W or b.y < 0 or b.y > Field.H then
            table.remove(G.shots, i)
        end
    end
end
