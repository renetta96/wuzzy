local assets = {
  Asset("ANIM", "anim/zeta.zip"),
  Asset("ANIM", "anim/ghost_zeta_build.zip")
}

local skins = {
  normal_skin = "zeta",
  ghost_skin = "ghost_zeta_build"
}

return CreatePrefabSkin(
  "zeta_none",
  {
    base_prefab = "zeta",
    build_name_override = "zeta",
    type = "base",
    rarity = "Character",
    skins = skins,
    assets = assets,
    skin_tags = {"BASE", "ZETA"},
    skip_item_gen = true,
    skip_giftable_gen = true
  }
)
