# Team Split

Split by **layer**, not by feature. Each dev owns different files, so you almost never edit the same file.
The only shared files are the contract in `src/shared/` and `docs/CONTRACTS.md`. Changes there need all three to review.

```
                Dev 1: Server & Match
          (state, rules, round loop, security)
                 ▲                    ▲
     Remotes in  │                    │  Tags + attributes
     Net.luau    │                    │  on parts in Studio
                 ▼                    ▼
   Dev 2: Client, UI, Combat     Dev 3: World, NPCs, AI
   (what players see & press)    (the map and the crowd)
```

## Dev 1: Backend & Match Architect

**Owns:** `StateService`, `MatchService`, `ClearanceService`, `CoverService`, `Net.luau`, `Config/*`

- Keep the server authoritative. **Never trust a value sent from a client.** Check type, range, distance and phase.
- Round loop, win conditions, intel/vault/extraction.
- Keycards, doors, safes, upgrade effects that live on the server.
- Disguise application and the suspicion tick.
- Later: DataStore for persistent unlocks and stats (post-alpha).

## Dev 2: Client, UI, Gadgets & Combat

**Owns:** everything in `src/client/`, plus `CombatService`

- Replace the placeholder HUD and lobby with designed UI: class cards, suspicion meter, keycard/upgrade
  inventory, hit markers, notifications.
- Weapons: client input → a `Fire` remote → server hitscan in `CombatService` (add the remote to the contract first).
- The four class gadgets (Holoshield, Scanner, Decoy, Camera) as Tools. Using one already breaks cover via `CombatService`.
- Client-side upgrade effects (Quick Hands: shorten terminal prompt `HoldDuration` locally).
- Game feel: sounds, screen shake, cover-blown flash, extraction ping visuals.

## Dev 3: World, NPCs & AI

**Owns:** the Studio map, NPC models, `NPCService`, every tag and attribute placed in the world

- Build a greybox map first (week 1–2), then the real art pass. Tag everything per `docs/CONTRACTS.md`.
- 20–40 crowd NPCs across all tiers, each with a distinct look (store it as a `HumanoidDescription` named `Look`).
- `NPCService`: wandering, idle animations, guards that patrol their own tier, and later NPC reactions to exposed agents.
- Lobby room: spawn point, a mirror of class models, a leaderboard board.
- Lighting, sound zones, performance (keep NPC count and part count in check on mobile).

## How the pieces connect without stepping on each other

| Dev 3 places in Studio… | …Dev 1's code picks it up |
|---|---|
| Model tagged `CrowdNPC`, attribute `Tier = 2` | `CoverService` adds a "Copy Disguise" prompt that gives tier 2 |
| Part tagged `Safe`, attribute `Tier = 3` | `ClearanceService` makes it crackable with a Technician keycard |
| Part tagged `IntelTerminal` | `MatchService` makes it hackable for intel |

| Dev 1's server sends… | …Dev 2's client shows it |
|---|---|
| `StateChanged(state)` | HUD reads `state.Suspicion`, `state.Keycards`, `state.Upgrades` |
| `PhaseChanged(phase, endsAt)` | Timer, lobby menu visibility |
| `Notify(text)`, `CarrierPing(pos)` | Toasts and the package marker |

**Rule:** if you need something from another layer, add it to the contract in its own small PR first.
Once that merges, both sides build against it in parallel.

## Weekly rhythm

- **Monday (15 min):** each person says what they'll merge this week and any contract changes they need.
- **Daily:** small PRs into `develop`. Review each other's within 24h.
- **Friday playtest (30 min):** all three in a Team Create session playing the current `develop` build.
  Write down what felt bad, and that becomes next week's work.
