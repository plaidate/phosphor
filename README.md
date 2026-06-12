# Phosphor

Twelve vector arcade games for the Playdate, sharing one library — white
beam lines on black, the way the cabinets drew them. Every game is an
original implementation of a classic vector-era design, with the crank
doing what each cabinet's spinner, throttle, yoke, or wheel did.

| Game | Inspired by the era of | Crank |
|---|---|---|
| Rubble | rock-field shooters (1979) | spin ship |
| Welldiver | tube shooters (1981) | spinner |
| Touchdown | lunar landers (1979) | throttle |
| Ringkeep | ring-fortress duels (1980) | spin ship |
| Border Circuit | arena racers (1981) | spinner |
| Lifters | canister-defense (1980) | spin ship |
| Webguard | web shooters (1983) | aim |
| Treadline | first-person tank combat (1980) | turret |
| Night Vector | first-person night driving (1979) | steering wheel |
| Trenchfire | trench-run rail shooters (1983) | throttle |
| Gravity Wells | gravity missions (1982) | spin ship |
| Duelstar | two-ship duels (1977) | spin ship |

## Layout

- `vec/` — the shared library: 2D/3D vector math, a wireframe projection
  camera with near-plane clipping, polyline shape models, a vector stroke
  font, particles/debris, synth voices, a shared attract-mode cabinet, and
  a built-in smoke-test harness.
- `games/<name>/` — each game is a thin directory of modules on top.

## Building

Requires the Playdate SDK (`pdc` on PATH).

    make <game>         # out/<Title>.pdx
    make all            # everything
    make <game>-smoke   # instrumented build (autopilot + telemetry)
    tools/smoke.sh <game> [seconds] [until-grep]   # headless verification

MIT licensed.
