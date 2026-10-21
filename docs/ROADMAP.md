# Roadmap: 12 weeks to a playable alpha

Alpha = one map, 4 classes, full loop, 8 players, stable. Assumes ~10–15 hrs/week each.
Weeks 1–2 run faster because the skeleton in this repo already exists.

| Weeks | Dev 1: Server | Dev 2: Client | Dev 3: World | Checkpoint |
|---|---|---|---|---|
| 1–2 | Read and own the skeleton. Fix bugs found in first playtests. | Tools set up. Sprint/HUD working. Start UI mockups. | Greybox test map (see CONTRACTS). First 10 NPC looks. | **Full round played solo and 2-player** |
| 3–4 | Harden validation. Tracker passive. Technocrat door hack. | Real lobby UI with class cards. Suspicion meter with feedback. | Greybox full-size map, all tiers, multiple routes. | **3-person playtest on real layout** |
| 5–6 | `Fire` remote + server hitscan (pair with Dev 2). Health/armor. | Weapons: client input, recoil, hit markers. | NPC idle animations. Guards patrol tiers. | **Combat feels okay** |
| 7–8 | Gadget server logic (shield HP, decoy NPC, camera marks). | Four gadgets: placement, UI, cooldowns. | Art pass, floor 1. Lighting. | **All 4 classes playable** |
| 9–10 | Upgrade effects complete. Anti-exploit pass. | Upgrade/keycard inventory UI. Extraction visuals. | Art pass, remaining floors. Lobby room. Mobile perf check. | **Feature complete** |
| 11–12 | Bug fixing, balance numbers in Config. | Polish: sounds, juice, settings, mobile controls. | Polish, perf, final NPC count. | **Alpha: public test with friends** |

## After alpha
- DataStore: XP, class unlocks, cosmetics
- Separate lobby place + MemoryStoreService matchmaking + reserved servers
- Classes 5 and 6, a second map
- NPCs that react (flee, alert guards) when an agent blows cover

## Honest risks
- **Combat feel** is the hardest thing to get right on Roblox (latency). Start it by week 5 and don't let it slip.
- **NPC count vs. performance.** 30+ pathfinding NPCs is fine on PC but test on a phone early.
- **Scope creep.** New classes and gadgets are fun to design. Don't add any until the alpha checkpoint.
