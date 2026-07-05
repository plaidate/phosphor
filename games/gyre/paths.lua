-- Swoop paths: Catmull-Rom splines through waypoints in unit space
-- (1.0 = the rim). Entry patterns burst out of the center, curl past the
-- rim and fall back to the hub; attack runs leave the hub, graze the
-- player's orbit and return. Chance-stage runs exit off-field instead.

Paths = {}

local clamp = Util.clamp

-- append a polar waypoint to a flat point list
local function pt(list, a, r)
    local rad = math.rad(a)
    list[#list + 1] = math.cos(rad) * r
    list[#list + 1] = math.sin(rad) * r
end

local function ptXY(list, x, y)
    list[#list + 1] = x
    list[#list + 1] = y
end

-- Catmull-Rom through the waypoints; t in [0,1] across the whole chain
function Paths.eval(pts, t)
    local n = #pts // 2
    if n == 1 or t <= 0 then return pts[1], pts[2] end
    if t >= 1 then return pts[n * 2 - 1], pts[n * 2] end
    local ft = t * (n - 1)
    local i = math.floor(ft)
    local u = ft - i
    local function P(k)
        k = clamp(k, 0, n - 1)
        return pts[k * 2 + 1], pts[k * 2 + 2]
    end
    local x0, y0 = P(i - 1)
    local x1, y1 = P(i)
    local x2, y2 = P(i + 1)
    local x3, y3 = P(i + 2)
    local u2, u3 = u * u, u * u * u
    local function cr(a, b, c, d)
        return 0.5 * (2 * b + (-a + c) * u
            + (2 * a - 5 * b + 4 * c - d) * u2
            + (-a + 3 * b - 3 * c + d) * u3)
    end
    return cr(x0, x1, x2, x3), cr(y0, y1, y2, y3)
end

-- rough arc length (waypoint chords), for duration = length / speed
local function chordLen(pts)
    local l = 0
    for i = 3, #pts - 1, 2 do
        l = l + Vec.len(pts[i] - pts[i - 2], pts[i + 1] - pts[i - 1])
    end
    return l
end

function Paths.make(pts, speed)
    return { pts = pts, dur = math.max(chordLen(pts) / speed, 0.7) }
end

-- ---- entry patterns -------------------------------------------------------
-- th = squad base angle, s = +/-1 mirror. All start at the center and end
-- back near the hub (the caller settles the ship into its slot from there).

local function weave(th, s)
    local p = {}
    pt(p, th, 0.04)
    pt(p, th + 35 * s, 0.34)
    pt(p, th - 12 * s, 0.6)
    pt(p, th + 48 * s, 0.88)
    pt(p, th + 18 * s, 1.08)
    pt(p, th + 66 * s, 0.62)
    pt(p, th + 84 * s, 0.24)
    return p
end

local function loop(th, s)
    local p = {}
    pt(p, th, 0.04)
    pt(p, th + 15 * s, 0.5)
    -- a loop-de-loop around a pivot two-thirds of the way out
    local pr = math.rad(th + 28 * s)
    local cx, cy = math.cos(pr) * 0.72, math.sin(pr) * 0.72
    for k = 0, 4 do
        local phi = math.rad(th) + s * (k / 4) * 2 * math.pi
        ptXY(p, cx + math.cos(phi) * 0.3, cy + math.sin(phi) * 0.3)
    end
    pt(p, th + 55 * s, 0.5)
    pt(p, th + 70 * s, 0.2)
    return p
end

local function graze(th, s)
    -- out to the rim, then a long arc along it: the scary one
    local p = {}
    pt(p, th, 0.04)
    pt(p, th - 20 * s, 0.5)
    pt(p, th, 0.98)
    pt(p, th + 45 * s, 1.06)
    pt(p, th + 90 * s, 1.06)
    pt(p, th + 130 * s, 0.98)
    pt(p, th + 160 * s, 0.5)
    pt(p, th + 170 * s, 0.2)
    return p
end

local function cross(th, s)
    -- across the whole tube: out one side, back through the middle
    local p = {}
    pt(p, th, 0.04)
    pt(p, th + 12 * s, 0.7)
    pt(p, th + 30 * s, 1.05)
    pt(p, th + 60 * s, 0.5)
    pt(p, th + 180, 0.6)
    pt(p, th + 205 * s, 1.02)
    pt(p, th + 190 * s, 0.45)
    pt(p, th + 180 * s, 0.18)
    return p
end

Paths.ENTRY_KINDS = { weave, loop, graze, cross }

function Paths.entry(kind, th, s, speed)
    local gen = Paths.ENTRY_KINDS[kind] or weave
    return Paths.make(gen(th, s), speed)
end

-- chance-stage run: same families, but the tail flies off past the rim
function Paths.chanceRun(kind, th, s, speed)
    local gen = Paths.ENTRY_KINDS[kind] or weave
    local p = gen(th, s)
    -- replace the fall-back-to-hub tail with an exit
    p[#p] = nil
    p[#p] = nil
    pt(p, th + 120 * s, 0.9)
    pt(p, th + 140 * s, 1.45)
    return Paths.make(p, speed)
end

-- ---- runtime paths --------------------------------------------------------

-- attack run: from (x0,y0) out past the player's angle and back to the hub
function Paths.attack(x0, y0, pa, s, homeA, homeR, speed)
    local p = {}
    ptXY(p, x0, y0)
    pt(p, pa + 55 * s, 0.45)
    pt(p, pa + 16 * s, 0.92)
    pt(p, pa - 4 * s, 1.1)
    pt(p, pa - 40 * s, 0.85)
    pt(p, pa - 60 * s, 0.45)
    pt(p, homeA, homeR)
    return Paths.make(p, speed)
end

-- recall: shot down the player mid-run, everyone glides quietly home
function Paths.recall(x0, y0, homeA, homeR, speed)
    local p = {}
    ptXY(p, x0, y0)
    local a = Vec.angleOf(x0, y0)
    pt(p, a, math.max(Vec.len(x0, y0) * 0.6, homeR + 0.1))
    pt(p, homeA, homeR)
    return Paths.make(p, speed)
end

-- leave: done with this stage, spiral off past the rim
function Paths.leave(x0, y0, s, speed)
    local p = {}
    ptXY(p, x0, y0)
    local a = Vec.angleOf(x0, y0)
    pt(p, a + 40 * s, 0.7)
    pt(p, a + 80 * s, 1.5)
    return Paths.make(p, speed)
end
