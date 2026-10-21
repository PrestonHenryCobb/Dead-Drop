# Dead Drop

A Roblox social-stealth game inspired by Deceive Inc. Agents blend into a crowd by copying NPC disguises,
hack terminals for intel, climb a clearance ladder with keycards and safes, then fight to extract the package.

**Status:** playable skeleton. The full round loop runs end to end with placeholder UI on a greybox map.

## Quick start (everyone)

1. Install [Aftman](https://github.com/LPGhatguy/aftman), then from this folder run:
   ```
   aftman install
   ```
   This installs the pinned versions of Rojo, Selene (linter) and StyLua (formatter).
2. Install the **Rojo** plugin in Roblox Studio (Plugins tab → Manage Plugins, or from the Rojo docs).
3. Open VS Code here and install the recommended extensions when prompted.
4. Run `rojo serve`, open the team's place in Studio, and click **Connect** in the Rojo plugin.
   Code in `src/` now syncs live into Studio.
5. Before pushing: `stylua src` then `selene src`. CI runs the same checks on every PR.

> Code lives in Git. **The map lives in the Studio place file.** Use Team Create for the map,
> and Git + Rojo for every script. Never edit synced scripts inside Studio; your edits get overwritten.

## Where things live

| Path | Roblox location | Owner |
|---|---|---|
| `src/shared/` | ReplicatedStorage.Shared | Everyone (contract, needs all three to review) |
| `src/server/Services/` | ServerScriptService.Server.Services | Dev 1 (except Combat → Dev 2, NPC → Dev 3) |
| `src/client/` | StarterPlayerScripts.Client | Dev 2 |
| Map, NPC models, tags | Studio place (Team Create) | Dev 3 |

## Docs

- [Game Design](docs/GAME_DESIGN.md): lobby, classes, clearance/keycards/safes, round flow
- [Team Split](docs/TEAM_SPLIT.md): who owns what and how the pieces connect
- [Contracts](docs/CONTRACTS.md): remotes, tags and attributes everyone codes against
- [Git Workflow](docs/GIT_WORKFLOW.md): branches, PRs, daily routine
- [Roadmap](docs/ROADMAP.md): 12-week plan with checkpoints
- [Claude Code Guide](docs/CLAUDE_CODE.md): how to use Claude Code on this repo
