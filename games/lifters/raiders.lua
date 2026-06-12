-- Lifters: the raid. Raiders fly in from the screen edges, claim a canister,
-- latch on, and drag it for the nearest edge — if one exits, that fuel is
-- gone forever. Kill the carrier and the canister drops on the spot.
-- Gunners snipe at the ship while they work; rammers ignore the fuel and
-- hunt the pilot.

Raiders = {}

local clamp = Util.clamp

local function speedFor(kind)
    local base = C.RAIDERS[kind].speed
    local ramp = math.min(1 + C.SPEED_RAMP * (G.wave - 1), C.SPEED_RAMP_MAX)
    return base * ramp
end

function Raiders.add(kind, delay)
    local t = C.RAIDERS[kind]
    local x, y
    local side = math.random(4)
    if side == 1 then
        x, y = -16, math.random(24, Field.H - 24)
    elseif side == 2 then
        x, y = Field.W + 16, math.random(24, Field.H - 24)
    elseif side == 3 then
        x, y = math.random(24, Field.W - 24), -16
    else
        x, y = math.random(24, Field.W - 24), Field.H + 16
    end
    G.raiders[#G.raiders + 1] = {
        kind = kind,
        x = x, y = y,
        vx = 0, vy = 0,
        r = t.r,
        speed = speedFor(kind),
        points = t.points,
        state = "seek", -- "seek" | "drag" | "ram"
        delay = delay or 0,
        target = nil,   -- canister being chased/carried
        exitX = nil, exitY = nil,
        fireT = (t.fireEvery or 0) * (0.6 + math.random()),
        wob = math.random() * 2 * math.pi, -- flight wobble phase
        heading = 0,
    }
    if kind == "rammer" then G.raiders[#G.raiders].state = "ram" end
end

function Raiders.spawnWave()
    G.wave = G.wave + 1
    Harness.count("waves")
    local n = math.min(2 + G.wave, C.MAX_WAVE_RAIDERS)
    for i = 1, n do
        local kind = "lifter"
        local roll = math.random()
        if G.wave >= C.RAMMER_WAVE and roll < 0.25 then
            kind = "rammer"
        elseif G.wave >= C.GUNNER_WAVE and roll < 0.60 then
            kind = "gunner"
        end
        Raiders.add(kind, (i - 1) * C.ENTER_STAGGER)
    end
    Sfx.warble()
end

-- nearest grounded canister, preferring ones no other raider has claimed
local function pickCanister(rd)
    local best, bestD, bestAny, bestAnyD = nil, math.huge, nil, math.huge
    for _, can in ipairs(G.canisters) do
        if not can.carrier then
            local d = G.dist2(rd.x, rd.y, can.x, can.y)
            if d < bestAnyD then bestAnyD, bestAny = d, can end
            if (not can.claimed or can.claimed == rd) and d < bestD then
                bestD, best = d, can
            end
        end
    end
    best = best or bestAny
    if best then best.claimed = rd end
    return best
end

local function moveToward(rd, tx, ty, speed, dt)
    rd.wob = rd.wob + dt * 3
    local dx, dy = Vec.norm(tx - rd.x, ty - rd.y)
    -- a slight sinusoidal weave so the raid looks alive
    local px, py = -dy, dx
    local w = math.sin(rd.wob) * 0.25
    rd.x = rd.x + (dx + px * w) * speed * dt
    rd.y = rd.y + (dy + py * w) * speed * dt
    rd.heading = Vec.angleOf(dx, dy)
end

-- straight-out exit point past the nearest edge from (x, y)
local function nearestExit(x, y)
    local dl, dr, dt_, db = x, Field.W - x, y, Field.H - y
    local m = math.min(dl, dr, dt_, db)
    if m == dl then return -30, y end
    if m == dr then return Field.W + 30, y end
    if m == dt_ then return x, -30 end
    return x, Field.H + 30
end

local function dropCanister(rd, escaped)
    local can = rd.target
    if can and can.carrier == rd then
        if escaped then
            can.inPlay = false
            for i, c in ipairs(G.canisters) do
                if c == can then
                    table.remove(G.canisters, i)
                    break
                end
            end
            Harness.count("stolen")
            Sfx.descend()
        else
            can.carrier = nil
            can.x = clamp(can.x, 14, Field.W - 14)
            can.y = clamp(can.y, 14, Field.H - 14)
            Harness.count("dropped")
        end
    end
    if can and can.claimed == rd then can.claimed = nil end
    rd.target = nil
end

local function removeRaider(i)
    local rd = G.raiders[i]
    dropCanister(rd, false)
    table.remove(G.raiders, i)
end

local function offScreen(rd)
    return rd.x < -20 or rd.x > Field.W + 20 or rd.y < -20 or rd.y > Field.H + 20
end

local function updateSeek(rd, dt)
    local can = rd.target
    if not can or can.carrier or not can.inPlay then
        if can and can.claimed == rd then can.claimed = nil end
        rd.target = pickCanister(rd)
        can = rd.target
    end
    if can then
        moveToward(rd, can.x, can.y, rd.speed, dt)
        if G.dist2(rd.x, rd.y, can.x, can.y) < 6 * 6 then
            -- latch on and run for the nearest edge
            can.carrier = rd
            rd.state = "drag"
            rd.exitX, rd.exitY = nearestExit(rd.x, rd.y)
            Sfx.blip(440)
        end
    else
        -- nothing left on the ground: harass the pilot until something drops
        local s = G.ship
        if s and s.alive then
            moveToward(rd, s.x, s.y, rd.speed * 0.7, dt)
        else
            moveToward(rd, Field.W / 2, Field.H / 2, rd.speed * 0.4, dt)
        end
    end
end

local function updateDrag(rd, dt, i)
    local dragSpeed = math.min(C.DRAG_SPEED + 2 * G.wave, C.DRAG_SPEED_MAX)
    moveToward(rd, rd.exitX, rd.exitY, dragSpeed, dt)
    local can = rd.target
    if can then
        can.x, can.y = rd.x, rd.y + 11
    end
    if offScreen(rd) then
        dropCanister(rd, true) -- gone forever
        table.remove(G.raiders, i)
    end
end

local function updateRam(rd, dt)
    local s = G.ship
    local tx, ty
    if s and s.alive and s.invuln <= 0 then
        tx, ty = s.x + s.vx * 0.25, s.y + s.vy * 0.25
    else
        tx, ty = Field.W / 2, Field.H / 2 -- circle the cluster, wait
    end
    -- steer velocity toward the mark; momentum makes the dives readable
    local dx, dy = Vec.norm(tx - rd.x, ty - rd.y)
    rd.vx = rd.vx + dx * rd.speed * 3.2 * dt
    rd.vy = rd.vy + dy * rd.speed * 3.2 * dt
    local sp = Vec.len(rd.vx, rd.vy)
    if sp > rd.speed then
        rd.vx, rd.vy = rd.vx * rd.speed / sp, rd.vy * rd.speed / sp
    end
    rd.x = rd.x + rd.vx * dt
    rd.y = rd.y + rd.vy * dt
    rd.x = clamp(rd.x, -40, Field.W + 40)
    rd.y = clamp(rd.y, -40, Field.H + 40)
    rd.heading = Vec.angleOf(rd.vx, rd.vy)
end

local function updateGun(rd, dt)
    local s = G.ship
    if not (s and s.alive) then return end
    rd.fireT = rd.fireT - dt
    if rd.fireT <= 0 and not offScreen(rd) then
        rd.fireT = C.RAIDERS.gunner.fireEvery * (0.8 + math.random() * 0.4)
        local dx, dy = Vec.norm(s.x - rd.x, s.y - rd.y)
        G.raiderShots[#G.raiderShots + 1] = {
            x = rd.x + dx * 9, y = rd.y + dy * 9,
            vx = dx * C.RAIDER_SHOT_SPEED,
            vy = dy * C.RAIDER_SHOT_SPEED,
            life = C.RAIDER_SHOT_LIFE,
        }
        Sfx.pew(330)
    end
end

function Raiders.update(dt)
    for i = #G.raiders, 1, -1 do
        local rd = G.raiders[i]
        if rd.delay > 0 then
            rd.delay = rd.delay - dt
        else
            if rd.state == "seek" then
                updateSeek(rd, dt)
            elseif rd.state == "drag" then
                updateDrag(rd, dt, i)
            elseif rd.state == "ram" then
                updateRam(rd, dt)
            end
            if rd.kind == "gunner" then updateGun(rd, dt) end
        end
    end
end

function Raiders.updateShots(dt)
    for i = #G.raiderShots, 1, -1 do
        local b = G.raiderShots[i]
        b.life = b.life - dt
        b.x = b.x + b.vx * dt
        b.y = b.y + b.vy * dt
        if b.life <= 0 or b.x < 0 or b.x > Field.W or b.y < 0 or b.y > Field.H then
            table.remove(G.raiderShots, i)
        end
    end
end

function Raiders.kill(i)
    local rd = G.raiders[i]
    G.addScore(rd.points)
    Harness.count("raiders")
    Fx.debris(rd.x, rd.y, 5)
    Fx.burst(rd.x, rd.y, 8)
    Sfx.boom(rd.state == "drag" and 2 or 1)
    removeRaider(i)
end

function Raiders.collide()
    local s = G.ship

    -- player shots vs raiders
    for i = #G.shots, 1, -1 do
        local b = G.shots[i]
        for j = #G.raiders, 1, -1 do
            local rd = G.raiders[j]
            if rd.delay <= 0 and G.dist2(b.x, b.y, rd.x, rd.y) < (rd.r + 2) * (rd.r + 2) then
                table.remove(G.shots, i)
                Raiders.kill(j)
                break
            end
        end
    end

    if not (s and s.alive) then return end

    -- raider bodies vs the ship (a collision wrecks both)
    for j = #G.raiders, 1, -1 do
        local rd = G.raiders[j]
        if rd.delay <= 0 and G.dist2(s.x, s.y, rd.x, rd.y) < (rd.r + C.SHIP_R) * (rd.r + C.SHIP_R) then
            if s.invuln <= 0 then
                Ship.kill()
                Fx.debris(rd.x, rd.y, 4)
                Sfx.boom(2)
                removeRaider(j) -- no points for a trade
                return
            end
        end
    end

    -- raider shots vs the ship
    if s.invuln <= 0 then
        for i = #G.raiderShots, 1, -1 do
            local b = G.raiderShots[i]
            if G.dist2(s.x, s.y, b.x, b.y) < (C.SHIP_R + 2) * (C.SHIP_R + 2) then
                table.remove(G.raiderShots, i)
                Ship.kill()
                return
            end
        end
    end
end
