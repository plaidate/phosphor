# Phosphor Developer Guide

How the shared `vec/` layer works, how a game plugs into it, and how to add
a new game to the collection. For player-facing rules see
[MANUAL.md](MANUAL.md).

## The big picture

Phosphor is sixteen vector arcade games that share one small library. There
is no framework and no build system beyond `pdc`: the Makefile *stages* a
game by copying `vec/*.lua` and `games/<name>/*` into one flat
`build/<name>/source/` directory (pdc wants a single source root), writes a
one-line `smokeflag.lua` (`SMOKE_BUILD = true|false`), and runs `pdc`. Every
module is therefore imported by bare name — there are no directories at
runtime.

Games run at a fixed 30 fps with a fixed `dt` of 1/30 (`Attract.dt`).
Everything is drawn with `playdate.graphics.drawLine` — white beams on
black, one pixel (or `weight` for titles) wide. No sprites, no images, no
raster fonts.

### Directory layout

- `vec/` — the shared library (~1000 lines, eleven modules, described below)
- `games/<name>/` — one directory per game: `main.lua`, `pdxinfo`,
  usually `config.lua`, `input.lua`, `draw.lua`, `gamestate.lua`, plus
  entity modules; also a `README.md` and `screenshot.png` (both stripped
  from builds)
- `tools/smoke.sh` — build the instrumented variant, run it headlessly in
  the Simulator, poll the datastore, report
- `tools/gen_ships.py` — offline generator that converted the original
  Elite ship `*.asm` vertex/edge data into `games/elite/ships.lua`
- `build/`, `out/` — staging and `.pdx` output (disposable);
  `dist/` — committed release builds; `results/` — smoke heartbeats

## The vec/ layer

One import pulls in everything, in dependency order — a game's `main.lua`
starts with `import "lib"`:

`vec` → `field` → `grid` → `shapes` → `mat` → `proj` → `beams` → `fx` →
`sfx` → `harness` → `attract` (plus `CoreLibs/graphics`).

Each module defines a single global table — that is the package's module
convention, game-side too (`C`, `G`, `Input`, `Draw`, `Ship`, ...). Playdate
Lua is Lua 5.4 with `import` (not `require`); files execute once, top to
bottom, into the shared global environment.

### vec.lua — `Vec`, `Util`
2D vector math on plain numbers (no vector objects, no allocation):
`Vec.len/norm/rot/fromAngle/angleOf/angleDiff/lerp`. Angles are degrees at
the API surface, radians internally. `Util.clamp`, plus a delayed-call
scheduler: `Util.after(delay, fn)` queues, `Util.runPending(dt)` is pumped
by Attract every frame, `Util.clearPending()` runs at game start. `Sfx`
uses the scheduler for multi-note effects.

### field.lua — `Field`
The 400x240 playfield. `Field.wrap(x, y)` toroidal wrapping,
`Field.dist2` shortest wrapped distance squared, and
`Field.offsets(x, y, r, fn)` which calls `fn(ox, oy)` for every wrap
offset under which an object of radius `r` could be visible — the standard
way to draw and collide near screen edges.

### grid.lua — `Grid`
The warping spring lattice behind Geometry Wars-style games. Every point
is anchored to its home by a weak spring and Laplacian-coupled to its four
neighbours, so `Grid.push(x, y, strength, radius)` (negative strength =
`Grid.pull`) dents the mesh and the dent ripples outward before settling.
Flat parallel arrays, zero allocation per frame; a per-point max offset
clamp keeps wild forces from exploding it. `Grid.init{spacing, stiff,
couple, damp, maxoff}` sizes it to the field; `Grid.draw` strokes it.

### shapes.lua — `Shapes`
2D polyline models: a shape is a list of flat `{x1,y1,x2,y2,...}` arrays in
model space. `Shapes.draw(shape, x, y, angleDeg, scale)` transforms and
strokes; `Shapes.drawWrapped` adds `Field.offsets`. Generators:
`Shapes.blob` (closed irregular polygon — asteroids, debris) and
`Shapes.gon` (regular or alternating-radius n-gon).

### mat.lua — `Mat`
3x3 orientation matrices (flat row-major 9-arrays) for full-attitude 3D:
`identity/mulVec/mul/rx/ry/rz`, `spinX/Y/Z` (premultiply by a parent-axis
rotation), and `Mat.tidy` — Gram-Schmidt re-orthonormalization anchored on
the nose column, the equivalent of Elite's TIDY, run occasionally to shed
rounding drift on matrices that spin every frame.

### proj.lua — `Proj`
The 3D wireframe camera for first-person games. World space is X right,
Y up, Z forward; `Proj.setCamera(x, y, z, yawDeg, pitchDeg)`.
`Proj.point` projects (nil behind the near plane), `Proj.line` clips
against the near plane by interpolation so geometry can pass the camera
without artifacts, `Proj.model` draws yaw-rotated 3D polylines (ground
games), `Proj.mesh(verts, edges, pos, mat, scale)` draws an indexed
wireframe at full attitude (free-flight games keep the camera at the
origin and move the universe), `Proj.horizon` draws the ground-plane
horizon for the current pitch.

### beams.lua — `Beams`
A vector stroke font (4x6 grid glyphs, parsed once at load), so HUDs and
titles are beam lines like the cabinets drew. `Beams.print(s, x, y, size,
{align, weight})` and `Beams.width`. Uppercase letters, digits, and basic
punctuation only — `Beams.print` upcases for you, unknown glyphs advance
silently.

### fx.lua — `Fx`
Shared juice pool: `Fx.burst` (point particles), `Fx.debris` (tumbling
line fragments), `Fx.flash(seconds)` (full-screen invert strobe; Attract
checks `Fx.flashing(frame)` when clearing). `Fx.update` is pumped by
Attract; games call `Fx.draw` from their draw hook. `Fx.reset` runs at
game start.

### sfx.lua — `Sfx`
A standard arcade synth kit on seven shared voices: `pew`, `blip`,
`thrustTick`, `boom(size)`, `bigBoom`, `zapSweep`, `warble`,
`fanfare(notes, step)`, `sirenTick(base)`, `beat` (the two-tone
Asteroids heartbeat), `descend`. Multi-note effects sequence themselves
through `Util.after`. Games may create extra `playdate.sound.synth`
voices of their own.

### attract.lua — `Attract`
The shared cabinet: title/attract screen, play, game over, high-score
persistence, and the package-wide look (black clear, white lines, the
thin bezel `drawRect`). Attract owns `playdate.update`. A game hands it
hooks once, at load:

```lua
Attract.setup({
    title = "RUBBLE",
    controls = { "CRANK - SPIN SHIP", "B OR UP - THRUST", "A - FIRE" },
    hooks = {
        start = startGame,          -- begin a fresh run
        update = updatePlay,        -- one play frame: sim + entity logic
        draw = Draw.play,           -- one play frame: render (after clear)
        ambient = ambient,          -- optional: sim behind title/game-over
        drawAmbient = Draw.ambient, -- optional: render behind title/game-over
        score = function() return G.score end,
    },
})
```

The game ends a run by calling `Attract.gameOver()`; Attract compares the
`score` hook against the saved high score and persists it via
`playdate.datastore` (one datastore per game, keyed by bundle ID — do not
rename bundle IDs). `Attract.setup` also seeds `math.random`, sets the
30 fps refresh rate, and adds a "restart" system-menu item. State machine:
`"title" → "play" → "over" → "title"`; A starts (instantly under the
smoke harness). `update` runs before the clear+`draw` pair, and drawing is
skipped on the frame the game calls `Attract.gameOver()`.

### harness.lua — `Harness`
The smoke-test harness as a first-class module. The staged `smokeflag.lua`
sets `SMOKE_BUILD`; when false everything is a no-op and release builds pay
nothing. When true:

- `Harness.count(key, n)` / `Harness.set(key, val)` accumulate counters
- `Harness.frame` (called by Attract's `playdate.update`) pcall-wraps the
  frame; errors are written to the `"err"` datastore
- every 90 frames the counters plus `Harness.extra(t)` fields are written
  to the `"smoke"` datastore — the heartbeat `smoke.sh` polls
- every 300 frames a screenshot is written to `Harness.shotPath`
  (repo-relative; Simulator only)
- `Harness.autopilot` — the game's `input.lua` sets this to a function
  returning the same tuple as `Input.gather()`, and `Input.gather()`
  returns it when `Harness.enabled`. The game plays itself; the title
  screen auto-starts.

## Anatomy of a game

`games/rubble/` is the reference. The pattern:

- **main.lua** — `import "lib"` then the game's own modules; defines
  `startGame` (reset `G`, spawn the first wave), `updatePlay(dt)` (gather
  input, step entities, collide, detect game over), optional `ambient`;
  sets `Harness.shotPath` and `Harness.extra`; calls `Attract.setup` at
  the bottom. No `playdate.update` — Attract owns it.
- **config.lua** — the `C` table of tunables. All the numbers live here.
- **gamestate.lua** — the `G` table (score, lives, entity lists) plus any
  state helpers.
- **input.lua** — `Input.gather()` returns a flat intent tuple
  (e.g. `turn, thrust, fire, hyper`), reading crank + buttons; it also
  defines `Harness.autopilot` returning the same tuple, so gameplay code
  never knows whether a human is playing. Crank is primary, d-pad is the
  fallback.
- **draw.lua** — `Draw.play` (and optionally `Draw.ambient`): pure
  rendering from `G`, using `Shapes`/`Proj`/`Beams`. Colour is already
  white on black when the hook runs.
- **entity modules** — `Ship`, `Rocks`, `Enemies`, ... one global table
  per concern, updated explicitly from `updatePlay` (no entity component
  system, no scene graph — a game is a handful of arrays and a loop).

## Adding a game

1. `mkdir games/<name>` — lowercase, one word (the Makefile title-cases it
   for the `.pdx` name).
2. Write `pdxinfo`: `name=Phosphor: <Title>`,
   `bundleID=com.sdwfrost.phosphor.<name>`, author, one-line description,
   `version=1.0`, `buildNumber=1`. The bundle ID keys the save datastore —
   pick once, never change.
3. Start `main.lua` with `import "lib"`, add `config.lua` / `gamestate.lua`
   / `input.lua` / `draw.lua` and entity modules per the pattern above,
   and wire `Attract.setup` with your hooks.
4. Add `<name>` to `GAMES` in the Makefile. `make <name>` builds
   `out/<Title>.pdx`.
5. Write the autopilot in `input.lua` (aim at the nearest threat, fire,
   dodge — a few lines is usually enough), add `Harness.count` calls at
   interesting events (`games`, `waves`, `gameovers`, kills), set
   `Harness.shotPath = "build/<name>-shot.png"` and a `Harness.extra`
   with score/lives/state.
6. `tools/smoke.sh <name> 180 '"gameovers":[1-9]'` — builds the `-smoke`
   variant and lets it play itself in the Simulator until the grep matches
   (or an error lands in `err.json`).
7. Add the game's `README.md` + `screenshot.png`, a row in the root
   README table, and a section in `MANUAL.md`.
8. Ship: `make <name>`, copy `out/<Title>.pdx` into `dist/`.

## Per-game notes

(One paragraph per game; display names as on the title screens.)

- **Rubble** — Classic Asteroids loop. Modules: `config`, `gamestate`,
  `ship`, `rocks` (asteroids, both saucers, all collisions), `input`,
  `draw`. Uses `Field.wrap`/`Field.dist2` on the 400×240 wrap field,
  `Shapes.blob` for lumpy rocks, `Shapes.drawWrapped` for the edge seam,
  `Fx`, `Sfx`, `Beams`. No 3D, no Grid.
- **Welldiver** — the most bespoke early game: a Tempest-style tube shooter
  with its *own* radial perspective in `wells.lua` (`Wells.persp(z)` depth
  scaling, lane math) — it does **not** use the library `Proj`. A custom
  submode machine (`G.mode` = "play"|"warp") sits inside Attract's play
  state, with a live title-screen level selector on the `ambient` hook.
  Modules: `config`, `gamestate`, `wells`, `player`, `enemies`, `shots`,
  `input`, `draw`. All-`drawLine` rendering; `Vec.rot`, `Fx`, `Sfx`, `Beams`.
- **Touchdown** — Lunar Lander. Modules: `config`, `gamestate`, `terrain`
  (random-walk skyline + pads + `heightAt`/`padUnder`), `lander` (flight
  model + safe-landing judgement), `input`, `draw`. A three-state machine
  ("fly"|"landed"|"crashed") inside Attract's play state. `Shapes`, `Beams`,
  `Fx`, `Sfx`. No wrap, no 3D.
- **Ringkeep** — original ring-fortress siege reusing Rubble's ship feel
  (crank 1:1, momentum, drag, wrap). Modules: `config`, `gamestate`, `ship`,
  `castle` (rings + core line-of-sight + homing fireball + orbit/chase
  mines), `input`, `draw`. `Field.wrap`/`dist2` plus its own signed
  `G.wrapDelta` for steering; `Shapes.gon`/`drawWrapped`, `Vec`, `Fx`,
  `Sfx`. Shot-vs-ring uses a radial-crossing test so fast shots can't tunnel.
- **Border Circuit** — non-wrapping arena racer. Modules: `config`,
  `gamestate`, `arena` (outer wall + central HUD barrier reflection physics
  + circuit waypoints), `ship`, `enemies` (drones/layers/mines), `input`,
  `draw`. Custom `Arena.bounce` (least-penetration reflection) instead of
  `Field.wrap`; `Vec`, `Util.clamp`, `Shapes`, `Beams`, `Fx`, `Sfx`. No 3D.
- **Lifters** — canister-defense; loss condition is fuel count, not lives
  (unlimited ships). Config+state together in `gamestate` (no `config.lua`).
  Modules: `gamestate`, `ship`, `raiders` (a seek→drag FSM plus rammers),
  `input`, `draw`. Non-wrapping (soft edge bounce, local `G.dist2`); `Vec`,
  `Shapes`, `Beams`, `Fx`, `Sfx`. No 3D.
- **Webguard** — twin-stick web defense. Modules: `config`, `web`
  (precomputed spoke/ring node lattice + neighbour graph), `player`,
  `enemies` (chaser/layer/egg/bomber/frag), `input`, `draw`. Layers path
  node-to-node via `Web.neighbor`; a shuffled spawn queue drains on a
  per-wave-shrinking timer. Non-wrapping, radial confinement; `Shapes.gon`,
  `Vec`, `Fx`, `Sfx`, `Beams`. No 3D.
- **Treadline** — first-person tank combat, and the first user of the shared
  **Proj** wireframe camera (`setCamera`/`point`/`line`/`model`/`horizon`).
  Modules: `config`, `gamestate` (independent hull yaw + turret offset =
  `G.viewYaw()`), `world` (infinite plain: obstacle scatter/recycle,
  `losBlocked` segment test, 3D frag bursts, fake mountain silhouette),
  `tanks` (player treads/turret + enemy stalk/circle/aim FSM with per-kill
  lead tuning + skimmer ram), `input`, `draw` (scene + turret-relative
  radar + hull-offset needle + procedural cracked windshield). `Vec`,
  `Shapes` (2D HUD), `Fx`, `Sfx`, `Beams`.
- **Night Vector** — first-person night driving on the **Proj** camera
  (with pitch for hills). Modules: `config`, `gamestate`, `road`
  (procedural curvature/hill/obstacle generation + `Road.point`/`curveAhead`
  centerline sampling), `car` (speed model, off-road drag, traffic
  collision + overtake scoring), `input`, `draw`. Fixed-ahead segment
  rendering as the "headlight throw"; a checkpoint clock is the fail state.
  `Vec`, `Beams`, `Fx`, `Sfx`. No wrap field.
- **Trenchfire** — wireframe rail shooter on **Proj**; the ship *is* the
  camera and eases toward a d-pad crosshair. Modules: `config`, `gamestate`,
  `world` (a three-phase level machine — APPROACH/TOWERS/TRENCH — that
  spawns fighters, ground towers, then the canyon with wall hardpoints,
  braces, and the end-wall port; plus fireballs and all collisions),
  `input`, `draw`. Crank throttle scales both ship speed and the score
  multiplier. Shields are lives. `Proj.point` drives autopilot targeting;
  `Vec`, `Beams`, `Fx`, `Sfx`.
- **Gravity Wells** — two-scale gravity missions. Modules: `config`,
  `gamestate`, `ship` (shared across scales), `system` (star + planets,
  constant inward pull, soft edge), `mission` (per-well side-view: gravity
  sign, bunkers, fuel tanks, tractor beam, reactor + escape timer), `input`,
  `draw`. `G.view` = "system"|"mission" swaps the whole update/draw inside
  Attract's play state. Fuel economy is the core constraint. `Vec`,
  `Shapes`, `Beams`, `Fx`, `Sfx`. No 3D/Proj.
- **Duelstar** — 1-v-1 gravity duel. Modules: `config`, `gamestate`
  (round/win bookkeeping), `ships` (shared ship physics + `sunDanger`/
  `leadAngle`/`tangentSide` gravity-aware helpers), `rival` (three rotating
  personality brains — orbiter/sniper/brawler — scaling with player wins),
  `input`, `draw`. Central-mass gravity bends ships *and* shots (`GRAV_MU`);
  a round/match state machine ("intro"|"fight"|round-pause) inside Attract's
  play state. `Vec`, `Shapes`, `Beams`, `Fx`, `Sfx`. No wrap, no 3D.
- **Elite** — the largest game: wireframe space trading and combat. The
  player is the fixed camera at the origin and the whole universe is
  transformed each frame, so it leans on **Mat** (per-object orientation
  matrices, `tidy`) and **Proj** (`point`/`mesh`). Ships are real Elite
  vertex/edge blueprints in a generated `ships.lua` (from
  `tools/gen_ships.py`; do not hand-edit). `galaxy.lua`/`trade.lua` are
  pure-Lua faithful ports (deterministic seed generation, no Playdate API —
  testable off-device). A docked sub-mode (`G.docked`) swaps update/draw to
  `docked.lua`'s station screens rather than adding an Attract state; the
  campaign saves to datastore key `"cmdr"` at every dock. `Fx`, `Sfx`,
  `Beams`.
- **Geometry Wars** (`opengw`) — twin-stick grid shooter built on the
  **Grid** spring lattice (every actor dents it — the signature effect).
  Modules: `config`, `gamestate`, `player`, `enemies`, `spawner`, `input`,
  `draw`. Difficulty is a continuous `spawnIndex`/`aggro` ramp rather than
  discrete waves. `Field`, `Vec`, `Shapes.gon`, `Fx`, `Sfx`, `Beams`.
- **Vectorblade** — Galaga-style swarm shooter with a between-wave shop.
  Modules: `config` (data-driven ranks table + `C.rankFor`), `gamestate`,
  `player`, `enemies` (quadratic-bezier fly-in into a breathing formation +
  dive AI), `bonuses` (drop letters), `shop`, `input`, `draw`. An in-play
  mode machine (`G.mode`: intro→battle→cleared→shop) inside Attract's play
  state — the shop is a mode, not a separate state. `Field`, `Vec`,
  `Shapes`, `Fx`, `Sfx`, `Beams`. No 3D.
- **Gyre** — Gyruss-style polar tube shooter. Modules: `config`,
  `gamestate` (polar helpers: `G.polarPx`, `G.scaleAt` for faked depth, plus
  a slot-allocation system for the rotating hub formation), `stars`, `paths`
  (a Catmull-Rom spline engine driving all enemy entry/attack/recall
  motion), `player`, `enemies`, `events` (satellites/meteors/laser pairs),
  `stage` (director: squad scheduling, stall detection, chance stages),
  `input`, `draw`. A rich in-play mode machine (intro/play/clear/warp/tally).
  `Vec`, `Shapes.blob`, `Fx`, `Sfx`, `Beams`. No Mat/Proj/Grid.

### Cross-cutting refactor candidates (noted during review, not applied)

These were flagged by the code-review pass as DRY opportunities for the
`vec/` layer. They are deliberately **not** implemented — polish was
behavior-preserving only — but are recorded here for a future engine pass:

- **A shared crank-momentum ship.** `rubble/ship.lua` and `ringkeep/ship.lua`
  are ~90% identical (crank-spun momentum ship with drag, speed clamp,
  wrapped bullets), and Duelstar/Gravity Wells share the same shape. A
  `vec/` ship mixin plus a shared config block could collapse them.
- **`Field.delta` (signed wrap vector)** and **`Vec.dist2` (plain,
  non-wrapping)** — several games re-roll these because `Field.dist2` is
  wrap-aware and the non-wrapping arenas (Border Circuit, Lifters, Webguard)
  need a plain version, while chase AIs (Ringkeep's `G.wrapDelta`) need a
  signed one.
- **`Vec.len3` / `Vec.clampLen`** — Elite hand-rolls a 3D length in three
  files; the "normalize and cap speed" idiom recurs across several games.
- **Dead `local clamp = Util.clamp`** — appears at the top of many modules;
  a handful were unused and removed during review. A repo-wide sweep
  (`grep -L "clamp(" $(grep -rl "local clamp = Util.clamp" games)`) would
  catch the rest.
