-- The swarm: a Galaga-style formation that streams in along curved paths,
-- breathes side to side, and peels single fighters off to dive and fire.
-- Bosses replace the wave on every C.BOSS_EVERY level.

Enemies = {}

local clamp = Util.clamp

local HP = { drone = 1, wedge = 1, tie = 2, bird = 3 }

-- which enemy kinds are in play at a given level
local function kindPool(level)
    local pool = { "drone" }
    if level >= 2 then pool[#pool + 1] = "wedge" end
    if level >= 3 then pool[#pool + 1] = "tie" end
    if level >= 4 then pool[#pool + 1] = "bird" end
    return pool
end

local function homeX(e) return C.FORM_X0 + e.col * C.FORM_DX end
local function homeY(e) return C.FORM_Y0 + e.row * C.FORM_DY end

local function sway()
    return math.sin(G.swayT * C.SWAY_SPEED) * C.SWAY_AMP
end

-- (re)start an enemy on a curved fly-in toward its formation slot
local function beginFlyin(e, fromTop)
    local fromLeft = math.random() < 0.5
    if fromTop then
        e.fx0, e.fy0 = clamp(e.x, 20, Field.W - 20), -15
    else
        e.fx0 = fromLeft and -20 or Field.W + 20
        e.fy0 = -10 + math.random() * 30
    end
    e.fcx = Field.W / 2 + math.random(-90, 90)
    e.fcy = 50 + math.random(40)
    e.u = 0
    e.delay = math.random() * 0.7
    e.state = "flyin"
end

function Enemies.spawnWave(level)
    G.enemies = {}
    G.boss = nil
    local pool = kindPool(level)
    local count = math.min(C.FORM_COLS * C.FORM_ROWS, 10 + level * 2)
    local rows = math.min(C.FORM_ROWS, math.ceil(count / C.FORM_COLS))
    local i = 0
    for row = 0, rows - 1 do
        -- centre shorter rows in the grid
        local inRow = math.min(C.FORM_COLS, count - i)
        local startCol = math.floor((C.FORM_COLS - inRow) / 2)
        for c = 0, inRow - 1 do
            local kind = pool[math.random(#pool)]
            local e = {
                kind = kind, hp = HP[kind],
                col = startCol + c, row = row,
                x = 0, y = 0,
            }
            e.x = homeX(e)
            e.y = homeY(e)
            beginFlyin(e, false)
            G.enemies[#G.enemies + 1] = e
            i = i + 1
        end
    end
    G.attackT = C.ATTACK_BASE
    Harness.set("waveEnemies", #G.enemies)
end

function Enemies.spawnBoss(level)
    G.enemies = {}
    local n = math.floor(level / C.BOSS_EVERY)
    G.boss = {
        x = Field.W / 2, y = 58,
        hp = C.BOSS_HP + (n - 1) * 20,
        maxhp = C.BOSS_HP + (n - 1) * 20,
        dir = 1, fireT = C.BOSS_FIRE, hitT = 0,
    }
    Harness.count("bosses")
end

-- quadratic bezier ease
local function bez(a, c, b, u)
    local v = 1 - u
    return v * v * a + 2 * v * u * c + u * u * b
end

local function fireAt(x, y, tx, ty, speed)
    local dx, dy = tx - x, ty - y
    local d = math.sqrt(dx * dx + dy * dy)
    if d < 1 then d = 1 end
    G.eshots[#G.eshots + 1] = {
        x = x, y = y,
        vx = dx / d * speed, vy = dy / d * speed,
    }
end

-- ENEMY FLY-IN -------------------------------------------------------------
-- returns true once every survivor has reached its slot
function Enemies.updateFlyin(dt)
    G.swayT = G.swayT + dt
    local allIn = true
    for _, e in ipairs(G.enemies) do
        if e.state == "flyin" then
            allIn = false
            if e.delay > 0 then
                e.delay = e.delay - dt
            else
                e.u = math.min(1, e.u + dt / C.FLYIN_TIME)
                local hx, hy = homeX(e) + sway(), homeY(e)
                local u = e.u * e.u * (3 - 2 * e.u) -- smoothstep
                e.x = bez(e.fx0, e.fcx, hx, u)
                e.y = bez(e.fy0, e.fcy, hy, u)
                if e.u >= 1 then e.state = "formed" end
            end
        end
    end
    return allIn
end

-- FORMATION + DIVES --------------------------------------------------------
local function launchDive()
    local formed = {}
    for _, e in ipairs(G.enemies) do
        if e.state == "formed" then formed[#formed + 1] = e end
    end
    if #formed == 0 then return end
    local e = formed[math.random(#formed)]
    e.state = "dive"
    e.baseX = e.x
    e.phase = math.random() * 6.28
    e.shotT = 0.3 + math.random() * 0.4
    Sfx.blip(420)
end

local function diverCount()
    local n = 0
    for _, e in ipairs(G.enemies) do
        if e.state == "dive" then n = n + 1 end
    end
    return n
end

function Enemies.updateBattle(dt)
    G.swayT = G.swayT + dt
    local sx = sway()
    local s = G.ship

    for _, e in ipairs(G.enemies) do
        if e.state == "formed" then
            e.x = homeX(e) + sx
            e.y = homeY(e)
        elseif e.state == "dive" then
            e.phase = e.phase + dt * 4
            e.y = e.y + C.DIVE_VY * dt
            if s and s.alive then
                e.baseX = e.baseX + clamp(s.x - e.baseX, -1, 1) * C.DIVE_HOMING * dt
            end
            e.x = e.baseX + math.sin(e.phase) * C.DIVE_WIGGLE
            e.shotT = e.shotT - dt
            if e.shotT <= 0 and e.y < Field.H * 0.7 and s then
                fireAt(e.x, e.y, s.x, s.y, C.ENEMY_SHOT_SPEED)
                e.shotT = 0.6
            end
            if e.y > Field.H + 14 then
                beginFlyin(e, true) -- loop around and re-form
            end
        elseif e.state == "flyin" then
            -- a recycled diver streaming back into formation
            if e.delay > 0 then
                e.delay = e.delay - dt
            else
                e.u = math.min(1, e.u + dt / C.FLYIN_TIME)
                local hx, hy = homeX(e) + sx, homeY(e)
                local u = e.u * e.u * (3 - 2 * e.u)
                e.x = bez(e.fx0, e.fcx, hx, u)
                e.y = bez(e.fy0, e.fcy, hy, u)
                if e.u >= 1 then e.state = "formed" end
            end
        end
    end

    G.attackT = G.attackT - dt
    if G.attackT <= 0 and diverCount() < G.maxDivers() then
        launchDive()
        local base = math.max(C.ATTACK_BASE - G.level * 0.08, C.ATTACK_MIN)
        G.attackT = base * (0.7 + math.random() * 0.6)
    end
end

function Enemies.updateBoss(dt)
    local b = G.boss
    if not b then return end
    if b.hitT > 0 then b.hitT = b.hitT - dt end
    b.x = b.x + b.dir * C.BOSS_SPEED * dt
    if b.x < 70 then b.x, b.dir = 70, 1 elseif b.x > Field.W - 70 then b.x, b.dir = Field.W - 70, -1 end
    b.fireT = b.fireT - dt
    if b.fireT <= 0 then
        local s = G.ship
        if s then fireAt(b.x, b.y + 14, s.x, s.y, C.ENEMY_SHOT_SPEED + 20) end
        -- a small downward fan
        for k = -1, 1 do
            G.eshots[#G.eshots + 1] = { x = b.x, y = b.y + 14, vx = k * 60, vy = C.ENEMY_SHOT_SPEED }
        end
        b.fireT = C.BOSS_FIRE
        Sfx.blip(300)
    end
end

-- ENEMY BULLETS ------------------------------------------------------------
function Enemies.updateEShots(dt)
    local s = G.ship
    for i = #G.eshots, 1, -1 do
        local b = G.eshots[i]
        b.x = b.x + b.vx * dt
        b.y = b.y + b.vy * dt
        if b.y > Field.H + 8 or b.y < -8 or b.x < -8 or b.x > Field.W + 8 then
            table.remove(G.eshots, i)
        elseif s and s.alive then
            if math.abs(b.x - s.x) < C.SHIP_HALF and math.abs(b.y - s.y) < 7 then
                table.remove(G.eshots, i)
                Player.hit()
            end
        end
    end
end

-- COLLISIONS ---------------------------------------------------------------
local function killEnemy(e, idx)
    G.addScore(C.PTS[e.kind] or 100)
    Fx.burst(e.x, e.y, 10)
    Fx.debris(e.x, e.y, 3)
    Sfx.boom(1)
    Harness.count("kills")
    Bonuses.maybeDrop(e.x, e.y)
    table.remove(G.enemies, idx)
end

-- player shots vs enemies and boss
function Enemies.collideShots()
    for si = #G.shots, 1, -1 do
        local b = G.shots[si]
        local hit = false
        for ei = #G.enemies, 1, -1 do
            local e = G.enemies[ei]
            if math.abs(b.x - e.x) < C.ENEMY_R and math.abs(b.y - e.y) < C.ENEMY_R then
                e.hp = e.hp - 1
                if e.hp <= 0 then killEnemy(e, ei) else Sfx.pew(700) end
                hit = true
                break
            end
        end
        if not hit and G.boss then
            local bo = G.boss
            if math.abs(b.x - bo.x) < 30 and math.abs(b.y - bo.y) < 18 then
                bo.hp = bo.hp - 1
                bo.hitT = 0.12
                Fx.burst(b.x, b.y, 3)
                Sfx.pew(500)
                hit = true
                if bo.hp <= 0 then
                    G.addScore(C.PTS_BOSS)
                    G.addCash(500)
                    Fx.burst(bo.x, bo.y, 40)
                    Fx.debris(bo.x, bo.y, 16)
                    Fx.flash(0.4)
                    Sfx.bigBoom()
                    G.boss = nil
                end
            end
        end
        if hit then table.remove(G.shots, si) end
    end
end

-- enemy bodies (divers / boss) vs the fighter
function Enemies.collidePlayer()
    local s = G.ship
    if not s or not s.alive then return end
    for ei = #G.enemies, 1, -1 do
        local e = G.enemies[ei]
        if e.state == "dive" and math.abs(e.x - s.x) < C.ENEMY_R + C.SHIP_HALF
            and math.abs(e.y - s.y) < C.ENEMY_R then
            Fx.burst(e.x, e.y, 10)
            table.remove(G.enemies, ei)
            Player.hit()
            return
        end
    end
    local b = G.boss
    if b and math.abs(b.x - s.x) < 30 and math.abs(b.y - s.y) < 18 then
        Player.hit()
    end
end

function Enemies.cleared()
    return #G.enemies == 0 and not G.boss
end

function Enemies.allFormed()
    for _, e in ipairs(G.enemies) do
        if e.state == "flyin" then return false end
    end
    return true
end
