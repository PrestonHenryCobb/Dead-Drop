# Dead Drop

A Roblox social-stealth game inspired by Deceive Inc. Agents blend into a crowd by copying NPC disguises,
hack terminals for intel, climb a clearance ladder with keycards and safes, then fight to extract the package.

A solo project. **Status:** playable skeleton. The full round loop runs end to end with placeholder UI on a greybox map.

## Setup

1. Install [Aftman](https://github.com/LPGhatguy/aftman), then from this folder run:
   ```
   aftman install
   ```
   This installs the pinned versions of Rojo, Selene (linter) and StyLua (formatter).
2. Install the **Rojo** plugin in Roblox Studio (Plugins tab → Manage Plugins, or from the Rojo docs).
3. Open VS Code here and install the recommended extensions when prompted.
4. Run `rojo serve`, open your place in Studio, and click **Connect** in the Rojo plugin.
   Code in `src/` now syncs live into Studio.
5. Before pushing: `stylua src` then `selene src`. CI runs the same checks on every PR.

> Code lives in Git. **The map lives in the Studio place file**, published to Roblox (back it up, see Git Workflow).
> Every script lives in Git and syncs in with Rojo. Never edit synced scripts inside Studio; your edits get overwritten.

## Where things live

| Path | Roblox location | What's in it |
|---|---|---|
| `src/shared/` | ReplicatedStorage.Shared | Types, tuning config, remote names, world tag names |
| `src/server/Services/` | ServerScriptService.Server.Services | Round loop, state, disguises, clearance, combat, NPCs |
| `src/client/` | StarterPlayerScripts.Client | HUD, lobby menu, input |
| Map, NPC models, tags | The Studio place file | Built by hand in Studio |

## Docs

- [Game Design](docs/GAME_DESIGN.md): lobby, classes, clearance/keycards/safes, round flow
- [Contracts](docs/CONTRACTS.md): remotes, tags and attributes that connect the code to the map
- [Git Workflow](docs/GIT_WORKFLOW.md): branches, PRs, daily routine
- [Roadmap](docs/ROADMAP.md): solo build order with milestones
- [Greybox builder](tools/BuildGreybox.luau): paste into Studio's Command Bar to build the test map
- [Claude Code Guide](docs/CLAUDE_CODE.md): how to use Claude Code on this repo
