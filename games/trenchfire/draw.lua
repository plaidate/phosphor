-- Trenchfire rendering: every scene element is Proj wireframe over black —
-- parallax stars for the approach, ground grid + horizon for the tower
-- field, two walls of receding rectangles for the trench — plus the
-- screen-space crosshair, corner lasers, and Beams HUD.

local gfx <const> = playdate.graphics

Draw = {}

-- small swept-wing fighter, nose toward -z (flying at the camera)
local FIGHTER <const> = {
    { -9, 0, 3, 0, 1, -7, 9, 0, 3, 0, -1, 2, -9, 0, 3 }, -- wing diamond
    { 0, 1, -7, 0, 5, 4, 0, -1, 2 },                     -- dorsal fin
}

-- tapering gun tower, base on the ground plane
local TOWER <const> = {
    { -7, 0, -7, 7, 0, -7, 7, 0, 7, -7, 0, 7, -7, 0, -7 },     -- base
    { -3, 30, -3, 3, 30, -3, 3, 30, 3, -3, 30, 3, -3, 30, -3 }, -- cap
    { -7, 0, -7, -3, 30, -3 }, { 7, 0, -7, 3, 30, -3 },
    { 7, 0, 7, 3, 30, 3 }, { -7, 0, 7, -3, 30, 3 },
    { 0, 30, 0, 0, 35, 0 },                                     -- gun mast
}

-- approach-phase starfield: screen-space with parallax against ship drift
local stars = {}
for i = 1, 44 do
    stars[i] = { x = math.random() * 400, y = math.random() * 240, p = 0.5 + math.random() * 1.6 }
end

local function drawStars()
    for i = 1, #stars do
        local s = stars[i]
        gfx.drawPixel((s.x - G.camX * s.p) % Field.W,
                      (s.y + (G.camY - 26) * s.p) % Field.H)
    end
end

-- ground grid for the tower field: longitudinal lines snapped to world x,
-- cross lines receding to the horizon
local function drawGrid(camX, camZ)
    Proj.horizon()
    local x0 = math.floor(camX / 40 + 0.5) * 40
    for k = -6, 6 do
        Proj.line(x0 + k * 40, 0, camZ + 2, x0 + k * 40, 0, camZ + 760)
    end
    local z0 = math.floor(camZ / 40) * 40
    for j = 1, 14 do
        Proj.line(camX - 280, 0, z0 + j * 40, camX + 280, 0, z0 + j * 40)
    end
end

-- the trench: rails + ribs make two rows of receding wall rectangles, with
-- overhead cross-braces. braces=nil draws them on a fixed modulo (title use).
function Draw.trenchWalls(camZ, endZ, braces)
    local W, H = C.TRENCH_W, C.TRENCH_H
    local z1 = camZ + 1
    local zTo = camZ + 720
    if endZ then zTo = math.min(zTo, endZ) end
    Proj.line(-W, 0, z1, -W, 0, zTo)
    Proj.line(W, 0, z1, W, 0, zTo)
    Proj.line(-W, H, z1, -W, H, zTo)
    Proj.line(W, H, z1, W, H, zTo)
    local z = (math.floor(z1 / C.RIB_EVERY) + 1) * C.RIB_EVERY
    while z < zTo do
        Proj.line(-W, 0, z, -W, H, z)
        Proj.line(W, 0, z, W, H, z)
        Proj.line(-W, 0, z, W, 0, z) -- floor seam
        z = z + C.RIB_EVERY
    end
    local function brace(bz)
        Proj.line(-W, H, bz, W, H, bz)
        Proj.line(-W, H - 10, bz, -W + 10, H, bz)
        Proj.line(W - 10, H, bz, W, H - 10, bz)
    end
    if braces then
        for i = 1, #braces do
            local bz = braces[i]
            if bz > z1 and bz < zTo then brace(bz) end
        end
    else
        local bz = (math.floor(z1 / C.BRACE_EVERY) + 1) * C.BRACE_EVERY
        while bz < zTo do
            brace(bz)
            bz = bz + C.BRACE_EVERY
        end
    end
end

local function drawHardpoints()
    for _, h in ipairs(G.hardpoints) do
        local dz = h.z - G.camZ
        if dz > 1 and dz < 700 then
            local x, y, z = h.x, h.y, h.z
            Proj.line(x, y + 4, z, x, y, z + 4) -- wall diamond
            Proj.line(x, y, z + 4, x, y - 4, z)
            Proj.line(x, y - 4, z, x, y, z - 4)
            Proj.line(x, y, z - 4, x, y + 4, z)
            Proj.line(x, y, z, x - h.side * 4, y, z) -- barrel stub
        end
    end
end

local function drawEndWall()
    local endZ = G.trenchEnd
    if endZ - G.camZ > 900 then return end
    local W, H = C.TRENCH_W, C.TRENCH_H
    Proj.line(-W, 0, endZ, W, 0, endZ)
    Proj.line(-W, H, endZ, W, H, endZ)
    Proj.line(-W, 0, endZ, -W, H, endZ)
    Proj.line(W, 0, endZ, W, H, endZ)
    local py, pw, ph = C.PORT_Y, C.PORT_W, C.PORT_H
    Proj.line(-pw, py - ph, endZ, pw, py - ph, endZ)
    Proj.line(pw, py - ph, endZ, pw, py + ph, endZ)
    Proj.line(pw, py + ph, endZ, -pw, py + ph, endZ)
    Proj.line(-pw, py + ph, endZ, -pw, py - ph, endZ)
    if endZ - G.camZ < C.PORT_RANGE and Attract.frame % 10 < 6 then
        -- in-range chevrons blinking beside the port window
        Proj.line(-pw - 7, py, endZ, -pw - 2, py, endZ)
        Proj.line(pw + 2, py, endZ, pw + 7, py, endZ)
    end
end

local function drawFireballs()
    for _, f in ipairs(G.fireballs) do
        local sx, sy, z = Proj.point(f.x, f.y, f.z)
        if sx then
            local r = math.min(math.max(C.FB_R * Proj.focal / z, 2), 22)
            gfx.drawCircleAtPoint(sx, sy, Attract.frame % 4 < 2 and r or r * 0.7)
        end
    end
end

local function drawLasers()
    if #G.lasers == 0 then return end
    gfx.setLineWidth(2)
    for _, l in ipairs(G.lasers) do
        gfx.drawLine(0, Field.H - 1, l.x, l.y)
        gfx.drawLine(Field.W - 1, Field.H - 1, l.x, l.y)
    end
    gfx.setLineWidth(1)
end

local function drawCrosshair()
    if G.invulnT > 0 and Attract.frame % 4 < 2 then return end -- hit blink
    local x, y = G.crossX, G.crossY
    gfx.drawLine(x - 10, y, x - 4, y)
    gfx.drawLine(x + 4, y, x + 10, y)
    gfx.drawLine(x, y - 10, x, y - 4)
    gfx.drawLine(x, y + 4, x, y + 10)
    gfx.drawRect(x - 1, y - 1, 3, 3)
end

local function drawHud()
    Beams.print(tostring(G.score), 8, 6, 11)
    Beams.print("HI " .. Attract.high, Field.W / 2, 6, 7, { align = "center" })
    for i = 1, G.shields do -- shield pips
        gfx.fillRect(Field.W - 6 - i * 9, 7, 6, 9)
    end
    Beams.print("LVL " .. G.level, 8, Field.H - 16, 8)
    Beams.print(string.format("X%.1f", G.mult()), Field.W - 8, Field.H - 16, 8, { align = "right" })
    local w = 60 -- throttle gauge
    gfx.drawRect(Field.W / 2 - w / 2, Field.H - 13, w, 6)
    gfx.fillRect(Field.W / 2 - w / 2, Field.H - 13, w * G.throttle, 6)
    if G.bannerT > 0 and G.banner then
        Beams.print(G.banner, Field.W / 2, 34, 12, { align = "center", weight = 1 })
    end
end

function Draw.play()
    Proj.setCamera(G.camX, G.camY, G.camZ, 0, 0)
    if G.phase == "approach" then
        drawStars()
        for _, f in ipairs(G.fighters) do
            Proj.model(FIGHTER, f.x, f.y, f.z, f.yaw)
        end
    elseif G.phase == "towers" then
        drawGrid(G.camX, G.camZ)
        for _, t in ipairs(G.towers) do
            Proj.model(TOWER, t.x, t.y, t.z, 0)
        end
    else
        Draw.trenchWalls(G.camZ, G.trenchEnd, G.braces)
        drawHardpoints()
        drawEndWall()
    end
    drawFireballs()
    drawLasers()
    drawCrosshair()
    drawHud()
end

-- title/over backdrop: an endless trench flythrough with a lazy weave
local ambZ = 0
function Draw.tickAmbient(dt)
    ambZ = ambZ + 90 * dt
end

function Draw.ambient()
    Proj.setCamera(math.sin(ambZ * 0.011) * 14, 26 + math.sin(ambZ * 0.007) * 9, ambZ, 0, 0)
    Draw.trenchWalls(ambZ, nil, nil)
end
