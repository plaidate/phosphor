-- Asteroids and saucers: lumpy drifting polygons, splitting, and the
-- two visitors who shoot back.

Rocks = {}

local clamp = Util.clamp

local SIZES <const> = { large = "medium", medium = "small" } -- split chain


function Rocks.add(size, x, y)
    local spec = C.ROCKS[size]
    local a = math.random() * math.pi * 2
    local v = spec.vmin + math.random() * (spec.vmax - spec.vmin)
    G.rocks[#G.rocks + 1] = {
        size = size, r = spec.r,
        x = x, y = y,
        vx = math.cos(a) * v, vy = math.sin(a) * v,
        angle = 0, spin = math.random(-60, 60),
        shape = Shapes.blob(spec.r),
    }
end

function Rocks.spawnWave()
    G.wave = G.wave + 1
    local n = math.min(C.START_ROCKS + (G.wave - 1) * 2, C.MAX_START_ROCKS)
    for _ = 1, n do
        -- spawn away from the ship, hugging an edge
        local x, y
        repeat
            if math.random() < 0.5 then
                x = math.random() < 0.5 and math.random(0, 60) or math.random(C.SCREEN_W - 60, C.SCREEN_W)
                y = math.random(0, C.SCREEN_H)
            else
                x = math.random(0, C.SCREEN_W)
                y = math.random() < 0.5 and math.random(0, 40) or math.random(C.SCREEN_H - 40, C.SCREEN_H)
            end
        until not G.ship or Util.dist2(x, y, G.ship.x, G.ship.y) > 90 * 90
        Rocks.add("large", x, y)
    end
end

function Rocks.shatter(i, scorer)
    local rock = G.rocks[i]
    table.remove(G.rocks, i)
    if scorer then
        G.addScore(C.ROCKS[rock.size].points)
    end
    G.burst(rock.x, rock.y, 6)
    Sfx.boom(({large=3, medium=2, small=1})[rock.size])
    local child = SIZES[rock.size]
    if child then
        Rocks.add(child, rock.x, rock.y)
        Rocks.add(child, rock.x, rock.y)
    end
end

function Rocks.update()
    for _, r in ipairs(G.rocks) do
        r.x, r.y = Util.wrap(r.x + r.vx * C.DT, r.y + r.vy * C.DT)
        r.angle = r.angle + r.spin * C.DT
    end
end

-- ------------------------------------------------------------------ saucers

function Rocks.spawnSaucer()
    -- the small saucer shows up once you have a reputation
    local small = G.score >= 8000 or (G.score >= 3000 and math.random() < 0.4)
    local fromLeft = math.random() < 0.5
    G.saucer = {
        small = small,
        r = small and 6 or 10,
        x = fromLeft and -12 or C.SCREEN_W + 12,
        y = math.random(30, C.SCREEN_H - 30),
        vx = (fromLeft and 1 or -1) * C.SAUCER_SPEED * (small and 1.25 or 1),
        vy = 0,
        zigT = 1.2,
        fireT = 1.0,
    }
end

function Rocks.updateSaucer()
    local s = G.saucer
    if not s then
        G.saucerT = G.saucerT - C.DT
        if G.saucerT <= 0 and #G.rocks > 0 then
            Rocks.spawnSaucer()
        end
        return
    end

    s.zigT = s.zigT - C.DT
    if s.zigT <= 0 then
        s.zigT = 0.9 + math.random()
        s.vy = (math.random(3) - 2) * 40 -- -40, 0, or 40
    end
    s.x = s.x + s.vx * C.DT
    s.y = clamp(s.y + s.vy * C.DT, 14, C.SCREEN_H - 14)

    if (s.vx > 0 and s.x > C.SCREEN_W + 14) or (s.vx < 0 and s.x < -14) then
        G.saucer = nil
        G.saucerT = math.max(7, C.SAUCER_EVERY - G.score / 1500)
        return
    end

    if Attract.frame % 9 == 0 then Sfx.sirenTick(s.small and 700 or 380) end

    -- gunnery
    s.fireT = s.fireT - C.DT
    if s.fireT <= 0 and G.ship and G.ship.alive then
        s.fireT = s.small and 0.85 or 1.1
        local a
        if s.small then
            -- aimed, with error that tightens as the score climbs
            local err = math.rad(math.max(2, 24 - G.score / 600))
            a = math.atan(G.ship.y - s.y, G.ship.x - s.x) + (math.random() - 0.5) * 2 * err
        else
            a = math.random() * math.pi * 2
        end
        G.saucerShots[#G.saucerShots + 1] = {
            x = s.x, y = s.y,
            vx = math.cos(a) * C.SAUCER_SHOT_SPEED,
            vy = math.sin(a) * C.SAUCER_SHOT_SPEED,
            life = 1.6,
        }
        Sfx.pew(620)
    end
end

function Rocks.killSaucer(scorer)
    local s = G.saucer
    if scorer then
        G.addScore(s.small and C.PTS_SAUCER_SMALL or C.PTS_SAUCER_BIG)
    end
    G.addDebris(s.x, s.y, 5)
    G.burst(s.x, s.y, 8)
    Sfx.boom(2)
    G.saucer = nil
    G.saucerT = math.max(7, C.SAUCER_EVERY - G.score / 1500)
end

function Rocks.updateSaucerShots()
    for i = #G.saucerShots, 1, -1 do
        local b = G.saucerShots[i]
        b.life = b.life - C.DT
        if b.life <= 0 then
            table.remove(G.saucerShots, i)
        else
            b.x, b.y = Util.wrap(b.x + b.vx * C.DT, b.y + b.vy * C.DT)
        end
    end
end

-- --------------------------------------------------------------- collisions

function Rocks.collide()
    -- player shots vs rocks and saucer
    for si = #G.shots, 1, -1 do
        local b = G.shots[si]
        local hit = false
        for ri = #G.rocks, 1, -1 do
            local r = G.rocks[ri]
            if Util.dist2(b.x, b.y, r.x, r.y) < r.r * r.r then
                Rocks.shatter(ri, true)
                hit = true
                break
            end
        end
        if not hit and G.saucer then
            local s = G.saucer
            if Util.dist2(b.x, b.y, s.x, s.y) < (s.r + 2) * (s.r + 2) then
                Rocks.killSaucer(true)
                hit = true
            end
        end
        if hit then table.remove(G.shots, si) end
    end

    if not (G.ship and G.ship.alive) then return end
    local ship = G.ship

    -- rocks vs ship
    for ri = #G.rocks, 1, -1 do
        local r = G.rocks[ri]
        if Util.dist2(ship.x, ship.y, r.x, r.y) < (r.r + C.SHIP_R) * (r.r + C.SHIP_R) then
            if ship.invuln <= 0 then
                Rocks.shatter(ri, false)
                Ship.kill()
                break
            end
        end
    end

    -- saucer and its shots vs ship
    if G.saucer and ship.alive and ship.invuln <= 0 then
        local s = G.saucer
        if Util.dist2(ship.x, ship.y, s.x, s.y) < (s.r + C.SHIP_R) * (s.r + C.SHIP_R) then
            Rocks.killSaucer(false)
            Ship.kill()
        end
    end
    for i = #G.saucerShots, 1, -1 do
        local b = G.saucerShots[i]
        if ship.alive and ship.invuln <= 0
            and Util.dist2(ship.x, ship.y, b.x, b.y) < (C.SHIP_R + 2) * (C.SHIP_R + 2) then
            table.remove(G.saucerShots, i)
            Ship.kill()
        end
    end

    -- saucer vs rocks (it is not immune to the furniture)
    if G.saucer then
        local s = G.saucer
        for ri = #G.rocks, 1, -1 do
            local r = G.rocks[ri]
            if Util.dist2(s.x, s.y, r.x, r.y) < (r.r + s.r) * (r.r + s.r) then
                Rocks.shatter(ri, false)
                Rocks.killSaucer(false)
                break
            end
        end
    end
end
