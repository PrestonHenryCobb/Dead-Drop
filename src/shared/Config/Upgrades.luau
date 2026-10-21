--!strict
-- Upgrade cards found inside safes. They last for the current round only.
-- Higher-tier safes roll from better pools.

export type UpgradeDef = {
	Id: string,
	Name: string,
	Description: string,
	MinSafeTier: number,
}

local Upgrades: { UpgradeDef } = {
	{ Id = "QuickHands", Name = "Quick Hands", Description = "Hack terminals 30% faster.", MinSafeTier = 1 },
	{ Id = "Padding", Name = "Padding", Description = "+20 max health.", MinSafeTier = 1 },
	{ Id = "LightStep", Name = "Light Step", Description = "Sprinting builds suspicion 30% slower.", MinSafeTier = 1 },
	{ Id = "ExtraGadget", Name = "Spare Gadget", Description = "+1 gadget charge.", MinSafeTier = 2 },
	{ Id = "CoolHead", Name = "Cool Head", Description = "Cover-break cooldown halved.", MinSafeTier = 2 },
	{ Id = "Ghost", Name = "Ghost", Description = "Trespassing builds suspicion 50% slower.", MinSafeTier = 3 },
	{ Id = "Overclock", Name = "Overclock", Description = "Gadget cooldowns 40% shorter.", MinSafeTier = 3 },
	{ Id = "MasterKey", Name = "Master Key", Description = "Treated as one clearance tier higher.", MinSafeTier = 4 },
}

local module = { All = Upgrades }

-- Picks a random upgrade the safe tier can drop, skipping ones the player already has.
function module.roll(safeTier: number, owned: { string }): UpgradeDef?
	local pool = {}
	for _, upgrade in Upgrades do
		if upgrade.MinSafeTier <= safeTier and not table.find(owned, upgrade.Id) then
			table.insert(pool, upgrade)
		end
	end
	if #pool == 0 then
		return nil
	end
	return pool[math.random(1, #pool)]
end

return module
