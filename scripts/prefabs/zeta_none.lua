local assets =
{
	Asset( "ANIM", "anim/zeta.zip" ),
	Asset( "ANIM", "anim/ghost_zeta_build.zip" ),
}

local skins =
{
	normal_skin = "zeta",
	ghost_skin = "ghost_zeta_build",
}

local base_prefab = "zeta"

local tags = {"ZETA", "CHARACTER"}

return CreatePrefabSkin("zeta_none",
{
	base_prefab = base_prefab,
	skins = skins,
	assets = assets,
	tags = tags,

	skip_item_gen = true,
	skip_giftable_gen = true,
})