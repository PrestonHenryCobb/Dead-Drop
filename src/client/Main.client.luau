--!strict
-- Client entry point. Every controller gets start().

local Controllers = script.Parent.Controllers
local order = { "StateController", "HUDController", "LobbyController", "SprintController" }

for _, name in order do
	local controller = require(Controllers[name]) :: any
	task.spawn(controller.start)
end
