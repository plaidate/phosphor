-- Elite: shared state. The player is the camera at the origin looking down +Z;
-- everything else lives in G.objs with a position and an orientation matrix.

G = {
    -- player condition
    energy = 0,
    shield = 0,
    hull = 0,
    laserHeat = 0,
    speed = 0,
    score = 0,
    kills = 0,

    -- flight inputs resolved for this frame (radians/sec)
    roll = 0,
    pitch = 0,
    firing = false,

    -- world
    objs = {},          -- ships, asteroids, station, cargo
    station = nil,      -- convenience handle into objs
    galaxyNum = 1,      -- which of the 8 galaxies (1..8)
    sysIndex = 7,       -- current system (0..255); 7 = Lave
    systems = nil,      -- the 256 system seeds of this galaxy
    planet = nil,       -- current system's economy/government/tech data
    sysName = "LAVE",   -- current system name
    fuel = 70,          -- light years * 10
    credits = 1000,     -- 100.0 Cr (tenths)
    cargo = {},         -- tonnes/kg/g held of each of the 17 commodities
    cargoBay = 20,      -- hold capacity in tonnes (35 with a large bay)
    missiles = 3,
    equip = {},         -- ecm / scoop / bomb / dockComp / galHyper flags
    docked = false,     -- at a station, showing the menu screens
    market = nil,       -- current system's stock market
    legalStatus = 0,    -- 0 clean .. offender .. fugitive (halves on a jump)
    cabinTemp = 0.1,    -- 0..1, rises near the sun
    altitude = 1,       -- 0..1, falls as you near the station/planet
    sunDir = { x = 0, y = 0.3, z = -1 },     -- unit bearing to the sun
    planetDir = { x = 0.4, y = -0.2, z = 1 }, -- unit bearing to the planet
    witchspace = false, -- dumped into interstellar space with Thargoids
    mission = 0,        -- 0 none, 1 hunt the Constrictor, 2 complete
    pirates = 0,        -- live hostiles remaining in this system

    -- transient hit feedback
    hitFlash = 0,       -- screen edge flash when the player is struck
    laserT = 0,         -- frames left to draw our own laser beams
    docking = 0,        -- seconds spent inside the dock envelope
    message = nil,      -- transient HUD line
    messageT = 0,
}

function G.addScore(n)
    G.score = G.score + n
    Harness.count("scorePts", n)
end

function G.say(text, secs)
    G.message = text
    G.messageT = secs or 2.5
end

-- combat-rating ladder, by cumulative kills (mirrors Elite's progression)
local RATINGS = {
    { 0, "HARMLESS" }, { 8, "MOSTLY HARMLESS" }, { 16, "POOR" },
    { 28, "AVERAGE" }, { 44, "ABOVE AVERAGE" }, { 64, "COMPETENT" },
    { 100, "DANGEROUS" }, { 256, "DEADLY" }, { 512, "ELITE" },
}

function G.rating()
    local name = RATINGS[1][2]
    for _, r in ipairs(RATINGS) do
        if G.kills >= r[1] then name = r[2] end
    end
    return name
end

-- legal status: clean until you shoot the innocent or the law
function G.statusName()
    if G.legalStatus == 0 then return "CLEAN" end
    if G.legalStatus < 40 then return "OFFENDER" end
    return "FUGITIVE"
end

function G.commitCrime(n)
    G.legalStatus = math.min(127, G.legalStatus + n)
end
