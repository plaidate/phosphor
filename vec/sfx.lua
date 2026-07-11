-- Phosphor core: shared synth voices. Games get a standard arcade kit and
-- can register extra one-shots of their own.

local snd <const> = playdate.sound

Sfx = {}

local sq = snd.synth.new(snd.kWaveSquare)
local sq2 = snd.synth.new(snd.kWaveSquare)
local tri = snd.synth.new(snd.kWaveTriangle)
local saw = snd.synth.new(snd.kWaveSawtooth)
local noise = snd.synth.new(snd.kWaveNoise)
local noise2 = snd.synth.new(snd.kWaveNoise)
local noise3 = snd.synth.new(snd.kWaveNoise)   -- sweeps + boom tails
local tri2 = snd.synth.new(snd.kWaveTriangle)  -- warble
local beatSynth = snd.synth.new(snd.kWaveSquare)

function Sfx.pew(freq)
    sq:playNote(freq or 880, 0.22, 0.05)
end

function Sfx.blip(freq)
    tri:playNote(freq or 660, 0.25, 0.05)
end

function Sfx.thrustTick()
    noise:playNote(140, 0.25, 0.09)
end

function Sfx.boom(size)
    -- size: 1 small .. 3 big
    local f = ({ 160, 110, 70 })[size or 2] or 110
    noise2:playNote(f, 0.45, 0.1 + (size or 2) * 0.08)
end

function Sfx.bigBoom()
    noise2:playNote(60, 0.5, 0.5)
    Util.after(0.1, function() noise3:playNote(90, 0.4, 0.3) end)
end

function Sfx.zapSweep()
    for i = 0, 6 do
        Util.after(i * 0.05, function() noise3:playNote(1800 - i * 230, 0.35, 0.05) end)
    end
end

function Sfx.warble()
    for i = 0, 4 do
        Util.after(i * 0.04, function() tri2:playNote(300 + i * 150, 0.25, 0.04) end)
    end
end

function Sfx.fanfare(notes, step)
    notes = notes or { 523, 659, 784, 1047 }
    step = step or 0.11
    for i, n in ipairs(notes) do
        Util.after((i - 1) * step, function() tri:playNote(n, 0.3, step) end)
    end
end

local sirenHigh = false
function Sfx.sirenTick(base)
    sirenHigh = not sirenHigh
    base = base or 380
    sq2:playNote(sirenHigh and base or base * 0.8, 0.18, 0.1)
end

local beatHigh = false
function Sfx.beat()
    beatHigh = not beatHigh
    beatSynth:playNote(beatHigh and 65 or 49, 0.3, 0.12)
end

function Sfx.descend()
    saw:playNote(500, 0.4, 0.1)
    Util.after(0.1, function() saw:playNote(330, 0.4, 0.1) end)
    Util.after(0.2, function() saw:playNote(180, 0.4, 0.2) end)
end
