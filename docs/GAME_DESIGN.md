# Game Design

## Core fantasy
You're a spy in a crowded building. Everyone else is a spy too. Look like you belong, take what you came for,
and get out before anyone figures out which civilian is you.

## Round flow

| Phase | Length | What happens |
|---|---|---|
| Lobby | until ready + 20s countdown | Pick a class, ready up. Starts when `MinPlayers` are ready. |
| Insertion | 10s | Agents drop in at `InsertionPoint`s, already disguised as random civilians. |
| Infiltration | 8 min | Hack terminals for intel, collect keycards, crack safes, climb clearance. |
| Extraction | 3 min | Someone opened the vault. They carry the package and get pinged to everyone every 5s. |
| PostRound | 10s | Winner announced, everyone respawns in the lobby. |

**Win:** extract the package at an `ExtractionPoint`, or be the last agent alive.
**Death:** you're out until next round (respawn in lobby). A dead carrier drops the package where they fell.

All timings are in `src/shared/Config/GameConfig.luau`.

## Lobby: in-server "Robloxified" lobby (recommended for launch)

Each Roblox server runs one match at a time. Players wait in a **physical lobby room** in the same place
(spawn there, walk around, see each other's agents) and use a **menu panel** to choose a class and ready up.

Why this over a separate matchmaking hub:
- **It's how Roblox players expect round games to work** (MM2, Flee the Facility). Friends join the same server
  by default, and the lobby is free social space for later cosmetics/emotes.
- **No TeleportService / MemoryStore matchmaking code to build or debug.** A separate lobby place plus
  reserved servers is a real project of its own. It's a post-launch upgrade (see Roadmap), not a launch blocker.
- One place file means one Studio session for testing the whole loop.

The previous PDF recommended a standard matchmaking lobby. That's still the right long-term direction once
you have enough players to need cross-server queues. For launch, an in-server lobby gets you playing weeks sooner.

## Classes (4 at launch)

Four is right for launch: one per playstyle, each easy to read at a glance, and every one gets proper tuning.
Add class 5 and 6 after you see real match data.

| Class | Role | HP | Weapon | Gadget | Passive |
|---|---|---|---|---|---|
| Vanguard | Frontline | 150 | Shotgun | Holoshield: wall that blocks shots for 6s | Armor regen out of combat |
| Tracker | Intel | 100 | Rifle | Scanner: pings nearby terminals, safes, keycards | Sees who last hacked a terminal for 10s |
| Scoundrel | Evasion | 90 | Pistol | Decoy: fake copy of your disguise walks away | Suspicion builds 25% slower |
| Technocrat | Control | 100 | SMG | Camera: marks agents who break cover nearby | Opens doors one tier above disguise |

Defined in `src/shared/Config/Classes.luau`. The lobby UI reads that table, so new classes show up automatically.

## Disguise and suspicion

- Hold the prompt on any crowd NPC (1.5s) to copy their look **and their clearance tier**.
- Disguised walk speed (12) **exactly matches NPC walk speed**, so walking normally is invisible in the crowd.
- Suspicion (0–100) builds on the server from things it can see:
  - Sprinting (moving faster than 14 studs/s): +35/s
  - Jumping or falling: +50/s
  - Standing in a `ClearanceZone` above your disguise tier: +25/s
  - Calm: −15/s
- At 100, or when you use any weapon or gadget, **cover breaks**: your real avatar shows and you can't
  re-disguise for 12s.
- The server detects all of this itself. A client can't skip suspicion by not reporting it.

## Clearance ladder: keycards, doors, safes, upgrade cards

This is our version of Deceive Inc.'s locked areas and in-round loot. Everything resets every round.

| Tier | Name | Where it is |
|---|---|---|
| 0 | Civilian | Public areas. Everyone starts here. |
| 1 | Staff | Back offices, kitchens |
| 2 | Guard | Security rooms |
| 3 | Technician | Server rooms, maintenance |
| 4 | VIP | Penthouse, vault level |

**The loop:**
1. **Keycards** spawn at `KeycardSpawn` points at round start. Put the tier N+1 keycard *inside* tier N rooms,
   so each keycard is the reward for getting one level deeper.
2. **Doors** (`ClearanceDoor`) open if your disguise tier **or** any keycard you hold is ≥ the door's tier.
   A keycard gets you through a door, but if your disguise is too low you still gain suspicion inside.
   That's the tension: a keycard alone isn't a free pass.
3. **Safes** (`Safe`) need the keycard of **exactly** their tier. Cracking takes 2s + tier.
   One agent per safe per round: first come, first served.
4. Each safe gives a random **Upgrade card** for the rest of the round. Higher-tier safes roll from better pools:

| Upgrade | Effect | Min safe tier |
|---|---|---|
| Quick Hands | Hack terminals 30% faster | 1 |
| Padding | +20 max HP | 1 |
| Light Step | Sprinting builds suspicion 30% slower | 1 |
| Spare Gadget | +1 gadget charge | 2 |
| Cool Head | Cover-break cooldown halved | 2 |
| Ghost | Trespassing builds suspicion 50% slower | 3 |
| Overclock | Gadget cooldowns 40% shorter | 3 |
| Master Key | Count as one tier higher | 4 |

Defined in `src/shared/Config/Upgrades.luau` and `Clearance.luau`.

## Intel, vault, extraction

- Each `IntelTerminal` can be hacked **once per round** (4s hold) for 1 intel. First agent wins it.
- With 3 intel you can open the `Vault` (5s hold). You instantly become the **carrier**: your cover breaks,
  you can't disguise, and everyone sees your position every 5 seconds.
- Reach any `ExtractionPoint` and hold the prompt (2s) to win.

## Map layout guidance (Dev 3)

- One building, three or four floors or wings, each floor about one tier deeper.
- At least 8 `IntelTerminal`s for 8 players. Spread them across tiers so intel pulls agents deeper.
- **Two or three routes into every high-tier room:** a guarded door (keycard/disguise), a vent or window
  (no check, but you trespass), and a Technocrat-only shortcut. Every playstyle should have a way in.
- **Crowds of 3+ NPCs** near every objective. Blending fails if you're the only person in the room.
- `ExtractionPoint`s far from the vault and from each other, so extraction becomes a chase.
