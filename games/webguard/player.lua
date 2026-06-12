-- The spider: free 8-way movement inside the outer ring, crank-aimed
-- autofire, dying, and respawning at the web's hub.

Player = {}

local clamp = Util.clamp

function Player.new()
    return {
        x = C.CX, y = C.CY,
        aim = -90, -- firing direction in degrees, 0 = right
        fireT = 0,
        invuln = C.INVULN,
        alive = true,
    }
end

-- mx, my: movement direction (any magnitude; normalized here)
-- aimDelta: degrees of aim change this frame; fire: autofire held
function Player.update(mx, my, aimDelta, fire)
    local p = G.player
    if not p.alive then return end

    if p.invuln > 0 then p.invuln = p.invuln - C.DT end
    if p.fireT > 0 then p.fireT = p.fireT - C.DT end

    p.aim = (p.aim + aimDelta) % 360

    local nx, ny, l = Vec.norm(mx, my)
    if l > 0 then
        p.x = p.x + nx * C.PLAYER_SPEED * C.DT
        p.y = p.y + ny * C.PLAYER_SPEED * C.DT
        -- confined to the web: never past the outer ring
        local rx, ry = p.x - C.CX, p.y - C.CY
        local ux, uy, r = Vec.norm(rx, ry)
        local limit = C.R_OUT - C.EDGE_MARGIN
        if r > limit then
            p.x = C.CX + ux * limit
            p.y = C.CY + uy * limit
        end
    end

    if fire and p.fireT <= 0 and #G.shots < C.MAX_SHOTS then
        p.fireT = C.FIRE_COOLDOWN
        local dx, dy = Vec.fromAngle(p.aim, 1)
        G.shots[#G.shots + 1] = {
            x = p.x + dx * 7, y = p.y + dy * 7,
            vx = dx * C.SHOT_SPEED, vy = dy * C.SHOT_SPEED,
        }
        Sfx.pew()
    end
end

function Player.updateShots()
    for i = #G.shots, 1, -1 do
        local b = G.shots[i]
        b.x = b.x + b.vx * C.DT
        b.y = b.y + b.vy * C.DT
        -- shots end at the web's edge
        if G.dist2(b.x, b.y, C.CX, C.CY) > (C.R_OUT + 4) * (C.R_OUT + 4) then
            table.remove(G.shots, i)
        end
    end
end

function Player.kill()
    local p = G.player
    if not p.alive or p.invuln > 0 then return end
    p.alive = false
    G.lives = G.lives - 1
    G.respawnT = 2
    Fx.debris(p.x, p.y, 6)
    Fx.burst(p.x, p.y, 10)
    Sfx.bigBoom()
    Harness.count("deaths")
end

function Player.respawn()
    G.player = Player.new()
end
