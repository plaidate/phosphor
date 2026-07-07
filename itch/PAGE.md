# Phosphor — itch.io page copy

**Tagline:** Sixteen vector arcade games for Playdate — white beams on black, crank in hand.

## Description

Phosphor is a package of sixteen original vector arcade games for the
Playdate, drawn the way the old cabinets drew them: pure white beam lines
on black, a stroke font for every score digit, and not a sprite in sight.
Each game reimagines a classic vector-era design — rock fields, tube
shooters, lunar landings, tank duels, trench runs, wireframe space trading
— and gives the Playdate crank the job the original cabinet gave its
spinner, throttle, yoke, or wheel.

Every game is a complete little cabinet: attract screen, escalating waves,
persistent high score, and a synth soundtrack of pews, booms, and that
two-tone heartbeat. Short runs, honest difficulty, one more go.

## The games

Rubble, Welldiver, Touchdown, Ringkeep, Border Circuit, Lifters, Webguard,
Treadline, Night Vector, Trenchfire, Gravity Wells, Duelstar, Elite,
Geometry Wars, Vectorblade, and Gyre. Full rules for all sixteen are in
the [manual](../MANUAL.md).

## Features

- Sixteen games, each a self-contained `.pdx` — install only the ones you want
- True vector look: every line beam-drawn, including the font
- The crank does what the cabinet's control did: spinner, throttle,
  turret, steering wheel, roll yoke
- Per-game persistent high scores
- 3D wireframe games with near-plane clipping (Treadline, Night Vector,
  Trenchfire, Elite) and a warping spring grid (Geometry Wars)
- A full wireframe galaxy: Elite with trading, jumping, and docking
- All-synth sound — no samples
- MIT licensed, source on GitHub

## Controls

Crank steers/aims/throttles (each game says what on its title screen);
d-pad is always a fallback. A fires / confirms, B thrusts or does each
game's second verb. Every title screen lists its controls.

## Installing (no dev tools needed)

Download `<Game>.pdx.zip` from Releases (or grab the `.pdx` from `dist/`
in the repo), then either:

- **On a Playdate:** sideload at https://play.date/account/sideload —
  upload the zip, then on the device go to Settings → Games to download it.
- **In the Playdate Simulator** (free with the Playdate SDK): unzip and
  open the `.pdx` directly, or drag it onto the Simulator window.
