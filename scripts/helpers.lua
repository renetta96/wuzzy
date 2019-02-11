local function CheckDlcEnabled(dlc)
	-- if the constant doesn't even exist, then they can't have the DLC
	if not rawget(_G, dlc) then return false end
	assert(rawget(_G, "IsDLCEnabled"), "Old version of game, please update (IsDLCEnabled function missing)")
	return IsDLCEnabled(_G[dlc])
end

return {
	CheckDlcEnabled = CheckDlcEnabled
}