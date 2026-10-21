--!strict
-- Shared type definitions used by both server and client. Update docs/CONTRACTS.md when they change.

export type MatchPhase = "Lobby" | "Insertion" | "Infiltration" | "Extraction" | "PostRound"

export type ClassId = "Vanguard" | "Tracker" | "Scoundrel" | "Technocrat"

-- 0 Civilian, 1 Staff, 2 Guard, 3 Technician, 4 VIP (see Config/Clearance.luau)
export type Tier = number

export type PlayerState = {
	ClassId: ClassId?,
	Ready: boolean,
	InRound: boolean,
	-- Disguise
	Disguised: boolean,
	DisguiseTier: Tier,
	Suspicion: number, -- 0..100, cover breaks at 100
	CoverCooldownUntil: number, -- os.clock() time when the player can disguise again
	-- Objectives
	Intel: number,
	CarryingPackage: boolean,
	-- In-round progression (cleared every round)
	Keycards: { [Tier]: boolean },
	Upgrades: { string },
}

return nil
