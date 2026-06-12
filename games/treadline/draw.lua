-- Treadline rendering: the first-person scene through the turret, the
-- radar scope (blips relative to TURRET heading), the hull-vs-turret
-- offset needle, beam-text HUD, and the cracked-windshield overlay.

local gfx <const> = playdate.graphics

Draw = {}

-- 3D models: polylines in {x,y,z,...} model space, +Z is forward
local TANK <const> = {
    -- hull
    { -1.3, 0.25, -1.8, 1.3, 0.25, -1.8, 1.3, 0.25, 1.8, -1.3, 0.25, 1.8, -1.3, 0.25, -1.8 },
    { -1.1, 1.0, -1.5, 1.1, 1.0, -1.5, 1.1, 1.0, 1.5, -1.1, 1.0, 1.5, -1.1, 1.0, -1.5 },
    { -1.3, 0.25, -1.8, -1.1, 1.0, -1.5 }, { 1.3, 0.25, -1.8, 1.1, 1.0, -1.5 },
    { 1.3, 0.25, 1.8, 1.1, 1.0, 1.5 }, { -1.3, 0.25, 1.8, -1.1, 1.0, 1.5 },
    -- turret
    { -0.6, 1.0, -0.7, 0.6, 1.0, -0.7, 0.6, 1.0, 0.7, -0.6, 1.0, 0.7, -0.6, 1.0, -0.7 },
    { -0.45, 1.5, -0.5, 0.45, 1.5, -0.5, 0.45, 1.5, 0.5, -0.45, 1.5, 0.5, -0.45, 1.5, -0.5 },
    { -0.6, 1.0, -0.7, -0.45, 1.5, -0.5 }, { 0.6, 1.0, -0.7, 0.45, 1.5, -0.5 },
    { 0.6, 1.0, 0.7, 0.45, 1.5, 0.5 }, { -0.6, 1.0, 0.7, -0.45, 1.5, 0.5 },
    -- barrel
    { 0, 1.25, 0.6, 0, 1.25, 2.7 },
}

local SKIM <const> = {
    { 1.2, 0, 0, 0, 0, 1.2, -1.2, 0, 0, 0, 0, -1.2, 1.2, 0, 0 },
    { 1.2, 0, 0, 0, 0.9, 0, -1.2, 0, 0 },
    { 0, 0, 1.2, 0, 0.9, 0, 0, 0, -1.2 },
    { 1.2, 0, 0, 0, -0.9, 0, -1.2, 0, 0 },
    { 0, 0, 1.2, 0, -0.9, 0, 0, 0, -1.2 },
}

local DART <const> = {
    { 0, 0, 0.55, 0.16, 0, -0.4, -0.16, 0, -0.4, 0, 0, 0.55 },
    { 0, 0, 0.55, 0, 0.16, -0.4, 0, -0.16, -0.4, 0, 0, 0.55 },
}

-- 2D tank silhouette for the lives row
local ICON <const> = Shapes.new({
    { -7, 3, 7, 3, 5, 6, -5, 6, -7, 3 },
    { -5, 3, -5, 0, 1, 0, 1, 3 },
    { 1, 1, 8, 1 },
})

-- ------------------------------------------------------------------- scene

function Draw.scene(viewYaw)
    Proj.setCamera(G.px, C.CAM_Y, G.pz, viewYaw)
    Proj.horizon()
    World.drawMountains(viewYaw)
    World.drawGround()
    World.drawObstacles(viewYaw)

    local e = G.enemy
    if e then
        if e.kind == "skimmer" then
            Proj.model(SKIM, e.x, e.y, e.z, e.yaw)
        else
            Proj.model(TANK, e.x, 0, e.z, e.yaw)
        end
    end
    local s = G.shell
    if s then Proj.model(DART, s.x, s.y, s.z, s.yaw) end
    s = G.eShell
    if s then Proj.model(DART, s.x, s.y, s.z, s.yaw) end

    World.drawFrags()
end

-- --------------------------------------------------------------------- HUD

local RX, RY, RR = 200, 27, 21 -- radar scope, top-center

function Draw.radar()
    gfx.drawCircleAtPoint(RX, RY, RR)
    gfx.drawLine(RX, RY - RR, RX, RY - RR + 3) -- turret-forward tick

    local sa = math.rad((Attract.frame * 6) % 360) -- the sweep
    gfx.drawLine(RX, RY, RX + math.sin(sa) * (RR - 2), RY - math.cos(sa) * (RR - 2))

    local e = G.enemy
    if e and Attract.frame % 8 < 5 then
        -- blip rotated so turret heading is straight up
        local v = math.rad(G.viewYaw())
        local dx, dz = e.x - G.px, e.z - G.pz
        local cv, sv = math.cos(v), math.sin(v)
        local rx = dx * cv - dz * sv
        local rz = dx * sv + dz * cv
        local k = RR / C.RADAR_RANGE
        local bx, by = rx * k, -rz * k
        local l = Vec.len(bx, by)
        if l > RR - 2 then
            bx, by = bx / l * (RR - 2), by / l * (RR - 2)
        end
        gfx.fillRect(RX + bx - 1, RY + by - 1, 3, 3)
    end
end

-- hull heading relative to where the turret (and you) are looking
function Draw.needle()
    local gx, gy, gr = 200, 60, 8
    gfx.drawCircleAtPoint(gx, gy, gr)
    gfx.drawLine(gx, gy - gr, gx, gy - gr - 2) -- up = turret/view
    local a = math.rad(-G.turretOff)
    gfx.drawLine(gx, gy, gx + math.sin(a) * gr, gy - math.cos(a) * gr)
end

local function crosshair()
    gfx.drawLine(188, 120, 195, 120)
    gfx.drawLine(205, 120, 212, 120)
    gfx.drawLine(200, 110, 200, 116)
    gfx.drawLine(200, 124, 200, 130)
end

function Draw.hud()
    Beams.print(tostring(G.score), 10, 8, 12, { weight = 1 })
    for i = 1, math.min(G.lives, 6) do
        Shapes.draw(ICON, Field.W - 22 * i, 12, 0, 1)
    end
end

-- ------------------------------------------------------ cracked windshield

local cracks = {}

function Draw.crack()
    cracks = {}
    local cx, cy = 130 + math.random(140), 70 + math.random(90)
    for _ = 1, 7 do
        local a = math.random() * 2 * math.pi
        local poly, x, y = { cx, cy }, cx, cy
        for _ = 1, 3 do
            a = a + (math.random() - 0.5) * 0.9
            local r = 25 + math.random(40)
            x, y = x + math.cos(a) * r, y + math.sin(a) * r
            poly[#poly + 1] = x
            poly[#poly + 1] = y
        end
        cracks[#cracks + 1] = poly
    end
end

local function drawCracks()
    if G.crackT <= 0 then return end
    for _, p in ipairs(cracks) do
        for i = 1, #p - 3, 2 do
            gfx.drawLine(p[i], p[i + 1], p[i + 2], p[i + 3])
        end
    end
end

-- ------------------------------------------------------------------- hooks

function Draw.play()
    Draw.scene(G.viewYaw())
    crosshair()
    Draw.radar()
    Draw.needle()
    Draw.hud()
    drawCracks()
    if G.dead then
        Beams.print("DESTROYED", 200, 100, 16, { align = "center", weight = 2 })
    end
end

-- title/over backdrop: the plain slowly panning, a derelict posed nearby
function Draw.ambient()
    Draw.scene(G.ambYaw)
    Proj.model(TANK, G.px + 6, 0, G.pz + 18, Attract.frame * 0.5)
end
