--!strict
-- Server entry point. Every service gets init() (wire up, no yielding), then start() (begin loops).

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Net = require(ReplicatedStorage.Shared.Net)
Net.init()

local Services = script.Parent.Services
local order = {
	"StateService",
	"ClearanceService",
	"CoverService",
	"CombatService",
	"NPCService",
	"MatchService",
}

local loaded = {}
for _, name in order do
	local service = require(Services[name]) :: any
	loaded[name] = service
	if service.init then
		service.init()
	end
end
for _, name in order do
	local service = loaded[name]
	if service.start then
		task.spawn(service.start)
	end
end

print("[Server] All services started")
