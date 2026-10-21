--!strict
-- OWNER: Dev 2. Server side of combat.
--
-- Rule that must never break: using a weapon or gadget while disguised blows your cover.
-- Every Tool's Activated event fires on the server, so we enforce it here rather than trusting the client.
--
-- TODO(Dev 2): server-authoritative hitscan. The client sends a "Fire" request with an aim direction,
-- the server raycasts from the character's head, checks fire rate and range, and applies damage.
-- Add the remote to Net.Events + docs/CONTRACTS.md in the same PR.

local Players = game:GetService("Players")

local CoverService = require(script.Parent.CoverService)

local CombatService = {}

local function watchTool(player: Player, tool: Instance)
	if not tool:IsA("Tool") or tool:GetAttribute("CombatWatched") then
		return
	end
	tool:SetAttribute("CombatWatched", true)
	tool.Activated:Connect(function()
		CoverService.breakCover(player, "Used " .. tool.Name)
	end)
end

local function onCharacter(player: Player, character: Model)
	for _, child in character:GetChildren() do
		watchTool(player, child)
	end
	character.ChildAdded:Connect(function(child)
		watchTool(player, child)
	end)
end

function CombatService.init()
	local function onPlayer(player: Player)
		if player.Character then
			onCharacter(player, player.Character)
		end
		player.CharacterAdded:Connect(function(character)
			onCharacter(player, character)
		end)
	end
	Players.PlayerAdded:Connect(onPlayer)
	for _, player in Players:GetPlayers() do
		onPlayer(player)
	end
end

return CombatService
