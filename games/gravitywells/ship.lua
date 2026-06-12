-- The ship, shared by both scales: crank rotation 1:1, thrust with momentum
-- and NO drag, fuel that burns on every thrust, firing, and dying. The view
-- modules add their own gravity and decide what the shots can hit.

Ship = {}

function Ship.spawn(x, y, vx, vy, angle)
    G.ship = {
        x = x, y = y,
        vx = vx or 0, vy = vy or 0,
        angle = angle or -90, -- degrees, 0 = right
        thrusting = false,
        fireT = 0,
        invuln = 2.2,
        alive = true,
    }
    G.shots = {}
end

-- rotation, thrust (burns fuel), firing. Gravity is the caller's business.
function Ship.control(turn, thrust, fire, dt)
    local s = G.ship
    if s.invuln > 0 then s.invuln = s.invuln - dt end
    if s.fireT > 0 then s.fireT = s.fireT - dt end

    s.angle = (s.angle + turn) % 360

    s.thrusting = false
    if thrust and G.fuel > 0 then
        s.thrusting = true
        local rad = math.rad(s.angle)
        local dx, dy = math.cos(rad), math.sin(rad)
        s.vx = s.vx + dx * C.THRUST * dt
        s.vy = s.vy + dy * C.THRUST * dt
        G.fuel = math.max(0, G.fuel - C.FUEL_BURN * dt)
        if G.fuel <= 0 and not G.fuelOut then
            G.fuelOut = true
            Harness.count("fuelOuts")
            G.message("OUT OF FUEL", 2.2)
            Sfx.descend()
        end
        if Attract.frame % 4 == 0 then Sfx.thrustTick() end
    end

    if fire and s.fireT <= 0 and #G.shots < C.MAX_SHOTS then
        s.fireT = C.FIRE_COOLDOWN
        local rad = math.rad(s.angle)
        local dx, dy = math.cos(rad), math.sin(rad)
        G.shots[#G.shots + 1] = {
            x = s.x + dx * 7, y = s.y + dy * 7,
            vx = dx * C.SHOT_SPEED + s.vx,
            vy = dy * C.SHOT_SPEED + s.vy,
            life = C.SHOT_LIFE,
        }
        Sfx.pew()
    end
end

function Ship.integrate(dt, maxSpeed)
    local s = G.ship
    local sp = Vec.len(s.vx, s.vy)
    if sp > maxSpeed then
        s.vx = s.vx * maxSpeed / sp
        s.vy = s.vy * maxSpeed / sp
    end
    s.x = s.x + s.vx * dt
    s.y = s.y + s.vy * dt
end

function Ship.kill(force)
    local s = G.ship
    if not s.alive or (s.invuln > 0 and not force) then return end
    s.alive = false
    s.thrusting = false
    G.ships = G.ships - 1
    G.deadT = 2.2
    G.fxBurst(s.x, s.y, 12)
    G.fxDebris(s.x, s.y, 7)
    Harness.count("deaths")
    Sfx.bigBoom()
end

-- move shots; hitFn(b) returns true when the shot is consumed
function Ship.updateShots(dt, hitFn)
    for i = #G.shots, 1, -1 do
        local b = G.shots[i]
        b.life = b.life - dt
        if b.life <= 0 then
            table.remove(G.shots, i)
        else
            b.x = b.x + b.vx * dt
            b.y = b.y + b.vy * dt
            if hitFn and hitFn(b) then
                table.remove(G.shots, i)
            end
        end
    end
end
