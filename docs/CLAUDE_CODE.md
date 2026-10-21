# Using Claude Code on this repo

Claude Code works on the text files in this repo. It can't see or click inside Roblox Studio,
so **you** playtest and paste back what happened.

## Good prompts are scoped to one system

> Read docs/CONTRACTS.md and src/server/Services/ClearanceService.luau. Add a sound that plays on the door
> when it opens and when access is denied. Read the sound asset IDs from attributes on the door
> so I can set them in Studio. Don't change any other file.

> In src/client/Controllers/HUDController.luau, replace the suspicion bar with a ring around the crosshair
> that turns from white to red, and pulses when Suspicion > 75. Keep reading from StateController.

## Feed it real errors
Copy the red text from Studio's Output window and paste it in:
> Studio output after a 2-player test: `ServerScriptService.Server.Services.CoverService:58: attempt to index nil with 'Position'`. Fix it.

## Rules to give it
- "Don't change anything in src/shared/ without telling me." Those files affect server, client and map at once.
- "Validate every argument from OnServerEvent." It usually does, but say it.
- Run `stylua src && selene src` before committing (or ask Claude to).
