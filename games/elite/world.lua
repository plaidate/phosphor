-- Elite: the universe. The player is fixed at the origin; every frame the whole
-- universe is rotated by the opposite of the player's roll/pitch and slid toward
-- them by their speed, which is exactly how the original keeps the player ship
-- still and moves the galaxy around it. Objects carry their own orientation
-- matrix (Mat) so they tumble and bank correctly as the view swings.

World = {}

local PLAYER_R <const> = 60     -- our own collision radius (a Cobra is ~135 wide)

local function len3(x, y, z) return math.sqrt(x * x + y * y + z * z) end

-- orientation whose nose (+Z, column 3) points along (dx,dy,dz), levelled to
-- world up: right = normalize(worldUp x nose), up = nose x right.
local function lookMatrix(dx, dy, dz)
    local l = len3(dx, dy, dz)
    if l < 1e-6 then return Mat.identity() end
    local nx, ny, nz = dx / l, dy / l, dz / l
    -- worldUp (0,1,0) x nose = (nz, 0, -nx)
    local rx, ry, rz = nz, 0, -nx
    local rl = len3(rx, ry, rz)
    if rl < 1e-6 then rx, ry, rz = 1, 0, 0 else rx, ry, rz = rx / rl, ry / rl, rz / rl end
    -- up = nose x right
    local ux = ny * rz - nz * ry
    local uy = nz * rx - nx * rz
    local uz = nx * ry - ny * rx
    return { rx, ux, nx, ry, uy, ny, rz, uz, nz }
end

local function addObj(o)
    G.objs[#G.objs + 1] = o
    return o
end

-- random unit direction biased forward (so contacts appear ahead of the player)
local function spawnPos(dist)
    local ang = math.random() * math.pi * 2
    local spread = C.SPAWN_SPREAD
    return math.cos(ang) * spread * (math.random() * 0.5 + 0.2),
           math.sin(ang) * spread * (math.random() * 0.5 + 0.2),
           dist + math.random(-600, 600)
end

-- which pirates prowl a system depends on its government (0 = anarchy, the most
-- dangerous, up to 7 = corporate state, the safest), as in Elite.
local PIRATE_POOL = {
    [0] = { "mamba", "ferdelance", "cobramk1", "asp", "krait" },
    [1] = { "mamba", "krait", "gecko", "cobramk1" },
    [2] = { "krait", "gecko", "sidewinder", "adder" },
    [3] = { "sidewinder", "gecko", "krait", "adder" },
    [4] = { "sidewinder", "adder", "worm" },
    [5] = { "sidewinder", "worm" },
    [6] = { "sidewinder", "worm" },
    [7] = { "sidewinder" },
}
local HP = { sidewinder = 14, gecko = 16, krait = 18, adder = 16, worm = 12, mamba = 22,
             cobramk1 = 20, ferdelance = 26, asp = 30, cobra = 26, python = 40, thargoid = 60,
             viper = 22, moray = 18 }

function World.addPirate(gov)
    local pool = PIRATE_POOL[gov] or PIRATE_POOL[3]
    local kind = pool[math.random(#pool)]
    if not (Ships[kind] and Ships[kind].verts) then kind = "sidewinder" end
    local s = Ships[kind]
    local x, y, z = spawnPos(C.SPAWN_Z)
    return addObj({
        kind = "pirate", mesh = kind, r = s.r,
        pos = { x = x, y = y, z = z }, m = lookMatrix(-x, -y, -z),
        speed = 200 + math.random(140), spin = 0,
        hp = HP[kind] or 16, maxhp = HP[kind] or 16, fireT = math.random() * 1.5,
    })
end

function World.addAsteroid()
    local s = Ships.asteroid
    local x, y, z = spawnPos(C.SPAWN_Z * 0.8)
    return addObj({
        kind = "asteroid", mesh = "asteroid", r = s.r,
        pos = { x = x, y = y, z = z }, m = lookMatrix(math.random(-9, 9), math.random(-9, 9), 9),
        speed = math.random(40), spin = (math.random() - 0.5) * 1.2,
        hp = 12, maxhp = 12,
    })
end

function World.addCargo(x, y, z)
    local s = Ships.canister
    addObj({
        kind = "cargo", mesh = "canister", r = s.r,
        pos = { x = x, y = y, z = z }, m = lookMatrix(math.random(-9, 9), math.random(-9, 9), 9),
        speed = 20, spin = (math.random() - 0.5) * 2,
        hp = 4, maxhp = 4,
    })
end

local GOV_NAME = { [0] = "ANARCHY", "FEUDAL", "MULTI-GOV", "DICTATORSHIP",
                   "COMMUNIST", "CONFEDERACY", "DEMOCRACY", "CORPORATE STATE" }

-- arrive in the system at G.systems[index+1]: read its economy/government and
-- populate space accordingly (lawless systems crawl with pirates).
function World.enterSystem(index)
    G.objs = {}
    G.sysIndex = index
    local seed = G.systems[index + 1]
    G.planet = Galaxy.data(seed)
    G.sysName = Galaxy.name(seed)

    local s = Ships.coriolis
    G.station = addObj({
        kind = "station", mesh = "coriolis", r = s.r,
        pos = { x = 0, y = 0, z = C.STATION_DIST }, m = Mat.identity(),
        speed = 0, spin = 0.45,
    })
    -- danger rises as government falls; 0 = anarchy, 7 = corporate state
    local gov = G.planet.gov
    local pirates = math.max(0, math.min(6, math.floor((7 - gov) * 0.8 + math.random(0, 1))))
    for _ = 1, pirates do World.addPirate(gov) end
    G.pirates = pirates
    for _ = 1, 1 + math.random(3) do World.addAsteroid() end
    G.say(G.sysName:upper() .. "  -  " .. (GOV_NAME[gov] or ""), 3)
end

function World.reset()
    G.energy, G.shield, G.hull = C.ENERGY_MAX, C.SHIELD_MAX, C.HULL_HITS
    G.laserHeat, G.speed = 0, C.SPEED_CRUISE
    G.score, G.kills = 0, 0
    G.hitFlash, G.laserT, G.docking = 0, 0, 0
    G.destroyed = false
    G.galaxyNum = 1
    G.systems = Galaxy.systems(1)
    G.fuel = C.FUEL_MAX
    G.credits = 1000          -- 100.0 Cr, Elite's starting balance (tenths)
    World.enterSystem(7)      -- Lave, the canonical starting system
    Harness.count("games")
end

-- apply damage to the player; shields soak first, then the hull/energy
function World.hurt(d)
    G.hitFlash = 0.18
    if G.shield > 0 then
        G.shield = G.shield - d
        if G.shield < 0 then G.energy = G.energy + G.shield; G.shield = 0 end
    else
        G.energy = G.energy - d
    end
    if G.energy <= 0 then
        G.energy = 0
        World.killPlayer("DESTROYED")
    end
end

function World.killPlayer(reason)
    if G.destroyed then return end
    G.destroyed = true
    G.deathReason = reason
    Fx.flash(0.5)
    Sfx.bigBoom()
    Harness.count("deaths")
end

local function destroyObj(o, i)
    if o.kind == "station" then return end
    local sx, sy = Proj.point(o.pos.x, o.pos.y, o.pos.z)
    if sx then
        Fx.burst(sx, sy, 10, 90)
        Fx.debris(sx, sy, 5, 60)
    end
    Sfx.boom(o.r > 120 and 2 or 1)
    local b = C.BOUNTY[o.mesh] or 0
    if o.kind == "pirate" then
        G.kills = G.kills + 1
        G.pirates = math.max(0, G.pirates - 1)
        Harness.count("kills")
        if math.random() < 0.5 then World.addCargo(o.pos.x, o.pos.y, o.pos.z) end
        if G.pirates == 0 then G.say("SYSTEM CLEAR - DOCK FOR BONUS", 3) end
    elseif o.kind == "asteroid" then
        Harness.count("rocks")
    end
    if b > 0 then G.addScore(b) end
    table.remove(G.objs, i)
end

-- the player's laser: hit the nearest live target whose projected centre falls
-- within the reticle and is in front of us and in range
local function fireLaser(dt)
    G.laserHeat = math.min(C.LASER_MAX_HEAT, G.laserHeat + C.LASER_HEAT_RATE * dt)
    if G.laserHeat >= C.LASER_MAX_HEAT then G.firing = false; return end
    G.laserT = 2
    Harness.count("shots")
    local best, bi, bestz = nil, nil, math.huge
    for i, o in ipairs(G.objs) do
        if o.kind ~= "station" and o.pos.z > 0 then
            local d = len3(o.pos.x, o.pos.y, o.pos.z)
            if d < C.LASER_RANGE then
                local sx, sy = Proj.point(o.pos.x, o.pos.y, o.pos.z)
                if sx then
                    local dx, dy = sx - Proj.cx, sy - Proj.cy
                    if dx * dx + dy * dy < C.LASER_HIT_PX * C.LASER_HIT_PX and o.pos.z < bestz then
                        best, bi, bestz = o, i, o.pos.z
                    end
                end
            end
        end
    end
    if best then
        best.hp = best.hp - C.LASER_DPS * dt
        best.hitT = 0.12
        if best.hp <= 0 then destroyObj(best, bi) end
    end
end

-- steer a pirate toward the player and fire when lined up
local function updatePirate(o, dt)
    local px, py, pz = o.pos.x, o.pos.y, o.pos.z
    local d = len3(px, py, pz)
    -- blend the nose toward the bearing to the player (origin), then re-tidy
    local ndx, ndy, ndz = -px / d, -py / d, -pz / d
    local nx, ny, nz = o.m[3], o.m[6], o.m[9]
    local turn = 0.06
    nx, ny, nz = nx + (ndx - nx) * turn, ny + (ndy - ny) * turn, nz + (ndz - nz) * turn
    o.m[3], o.m[6], o.m[9] = nx, ny, nz
    o.m = Mat.tidy(o.m)
    -- fire if aligned, in range, and off cooldown
    o.fireT = o.fireT - dt
    local dot = (o.m[3] * ndx + o.m[6] * ndy + o.m[9] * ndz)
    if d < C.ENEMY_RANGE and dot > C.ENEMY_FIRE_DOT and o.fireT <= 0 then
        World.hurt(C.ENEMY_DPS * (0.6 + math.random() * 0.8))
        o.fireT = 0.5 + math.random()
        Sfx.blip(120)
    end
    -- keep a stand-off distance so pirates orbit rather than ram constantly
    if d < 900 then o.speed = math.max(120, o.speed - 400 * dt) end
end

local function tryDock(o, dist)
    local sx, sy = Proj.point(o.pos.x, o.pos.y, o.pos.z)
    local centred = sx and o.pos.z > 0
        and (sx - Proj.cx) ^ 2 + (sy - Proj.cy) ^ 2 < 60 * 60
    local slow = G.speed <= C.SPEED_DOCK
    if dist < 380 and slow and centred then
        World.dock()
        return
    end
    if dist < o.r + PLAYER_R and not (slow and centred) then
        World.killPlayer("CRASHED INTO STATION")
    end
end

-- pick a hyperspace target: one of the nearest systems within fuel range that
-- isn't where we are (the galactic chart in Phase 3 will let the pilot choose).
local function pickJumpTarget()
    local here = G.systems[G.sysIndex + 1]
    local reach = {}
    for i = 1, 256 do
        if i - 1 ~= G.sysIndex then
            local d = Galaxy.distance(here, G.systems[i])
            if d > 0 and d <= G.fuel then reach[#reach + 1] = { i = i - 1, d = d } end
        end
    end
    if #reach == 0 then return nil end
    table.sort(reach, function(a, b) return a.d < b.d end)
    local pick = reach[math.random(1, math.min(6, #reach))]
    return pick.i, pick.d
end

function World.dock()
    G.energy, G.shield, G.hull = C.ENERGY_MAX, C.SHIELD_MAX, C.HULL_HITS
    G.laserHeat = 0
    G.fuel = C.FUEL_MAX          -- refuel and repair at the station
    G.addScore(C.DOCK_BONUS)
    Sfx.fanfare()
    Harness.count("docks")
    local target, dist = pickJumpTarget()
    if target then
        G.fuel = math.max(0, G.fuel - dist)
        Harness.count("jumps")
        World.enterSystem(target)
    else
        World.enterSystem(G.sysIndex)
    end
end

function World.update(dt)
    -- the rotation the universe undergoes this frame: opposite the player's
    -- roll (about Z, the view axis) and pitch (about X)
    local R = Mat.mul(Mat.rx(-G.pitch * dt), Mat.rz(-G.roll * dt))
    local forward = G.speed * dt

    -- condition regen
    G.energy = math.min(C.ENERGY_MAX, G.energy + C.ENERGY_REGEN * dt)
    if G.energy > 20 and G.shield < C.SHIELD_MAX then
        G.shield = math.min(C.SHIELD_MAX, G.shield + C.SHIELD_REGEN * dt)
    end
    G.laserHeat = math.max(0, G.laserHeat - C.LASER_COOL_RATE * dt)
    if G.hitFlash > 0 then G.hitFlash = G.hitFlash - dt end
    if G.laserT > 0 then G.laserT = G.laserT - 1 end
    if G.messageT > 0 then G.messageT = G.messageT - dt; if G.messageT <= 0 then G.message = nil end end

    if G.firing then fireLaser(dt) end

    for i = #G.objs, 1, -1 do
        local o = G.objs[i]
        local p = o.pos
        -- swing the object around the player
        p.x, p.y, p.z = Mat.mulVec(R, p.x, p.y, p.z)
        if o.m then o.m = Mat.mul(R, o.m) end
        -- the object's own forward motion
        if o.speed ~= 0 and o.m then
            local vx, vy, vz = Mat.mulVec(o.m, 0, 0, o.speed)
            p.x = p.x + vx * dt; p.y = p.y + vy * dt; p.z = p.z + vz * dt
        end
        -- own spin (asteroids tumble, the station rotates)
        if o.spin and o.spin ~= 0 then o.m = Mat.spinZ(o.m, o.spin * dt) end
        -- slide toward the player by our speed
        p.z = p.z - forward
        if o.hitT then o.hitT = o.hitT - dt; if o.hitT <= 0 then o.hitT = nil end end

        local dist = len3(p.x, p.y, p.z)

        if o.kind == "pirate" then
            updatePirate(o, dt)
        elseif o.kind == "station" then
            tryDock(o, dist)
        end

        -- collision with the player (non-station; station handled in tryDock)
        if o.kind ~= "station" and dist < o.r + PLAYER_R then
            if o.kind == "cargo" then
                G.addScore(C.BOUNTY.canister or 0)
                table.remove(G.objs, i)
            else
                World.hurt(o.kind == "pirate" and 45 or 30)
                destroyObj(o, i)
            end
        elseif dist > 14000 then
            -- drifted out of range: recycle it back into play ahead of us
            if o.kind == "station" then
                p.x, p.y, p.z = 0, 0, C.STATION_DIST
            else
                p.x, p.y, p.z = spawnPos(C.SPAWN_Z)
                if o.m then o.m = lookMatrix(-p.x, -p.y, -p.z) end
            end
        end
    end
end
