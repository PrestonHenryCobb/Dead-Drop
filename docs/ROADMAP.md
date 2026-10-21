# Roadmap (solo)

A three-person team needs about 12 weeks for the alpha. Solo that's roughly **6–8 months at 10–15 hrs/week**,
or about half that full-time. Claude Code speeds up the scripting a lot. It doesn't speed up building the map,
playtesting, or tuning how things feel, and that's where solo time goes.

So the plan is **sequential milestones, each ending in something playable**, with the scope cut hard for the
first public test.

## Milestone 1: The loop works (weeks 1–3)
- Build the greybox test map from `docs/CONTRACTS.md`.
- Play full rounds solo (`MinPlayers = 1`) and with 2 local test clients. Fix whatever breaks.
- Tune suspicion numbers until blending in feels fair.
- **Done when:** a 2-player test round goes lobby → extraction with no errors in Output.

## Milestone 2: It's a fight (weeks 4–8)
- `Fire` remote + server hitscan in `CombatService`; client input, hit markers, health.
- One weapon per class (reuse one weapon script with different stats).
- Real lobby UI with class cards; better suspicion meter.
- **Done when:** a friend can join and you'd both play a second round.

## Milestone 3: Classes are distinct (weeks 9–14)
- Build the four gadgets one at a time: Scanner (easiest) → Holoshield → Decoy → Camera (hardest).
- Class passives (Tracker terminal reveal, Technocrat door hack are partly wired already).
- Remaining upgrade effects (Quick Hands, Spare Gadget, Overclock).
- **Done when:** all 4 classes are playable and feel different.

## Milestone 4: A real map (weeks 15–22)
- Full-size greybox first, all tiers, 2–3 routes into every high-tier room. Playtest it *before* any art.
- NPC idle animations, guards patrolling their tier, 20–30 NPCs total.
- Art pass, lighting, sound. Lobby room.
- Check performance on a phone early.
- **Done when:** the map looks like a place, not a test level.

## Milestone 5: Alpha (weeks 23–28)
- Bug fixing, balance, game feel (sounds, screen shake, cover-blown effects), mobile controls.
- Public test with friends / a small Discord.

## Cut from the first release (add later)
- DataStore progression (XP, unlocks, cosmetics)
- Separate lobby place + cross-server matchmaking
- Classes 5 and 6, a second map
- NPCs that react to exposed agents

## Solo tips
- **Map is the biggest solo time cost.** Use free Toolbox / Creator Store models for the greybox and
  first art pass. Swap in your own later, or commission pieces.
- **Playtesting needs other people.** Find 2–3 friends for a fixed weekly session from Milestone 2 on.
  Studio's multi-client test only goes so far.
- **One system at a time.** Finish and playtest each before starting the next; half-done systems pile up fast.
- **Don't add classes or gadgets** until Milestone 5 is out, no matter how good the idea is.
