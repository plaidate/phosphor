-- Well geometry: rim shapes, perspective projection, and lane coordinates.
-- Carried over intact from the verified Tempest-style build.
--
-- A well has 16 rim points. Closed wells wrap (16 lanes); open wells don't
-- (15 lanes). Depth z runs from 0 (far end) to 1 (the rim).

Wells = {}

local NPTS <const> = 16

-- rim points from a radial function r(angle) -> scalar radius, starting at
-- the bottom of the screen; y is squashed to fit the 400x240 display
local function radialShape(rfn)
    local pts = {}
    for i = 0, NPTS - 1 do
        local a = (i / NPTS) * 2 * math.pi + math.pi / 2
        local r = rfn(a)
        pts[#pts + 1] = { x = 200 + r * math.cos(a), y = 126 + r * 0.63 * math.sin(a) }
    end
    return pts
end

local function lineShape(yfn)
    local pts = {}
    for i = 0, NPTS - 1 do
        pts[#pts + 1] = { x = 40 + i * (320 / (NPTS - 1)), y = yfn(i) }
    end
    return pts
end

local SHAPES = {
    {
        name = "circle", closed = true, fcx = 200, fcy = 126,
        pts = function()
            return radialShape(function() return 152 end)
        end,
    },
    {
        name = "square", closed = true, fcx = 200, fcy = 126,
        pts = function()
            return radialShape(function(a)
                return 1 / math.max(math.abs(math.cos(a)) / 150, math.abs(math.sin(a)) / 150)
            end)
        end,
    },
    {
        name = "star", closed = true, fcx = 200, fcy = 126,
        pts = function()
            local pts = {}
            for i = 0, NPTS - 1 do
                local a = (i / NPTS) * 2 * math.pi + math.pi / 2
                local r = (i % 2 == 0) and 152 or 95
                pts[#pts + 1] = { x = 200 + r * math.cos(a), y = 126 + r * 0.63 * math.sin(a) }
            end
            return pts
        end,
    },
    {
        name = "line", closed = false, fcx = 200, fcy = 112,
        pts = function()
            return lineShape(function() return 212 end)
        end,
    },
    {
        name = "vee", closed = false, fcx = 200, fcy = 104,
        pts = function()
            return lineShape(function(i)
                local t = math.abs(i - (NPTS - 1) / 2) / ((NPTS - 1) / 2)
                return 212 - t * 66
            end)
        end,
    },
    {
        name = "diamond", closed = true, fcx = 200, fcy = 126,
        pts = function()
            return radialShape(function(a)
                return 1 / (math.abs(math.cos(a)) / 150 + math.abs(math.sin(a)) / 150)
            end)
        end,
    },
}

function Wells.forLevel(level)
    local shape = SHAPES[(level - 1) % #SHAPES + 1]
    return {
        name = shape.name,
        pts = shape.pts(),
        closed = shape.closed,
        lanes = shape.closed and NPTS or NPTS - 1,
        npts = NPTS,
        fcx = shape.fcx, fcy = shape.fcy,
    }
end

-- perspective factor: f(0) = FAR_SCALE (far end), f(1) = 1 (rim).
-- During the warp G.warpE shrinks, ballooning the far end toward the camera.
function Wells.persp(z)
    local e = G.warpE or 1.6
    return C.FAR_SCALE + (1 - C.FAR_SCALE) * (math.max(z, 0) ^ e)
end

-- rim point index i (0-based; closed wells wrap) at depth z, in screen coords
function Wells.edge(well, i, z)
    if well.closed then i = i % well.npts end
    local p = well.pts[i + 1]
    local f = Wells.persp(z)
    return well.fcx + (p.x - well.fcx) * f, well.fcy + (p.y - well.fcy) * f
end

function Wells.laneCenter(well, lane, z)
    local x1, y1 = Wells.edge(well, lane, z)
    local x2, y2 = Wells.edge(well, lane + 1, z)
    return (x1 + x2) / 2, (y1 + y2) / 2
end

-- unit vector pointing out of the well mouth at this lane
function Wells.outward(well, lane)
    local mx, my = Wells.laneCenter(well, lane, 1)
    local fx, fy = Wells.laneCenter(well, lane, 0)
    local dx, dy = mx - fx, my - fy
    local d = math.sqrt(dx * dx + dy * dy)
    if d < 0.001 then return 0, -1 end
    return dx / d, dy / d
end
