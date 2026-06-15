# Elite

Wireframe space combat from the cockpit — fly, fight, dock, jump.

![Elite](screenshot.png)

## Controls

- Crank — roll (d-pad left/right rolls too)
- D-pad up/down — pitch (up climbs)
- A — fire the front laser
- B is the secondary-functions modifier:
  - B + up/down — throttle
  - B + A — launch a missile at the locked target
  - B + left — E.C.M. (destroy incoming missiles)
  - B + right — energy bomb
- Dock with the station for the trade screens — buy/sell cargo at the
  market, equip your ship, pick a jump target on the galactic chart

## How it plays

You are the ship: the cockpit is fixed and the whole universe wheels
around you as you roll and pitch, exactly as the 1984 original flew it.
Pirates close in and fire when they line you up — roll them onto the
vertical and pitch them into the reticle, and a held laser does the
rest. Watch the laser-temperature gauge (LT); a maxed laser cuts out
until it cools.

The 3D scanner below the view plots every contact: left/right and
fore/aft on the ellipse, above/below on the stalk. The station shows
as the larger blip. Clear a system for the bounties, then fly into the
station — slow (at or below the docking speed) and dead centre — to
refuel, repair, and jump to the next, tougher system. Hit it fast or
off-centre and you scatter yourself across the hull.

Your shields soak fire and recharge from the energy banks; when energy
hits zero, you're gone. Kills raise your combat rating from Harmless all
the way to Elite.

The ships are the real thing: the meshes are the vertex-and-edge
blueprints from the [Elite source archive][src] (Sidewinder, Mamba,
Viper, Cobra Mk III, Python, the Coriolis station, asteroids and cargo),
and the controls follow the NES port's scheme.

[src]: https://github.com/markmoxon/elite-source-code-library

---

Part of [Phosphor](../../README.md) — `make elite` from the repo root
builds it; a ready-to-play copy ships in [`dist/`](../../dist/).
