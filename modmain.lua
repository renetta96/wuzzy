PrefabFiles = {
	"mutantbeecocoon",
	"mutantbee",
	"mutantbeehive",
	"honeyspill",
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
	Asset( "IMAGE", "images/map_icons/mutantbeecocoon.tex" ),
	Asset( "ATLAS", "images/map_icons/mutantbeecocoon.xml" ),
	
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
TUNING.OZZY_MAX_HEALTH = 125
TUNING.OZZY_MAX_SANITY = 100
TUNING.OZZY_MAX_HUNGER = 100
TUNING.OZZY_DEFAULT_DAMAGE_MULTIPLIER = 0.75
TUNING.OZZY_HUNGER_SCALE = 1.2
TUNING.OZZY_NUM_PETALS_PER_HONEY = 5
TUNING.OZZY_SHARE_TARGET_DIST = 30
TUNING.OZZY_MAX_SHARE_TARGETS = 20
TUNING.OZZY_DEFAUT_SPEED_MULTIPLIER = 1.0
TUNING.OZZY_SPRING_SPEED_MULTIPLIER = 1.15
TUNING.OZZY_WINTER_SPEED_MULTIPLIER = 0.85
TUNING.OZZY_MAX_SUMMON_BEES = 4
TUNING.OZZY_SUMMON_CHANCE = 0.3

-- Mutant bee stats
TUNING.MUTANT_BEE_HEALTH = 100
TUNING.MUTANT_BEE_DAMAGE = 10
TUNING.MUTANT_BEE_ATTACK_PERIOD = 1
TUNING.MUTANT_BEE_TARGET_DIST = 8
TUNING.MUTANT_BEE_MAX_POISON_TICKS = 5
TUNING.MUTANT_BEE_POISON_DAMAGE = -5
TUNING.MUTANT_BEE_POISON_PERIOD = 0.75
TUNING.MUTANT_BEE_EXPLOSIVE_DAMAGE_MULTIPLIER = 2.0
TUNING.MUTANT_BEE_EXPLOSIVE_RANGE = 3
TUNING.MUTANT_BEE_FROSTBITE_SPEED_PENALTY = 0.5
TUNING.MUTANT_BEE_FROSTBITE_ATK_PERIOD_PENALTY = 1.65
TUNING.MUTANT_BEE_WEAPON_ATK_RANGE = 10
TUNING.MUTANT_BEE_RANGED_TARGET_DIST = 10
TUNING.MUTANT_BEE_RANGED_ATK_HEALTH_PENALTY = 1 / 10
TUNING.MUTANT_BEE_RANGED_DAMAGE = 15
TUNING.MUTANT_BEE_RANGED_ATK_PERIOD = 2.5

-- Mutant beehive stats
TUNING.MUTANT_BEEHIVE_EMERGENCY_BEES = 6
TUNING.MUTANT_BEEHIVE_EMERGENCY_BEES_PER_PLAYER = 1
TUNING.MUTANT_BEEHIVE_EMERGENCY_RADIUS = 20
TUNING.MUTANT_BEEHIVE_DEFAULT_BEES = 4
TUNING.MUTANT_BEEHIVE_DEFAULT_RELEASE_TIME = 50
TUNING.MUTANT_BEEHIVE_DEFAULT_REGEN_TIME = 30
TUNING.MUTANT_BEEHIVE_DELTA_BEES = 1
TUNING.MUTANT_BEEHIVE_DELTA_RELEASE_TIME = 5
TUNING.MUTANT_BEEHIVE_DELTA_REGEN_TIME = 5
TUNING.MUTANT_BEEHIVE_UPGRADES_PER_STAGE = 3
TUNING.MUTANT_BEEHIVE_WATCH_DIST = 20
TUNING.MUTANT_BEEHIVE_RECOVER_PER_CHILD = 0.75
TUNING.MUTANT_BEEHIVE_GROW_TIME = {TUNING.TOTAL_DAY_TIME * 10, TUNING.TOTAL_DAY_TIME * 10}

-- The character select screen lines
STRINGS.CHARACTER_TITLES.zeta = "The Buzzy"
STRINGS.CHARACTER_NAMES.zeta = "Ozzy"
STRINGS.CHARACTER_DESCRIPTIONS.zeta = "*Is a bee\n*Has his own beehive\n*Can produce honey by eating petals"
STRINGS.CHARACTER_QUOTES.zeta = "\"Let's beefriend !\""

-- Custom speech strings
STRINGS.CHARACTERS.ZETA = require "speech_zeta"

-- The character's name as appears in-game 
STRINGS.NAMES.ZETA = "Ozzy"

AddMinimapAtlas("images/map_icons/zeta.xml")
AddMinimapAtlas("images/map_icons/mutantbeecocoon.xml")

-- Add mod character to mod character list. Also specify a gender. Possible genders are MALE, FEMALE, ROBOT, NEUTRAL, and PLURAL.
AddModCharacter("zeta", "MALE")

local function MakeHoneycombUpgrader(prefab)
	if not prefab.components.upgrader then
		prefab:AddComponent("upgrader")		
	end
end

AddPrefabPostInit("honeycomb", MakeHoneycombUpgrader)
