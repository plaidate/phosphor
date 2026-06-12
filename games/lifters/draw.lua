-- Lifters rendering: library shapes and beam text. Lifters hover flat with
-- their grab-legs down, gunners are diamonds, rammers are darts that point
-- where they dive. Canisters are the small triangles everything is about.

local gfx <const> = playdate.graphics

Draw = {}

local SHIP <const> = Shapes.new({
    { 8, 0, -6, -5, -3.5, 0, -6, 5, 8, 0 },
})
local FLAME <const> = Shapes.new({
    { -4, -2.5, -9, 0, -4, 2.5 },
})
local CAN <const> = Shapes.new({
    { 0, -5, 4.5, 3.5, -4.5, 3.5, 0, -5 },
})
local LIFTER <const> = Shapes.new({
    { -8, 0, -5, -6, 5, -6, 8, 0, -8, 0 },
    { -6, 0, -6, 4 },
    { 6, 0, 6, 4 },
})
local GUNNER <const> = Shapes.new({
    { 0, -8, 7, 0, 0, 8, -7, 0, 0, -8 },
    { -3, 0, 3, 0 },
})
local RAMMER <const> = Shapes.new({
    { 10, 0, -6, -5, -2, 0, -6, 5, 10, 0 },
})

local KINDSHAPE <const> = {
    lifter = LIFTER,
    gunner = GUNNER,
    rammer = RAMMER,
}

local function drawRaider(kind, x, y, heading)
    local angle = (kind == "rammer") and heading or 0
    Shapes.draw(KINDSHAPE[kind], x, y, angle, 1)
end

function Draw.ship()
    local s = G.ship
    if not s or not s.alive then return end
    if s.invuln > 0 and Attract.frame % 4 < 2 then return end
    Shapes.draw(SHIP, s.x, s.y, s.angle, 1)
    if s.thrusting and Attract.frame % 2 == 0 then
        Shapes.draw(FLAME, s.x, s.y, s.angle, 1)
    end
end

function Draw.canisters()
    for _, can in ipairs(G.canisters) do
        Shapes.draw(CAN, can.x, can.y, 0, 1)
        if can.carrier then
            -- the grab beam: a flickering tether to the carrier
            if Attract.frame % 3 ~= 0 then
                gfx.drawLine(can.carrier.x, can.carrier.y + 3, can.x, can.y - 5)
            end
        end
    end
end

function Draw.raiders()
    for _, rd in ipairs(G.raiders) do
        if rd.delay <= 0 then
            drawRaider(rd.kind, rd.x, rd.y, rd.heading)
        end
    end
end

function Draw.shots()
    for _, b in ipairs(G.shots) do
        gfx.fillRect(b.x - 1, b.y - 1, 2, 2)
    end
    for _, b in ipairs(G.raiderShots) do
        gfx.fillRect(b.x - 1, b.y - 1, 2, 2)
    end
end

function Draw.hud()
    Beams.print(tostring(G.score), 10, 8, 12, { weight = 1 })
    Beams.print(tostring(Attract.high), Field.W / 2, 8, 8, { align = "center" })
    -- the fuel that's still in play, one icon per canister
    for i = 1, G.canistersLeft() do
        Shapes.draw(CAN, Field.W - 12 - (i - 1) * 11, 13, 0, 0.8)
    end
end

function Draw.play()
    Draw.canisters()
    Draw.raiders()
    Draw.ship()
    Draw.shots()
    Draw.hud()
end

-- the title/over backdrop: raiders cruising past, and on the over screen
-- the line that matters — how long the fuel lasted
function Draw.ambient()
    for _, d in ipairs(G.drift) do
        local heading = Vec.angleOf(d.vx, d.vy)
        drawRaider(d.kind, d.x, d.y, heading)
    end
    if Attract.state == "over" then
        local waves = math.max(G.wave - 1, 0)
        Beams.print("WAVES SURVIVED " .. waves, Field.W / 2, Field.H - 28, 10, { align = "center" })
    end
end
