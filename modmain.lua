PrefabFiles = {
	"zeta",
	"zeta_none",
}

Assets = {
    Asset( "IMAGE", "images/saveslot_portraits/zeta.tex" ),
    Asset( "ATLAS", "images/saveslot_portraits/zeta.xml" ),

    Asset( "IMAGE", "images/selectscreen_portraits/zeta.tex" ),
    Asset( "ATLAS", "images/selectscreen_portraits/zeta.xml" ),
	
    Asset( "IMAGE", "images/selectscreen_portraits/zeta_silho.tex" ),
    Asset( "ATLAS", "images/selectscreen_portraits/zeta_silho.xml" ),

    Asset( "IMAGE", "bigportraits/zeta.tex" ),
    Asset( "ATLAS", "bigportraits/zeta.xml" ),
	
	Asset( "IMAGE", "images/map_icons/zeta.tex" ),
	Asset( "ATLAS", "images/map_icons/zeta.xml" ),
	
	Asset( "IMAGE", "images/avatars/avatar_zeta.tex" ),
    Asset( "ATLAS", "images/avatars/avatar_zeta.xml" ),
	
	Asset( "IMAGE", "images/avatars/avatar_ghost_zeta.tex" ),
    Asset( "ATLAS", "images/avatars/avatar_ghost_zeta.xml" ),
	
	Asset( "IMAGE", "images/avatars/self_inspect_zeta.tex" ),
    Asset( "ATLAS", "images/avatars/self_inspect_zeta.xml" ),
	
	Asset( "IMAGE", "images/names_zeta.tex" ),
    Asset( "ATLAS", "images/names_zeta.xml" ),
	
    Asset( "IMAGE", "bigportraits/zeta_none.tex" ),
    Asset( "ATLAS", "bigportraits/zeta_none.xml" ),

}

local require = GLOBAL.require
local STRINGS = GLOBAL.STRINGS
local TUNING = GLOBAL.TUNING

-- Stats
TUNING.ATEZAROTH_MAX_HEALTH = 175
TUNING.ATEZAROTH_MAX_SANITY = 150
TUNING.ATEZAROTH_MAX_HUNGER = 200
TUNING.ATEZAROTH_BLOODLUST_THRESHOLD_1 = 25
TUNING.ATEZAROTH_BLOODLUST_THRESHOLD_2 = 50
TUNING.ATEZAROTH_MAX_TOUGHNESS = 0.6

-- The character select screen lines
STRINGS.CHARACTER_TITLES.zeta = "The Hollow Walker"
STRINGS.CHARACTER_NAMES.zeta = "Atezaroth"
STRINGS.CHARACTER_DESCRIPTIONS.zeta = "*Is a decaying Undead\n*Get angry when hunger\n*Become tougher every time come back from death"
STRINGS.CHARACTER_QUOTES.zeta = "\"Every man lives. Not every man truly dies.\""

-- Custom speech strings
STRINGS.CHARACTERS.ZETA = require "speech_zeta"

-- The character's name as appears in-game 
STRINGS.NAMES.ZETA = "Atezaroth"

AddMinimapAtlas("images/map_icons/zeta.xml")

-- Add mod character to mod character list. Also specify a gender. Possible genders are MALE, FEMALE, ROBOT, NEUTRAL, and PLURAL.
AddModCharacter("zeta", "MALE")

