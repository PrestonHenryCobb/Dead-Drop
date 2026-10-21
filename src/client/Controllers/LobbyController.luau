--!strict
-- Placeholder lobby menu: pick a class, toggle ready.
-- Shown only during the Lobby phase. Reads the class list from Config/Classes, so new classes appear automatically.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Classes = require(ReplicatedStorage.Shared.Config.Classes)
local Net = require(ReplicatedStorage.Shared.Net)
local StateController = require(script.Parent.StateController)

local LobbyController = {}

local function button(parent: Instance, text: string, order: number): TextButton
	local b = Instance.new("TextButton")
	b.Size = UDim2.new(1, 0, 0, 56)
	b.LayoutOrder = order
	b.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
	b.TextColor3 = Color3.new(1, 1, 1)
	b.Font = Enum.Font.GothamBold
	b.TextSize = 16
	b.TextWrapped = true
	b.Text = text
	b.Parent = parent
	return b
end

function LobbyController.start()
	local gui = Instance.new("ScreenGui")
	gui.Name = "Lobby"
	gui.ResetOnSpawn = false
	gui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")

	local frame = Instance.new("Frame")
	frame.AnchorPoint = Vector2.new(1, 0.5)
	frame.Position = UDim2.new(1, -16, 0.5, 0)
	frame.Size = UDim2.new(0, 300, 0, 360)
	frame.BackgroundTransparency = 1
	frame.Parent = gui

	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, 8)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = frame

	local classButtons: { [string]: TextButton } = {}
	for i, classId in Classes.Order do
		local def = Classes.Classes[classId]
		local b = button(frame, `{def.DisplayName}  ({def.Role})\n{def.Description}`, i)
		b.TextSize = 13
		b.MouseButton1Click:Connect(function()
			Net.event("SelectClass"):FireServer(classId)
		end)
		classButtons[classId] = b
	end

	local readyButton = button(frame, "READY", #Classes.Order + 1)
	readyButton.MouseButton1Click:Connect(function()
		local state = StateController.state
		Net.event("SetReady"):FireServer(not (state and state.Ready))
	end)

	local function render()
		frame.Visible = StateController.phase == "Lobby"
		local state = StateController.state
		for classId, b in classButtons do
			local selected = state ~= nil and state.ClassId == classId
			b.BackgroundColor3 = if selected then Color3.fromRGB(60, 120, 220) else Color3.fromRGB(35, 35, 45)
		end
		local ready = state ~= nil and state.Ready
		readyButton.Text = if ready then "READY ✓ (click to cancel)" else "READY"
		readyButton.BackgroundColor3 = if ready then Color3.fromRGB(40, 160, 80) else Color3.fromRGB(35, 35, 45)
	end

	StateController.StateChanged:Connect(render)
	StateController.PhaseChanged:Connect(render)
	render()
end

return LobbyController
