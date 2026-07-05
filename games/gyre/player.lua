-- The ship: rides the rim at angle P.a, nose to the center. Shots converge
-- on the middle of the tube. Destroying a full satellite trio fits the
-- twin cannons, which stay until the ship is lost.

Player = {}

function Player.new()
    return {
        a = 90, -- bottom of the screen
        alive = true,
        fireT = 0,
        twin = false,
        invulnT = 0,
    }
end

-- moveDeg comes straight from Input.gather (crank degrees or d-pad rate)
function Player.move(moveDeg)
    local p = G.player
    p.a = (p.a + moveDeg * C.CRANK_RATIO) % 360
end

local function volleysInFlight()
    local n = 0
    for _, s in ipairs(G.shots) do
        if not s.wing then n = n + 1 end
    end
    return n
end

function Player.fire()
    local p = G.player
    if p.fireT > 0 or not p.alive then return end
    if volleysInFlight() >= C.MAX_VOLLEYS then return end
    p.fireT = C.FIRE_COOLDOWN
    if p.twin then
        G.shots[#G.shots + 1] = { a = p.a - C.TWIN_SPREAD, r = 0.97 }
        G.shots[#G.shots + 1] = { a = p.a + C.TWIN_SPREAD, r = 0.97, wing = true }
    else
        G.shots[#G.shots + 1] = { a = p.a, r = 0.97 }
    end
    Harness.count("shots")
    Sfx.pew(p.twin and 990 or 880)
end

function Player.updateShots(dt)
    for i = #G.shots, 1, -1 do
        local s = G.shots[i]
        s.r = s.r - C.SHOT_SPEED * dt
        if s.r <= 0.02 then table.remove(G.shots, i) end
    end
end

function Player.kill()
    local p = G.player
    if not p.alive or p.invulnT > 0 then return end
    p.alive = false
    p.twin = false
    G.respawnT = C.RESPAWN_TIME
    local ux, uy = G.unit(p.a, 1)
    G.boom(ux, uy, 20)
    local x, y = G.px(ux, uy)
    Fx.debris(x, y, 10)
    Fx.flash(0.15)
    G.lives = G.lives - 1
    G.bullets = {}
    Enemies.recallAttackers()
    Harness.count("deaths")
    Sfx.bigBoom()
end

function Player.respawn()
    local p = G.player
    p.alive = true
    p.invulnT = C.INVULN_TIME
    p.fireT = 0
end
