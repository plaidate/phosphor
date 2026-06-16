-- Open Geometry Wars: spawning and the difficulty ramp. spawnIndex climbs
-- with time; it gates which enemy types appear and how many live enemies the
-- arena tries to hold. Spawns are placed away from the ship and telegraphed.

Spawner = {}

-- types unlocked as the index climbs, with relative weights
local function pool(idx)
    local p = { { "grunt", 4 }, { "wander", 3 } }
    if idx > 2 then p[#p + 1] = { "spinner", 2 } end
    if idx > 4 then p[#p + 1] = { "weaver", 2 } end
    if idx > 7 then p[#p + 1] = { "hole", 1 } end
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

-- spawns quicken from ~1.5s down to ~0.4s as difficulty climbs
local function interval(idx)
    return Util.clamp(1.5 - idx * 0.05, 0.4, 1.5)
end

local function farPlace()
    local s = G.ship
    for _ = 1, 12 do
        local x, y = math.random(20, Field.W - 20), math.random(20, Field.H - 20)
        if Vec.len(x - s.x, y - s.y) > C.MIN_SPAWN_DIST then return x, y end
    end
    -- fall back to a corner away from the ship
    return (s.x < Field.W / 2) and Field.W - 30 or 30,
        (s.y < Field.H / 2) and Field.H - 30 or 30
end

function Spawner.reset()
    G.spawnIndex = 0
    G.spawnT = 1.0
end

function Spawner.update(dt)
    G.spawnIndex = G.spawnIndex + C.SPAWN_RAMP * dt
    Harness.set("spawnIndex", math.floor(G.spawnIndex))

    -- target population grows with the ramp
    local target = math.min(C.MAX_ENEMIES, 6 + math.floor(G.spawnIndex * 1.5))
    -- count only fully-live enemies toward pressure so waves keep coming
    local live = #G.enemies

    G.spawnT = G.spawnT - dt
    if G.spawnT <= 0 and live < target and not (G.ship and not G.ship.alive) then
        G.spawnT = interval(G.spawnIndex)
        -- spawn a small cluster as the index rises
        local burst = 1 + math.floor(G.spawnIndex / 6)
        local p = pool(G.spawnIndex)
        for _ = 1, math.min(burst, target - live) do
            local x, y = farPlace()
            Enemies.spawn(pick(p), x, y, true)
        end
    end
end
