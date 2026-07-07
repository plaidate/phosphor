# Phosphor — Player's Manual

Sixteen vector arcade games for the Playdate, drawn in white beam lines on
black. Each is a self-contained cabinet with its own controls, waves, and
persistent high score. This manual has one section per game; every game
also lists its controls on its own title screen.

**Universal notes:**
- Press **A** to start (and to continue past GAME OVER).
- The **crank** is each game's main control — the title screen says what it
  does. The **d-pad** is always a fallback.
- High scores save automatically, per game, on the device.
- A "restart" item in the Playdate system menu drops you back to the title.

---

## Rubble

*Vector rock-blasting with full Newtonian momentum — spin, drift, and pray.*

You are one ship adrift in a field of tumbling rocks, with nothing but a
pea-shooter and a nerve-wracking emergency teleporter. Blast every rock to
gravel, survive the saucers that drop by to take pot-shots, and keep the
field clear as each new wave arrives heavier than the last. The cabinet's
heartbeat quickens as the rocks thin out — the quiet is the dangerous part.

**Controls:**
- **Crank** — spins the ship 1:1 (one crank degree = one degree of turn)
- **Left / Right** — turn the ship (d-pad fallback, 240°/sec)
- **B or Up** — thrust (momentum builds; drag slowly bleeds it off)
- **A** — fire (max 4 shots on screen, ~7 shots/sec)
- **Down** — hyperspace jump (teleport to a random spot; 1-in-6 chance it kills you)

**How to play:**
Clear the field to advance. Every rock you shoot splits: a large rock breaks
into two mediums, each medium into two smalls, and smalls vanish. The ship
carries momentum and the screen wraps at every edge, so thrust is a
commitment — you keep drifting until you thrust the other way. Firing adds
your own velocity to the bullet, so a fast ship throws fast shots.

Hyperspace is your panic button when you are boxed in: it drops you somewhere
random with a brief moment of invulnerability, but one time in six you
rematerialize dead. Use it only when a collision is otherwise certain.

**Scoring & progression:**
- Large rock: **20** · Medium rock: **50** · Small rock: **100**
- Big saucer: **200** · Small saucer: **1,000**
- Each cleared field spawns the next wave: 4 large rocks on wave 1, +2 per
  wave, capped at 11.
- Extra ship every **10,000 points** (up to 8 ships in reserve).
- You start with **3 ships**.

**Enemies & hazards:**
- **Large / Medium / Small rocks** — drift and spin at random; smaller
  fragments move faster (large ~22-45 px/s up to small ~65-110 px/s). A rock
  that touches your hull is fatal unless you are still spawn-invulnerable.
- **Big saucer** — cruises across the field firing in *random* directions
  and zig-zagging vertically. Dangerous by volume, not aim.
- **Small saucer** — appears once you have a reputation (score ≥ 8,000, or
  ≥ 3,000 with 40% odds). It *aims* at you, and its aim tightens as your
  score climbs (spread shrinks from ~24° down to 2°). Kill it fast.
- Saucers only visit while rocks remain, roughly every 18 seconds — an
  interval that shortens as your score grows. Saucers are not immune to the
  rocks either; they occasionally fly into one.

**Tips:**
- Tap-thrust rather than holding B. A slow ship is far easier to aim, and
  momentum + wrap means a long burn will fling you back into a rock you
  already passed.
- The screen wraps, so a rock leaving one edge reappears on the opposite
  side — line up shots through the wrap seam when a rock hugs an edge.
- Kill the small saucer the instant it appears; every extra second lets its
  aim tighten toward a dead-eye lock.
- When only small rocks remain the heartbeat is fastest but the field is
  most lethal — smalls move quickest. Clear them decisively rather than
  drifting among them.
- Save hyperspace for genuine no-escape moments; the 1-in-6 death makes it a
  worse bet than almost any thrust-away.

---

## Welldiver

*Crank the claw around the rim of a bottomless well and blast whatever climbs toward you.*

You grip the mouth of a geometric well while its residents spiral up out of
the depths toward your lane. Sweep around the rim, pour fire down the tubes,
and when the well is empty, dive through it to the next one. Every well wears
its own shape and its own line style — and a deeper starting dive pays a fat
bonus for the brave.

**Controls:**
- **Crank** — spins the claw around the rim (one full revolution sweeps all 16 lanes)
- **Left / Right** — step the claw lane to lane (d-pad fallback)
- **B** — fire down your lane (max 8 shots)
- **A** — Superzapper
- **On the title screen** — crank or Left/Right to pick your starting level (1 / 3 / 5 / 7)

**How to play:**
Enemies climb from the far end of the well (depth 0) toward the rim (depth 1),
where they can reach and kill you. Keep the claw over threats and fire; your
shots race down the lane and detonate anything in it, including enemy shots
and spikes. Clear every enemy and the level ends in a **warp** — a two-second
plunge down the well to the next one.

The **Superzapper** is a once-per-level panic weapon: the first press vaporizes
*every* enemy on the field; a second press (if any survive) kills one more at
random. After that it is spent until the next level, shown by the ZAP light
and the "SUPERZAPPER RECHARGE" banner.

During the warp, watch the lanes: **spikes** left by spikers become hull
breaches if one is taller than your current depth. Steer to a spike-free lane,
or shoot spikes down before you dive into them.

**Scoring & progression:**
- Flipper **150** · Tanker **100** · Spiker **50** · Fuseball **250**
  (**500** if it reaches the rim) · Pulsar **200** · Spike whittled **1** per hit
- Deeper start bonus: level 1 = **0**, level 3 = **+6,000**, level 5 = **+16,000**,
  level 7 = **+30,000** (banked immediately at game start)
- Extra life every **20,000 points**, up to 6 lives; you start with **3**.
- Levels cycle six well shapes (circle, square, star, line, vee, diamond) and
  six line styles; enemies climb faster and arrive in greater numbers each level.

**Enemies & hazards:**
- **Flipper** — climbs, then cartwheels lane to lane, biasing toward your lane
  as it nears the rim; at the rim it stalks you around the edge. Fatal on contact.
- **Tanker** — slow; splits into two flippers (or fuseballs from level 7) when
  shot *or* when it reaches the rim's edge. Shoot it deep so the halves have
  further to climb.
- **Spiker** — fast; climbs partway leaving a growing spike in its lane, then
  retreats and starts a new spike elsewhere. The spikes are the real threat —
  they menace the warp.
- **Fuseball** — jittery, drifts up and down and hops lanes unpredictably;
  can't be reliably tracked, and is worth double if it makes the rim.
- **Pulsar** — lurks just below the rim and periodically electrifies its whole
  lane; sitting on an electrified lane kills you. Don't loiter on a pulsar's lane.
- **Enemy shots** — spinning tri-spikes fired up a lane by climbing flippers
  and tankers. They are destructible — a well-timed shot cancels them.

**Tips:**
- Fire constantly. Shots are cheap (8 in flight) and clearing enemies deep is
  far safer than fighting them at the rim.
- Hold the Superzapper for a rim crowd, not the first enemy — its first press
  is a full board wipe, so cash it when three or more reach the top at once.
- Shoot tankers as deep as possible; splitting them near the rim dumps two
  fresh flippers right on top of you.
- Before the wave clears, whittle down any tall spikes — you're about to dive
  through those lanes, and a spike taller than your depth is a death.
- A deeper starting level is free points if you can handle the pace: +30,000
  for starting on level 7 is worth several early levels of grinding.

---

## Touchdown

*Feather a lunar lander onto a flat pad before gravity or your fuel gauge has the last word.*

Gravity is patient; your fuel is not. Ride the crank-controlled throttle down
through a jagged moonscape and set all four feet on a landing pad — gently,
level, and slow. The narrow pads pay the big multipliers, but they leave no
room for a sloppy approach. Bank fuel with every clean landing and see how
many moonscapes you can conquer before the tank runs dry.

**Controls:**
- **Crank** — throttle, analog 0-100% (crank forward to add thrust, back to cut it)
- **Left / Right** — tilt the lander (up to 90° either side)
- **B** — full burn (overrides the throttle to 100% while held)

**How to play:**
Thrust pushes along the ship's up-axis, so your tilt steers your horizontal
drift — lean to kill sideways speed, then level out for the touchdown. Gravity
pulls a constant 22 px/s² downward the whole time.

A landing counts as safe only if you come down on a flat pad with **both feet
on the same pad**, **|horizontal speed| < 12**, **descent speed < 25** (and not
rising), **tilt under 12°**, and no part of the hull touching ground. Miss any
of those and you crash. The HUD readouts (VX, VY, FUEL) flash when a value is
out of safe limits — watch them on final approach.

**Scoring & progression:**
- Landing score = **50 × pad multiplier + half your remaining fuel**.
- Pad multipliers by width: 44px = **×1**, 30px = **×2**, 20px = **×3**,
  14px = **×5** (narrower pays more; the multiplier is printed beside each pad).
- Every safe landing refunds **25% of a full tank** and generates a fresh
  moonscape with 2-4 new pads.
- You start with **3 landers**. The game ends when you run out of landers *or*
  fuel.

**Enemies & hazards:**
- **The terrain** — a jagged skyline; touching it anywhere but squarely on a
  pad is a crash.
- **Fuel** — burns at 7/sec at full throttle. Run dry mid-air and thrust cuts
  out completely (an "OUT OF FUEL" warning flashes), leaving you to fall.

**Tips:**
- Cancel your sideways drift high up, then descend nearly vertical. Trying to
  fix horizontal speed near the deck wastes fuel and time you don't have.
- The crank throttle holds its setting — find a hover throttle (enough to
  slow your fall) and make small adjustments rather than pumping B.
- The fuel bonus (half your tank) plus the 25% refund means an efficient
  landing on a ×1 pad can out-score a fuel-guzzling ×5 approach. Fly clean.
- Keep tilt near zero for the last few metres — even a fast, on-target descent
  fails if you're tilted past 12° at contact.
- Line up over the pad early; the narrow high-multiplier pads give almost no
  horizontal margin, so arrive already centred.

---

## Ringkeep

*Three spinning shield rings guard a cannon core — crack them before it cracks you.*

At the centre of the screen sits a fortress: a tracking core wrapped in three
counter-rotating rings of shield segments. When its gun-sight finds you
through aligned gaps, it breathes a homing fireball. Two mines ride the outer
ring, waiting to peel off and hunt. Chip the shields open, thread a shot to
the core, and do it again — faster — for every keep you bring down.

**Controls:**
- **Crank** — spins the ship 1:1
- **Left / Right** — turn the ship (d-pad fallback, 240°/sec)
- **B or Up** — thrust (momentum + drag; the screen wraps)
- **A** — fire (max 4 shots)

**How to play:**
The keep's three rings each carry twelve shield segments and spin at different
speeds and directions (the inner ring is fastest). Your shots hit the
outermost intact segment in their path — so you drill inward, one segment per
shot, until a gap lines up all the way to the exposed core.

The core continuously aims its turret at you but can only fire when it has a
clear **line of sight** — a gap aligned through every ring between it and you.
Keep moving so the gaps rarely line up, and take your shots when the rings
present an opening. Land a hit on the core and the keep detonates.

**Scoring & progression:**
- Shield segment: **10** · Mine: **100** · Core: **1,500**
- Killing the core grants an **extra ship** (up to 8) and starts the next wave:
  the rings regrow and *everything* speeds up (×1.18 per wave, capped at ×2.4).
- You start with **3 ships**. You respawn a safe 100-125px from the keep,
  clear of the mines and fireball.

**Enemies & hazards:**
- **Shield rings** — touching a live segment kills you, so don't drift into the
  keep. They rotate constantly; the gaps that let your shots through also let
  the core see you.
- **The core** — tracks you and breathes a homing fireball whenever it has
  line of sight (roughly every 1.5s of clear line). Contact is fatal.
- **Fireball** — homes at a limited turn rate and expires after ~4 seconds. A
  straight, full-throttle run outruns it; it tires and pops on its own.
- **Mines** (×2) — circulate along the outer ring, then peel off after a few
  seconds and chase you across the wrapping field (up to 130 px/s). Contact is
  fatal, but they're worth 100 and stand down the moment you die.

**Tips:**
- Hold a lane just *outside* the outer ring and pour fire straight at the
  centre; the rotating shields feed you fresh segments to destroy and you stay
  clear of contact.
- Don't try to turn-fight the fireball — point dead away and thrust in a
  straight line. Its turn rate can't keep up and it expires in seconds.
- Shoot the mines for 100 each once they peel off to chase; a chasing mine on
  a straight line is an easy, valuable target and removes a threat.
- Watch the ring gaps: the core can only fire when a gap aligns through all
  three rings to you, so constant orbital motion starves it of shots.
- After you kill a core you get ~2 seconds of invulnerability as the rings
  regrow — use it to reposition to a clean firing lane before the faster wave
  bites.

---

## Border Circuit

*A frictionless knife-fight around the track.*

You pilot a spinner-steered ship trapped in the gutter between the arena's outer wall and the central scoreboard barrier. There's no drag — you coast until something stops you — and everything caroms off the walls: you, your shots, the drones lapping the circuit. Clear each wave of drones and mine-layers while the drones lap faster and faster.

**Controls:**
- **Crank** — steer the ship 1:1 (the original cabinet used a spinner)
- **B or Up** — thrust (accelerate along your facing)
- **A** — fire (bounces at full elasticity; max 4 shots live at once)
- **D-pad left/right** — fallback steering if you'd rather not crank

**How to play:** No friction means momentum is everything — a tap of thrust sends you drifting until a wall or barrier bounces you back (you keep 78% of your speed on impact; shots keep 100%). Line up bank shots off the outer wall or the central barrier to hit drones you can't reach directly. A wave clears when every drone and mine-layer is destroyed; mines you leave behind persist into the next wave, so the track gets more cluttered the longer you stall.

**Scoring & progression:** Drones are worth 200 for the first kill of a wave, stepping up +50 per kill to a cap of 250. A mine-layer is worth 500 if you kill it before it finishes its lap, 200 after. Photon mines are 350 each. Each wave adds a drone (from 4 up to 6) and raises drone base speed (+8/wave, capped at 150); drones also accelerate the longer they stay alive. Start with 3 lives, extra ship at 40,000 (up to a cap of 8).

**Enemies & hazards:**
- **Drones** (diamonds) — circulate the four gutter corners, accelerating over time, and periodically snipe a leading shot at you (~60% of the time when they fire).
- **Mine-layers** (pods) — slow circuit-runners that drop a photon mine every ~1.7s. Each mine arms after 1 second, then blinking stops and it's lethal on contact. Max 10 mines on the track.
- **Mines** — persist across waves; a live mine kills on touch but is worth 350 shot.

**Tips:**
- Bounce shots deliberately — the barrier and outer wall turn a miss into a hit on the far side of the track.
- Kill mine-layers *early* for 500 apiece and to stop the mine clutter before it strangles the gutter.
- After dying you respawn along the bottom straight only once the spot is clear of enemies; don't burn your invuln window (2.2s) drifting into a drone.
- Drone kills escalate within a wave — chain them quickly so more land at the 250 cap.
- Coast, don't over-thrust: with no drag you can set a drift and spend your attention aiming instead of flying.

---

## Lifters

*They're not here for you. They're here for the fuel.*

Eight fuel canisters sit clustered mid-field, and waves of raiders fly in from the edges to latch on and drag them off-screen. Your ships are unlimited — dying only costs you a couple of seconds — so the only clock that matters is how much fuel is left on the ground. Kill a carrier and its canister drops right where it was.

**Controls:**
- **Crank** — spin the ship 1:1
- **B or Up** — thrust (mild drag, so you settle rather than coast forever)
- **A** — fire (max 4 shots)
- **D-pad left/right** — fallback spin

**How to play:** The arena doesn't wrap; soft edge-bounces keep the fight near the canisters. A theft alarm siren pulses whenever fuel is actively being dragged — that's your cue to prioritize. Shoot a raider that's carrying a canister and the fuel drops back onto the field (clamped inside the arena); let the raider reach an edge and that canister is gone forever. Waves flow seamlessly: the next raid scrambles ~1.4s after the last raider is cleared.

**Scoring & progression:** Grabbers ("lifters") 100, gunners 150, rammers 200. Waves grow from 3 raiders up to 5. Gunners start appearing at wave 3, rammers at wave 5. Raider fly-in speed ramps +5% per wave (capped +50%), and drag speed ticks up +2/wave. There are no extra-life mechanics — you have unlimited ships and the game ends only when all 8 canisters are stolen. The game-over screen reports waves survived.

**Enemies & hazards:**
- **Lifters** (flat, legs-down) — the core threat: seek the nearest unclaimed canister, latch on, and haul it to the nearest edge.
- **Gunners** (diamonds) — do the same grabbing work but snipe aimed shots at you (~every 1.7s) while they operate.
- **Rammers** (darts) — ignore the fuel entirely and dive at your predicted position with momentum-based lunges; when no fuel is on the ground, all raiders harass the pilot.

**Tips:**
- Prioritize carriers heading for an edge — a dropped canister is recoverable, an escaped one is not.
- A body-to-body collision with a raider wrecks both of you for zero points; shoot rammers before they close.
- When fuel runs low the surviving raiders converge on you — keep moving and pick them off rather than camping the cluster.
- Killing a carrier drops the fuel exactly where the raider was, so you can "walk" canisters back toward the center by choosing where you kill.
- Your shots inherit your velocity — a moving firing pass covers more angles than sitting still.

---

## Webguard

*Twin-stick defense, Playdate style.*

You're the spider guarding your own web — eight spokes and four rings. Invaders arrive at the rim and work inward; you scuttle freely inside the outer ring while crank-aiming a stream of autofire at them. Keep the web clear, and mind the eggs before they hatch.

**Controls:**
- **D-pad** — move the spider (free 8-way, confined inside the outer ring)
- **Crank** — aim the firing line 1:1
- **Hold A or B** — autofire (~7 shots/sec, up to 8 shots on screen)

**How to play:** Movement and aim are fully independent — d-pad for position, crank for the gun. Shots die at the web's edge, so range is limited to the web radius. Each wave is a shuffled queue of arrivals that trickle in from the rim; the wave clears (and the next begins ~2s later) only when the spawn queue, chasers, layers, bombers, and eggs are all gone. Touching *anything* hostile costs a life.

**Scoring & progression:** Chaser 150, layer 200, egg 50, bomber 300. Waves scale up counts (more chasers, then layers, then bombers) and enemy speed (+7%/wave, capped +80%); the gap between rim arrivals shrinks each wave too. Start with 3 lives, extra life at 20,000 (cap 8).

**Enemies & hazards:**
- **Chasers** (spiky mites) — crawl in along a spoke, then home straight at you. When you're dead they back off toward the rim to clear your respawn.
- **Layers** (finned diamonds) — wander intersection to intersection along the strands, depositing a pulsing egg at nodes (every ~2.4s, max 10 eggs).
- **Eggs** — worth 50 shot now, or they pulse faster and hatch into a fresh chaser after 6 seconds.
- **Bombers** (hexes) — drift across the web and burst into 4 radial fragments, on your shot *or* when their fuse runs out. Fragments fly to the rim and are lethal on contact.

**Tips:**
- Clear eggs before they hatch — 50 points and one fewer chaser beats letting the web fill with mites.
- Killing a bomber still sprays four fragments, so shoot it when you're not standing in the blast lanes.
- The mid rings are the safe zone: enough room to kite a homing chaser in a circle while your shots reach the rim.
- Layers are the root cause of chaser swarms — prioritize them to cut off the egg supply.
- Aim leads with the crank while you dodge with the d-pad; you never have to stop moving to keep firing.

---

## Treadline

*First-person tank duels on an endless plain.*

You command a wireframe tank on an infinite plain of pyramids and boxes, hunting one hostile at a time through a first-person turret view. The hull and turret move independently — treads point one way, gun points another — and the radar and offset needle keep you oriented. Every third contact is a skimmer that ignores gunnery and just rams.

**Controls:**
- **D-pad up/down** — drive both treads forward/reverse
- **D-pad left/right** — pivot the hull (in place, or a gentle arc while driving)
- **Crank** — slew the turret and your view independently of the hull
- **A or B** — fire (one shell in flight at a time)

**How to play:** The camera rides your turret, so the crank aims where you look. The radar scope (top center) shows the hostile's blip *relative to your turret heading* — straight up is where your gun points. The small needle below it shows how far your hull has drifted from your gun line, so you can reorient the treads without losing your aim. Pyramids and boxes block shells (yours and theirs) and line of sight; obstacles recycle ahead of you as you roam. Getting hit cracks your windshield and destroys the tank; you respawn with 2s of invulnerability and the hostile is shoved back out to ~50m.

**Scoring & progression:** Tank 1,000, skimmer 2,500. Enemy aim sharpens with every kill you make — their lead error starts at 14° and shrinks 2.2° per kill down to a 1.5° floor — so the better you do, the deadlier they get. Start with 3 lives (cap 6), extra life at 15,000. Every third spawn (spawn #3, #6, #9…) is a skimmer instead of a tank.

**Enemies & hazards:**
- **Hostile tanks** — stalk toward you, circle at ~25m, then stop to aim and fire a lead shot; they won't shoot through obstacles and hold fire while a shell is already in flight. They steer around obstacles they'd otherwise drive into.
- **Skimmers** (floating darts) — bob up and down and weave erratically inward at high speed to ram you; a ram costs you a life but scores you nothing, and killing one on the ram scores nothing either — you must shell it first.
- **Obstacles** (pyramids, boxes) — block movement and shells for both sides; use them as cover.

**Tips:**
- Break line of sight behind a pyramid when a tank enters its aim phase — it can't fire through cover.
- Slew the turret to track the blip while pivoting the hull separately; the offset needle tells you when to straighten the treads.
- Skimmers can't be out-gunned by waiting — lead their weave and shell them before they close, because contact is a guaranteed life lost.
- Your own shells are blocked by obstacles too; don't fire into a pyramid between you and the target.
- Keep moving — a tank leads your velocity, so a straight-line charge walks you into its shell.
- The enemy's aim only gets tighter as your score climbs, so use terrain more aggressively in later kills rather than trading shots in the open.

---

## Night Vector

*Headlights, wireframes, and a clock that will not wait — drive the ghost road before it swallows you.*

There is nothing ahead but the throw of your headlights: thirty segments of wireframe tarmac unspooling out of the dark, winding and rising, dotted with trees, signs, and traffic. Reach each kilometre checkpoint before the clock runs out and it grants you a few more seconds — but a little less each time. Run wide into the dirt and the world scrubs your speed away; clip a car and you lose one of your three.

**Controls:**
- **Crank** — the steering wheel, 1:1, clamped at the lock stops (±110°)
- **A or Up** — accelerate
- **B or Down** — brake
- **Left / Right** — turn the wheel (d-pad fallback, 170°/sec)

**How to play:**
The car is the camera. The wheel sets a yaw rate that scales with speed, so the faster you go the twitchier the steering — ease the wheel through curves rather than sawing at it. Gravity of a different sort rules the shoulder: leave the tarmac and off-road drag (1.7/sec) violently bleeds your speed, and the roadside trees and signs are a straight crash. Traffic runs both ways — same-direction cars to overtake and oncoming lights to thread.

The clock is the whole game. Every 1,000 m checkpoint you cross adds **+18 seconds** (plus a little early-level grace that decays one second per checkpoint). Miss the clock and it's over; so is crashing your last car.

**Scoring & progression:**
- Distance: **10** points per 100 m travelled.
- Overtake a same-direction car: **200**.
- Checkpoints tighten as you climb: the grace bonus shrinks to a hard +18 by around checkpoint 8, and the road curves and rolls harder.
- You start with **3 cars**. Top speed is 50 m/s (**180 kph**) — you'll need most of it.

**Enemies & hazards:**
- **Same-direction traffic** — rolls at 13-23 m/s; overtake cleanly for 200, rear-end it and you crash.
- **Oncoming traffic** — closes at 15-26 m/s in the other lane; a head-on is fatal. Don't swing wide into its lane to pass.
- **Roadside trees & signs** — grow on ~16% of segments just off the tarmac; touching one crashes you.
- **The shoulder** — not lethal by itself, but the dirt scrubs your speed so fast that a curve you entered too wide can cost you the checkpoint.

**Tips:**
- Steer with small, early inputs. Yaw rate rises with speed, so a flick that's fine at 80 kph oversteers you off the road at 170.
- Lift off the throttle *before* a curve, not in it — braking mid-corner on the shoulder is how you lose a car and the clock at once.
- Overtakes are free points and cost no time; when a same-direction car sits in your lane and no lights are coming, swing to the other lane and take the 200.
- Bank early. The first checkpoints hand out the most grace seconds, so drive them hard to build a time cushion for the tighter later legs.
- The dirt is a speed tax you can't afford near a checkpoint — when in doubt, sacrifice the racing line to keep all four wheels on the wireframe.

---

## Trenchfire

*Wireframe rail assault on the fortress canyon — blast the fighters, flatten the towers, thread the trench, and put one shot through the port.*

The fortress waits at the end of the canyon, and there is only one way in: fight through the fighters and gun towers, dive into the trench, and thread your ship past its ribs and braces to the tiny port window at the far wall. One clean shot through the port and the whole fortress comes down. Fly it faster for more points — but the throttle that pays the multiplier is the same throttle that makes the trench a blur.

**Controls:**
- **D-pad** — move the crosshair; the ship eases toward it (it *is* the camera)
- **Crank** — throttle lever, accumulated 0-100% (crank forward to speed up)
- **A or B** — fire

**How to play:**
The crank throttle is a risk dial. Higher speed multiplies your score (up to **×3** at full throttle) but rushes every dodge and shortens your reaction time in the trench. Each level runs three phases in order: **APPROACH** (fighters swoop in from the deep), **TOWERS** (gun towers on the ground grid), then the **TRENCH** — a canyon lined with wall hardpoints and overhead braces, ending at the fortress port.

The port is small and only reachable inside about 330 units, so in the trench you center up, wait for the window to come into range, and snipe it. Land it and the fortress bursts: **5,000 × your throttle multiplier**, plus a bonus shield. Then the next level starts, longer and faster.

**Scoring & progression:** All points scale by your throttle multiplier (×1 to ×3):
- Fighter **200** · Gun tower **250** · Trench hardpoint **150** · Fireball shot down **50**
- Fortress port hit: **5,000** (before the multiplier) and **+1 shield**.
- Each level adds fighters (+2 quota), a longer trench (+150), tighter tower/hardpoint spacing, +7% ship speed, and one more live fireball every two levels.

**Enemies & hazards:**
- **Fighters** — swoop in from the distance during the approach and fire down at you.
- **Gun towers** — rooted on the ground grid, firing up at you as you pass over.
- **Trench hardpoints** — gun emplacements on the canyon walls during the run.
- **Fireballs** — the enemy fire itself; these are **shootable** for 50 each, and your speed adds to their closing rate. Cap of 7 live (rising with level).
- **The trench walls & braces** — scraping a wall or clipping an overhead brace costs a shield (with a short grace between scrapes).

**Tips:**
- Fireballs come first for the autopilot for a reason — shoot the ones you can, since a destroyed fireball is 50 points *and* one fewer thing that can hit you.
- Throttle is a dial, not a switch. Push it up in the open approach/tower phases where dodging is easy, and back it off entering the trench so you can actually thread the ribs.
- The port outranges everything — don't waste the trench run chasing hardpoints when you could be centering the crosshair for the one shot that ends the level.
- Every fortress kill refunds a shield, so an aggressive, clean run is self-sustaining; a sloppy one bleeds shields faster than it earns them.
- Shields are your lives (start 6, cap 9) — bank them by not scraping walls, and the +1 per fortress keeps you alive deep into the escalating levels.

---

## Gravity Wells

*Gravity-thrust raids on four wells around a killing star — beam the fuel, blast the bunkers, and outrun the reactor.*

The game plays at two scales. In the **system view** a central star pulls on you constantly and touching it is instant death; fly into a planet to descend into its **well**, a side-view mission under gravity. Down there, thrust burns fuel and the only refills are the fuel tanks you tractor-beam up, so every burn is a debt. Silence the bunkers, and if a well hides a reactor, shoot it and get out before it blows. Clear all four wells and the next system pulls harder still.

**Controls:**
- **Crank** — rotate the ship 1:1 (d-pad left/right fallback, 220°/sec)
- **B or Up** — thrust (burns fuel — 7/sec — everywhere)
- **A** — fire
- **Down** — hold the tractor beam out below the ship

**How to play:**
In the system view the star's gravity (26 px/s² and rising per system) never lets up — carry momentum, don't fight it head-on, and dive into a planet to start its mission. Each well is a wide (~2 screens) side-view arena with downward gravity (30 px/s², **reversed on the odd planet** so "down" is up). Fuel is life: it drains with every thrust and refills only from tanks you hover over and **beam up** (+30 each). Run dry and you can't thrust — a slow fall into the terrain.

Silence the four bunkers, and if the well has a **reactor**, shoot it to start an **8-second** countdown — fly out of the well before it detonates for a heavy escape bonus. Clearing a well banks 1,000; clear all four and the system is done.

**Scoring & progression:**
- Bunker **250** · Fuel tank beamed **50** · Reactor hit **500** · Well cleared **1,000**
- Reactor escape: **2,500** (+500 per system beyond the first).
- Each new system raises star gravity (+7) and planet gravity (+8), so the same manoeuvres cost more fuel and control.
- You start with **3 ships**; an extra ship at **10,000** points.

**Enemies & hazards:**
- **The star** (system view) — a constant inward pull; contact anywhere in its kill radius is final.
- **Bunkers** — ground emplacements that track and fire at you when you're within ~250 units, on a 1.6-2.9s cadence. Worth 250 each; silence all four to clear the well.
- **The reactor** — optional high-value target; shoot it to arm an 8-second self-destruct, then escape the well for the bonus. Stay too long and you go up with it.
- **Enemy shots** — bunker fire (up to 8 live); dodge or outrun it.
- **Terrain & gravity** — the well floor and the ever-present pull; a mistimed hover or an empty tank ends in a crash.

**Tips:**
- Fly the star, don't fight it. In the system view, set a curving course that uses the pull to slingshot toward your target planet instead of burning fuel straight into it.
- Beam fuel *first* whenever a tank is under you — the mission autopilot bails for fuel below 30% for good reason; a dry tank is a dead ship.
- Learn each well's gravity sign before you commit thrust — on the reversed planet, "down" is up, and habit will fly you straight into the ceiling.
- Reactors are all-or-nothing: only shoot one when you have the fuel and a clear exit for the 8-second sprint. The escape bonus (2,500+) dwarfs the bunkers, but a botched escape costs a ship.
- Hover, don't hang. Bunkers only fire inside ~250 units, so approach from range, pop them, and drift back out rather than parking in their firing arc.

---

## Duelstar

*Two ships, one hungry sun — a gravity duel to five rounds, and the star settles every argument.*

You and the Rival circle a sun that pulls on ships and shots alike. Three hits ends a round, and each hit visibly knocks a piece off the loser — a ship down to its last hit flies worse, turning slower and thrusting weaker. Best it to five rounds to take the match. The Rival cycles personalities between rounds and sharpens every time you win, so the duel gets meaner as you climb.

**Controls:**
- **Crank** — turn the ship 1:1 (d-pad left/right fallback, 220°/sec)
- **B or Up** — thrust (momentum + drag; the sun's gravity is always pulling)
- **A** — fire (max 3 shots, and gravity bends them mid-flight)
- **Down** — hyperspace (escape a sun capture; 1-in-6 chance it kills you)

**How to play:**
Everything orbits the sun. Its gravity (accel = 230000 / dist², capped near the core) curves your ship and your shots, so leading the Rival means aiming where gravity will carry the bullet, not where the ship is now. Get too deep into the well and you'll be captured and dragged into the core — hyperspace is your bail-out, at the usual 1-in-6 risk.

Three hits kills a ship and ends the round. Each hit you take chips your ship; on your **last hit** your turn and thrust are throttled (to 60% and 70%), so a wounded ship is a slower, clumsier ship. Rounds go to five wins for the match. Sun contact — for either ship — is instant death and ends the round then and there.

**Scoring & progression:**
- Each hit landed: **500** · Each round won: **2,000** · Winning the match: **10,000**
- The Rival's skill starts at 0.45 and climbs +0.14 per round you win — faster turning and better-led shots as the match goes on.

**Enemies & hazards:**
- **The Rival** — rotates three personalities each round: **the Orbiter** rides the sun's gravity and fires on close passes; **the Sniper** holds the range open and leads its shots well; **the Brawler** charges in for point-blank fire and barely respects the sun (it panics much later than the others near the core). All sharpen as you win rounds.
- **The sun** — a constant inward pull that bends ships and bullets; its kill radius is death on contact for both duellists. It also drags in anyone who lingers too deep in the well.

**Tips:**
- Curve your shots. The sun bends bullets, so against a distant Rival, fire "uphill" of it and let gravity walk the shot onto the target.
- Use the well as a weapon. The Brawler ignores the sun the longest — bait it into a low pass and let the star finish what your guns started.
- Watch your own depth: if you feel the pull tightening, thrust prograde (sideways along your orbit) to climb out rather than fighting straight against gravity, and keep hyperspace in reserve for a true capture.
- A wounded ship handles badly, so when you're down to your last hit, play for range and let your shots do the work instead of dogfighting with crippled controls.
- Read the personality each round: hold the range against the Sniper, crowd and out-turn the Orbiter, and don't try to out-charge the Brawler — sidestep it and punish the overshoot.

---

## Elite

*Wireframe space trading and combat from the cockpit — fly, fight, trade, and work your way across eight real galaxies.*

You are Commander Jameson, launching from Lave in a Cobra Mk III with 100 credits and a dream of the Elite combat rating. The cockpit is fixed and the whole universe wheels around you as you roll and pitch — exactly how the 1984 original flew. Trade cargo between systems, gun down (or become) a pirate, dodge the law, and jump star to star across a galaxy generated from Elite's own seeds.

**Controls:**
- **Crank** — roll (d-pad left/right rolls too)
- **D-pad up/down** — pitch (up climbs the nose)
- **A** — fire the front laser
- **B (modifier) + up/down** — throttle up / down
- **B + A** — launch a missile at the locked target
- **B + left** — E.C.M. (destroys incoming missiles)
- **B + right** — energy bomb (single use)
- **Docked**, the d-pad moves the cursor and A selects; on the market Right buys / Left sells; B backs out of a screen

**How to play:** Combat is a rolling-and-pitching duel: roll a target onto the vertical centre line, pitch it into the reticle, and hold A — a continuous laser does the damage. Watch the **LT** (laser temperature) gauge; a maxed laser cuts out until it cools. The 3D scanner below the view plots every contact (left/right and fore/aft on the ellipse, above/below on the stalk), and the round compass points to the station.

To dock, fly slow (at or below the docking speed) and centred into the rotating Coriolis slot, rolling until your ship lines up with it — hit it wrong and you scatter across the hull. A **Docking Computer** (once you can afford one) flies you straight in. Docking restores shields/energy, banks a bonus, and saves your commander.

Docked, the station screens are the other half of the game. At the **Market**, buy low and sell high across 17 commodities whose prices swing with each system's economy. **Equip Ship** sells fuel, missiles, a bigger cargo bay, E.C.M., fuel scoops, an energy bomb, a docking computer, and a galactic hyperdrive. The **Galactic Chart** lists reachable systems (nearest first) with distance and tech level — pick one and jump. Fuel limits every jump; refuel at a station or skim a sun with scoops fitted.

**Scoring & progression:** Kills score their ship's bounty: Sidewinder 50, Viper 60, Cobra 75, Mamba 100, Python 200, Thargoid 500; asteroids 5, cargo canisters 10. Docking awards a 150 bonus, and clearing every hostile in a system flags "DOCK FOR BONUS." Your **combat rating** climbs by cumulative kills — Harmless → Mostly Harmless → Poor → Average → Above Average → Competent → Dangerous → Deadly → Elite. There are no extra lives: your condition (shields, then energy) is your life bar, and it regenerates over time. Reach 12 kills and the Navy recruits you to hunt the prototype **Constrictor** (+5000 Cr when destroyed). Your commander — credits, cargo, kit, galaxy, legal record — is saved at every dock, so a death drops you back at your last station.

**Enemies & hazards:**
- **Pirates** (Sidewinder, Krait, Mamba, Cobra, Asp, Fer-de-Lance…) — turn toward you, fire when lined up and in range, keep a stand-off orbit, and some launch homing missiles. Which pirates appear depends on the system's government — anarchies swarm with the deadliest ships, corporate states send only the odd Sidewinder.
- **Traders** — neutral; shoot one and you become **Wanted** and the police turn hostile.
- **Police (Vipers)** — appear in strong-law systems or when you're wanted; deadly if you've earned their attention.
- **Thargoids** — the rare **witchspace** ambush drops you among 2–4 of them.
- **Asteroids** — tumbling rock, minor bounty; **cargo canisters** drift free after a kill and are scooped for points on contact.
- **The sun** — flying into it heats the cabin (CT gauge); max heat cooks your hull, but fuel scoops let you skim it to refuel.
- **The station** — ram it at speed or off-angle and you die.

**Tips:**
- Roll first to put a target on the vertical, then pitch to the centre — trying to do both at once makes the axes fight.
- Feather the trigger. Continuous fire spikes the LT gauge; let it cool between bursts so the laser never cuts out mid-fight.
- Government dictates danger. Corporate States and Democracies are calm places to trade; Anarchies and Feudal states are where the bounties (and the risk) pile up.
- Classic trade route: buy Computers and Luxuries in rich industrial systems and sell them into poor agricultural ones; run Furs and Liquor the other way. Prices swing with the economy, so read the chart's tech level as a proxy for what a system wants.
- Buy the **Docking Computer** early if you can — the manual dock is unforgiving, and a botched approach at the station is a common death.
- E.C.M. swats incoming missiles; save the single-use **energy bomb** for a witchspace Thargoid swarm.
- Every dock is a checkpoint. When your shields are low and a system is clear, dock to save, heal, and bank the bonus before pushing on.

---

## Geometry Wars

*Twin-stick arena shooting on a living, spring-loaded vector grid.*

The floor is a lattice under tension, and it fills with geometric enemies that home, juke, and swarm. Fly with the d-pad, aim independently with the crank, and rake the arena clean — while the whole grid dents and ripples under your wake, your shots, every explosion, and the pull of black holes.

**Controls:**
- **D-pad** — fly the ship (full momentum, eight directions)
- **Crank** — absolute aim dial: point it where the guns should fire (aim and movement are independent)
- **Autofire** is always on
- **B (or A)** — drop a smart bomb

**How to play:** Because guns fire wherever the crank points, you can circle a swarm while raking it from the side. Your gun **auto-switches** every 10,000 points earned between three patterns: a twin spread, a rapid alternating gun (wide pair then fast single), and a five-way fan. A smart bomb detonates a growing shock ring that clears everything it touches and blows the grid wide open — you get five, so save them for when you're pinned.

**Scoring & progression:** Points scale by your **multiplier**, which climbs +1 for every 25 kills in a life (up to ×6) and resets to ×1 when you die. Base values: Wanderer 25, Grunt/Tiny/Mayfly/Snake/Black hole 50, Spinner/Weaver/Repulsor 100. An **extra ship** every 75,000 points and an **extra bomb** every 100,000. Difficulty ramps continuously: a rising spawn index unlocks tougher enemy types and raises the target population, while a slow "aggression" creep speeds every chaser up over time. Alongside the steady trickle, **SWARM** waves pour one type in from a corner and **RUSH** waves ring you.

**Enemies & hazards:**
- **Grunts** — diamonds that home straight in.
- **Wanderers** — drifters that ignore you and bounce off the walls.
- **Spinners** — stars that charge you and split into two **tiny** spinners when killed.
- **Weavers** — hexagons that actively juke away from your nearby shots.
- **Mayflies** — flapping swarmers that dart and drift.
- **Snakes** — a shootable head dragging a long, deadly tail; only the head takes damage, but every body segment kills you.
- **Black holes** — take 12 hits; drag the grid into a deep well, pull in the ship and every nearby enemy, and bend your shots off course. Destroyed, they burst into six **protons** that scatter and home.
- **Repulsors** — shielded chargers (6 hits) that swat away any shot hitting their front arc — you must flank them.

**Tips:**
- Keep moving in wide circles. Standing still lets homing grunts and spinners converge from all sides.
- Kill count, not points, drives the multiplier — clear cheap enemies steadily to reach ×6 and keep it there; dying dumps you back to ×1 and resets your weapon to the twin spread.
- Black holes are both threat and tool: their pull yanks other enemies together, so a well-placed shot or bomb near one can clear a cluster. But don't get sucked into contact.
- Flank repulsors — never trade shots head-on. Their front shield just bats your rounds back out.
- Snakes: aim only for the head and give the whipping tail a wide berth.
- Don't hoard bombs to the end. Use one the moment a RUSH wave rings you or a swarm boxes you into a corner — a death costs far more than a bomb.

---

## Vectorblade

*A vector swarm shooter — Galaga by way of Warblade, with a shop between every wave.*

Your fighter holds the bottom of the field while waves stream in along curved paths, lock into a breathing formation overhead, and peel off one at a time to dive and fire. Catch the power-up drops, spend your cash in the shop, and climb the naval ranks from Ensign to Great Defender.

**Controls:**
- **Crank** — slide the fighter along the bottom (the cabinet spinner)
- **D-pad left/right** — fallback movement
- **A** — fire (or hold; autofire once you find or buy it)
- **B** — smart bomb (when you own one)
- **In the shop:** Up/Down or crank to choose, A to buy, B to fly on

**How to play:** Dodge the divers, shoot straight up into the formation, and clear the wave. Your gun starts as a single barrel; the **weapon** upgrade widens it (1–2 barrels fire side by side, wider volleys fan outward, up to 6 barrels). A **smart bomb** wipes the formation instantly (and dents a boss). Between every wave the **shop** opens automatically for a spell — a death costs you a weapon stage, so the shop is how you rebuild.

**Scoring & progression:** Kills score by type: Drone 100, Wedge 150, Tie 250, Bird 400; a boss is worth 25,000. A **Multiply (X)** pickup doubles all scoring for 8 seconds. **Extra life** every 20,000 points (max 9 lives). New enemy kinds join the pool as levels climb — wedges at level 2, ties at 3, birds at 4 — and a **boss** replaces the wave every fifth level, gaining +20 HP each appearance. Your final score earns a naval rank: Ensign, Lieutenant, Commander, Captain, Admiral, up through bronze/silver stars to Great Defender at 1,040,000.

**Enemies & hazards:**
- **Drones / Wedges / Ties / Birds** — fill the formation grid; tougher kinds take more hits (drone/wedge 1, tie 2, bird 3). They fly in on curved bezier paths, breathe side to side in formation, then peel off to **dive**, homing toward your x-position with a sine wiggle and firing aimed shots. A diver that reaches the bottom loops around and re-forms.
- **Boss** (every 5th level) — patrols side to side, fires an aimed shot plus a downward three-way fan, and shows an HP bar. Bombs only chip it; lasers do the work.
- **Enemy bullets** — kill you on contact unless you have a shield or armour up.

**Power-up drops** (a killed enemy has a ~16% chance to drop one; catch it with the fighter):
- **C** — cash (banked for the shop) · **P** — wider gun · **R** — faster shots · **X** — double score (timed)
- **S** — shield (timed invulnerability) · **A** — armour plate (absorbs one hit) · **F** — autofire · **1** — extra life

**Shop items:** Speed +, Bullet + (wider gun), Rate + (faster fire), Shield, Autofire, Armor, Bomb, Extra Life — priced 50 up to 1,500.

**Tips:**
- Stay mobile under the formation and pick divers off as they commit — a lone diver is far easier than a formed grid, and it's worth double the risk of camping.
- Grab every **C** (cash) drop you safely can; the shop is what keeps your firepower ahead of the difficulty curve.
- A death drops your weapon a stage and cancels autofire, so protect your lives — buy **Armor** and **Shield** to survive the boss levels.
- **Rate +** and **Bullet +** stack: a wide, fast gun shreds formations before they can all dive. Prioritise them early.
- Save a smart bomb for the moment a wave finishes forming, or to instantly clear divers when you're boxed in.
- Autofire frees you to focus entirely on dodging with the crank — a high-value early buy (350) if no drop gives it to you.

---

## Gyre

*Vector orbit gunnery — ride the rim of a tube while squadrons swoop out of the deep, warp planet to planet.*

An original take on the 1983 arcade tube-shooter (the one that flew you from Neptune to Earth to a Bach fugue). Your ship orbits the rim of the screen; drones burst out of the center along looping spline paths, settle into a rotating hub formation, and take turns diving at your orbit. Clear the field to warp; every third warp reaches a planet and a scoring **chance stage**.

**Controls:**
- **Crank** — fly the ship around the rim (one full revolution = one full orbit)
- **D-pad left/right** — fly without the crank
- **A or B** — fire (hold for autofire)

**How to play:** The playfield is polar — you slide around a circle, nose pointed inward, and your shots converge on the center of the tube. Depth is faked by scaling: distant enemies near the center are small, and swell as they charge the rim. Keep the crank moving to line targets up, and shoot squads before they reach the hub — but everything that reaches the rim (divers, bullets, meteors, the laser beam) can kill you. You can hold at most three shot volleys in flight, so pace your fire.

**Scoring & progression:** Drones score 50 in formation or on entry, 100 as mid-run **divers**. Clearing the whole field warps you onward; stages get faster and meaner (enemy speed and dive frequency scale with stage number). Every third warp is a **planet** — Neptune, Uranus, Saturn, Jupiter, Mars, Earth, then around again — reached through a **chance stage**: four squads of eight fly their patterns and never shoot back, worth 100 a hit, **1500 for a perfect squad** (all eight), and **5000 for a perfect stage** (all four squads perfect). **Extra ship** every 60,000 points (max 6). Dawdle too long once a stage's spawns are exhausted and the formation gives up and flies off — no points for a stalemate.

**Enemies & hazards:**
- **Drones** — swoop in along one of four entry splines (weave, loop, graze, cross), settle into the rotating hub, then dive in chains (a leader plus wingmates down the same lane), firing aimed shots mid-run. After three dive runs they flee the stage. Divers score double.
- **Satellites** — a trio slips in mid-stage and drifts along the rim toward your side, taking potshots. Destroy all three (500 / 1000 / 1500 for the chain) to fit **twin cannons**, kept until you lose a ship.
- **Meteors** (stage 2+) — indestructible rocks tumbling outward; your shots pass straight through. Move out of their radial.
- **Laser pairs** (stage 4+) — two linked ships straddle the rim and drag a sweeping beam between them that hunts your angle. The beam kills anyone parked on its line; shoot **either** ship to cut it.

**Tips:**
- The crank is your dodge and your aim at once — keep it moving. Standing still on the rim is how divers, bullets, and the laser beam catch you.
- Prioritise the **satellite trio**: three quick kills earn twin cannons, roughly doubling your clear speed for the rest of the life. Don't let them drift off (they linger only ~9 seconds).
- Against the laser pair, don't chase the beam — shoot one of the two ships to kill the whole beam instantly. Kill the lead ship and the sweep is gone.
- Meteors can't be shot, so treat them as pure spacing: read the radial they're falling on and orbit clear of it.
- In chance stages nothing shoots back — go for the **perfect**. Wipe all eight of each squad for 1500, and all four squads for the 5000 stage bonus, before worrying about your own position.
- Don't stall. Once a stage's squads are spent, the fleet flees after a timeout — keep clearing so you bank the kills instead of watching them escape.
