# Git Workflow

## Branches

- `main`: what's published to Roblox. Only updated from `develop` at a milestone. Protected.
- `develop`: integration branch. Everyone's PRs go here. Should always run.
- `feature/<area>-<thing>`: your work. Area is `server`, `client`, or `world`.
  e.g. `feature/server-safe-loot`, `feature/client-suspicion-meter`, `feature/world-npc-idles`.
- `contract/<thing>`: changes to `src/shared/` or `docs/CONTRACTS.md`. All three review.

## One-time GitHub setup (repo owner)

1. Settings → Collaborators: add your two teammates.
2. Settings → Branches → add protection rules for `main` and `develop`:
   require a pull request, 1 approval, and the `CI / lint` check passing.
3. Edit `.github/CODEOWNERS` and replace `@DEV1/@DEV2/@DEV3` with your usernames.

## Daily loop

```bash
git checkout develop
git pull origin develop
git checkout -b feature/server-door-sounds

# ... work, with `rojo serve` running and Studio connected ...

stylua src && selene src
git add -A
git commit -m "server: play sound when clearance door opens"
git push -u origin feature/server-door-sounds
# open a PR into develop on GitHub; fill in the template
```

Keep PRs small: one idea, ideally under ~300 lines. Small PRs get reviewed the same day.

## When develop moved while you were working

```bash
git fetch origin
git rebase origin/develop
# fix conflicts if any, then:
git push --force-with-lease
```

## The map file

Scripts are text and merge cleanly. The `.rbxl` place file doesn't, which is why it's gitignored.
- Keep the map in **Team Create** on the team's Roblox group place.
- At each milestone, Dev 3 exports a backup (File → Save to File) and attaches it to a GitHub Release.

## Publishing

1. Merge `develop` → `main` via PR at the end of a milestone.
2. Pull `main`, `rojo serve`, sync into the Team Create place, Playtest, then File → Publish to Roblox.
3. Tag it: `git tag v0.1.0 && git push origin v0.1.0`.
