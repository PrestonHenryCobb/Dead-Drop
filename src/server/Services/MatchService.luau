--!strict
-- The round loop and objectives.
--
-- Lobby -> Insertion -> Infiltration -> Extraction -> PostRound -> Lobby
--
-- Lobby:        players pick a class and ready up. Starts when MinPlayers are ready.
-- Insertion:    ready players are dropped into the map disguised as civilians.
-- Infiltration: hack IntelTerminals for intel. Anyone with IntelToOpenVault intel can open the Vault.
-- Extraction:   whoever opened the vault carries the package. Their position is pinged to everyone
--               every CarrierPingInterval seconds. Reach an ExtractionPoint to win.
--               If the carrier dies, the package drops where they fell.
-- Agents who die are out until the next round.

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Classes = require(ReplicatedStorage.Shared.Config.Classes)
local GameConfig = require(ReplicatedStorage.Shared.Config.GameConfig)
local Net = require(ReplicatedStorage.Shared.Net)
local Types = require(ReplicatedStorage.Shared.Types)
local WorldTags = require(ReplicatedStorage.Shared.Config.WorldTags)
local ClearanceService = require(script.Parent.ClearanceService)
local CoverService = require(script.Parent.CoverService)
local StateService = require(script.Parent.StateService)

type MatchPhase = Types.MatchPhase

local MatchService = {}

local phase: MatchPhase = "Lobby"
local phaseEndsAt = 0
local winner: Player? = nil
local droppedPackage: BasePart? = nil

local function notifyAll(message: string)
	Net.event("Notify"):FireAllClients(message)
end

-- duration nil means no timer (endsAt is sent as 0).
local function setPhase(newPhase: MatchPhase, duration: number?)
	phase = newPhase
	phaseEndsAt = if duration then workspace:GetServerTimeNow() + duration else 0
	workspace:SetAttribute("Phase", phase)
	workspace:SetAttribute("PhaseEndsAt", phaseEndsAt)
	Net.event("PhaseChanged"):FireAllClients(phase, phaseEndsAt)
end

function MatchService.getPhase(): MatchPhase
	return phase
end

-- Waits until the phase timer runs out or done() returns true. Returns true if done() ended it.
local function waitPhase(done: () -> boolean): boolean
	while workspace:GetServerTimeNow() < phaseEndsAt do
		if done() then
			return true
		end
		task.wait(0.25)
	end
	return done()
end

local function readyPlayers(): { Player }
	local result = {}
	for _, player in Players:GetPlayers() do
		local state = StateService.get(player)
		if state and state.Ready and state.ClassId then
			table.insert(result, player)
		end
	end
	return result
end

local function carrier(): Player?
	for _, player in StateService.playersInRound() do
		local state = StateService.get(player)
		if state and state.CarryingPackage then
			return player
		end
	end
	return nil
end

local function makePrompt(
	parent: Instance,
	actionText: string,
	objectText: string,
	holdDuration: number
): ProximityPrompt
	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = actionText
	prompt.ObjectText = objectText
	prompt.HoldDuration = holdDuration
	prompt.RequiresLineOfSight = false
	prompt.Parent = parent
	return prompt
end

local function givePackage(player: Player)
	StateService.update(player, function(s)
		s.CarryingPackage = true
	end)
	CoverService.breakCover(player, "Carrying the package")
	notifyAll(`{player.DisplayName} has the package!`)
end

-- Objectives ---------------------------------------------------------------

local function setupTerminal(terminal: Instance)
	if not terminal:IsA("BasePart") then
		return
	end
	local prompt = makePrompt(terminal, "Hack", "Intel Terminal", GameConfig.TerminalHackTime)
	prompt.Name = "TerminalPrompt"
	prompt.Triggered:Connect(function(player)
		local state = StateService.get(player)
		if phase ~= "Infiltration" or not state or not state.InRound or terminal:GetAttribute("Hacked") then
			return
		end
		terminal:SetAttribute("Hacked", true)
		terminal:SetAttribute("LastHackedBy", player.UserId) -- Tracker passive reads this
		prompt.Enabled = false
		StateService.update(player, function(s)
			s.Intel += GameConfig.IntelPerTerminal
		end)
	end)
end

local function setupVault(vault: Instance)
	if not vault:IsA("BasePart") then
		return
	end
	local prompt = makePrompt(vault, "Open Vault", "Vault", 5)
	prompt.Triggered:Connect(function(player)
		local state = StateService.get(player)
		if phase ~= "Infiltration" or not state or not state.InRound then
			return
		end
		if state.Intel < GameConfig.IntelToOpenVault then
			Net.event("Notify"):FireClient(player, `Need {GameConfig.IntelToOpenVault} intel to open the vault`)
			return
		end
		givePackage(player)
	end)
end

local function setupExtraction(point: Instance)
	if not point:IsA("BasePart") then
		return
	end
	local prompt = makePrompt(point, "Extract", "Extraction", 2)
	prompt.Triggered:Connect(function(player)
		local state = StateService.get(player)
		if phase == "Extraction" and state and state.InRound and state.CarryingPackage then
			winner = player
		end
	end)
end

local function dropPackage(position: Vector3)
	local package = Instance.new("Part")
	package.Name = "Package"
	package.Size = Vector3.new(2, 1.5, 1)
	package.Color = Color3.fromRGB(255, 215, 0)
	package.Material = Enum.Material.Neon
	package.Anchored = true
	package.CanCollide = false
	package.Position = position
	package.Parent = workspace
	droppedPackage = package

	local prompt = makePrompt(package, "Grab", "Package", 1)
	prompt.Triggered:Connect(function(player)
		local state = StateService.get(player)
		if phase == "Extraction" and state and state.InRound and package.Parent then
			package:Destroy()
			droppedPackage = nil
			givePackage(player)
		end
	end)
end

local function resetObjectives()
	for _, terminal in CollectionService:GetTagged(WorldTags.IntelTerminal) do
		terminal:SetAttribute("Hacked", false)
		local prompt = terminal:FindFirstChild("TerminalPrompt")
		if prompt and prompt:IsA("ProximityPrompt") then
			prompt.Enabled = true
		end
	end
	if droppedPackage then
		droppedPackage:Destroy()
		droppedPackage = nil
	end
	winner = nil
end

-- Players -----------------------------------------------------------------

local function eliminate(player: Player)
	local state = StateService.get(player)
	if not state or not state.InRound then
		return
	end
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if state.CarryingPackage and root then
		dropPackage(root.Position)
		notifyAll(`{player.DisplayName} dropped the package!`)
	end
	StateService.update(player, function(s)
		s.InRound = false
		s.CarryingPackage = false
		s.Disguised = false
	end)
end

local function insertPlayer(player: Player, insertionPoints: { BasePart })
	StateService.resetRound(player)
	StateService.update(player, function(s)
		s.InRound = true
	end)

	local character = player.Character or player.CharacterAdded:Wait()
	local humanoid = character:WaitForChild("Humanoid") :: Humanoid
	local state = StateService.get(player)
	local classDef = state and state.ClassId and Classes.Classes[state.ClassId]
	if classDef then
		humanoid.MaxHealth = classDef.MaxHealth
		humanoid.Health = classDef.MaxHealth
	end
	-- TODO: give the class's weapon and gadget Tools here.

	if #insertionPoints > 0 then
		local point = insertionPoints[math.random(1, #insertionPoints)]
		character:PivotTo(point.CFrame + Vector3.new(0, 3, 0))
	end
	CoverService.disguiseAsRandomCivilian(player)
end

local function onCharacterAdded(player: Player, character: Model)
	local humanoid = character:WaitForChild("Humanoid") :: Humanoid
	humanoid.Died:Connect(function()
		eliminate(player)
	end)
end

-- Round loop ---------------------------------------------------------------

local function runLobby()
	setPhase("Lobby")
	notifyAll("Pick a class and ready up")
	while true do
		task.wait(0.5)
		if #readyPlayers() >= GameConfig.MinPlayers then
			setPhase("Lobby", GameConfig.LobbyCountdown)
			local cancelled = waitPhase(function()
				return #readyPlayers() < GameConfig.MinPlayers
			end)
			if not cancelled then
				return
			end
			setPhase("Lobby")
		end
	end
end

local function runRound()
	resetObjectives()
	ClearanceService.resetRound()

	local insertionPoints = {}
	for _, point in CollectionService:GetTagged(WorldTags.InsertionPoint) do
		if point:IsA("BasePart") then
			table.insert(insertionPoints, point)
		end
	end

	local participants = readyPlayers()
	-- With one player (solo testing) the round runs until the timer; otherwise last one standing ends it.
	local function lastStanding(): boolean
		local alive = #StateService.playersInRound()
		return alive == 0 or (#participants > 1 and alive <= 1)
	end

	setPhase("Insertion", GameConfig.InsertionTime)
	for _, player in participants do
		task.spawn(insertPlayer, player, insertionPoints)
	end
	waitPhase(function()
		return false
	end)

	setPhase("Infiltration", GameConfig.InfiltrationTime)
	local vaultOpened = waitPhase(function()
		return carrier() ~= nil or lastStanding()
	end)

	if vaultOpened and carrier() then
		setPhase("Extraction", GameConfig.ExtractionTime)
		local lastPing = 0
		waitPhase(function()
			local current = carrier()
			if current and os.clock() - lastPing >= GameConfig.CarrierPingInterval then
				lastPing = os.clock()
				local root = current.Character and current.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
				if root then
					for _, other in Players:GetPlayers() do
						if other ~= current then
							Net.event("CarrierPing"):FireClient(other, root.Position)
						end
					end
				end
			end
			return winner ~= nil or #StateService.playersInRound() == 0
		end)
	end

	-- Last agent standing also wins.
	if not winner and #participants > 1 then
		local remaining = StateService.playersInRound()
		if #remaining == 1 then
			winner = remaining[1]
		end
	end

	setPhase("PostRound", GameConfig.PostRoundTime)
	notifyAll(if winner then `{winner.DisplayName} wins!` else "Nobody extracted. Mission failed.")
	waitPhase(function()
		return false
	end)

	for _, player in Players:GetPlayers() do
		StateService.resetRound(player)
		task.spawn(player.LoadCharacter, player)
	end
end

function MatchService.init()
	for _, terminal in CollectionService:GetTagged(WorldTags.IntelTerminal) do
		setupTerminal(terminal)
	end
	for _, vault in CollectionService:GetTagged(WorldTags.Vault) do
		setupVault(vault)
	end
	for _, point in CollectionService:GetTagged(WorldTags.ExtractionPoint) do
		setupExtraction(point)
	end

	Net.event("SelectClass").OnServerEvent:Connect(function(player, classId)
		if phase ~= "Lobby" or typeof(classId) ~= "string" or not Classes.Classes[classId] then
			return
		end
		StateService.update(player, function(s)
			s.ClassId = classId :: Types.ClassId
		end)
	end)

	Net.event("SetReady").OnServerEvent:Connect(function(player, ready)
		if typeof(ready) ~= "boolean" then
			return
		end
		StateService.update(player, function(s)
			s.Ready = ready and s.ClassId ~= nil
		end)
	end)

	local function onPlayer(player: Player)
		Net.event("PhaseChanged"):FireClient(player, phase, phaseEndsAt)
		if player.Character then
			task.spawn(onCharacterAdded, player, player.Character)
		end
		player.CharacterAdded:Connect(function(character)
			onCharacterAdded(player, character)
		end)
	end
	Players.PlayerAdded:Connect(onPlayer)
	for _, player in Players:GetPlayers() do
		onPlayer(player)
	end
	Players.PlayerRemoving:Connect(eliminate)
end

function MatchService.start()
	while true do
		runLobby()
		runRound()
	end
end

return MatchService
