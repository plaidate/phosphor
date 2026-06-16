-- Open Geometry Wars: shared live state and scoring. Multiplier is kill-count
-- based (×1 per 25 kills, reset on death), and earned points feed the extra-
-- life, extra-bomb, and weapon-switch counters — all as in capehill/opengw.

G = {
    score = 0,
    lives = C.START_LIVES,
    bombs = C.START_BOMBS,
    mult = 1,
    killCounter = 0,        -- kills toward the next multiplier step
    lifeCounter = 0,        -- points toward the next extra life
    bombCounter = 0,        -- points toward the next extra bomb
    weaponCounter = 0,      -- points toward the next weapon switch
    weapon = 0,             -- current weapon pattern (0..2)

    ship = nil,
    shots = {},
    enemies = {},

    spawnIndex = 0,
    spawnT = 0,
    waveT = 0,
    aggro = 1.0,
    respawnT = 0,
    bombT = 0,
}

-- score a kill: points scale by multiplier, and the milestone counters tick
function G.addScore(points)
    local earned = points * G.mult
    G.score = G.score + earned
    Harness.count("scorePts", earned)

    G.lifeCounter = G.lifeCounter + earned
    if G.lifeCounter >= C.EXTRA_LIFE_AT then
        G.lifeCounter = G.lifeCounter - C.EXTRA_LIFE_AT
        G.lives = G.lives + 1
        Sfx.fanfare()
    end
    G.bombCounter = G.bombCounter + earned
    if G.bombCounter >= C.EXTRA_BOMB_AT then
        G.bombCounter = G.bombCounter - C.EXTRA_BOMB_AT
        G.bombs = G.bombs + 1
        Sfx.blip(880)
    end
    G.weaponCounter = G.weaponCounter + earned
    if G.weaponCounter >= C.WEAPON_SWITCH_AT then
        G.weaponCounter = G.weaponCounter - C.WEAPON_SWITCH_AT
        G.switchWeapon()
    end
end

-- opengw: weapon 0 -> 1; thereafter a coin-flip between 1 and 2
function G.switchWeapon()
    if G.weapon == 0 then
        G.weapon = 1
    else
        G.weapon = (math.random() < 0.5) and 1 or 2
    end
    Sfx.warble()
end

-- count a kill toward the multiplier (opengw: +1 per 25, capped)
function G.registerKill()
    Harness.count("kills")
    G.killCounter = G.killCounter + 1
    if G.killCounter >= C.MULT_PER_KILLS then
        G.killCounter = 0
        if G.mult < C.MAX_MULT then
            G.mult = G.mult + 1
            Sfx.fanfare({ 660, 880 }, 0.08)
        end
    end
end

function G.loseMultiplier()
    G.mult = 1
    G.killCounter = 0
    G.weapon = 0
    G.weaponCounter = 0
end
