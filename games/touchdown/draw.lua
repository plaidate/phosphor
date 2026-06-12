-- Touchdown rendering: terrain polyline, pad multipliers in beam digits,
-- the lander with a throttle-proportional flame, gauge, and HUD.

local gfx <const> = playdate.graphics

Draw = {}

local LANDER <const> = Shapes.new({
    -- ascent cabin
    { -3, -9, 3, -9, 6, -5, 6, -2, -6, -2, -6, -5, -3, -9 },
    -- descent stage
    { -6, -2, 6, -2, 6, 3, -6, 3, -6, -2 },
    -- legs and feet
    { -5, 3, -7, 8 }, { 5, 3, 7, 8 },
    { -8.5, 8, -5.5, 8 }, { 5.5, 8, 8.5, 8 },
})

function Draw.terrain()
    local pts = G.terrain
    if not pts then return end
    for i = 3, #pts - 1, 2 do
        gfx.drawLine(pts[i - 2], pts[i - 1], pts[i], pts[i + 1])
    end
    for _, p in ipairs(G.pads or {}) do
        gfx.setLineWidth(3)
        gfx.drawLine(p.x1, p.y, p.x2, p.y)
        gfx.setLineWidth(1)
        Beams.print("X" .. p.mult, (p.x1 + p.x2) / 2, p.y + 4, 6, { align = "center" })
    end
end

function Draw.lander()
    local l = G.lander
    if not l or l.dead then return end
    Shapes.draw(LANDER, l.x, l.y, l.tilt)
    if G.mode == "fly" and l.thrust > 0 and Attract.frame % 2 == 0 then
        local len = 4 + l.thrust * 14 + math.random() * 2
        Shapes.draw({ { -2.5, 4, 0, 4 + len, 2.5, 4 } }, l.x, l.y, l.tilt)
    end
end

local function gauge()
    local l = G.lander
    local x, y, h = 8, 70, 110
    gfx.drawRect(x, y, 7, h)
    local fill = math.floor((l and l.throttle or 0) / 100 * (h - 2))
    if fill > 0 then
        gfx.fillRect(x + 1, y + h - 1 - fill, 5, fill)
    end
    Beams.print("THR", x + 3, y + h + 5, 5, { align = "center" })
end

-- right-aligned readout that can flash when out of limits
local function readout(label, val, y, hot)
    if hot and Attract.frame % 4 < 2 then return end
    Beams.print(label, Field.W - 52, y, 7)
    Beams.print(tostring(val), Field.W - 8, y, 7, { align = "right" })
end

function Draw.hud()
    local l = G.lander
    Beams.print(tostring(G.score), 10, 8, 12, { weight = 1 })
    for i = 1, math.min(G.landers, 6) do
        Shapes.draw(LANDER, 4 + 16 * i, 34, 0, 0.7)
    end

    if l then
        local vx, vy = math.floor(l.vx + 0.5), math.floor(l.vy + 0.5)
        readout("ALT", math.floor(Lander.altitude()), 8, false)
        readout("VX", vx, 20, math.abs(l.vx) >= C.SAFE_VX)
        readout("VY", vy, 32, l.vy >= C.SAFE_VY)
        readout("FUEL", math.floor(G.fuel), 44, G.fuel < 20)
    end
    gauge()
end

function Draw.play()
    Draw.terrain()
    Draw.lander()
    Draw.hud()
    if G.msg then
        Beams.print(G.msg, Field.W / 2, 78, 12, { align = "center", weight = 2 })
    elseif G.fuelOut and Attract.frame % 20 < 12 then
        Beams.print("OUT OF FUEL", Field.W / 2, 78, 10, { align = "center" })
    end
end

-- the title screen's backdrop: just the moonscape waiting below
function Draw.ambient()
    Draw.terrain()
end
