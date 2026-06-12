-- The RIVAL's brain. Three personalities rotate per round:
--   orbiter — rides the sun's gravity, firing on close passes
--   sniper  — holds the range open and leads its shots well
--   brawler — charges in, fires point-blank, barely respects the sun
-- All of them get sharper as the player racks up round wins.

Rival = {}

local clamp = Util.clamp

local BRAINS <const> = { "orbiter", "sniper", "brawler" }
local TITLES <const> = {
    orbiter = "THE ORBITER",
    sniper = "THE SNIPER",
    brawler = "THE BRAWLER",
}

function Rival.newBrain()
    G.brain = BRAINS[(G.round - 1) % #BRAINS + 1]
end

function Rival.title()
    return TITLES[G.brain] or ""
end

local function skill()
    return clamp(C.AI_BASE_SKILL + G.pWins * C.AI_SKILL_PER_WIN, C.AI_BASE_SKILL, 1)
end

local function steer(s, want)
    local rate = C.AI_TURN * (0.55 + 0.45 * skill())
    return clamp(Vec.angleDiff(s.angle, want), -rate * C.DT, rate * C.DT)
end

-- returns turn, thrust, fire, hyper (same contract as Input.gather)
function Rival.think()
    local r, p = G.rival, G.player
    if not (r and r.alive and p and p.alive) then
        return 0, false, false, false
    end
    local sk = skill()
    local brain = G.brain

    -- sun safety first; the brawler waits much longer before flinching
    local steps = Ships.sunDanger(r)
    if steps then
        local panic = brain == "brawler" and 5 or 9
        if steps <= panic then
            return 0, false, false, true -- hyperspace out of the dive
        end
        if brain ~= "brawler" or steps <= 16 then
            -- burn outward, biased prograde so it spirals clear
            local out = Vec.angleOf(r.x - C.SUN_X, r.y - C.SUN_Y)
            return steer(r, out + Ships.tangentSide(r) * 50), true, false, false
        end
    end

    local lead, dist = Ships.leadAngle(r, p)
    -- aim error wanders instead of jittering; shrinks with skill
    local err = (1 - sk) * 26 * math.sin(Attract.frame * 0.11)
    local off = math.abs(Vec.angleDiff(r.angle, lead))
    local canShoot = #G.rShots < C.MAX_SHOTS and r.fireT <= 0
    local eager = math.random() < 0.35 + 0.6 * sk

    local turn, thrust, fire = 0, false, false

    if brain == "orbiter" then
        local d = Vec.len(r.x - C.SUN_X, r.y - C.SUN_Y)
        if dist < 165 and canShoot then
            -- a firing pass: swing the nose onto the lead solution
            turn = steer(r, lead + err)
            fire = off < 14 + 10 * sk and eager
            thrust = Attract.frame % 8 < 2
        else
            -- circularize at ORBIT_R and let gravity do the flying
            local side = Ships.tangentSide(r)
            local tangent = Vec.angleOf(r.x - C.SUN_X, r.y - C.SUN_Y) + side * 90
            local correction = clamp((d - C.ORBIT_R) * 0.8, -45, 45)
            turn = steer(r, tangent + side * correction)
            thrust = Vec.len(r.vx, r.vy) < math.sqrt(C.GRAV_MU / math.max(d, 30)) * 1.1
        end
    elseif brain == "sniper" then
        local aim = lead + err * 0.5 -- half the wander: it leads shots well
        if dist < 130 then
            turn = steer(r, lead + 180) -- open the range
            thrust = true
        elseif dist > 215 then
            turn = steer(r, aim)
            thrust = off < 50
            fire = canShoot and off < 10 + 8 * sk and eager
        else
            turn = steer(r, aim)
            fire = canShoot and off < 10 + 8 * sk and eager
        end
    else -- brawler
        turn = steer(r, lead + err * 1.4)
        thrust = dist > 45
        fire = canShoot and dist < 115 and off < 24 and eager
    end

    return turn, thrust, fire, false
end
