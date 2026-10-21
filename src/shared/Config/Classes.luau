--!strict
-- Launch roster: four classes, one per playstyle. Add new classes here; the lobby UI reads this table.

export type ClassDef = {
	Id: string,
	DisplayName: string,
	Role: string,
	Description: string,
	MaxHealth: number,
	Weapon: string,
	Gadget: string,
	Passive: string,
}

local Classes: { [string]: ClassDef } = {
	Vanguard = {
		Id = "Vanguard",
		DisplayName = "The Vanguard",
		Role = "Frontline",
		Description = "Takes hits and wins fights once cover is blown.",
		MaxHealth = 150,
		Weapon = "Shotgun",
		Gadget = "Holoshield", -- deployable wall that blocks shots for 6s
		Passive = "Armor plating regenerates out of combat",
	},
	Tracker = {
		Id = "Tracker",
		DisplayName = "The Tracker",
		Role = "Intel",
		Description = "Finds intel fast and sees who has been touching it.",
		MaxHealth = 100,
		Weapon = "Rifle",
		Gadget = "Scanner", -- pings nearby terminals, safes and keycards
		Passive = "Sees the last agent to hack a terminal for 10s",
	},
	Scoundrel = {
		Id = "Scoundrel",
		DisplayName = "The Scoundrel",
		Role = "Evasion",
		Description = "Slippery. Best at keeping a disguise and escaping when it breaks.",
		MaxHealth = 90,
		Weapon = "Pistol",
		Gadget = "Decoy", -- spawns a fake copy of your current disguise that walks away
		Passive = "Suspicion builds 25% slower",
	},
	Technocrat = {
		Id = "Technocrat",
		DisplayName = "The Technocrat",
		Role = "Control",
		Description = "Locks down areas with cameras and door overrides.",
		MaxHealth = 100,
		Weapon = "SMG",
		Gadget = "Camera", -- placeable camera that marks agents who break cover nearby
		Passive = "Can hack clearance doors one tier above their disguise",
	},
}

local Order = { "Vanguard", "Tracker", "Scoundrel", "Technocrat" }

return {
	Classes = Classes,
	Order = Order,
}
