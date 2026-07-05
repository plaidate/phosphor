-- The tunnel: stars stream outward from the center of the tube toward the
-- rim. During a warp they accelerate into radial streaks.

local gfx <const> = playdate.graphics

Stars = {}

local list = {}

local function reset(s)
    s.a = math.random() * 360
    s.r = 0.02 + math.random() * 0.15
    s.v = 0.18 + math.random() * 0.4
end

function Stars.init(n)
    list = {}
    for _ = 1, (n or 44) do
        local s = {}
        reset(s)
        s.r = math.random() * 1.25 -- scatter the opening frame
        list[#list + 1] = s
    end
end

function Stars.update(dt, mul)
    mul = mul or 1
    for _, s in ipairs(list) do
        s.r = s.r + s.v * mul * dt
        if s.r > 1.35 then reset(s) end
    end
end

function Stars.draw(mul)
    mul = mul or 1
    for _, s in ipairs(list) do
        local x, y = G.polarPx(s.a, s.r)
        if mul > 2 then
            -- warp streaks along the radial
            local x2, y2 = G.polarPx(s.a, math.max(s.r - 0.05 * mul, 0.01))
            gfx.drawLine(x, y, x2, y2)
        elseif s.r > 0.5 then
            gfx.drawPixel(x, y)
        elseif math.floor(s.a) % 2 == 0 then
            gfx.drawPixel(x, y) -- thin the deep field so the hub reads
        end
    end
end
