local prefabs = {} --Hornet: This is how I did my skins prefab file!, Obviously youll need to change all instances of wilba to your characters prefab name

table.insert(prefabs, CreatePrefabSkin("zeta_none", --This skin is the regular default skin we have, You should already have this
{
	base_prefab = "zeta", --What Prefab are we skinning? The character of course!
	build_name_override = "zeta",
	type = "base", --Hornet: Make sure you have this here! You should have it but ive seen some character mods with out
	rarity = "Character",
	skip_item_gen = true,
	skip_giftable_gen = true,
	skin_tags = { "BASE", "ZETA", },
	skins = {
		normal_skin = "zeta",      --These are your skin modes here, now you should have 2. But I actually have 4 for WIlba! Due to her werewilba form and transformation animation
		ghost_skin = "ghost_zeta_build",
	},
	assets = {
		Asset( "ANIM", "anim/zeta.zip" ), --Self-explanatory, these are the assets your character is using!
		Asset( "ANIM", "anim/ghost_zeta_build.zip" ),
	},

}))

table.insert(prefabs, CreatePrefabSkin("zeta_rose", --Now heres the fun part, Our skin! I did "wilba_victorian" but you can do whatever skin set you want!
{
	base_prefab = "zeta",
	build_name_override = "zeta_rose", --The build name of your new skin,
	type = "base",
	rarity = "Elegant", --I did the Elegant Rarity, but you can do whatever rarity you want!
	rarity_modifier = "Woven", --Ive put the rarity_modifier to Woven, Doesnt make a difference other than say youve woven the skin
	skip_item_gen = true,
	skip_giftable_gen = true,
	skin_tags = { "BASE", "ZETA", "ROSE"}, --Notice in this skin_tags table I have "VICTORIAN", This tag actually makes the little gorge icon show up on the skin! Other tags will do the same thing such as forge, yotc, yotp, yotv, yog and so on!
	skins = {
		normal_skin = "zeta_rose", --Rename your "normal_skin" accordingly
		
		ghost_skin = "ghost_zeta_build", --And if you did a ghost skin, rename that too!
	},

	assets = {
		Asset( "ANIM", "anim/zeta_rose.zip" ),
		Asset( "ANIM", "anim/ghost_zeta_build.zip" ),
	},

}))

--If youd like to make more skins, simply copy the CreatePrefabSkin function and accordingly make new skins you want!

return unpack(prefabs)