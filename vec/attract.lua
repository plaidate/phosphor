-- Phosphor core: the shared cabinet — title/attract, play, game over,
-- high-score persistence, and the package-wide look. A game hands Attract
-- its hooks and Attract owns playdate.update.
--
-- Attract.setup{
--     title = "RUBBLE",
--     controls = { "CRANK SPIN SHIP", "B THRUST", "A FIRE" },
--     hooks = {
--         start = function() end,        -- begin a fresh game
--         update = function(dt) end,     -- one play frame (sim + entity logic)
--         draw = function() end,         -- one play frame (render, after clear)
--         ambient = function(dt) end,    -- optional: runs behind title/over
--         drawAmbient = function() end,  -- optional: render behind title/over
--         score = function() return n end,
--     },
-- }
-- The game ends a run by calling Attract.gameOver().

local gfx <const> = playdate.graphics

Attract = {
    state = "title", -- "title" | "play" | "over"
    frame = 0,
    high = 0,
    dt = 1 / 30,
}

local cfg
local overT = 0

function Attract.setup(c)
    cfg = c
    local saved = playdate.datastore.read()
    Attract.high = (saved and saved.highScore) or 0

    math.randomseed(playdate.getSecondsSinceEpoch())
    playdate.display.setRefreshRate(30)

    playdate.getSystemMenu():addMenuItem("restart", function()
        Attract.state = "title"
    end)
end

function Attract.gameOver()
    Attract.state = "over"
    overT = 0
    local score = cfg.hooks.score and cfg.hooks.score() or 0
    if score > Attract.high then
        Attract.high = score
        playdate.datastore.write({ highScore = Attract.high })
    end
end

local function startPressed()
    if Harness.enabled then return true end
    return playdate.buttonJustPressed(playdate.kButtonA)
end

local function drawChrome()
    -- the cabinet bezel: a thin border common to every Phosphor game
    gfx.drawRect(0, 0, Field.W, Field.H)
end

local function drawTitle()
    gfx.clear(gfx.kColorBlack)
    gfx.setColor(gfx.kColorWhite)
    if cfg.hooks.drawAmbient then cfg.hooks.drawAmbient() end
    drawChrome()

    Beams.print(cfg.title, Field.W / 2, 38, 30, { align = "center", weight = 2 })
    Beams.print("PHOSPHOR", Field.W / 2, 16, 7, { align = "center" })

    local y = 110
    for _, line in ipairs(cfg.controls or {}) do
        Beams.print(line, Field.W / 2, y, 8, { align = "center" })
        y = y + 16
    end
    if Attract.frame % 30 < 20 then
        Beams.print("PRESS A TO START", Field.W / 2, y + 12, 10, { align = "center" })
    end
    Beams.print("HIGH " .. Attract.high, Field.W / 2, Field.H - 20, 8, { align = "center" })
end

local function drawOver()
    gfx.clear(gfx.kColorBlack)
    gfx.setColor(gfx.kColorWhite)
    if cfg.hooks.drawAmbient then cfg.hooks.drawAmbient() end
    drawChrome()

    local score = cfg.hooks.score and cfg.hooks.score() or 0
    Beams.print("GAME OVER", Field.W / 2, 60, 22, { align = "center", weight = 2 })
    Beams.print("SCORE " .. score, Field.W / 2, 110, 12, { align = "center" })
    if score >= Attract.high and score > 0 then
        Beams.print("NEW HIGH SCORE", Field.W / 2, 134, 10, { align = "center" })
    else
        Beams.print("HIGH " .. Attract.high, Field.W / 2, 134, 10, { align = "center" })
    end
    if Attract.frame % 30 < 20 then
        Beams.print("PRESS A", Field.W / 2, 168, 10, { align = "center" })
    end
end

local function tick()
    Attract.frame = Attract.frame + 1
    local dt = Attract.dt
    Util.runPending(dt)
    Fx.update(dt)

    if Attract.state == "title" then
        if cfg.hooks.ambient then cfg.hooks.ambient(dt) end
        drawTitle()
        if startPressed() then
            Fx.reset()
            Util.clearPending()
            cfg.hooks.start()
            Attract.state = "play"
        end
    elseif Attract.state == "play" then
        cfg.hooks.update(dt)
        if Attract.state == "play" then
            gfx.clear(Fx.flashing(Attract.frame) and gfx.kColorWhite or gfx.kColorBlack)
            gfx.setColor(gfx.kColorWhite)
            cfg.hooks.draw()
            Fx.draw()
        end
    elseif Attract.state == "over" then
        overT = overT + dt
        if cfg.hooks.ambient then cfg.hooks.ambient(dt) end
        drawOver()
        if overT > 1 and startPressed() then
            Attract.state = "title"
        end
    end
end

function playdate.update()
    Harness.frame(Attract.frame + 1, tick)
end
