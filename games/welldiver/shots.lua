-- Player shots: travel down the lane, hitting enemies, enemy shots, and
-- spikes. Carried over from the verified Tempest-style build.

Shots = {}

function Shots.update(speed)
    for i = #G.pShots, 1, -1 do
        local b = G.pShots[i]
        b.z = b.z - speed * C.DT
        local dead = false

        if b.z <= 0 then
            dead = true
        end

        -- enemies in the same lane within reach
        if not dead then
            for ei = #G.enemies, 1, -1 do
                local e = G.enemies[ei]
                if e.lane == b.lane and math.abs(e.z - b.z) < 0.06 then
                    dead = true
                    local x, y = Wells.laneCenter(G.well, e.lane, e.z)
                    if e.type == "tanker" then
                        G.burst(x, y, 5)
                        G.addScore(e.points)
                        Enemies.splitTanker(e)
                        table.remove(G.enemies, ei)
                    else
                        G.burst(x, y, 6)
                        G.addScore(e.points)
                        table.remove(G.enemies, ei)
                    end
                    Harness.count("kills")
                    Sfx.boom(1)
                    break
                end
            end
        end

        -- enemy shots are destructible
        if not dead then
            for si = #G.eShots, 1, -1 do
                local s = G.eShots[si]
                if s.lane == b.lane and math.abs(s.z - b.z) < 0.05 then
                    dead = true
                    table.remove(G.eShots, si)
                    Sfx.pew(900)
                    break
                end
            end
        end

        -- spikes get whittled down a notch per hit
        if not dead then
            local h = G.spikes[b.lane] or 0
            if h > 0 and b.z <= h then
                G.spikes[b.lane] = math.max(0, h - 0.09)
                G.addScore(C.PTS_SPIKE_HIT)
                dead = true
                Sfx.pew(2200)
            end
        end

        if dead then table.remove(G.pShots, i) end
    end
end
