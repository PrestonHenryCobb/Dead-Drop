--!strict
-- Clearance tiers, keycards, doors and upgrade safes.
--
-- The loop: keycards spawn around the map each round (higher tiers inside higher-tier rooms).
-- A keycard of tier N cracks safes of tier N and opens doors up to tier N.
-- Safes hand out a random Upgrade card that lasts for the rest of the round.

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Clearance = require(ReplicatedStorage.Shared.Config.Clearance)
local Net = require(ReplicatedStorage.Shared.Net)
local Types = require(ReplicatedStorage.Shared.Types)
local Upgrades = require(ReplicatedStorage.Shared.Config.Upgrades)
local WorldTags = require(ReplicatedStorage.Shared.Config.WorldTags)
local StateService = require(script.Parent.StateService)

type PlayerState = Types.PlayerState

local DOOR_OPEN_SECONDS = 3

local ClearanceService = {}

local spawnedKeycards: { BasePart } = {}

local function notify(player: Player, message: string)
	Net.event("Notify"):FireClient(player, message)
end

local function makePrompt(
	parent: Instance,
	actionText: string,
	objectText: string,
	holdDuration: number
): ProximityPrompt
	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = actionText
	prompt.ObjectText = objectText
	prompt.HoldDuration = holdDuration
	prompt.MaxActivationDistance = 8
	prompt.RequiresLineOfSight = false
	prompt.Parent = parent
	return prompt
end

-- Disguise tier plus any upgrade bonuses. Used for zones and doors.
function ClearanceService.effectiveTier(player: Player, state: PlayerState): number
	local tier = if state.Disguised then state.DisguiseTier else 0
	if StateService.hasUpgrade(player, "MasterKey") then
		tier += 1
	end
	return math.min(tier, Clearance.MaxTier)
end

-- Highest RequiredTier of any ClearanceZone containing the position, or 0.
function ClearanceService.zoneTierAt(position: Vector3): number
	local highest = 0
	for _, zone in CollectionService:GetTagged(WorldTags.ClearanceZone) do
		if zone:IsA("BasePart") then
			local localPos = zone.CFrame:PointToObjectSpace(position)
			local half = zone.Size / 2
			if math.abs(localPos.X) <= half.X and math.abs(localPos.Y) <= half.Y and math.abs(localPos.Z) <= half.Z then
				highest = math.max(highest, zone:GetAttribute("RequiredTier") or 0)
			end
		end
	end
	return highest
end

local function canOpenDoor(player: Player, state: PlayerState, requiredTier: number): boolean
	local tier = ClearanceService.effectiveTier(player, state)
	if state.ClassId == "Technocrat" then
		tier += 1
	end
	if tier >= requiredTier then
		return true
	end
	for keycardTier in state.Keycards do
		if keycardTier >= requiredTier then
			return true
		end
	end
	return false
end

local function setupDoor(door: Instance)
	if not door:IsA("BasePart") then
		return
	end
	local requiredTier = door:GetAttribute("RequiredTier") or 1
	local prompt = makePrompt(door, "Open", Clearance.get(requiredTier).Name .. " Door", 0)
	local isOpen = false

	prompt.Triggered:Connect(function(player)
		local state = StateService.get(player)
		if not state or isOpen then
			return
		end
		if not canOpenDoor(player, state, requiredTier) then
			notify(player, `Requires {Clearance.get(requiredTier).Name} clearance or keycard`)
			return
		end
		isOpen = true
		local oldTransparency = door.Transparency
		door.CanCollide = false
		door.Transparency = 0.8
		task.delay(DOOR_OPEN_SECONDS, function()
			door.CanCollide = true
			door.Transparency = oldTransparency
			isOpen = false
		end)
	end)
end

local function applyUpgradeEffects(player: Player, upgradeId: string)
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if upgradeId == "Padding" and humanoid then
		humanoid.MaxHealth += 20
		humanoid.Health += 20
	end
	-- QuickHands, ExtraGadget, Overclock: read on the client / by gadget code via StateService.hasUpgrade.
	-- LightStep, Ghost, CoolHead, MasterKey: read by CoverService / effectiveTier.
end

local function setupSafe(safe: Instance)
	if not safe:IsA("BasePart") then
		return
	end
	local tier = safe:GetAttribute("Tier") or 1
	local info = Clearance.get(tier)
	local prompt = makePrompt(safe, "Crack Safe", info.Name .. " Safe", 2 + tier)
	prompt.Name = "SafePrompt"

	prompt.Triggered:Connect(function(player)
		local state = StateService.get(player)
		if not state or not state.InRound or safe:GetAttribute("Looted") then
			return
		end
		if not state.Keycards[tier] then
			notify(player, `Needs a {info.Name} keycard`)
			return
		end
		local upgrade = Upgrades.roll(tier, state.Upgrades)
		safe:SetAttribute("Looted", true)
		prompt.Enabled = false
		if not upgrade then
			notify(player, "The safe was empty")
			return
		end
		StateService.update(player, function(s)
			table.insert(s.Upgrades, upgrade.Id)
		end)
		applyUpgradeEffects(player, upgrade.Id)
		notify(player, `Upgrade: {upgrade.Name} - {upgrade.Description}`)
	end)
end

local function spawnKeycard(spawnPoint: BasePart)
	local tier = spawnPoint:GetAttribute("Tier") or 1
	local info = Clearance.get(tier)

	local card = Instance.new("Part")
	card.Name = "Keycard"
	card.Size = Vector3.new(1, 0.1, 1.5)
	card.Color = info.Color
	card.Material = Enum.Material.Neon
	card.Anchored = true
	card.CanCollide = false
	card.CFrame = spawnPoint.CFrame
	card.Parent = workspace

	local prompt = makePrompt(card, "Take", info.Name .. " Keycard", 0.5)
	prompt.Triggered:Connect(function(player)
		local state = StateService.get(player)
		if not state or not state.InRound or card.Parent == nil then
			return
		end
		StateService.update(player, function(s)
			s.Keycards[tier] = true
		end)
		notify(player, `Picked up {info.Name} keycard`)
		card:Destroy()
	end)

	table.insert(spawnedKeycards, card)
end

-- Called by MatchService at the start of every round.
function ClearanceService.resetRound()
	for _, card in spawnedKeycards do
		card:Destroy()
	end
	table.clear(spawnedKeycards)

	for _, spawnPoint in CollectionService:GetTagged(WorldTags.KeycardSpawn) do
		if spawnPoint:IsA("BasePart") then
			spawnKeycard(spawnPoint)
		end
	end

	for _, safe in CollectionService:GetTagged(WorldTags.Safe) do
		safe:SetAttribute("Looted", false)
		local prompt = safe:FindFirstChild("SafePrompt")
		if prompt and prompt:IsA("ProximityPrompt") then
			prompt.Enabled = true
		end
	end
end

function ClearanceService.init()
	for _, door in CollectionService:GetTagged(WorldTags.ClearanceDoor) do
		setupDoor(door)
	end
	CollectionService:GetInstanceAddedSignal(WorldTags.ClearanceDoor):Connect(setupDoor)

	for _, safe in CollectionService:GetTagged(WorldTags.Safe) do
		setupSafe(safe)
	end
	CollectionService:GetInstanceAddedSignal(WorldTags.Safe):Connect(setupSafe)

	-- Padding has to be re-applied if the character respawns mid-round.
	Players.PlayerAdded:Connect(function(player)
		player.CharacterAdded:Connect(function()
			if StateService.hasUpgrade(player, "Padding") then
				task.defer(applyUpgradeEffects, player, "Padding")
			end
		end)
	end)
end

return ClearanceService
