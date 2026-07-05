-- The stage director: schedules squads of drones (chains riding one spline),
-- the satellite trio, meteors and the laser pair; detects the stage clear
-- and the stall (formation flies off if the player dawdles). Also runs the
-- chance stages: four squads, no danger, bonus for wiping each one.

Stage = {}

function Stage.begin(stageNum)
    G.chance = false
    local squads = math.min(4 + (stageNum - 1) // 2, 7)
    Stage.queue = {}
    local t = 0.6
    local baseTh = math.random() * 360
    for i = 1, squads do
        Stage.queue[#Stage.queue + 1] = {
            t = t,
            kind = math.random(#Paths.ENTRY_KINDS),
            th = (baseTh + i * 137) % 360,
            s = (i % 2 == 0) and -1 or 1,
            size = C.SQUAD_SIZE + ((stageNum >= 6 and i % 2 == 0) and 1 or 0),
        }
        t = t + C.SQUAD_GAP + 0.9
    end
    Stage.spawned = 0
    Stage.satDone = false
    Stage.satAt = squads // 2
    Stage.laserDone = stageNum < C.LASER_FROM_STAGE
    Stage.laserAt = math.max(squads - 1, 2)
    Stage.meteorT = C.METEOR_INTERVAL
    Stage.stallT = 0
    Stage.fled = false
end

local function spawnSquad(q)
    for k = 0, q.size - 1 do
        Enemies.spawnDrone(q.kind, q.th, q.s, k * C.SQUAD_STAGGER)
    end
    Stage.spawned = Stage.spawned + 1
    Harness.count("squads")
end

local function updateWaves(dt)
    for i = #Stage.queue, 1, -1 do
        local q = Stage.queue[i]
        q.t = q.t - dt
        if q.t <= 0 then
            table.remove(Stage.queue, i)
            spawnSquad(q)
        end
    end

    if not Stage.satDone and Stage.spawned >= Stage.satAt then
        Stage.satDone = true
        if not G.player.twin then Events.spawnSatellites() end
    end
    if not Stage.laserDone and Stage.spawned >= Stage.laserAt then
        Stage.laserDone = true
        Events.spawnLaser()
    end
    if G.stage >= C.METEOR_FROM_STAGE then
        Stage.meteorT = Stage.meteorT - dt
        if Stage.meteorT <= 0 and #G.meteors < 2 then
            Stage.meteorT = C.METEOR_INTERVAL * (0.7 + math.random() * 0.6)
            Events.spawnMeteor()
        end
    end

    -- nobody left to spawn and the player is grinding: the fleet moves on
    if #Stage.queue == 0 then
        Stage.stallT = Stage.stallT + dt
        if Stage.stallT > C.STALL_TIMEOUT and not Stage.fled then
            Stage.fled = true
            Enemies.leaveAll()
        end
    end
end

function Stage.isClear()
    return #Stage.queue == 0 and #G.enemies == 0
end

-- ---- chance stages ---------------------------------------------------------

function Stage.beginChance()
    G.chance = true
    G.chanceHits = 0
    G.chanceCombo = 0
    Stage.queue = {}
    Stage.cAlive, Stage.cKills = {}, {}
    Stage.perfect = 0
    Stage.chanceBonus = 0
    Stage.cSpawnedSquads = 0
    for i = 1, C.CHANCE_SQUADS do
        Stage.queue[#Stage.queue + 1] = {
            t = 0.8 + (i - 1) * 4.6,
            kind = ((i - 1) % #Paths.ENTRY_KINDS) + 1,
            th = math.random() * 360,
            s = (i % 2 == 0) and -1 or 1,
            squad = i,
        }
        Stage.cAlive[i] = 0
        Stage.cKills[i] = 0
    end
end

local function updateChance(dt)
    for i = #Stage.queue, 1, -1 do
        local q = Stage.queue[i]
        q.t = q.t - dt
        if q.t <= 0 then
            table.remove(Stage.queue, i)
            for k = 0, C.CHANCE_SIZE - 1 do
                Enemies.spawnChance(q.kind, q.th, q.s, k * C.SQUAD_STAGGER, q.squad)
            end
            Stage.cAlive[q.squad] = C.CHANCE_SIZE
            Stage.cSpawnedSquads = Stage.cSpawnedSquads + 1
            G.chanceCombo = 0
        end
    end
end

-- every chance drone reports in when it dies or escapes
function Stage.chanceResolved(e, killed)
    local i = e.squad
    if not i or not Stage.cAlive or not Stage.cAlive[i] then return end
    Stage.cAlive[i] = Stage.cAlive[i] - 1
    if killed then
        Stage.cKills[i] = Stage.cKills[i] + 1
        G.chanceHits = (G.chanceHits or 0) + 1
        Harness.count("chanceHits")
    end
    if Stage.cAlive[i] <= 0 then
        if Stage.cKills[i] >= C.CHANCE_SIZE then
            Stage.perfect = Stage.perfect + 1
            Stage.chanceBonus = Stage.chanceBonus + C.PTS_CHANCE_SQUAD
            G.addScore(C.PTS_CHANCE_SQUAD)
            G.pop("PERFECT +" .. C.PTS_CHANCE_SQUAD, 1.4)
            Sfx.fanfare({ 659, 784, 1047 }, 0.08)
        end
    end
end

function Stage.chanceOver()
    return G.chance and #Stage.queue == 0
        and Stage.cSpawnedSquads >= C.CHANCE_SQUADS and #G.enemies == 0
end

function Stage.update(dt)
    if G.chance then
        updateChance(dt)
    else
        updateWaves(dt)
    end
end
