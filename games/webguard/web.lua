-- Webguard: the spiderweb playfield. 8 radial spokes and 4 concentric
-- rings, with intersection nodes (where layers deposit eggs) precomputed.
-- One random strand shimmers brighter every frame.

local gfx <const> = playdate.graphics

Web = {}

local NRINGS <const> = #C.RINGS

function Web.spokeAngle(s)
    return s * (360 / C.SPOKES)
end

-- nodes[spoke * NRINGS + ring], spoke 0..SPOKES-1, ring 1..NRINGS
Web.nodes = {}
for s = 0, C.SPOKES - 1 do
    local dx, dy = Vec.fromAngle(Web.spokeAngle(s), 1)
    for ri = 1, NRINGS do
        Web.nodes[s * NRINGS + ri] = {
            x = C.CX + dx * C.RINGS[ri],
            y = C.CY + dy * C.RINGS[ri],
            ring = ri, spoke = s,
        }
    end
end

function Web.node(ring, spoke)
    return Web.nodes[(spoke % C.SPOKES) * NRINGS + ring]
end

-- a random neighbouring intersection (along a ring or along a spoke)
function Web.neighbor(ring, spoke)
    local opts = {}
    if ring > 1 then opts[#opts + 1] = { ring - 1, spoke } end
    if ring < NRINGS then opts[#opts + 1] = { ring + 1, spoke } end
    opts[#opts + 1] = { ring, (spoke + 1) % C.SPOKES }
    opts[#opts + 1] = { ring, (spoke - 1) % C.SPOKES }
    local pick = opts[math.random(#opts)]
    return pick[1], pick[2]
end

local function drawSpoke(s)
    local dx, dy = Vec.fromAngle(Web.spokeAngle(s), C.R_OUT)
    gfx.drawLine(C.CX, C.CY, C.CX + dx, C.CY + dy)
end

function Web.draw()
    for s = 0, C.SPOKES - 1 do
        drawSpoke(s)
    end
    for ri = 1, NRINGS do
        gfx.drawCircleAtPoint(C.CX, C.CY, C.RINGS[ri])
    end
    -- the shimmer: one strand catches the light each frame
    local pick = math.random(C.SPOKES + NRINGS)
    gfx.setLineWidth(2)
    if pick <= C.SPOKES then
        drawSpoke(pick - 1)
    else
        gfx.drawCircleAtPoint(C.CX, C.CY, C.RINGS[pick - C.SPOKES])
    end
    gfx.setLineWidth(1)
end
