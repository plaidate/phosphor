-- Live game state and the polar-playfield helpers every module leans on.
-- Positions are unit Cartesian (1.0 = the rim); G.px converts to pixels and
-- G.scaleAt fakes tube depth.

G = {
    score = 0,
    lives = 0,
    stage = 1,
    planetIdx = 1,
    warpsLeft = C.WARPS_PER_PLANET,
    mode = "intro", -- "intro" | "play" | "clear" | "tally" | "warp"
    modeT = 0,
    chance = false,
    formA = 0,
    time = 0,
    bannerText = nil,
    bannerT = 0,
    popText = nil,
    popT = 0,
}

-- unit-space position for a polar coordinate
function G.unit(a, r)
    local rad = math.rad(a)
    return math.cos(rad) * r, math.sin(rad) * r
end

-- pixel position for a unit-space point
function G.px(ux, uy)
    return C.CX + ux * C.RIM, C.CY + uy * C.RIM
end

-- pixel position straight from polar
function G.polarPx(a, r)
    local rad = math.rad(a)
    return C.CX + math.cos(rad) * r * C.RIM, C.CY + math.sin(rad) * r * C.RIM
end

-- draw scale for tube depth: 1 at the rim, MIN_SCALE at the center
function G.scaleAt(r)
    local t = Util.clamp(r, 0, 1.2)
    return C.MIN_SCALE + (1 - C.MIN_SCALE) * t ^ 1.3
end

-- hub formation slots: three rings near the center
G.slots = {}
do
    local rings = {
        { r = 0.11, n = 6 },
        { r = 0.21, n = 12 },
        { r = 0.31, n = 16 },
    }
    for ri, ring in ipairs(rings) do
        for i = 0, ring.n - 1 do
            G.slots[#G.slots + 1] = {
                a = i * (360 / ring.n) + ri * 15,
                r = ring.r,
                taken = false,
            }
        end
    end
end

function G.freeSlot()
    for i, s in ipairs(G.slots) do
        if not s.taken then
            s.taken = true
            return i
        end
    end
    return nil
end

function G.releaseSlot(i)
    if i and G.slots[i] then G.slots[i].taken = false end
end

function G.resetSlots()
    for _, s in ipairs(G.slots) do s.taken = false end
end

-- a slot's live polar position (the formation rotates and breathes)
function G.slotPos(i)
    local s = G.slots[i]
    local a = G.formA + s.a
    local r = s.r * (1 + 0.05 * math.sin(G.time * 2 + i))
    return a, r
end

function G.addScore(n)
    G.score = G.score + n
    if G.score >= G.nextLifeAt then
        G.nextLifeAt = G.nextLifeAt + C.EXTRA_LIFE_EVERY
        if G.lives < C.MAX_LIVES then
            G.lives = G.lives + 1
            G.pop("EXTRA SHIP")
            Sfx.fanfare({ 659, 784, 988, 1319 }, 0.09)
            Harness.count("extraLives")
        end
    end
end

-- full-screen banner (stage intros) and small popup (bonuses)
function G.banner(text, secs)
    G.bannerText = text
    G.bannerT = secs or 1.6
end

function G.pop(text, secs)
    G.popText = text
    G.popT = secs or 1.4
end

-- explosion at a unit-space point, sized by tube depth
function G.boom(ux, uy, n)
    local x, y = G.px(ux, uy)
    local s = G.scaleAt(Vec.len(ux, uy))
    Fx.burst(x, y, math.floor(n * s + 2), 60 * s + 20)
    if s > 0.6 then Fx.debris(x, y, 4) end
end
