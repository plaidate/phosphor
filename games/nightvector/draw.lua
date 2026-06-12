-- Night Vector rendering: thirty segments of road in the headlights — edge
-- posts, edge lines, a dashed centerline — plus roadside wireframes, traffic
-- boxes with their lights, a star field for steering feedback, and the HUD
-- with its needle speedometer. All beams on black.

local gfx <const> = playdate.graphics

Draw = {}

-- roadside furniture, in Proj.model polyline form ({x,y,z, x,y,z, ...})
local TREE <const> = {
    { 0, 0, 0, 0, 1.4, 0 },
    { -1.3, 1.4, 0, 0, 3.8, 0, 1.3, 1.4, 0, -1.3, 1.4, 0 },
}
local SIGN <const> = {
    { 0, 0, 0, 0, 1.5, 0 },
    { -0.6, 2.1, 0, 0, 2.7, 0, 0.6, 2.1, 0, 0, 1.5, 0, -0.6, 2.1, 0 },
}
local OBS_MODELS <const> = { TREE, SIGN }

-- traffic: a low box with a cabin
local CARM <const> = {
    { -0.85, 0.2, -2, 0.85, 0.2, -2, 0.85, 0.2, 2, -0.85, 0.2, 2, -0.85, 0.2, -2 },
    { -0.85, 1.0, -2, 0.85, 1.0, -2, 0.85, 1.0, 2, -0.85, 1.0, 2, -0.85, 1.0, -2 },
    { -0.85, 0.2, -2, -0.85, 1.0, -2 }, { 0.85, 0.2, -2, 0.85, 1.0, -2 },
    { -0.85, 0.2, 2, -0.85, 1.0, 2 }, { 0.85, 0.2, 2, 0.85, 1.0, 2 },
    { -0.62, 1.0, -1.6, -0.55, 1.5, -0.8, -0.55, 1.5, 0.7, -0.62, 1.0, 1.3 },
    { 0.62, 1.0, -1.6, 0.55, 1.5, -0.8, 0.55, 1.5, 0.7, 0.62, 1.0, 1.3 },
    { -0.55, 1.5, -0.8, 0.55, 1.5, -0.8 },
    { -0.55, 1.5, 0.7, 0.55, 1.5, 0.7 },
}

local STARS = {}
for i = 1, 30 do
    STARS[i] = { az = math.random() * 360, h = 6 + math.random(62) }
end

local CK_SEGS <const> = C.CK_M // C.SEG

function Draw.sky(yawDeg, pitchDeg)
    local horY = Proj.cy + math.sin(math.rad(pitchDeg)) * Proj.focal
    for i = 1, #STARS do
        local st = STARS[i]
        local d = (st.az - yawDeg + 180) % 360 - 180
        if d > -34 and d < 34 then
            gfx.drawPixel(Proj.cx + math.tan(math.rad(d)) * Proj.focal, horY - st.h)
        end
    end
    Proj.horizon()
end

function Draw.road(seg0)
    Road.ensure(seg0 + C.DRAW_SEGS + 2)
    local hw = C.HALF_W
    local p = Road.point(seg0)
    local plx, plz = p.x - p.fz * hw, p.z + p.fx * hw
    local prx, prz = p.x + p.fz * hw, p.z - p.fx * hw
    local py = p.y
    for i = seg0 + 1, seg0 + C.DRAW_SEGS do
        local q = Road.point(i)
        local qlx, qlz = q.x - q.fz * hw, q.z + q.fx * hw
        local qrx, qrz = q.x + q.fz * hw, q.z - q.fx * hw
        -- edge lines and the classic edge posts
        Proj.line(plx, py, plz, qlx, q.y, qlz)
        Proj.line(prx, py, prz, qrx, q.y, qrz)
        Proj.line(qlx, q.y, qlz, qlx, q.y + C.POST_H, qlz)
        Proj.line(qrx, q.y, qrz, qrx, q.y + C.POST_H, qrz)
        -- dashed centerline
        if i % 2 == 0 then
            local r = Road.point(i + 1)
            Proj.line(q.x, q.y, q.z,
                      q.x + (r.x - q.x) * 0.55, q.y + (r.y - q.y) * 0.55,
                      q.z + (r.z - q.z) * 0.55)
        end
        -- checkpoint gate every kilometre
        if (i - 1) % CK_SEGS == 0 and i > 1 then
            local gh = 4.4
            Proj.line(qlx, q.y, qlz, qlx, q.y + gh, qlz)
            Proj.line(qrx, q.y, qrz, qrx, q.y + gh, qrz)
            Proj.line(qlx, q.y + gh, qlz, qrx, q.y + gh, qrz)
        end
        -- roadside obstacle
        local o = q.obs
        if o then
            Proj.model(OBS_MODELS[o.kind],
                       q.x + q.fz * o.off * o.side, q.y,
                       q.z - q.fx * o.off * o.side, q.h)
        end
        plx, plz, prx, prz, py = qlx, qlz, qrx, qrz, q.y
    end
end

function Draw.traffic(camS)
    local range = C.DRAW_SEGS * C.SEG
    for _, t in ipairs(G.traffic) do
        local ds = t.s - camS
        if ds > -25 and ds < range then
            local x, y, z, h = Road.posAt(t.s, t.lat)
            local yaw = t.dir == 1 and h or h + 180
            Proj.model(CARM, x, y, z, yaw)
            -- lights: tail dots going our way, headlight blobs coming at us
            local r = math.rad(yaw)
            local s_, c_ = math.sin(r), math.cos(r)
            local mz = t.dir == 1 and -2.02 or 2.02 -- the face we see
            for side = -1, 1, 2 do
                local mx = side * 0.5
                local sx, sy = Proj.point(x + mx * c_ + mz * s_, y + 0.6,
                                          z - mx * s_ + mz * c_)
                if sx then
                    if t.dir == 1 then
                        gfx.fillRect(sx - 1, sy - 1, 2, 2)
                    else
                        gfx.fillRect(sx - 1, sy - 1, 3, 3)
                    end
                end
            end
        end
    end
end

local function speedo(kph)
    local cx, cy, r = 366, 220, 20
    for k = 0, 180, 30 do
        local a = math.rad(200 - k / 180 * 220)
        local ca, sa = math.cos(a), math.sin(a)
        gfx.drawLine(cx + ca * r * 0.76, cy - sa * r * 0.76, cx + ca * r, cy - sa * r)
    end
    local a = math.rad(200 - math.min(kph, 180) / 180 * 220)
    gfx.setLineWidth(2)
    gfx.drawLine(cx, cy, cx + math.cos(a) * r * 0.88, cy - math.sin(a) * r * 0.88)
    gfx.setLineWidth(1)
    Beams.print(tostring(math.floor(kph + 0.5)), cx - r - 8, 214, 11, { align = "right" })
end

local function hud(c)
    Beams.print(tostring(G.score), 8, 6, 10)
    local t = math.ceil(G.time)
    if G.time >= 6 or Attract.frame % 16 < 10 then
        Beams.print("TIME " .. t, Field.W - 8, 6, 12, { align = "right", weight = G.time < 6 and 2 or 1 })
    end
    Beams.print(string.format("%.1f KM", c.dist / 1000), 8, 226, 9)
    Beams.print("CARS " .. G.cars, 96, 226, 9)
    speedo(c.speed * 3.6)

    if G.msgT > 0 and G.msg then
        Beams.print(G.msg, Proj.cx, 70, 14, { align = "center", weight = 2 })
    end
    if c.crashT > 0 then
        Beams.print("CRASHED", Proj.cx, 96, 22, { align = "center", weight = 2 })
        if G.cars > 0 then
            Beams.print(G.cars .. (G.cars == 1 and " CAR LEFT" or " CARS LEFT"),
                        Proj.cx, 126, 10, { align = "center" })
        end
    end
end

-- the wireframe hood: the only part of our own car in frame
local function cockpit()
    gfx.drawLine(82, 239, 140, 225)
    gfx.drawLine(140, 225, 260, 225)
    gfx.drawLine(260, 225, 318, 239)
end

function Draw.play()
    local c = G.car
    local _, py = Road.posAt(c.s, 0)
    local pitch = math.deg(math.atan((Road.point(c.seg + 5).y - py) / (5 * C.SEG))) * 0.8
    local jx, jy, jyaw = 0, 0, 0
    if G.shake > 0 and c.crashT <= 0 then
        jx = (math.random() - 0.5) * 0.12 * G.shake
        jy = (math.random() - 0.5) * 0.10 * G.shake
        jyaw = (math.random() - 0.5) * 1.1 * G.shake
    end
    Proj.setCamera(c.x + jx, py + C.EYE + jy, c.z, c.yaw + jyaw, pitch)

    Draw.sky(c.yaw + jyaw, pitch)
    Draw.road(c.seg)
    Draw.traffic(c.s)
    cockpit()
    hud(c)
end

-- the attract flythrough: an empty road unwinding behind the title
function Draw.ambient()
    local s = G.demo.s
    local x, y, z, h = Road.posAt(s, 0)
    local seg = math.floor(s / C.SEG) + 1
    local pitch = math.deg(math.atan((Road.point(seg + 5).y - y) / (5 * C.SEG))) * 0.8
    Proj.setCamera(x, y + C.EYE, z, h, pitch)
    Draw.sky(h, pitch)
    Draw.road(seg)
end
