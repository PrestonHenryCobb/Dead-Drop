--!strict
-- Mirrors the server's view of this player and the match phase.
-- Other controllers read from here instead of listening to remotes themselves.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Net = require(ReplicatedStorage.Shared.Net)
local Types = require(ReplicatedStorage.Shared.Types)

local StateController = {}

StateController.state = nil :: Types.PlayerState?
StateController.phase = "Lobby" :: Types.MatchPhase
StateController.phaseEndsAt = 0

local stateChanged = Instance.new("BindableEvent")
local phaseChanged = Instance.new("BindableEvent")
StateController.StateChanged = stateChanged.Event -- (state)
StateController.PhaseChanged = phaseChanged.Event -- (phase, endsAt)

function StateController.start()
	Net.event("StateChanged").OnClientEvent:Connect(function(state: Types.PlayerState)
		StateController.state = state
		stateChanged:Fire(state)
	end)
	Net.event("PhaseChanged").OnClientEvent:Connect(function(phase: Types.MatchPhase, endsAt: number)
		StateController.phase = phase
		StateController.phaseEndsAt = endsAt
		phaseChanged:Fire(phase, endsAt)
	end)
end

return StateController
