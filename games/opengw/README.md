# Geometry Wars

Twin-stick arena shooting on a living vector grid.

![Geometry Wars](screenshot.png)

## Controls

- D-pad — fly the ship (full momentum, eight directions)
- Crank — absolute aim dial: point it where the guns should fire
- Autofire is always on
- B (or A) — smart bomb

## How it plays

Survive an arena that fills with geometric enemies. Guns fire wherever the
crank points, so flying and aiming are independent — circle a swarm while
raking it from the side. Your gun **auto-switches** every 10,000 points
between a twin spread, a rapid alternating gun, and a five-way fan. Killing
enemies climbs your scoring **multiplier** — +1 every 25 kills, up to ×6 — but
die and it resets to one.

The full cast arrives as the run heats up, both as a steady trickle and as
**waves** that pour from a corner or ring you in:

- **Grunts** — diamonds that home straight in (50)
- **Wanderers** — drifters that bounce off the walls (25)
- **Spinners** — stars that charge you and split into two tiny spinners (100 + 50×2)
- **Weavers** — hexagons that juke your shots (100)
- **Mayflies** — flapping swarmers (50)
- **Snakes** — a shootable head dragging a long, deadly tail; kill the head (50)
- **Black holes** — drag the grid into a deep well, pull in everything nearby,
  and bend your shots; pump enough rounds in and they burst into **protons** (50)
- **Repulsors** — shielded chargers that swat away any shot from the front;
  flank them (100)

The whole floor is a spring-loaded lattice: your wake, your shots, every
explosion, the bombs, the black holes' pull all dent and ripple it. Five
lives, five bombs; an extra ship every 75,000 and an extra bomb every 100,000.
A smart bomb clears the screen and blows the grid wide open — save them.

Two-player co-op from the original is left out: a single Playdate has one
d-pad and one crank.

---

Part of [Phosphor](../../README.md) — `make opengw` from the repo root
builds it; a ready-to-play copy ships in [`dist/`](../../dist/). An original
implementation of the [Open Geometry Wars][gw] design; clone the upstream C++
source into `opengw/` (git-ignored) as a reference.

[gw]: https://github.com/capehill/opengw
