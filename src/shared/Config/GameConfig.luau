--!strict
-- Tuning numbers. Designers can change these without touching gameplay code.

local GameConfig = {
	MinPlayers = 2, -- set to 1 for solo testing in Studio
	MaxPlayers = 8,

	-- Phase lengths in seconds
	LobbyCountdown = 20,
	InsertionTime = 10,
	InfiltrationTime = 8 * 60,
	ExtractionTime = 3 * 60,
	PostRoundTime = 10,

	-- Intel
	IntelPerTerminal = 1,
	IntelToOpenVault = 3,
	TerminalHackTime = 4,

	-- Disguise / suspicion
	DisguiseRange = 8,
	CoverBreakCooldown = 12,
	WalkSpeedDisguised = 12,
	WalkSpeedRevealed = 16,
	SuspicionPerSecond = {
		Sprinting = 35, -- moving faster than a disguised walk
		Airborne = 50, -- jumping / falling
		Trespassing = 25, -- inside a zone above your disguise tier
	},
	SuspicionDecayPerSecond = 15,
	SprintSpeedThreshold = 14,

	-- Extraction
	CarrierPingInterval = 5,
}

return GameConfig
