-- The fighter: rides the bottom line, crank/d-pad slide it sideways, A (or
-- autofire) launches a volley whose width grows with the weapon upgrade.

Player = {}

local clamp = Util.clamp

function Player.new()
    return {
        x = Field.W / 2,
        y = C.SHIP_Y,
        alive = true,
        invuln = 1.0,
        fireT = 0,
    }
end

function Player.respawn()
    local s = G.ship
    s.x = Field.W / 2
    s.alive = true
    s.invuln = 1.5
    s.fireT = 0
end

-- dx: signed px of intended travel this frame; fire/bomb: control flags
function Player.update(dt, dx, fire, bomb)
    local s = G.ship
    if s.invuln > 0 then s.invuln = s.invuln - dt end
    if G.shieldT > 0 then G.shieldT = G.shieldT - dt end
    if G.multT > 0 then G.multT = G.multT - dt end

    local margin = C.SHIP_HALF + 4
    s.x = clamp(s.x + dx, margin, Field.W - margin)

    s.fireT = s.fireT - dt
    if (fire or G.autofire) and s.fireT <= 0 then
        Player.fire()
        local cd = C.FIRE_COOLDOWN - G.rateLvl * 0.03
        s.fireT = math.max(cd, C.FIRE_COOLDOWN_MIN)
    end

    if bomb and G.bombs > 0 then
        Player.smartBomb()
    end
end

function Player.fire()
    local s = G.ship
    local n = clamp(G.spread, 1, C.MAX_SPREAD)
    local speed = -(C.SHOT_SPEED + G.rateLvl * C.SHOT_SPEED_BONUS)
    -- 1-2 barrels fire straight up side by side; wider volleys fan outward
    for i = 1, n do
        local off = (i - (n + 1) / 2)
        local vx = 0
        if n > 2 then vx = off / ((n - 1) / 2) * C.SPREAD_FAN end
        G.shots[#G.shots + 1] = {
            x = s.x + off * C.SPREAD_GAP, y = s.y - 8,
            vx = vx, vy = speed,
        }
    end
    Sfx.pew(980)
    Harness.count("shotsFired")
end

function Player.updateShots(dt)
    for i = #G.shots, 1, -1 do
        local b = G.shots[i]
        b.x = b.x + b.vx * dt
        b.y = b.y + b.vy * dt
        if b.y < -8 or b.x < -8 or b.x > Field.W + 8 then
            table.remove(G.shots, i)
        end
    end
end

function Player.smartBomb()
    G.bombs = G.bombs - 1
    G.eshots = {}
    Fx.flash(0.3)
    Sfx.bigBoom()
    Harness.count("bombs")
    -- clear the screen of formation enemies (boss only takes a dent)
    for i = #G.enemies, 1, -1 do
        local e = G.enemies[i]
        Fx.burst(e.x, e.y, 8)
        G.addScore(C.PTS[e.kind] or 100)
        table.remove(G.enemies, i)
    end
    if G.boss then
        G.boss.hp = G.boss.hp - 8
    end
end

-- apply a hit to the fighter; returns true if it was lethal
function Player.hit()
    local s = G.ship
    if not s.alive or s.invuln > 0 or G.shieldT > 0 then return false end
    if G.armor > 0 then
        G.armor = G.armor - 1
        s.invuln = 0.8
        Sfx.boom(1)
        Fx.burst(s.x, s.y, 8)
        return false
    end
    s.alive = false
    G.lives = G.lives - 1
    G.spread = math.max(1, G.spread - 1)  -- a death costs a weapon stage
    G.autofire = false
    Fx.burst(s.x, s.y, 26)
    Fx.debris(s.x, s.y, 10)
    Fx.flash(0.25)
    Sfx.bigBoom()
    G.respawnT = 1.8
    Harness.count("deaths")
    return true
end
