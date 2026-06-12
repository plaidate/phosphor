-- The well's residents: Flippers, Tankers, Spikers, Fuseballs, Pulsars,
-- their shots, and the wave spawner. Logic carried over from the verified
-- Tempest-style build; lane flips now record direction and start the
-- cartwheel animation the renderer pivots around the shared lane edge.

Enemies = {}

local clamp = Util.clamp

local function climbSpeed()
    return 0.085 + G.level * 0.011
end

local function randomLane()
    return math.random(0, G.well.lanes - 1)
end

local function neighborLane(lane, dir)
    local w = G.well
    if w.closed then
        return (lane + dir) % w.lanes
    end
    local n = lane + dir
    if n < 0 or n > w.lanes - 1 then return lane - dir end -- bounce at open ends
    return n
end

-- move e one lane over (if it can) and start the flip animation
local function flipTo(e, dir)
    local from = e.lane
    e.lane = neighborLane(e.lane, dir)
    local moved = G.laneDelta(from, e.lane, G.well.lanes, G.well.closed)
    if moved ~= 0 then
        e.flipDir = moved > 0 and 1 or -1
        e.flipAnim = C.FLIP_ANIM
    end
    Sfx.sirenTick(170)
end

function Enemies.add(etype, lane, z)
    local e = {
        type = etype, lane = lane or randomLane(), z = z or 0.02,
        atRim = false, rimT = 0,
        flipT = 0.8 + math.random(),
        pulseT = 1.5 + math.random(), pulsing = 0,
        climbing = true,
    }
    if etype == "flipper" then
        e.points = C.PTS_FLIPPER
        e.speed = climbSpeed()
    elseif etype == "tanker" then
        e.points = C.PTS_TANKER
        e.speed = climbSpeed() * 0.55
    elseif etype == "spiker" then
        e.points = C.PTS_SPIKER
        e.speed = climbSpeed() * 1.3
        e.turnAt = 0.55 + math.random() * 0.15
    elseif etype == "fuseball" then
        e.points = C.PTS_FUSEBALL
        e.speed = climbSpeed() * 1.15
        e.flipT = 0.3 + math.random() * 0.4
    elseif etype == "pulsar" then
        e.points = C.PTS_PULSAR
        e.speed = climbSpeed() * 0.9
    end
    G.enemies[#G.enemies + 1] = e
end

function Enemies.queueWave(level)
    G.spawnQ = {}
    local interval = math.max(0.6, 1.5 - level * 0.06)
    local t = 0.8
    local function queue(etype, n)
        for _ = 1, n do
            G.spawnQ[#G.spawnQ + 1] = { t = t, type = etype }
            t = t + interval * (0.7 + math.random() * 0.6)
        end
    end
    queue("flipper", math.min(4 + level, 10))
    if level >= 2 then queue("tanker", math.min(level - 1, 4)) end
    if level >= 2 then queue("spiker", math.min(1 + level // 2, 4)) end
    if level >= 4 then queue("fuseball", math.min(level // 3, 3)) end
    if level >= 5 then queue("pulsar", math.min(level // 4, 3)) end
end

function Enemies.updateSpawnQ()
    for i = #G.spawnQ, 1, -1 do
        local s = G.spawnQ[i]
        s.t = s.t - C.DT
        if s.t <= 0 then
            table.remove(G.spawnQ, i)
            Enemies.add(s.type)
        end
    end
end

-- splitting a tanker releases two flippers (fuseballs deeper in the game)
function Enemies.splitTanker(e)
    local child = (G.level >= 7 and math.random() < 0.35) and "fuseball" or "flipper"
    local z = math.max(0.05, math.min(e.z, 0.88))
    Enemies.add(child, neighborLane(e.lane, -1), z)
    Enemies.add(child, neighborLane(e.lane, 1), z)
end

local function rimWalk(e, stepTime)
    -- at the rim: stalk the player around it
    e.rimT = e.rimT - C.DT
    if e.rimT <= 0 then
        e.rimT = stepTime
        local d = G.laneDelta(e.lane, Player.lane(), G.well.lanes, G.well.closed)
        if d ~= 0 then
            flipTo(e, d > 0 and 1 or -1)
        end
    end
    if G.player.alive and e.lane == Player.lane() then
        Player.kill()
    end
end

local function updateFlipper(e)
    if e.atRim then
        rimWalk(e, math.max(0.28, 0.5 - G.level * 0.015))
        return
    end
    e.z = e.z + e.speed * C.DT
    if e.z >= 1 then
        e.z = 1
        e.atRim = true
        e.rimT = 0.3
        return
    end
    e.flipT = e.flipT - C.DT
    if e.flipT <= 0 then
        e.flipT = 0.8 + math.random() * 0.8
        -- bias the flip toward the player's lane as they near the rim
        local d = G.laneDelta(e.lane, Player.lane(), G.well.lanes, G.well.closed)
        local dir
        if d ~= 0 and (e.z > 0.6 or math.random() < 0.6) then
            dir = d > 0 and 1 or -1
        else
            dir = math.random() < 0.5 and -1 or 1
        end
        flipTo(e, dir)
    end
end

local function updateTanker(e)
    e.z = e.z + e.speed * C.DT
    if e.z >= 0.92 then
        -- bursts open at the rim's edge
        local x, y = Wells.laneCenter(G.well, e.lane, e.z)
        G.burst(x, y, 5)
        Enemies.splitTanker(e)
        return true -- remove
    end
    return false
end

local function updateSpiker(e)
    if e.climbing then
        e.z = e.z + e.speed * C.DT
        local cur = G.spikes[e.lane] or 0
        if e.z > cur then G.spikes[e.lane] = math.min(e.z, e.turnAt) end
        if e.z >= e.turnAt then
            e.climbing = false
        end
    else
        e.z = e.z - e.speed * 1.4 * C.DT
        if e.z <= 0.05 then
            e.z = 0.05
            e.climbing = true
            e.lane = randomLane() -- start a spike somewhere new
            e.turnAt = 0.55 + math.random() * 0.2
        end
    end
end

local function updateFuseball(e)
    if e.atRim then
        rimWalk(e, 0.3)
        return
    end
    e.z = e.z + e.speed * C.DT * (math.random() < 0.15 and -1 or 1) -- jittery
    e.z = clamp(e.z, 0.02, 1)
    if e.z >= 1 then
        e.atRim = true
        e.rimT = 0.2
        e.points = C.PTS_FUSEBALL_RIM
        return
    end
    e.flipT = e.flipT - C.DT
    if e.flipT <= 0 then
        e.flipT = 0.3 + math.random() * 0.4
        e.lane = neighborLane(e.lane, math.random() < 0.5 and -1 or 1)
    end
end

local function updatePulsar(e)
    e.z = e.z + e.speed * C.DT
    if e.z >= 0.95 then e.z = 0.95 end -- lurks just below the rim
    e.pulseT = e.pulseT - C.DT
    if e.pulsing > 0 then
        e.pulsing = e.pulsing - C.DT
        -- an electrified lane is death to a claw sitting on it
        if G.player.alive and e.lane == Player.lane() then
            Player.kill()
        end
    elseif e.pulseT <= 0 then
        e.pulseT = 1.8 + math.random() * 1.2
        e.pulsing = 0.5
        Sfx.warble()
    end
end

function Enemies.update()
    for i = #G.enemies, 1, -1 do
        local e = G.enemies[i]
        if e.flipAnim and e.flipAnim > 0 then e.flipAnim = e.flipAnim - C.DT end
        local remove = false
        if e.type == "flipper" then
            updateFlipper(e)
        elseif e.type == "tanker" then
            remove = updateTanker(e)
        elseif e.type == "spiker" then
            updateSpiker(e)
        elseif e.type == "fuseball" then
            updateFuseball(e)
        elseif e.type == "pulsar" then
            updatePulsar(e)
        end

        -- climbers take potshots up their lane
        if not remove and not e.atRim and e.z < 0.85
            and (e.type == "flipper" or e.type == "tanker")
            and G.player.alive and math.random() < (0.22 + G.level * 0.02) * C.DT then
            G.eShots[#G.eShots + 1] = { lane = e.lane, z = e.z, spin = math.random(0, 359) }
        end

        if remove then table.remove(G.enemies, i) end
    end
end

function Enemies.updateShots()
    for i = #G.eShots, 1, -1 do
        local s = G.eShots[i]
        s.z = s.z + (C.ESHOT_BASE_SPEED + G.level * 0.02) * C.DT
        s.spin = s.spin + 480 * C.DT -- tri-spikes spin as they climb
        if s.z >= 0.97 then
            if G.player.alive and s.lane == Player.lane() then
                Player.kill()
            end
            table.remove(G.eShots, i)
        end
    end
end
