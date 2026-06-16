-- Open Geometry Wars: spawning, the difficulty ramp, and waves. spawnIndex
-- climbs with time, gating enemy types and the target population; aggression
-- creeps the enemy speeds up. Alongside the steady trickle, SWARM waves pour
-- from a corner and RUSH waves ring the player, as in capehill/opengw.

Spawner = {}

local clamp = Util.clamp

-- types unlocked as the index climbs, with relative weights
local function pool(idx)
    local p = { { "grunt", 4 }, { "wander", 3 } }
    if idx > 2 then p[#p + 1] = { "spinner", 2 } end
    if idx > 3 then p[#p + 1] = { "weaver", 2 } end
    if idx > 4 then p[#p + 1] = { "mayfly", 2 } end
    if idx > 5 then p[#p + 1] = { "snake", 1 } end
    if idx > 7 then p[#p + 1] = { "hole", 1 } end
    if idx > 9 then p[#p + 1] = { "repulsor", 1 } end
    return p
end

local function pick(p)
    local total = 0
    for _, e in ipairs(p) do total = total + e[2] end
    local r = math.random() * total
    for _, e in ipairs(p) do
        r = r - e[2]
        if r <= 0 then return e[1] end
    end
    return p[1][1]
end

local function interval(idx)
    return clamp(1.5 - idx * 0.05, 0.4, 1.5)
end

local function farPlace()
    local s = G.ship
    for _ = 1, 12 do
        local x, y = math.random(20, Field.W - 20), math.random(20, Field.H - 20)
        if Vec.len(x - s.x, y - s.y) > C.MIN_SPAWN_DIST then return x, y end
    end
    return (s.x < Field.W / 2) and Field.W - 30 or 30,
        (s.y < Field.H / 2) and Field.H - 30 or 30
end

-- a SWARM pours one type in from a random corner; a RUSH rings the player
local function wave(idx)
    if #G.enemies >= C.MAX_ENEMIES then return end
    local kind = pick(pool(idx))
    local n = 3 + math.floor(idx * 0.6)
    if math.random() < 0.5 then
        local cx = (math.random() < 0.5) and 24 or Field.W - 24
        local cy = (math.random() < 0.5) and 24 or Field.H - 24
        for _ = 1, n do
            local x = clamp(cx + math.random(-30, 30), 16, Field.W - 16)
            local y = clamp(cy + math.random(-30, 30), 16, Field.H - 16)
            Enemies.spawn(kind, x, y, true)
        end
    else
        local s = G.ship
        for i = 1, n do
            local dx, dy = Vec.fromAngle(i / n * 360, 110)
            Enemies.spawn(kind, clamp(s.x + dx, 16, Field.W - 16),
                clamp(s.y + dy, 16, Field.H - 16), true)
        end
    end
    Harness.count("waves")
end

function Spawner.reset()
    G.spawnIndex = 0
    G.spawnT = 1.0
    G.waveT = 6.0
    G.aggro = 1.0
end

function Spawner.update(dt)
    G.spawnIndex = G.spawnIndex + C.SPAWN_RAMP * dt
    G.aggro = math.min(C.AGGRO_MAX, G.aggro + C.AGGRO_RAMP * dt)
    Harness.set("spawnIndex", math.floor(G.spawnIndex))

    if G.ship and not G.ship.alive then return end
    local idx = G.spawnIndex
    local target = math.min(C.MAX_ENEMIES, 6 + math.floor(idx * 1.5))

    -- steady trickle up to the target population
    G.spawnT = G.spawnT - dt
    if G.spawnT <= 0 and #G.enemies < target then
        G.spawnT = interval(idx)
        local burst = 1 + math.floor(idx / 6)
        local p = pool(idx)
        for _ = 1, math.min(burst, target - #G.enemies) do
            local x, y = farPlace()
            Enemies.spawn(pick(p), x, y, true)
        end
    end

    -- periodic waves once things warm up
    if idx > 1 then
        G.waveT = G.waveT - dt
        if G.waveT <= 0 then
            G.waveT = clamp(9 - idx * 0.2, 3.5, 9)
            wave(idx)
        end
    end
end
