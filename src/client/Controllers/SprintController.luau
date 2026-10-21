--!strict
-- Hold Shift to sprint.
-- Sprinting while disguised is allowed, but the server sees the speed and raises Suspicion.

local ContextActionService = game:GetService("ContextActionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage.Shared.Config.GameConfig)
local StateController = require(script.Parent.StateController)

local SPRINT_SPEED = 22

local SprintController = {}

local sprinting = false

local function applySpeed()
	local character = Players.LocalPlayer.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		return
	end
	local state = StateController.state
	local base = if state and state.Disguised then GameConfig.WalkSpeedDisguised else GameConfig.WalkSpeedRevealed
	humanoid.WalkSpeed = if sprinting then SPRINT_SPEED else base
end

function SprintController.start()
	ContextActionService:BindAction("Sprint", function(_, inputState)
		sprinting = inputState == Enum.UserInputState.Begin
		applySpeed()
		return Enum.ContextActionResult.Pass
	end, true, Enum.KeyCode.LeftShift, Enum.KeyCode.ButtonL3)

	StateController.StateChanged:Connect(applySpeed)
	Players.LocalPlayer.CharacterAdded:Connect(function()
		sprinting = false
		task.defer(applySpeed)
	end)
end

return SprintController
