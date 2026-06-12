-- Phosphor core: 3D wireframe projection for the first-person games.
--
-- World space: X right, Y up, Z forward. The camera has a position and a
-- yaw (degrees, about Y); pitch is optional and small-angle. Lines crossing
-- the near plane are clipped by interpolation, so terrain and obstacles can
-- pass the camera without artifacts.

local gfx <const> = playdate.graphics

Proj = {
    cx = 200, cy = 120, -- screen center
    focal = 207,        -- ~60 degree horizontal field of view on 400px
    near = 0.5,
}

local cam = { x = 0, y = 0, z = 0, siny = 0, cosy = 1, sinp = 0, cosp = 1 }

function Proj.setCamera(x, y, z, yawDeg, pitchDeg)
    cam.x, cam.y, cam.z = x, y, z
    local yr = math.rad(yawDeg or 0)
    cam.siny, cam.cosy = math.sin(yr), math.cos(yr)
    local pr = math.rad(pitchDeg or 0)
    cam.sinp, cam.cosp = math.sin(pr), math.cos(pr)
end

-- world -> camera space
local function toCam(wx, wy, wz)
    local x, y, z = wx - cam.x, wy - cam.y, wz - cam.z
    -- yaw about Y
    local xz = x * cam.cosy - z * cam.siny
    local zz = x * cam.siny + z * cam.cosy
    -- pitch about X
    local yz = y * cam.cosp - zz * cam.sinp
    zz = y * cam.sinp + zz * cam.cosp
    return xz, yz, zz
end

-- returns sx, sy, depth or nil when behind the near plane
function Proj.point(wx, wy, wz)
    local x, y, z = toCam(wx, wy, wz)
    if z < Proj.near then return nil end
    local k = Proj.focal / z
    return Proj.cx + x * k, Proj.cy - y * k, z
end

-- draw a world-space line with near-plane clipping
function Proj.line(x1, y1, z1, x2, y2, z2)
    local ax, ay, az = toCam(x1, y1, z1)
    local bx, by, bz = toCam(x2, y2, z2)
    local n = Proj.near
    if az < n and bz < n then return end
    if az < n then
        local t = (n - az) / (bz - az)
        ax, ay, az = ax + (bx - ax) * t, ay + (by - ay) * t, n
    elseif bz < n then
        local t = (n - bz) / (az - bz)
        bx, by, bz = bx + (ax - bx) * t, by + (ay - by) * t, n
    end
    local ka, kb = Proj.focal / az, Proj.focal / bz
    gfx.drawLine(Proj.cx + ax * ka, Proj.cy - ay * ka,
                 Proj.cx + bx * kb, Proj.cy - by * kb)
end

-- a 3D model: list of polylines, each {x1,y1,z1, x2,y2,z2, ...}.
-- Drawn at (ox, oy, oz) rotated by yawDeg about Y.
function Proj.model(polys, ox, oy, oz, yawDeg)
    local s, c = 0, 1
    if yawDeg and yawDeg ~= 0 then
        local r = math.rad(yawDeg)
        s, c = math.sin(r), math.cos(r)
    end
    for p = 1, #polys do
        local poly = polys[p]
        local px, py, pz
        for i = 1, #poly - 2, 3 do
            local mx, my, mz = poly[i], poly[i + 1], poly[i + 2]
            local wx = ox + mx * c + mz * s
            local wz = oz - mx * s + mz * c
            local wy = oy + my
            if px then
                Proj.line(px, py, pz, wx, wy, wz)
            end
            px, py, pz = wx, wy, wz
        end
    end
end

-- horizon line for ground-plane games (uses current camera yaw/pitch)
function Proj.horizon()
    local y = Proj.cy + cam.sinp * Proj.focal
    gfx.drawLine(0, y, Field.W, y)
end
