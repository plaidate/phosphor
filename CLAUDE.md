# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

Phosphor is a package of thirteen original vector arcade games for the Playdate, written in Lua against the Playdate SDK. Every game is white beam lines on black, and the crank stands in for each cabinet's spinner/throttle/yoke/wheel. The games share a single library in `vec/`.

Playdate-specific API and SDK reference (CoreLibs, `playdate.*`, the Simulator, sideloading): <https://sdk.play.date/3.0.6/Inside%20Playdate.html>. Reach for it before guessing at SDK behaviour — the games lean on `playdate.graphics`, `playdate.datastore`, `playdate.getCrankChange`, `playdate.sound.synth`, and `playdate.simulator`.

## Commands

Requires the Playdate SDK with `pdc` on PATH (compiler) and, for smoke runs, the Playdate Simulator installed under `~/Developer/PlaydateSDK/`.

- `make <game>` — build one game to `out/<Title>.pdx` (game names are the lowercase dirs in `games/`, e.g. `make rubble`)
- `make all` — build every game (release)
- `make <game>-smoke` — instrumented build to `out/<Title>Smoke.pdx` (autopilot + telemetry)
- `make clean` — remove `build/` and `out/`
- `tools/smoke.sh <game> [seconds] [until-grep]` — build the smoke variant, run it headlessly in the Simulator, poll the datastore, and print errors + the telemetry heartbeat. Example: `tools/smoke.sh rubble 180 '"gameovers":[1-9]'`. This is the primary way to verify a game actually runs — there is no unit-test suite.

`build/`, `out/`, and `results/` are gitignored. `dist/` holds committed, playable release builds (compiled `.pdx`); the `pdxinfo` bundle ID is `com.sdwfrost.phosphor.<game>`.

## Architecture

### The shared cabinet (`vec/`)

`vec/lib.lua` is the single import that pulls in the whole library in dependency order. The modules expose **global** singletons (no `local M = {}; return M` module pattern — this is Playdate's flat `import` namespace):

- `Vec` / `Util` — 2D vector math, `clamp`, and a delayed-call scheduler (`Util.runPending`/`clearPending`). `Util` is a compatibility alias kept so all games read uniformly.
- `Field` — the 400×240 playfield: screen wrapping and wrap-aware distance (`Field.dist2`).
- `Shapes` — polyline models drawn transformed; `Shapes.drawWrapped` for screen-wrap rendering.
- `proj` — 3D wireframe camera with near-plane clipping. Ground games (treadline, nightvector, trenchfire) move a yaw-only camera with `Proj.model`/`Proj.line`/`Proj.horizon`. Free-flight (elite) instead keeps the camera at the origin (`Proj.setCamera(0,0,0,0,0)`) and draws full-attitude objects with `Proj.mesh(verts, edges, pos, orient, scale)`, where `verts` is a flat `{x,y,z,...}` model array and `edges` is a flat 1-based index-pair array.
- `Mat` — 3x3 orientation matrices (flat row-major 9-arrays) for objects at any attitude: `identity`, `mulVec`, `mul`, the axis rotations `rx/ry/rz`, the premultiply helpers `spinX/Y/Z`, and `tidy` (re-orthonormalize to shed per-frame drift, anchored on the nose = column 3). Column 3 is the object's forward (+Z) direction. This is the general-purpose 3D layer `Proj.mesh` and elite are built on.
- `Beams` — a vector **stroke** font (no raster font); `Beams.print` for all HUD/title text at any pixel height.
- `Fx` — shared particle/debris/flash pool (`Fx.burst`, `Fx.debris`, `Fx.flashing`).
- `Sfx` — shared synth voice kit.
- `Harness` — the smoke-test harness (see below).
- `Attract` — **owns `playdate.update`.** A game does not write its own main loop; it hands `Attract.setup{}` a config and Attract runs the title → play → game-over state machine, draws the shared bezel/chrome, and persists the high score via `playdate.datastore`.

### A game is hooks on the cabinet

Each `games/<name>/` is a thin set of modules layered on the library. `games/rubble/` is the reference structure. The convention across files:

- `config.lua` defines a global `C` table of tunables (everything is a named constant here — speeds, radii, point values).
- `gamestate.lua` defines a global `G` table holding live game state plus helpers like `G.addScore`.
- `input.lua` defines `Input.gather()` returning the frame's control values, **and** sets `Harness.autopilot` — the function the smoke build uses to play itself.
- `draw.lua` defines render functions (`Draw.play`, `Draw.ambient`).
- `main.lua` imports `lib` first, then the game's modules, defines the `start`/`update` logic, and ends by calling `Attract.setup{ title, controls, hooks = { start, update, draw, ambient, drawAmbient, score } }`. `update` does sim + entity logic; `draw` renders after Attract has cleared the screen.

`Input.gather()` must check `Harness.enabled and Harness.autopilot` first and return the autopilot's values when in a smoke build — that is what makes the game playable headlessly.

### Build staging

`pdc` wants a single source root. The Makefile copies `vec/*.lua` + `games/<g>/*` into `build/<g>/source`, strips `README.md`/`screenshot.png`, and writes `smokeflag.lua` (`SMOKE_BUILD = false` for release, `true` for `-smoke`) before invoking `pdc`. So `import "smokeflag"` resolves to a generated file, never one in the repo.

### Smoke harness

When `SMOKE_BUILD` is false, `Harness` is a no-op and games pay nothing. When true, `Harness.frame` (called by Attract) wraps each update in `pcall`, writes any error to the `err` datastore, emits a telemetry heartbeat to the `smoke` datastore every 90 frames (counters from `Harness.count`/`set` plus the game's `Harness.extra` fields), and writes periodic screenshots to `Harness.shotPath`. `tools/smoke.sh` reads those datastore files back from `~/Developer/PlaydateSDK/Disk/Data/<bundleID>/`.

## Conventions

- Refresh rate is 30 fps; `Attract.dt` is `1/30`. Per-frame turn/accel constants are expressed per second and multiplied by `dt`.
- Globals (`C`, `G`, `Vec`/`Util`, `Field`, `Beams`, `Fx`, `Sfx`, `Attract`, `Harness`, `Input`, `Draw`, `Shapes`) are intentional — do not refactor them into locals/returns; the import system and every game depend on them.
- New tunables go in `C`; instrument new behavior with `Harness.count(...)` so smoke runs surface it.
- `games/elite/ships.lua` is generated, not hand-written: the ship meshes are parsed from `ship_*.asm` blueprints in the Elite source archive (vertices + edge index-pairs, kept in Elite's native coordinates). Regenerate rather than hand-edit. Elite's flight model keeps the player fixed at the origin and rotates/slides the universe around them each frame (`World.update`), which is also why its scanner and docking math read straight off each object's camera-space position.
