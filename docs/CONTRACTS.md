# Contracts

Everything here is shared. Change it only in a dedicated PR that all three devs approve.

## Remotes (`src/shared/Net.luau`)

| Name | Direction | Arguments | Notes |
|---|---|---|---|
| `SelectClass` | Client → Server | `classId: string` | Lobby only. Server validates against `Config/Classes`. |
| `SetReady` | Client → Server | `ready: boolean` | Ignored until a class is picked. |
| `StateChanged` | Server → owner | `state: PlayerState` | Full state, sent whenever it changes. |
| `PhaseChanged` | Server → all | `phase: MatchPhase, endsAt: number` | `endsAt` is `workspace:GetServerTimeNow()`. `0` means no timer. |
| `Notify` | Server → one/all | `message: string` | Toasts. |
| `CarrierPing` | Server → all but carrier | `position: Vector3` | Every 5s during Extraction. |

**Things that deliberately are not remotes:**
- Disguising, hacking, doors, safes, keycards, vault and extraction all use `ProximityPrompt.Triggered`,
  which fires on the server with the real player. There's no remote for an exploiter to spam.
- Breaking cover is detected on the server from movement, zones and `Tool.Activated`. An earlier draft had a
  client-fired `BreakCover`, but a cheater would simply never fire it.

## PlayerState (`src/shared/Types.luau`)

```lua
{
  ClassId: ClassId?, Ready: boolean, InRound: boolean,
  Disguised: boolean, DisguiseTier: number, Suspicion: number, CoverCooldownUntil: number,
  Intel: number, CarryingPackage: boolean,
  Keycards: { [tier]: true }, Upgrades: { upgradeId },
}
```

Only `StateService.update()` writes it.

## World tags (`src/shared/Config/WorldTags.luau`)

Add tags in Studio with **View → Tags**. Set attributes in the Properties panel → **Attributes → +**.

| Tag | Put it on | Attributes | Notes |
|---|---|---|---|
| `CrowdNPC` | NPC Model (R15, with Humanoid + HumanoidRootPart) | `Tier: number` (0–4) | Optional child `HumanoidDescription` named `Look`. |
| `WanderNode` | Small invisible anchored Part | `Tier: number` | NPCs only walk to nodes of their own tier. |
| `ClearanceZone` | Invisible, `CanCollide=false`, `CanQuery=false` Part covering a room | `RequiredTier: number` | Overlapping zones: highest tier counts. |
| `ClearanceDoor` | Door Part | `RequiredTier: number` | Opens for 3s. |
| `KeycardSpawn` | Invisible anchored Part | `Tier: number` (1–4) | A keycard appears here each round. |
| `Safe` | Safe Part | `Tier: number` (1–4) | Needs the exact-tier keycard. |
| `IntelTerminal` | Terminal Part | none | Once per round. |
| `Vault` | Vault Part | none | Needs `IntelToOpenVault` intel. |
| `ExtractionPoint` | Part | none | Carrier holds prompt to win. |
| `InsertionPoint` | Part | none | Where agents spawn each round. |

The lobby is just a normal `SpawnLocation` placed in the lobby room. Dead players and post-round
respawns land there automatically.

## Day-one greybox test map (Dev 3, ~1 hour)

1. Baseplate. A `SpawnLocation` in a walled lobby room off to one side.
2. Three `InsertionPoint`s in the main hall, plus 5 `CrowdNPC`s (`Tier 0`) and 4 `WanderNode`s (`Tier 0`).
3. A side room covered by a `ClearanceZone` (`RequiredTier 1`) behind a `ClearanceDoor` (`RequiredTier 1`).
   Inside: 2 `CrowdNPC` + 2 `WanderNode` at `Tier 1`, a `Safe` (`Tier 1`), a `KeycardSpawn` (`Tier 2`).
4. A `KeycardSpawn` (`Tier 1`) in the main hall.
5. Three `IntelTerminal`s, one `Vault`, one `ExtractionPoint`.
6. Set `MinPlayers = 1` in `GameConfig` locally (don't commit it), press Play, and run a full round solo.
   Use **Test → Clients and Servers → 2 players** to test with a second player.
