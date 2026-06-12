-- Night Vector: the procedural road. A centerline of 10 m segments whose
-- curvature and grade wander smoothly; each point caches its heading basis
-- so locating and rendering are pure arithmetic. Points are generated on
-- demand ahead of whoever asks and kept for the whole run (1 km = 100 small
-- tables, so a long night is still only a few thousand entries).
--
-- Conventions match Proj: X right, Y up, Z forward. heading h in degrees,
-- forward = (sin h, cos h) in the XZ plane, right = (fz, -fx). Positive
-- curvature bends the road to the right; positive lat is right of center.

local clamp = Util.clamp

Road = {}

local pts = {}
local st = {} -- generator state: current/target curvature and grade

function Road.reset()
    pts = { { x = 0, y = 0, z = 0, h = 0, fx = 0, fz = 1, curv = 0 } }
    st = { curv = 0, curvT = 0, curvHold = 14, slope = 0, slopeT = 0, slopeHold = 18 }
end

local function genNext()
    local i = #pts + 1
    local p = pts[#pts]
    if i > 12 then -- the first dozen segments leave the start straight & flat
        st.curvHold = st.curvHold - 1
        if st.curvHold <= 0 then
            st.curvT = (math.random() * 2 - 1) * C.CURV_MAX
            if math.random() < 0.3 then st.curvT = 0 end -- breathe with straights
            st.curvHold = math.random(C.CURV_HOLD[1], C.CURV_HOLD[2])
        end
        st.slopeHold = st.slopeHold - 1
        if st.slopeHold <= 0 then
            st.slopeT = (math.random() * 2 - 1) * C.HILL_MAX
            if math.random() < 0.35 then st.slopeT = 0 end
            st.slopeHold = math.random(C.HILL_HOLD[1], C.HILL_HOLD[2])
        end
    end
    st.curv = st.curv + clamp(st.curvT - st.curv, -C.CURV_SLEW, C.CURV_SLEW)
    st.slope = st.slope + clamp(st.slopeT - st.slope, -C.HILL_SLEW, C.HILL_SLEW)

    local h = p.h + st.curv
    local r = math.rad(h)
    local fx, fz = math.sin(r), math.cos(r)
    local q = {
        x = p.x + fx * C.SEG,
        y = p.y + st.slope,
        z = p.z + fz * C.SEG,
        h = h, fx = fx, fz = fz, curv = st.curv,
    }
    if i > 18 and math.random() < C.OBSTACLE_P then
        q.obs = {
            side = math.random() < 0.5 and -1 or 1,
            off = C.HALF_W + 1.2 + math.random() * 4, -- metres off the centerline
            kind = math.random() < 0.6 and 1 or 2,    -- 1 tree, 2 sign
        }
    end
    pts[i] = q
end

function Road.ensure(n)
    while #pts < n do genNext() end
end

function Road.point(i)
    if not pts[i] then Road.ensure(i) end
    return pts[i]
end

-- Track a moving world position against the centerline. Returns the segment
-- index, distance along it, and signed lateral offset (positive = right).
function Road.locate(seg, x, z)
    for _ = 1, 12 do
        local p = Road.point(seg)
        local dx, dz = x - p.x, z - p.z
        local along = dx * p.fx + dz * p.fz
        if along > C.SEG then
            seg = seg + 1
        elseif along < 0 and seg > 1 then
            seg = seg - 1
        else
            return seg, along, dx * p.fz - dz * p.fx
        end
    end
    local p = Road.point(seg)
    local dx, dz = x - p.x, z - p.z
    return seg, dx * p.fx + dz * p.fz, dx * p.fz - dz * p.fx
end

-- World position for a road coordinate (s metres along, lat to the right).
function Road.posAt(s, lat)
    if s < 0 then s = 0 end
    local i = math.floor(s / C.SEG) + 1
    Road.ensure(i + 1)
    local p, q = pts[i], pts[i + 1]
    local along = s - (i - 1) * C.SEG
    local t = along / C.SEG
    return p.x + p.fx * along + p.fz * lat,
           p.y + (q.y - p.y) * t,
           p.z + p.fz * along - p.fx * lat,
           p.h + (q.h - p.h) * t
end

-- Mean signed curvature (deg/segment) over a window of segments ahead.
function Road.curveAhead(seg, from, to)
    local sum = 0
    for i = seg + from, seg + to do
        sum = sum + Road.point(i).curv
    end
    return sum / (to - from + 1)
end
