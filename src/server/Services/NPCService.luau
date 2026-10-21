--!strict
-- The crowd.
--
-- Every model tagged CrowdNPC wanders between WanderNode parts of its own Tier, pauses, and repeats.
-- NPCs walk at exactly the disguised player walk speed so a disguised agent moving normally is
-- indistinguishable from the crowd. Do not change one without the other.

local CollectionService = game:GetService("CollectionService")
local PathfindingService = game:GetService("PathfindingService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage.Shared.Config.GameConfig)
local WorldTags = require(ReplicatedStorage.Shared.Config.WorldTags)

local IDLE_MIN, IDLE_MAX = 2, 7
local MOVE_TIMEOUT = 6

local NPCService = {}

local function nodesForTier(tier: number): { BasePart }
	local matching, all = {}, {}
	for _, node in CollectionService:GetTagged(WorldTags.WanderNode) do
		if node:IsA("BasePart") then
			table.insert(all, node)
			if (node:GetAttribute("Tier") or 0) == tier then
				table.insert(matching, node)
			end
		end
	end
	return if #matching > 0 then matching else all
end

local function walkTo(humanoid: Humanoid, root: BasePart, target: Vector3)
	local path = PathfindingService:CreatePath({ AgentRadius = 2, AgentHeight = 5, AgentCanJump = false })
	local ok = pcall(function()
		path:ComputeAsync(root.Position, target)
	end)
	if not ok or path.Status ~= Enum.PathStatus.Success then
		return
	end
	for _, waypoint in path:GetWaypoints() do
		if humanoid.Health <= 0 then
			return
		end
		humanoid:MoveTo(waypoint.Position)
		local reached = false
		local connection = humanoid.MoveToFinished:Connect(function(success)
			reached = success
		end)
		local started = os.clock()
		while not reached and os.clock() - started < MOVE_TIMEOUT do
			task.wait(0.1)
		end
		connection:Disconnect()
		if not reached then
			return
		end
	end
end

local function runNpc(npc: Instance)
	if not npc:IsA("Model") then
		return
	end
	local humanoid = npc:FindFirstChildOfClass("Humanoid")
	local root = npc:FindFirstChild("HumanoidRootPart")
	if not humanoid or not root or not root:IsA("BasePart") then
		warn(`[NPCService] {npc:GetFullName()} needs a Humanoid and HumanoidRootPart`)
		return
	end

	-- Save the NPC's look so CoverService can copy it reliably.
	if not npc:FindFirstChild("Look") then
		local look = humanoid:GetAppliedDescription()
		look.Name = "Look"
		look.Parent = npc
	end

	humanoid.WalkSpeed = GameConfig.WalkSpeedDisguised
	pcall(root.SetNetworkOwner, root, nil)

	local tier = npc:GetAttribute("Tier") or 0
	-- Stagger start times so the crowd doesn't move in lockstep.
	task.wait(math.random() * IDLE_MAX)

	while npc.Parent and humanoid.Health > 0 do
		local nodes = nodesForTier(tier)
		if #nodes > 0 then
			local node = nodes[math.random(1, #nodes)]
			local offset = Vector3.new(math.random(-3, 3), 0, math.random(-3, 3))
			walkTo(humanoid, root, node.Position + offset)
		end
		-- TODO: play an idle animation here (phone, coffee, look around).
		task.wait(IDLE_MIN + math.random() * (IDLE_MAX - IDLE_MIN))
	end
end

function NPCService.start()
	for _, npc in CollectionService:GetTagged(WorldTags.CrowdNPC) do
		task.spawn(runNpc, npc)
	end
	CollectionService:GetInstanceAddedSignal(WorldTags.CrowdNPC):Connect(runNpc)
end

return NPCService
