-- Treadline world: the infinite plain. Scattered wireframe pyramids and
-- boxes block tanks and shells and get recycled ahead of the player as they
-- roam; a fixed jagged mountain silhouette is drawn as a cheap 2D polyline
-- offset by view yaw; sparse ground dots sell the motion; 3D line fragments
-- fly when something dies.

local gfx <const> = playdate.graphics

World = {}

World.obs = {}
local frags = {}

-- heading degrees -> unit (x, z); yaw 0 faces +Z, matching Proj's camera
function World.heading(deg)
    local r = math.rad(deg)
    return math.sin(r), math.cos(r)
end

function World.bearing(dx, dz)
    return math.deg(math.atan(dx, dz))
end

-- ---------------------------------------------------------------- obstacles

local function pyramid(s, h)
    return {
        { -s, 0, -s, s, 0, -s, s, 0, s, -s, 0, s, -s, 0, -s },
        { -s, 0, -s, 0, h, 0 }, { s, 0, -s, 0, h, 0 },
        { s, 0, s, 0, h, 0 }, { -s, 0, s, 0, h, 0 },
    }
end

local function box(w, h, d)
    return {
        { -w, 0, -d, w, 0, -d, w, 0, d, -w, 0, d, -w, 0, -d },
        { -w, h, -d, w, h, -d, w, h, d, -w, h, d, -w, h, -d },
        { -w, 0, -d, -w, h, -d }, { w, 0, -d, w, h, -d },
        { w, 0, d, w, h, d }, { -w, 0, d, -w, h, d },
    }
end

local function makeObstacle()
    local ob
    if math.random() < 0.5 then
        local s = 2.2 + math.random() * 2.2
        ob = { model = pyramid(s, s * 1.3), r = s * 1.15 }
    else
        local w = 1.8 + math.random() * 1.6
        local d = 1.8 + math.random() * 1.6
        ob = { model = box(w, 1.6 + math.random() * 1.8, d), r = math.max(w, d) * 1.2 }
    end
    ob.yaw = math.random(0, 359)
    return ob
end

local function clearAt(self, x, z, r)
    if Vec.len(x - G.px, z - G.pz) < r + 10 then return false end
    if G.enemy and Vec.len(x - G.enemy.x, z - G.enemy.z) < r + 6 then return false end
    for _, o in ipairs(World.obs) do
        if o ~= self and o.x and Vec.len(x - o.x, z - o.z) < r + o.r + 3 then
            return false
        end
    end
    return true
end

-- ahead=true biases placement into the player's path (recycling while roaming)
local function place(ob, ahead)
    for _ = 1, 12 do
        local brg = ahead and (G.hullYaw + math.random(-80, 80)) or math.random(0, 359)
        local dist = ahead and (55 + math.random() * 33) or (14 + math.random() * 70)
        local hx, hz = World.heading(brg)
        local x, z = G.px + hx * dist, G.pz + hz * dist
        if clearAt(ob, x, z, ob.r) then
            ob.x, ob.z = x, z
            return
        end
    end
    ob.x, ob.z = G.px + 60, G.pz + 60 -- last resort, far off
end

function World.scatter()
    World.obs = {}
    frags = {}
    for i = 1, C.OBSTACLES do
        local ob = makeObstacle()
        World.obs[i] = ob
        place(ob, false)
    end
end

function World.recycle()
    local far2 = C.OB_FAR * C.OB_FAR
    for _, ob in ipairs(World.obs) do
        local dx, dz = ob.x - G.px, ob.z - G.pz
        if dx * dx + dz * dz > far2 then
            place(ob, true)
        end
    end
end

-- circle of radius r at (x, z) against every obstacle footprint
function World.hitsObstacle(x, z, r)
    for _, ob in ipairs(World.obs) do
        local dx, dz = x - ob.x, z - ob.z
        local rr = ob.r + r
        if dx * dx + dz * dz < rr * rr then return ob end
    end
    return nil
end

-- does any obstacle sit on the segment a->b? (shell paths, AI line of sight)
function World.losBlocked(ax, az, bx, bz)
    local dx, dz = bx - ax, bz - az
    local len2 = dx * dx + dz * dz
    if len2 < 1 then return false end
    for _, ob in ipairs(World.obs) do
        local t = ((ob.x - ax) * dx + (ob.z - az) * dz) / len2
        if t > 0 and t < 1 then
            local cx = ax + dx * t - ob.x
            local cz = az + dz * t - ob.z
            local rr = ob.r * 0.9
            if cx * cx + cz * cz < rr * rr then return true end
        end
    end
    return false
end

-- ---------------------------------------------------------------- fragments

function World.fragBurst(x, y, z, n)
    for _ = 1, n or 8 do
        local a = math.random() * 2 * math.pi
        local s = 4 + math.random() * 8
        frags[#frags + 1] = {
            x = x, y = y + math.random() * 0.8, z = z,
            vx = math.cos(a) * s, vz = math.sin(a) * s, vy = 2 + math.random() * 5,
            a = math.random() * 360, spin = math.random(-360, 360),
            len = 0.4 + math.random() * 0.9,
            life = 0.9 + math.random() * 0.6,
        }
    end
end

function World.updateFrags(dt)
    for i = #frags, 1, -1 do
        local f = frags[i]
        f.life = f.life - dt
        f.vy = f.vy - 12 * dt
        f.x, f.y, f.z = f.x + f.vx * dt, f.y + f.vy * dt, f.z + f.vz * dt
        f.a = f.a + f.spin * dt
        if f.life <= 0 or f.y < 0.05 then table.remove(frags, i) end
    end
end

function World.drawFrags()
    for _, f in ipairs(frags) do
        local r = math.rad(f.a)
        local dx, dz = math.cos(r) * f.len, math.sin(r) * f.len
        Proj.line(f.x - dx, f.y, f.z - dz, f.x + dx, f.y, f.z + dz)
    end
end

-- ------------------------------------------------------------------ scenery

-- fixed jagged silhouette: height every 4 degrees of bearing, drawn at the
-- horizon with a linear yaw->pixels offset (the classic cheap 2D trick)
local MTN = {}
for i = 1, 90 do
    MTN[i] = 5 + 10 * math.abs(math.sin(i * 1.93))
        + 8 * math.abs(math.sin(i * 0.61 + 2)) * math.abs(math.sin(i * 0.13))
end

function World.drawMountains(viewYaw)
    local hy = Proj.cy
    local k = Proj.focal * math.pi / 180 -- ~3.6 px per degree at screen center
    local px, py
    for i = 0, 90 do
        local diff = Vec.angleDiff(viewYaw, i * 4)
        local x = Proj.cx + diff * k
        local y = hy - MTN[(i % 90) + 1]
        if px and math.abs(x - px) < 40           -- skip the +-180 wrap jump
            and not (x < -10 and px < -10) and not (x > 410 and px > 410) then
            gfx.drawLine(px, py, x, y)
        end
        px, py = x, y
    end
end

-- sparse lattice dots on the plain so tread motion reads
function World.drawGround()
    local sp = 10
    local gx0 = math.floor((G.px - 40) / sp) * sp
    local gz0 = math.floor((G.pz - 40) / sp) * sp
    for gx = gx0, gx0 + 80, sp do
        for gz = gz0, gz0 + 80, sp do
            local sx, sy = Proj.point(gx, 0, gz)
            if sx and sy > Proj.cy + 1 then
                gfx.drawPixel(sx, sy)
            end
        end
    end
end

function World.drawObstacles(viewYaw)
    local fx, fz = World.heading(viewYaw)
    for _, ob in ipairs(World.obs) do
        local dx, dz = ob.x - G.px, ob.z - G.pz
        if dx * dx + dz * dz < 9500               -- ~97m draw range
            and dx * fx + dz * fz > -ob.r * 2 then -- cheap behind-camera cull
            Proj.model(ob.model, ob.x, 0, ob.z, ob.yaw)
        end
    end
end
