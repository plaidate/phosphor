-- Touchdown terrain: a jagged vector skyline walked left to right, with
-- 2-4 flat landing pads of differing widths (narrower pad = bigger
-- multiplier). One pad per horizontal region keeps them spread out.

Terrain = {}

local clamp = Util.clamp

local function shuffle(t)
    for i = #t, 2, -1 do
        local j = math.random(i)
        t[i], t[j] = t[j], t[i]
    end
end

function Terrain.generate()
    local pts, pads = {}, {}

    local specs = {}
    for _, s in ipairs(C.PAD_SPECS) do specs[#specs + 1] = s end
    shuffle(specs)

    local padCount = math.random(2, 4)
    local region = Field.W / padCount
    for i = 1, padCount do
        local spec = specs[(i - 1) % #specs + 1]
        local w = spec[1]
        local cx = (i - 0.5) * region + (math.random() - 0.5) * region * 0.44
        local x1 = clamp(cx - w / 2, 8, Field.W - 8 - w)
        pads[#pads + 1] = { x1 = x1, x2 = x1 + w, y = 0, mult = spec[2] }
    end

    -- random walk across the screen, flattening through each pad
    local y = math.random(C.TERRAIN_MIN_Y + 20, C.TERRAIN_MAX_Y - 6)
    local x = 0
    pts[1], pts[2] = 0, y
    local pi = 1
    while x < Field.W do
        local pad = pads[pi]
        local step = math.random(12, 30)
        if pad and x + step >= pad.x1 then
            y = clamp(y + math.random(-20, 20), C.TERRAIN_MIN_Y + 30, C.TERRAIN_MAX_Y)
            pad.y = y
            pts[#pts + 1] = pad.x1; pts[#pts + 1] = y
            pts[#pts + 1] = pad.x2; pts[#pts + 1] = y
            x = pad.x2
            pi = pi + 1
        else
            x = math.min(x + step, Field.W)
            y = clamp(y + math.random(-26, 26), C.TERRAIN_MIN_Y, C.TERRAIN_MAX_Y)
            pts[#pts + 1] = x; pts[#pts + 1] = y
        end
    end

    G.terrain = pts
    G.pads = pads
end

-- ground height (screen y) under x, linearly interpolated
function Terrain.heightAt(x)
    local pts = G.terrain
    if not pts then return Field.H end
    if x <= pts[1] then return pts[2] end
    for i = 3, #pts - 1, 2 do
        local xi = pts[i]
        if x <= xi then
            local x0, y0 = pts[i - 2], pts[i - 1]
            local t = (x - x0) / math.max(xi - x0, 1e-6)
            return y0 + (pts[i + 1] - y0) * t
        end
    end
    return pts[#pts]
end

function Terrain.padUnder(x)
    for _, p in ipairs(G.pads or {}) do
        if x >= p.x1 and x <= p.x2 then return p end
    end
    return nil
end
