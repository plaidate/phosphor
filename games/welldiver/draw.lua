-- Welldiver rendering: the well and its residents as beam lines, every
-- character via Beams — no system font anywhere.
--
-- The rework lives here: per-level line styling, cartwheeling flippers that
-- pivot around the shared lane edge, the two-pronged claw, spinning
-- tri-spike enemy shots, growing spiral spikers, animated pulsar zigzags,
-- Superzapper lane lightning, and the warp's streaks and rushing rings.

local gfx <const> = playdate.graphics

Draw = {}

-- per-level line styling: rim weight and spoke dash pattern cycle with the
-- level, so each trip down the well reads differently
local STYLES <const> = {
    { rimW = 2, dash = nil },        -- classic solid
    { rimW = 2, dash = { 6, 3 } },   -- dashed spokes
    { rimW = 3, dash = nil },        -- heavy rim
    { rimW = 1, dash = { 2, 4 } },   -- dotted spokes, thin rim
    { rimW = 2, dash = { 9, 4 } },   -- long dashes
    { rimW = 3, dash = { 3, 5 } },   -- heavy rim, sparse dots
}

local function levelStyle()
    return STYLES[(G.level - 1) % #STYLES + 1]
end

local function dashLine(x0, y0, x1, y1, on, off)
    local dx, dy = x1 - x0, y1 - y0
    local len = math.sqrt(dx * dx + dy * dy)
    if len < 1 then return end
    local ux, uy = dx / len, dy / len
    local d = 0
    while d < len do
        local e = math.min(d + on, len)
        gfx.drawLine(x0 + ux * d, y0 + uy * d, x0 + ux * e, y0 + uy * e)
        d = e + off
    end
end

-- one well outline (the rim polygon) at depth z
local function outline(w, z)
    local segs = w.closed and w.npts or w.npts - 1
    for i = 0, segs - 1 do
        local x1, y1 = Wells.edge(w, i, z)
        local x2, y2 = Wells.edge(w, i + 1, z)
        gfx.drawLine(x1, y1, x2, y2)
    end
end

function Draw.well()
    local w = G.well
    local st = levelStyle()
    gfx.setLineWidth(1)

    -- spokes, in this level's pattern
    for i = 0, w.npts - 1 do
        local x0, y0 = Wells.edge(w, i, 0)
        local x1, y1 = Wells.edge(w, i, 1)
        if st.dash then
            dashLine(x0, y0, x1, y1, st.dash[1], st.dash[2])
        else
            gfx.drawLine(x0, y0, x1, y1)
        end
    end

    -- rim and far rim
    gfx.setLineWidth(st.rimW)
    outline(w, 1)
    gfx.setLineWidth(1)
    outline(w, 0)

    -- the claw's lane glows: solid, thicker spokes on both edges
    if Attract.state == "play" and G.player and G.player.alive then
        local lane = Player.lane()
        gfx.setLineWidth(2)
        for _, i in ipairs({ lane, lane + 1 }) do
            local x1, y1 = Wells.edge(w, i, 1)
            local x0, y0 = Wells.edge(w, i, 0)
            gfx.drawLine(x0, y0, x1, y1)
        end
        gfx.setLineWidth(1)
    end
end

function Draw.spikes()
    local w = G.well
    for lane = 0, w.lanes - 1 do
        local h = G.spikes[lane] or 0
        if h > 0.02 then
            local x0, y0 = Wells.laneCenter(w, lane, 0)
            local x1, y1 = Wells.laneCenter(w, lane, h)
            gfx.drawLine(x0, y0, x1, y1)
            gfx.drawCircleAtPoint(x1, y1, 1.5) -- glinting tip
        end
    end
end

-- the claw: a two-pronged C gripping the rim, hooks curling over the mouth
function Draw.claw()
    if not G.player or not G.player.alive then return end
    local w = G.well
    local lane = Player.lane()
    local x1, y1 = Wells.edge(w, lane, 1)
    local x2, y2 = Wells.edge(w, lane + 1, 1)
    local mx, my = (x1 + x2) / 2, (y1 + y2) / 2
    local ox, oy = Wells.outward(w, lane)
    local t1x, t1y = x1 + ox * 12, y1 + oy * 12 -- prong tips
    local t2x, t2y = x2 + ox * 12, y2 + oy * 12
    local h1x, h1y = t1x + (t2x - t1x) * 0.3, t1y + (t2y - t1y) * 0.3 -- hooks
    local h2x, h2y = t2x + (t1x - t2x) * 0.3, t2y + (t1y - t2y) * 0.3
    local nx, ny = mx - ox * 3, my - oy * 3 -- inner notch

    gfx.setLineWidth(2)
    gfx.drawLine(x1, y1, nx, ny) -- the C's back, dipping into the well
    gfx.drawLine(nx, ny, x2, y2)
    gfx.drawLine(x1, y1, t1x, t1y) -- prongs
    gfx.drawLine(x2, y2, t2x, t2y)
    gfx.drawLine(t1x, t1y, h1x, h1y) -- hooks curling toward each other
    gfx.drawLine(t2x, t2y, h2x, h2y)
    gfx.setLineWidth(1)
end

-- flippers: a bowtie chevron across the lane. Mid-flip it cartwheels around
-- the edge shared with the lane it is flipping from.
local function drawFlipper(e)
    local w = G.well
    local ax, ay, bx, by
    if e.flipAnim and e.flipAnim > 0 and e.flipDir then
        local pivotI = (e.flipDir == 1) and e.lane or e.lane + 1
        local farI = (e.flipDir == 1) and e.lane + 1 or e.lane
        local px, py = Wells.edge(w, pivotI, e.z)
        local qx, qy = Wells.edge(w, farI, e.z)
        local vx, vy = qx - px, qy - py
        -- sweep over the well mouth: pick the rotation sense whose arc
        -- bulges outward, and unwind it as the animation runs out
        local ox, oy = Wells.outward(w, e.lane)
        local sense = ((-vy) * ox + vx * oy) >= 0 and 1 or -1
        local t = math.min(e.flipAnim / C.FLIP_ANIM, 1)
        local rvx, rvy = Vec.rot(vx, vy, sense * t * math.pi)
        ax, ay, bx, by = px, py, px + rvx, py + rvy
    else
        ax, ay = Wells.edge(w, e.lane, e.z)
        bx, by = Wells.edge(w, e.lane + 1, e.z)
    end
    local mx, my = (ax + bx) / 2, (ay + by) / 2
    local cx, cy = -(by - ay) * 0.3, (bx - ax) * 0.3
    gfx.drawLine(ax, ay, mx + cx, my + cy)
    gfx.drawLine(mx + cx, my + cy, bx, by)
    gfx.drawLine(ax, ay, mx - cx, my - cy)
    gfx.drawLine(mx - cx, my - cy, bx, by)
end

local function drawTanker(e)
    local w = G.well
    local mx, my = Wells.laneCenter(w, e.lane, e.z)
    local s = 9 * Wells.persp(e.z)
    gfx.drawLine(mx - s, my, mx, my - s)
    gfx.drawLine(mx, my - s, mx + s, my)
    gfx.drawLine(mx + s, my, mx, my + s)
    gfx.drawLine(mx, my + s, mx - s, my)
    gfx.drawLine(mx - s * 0.5, my, mx + s * 0.5, my) -- the flippers inside
end

-- spikers: a spiral arc that grows as the spike beneath it builds, slowly
-- rotating like a drill bit
local function drawSpiker(e)
    local mx, my = Wells.laneCenter(G.well, e.lane, e.z)
    local grown = 0.35 + 0.65 * math.min(1, e.z / (e.turnAt or 0.6))
    local rmax = 8 * Wells.persp(e.z) * grown
    local a0 = Attract.frame * 0.22
    local steps = 14
    local px, py
    for i = 0, steps do
        local t = i / steps
        local a = a0 + t * math.pi * 3.5
        local r = rmax * (0.12 + 0.88 * t)
        local x, y = mx + math.cos(a) * r, my + math.sin(a) * r
        if px then gfx.drawLine(px, py, x, y) end
        px, py = x, y
    end
end

local function drawFuseball(e)
    local mx, my = Wells.laneCenter(G.well, e.lane, e.z)
    local s = 7 * Wells.persp(e.z)
    for _ = 1, 5 do
        local a = math.random() * math.pi * 2
        gfx.drawLine(mx, my, mx + math.cos(a) * s, my + math.sin(a) * s)
    end
end

-- jagged lightning down a lane, far end to depth zTop
local function laneLightning(w, lane, zTop)
    local px, py = Wells.laneCenter(w, lane, 0)
    local n = 6
    for i = 1, n do
        local z = (i / n) * zTop
        local x, y = Wells.laneCenter(w, lane, z)
        if i < n then
            local j = 5 * Wells.persp(z)
            x = x + (math.random() * 2 - 1) * j
            y = y + (math.random() * 2 - 1) * j
        end
        gfx.drawLine(px, py, x, y)
        px, py = x, y
    end
end

-- pulsars: a zigzag whose teeth breathe; firing, the whole lane lights up
local function drawPulsar(e)
    local w = G.well
    local x1, y1 = Wells.edge(w, e.lane, e.z)
    local x2, y2 = Wells.edge(w, e.lane + 1, e.z)
    local amp = 2.5 + 1.5 * math.sin(Attract.frame * 0.45)
    if e.pulsing > 0 then
        amp = 4 + 2.5 * math.sin(Attract.frame * 1.3)
    end
    local nx, ny = -(y2 - y1), (x2 - x1)
    local d = math.sqrt(nx * nx + ny * ny)
    if d > 0 then nx, ny = nx / d, ny / d end
    local n = 6
    local lx, ly = x1, y1
    for i = 1, n do
        local t = i / n
        local px = x1 + (x2 - x1) * t
        local py = y1 + (y2 - y1) * t
        if i < n then
            local off = (i % 2 == 0) and amp or -amp
            px = px + nx * off
            py = py + ny * off
        end
        gfx.drawLine(lx, ly, px, py)
        lx, ly = px, py
    end
    -- the electrified lane crackles all the way down
    if e.pulsing > 0 and Attract.frame % 2 == 0 then
        laneLightning(w, e.lane, 1)
    end
end

function Draw.enemies()
    for _, e in ipairs(G.enemies) do
        if e.type == "flipper" then
            drawFlipper(e)
        elseif e.type == "tanker" then
            drawTanker(e)
        elseif e.type == "spiker" then
            drawSpiker(e)
        elseif e.type == "fuseball" then
            drawFuseball(e)
        elseif e.type == "pulsar" then
            drawPulsar(e)
        end
    end
end

function Draw.shots()
    local w = G.well
    for _, b in ipairs(G.pShots) do
        local x, y = Wells.laneCenter(w, b.lane, b.z)
        local s = math.max(1, 2.5 * Wells.persp(b.z))
        gfx.fillRect(x - s / 2, y - s / 2, s, s)
    end
    -- enemy shots: spinning tri-spikes
    for _, s in ipairs(G.eShots) do
        local x, y = Wells.laneCenter(w, s.lane, s.z)
        local r = math.max(1.5, 4.5 * Wells.persp(s.z))
        for k = 0, 2 do
            local a = math.rad(s.spin + k * 120)
            gfx.drawLine(x, y, x + math.cos(a) * r, y + math.sin(a) * r)
        end
    end
end

-- the Superzapper discharge: lightning down every lane while the bolt lasts
function Draw.zapBolt()
    if G.zapBolt <= 0 or Attract.frame % 2 == 1 then return end
    local w = G.well
    for lane = 0, w.lanes - 1 do
        laneLightning(w, lane, 1)
    end
end

-- warp dressing: star streaks radiating from the depths, and well outlines
-- rushing outward past the camera
function Draw.warpFx()
    local w = G.well
    for _, r in ipairs(G.warpRings) do
        outline(w, r.z)
    end
    local cx, cy = w.fcx, w.fcy
    for _, s in ipairs(G.warpStreaks) do
        local ca, sa = math.cos(s.a), math.sin(s.a)
        local d2 = s.d + 5 + s.d * 0.3
        gfx.drawLine(cx + ca * s.d, cy + sa * s.d * 0.63,
            cx + ca * d2, cy + sa * d2 * 0.63)
    end
end

local function miniClaw(x, y)
    gfx.drawLine(x - 4, y + 7, x - 4, y) -- prongs
    gfx.drawLine(x + 4, y + 7, x + 4, y)
    gfx.drawLine(x - 4, y, x - 2, y + 2) -- hooks
    gfx.drawLine(x + 4, y, x + 2, y + 2)
    gfx.drawLine(x - 4, y + 7, x + 4, y + 7) -- base
end

function Draw.hud()
    Beams.print(tostring(G.score), 8, 6, 12, { weight = 1 })
    Beams.print("LV " .. G.level, Field.W - 8, 6, 9, { align = "right" })
    for i = 1, math.min(G.lives, C.MAX_LIVES) do
        miniClaw(146 + i * 16, 6)
    end
    if G.zapsUsed == 0 then
        Beams.print("ZAP", 8, Field.H - 16, 8)
    end
    if G.rechargeT > 0 and Attract.frame % 4 < 3 then
        Beams.print("SUPERZAPPER RECHARGE", Field.W / 2, 198, 8, { align = "center" })
    end
end

function Draw.play()
    Draw.well()
    Draw.spikes()
    if G.mode == "warp" then
        Draw.warpFx()
        Beams.print("AVOID SPIKES", Field.W / 2, Field.H - 18, 9, { align = "center" })
    else
        Draw.enemies()
        Draw.zapBolt()
    end
    Draw.shots()
    Draw.claw()
    Draw.hud()
end

-- the title screen's starting-level selector, drawn under Attract's chrome
local function levelSelect()
    local bonus = C.START_BONUS[G.startIdx]
    local label = bonus > 0 and ("START LEVEL  +" .. bonus) or "START LEVEL"
    Beams.print(label, Field.W / 2, 176, 7, { align = "center" })
    local n = #C.START_LEVELS
    local x0 = Field.W / 2 - (n - 1) * 18
    for i, lv in ipairs(C.START_LEVELS) do
        local x = x0 + (i - 1) * 36
        local sel = (i == G.startIdx)
        Beams.print(tostring(lv), x, 190, 9, { align = "center", weight = sel and 2 or 1 })
        if sel then
            gfx.drawRect(x - 9, 186, 18, 17)
        end
    end
end

-- backdrop behind the title and game-over cards
function Draw.ambient()
    Draw.well()
    if Attract.state == "title" then
        levelSelect()
    end
end
