-- REIGN_OF_GIANTS
-- CAPY_DLC
-- PORKLAND_DLC
local function CheckDlcEnabled(dlc)
	-- if the constant doesn't even exist, then they can't have the DLC
	if not rawget(_G, dlc) then return false end
	assert(rawget(_G, "IsDLCEnabled"), "Old version of game, please update (IsDLCEnabled function missing)")
	return IsDLCEnabled(_G[dlc])
end

local function GetCombatCooldown(inst)
	local combat = inst.components.combat
	return combat.laststartattacktime ~= nil
		and math.max(
			0,
			combat.min_attack_period
			+ (combat:GetPeriodModifier() * combat.min_attack_period)
			- GetTime() + combat.laststartattacktime)
		or 0
end

return {
	CheckDlcEnabled = CheckDlcEnabled,
	GetCombatCooldown = GetCombatCooldown
}