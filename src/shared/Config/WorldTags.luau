--!strict
-- CollectionService tags that Dev 3 puts on parts/models in Studio and Dev 1's services look for.
-- Use the Tag Editor in Studio (View > Tags). Each tag lists the attributes it expects.

return {
	-- Models with a Humanoid. Attributes: Tier (number). Optional child HumanoidDescription named "Look".
	CrowdNPC = "CrowdNPC",
	-- Invisible parts NPCs walk between. Attributes: Tier (number), so guards stay in guard areas.
	WanderNode = "WanderNode",
	-- Invisible, non-colliding volumes. Attributes: RequiredTier (number). Being inside one
	-- with a lower disguise tier builds suspicion.
	ClearanceZone = "ClearanceZone",
	-- Door parts. Attributes: RequiredTier (number).
	ClearanceDoor = "ClearanceDoor",
	-- Where a keycard appears at round start. Attributes: Tier (number, 1-4).
	KeycardSpawn = "KeycardSpawn",
	-- Safe parts. Attributes: Tier (number, 1-4). Needs the matching keycard.
	Safe = "Safe",
	-- Terminal parts that give intel when hacked.
	IntelTerminal = "IntelTerminal",
	-- The vault part. Opening it starts Extraction.
	Vault = "Vault",
	-- Parts where the package carrier can extract.
	ExtractionPoint = "ExtractionPoint",
	-- Parts where agents are dropped at the start of a round.
	InsertionPoint = "InsertionPoint",
}
