--!strict
-- OWNER: Dev 1. Disguises and suspicion.
--
-- Agents copy a crowd NPC's look with a ProximityPrompt. The server watches how they move
-- (replicated physics, so exploiters can't just skip a "BreakCover" call) and raises
-- Suspicion for sprinting, jumping, or standing in a zone above their disguise tier.
-- At 100 Suspicion the cover breaks.

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Clearance = require(ReplicatedStorage.Shared.Config.Clearance)
local GameConfig = require(ReplicatedStorage.Shared.Config.GameConfig)
local Net = require(ReplicatedStorage.Shared.Net)
local WorldTags = require(ReplicatedStorage.Shared.Config.WorldTags)
local ClearanceService = require(script.Parent.ClearanceService)
local StateService = require(script.Parent.StateService)

local TICK = 0.25

local CoverService = {}

-- Each player's own look, saved the first time they disguise so it can be restored.
local originalLooks: { [Player]: HumanoidDescription } = {}

local function notify(player: Player, message: string)
	Net.event("Notify"):FireClient(player, message)
end

local function getHumanoid(model: Model?): Humanoid?
	return if model then model:FindFirstChildOfClass("Humanoid") else nil
end

local function getLook(npc: Model): HumanoidDescription?
	local look = npc:FindFirstChild("Look")
	if look and look:IsA("HumanoidDescription") then
		return look:Clone()
	end
	local humanoid = getHumanoid(npc)
	return if humanoid then humanoid:GetAppliedDescription() else nil
end

local function setWalkSpeed(player: Player, disguised: boolean)
	local humanoid = getHumanoid(player.Character)
	if humanoid then
		humanoid.WalkSpeed = if disguised then GameConfig.WalkSpeedDisguised else GameConfig.WalkSpeedRevealed
	end
end

function CoverService.disguise(player: Player, npc: Model)
	local state = StateService.get(player)
	if not state or not state.InRound or state.CarryingPackage then
		return
	end
	if os.clock() < state.CoverCooldownUntil then
		notify(player, "Too hot to blend in yet")
		return
	end

	local character = player.Character
	local humanoid = getHumanoid(character)
	local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
	local npcRoot = npc:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not humanoid or humanoid.Health <= 0 or not root or not npcRoot then
		return
	end
	if (root.Position - npcRoot.Position).Magnitude > GameConfig.DisguiseRange + 2 then
		return
	end

	local look = getLook(npc)
	if not look then
		return
	end
	if not originalLooks[player] then
		originalLooks[player] = humanoid:GetAppliedDescription()
	end
	humanoid:ApplyDescription(look)

	local tier = npc:GetAttribute("Tier") or 0
	StateService.update(player, function(s)
		s.Disguised = true
		s.DisguiseTier = tier
		s.Suspicion = 0
	end)
	setWalkSpeed(player, true)
	notify(player, `Disguised as {Clearance.get(tier).Name}`)
end

function CoverService.breakCover(player: Player, reason: string)
	local state = StateService.get(player)
	if not state or not state.Disguised then
		return
	end

	local humanoid = getHumanoid(player.Character)
	local original = originalLooks[player]
	if humanoid and original then
		humanoid:ApplyDescription(original)
	end

	local cooldown = GameConfig.CoverBreakCooldown
	if StateService.hasUpgrade(player, "CoolHead") then
		cooldown /= 2
	end
	StateService.update(player, function(s)
		s.Disguised = false
		s.DisguiseTier = 0
		s.Suspicion = 0
		s.CoverCooldownUntil = os.clock() + cooldown
	end)
	setWalkSpeed(player, false)
	notify(player, `Cover blown: {reason}`)
end

-- Used at insertion so everyone starts blending in as a civilian.
function CoverService.disguiseAsRandomCivilian(player: Player)
	local civilians = {}
	for _, npc in CollectionService:GetTagged(WorldTags.CrowdNPC) do
		if npc:IsA("Model") and (npc:GetAttribute("Tier") or 0) == 0 then
			table.insert(civilians, npc)
		end
	end
	if #civilians == 0 then
		return
	end
	local npc = civilians[math.random(1, #civilians)]
	local humanoid = getHumanoid(player.Character)
	local look = getLook(npc)
	if not humanoid or not look then
		return
	end
	originalLooks[player] = humanoid:GetAppliedDescription()
	humanoid:ApplyDescription(look)
	StateService.update(player, function(s)
		s.Disguised = true
		s.DisguiseTier = 0
		s.Suspicion = 0
	end)
	setWalkSpeed(player, true)
end

local function setupNpcPrompt(npc: Instance)
	if not npc:IsA("Model") then
		return
	end
	local root = npc:WaitForChild("HumanoidRootPart", 5)
	if not root then
		warn(`[CoverService] CrowdNPC {npc:GetFullName()} has no HumanoidRootPart`)
		return
	end
	local tier = npc:GetAttribute("Tier") or 0
	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Copy Disguise"
	prompt.ObjectText = Clearance.get(tier).Name
	prompt.HoldDuration = 1.5
	prompt.MaxActivationDistance = GameConfig.DisguiseRange
	prompt.RequiresLineOfSight = false
	prompt.Parent = root
	prompt.Triggered:Connect(function(player)
		CoverService.disguise(player, npc)
	end)
end

local function suspicionGain(player: Player): number
	local state = StateService.get(player)
	local character = player.Character
	local humanoid = getHumanoid(character)
	local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not state or not humanoid or not root then
		return 0
	end

	local rates = GameConfig.SuspicionPerSecond
	local velocity = root.AssemblyLinearVelocity
	local gain = 0

	if Vector3.new(velocity.X, 0, velocity.Z).Magnitude > GameConfig.SprintSpeedThreshold then
		gain += rates.Sprinting * (if StateService.hasUpgrade(player, "LightStep") then 0.7 else 1)
	end
	if humanoid.FloorMaterial == Enum.Material.Air then
		gain += rates.Airborne
	end
	if ClearanceService.zoneTierAt(root.Position) > ClearanceService.effectiveTier(player, state) then
		gain += rates.Trespassing * (if StateService.hasUpgrade(player, "Ghost") then 0.5 else 1)
	end

	if state.ClassId == "Scoundrel" then
		gain *= 0.75
	end
	return gain
end

local function tick()
	for _, player in StateService.playersInRound() do
		local state = StateService.get(player)
		if state and state.Disguised then
			local gain = suspicionGain(player)
			local delta = if gain > 0 then gain * TICK else -GameConfig.SuspicionDecayPerSecond * TICK
			local newValue = math.clamp(state.Suspicion + delta, 0, 100)
			if newValue >= 100 then
				CoverService.breakCover(player, "Too suspicious")
			elseif newValue ~= state.Suspicion then
				StateService.update(player, function(s)
					s.Suspicion = newValue
				end)
			end
		end
	end
end

function CoverService.init()
	for _, npc in CollectionService:GetTagged(WorldTags.CrowdNPC) do
		task.spawn(setupNpcPrompt, npc)
	end
	CollectionService:GetInstanceAddedSignal(WorldTags.CrowdNPC):Connect(setupNpcPrompt)

	Players.PlayerRemoving:Connect(function(player)
		originalLooks[player] = nil
	end)
end

function CoverService.start()
	while true do
		task.wait(TICK)
		tick()
	end
end

return CoverService
