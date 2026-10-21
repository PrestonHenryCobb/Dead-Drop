--!strict
-- Security tiers. A disguise of tier N opens doors and zones of tier <= N.
-- A keycard of tier N opens safes of exactly tier N (and doors of tier <= N).

export type TierInfo = {
	Id: number,
	Name: string,
	Color: Color3,
}

local Clearance: { TierInfo } = {
	{ Id = 0, Name = "Civilian", Color = Color3.fromRGB(200, 200, 200) },
	{ Id = 1, Name = "Staff", Color = Color3.fromRGB(80, 170, 255) },
	{ Id = 2, Name = "Guard", Color = Color3.fromRGB(255, 200, 60) },
	{ Id = 3, Name = "Technician", Color = Color3.fromRGB(255, 120, 40) },
	{ Id = 4, Name = "VIP", Color = Color3.fromRGB(200, 70, 255) },
}

local byId: { [number]: TierInfo } = {}
for _, info in Clearance do
	byId[info.Id] = info
end

local module = {
	Tiers = Clearance,
	MaxTier = 4,
}

function module.get(tier: number): TierInfo
	return byId[tier] or byId[0]
end

return module
