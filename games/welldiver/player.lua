-- The claw: rim movement, firing, the Superzapper, and dying.
-- Gameplay carried over from the verified Tempest-style build; the rework
-- gives death a debris shower and the Superzapper a flash + lane lightning.

Player = {}

local clamp = Util.clamp

function Player.new()
    return {
        pos = 0,      -- continuous lane coordinate
        fireT = 0,
        alive = true,
    }
end

-- the integer lane the claw currently occupies
function Player.lane()
    local w = G.well
    local p = G.player
    if w.closed then
        return math.floor(p.pos + 0.5) % w.lanes
    end
    return clamp(math.floor(p.pos + 0.5), 0, w.lanes - 1)
end

function Player.move(delta)
    local w = G.well
    local p = G.player
    p.pos = p.pos + delta
    if w.closed then
        p.pos = p.pos % w.lanes
    else
        p.pos = clamp(p.pos, 0, w.lanes - 1)
    end
end

function Player.fire()
    local p = G.player
    if p.fireT > 0 or #G.pShots >= C.MAX_SHOTS then return end
    p.fireT = C.FIRE_COOLDOWN
    G.pShots[#G.pShots + 1] = { lane = Player.lane(), z = 0.97 }
    Sfx.pew(1150 + math.random(200))
end

local function zapKill(i)
    local e = G.enemies[i]
    G.addScore(e.points)
    local x, y = Wells.laneCenter(G.well, e.lane, e.z)
    G.burst(x, y, 6)
    table.remove(G.enemies, i)
    Harness.count("kills")
end

function Player.superzap()
    if G.mode ~= "play" or not G.player.alive then return end
    if G.zapsUsed == 0 then
        -- the works: every enemy on the field dies
        for i = #G.enemies, 1, -1 do
            zapKill(i)
        end
        G.zapBolt = 0.35
        Fx.flash(0.3)
        G.zapsUsed = 1
        Harness.count("zaps")
        Sfx.zapSweep()
    elseif G.zapsUsed == 1 and #G.enemies > 0 then
        -- second use: one random enemy
        zapKill(math.random(#G.enemies))
        G.zapBolt = 0.15
        Fx.flash(0.12)
        G.zapsUsed = 2
        Harness.count("zaps")
        Sfx.zapSweep()
    end
end

function Player.kill()
    local p = G.player
    if not p.alive then return end
    p.alive = false
    G.lives = G.lives - 1
    G.respawnT = 2
    local x, y = Wells.laneCenter(G.well, Player.lane(), 1)
    G.burst(x, y, 10)
    Fx.debris(x, y, 10)
    Harness.count("deaths")
    Sfx.descend()
end

-- after a death the field relents: shots vanish and enemies fall back
function Player.respawn()
    G.eShots = {}
    for _, e in ipairs(G.enemies) do
        e.z = math.max(0.05, e.z - 0.45)
        e.atRim = false
    end
    G.player.alive = true
end
