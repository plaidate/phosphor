-- Gravity Wells, scale A: the system view. A lethal star at center pulls
-- constantly; four statically-orbiting planets wait to be raided. The screen
-- does not wrap — a gentle pull keeps the ship in bounds. Fly into an
-- uncleared planet's circle to drop into its mission.

System = {}

local clamp = Util.clamp

function System.newPlanets()
    G.planets = {}
    -- orbit radius, base angle (degrees); jittered each system
    local defs = { { 85, 30 }, { 85, 150 }, { 100, 230 }, { 100, 310 } }
    -- the signature twist: from system 2 on, one planet's gravity is reversed
    local rev = (G.system >= 2) and math.random(4) or 0
    for i, d in ipairs(defs) do
        local orbitR = d[1] + math.random(-8, 8)
        local a = math.rad(d[2] + math.random(-12, 12))
        local p = {
            x = clamp(C.STAR_X + math.cos(a) * orbitR, 34, Field.W - 34),
            y = clamp(C.STAR_Y + math.sin(a) * orbitR, 34, Field.H - 34),
            r = 15 + i,
            orbitR = orbitR,
            kind = i,
            cleared = false,
            revGrav = (i == rev),
            mission = nil,
        }
        p.ring = Shapes.gon(p.r, 18)
        G.planets[i] = p
    end
end

function System.respawn()
    local x = (math.random(2) == 1) and 70 or Field.W - 70
    local y = 48
    -- tangential drift so a fresh ship doesn't fall straight into the star
    local nx, ny = Vec.norm(x - C.STAR_X, y - C.STAR_Y)
    local vx, vy = -ny * 42, nx * 42
    Ship.spawn(x, y, vx, vy, Vec.angleOf(vx, vy))
    G.view = "system"
end

function System.allCleared()
    for _, p in ipairs(G.planets) do
        if not p.cleared then return false end
    end
    return #G.planets > 0
end

function System.nextSystem()
    G.system = G.system + 1
    Harness.count("systems")
    System.newPlanets()
    G.message("SYSTEM " .. G.system .. " - GRAVITY RISES", 2.6)
    Sfx.fanfare({ 523, 659, 784, 1047, 1319 })
end

function System.starG()
    return C.STAR_G + (G.system - 1) * C.STAR_G_PER_SYS
end

function System.update(dt)
    local s = G.ship
    if s.alive then
        local turn, thrust, fire = Input.gather()
        Ship.control(turn, thrust, fire, dt)

        -- the star never lets go
        local nx, ny, d = Vec.norm(C.STAR_X - s.x, C.STAR_Y - s.y)
        local g = System.starG()
        s.vx = s.vx + nx * g * dt
        s.vy = s.vy + ny * g * dt

        -- soft boundary: gentle pull back toward the playfield
        local M = C.EDGE_MARGIN
        if s.x < M then s.vx = s.vx + C.EDGE_PULL * dt
        elseif s.x > Field.W - M then s.vx = s.vx - C.EDGE_PULL * dt end
        if s.y < M then s.vy = s.vy + C.EDGE_PULL * dt
        elseif s.y > Field.H - M then s.vy = s.vy - C.EDGE_PULL * dt end

        Ship.integrate(dt, C.SYS_MAX_SPEED)

        -- last-resort cushion at the absolute edge
        if s.x < 3 then s.x = 3 if s.vx < 0 then s.vx = -s.vx * 0.5 end end
        if s.x > Field.W - 3 then s.x = Field.W - 3 if s.vx > 0 then s.vx = -s.vx * 0.5 end end
        if s.y < 3 then s.y = 3 if s.vy < 0 then s.vy = -s.vy * 0.5 end end
        if s.y > Field.H - 3 then s.y = Field.H - 3 if s.vy > 0 then s.vy = -s.vy * 0.5 end end

        if d < C.STAR_R + C.SHIP_R then
            Ship.kill(true)
        end

        if s.alive then
            for _, p in ipairs(G.planets) do
                if not p.cleared then
                    local dx, dy = s.x - p.x, s.y - p.y
                    if dx * dx + dy * dy < (p.r - 3) * (p.r - 3) then
                        Mission.enter(p)
                        return
                    end
                end
            end
        end
    end

    Ship.updateShots(dt, function(b)
        if b.x < 0 or b.x > Field.W or b.y < 0 or b.y > Field.H then return true end
        local dx, dy = b.x - C.STAR_X, b.y - C.STAR_Y
        if dx * dx + dy * dy < C.STAR_R * C.STAR_R then return true end
        for _, p in ipairs(G.planets) do
            local px, py = b.x - p.x, b.y - p.y
            if px * px + py * py < p.r * p.r then return true end
        end
        return false
    end)
end
