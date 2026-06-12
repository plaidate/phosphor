-- Night Vector — first-person night driving for Playdate (Phosphor package).
-- An original implementation of the 1979 arcade classic's design: a dark
-- two-lane road picked out by edge posts in the headlights, the crank as the
-- steering wheel, traffic to thread, and a checkpoint clock that always
-- wins in the end. A = accelerate, B = brake; distance is score.

import "lib"

import "config"
import "gamestate"
import "road"
import "car"
import "input"
import "draw"

local function startGame()
    Road.reset()
    G.score = 0
    G.cars = C.START_CARS
    G.level = 0
    G.time = C.TIME_START
    G.nextCk = C.CK_M
    G.next100 = 100
    G.traffic = {}
    G.spawnT = 1.5
    G.shake = 0
    G.dead = false
    G.msg, G.msgT = nil, 0
    G.beepT = 0
    G.demo.s = 0
    G.car = Car.new()
    Harness.count("games")
end

local function gameOver()
    Harness.count("gameovers")
    Attract.gameOver()
end

local function checkpoint()
    G.level = G.level + 1
    local bonus = C.TIME_BONUS + math.max(0, C.TIME_GRACE - G.level)
    G.time = G.time + bonus
    G.nextCk = G.nextCk + C.CK_M
    G.banner("CHECKPOINT +" .. bonus)
    Harness.count("checkpoints")
    Sfx.fanfare()
end

local function updatePlay(dt)
    local wd, accel, brake = Input.gather()
    Car.update(dt, wd, accel, brake)
    Car.updateTraffic(dt)
    local c = G.car

    if G.dead then -- the last car is wrecked
        gameOver()
        return
    end

    if c.crashT <= 0 then
        -- the clock pauses while the wreck is cleared; losing a car is enough
        G.time = G.time - dt
        if G.time < 6 then
            G.beepT = G.beepT - dt
            if G.beepT <= 0 then
                G.beepT = 1
                Sfx.blip(880)
            end
        end
        if G.time <= 0 then
            G.time = 0
            Sfx.descend()
            gameOver()
            return
        end
        while c.dist >= G.next100 do
            G.addScore(C.PTS_100M)
            G.next100 = G.next100 + 100
        end
        if c.dist >= G.nextCk then
            checkpoint()
        end
    end

    if G.msgT > 0 then G.msgT = G.msgT - dt end
end

local function ambient(dt)
    G.demo.s = G.demo.s + 24 * dt
end

Harness.shotPath = "phosphor/build/nightvector-shot.png"

Harness.extra = function(t)
    t.state = Attract.state
    t.score = G.score
    t.speed = G.car and math.floor(G.car.speed * 3.6 + 0.5) or 0
    t.dist = G.car and math.floor(G.car.dist) or 0
    t.time = math.floor(G.time + 0.5)
    t.carsLeft = G.cars
end

-- the title screen needs a road to fly down
Road.reset()

Attract.setup({
    title = "NIGHT VECTOR",
    controls = {
        "CRANK - STEERING WHEEL",
        "A - GAS   B - BRAKE",
        "MAKE EACH KM BEFORE THE CLOCK",
    },
    hooks = {
        start = startGame,
        update = updatePlay,
        draw = Draw.play,
        ambient = ambient,
        drawAmbient = Draw.ambient,
        score = function() return G.score end,
    },
})
