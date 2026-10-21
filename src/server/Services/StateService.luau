--!strict
-- The single source of truth for per-player data.
-- Nobody else writes player data directly: call StateService.update(player, function(state) ... end).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Net = require(ReplicatedStorage.Shared.Net)
local Types = require(ReplicatedStorage.Shared.Types)

type PlayerState = Types.PlayerState

local StateService = {}

local states: { [Player]: PlayerState } = {}
local changedEvent = Instance.new("BindableEvent")

-- Fires (player, state) after every update. Server-only.
StateService.Changed = changedEvent.Event

local function newState(): PlayerState
	return {
		ClassId = nil,
		Ready = false,
		InRound = false,
		Disguised = false,
		DisguiseTier = 0,
		Suspicion = 0,
		CoverCooldownUntil = 0,
		Intel = 0,
		CarryingPackage = false,
		Keycards = {},
		Upgrades = {},
	}
end

function StateService.get(player: Player): PlayerState?
	return states[player]
end

function StateService.update(player: Player, mutate: (PlayerState) -> ())
	local state = states[player]
	if not state then
		return
	end
	mutate(state)
	Net.event("StateChanged"):FireClient(player, state)
	changedEvent:Fire(player, state)
end

function StateService.hasUpgrade(player: Player, upgradeId: string): boolean
	local state = states[player]
	return state ~= nil and table.find(state.Upgrades, upgradeId) ~= nil
end

-- Clears everything that only lasts one round. Class and Ready are kept.
function StateService.resetRound(player: Player)
	StateService.update(player, function(state)
		state.InRound = false
		state.Disguised = false
		state.DisguiseTier = 0
		state.Suspicion = 0
		state.CoverCooldownUntil = 0
		state.Intel = 0
		state.CarryingPackage = false
		state.Keycards = {}
		state.Upgrades = {}
	end)
end

function StateService.playersInRound(): { Player }
	local result = {}
	for player, state in states do
		if state.InRound then
			table.insert(result, player)
		end
	end
	return result
end

function StateService.init()
	local function onPlayerAdded(player: Player)
		states[player] = newState()
		Net.event("StateChanged"):FireClient(player, states[player])
	end

	Players.PlayerAdded:Connect(onPlayerAdded)
	Players.PlayerRemoving:Connect(function(player)
		-- Deferred so other services' PlayerRemoving handlers can still read the state.
		task.defer(function()
			states[player] = nil
		end)
	end)
	for _, player in Players:GetPlayers() do
		onPlayerAdded(player)
	end
end

return StateService
