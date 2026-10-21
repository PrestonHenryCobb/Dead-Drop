--!strict
-- Placeholder HUD built in code so the game is playable on day one.
-- Replace with designed UI whenever you like; keep reading from StateController.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Clearance = require(ReplicatedStorage.Shared.Config.Clearance)
local GameConfig = require(ReplicatedStorage.Shared.Config.GameConfig)
local Net = require(ReplicatedStorage.Shared.Net)
local Types = require(ReplicatedStorage.Shared.Types)
local Upgrades = require(ReplicatedStorage.Shared.Config.Upgrades)
local StateController = require(script.Parent.StateController)

local HUDController = {}

local function label(parent: Instance, name: string, position: UDim2, size: UDim2): TextLabel
	local text = Instance.new("TextLabel")
	text.Name = name
	text.Position = position
	text.Size = size
	text.BackgroundTransparency = 1
	text.TextColor3 = Color3.new(1, 1, 1)
	text.TextStrokeTransparency = 0.5
	text.Font = Enum.Font.GothamBold
	text.TextScaled = true
	text.TextXAlignment = Enum.TextXAlignment.Left
	text.Parent = parent
	return text
end

local function upgradeName(id: string): string
	for _, upgrade in Upgrades.All do
		if upgrade.Id == id then
			return upgrade.Name
		end
	end
	return id
end

function HUDController.start()
	local gui = Instance.new("ScreenGui")
	gui.Name = "HUD"
	gui.ResetOnSpawn = false
	gui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")

	local phaseLabel = label(gui, "Phase", UDim2.new(0.35, 0, 0, 8), UDim2.new(0.3, 0, 0, 32))
	phaseLabel.TextXAlignment = Enum.TextXAlignment.Center

	local panel = Instance.new("Frame")
	panel.Name = "Status"
	panel.Position = UDim2.new(0, 16, 1, -176)
	panel.Size = UDim2.new(0, 280, 0, 160)
	panel.BackgroundTransparency = 0.4
	panel.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
	panel.Parent = gui

	local disguiseLabel = label(panel, "Disguise", UDim2.new(0, 8, 0, 4), UDim2.new(1, -16, 0, 24))
	local intelLabel = label(panel, "Intel", UDim2.new(0, 8, 0, 32), UDim2.new(1, -16, 0, 22))
	local keycardLabel = label(panel, "Keycards", UDim2.new(0, 8, 0, 58), UDim2.new(1, -16, 0, 20))
	local upgradeLabel = label(panel, "Upgrades", UDim2.new(0, 8, 0, 82), UDim2.new(1, -16, 0, 20))

	local barBack = Instance.new("Frame")
	barBack.Position = UDim2.new(0, 8, 0, 112)
	barBack.Size = UDim2.new(1, -16, 0, 14)
	barBack.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
	barBack.Parent = panel
	local barFill = Instance.new("Frame")
	barFill.Size = UDim2.new(0, 0, 1, 0)
	barFill.BackgroundColor3 = Color3.fromRGB(255, 80, 60)
	barFill.BorderSizePixel = 0
	barFill.Parent = barBack
	label(panel, "SuspicionText", UDim2.new(0, 8, 0, 130), UDim2.new(1, -16, 0, 18)).Text = "SUSPICION"

	local notifyLabel = label(gui, "Notify", UDim2.new(0.25, 0, 0, 48), UDim2.new(0.5, 0, 0, 26))
	notifyLabel.TextXAlignment = Enum.TextXAlignment.Center
	notifyLabel.TextColor3 = Color3.fromRGB(255, 230, 120)

	local function render(state: Types.PlayerState)
		local tier = Clearance.get(state.DisguiseTier)
		disguiseLabel.Text = if state.Disguised then `Disguise: {tier.Name}` else "EXPOSED"
		disguiseLabel.TextColor3 = if state.Disguised then tier.Color else Color3.fromRGB(255, 80, 60)
		intelLabel.Text = `Intel: {state.Intel}/{GameConfig.IntelToOpenVault}`
			.. (if state.CarryingPackage then "  [PACKAGE]" else "")

		local cards = {}
		for cardTier in state.Keycards do
			table.insert(cards, Clearance.get(cardTier).Name)
		end
		keycardLabel.Text = "Keycards: " .. (if #cards > 0 then table.concat(cards, ", ") else "none")

		local names = {}
		for _, id in state.Upgrades do
			table.insert(names, upgradeName(id))
		end
		upgradeLabel.Text = "Upgrades: " .. (if #names > 0 then table.concat(names, ", ") else "none")

		barFill.Size = UDim2.new(state.Suspicion / 100, 0, 1, 0)
		panel.Visible = state.InRound
	end

	StateController.StateChanged:Connect(render)
	if StateController.state then
		render(StateController.state)
	end

	RunService.RenderStepped:Connect(function()
		local endsAt = StateController.phaseEndsAt
		local remaining = math.max(0, math.floor(endsAt - workspace:GetServerTimeNow()))
		phaseLabel.Text = if endsAt > 0
			then `{StateController.phase}  {remaining // 60}:{string.format("%02d", remaining % 60)}`
			else StateController.phase
	end)

	local notifyId = 0
	Net.event("Notify").OnClientEvent:Connect(function(message: string)
		notifyId += 1
		local myId = notifyId
		notifyLabel.Text = message
		task.delay(4, function()
			if notifyId == myId then
				notifyLabel.Text = ""
			end
		end)
	end)

	-- Show a marker where the package carrier was last seen.
	Net.event("CarrierPing").OnClientEvent:Connect(function(position: Vector3)
		local marker = Instance.new("Part")
		marker.Anchored = true
		marker.CanCollide = false
		marker.CanQuery = false
		marker.Transparency = 1
		marker.Position = position
		marker.Parent = workspace
		local billboard = Instance.new("BillboardGui")
		billboard.Size = UDim2.new(0, 120, 0, 40)
		billboard.AlwaysOnTop = true
		billboard.Parent = marker
		local text = label(billboard, "Ping", UDim2.new(), UDim2.new(1, 0, 1, 0))
		text.Text = "PACKAGE"
		text.TextXAlignment = Enum.TextXAlignment.Center
		text.TextColor3 = Color3.fromRGB(255, 215, 0)
		task.delay(GameConfig.CarrierPingInterval, function()
			marker:Destroy()
		end)
	end)
end

return HUDController
