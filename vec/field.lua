-- Phosphor core: the playfield — screen wrapping and wrap-aware distance.

Field = {
    W = 400,
    H = 240,
}

function Field.wrap(x, y)
    if x < 0 then x = x + Field.W elseif x >= Field.W then x = x - Field.W end
    if y < 0 then y = y + Field.H elseif y >= Field.H then y = y - Field.H end
    return x, y
end

-- shortest wrapped distance squared
function Field.dist2(ax, ay, bx, by)
    local dx = math.abs(ax - bx)
    local dy = math.abs(ay - by)
    if dx > Field.W / 2 then dx = Field.W - dx end
    if dy > Field.H / 2 then dy = Field.H - dy end
    return dx * dx + dy * dy
end

-- call fn(ox, oy) for every wrap offset under which an object of radius r
-- at (x, y) could be visible; fn is called at least once with (0, 0)
function Field.offsets(x, y, r, fn)
    local oxs = { 0 }
    if x < r then oxs[#oxs + 1] = Field.W end
    if x > Field.W - r then oxs[#oxs + 1] = -Field.W end
    local oys = { 0 }
    if y < r then oys[#oys + 1] = Field.H end
    if y > Field.H - r then oys[#oys + 1] = -Field.H end
    for _, ox in ipairs(oxs) do
        for _, oy in ipairs(oys) do
            fn(ox, oy)
        end
    end
end

-- compatibility aliases (pre-library games used Util.*)
Util = Util or {}
Util.wrap = Field.wrap
Util.dist2 = Field.dist2
