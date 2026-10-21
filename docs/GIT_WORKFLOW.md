# Git Workflow (solo)

Git is your undo button and your save history. The aim is that `main` always runs.

## Branches

- `main`: always playable. Small fixes can go straight here.
- `feature/<thing>`: for anything that takes more than one sitting or might break the game
  (e.g. `feature/hitscan`, `feature/decoy-gadget`). Merge into `main` when it works in a playtest.

## Daily loop

```bash
git checkout main
git pull

# for a bigger change:
git checkout -b feature/door-sounds

# ... work, with `rojo serve` running and Studio connected ...

stylua src && selene src
git add -A
git commit -m "Play sound when clearance doors open"
git push -u origin feature/door-sounds
```

When it works in Studio:

```bash
git checkout main
git merge feature/door-sounds
git push
git branch -d feature/door-sounds
```

Commit every time something works, even small things. That gives you more points to roll back to.

## Optional GitHub setting

Settings → Branches → add a rule for `main` that requires the `CI / lint` check to pass. This stops you from
merging code that doesn't parse. You can still push directly; open a PR from a feature branch when you want CI to check it first.

## The map file

Scripts are text and diff cleanly. The `.rbxl` place file doesn't, which is why it's gitignored.
- Publish the place to Roblox often. Roblox keeps version history (Game Settings → Places → Version History).
- At each milestone, also File → Save to File and attach the `.rbxl` to a GitHub Release as a backup.

## Publishing

1. Make sure `main` is in a good state and pushed.
2. `rojo serve`, sync into your place, Playtest, then File → Publish to Roblox.
3. Tag it: `git tag v0.1.0 && git push origin v0.1.0`.
