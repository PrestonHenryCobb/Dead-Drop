--!strict
-- The one place RemoteEvents are named and created.
-- The server calls Net.init() once at startup; everyone else calls Net.event(name).
-- Adding or renaming an event is a contract change: update docs/CONTRACTS.md in the same PR.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local FOLDER_NAME = "Remotes"

local Net = {}

Net.Events = {
	-- Client -> Server
	SelectClass = "SelectClass", -- (classId: string)
	SetReady = "SetReady", -- (ready: boolean)

	-- Server -> Client
	StateChanged = "StateChanged", -- (state: PlayerState) sent only to the owning player
	PhaseChanged = "PhaseChanged", -- (phase: MatchPhase, endsAt: number) endsAt is workspace:GetServerTimeNow()
	Notify = "Notify", -- (message: string)
	CarrierPing = "CarrierPing", -- (position: Vector3) package carrier's position, sent to everyone else
}

function Net.init()
	assert(RunService:IsServer(), "Net.init() is server-only")
	local folder = ReplicatedStorage:FindFirstChild(FOLDER_NAME)
	if not folder then
		folder = Instance.new("Folder")
		folder.Name = FOLDER_NAME
		folder.Parent = ReplicatedStorage
	end
	for name in Net.Events do
		if not folder:FindFirstChild(name) then
			local remote = Instance.new("RemoteEvent")
			remote.Name = name
			remote.Parent = folder
		end
	end
end

function Net.event(name: string): RemoteEvent
	assert(Net.Events[name], `Unknown remote "{name}". Add it to Net.Events first.`)
	local folder = ReplicatedStorage:WaitForChild(FOLDER_NAME)
	return folder:WaitForChild(name) :: RemoteEvent
end

return Net
