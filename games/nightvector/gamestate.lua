-- Night Vector: shared state. The car and road live in their own modules;
-- everything they share routes through G.

G = {
    score = 0,
    cars = 0,            -- the stable of cars left
    level = 0,           -- checkpoints reached
    time = 0,            -- seconds on the checkpoint clock
    nextCk = 0,          -- distance of the next checkpoint
    next100 = 0,         -- next 100 m score tick
    car = nil,
    traffic = {},
    spawnT = 0,
    shake = 0,           -- camera jitter amplitude (off-road, in m-ish units)
    dead = false,        -- set when the last car is wrecked
    msg = nil,           -- centre-screen banner
    msgT = 0,
    beepT = 0,           -- low-time beeper
    demo = { s = 0 },    -- the attract-mode flythrough
}

function G.addScore(n)
    G.score = G.score + n
    Harness.count("scorePts", n)
end

function G.banner(text, secs)
    G.msg, G.msgT = text, secs or 1.6
end
