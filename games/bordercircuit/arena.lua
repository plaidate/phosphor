-- The track: outer walls, the central HUD barrier, and reflective physics.
-- Everything that moves gets pushed back into the gutter and reflected;
-- the four waypoints at the gutter corners give the enemies their circuit.

Arena = {}

local A <const> = C.ARENA
local B <const> = C.BAR

-- circuit waypoints at the center of each gutter corner, clockwise from
-- top-left: index wraps, so enemies just keep adding their direction
local midL <const> = (A.x1 + B.x1) / 2
local midR <const> = (B.x2 + A.x2) / 2
local midT <const> = (A.y1 + B.y1) / 2
local midB <const> = (B.y2 + A.y2) / 2

Arena.WP = {
    { midL, midT },
    { midR, midT },
    { midR, midB },
    { midL, midB },
}

function Arena.waypoint(i)
    local w = Arena.WP[((i - 1) % 4) + 1]
    return w[1], w[2]
end

-- the ship's home straight: middle of the bottom gutter
Arena.SPAWN_X = (B.x1 + B.x2) / 2
Arena.SPAWN_Y = midB

-- reflect a circle of radius r off the outer walls and the barrier.
-- e needs x, y, vx, vy. elast scales the reflected component (1 = perfect,
-- the ship uses C.SHIP_BOUNCE). Returns true if anything was hit.
function Arena.bounce(e, r, elast)
    local hit = false

    -- outer walls
    if e.x - r < A.x1 then
        e.x = A.x1 + r
        if e.vx < 0 then e.vx = -e.vx * elast end
        hit = true
    elseif e.x + r > A.x2 then
        e.x = A.x2 - r
        if e.vx > 0 then e.vx = -e.vx * elast end
        hit = true
    end
    if e.y - r < A.y1 then
        e.y = A.y1 + r
        if e.vy < 0 then e.vy = -e.vy * elast end
        hit = true
    elseif e.y + r > A.y2 then
        e.y = A.y2 - r
        if e.vy > 0 then e.vy = -e.vy * elast end
        hit = true
    end

    -- the barrier: resolve along the axis of least penetration
    local bx1, by1 = B.x1 - r, B.y1 - r
    local bx2, by2 = B.x2 + r, B.y2 + r
    if e.x > bx1 and e.x < bx2 and e.y > by1 and e.y < by2 then
        local dl, dr = e.x - bx1, bx2 - e.x
        local dtp, db = e.y - by1, by2 - e.y
        local m = math.min(dl, dr, dtp, db)
        if m == dl then
            e.x = bx1
            if e.vx > 0 then e.vx = -e.vx * elast end
        elseif m == dr then
            e.x = bx2
            if e.vx < 0 then e.vx = -e.vx * elast end
        elseif m == dtp then
            e.y = by1
            if e.vy > 0 then e.vy = -e.vy * elast end
        else
            e.y = by2
            if e.vy < 0 then e.vy = -e.vy * elast end
        end
        hit = true
    end

    return hit
end

function Arena.spark(x, y)
    Fx.burst(x, y, 3, 55)
end
