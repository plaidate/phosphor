# Phosphor

> Part of **[plAIdate](https://plaidate.github.io)** — AI-built 1-bit games, ports, and engines for the Playdate.

Sixteen vector arcade games for the [Playdate](https://play.date) — white
beam lines on black, the way the cabinets drew them. Every game is an
original implementation of a classic vector-era design, with the crank
doing what each cabinet's spinner, throttle, yoke, or wheel did.

**[Player's manual](MANUAL.md)** — controls, rules, enemies, and tips for
every game. **[Developer guide](DEVGUIDE.md)** — the shared `vec/` engine
and how to add a game.

Each game also links to its own page with controls, rules, and a screenshot.

| Game | Inspired by the era of | Crank |
|---|---|---|
| [Rubble](games/rubble/) | rock-field shooters (1979) | spin ship |
| [Welldiver](games/welldiver/) | tube shooters (1981) | spinner |
| [Touchdown](games/touchdown/) | lunar landers (1979) | throttle |
| [Ringkeep](games/ringkeep/) | ring-fortress duels (1980) | spin ship |
| [Border Circuit](games/bordercircuit/) | arena racers (1981) | spinner |
| [Lifters](games/lifters/) | canister-defense (1980) | spin ship |
| [Webguard](games/webguard/) | web shooters (1983) | aim |
| [Treadline](games/treadline/) | first-person tank combat (1980) | turret |
| [Night Vector](games/nightvector/) | first-person night driving (1979) | steering wheel |
| [Trenchfire](games/trenchfire/) | trench-run rail shooters (1983) | throttle |
| [Gravity Wells](games/gravitywells/) | gravity missions (1982) | spin ship |
| [Duelstar](games/duelstar/) | two-ship duels (1977) | spin ship |
| [Elite](games/elite/) | wireframe space combat (1984) | roll |
| [Geometry Wars](games/opengw/) | twin-stick grid shooters (2003) | aim |
| [Vectorblade](games/vectorblade/) | vector swarm shooters (2019) | spinner |
| [Gyre](games/gyre/) | orbit tube shooters (1983) | fly the rim |

## Playing (no build needed)

Ready-to-run copies of every game live in [`dist/`](dist/), and zipped
`.pdx` bundles are attached to each GitHub Release.

- **On a Playdate**: sign in at [play.date/account/sideload](https://play.date/account/sideload),
  upload the `.pdx` you want (zip it first if your browser requires a
  single file), then download it to the device from Settings → Games.
- **In the Playdate Simulator** (ships with the
  [Playdate SDK](https://play.date/dev/)): open the `.pdx` directly, or
  drag it onto the Simulator window.

High scores save per game on the device.

## Development

Requires the Playdate SDK with `pdc` on your PATH.

- `make <game>` — build one game to `out/<Title>.pdx`
- `make all` — build everything
- `make <game>-smoke` — instrumented build: the game plays itself
  (autopilot) and writes telemetry counters, errors, and periodic
  screenshots through the built-in harness
- `tools/smoke.sh <game> [seconds] [until-grep]` — build the smoke
  variant, run it headlessly in the Simulator, and report

### Layout

- `vec/` — the shared library: 2D vector math (`vec`), screen wrap
  (`field`), a warping spring grid (`grid`), polyline shape models
  (`shapes`), 3x3 orientation matrices (`mat`), a 3D wireframe camera
  with near-plane clipping (`proj`), a vector stroke font (`beams`),
  particles and debris (`fx`), synth voices (`sfx`), the shared
  attract-mode cabinet and high scores (`attract`), and the smoke-test
  harness (`harness`). See [DEVGUIDE.md](DEVGUIDE.md) for the full tour.
- `games/<name>/` — each game is a thin set of modules on the library;
  `games/rubble/` is the reference for the structure.
- The Makefile stages `vec/` + the game's files into `build/<name>/source`
  and runs `pdc`; `dist/` holds committed release builds.

MIT licensed.
