-- Duelstar: shared state. One match = one game; rounds tick inside it.

G = {
    score = 0,
    pWins = 0,      -- player round wins this match
    rWins = 0,      -- rival round wins this match
    round = 0,
    player = nil,
    rival = nil,
    pShots = {},
    rShots = {},
    phase = "fight", -- "fight" | "between"
    phaseT = 0,
    introT = 0,
    brain = "orbiter",
    msg = nil,
}

function G.addScore(n)
    G.score = G.score + n
    Harness.count("scorePts", n)
end
