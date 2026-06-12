-- Duelstar rendering: the burning sun, both ships piece by piece, shot
-- trails, and a tally-mark HUD. Library shapes and beam text throughout.

local gfx <const> = playdate.graphics

Draw = {}

local FLAME <const> = {
    player = Shapes.new({ { -5, -3, -11, 0, -5, 3 } }),
    rival = Shapes.new({ { -7, -2, -13, 0, -7, 2 } }),
}

local SUN_SPIKES <const> = Shapes.gon(C.SUN_R + 5, 8, C.SUN_R * 0.55)
local SUN_CORE <const> = Shapes.gon(C.SUN_R * 0.6, 6)

local STARS = {}
for _ = 1, 26 do
    STARS[#STARS + 1] = { math.random(6, Field.W - 6), math.random(6, Field.H - 6) }
end

function Draw.stars()
    for i = 1, #STARS do
        if (Attract.frame + i * 7) % 50 > 3 then -- each winks out now and then
            gfx.drawPixel(STARS[i][1], STARS[i][2])
        end
    end
end

function Draw.sun()
    local pulse = 1 + 0.1 * math.sin(Attract.frame * 0.3)
    Shapes.draw(SUN_SPIKES, C.SUN_X, C.SUN_Y, Attract.frame * 2.4, pulse)
    Shapes.draw(SUN_CORE, C.SUN_X, C.SUN_Y, -Attract.frame * 1.7, 1)
end

local function drawShip(s)
    if not s or not s.alive then return end
    if s.invuln > 0 and Attract.frame % 4 < 2 then return end
    Shapes.drawWrapped(s.shape, s.x, s.y, s.angle, 1, 16)
    if s.thrusting and Attract.frame % 2 == 0 then
        Shapes.drawWrapped(FLAME[s.kind], s.x, s.y, s.angle, 1, 16)
    end
end

local function drawShots(shots)
    for _, b in ipairs(shots) do
        gfx.fillRect(b.x - 1, b.y - 1, 2, 2)
        -- fading trail: recent segments solid, older ones flicker out
        local t = b.trail
        local px, py = b.x, b.y
        for i = 1, #t // 2 do
            local tx, ty = t[i * 2 - 1], t[i * 2]
            if i <= 2 or (Attract.frame + i) % 2 == 0 then
                gfx.drawLine(px, py, tx, ty)
            end
            px, py = tx, ty
        end
    end
end

local function tally(x, n, dir)
    for i = 1, n do
        local tx = x + dir * (i - 1) * 5
        gfx.drawLine(tx, 22, tx, 30)
    end
end

function Draw.hud()
    Beams.print(tostring(G.score), 10, 8, 12, { weight = 1 })
    Beams.print(tostring(Attract.high), Field.W / 2, 8, 8, { align = "center" })
    Beams.print("RIVAL", Field.W - 10, 8, 8, { align = "right" })
    tally(12, G.pWins, 1)
    tally(Field.W - 12, G.rWins, -1)
end

function Draw.msgs()
    if G.phase == "between" and G.msg then
        Beams.print(G.msg, Field.W / 2, 82, 16, { align = "center", weight = 2 })
    elseif G.introT > 0 then
        Beams.print("ROUND " .. G.round, Field.W / 2, 58, 14, { align = "center", weight = 2 })
        Beams.print(Rival.title(), Field.W / 2, 82, 9, { align = "center" })
    end
end

function Draw.play()
    Draw.stars()
    Draw.sun()
    drawShip(G.player)
    drawShip(G.rival)
    drawShots(G.pShots)
    drawShots(G.rShots)
    Draw.hud()
    Draw.msgs()
end

-- the title screen's backdrop
function Draw.ambient()
    Draw.stars()
    Draw.sun()
end
