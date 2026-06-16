-- Open Geometry Wars: the player ship — d-pad thrust, crank-aimed autofire,
-- smart bombs, and death/respawn. The ship continuously dimples the grid
-- under it, so the mesh swells around you as you fly.

Player = {}

local clamp = Util.clamp

function Player.new()
    return {
        x = Field.W / 2, y = Field.H / 2,
        vx = 0, vy = 0,
        aim = -90,          -- degrees, screen space (0 = right, 90 = down)
        invuln = C.SPAWN_INVULN,
        fireT = 0,
        alive = true,
    }
end

function Player.respawn()
    G.ship = Player.new()
    -- a respawn shoves the grid outward like a soft bomb
    Grid.push(Field.W / 2, Field.H / 2, 220, 110)
end

-- mvx,mvy: normalised move vector (or 0); aimDeg: absolute aim; fire/bomb flags
function Player.update(dt, mvx, mvy, aimDeg, bomb)
    local s = G.ship
    if not s.alive then return end

    s.aim = aimDeg

    if mvx ~= 0 or mvy ~= 0 then
        s.vx = s.vx + mvx * C.MOVE_ACCEL * dt
        s.vy = s.vy + mvy * C.MOVE_ACCEL * dt
    else
        s.vx = s.vx * C.MOVE_DRAG
        s.vy = s.vy * C.MOVE_DRAG
    end
    local sp = Vec.len(s.vx, s.vy)
    if sp > C.MOVE_MAX then
        s.vx, s.vy = s.vx / sp * C.MOVE_MAX, s.vy / sp * C.MOVE_MAX
    end

    s.x = clamp(s.x + s.vx * dt, C.SHIP_R, Field.W - C.SHIP_R)
    s.y = clamp(s.y + s.vy * dt, C.SHIP_R, Field.H - C.SHIP_R)

    -- the ship's wake: push the lattice away from the hull each frame
    Grid.push(s.x, s.y, 26 + sp * 0.08, 46)

    if s.invuln > 0 then s.invuln = s.invuln - dt end

    -- autofire
    s.fireT = s.fireT - dt
    if s.fireT <= 0 then
        s.fireT = C.FIRE_COOLDOWN
        Player.fire()
    end

    if bomb then Player.bomb() end
end

function Player.fire()
    if #G.shots >= C.MAX_SHOTS then return end
    local s = G.ship
    for _, off in ipairs({ -C.SHOT_SPREAD / 2, C.SHOT_SPREAD / 2 }) do
        local dx, dy = Vec.fromAngle(s.aim + off, C.SHOT_SPEED)
        -- launch a little ahead of the nose, offset to its barrel
        local px, py = Vec.fromAngle(s.aim + off, C.SHIP_R + 2)
        G.shots[#G.shots + 1] = {
            x = s.x + px, y = s.y + py,
            vx = dx + s.vx, vy = dy + s.vy,
            life = C.SHOT_LIFE,
        }
    end
    Sfx.pew(960)
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

function Player.updateShots(dt)
    local shots = G.shots
    for i = #shots, 1, -1 do
        local b = shots[i]
        b.life = b.life - dt
        b.x = b.x + b.vx * dt
        b.y = b.y + b.vy * dt
        if b.life <= 0 or b.x < 0 or b.x > Field.W or b.y < 0 or b.y > Field.H then
            if b.life > 0 then Grid.push(b.x, b.y, 70, 30) end -- splash on the wall
            table.remove(shots, i)
        else
            Grid.push(b.x, b.y, 16, 22) -- shots ripple the mesh as they fly
        end
    end
end
