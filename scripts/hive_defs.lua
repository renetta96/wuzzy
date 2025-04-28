local HiveDefs = {
	{
		hive_prefab = "mutantdefenderhive",
		hive_tag = "mutantdefenderhive",
		minion_prefab = "mutantdefenderbee",
		token_prefab = "mutantdefenderbee_token"
	},
	{
		hive_prefab = "mutantrangerhive",
		hive_tag = "mutantrangerhive",
		minion_prefab = "mutantrangerbee",
		token_prefab = "mutantrangerbee_token"
	},
	{
		hive_prefab = "mutantassassinhive",
		hive_tag = "mutantassassinhive",
		minion_prefab = "mutantassassinbee",
		token_prefab = "mutantassassinbee_token"
	},
	{
		hive_prefab = "mutantshadowhive",
		hive_tag = "mutantshadowhive",
		minion_prefab = "mutantshadowbee",
		token_prefab = "mutantshadowbee_token"
	},
	{
		hive_prefab = "mutanthealerhive",
		hive_tag = "mutanthealerhive",
		minion_prefab = "mutanthealerbee",
		token_prefab = "mutanthealerbee_token"
	},
}

local function GetDefByTokenPrefab(prefab)
	for i, def in ipairs(HiveDefs) do
		if def.token_prefab == prefab then
			return def
		end
	end

	return nil
end

return {
	HiveDefs = HiveDefs,
	GetDefByTokenPrefab = GetDefByTokenPrefab,
}
