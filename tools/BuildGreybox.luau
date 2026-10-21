--!strict
-- Builds the day-one greybox test map into Workspace.Greybox.
--
-- How to run: in Roblox Studio, open View > Command Bar, paste this whole file, press Enter.
-- Then File > Save (or Publish). Running it again deletes and rebuilds Workspace.Greybox.
--
-- Layout (top-down, +X is east):
--
--   [ Lobby ]          [ Main hall: tier 0              ][ Staff room: tier 1 ]
--   spawn here         insertion points, civilians,      door, 2 staff NPCs,
--   (sealed room)      3 terminals, vault, extraction,   safe, terminal,
--                      tier-1 keycard                    tier-2 keycard

local ChangeHistoryService = game:GetService("ChangeHistoryService")
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")

local WALL_HEIGHT = 14
local GREY = Color3.fromRGB(163, 162, 165)

local old = workspace:FindFirstChild("Greybox")
if old then
	old:Destroy()
end

local root = Instance.new("Folder")
root.Name = "Greybox"
root.Parent = workspace

local function folder(name: string): Folder
	local f = Instance.new("Folder")
	f.Name = name
	f.Parent = root
	return f
end

local geometry = folder("Geometry")
local markers = folder("Markers")
local objectives = folder("Objectives")
local npcs = folder("NPCs")

local function part(parent: Instance, name: string, size: Vector3, position: Vector3, color: Color3?): Part
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.Position = position
	p.Anchored = true
	p.Color = color or GREY
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Parent = parent
	return p
end

local function tag(instance: Instance, tagName: string, attributes: { [string]: any }?)
	CollectionService:AddTag(instance, tagName)
	for key, value in attributes or {} do
		instance:SetAttribute(key, value)
	end
end

-- Invisible, non-colliding helper part (nodes, spawns, zones).
local function marker(name: string, size: Vector3, position: Vector3): Part
	local p = part(markers, name, size, position)
	p.Transparency = 1
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	return p
end

-- Wall from (x1, z1) to (x2, z2); must be axis-aligned.
local function wall(x1: number, z1: number, x2: number, z2: number)
	local size = Vector3.new(math.max(math.abs(x2 - x1), 1), WALL_HEIGHT, math.max(math.abs(z2 - z1), 1))
	part(geometry, "Wall", size, Vector3.new((x1 + x2) / 2, WALL_HEIGHT / 2, (z1 + z2) / 2))
end

local function floor(name: string, x1: number, z1: number, x2: number, z2: number, color: Color3)
	part(
		geometry,
		name,
		Vector3.new(math.abs(x2 - x1), 1, math.abs(z2 - z1)),
		Vector3.new((x1 + x2) / 2, 0.5, (z1 + z2) / 2),
		color
	)
end

-- Lobby: sealed room to the west ------------------------------------------------

floor("LobbyFloor", -130, -20, -90, 20, Color3.fromRGB(90, 90, 110))
wall(-130, -20, -90, -20)
wall(-130, 20, -90, 20)
wall(-130, -20, -130, 20)
wall(-90, -20, -90, 20)

local spawn = Instance.new("SpawnLocation")
spawn.Name = "LobbySpawn"
spawn.Size = Vector3.new(8, 1, 8)
spawn.Position = Vector3.new(-110, 1.5, 0)
spawn.Anchored = true
spawn.Neutral = true
spawn.Duration = 0 -- no spawn forcefield
spawn.Parent = geometry

-- Any other spawn (e.g. the Baseplate template's) would put players outside the lobby.
for _, other in workspace:GetDescendants() do
	if other:IsA("SpawnLocation") and other ~= spawn and other.Enabled then
		other.Enabled = false
		print(`[Greybox] Disabled other spawn: {other:GetFullName()}`)
	end
end

-- Main hall (tier 0): x -40..40, z -30..30 -------------------------------------

floor("HallFloor", -40, -30, 40, 30, Color3.fromRGB(120, 120, 120))
wall(-40, -30, 40, -30)
wall(-40, 30, 40, 30)
wall(-40, -30, -40, 30)
-- East wall with a 6-stud doorway at z -3..3
wall(40, -30, 40, -3)
wall(40, 3, 40, 30)
part(geometry, "Lintel", Vector3.new(1, WALL_HEIGHT - 10, 6), Vector3.new(40, 10 + (WALL_HEIGHT - 10) / 2, 0))

for i, pos in { Vector3.new(-30, 1.5, -20), Vector3.new(-30, 1.5, 0), Vector3.new(-30, 1.5, 20) } do
	tag(marker(`InsertionPoint{i}`, Vector3.new(4, 1, 4), pos), "InsertionPoint")
end

for i, pos in
	{
		Vector3.new(-15, 1, -15),
		Vector3.new(-15, 1, 15),
		Vector3.new(15, 1, -15),
		Vector3.new(15, 1, 15),
		Vector3.new(0, 1, 0),
	}
do
	tag(marker(`WanderNode0_{i}`, Vector3.new(1, 1, 1), pos), "WanderNode", { Tier = 0 })
end

tag(marker("KeycardSpawn_T1", Vector3.new(1, 1, 1), Vector3.new(-35, 3, 25)), "KeycardSpawn", { Tier = 1 })

local TERMINAL_COLOR = Color3.fromRGB(40, 200, 255)
tag(part(objectives, "Terminal1", Vector3.new(3, 5, 1), Vector3.new(-20, 3.5, -29), TERMINAL_COLOR), "IntelTerminal")
tag(part(objectives, "Terminal2", Vector3.new(3, 5, 1), Vector3.new(20, 3.5, 29), TERMINAL_COLOR), "IntelTerminal")

tag(part(objectives, "Vault", Vector3.new(8, 10, 2), Vector3.new(0, 6, 29), Color3.fromRGB(60, 60, 60)), "Vault")

local extraction =
	part(objectives, "Extraction", Vector3.new(8, 1, 8), Vector3.new(-30, 1.5, -25), Color3.fromRGB(0, 200, 90))
extraction.Material = Enum.Material.Neon
tag(extraction, "ExtractionPoint")

-- Staff room (tier 1): x 40..70, z -15..15 -------------------------------------

floor("StaffFloor", 40, -15, 70, 15, Color3.fromRGB(80, 120, 170))
wall(40, -15, 70, -15)
wall(40, 15, 70, 15)
wall(70, -15, 70, 15)

local door = part(geometry, "StaffDoor", Vector3.new(1, 10, 6), Vector3.new(40, 6, 0), Color3.fromRGB(80, 170, 255))
tag(door, "ClearanceDoor", { RequiredTier = 1 })

local zone = marker("StaffZone", Vector3.new(29, WALL_HEIGHT, 29), Vector3.new(55.5, WALL_HEIGHT / 2, 0))
tag(zone, "ClearanceZone", { RequiredTier = 1 })

for i, pos in { Vector3.new(50, 1, -8), Vector3.new(62, 1, 8) } do
	tag(marker(`WanderNode1_{i}`, Vector3.new(1, 1, 1), pos), "WanderNode", { Tier = 1 })
end

tag(
	part(objectives, "Safe_T1", Vector3.new(3, 4, 3), Vector3.new(67, 3, -12), Color3.fromRGB(80, 170, 255)),
	"Safe",
	{ Tier = 1 }
)
tag(part(objectives, "Terminal3", Vector3.new(3, 5, 1), Vector3.new(60, 3.5, 14), TERMINAL_COLOR), "IntelTerminal")
tag(marker("KeycardSpawn_T2", Vector3.new(1, 1, 1), Vector3.new(67, 3, 12)), "KeycardSpawn", { Tier = 2 })

-- NPCs ---------------------------------------------------------------------------
-- Uniform torso colors per tier so disguises are readable; skin and legs vary.

local SKIN = {
	Color3.fromRGB(255, 220, 185),
	Color3.fromRGB(234, 184, 146),
	Color3.fromRGB(198, 134, 66),
	Color3.fromRGB(141, 85, 36),
	Color3.fromRGB(90, 56, 37),
}
local CIVILIAN_SHIRTS = {
	Color3.fromRGB(200, 60, 60),
	Color3.fromRGB(60, 160, 80),
	Color3.fromRGB(230, 200, 80),
	Color3.fromRGB(150, 90, 200),
	Color3.fromRGB(240, 240, 240),
}
local TIER_UNIFORM = { [1] = Color3.fromRGB(80, 170, 255) }

local function pick<T>(list: { T }): T
	return list[math.random(1, #list)]
end

local function spawnNpc(name: string, tier: number, position: Vector3)
	local look = Instance.new("HumanoidDescription")
	local skin = pick(SKIN)
	look.HeadColor = skin
	look.LeftArmColor = skin
	look.RightArmColor = skin
	look.TorsoColor = TIER_UNIFORM[tier] or pick(CIVILIAN_SHIRTS)
	local legs = if tier > 0 then Color3.fromRGB(40, 40, 50) else pick(CIVILIAN_SHIRTS)
	look.LeftLegColor = legs
	look.RightLegColor = legs

	local ok, model = pcall(function()
		return Players:CreateHumanoidModelFromDescription(look, Enum.HumanoidRigType.R15)
	end)
	if not ok or not model then
		warn(`[Greybox] Could not create NPC {name}: {model}`)
		return
	end
	model.Name = name
	model:PivotTo(CFrame.new(position + Vector3.new(0, 3, 0)))
	look.Name = "Look"
	look.Parent = model
	tag(model, "CrowdNPC", { Tier = tier })
	model.Parent = npcs
end

for i = 1, 5 do
	spawnNpc(`Civilian{i}`, 0, Vector3.new(math.random(-20, 20), 1, math.random(-20, 20)))
end
spawnNpc("Staff1", 1, Vector3.new(50, 1, -5))
spawnNpc("Staff2", 1, Vector3.new(60, 1, 5))

ChangeHistoryService:SetWaypoint("Build greybox")
print("[Greybox] Built. Remember to File > Save. Set MinPlayers = 1 in GameConfig to test solo.")
