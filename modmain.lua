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
TUNING.FRANZ_MAX_HEALTH = 175
TUNING.FRANZ_MAX_SANITY = 100
TUNING.FRANZ_MAX_HUNGER = 100
TUNING.FRANZ_VIRUS_DAMAGE = -5
TUNING.FRANZ_MAX_VIRUS_TICKS = 5
TUNING.FRANZ_VIRUS_PERIOD = 0.75
TUNING.FRANZ_DEFAULT_DAMAGE_MULTIPLIER = 0.85
TUNING.FRANZ_BONUS_DAMAGE_MULTIPLIER = 1.5
TUNING.FRANZ_HUNGER_SCALE = 1.6
TUNING.FRANZ_DEFAUT_SPEED_MULTIPLIER = 0.85
TUNING.FRANZ_BONUS_SPEED_MULTIPLIER = 0.75

-- The character select screen lines
STRINGS.CHARACTER_TITLES.zeta = "The Rot"
STRINGS.CHARACTER_NAMES.zeta = "Franz"
STRINGS.CHARACTER_DESCRIPTIONS.zeta = "*Is a decaying zombie, only eats meat\n*Infects deadly virus on attack\n*Becomes berserk at low hunger"
STRINGS.CHARACTER_QUOTES.zeta = "\"How did I become like this ?\""

-- Custom speech strings
STRINGS.CHARACTERS.ZETA = require "speech_zeta"

-- The character's name as appears in-game 
STRINGS.NAMES.ZETA = "Franz"

AddMinimapAtlas("images/map_icons/zeta.xml")

-- Add mod character to mod character list. Also specify a gender. Possible genders are MALE, FEMALE, ROBOT, NEUTRAL, and PLURAL.
AddModCharacter("zeta", "MALE")

