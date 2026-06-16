-- Open Geometry Wars: the player ship — d-pad thrust, crank-aimed autofire
-- with three weapon patterns, smart bombs, and death/respawn. The ship dimples
-- the grid under it (a shield well while invulnerable, a wake otherwise), and
-- its shots ripple the mesh and bend toward black holes.

Player = {}

local clamp = Util.clamp

function Player.new()
    return {
        x = Field.W / 2, y = Field.H / 2,
        vx = 0, vy = 0,
        aim = -90,          -- degrees, screen space (0 = right, 90 = down)
        invuln = C.SPAWN_INVULN,
        fireT = 0,
        alt = false,        -- weapon-1 alternation toggle
        alive = true,
    }
end

function Player.respawn()
    G.ship = Player.new()
    Grid.push(Field.W / 2, Field.H / 2, 220, 110)
end

function Player.update(dt, mvx, mvy, aimDeg, bomb)
    local s = G.ship
    if not s.alive then return end

    s.aim = aimDeg

    if mvx ~= 0 or mvy ~= 0 then
        s.vx = s.vx + mvx * C.MOVE_ACCEL * dt
        s.vy = s.vy + mvy * C.MOVE_ACCEL * dt
    else
        s.vx, s.vy = s.vx * C.MOVE_DRAG, s.vy * C.MOVE_DRAG
    end
    local sp = Vec.len(s.vx, s.vy)
    if sp > C.MOVE_MAX then s.vx, s.vy = s.vx / sp * C.MOVE_MAX, s.vy / sp * C.MOVE_MAX end

    s.x = clamp(s.x + s.vx * dt, C.SHIP_R, Field.W - C.SHIP_R)
    s.y = clamp(s.y + s.vy * dt, C.SHIP_R, Field.H - C.SHIP_R)

    if s.invuln > 0 then
        s.invuln = s.invuln - dt
        Grid.pull(s.x, s.y, 90, 36) -- the shield bends the lattice inward
    else
        Grid.push(s.x, s.y, 26 + sp * 0.08, 46) -- wake
    end

    s.fireT = s.fireT - dt
    if s.fireT <= 0 then s.fireT = Player.fire() end

    if bomb then Player.bomb() end
end

local function launch(angleDeg, speed)
    if #G.shots >= C.MAX_SHOTS then return end
    local s = G.ship
    local dx, dy = Vec.fromAngle(angleDeg, speed)
    local px, py = Vec.fromAngle(angleDeg, C.SHIP_R + 2)
    G.shots[#G.shots + 1] = {
        x = s.x + px, y = s.y + py,
        vx = dx + s.vx, vy = dy + s.vy,
        life = C.SHOT_LIFE,
    }
end

-- fire the current weapon; returns the cooldown until the next volley
function Player.fire()
    local s = G.ship
    local w = G.weapon
    local def = C.WEAPONS[w]
    if w == 0 then
        -- twin parallel-ish barrels
        launch(s.aim - 5, def.speed)
        launch(s.aim + 5, def.speed)
        Sfx.pew(960)
        return def.cd
    elseif w == 1 then
        -- alternating: a wide pair, then a fast single
        s.alt = not s.alt
        if s.alt then
            launch(s.aim - 14, def.speed)
            launch(s.aim + 14, def.speed)
            Sfx.pew(1040)
            return 0.067
        else
            launch(s.aim, def.speed)
            Sfx.pew(1180)
            return 0.033
        end
    else
        -- five-way fan
        for _, off in ipairs({ -12, -6, 0, 6, 12 }) do
            launch(s.aim + off, def.speed)
        end
        Sfx.pew(820)
        return def.cd
    end
end

function Player.bomb()
    if G.bombs <= 0 or G.bombT > 0 then return end
    G.bombs = G.bombs - 1
    G.bombT = C.BOMB_COOLDOWN
    local s = G.ship
    G.bombWave = { x = s.x, y = s.y, r = 8 }
    Grid.push(s.x, s.y, 600, 160)
    Fx.burst(s.x, s.y, 60, 160)
    Fx.flash(0.18)
    Sfx.bigBoom()
    Harness.count("bombs")
end

function Player.kill()
    local s = G.ship
    if not s or not s.alive or s.invuln > 0 then return end
    s.alive = false
    G.lives = G.lives - 1
    G.loseMultiplier()
    Fx.burst(s.x, s.y, 90, 180)
    Fx.debris(s.x, s.y, 10)
    Grid.push(s.x, s.y, 480, 150)
    Fx.flash(0.2)
    Sfx.descend()
    G.respawnT = C.RESPAWN_DELAY
    Harness.count("deaths")
end

-- nearest live black hole to (x,y), for homing
local function nearestHole(x, y)
    local best, bd = nil, C.HOLE_HOMING_DIST * C.HOLE_HOMING_DIST
    for _, e in ipairs(G.enemies) do
        if e.kind == "hole" and e.warn <= 0 then
            local d = (e.x - x) ^ 2 + (e.y - y) ^ 2
            if d < bd then bd, best = d, e end
        end
    end
    return best
end

function Player.updateShots(dt)
    local shots = G.shots
    for i = #shots, 1, -1 do
        local b = shots[i]
        -- bend toward a nearby black hole
        local h = nearestHole(b.x, b.y)
        if h then
            local sp = Vec.len(b.vx, b.vy)
            local cur = Vec.angleOf(b.vx, b.vy)
            local want = Vec.angleOf(h.x - b.x, h.y - b.y)
            local na = cur + Vec.angleDiff(cur, want) * C.HOLE_HOMING_RATE
            b.vx, b.vy = Vec.fromAngle(na, sp)
        end
        b.life = b.life - dt
        b.x = b.x + b.vx * dt
        b.y = b.y + b.vy * dt
        if b.life <= 0 or b.x < 0 or b.x > Field.W or b.y < 0 or b.y > Field.H then
            if b.life > 0 then Grid.push(b.x, b.y, 70, 30) end
            table.remove(shots, i)
        else
            Grid.push(b.x, b.y, 16, 22)
        end
    end
end
