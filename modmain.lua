local require = GLOBAL.require
local STRINGS = GLOBAL.STRINGS
local TUNING = GLOBAL.TUNING
local Ingredient = GLOBAL.Ingredient
local TECH = GLOBAL.TECH
local SpawnPrefab = GLOBAL.SpawnPrefab
local Action = GLOBAL.Action
local SEASONS = GLOBAL.SEASONS
local RECIPETABS = GLOBAL.RECIPETABS
local SendRPCToClient = GLOBAL.SendRPCToClient
local CLIENT_RPC = GLOBAL.CLIENT_RPC
local PREFAB_SKINS = GLOBAL.PREFAB_SKINS
local PREFAB_SKINS_IDS = GLOBAL.PREFAB_SKINS_IDS
local SkillTreeDefs = require("prefabs/skilltree_defs")
local GetClosestInstWithTag = GLOBAL.GetClosestInstWithTag
local FindClosestEntity = GLOBAL.FindClosestEntity
local Vector3 = GLOBAL.Vector3

PrefabFiles = {
    "mutantworkerbee",
    "mutantsoldierbee",
    "mutantmimicbee",
    "mutantassassinbee",
    "mutantrangerbee",
    "mutantshadowbee",
    "mutantdefenderbee",
    "mutanthealerbee",
    "mutantbeehive",
    "mutantbeehive_lamp",
    "mutantchildhive",
    "mutantcontainer",
    "zeta",
    "zeta_none",
    "armor_honey",
    "melissa",
    "honey_sting_spike",
    "honey_sting_trap",
    "zetapollen",
    "pollen_fx",
    "shadowspike_fx",
    "electric_bubble",
    "healing_fx",
    "icenova_fx",
    "poison_fx",
    "metapis_buffs",
    "mutantbeetoken",
}

Assets = {
    Asset("IMAGE", "images/saveslot_portraits/zeta.tex"),
    Asset("ATLAS", "images/saveslot_portraits/zeta.xml"),
    Asset("IMAGE", "images/selectscreen_portraits/zeta.tex"),
    Asset("ATLAS", "images/selectscreen_portraits/zeta.xml"),
    Asset("IMAGE", "images/selectscreen_portraits/zeta_silho.tex"),
    Asset("ATLAS", "images/selectscreen_portraits/zeta_silho.xml"),
    Asset("IMAGE", "bigportraits/zeta.tex"),
    Asset("ATLAS", "bigportraits/zeta.xml"),
    Asset("IMAGE", "images/map_icons/zeta.tex"),
    Asset("ATLAS", "images/map_icons/zeta.xml"),
    Asset("IMAGE", "images/map_icons/mutantbeehive.tex"),
    Asset("ATLAS", "images/map_icons/mutantbeehive.xml"),
    -- Asset("IMAGE", "images/map_icons/mutantdefenderhive.tex"),
    -- Asset("ATLAS", "images/map_icons/mutantdefenderhive.xml"),
    -- Asset("IMAGE", "images/map_icons/mutantrangerhive.tex"),
    -- Asset("ATLAS", "images/map_icons/mutantrangerhive.xml"),
    -- Asset("IMAGE", "images/map_icons/mutantassassinhive.tex"),
    -- Asset("ATLAS", "images/map_icons/mutantassassinhive.xml"),
    -- Asset("IMAGE", "images/map_icons/mutantshadowhive.tex"),
    -- Asset("ATLAS", "images/map_icons/mutantshadowhive.xml"),
    -- Asset("IMAGE", "images/map_icons/mutanthealerhive.tex"),
    -- Asset("ATLAS", "images/map_icons/mutanthealerhive.xml"),
    Asset("IMAGE", "images/map_icons/mutantteleportal.tex"),
    Asset("ATLAS", "images/map_icons/mutantteleportal.xml"),
    Asset("IMAGE", "images/avatars/avatar_zeta.tex"),
    Asset("ATLAS", "images/avatars/avatar_zeta.xml"),
    Asset("IMAGE", "images/crafting_menu_avatars/avatar_zeta.tex"),
    Asset("ATLAS", "images/crafting_menu_avatars/avatar_zeta.xml"),
    Asset("IMAGE", "images/avatars/avatar_ghost_zeta.tex"),
    Asset("ATLAS", "images/avatars/avatar_ghost_zeta.xml"),
    Asset("IMAGE", "images/avatars/self_inspect_zeta.tex"),
    Asset("ATLAS", "images/avatars/self_inspect_zeta.xml"),
    Asset("IMAGE", "images/names_zeta.tex"),
    Asset("ATLAS", "images/names_zeta.xml"),
    Asset("IMAGE", "bigportraits/zeta_none.tex"),
    Asset("ATLAS", "bigportraits/zeta_none.xml"),
    Asset("SOUNDPACKAGE", "sound/zeta.fev"),
    Asset("SOUND", "sound/zeta.fsb"),
    Asset("ANIM", "anim/status_symbiosis.zip"),
    Asset("ANIM", "anim/status_meter_symbiosis.zip"),
    Asset("IMAGE", "images/inventoryimages/mutantdefenderhive.tex"),
    Asset("ATLAS", "images/inventoryimages/mutantdefenderhive.xml"),
    Asset("IMAGE", "images/inventoryimages/mutantrangerhive.tex"),
    Asset("ATLAS", "images/inventoryimages/mutantrangerhive.xml"),
    Asset("IMAGE", "images/inventoryimages/mutantassassinhive.tex"),
    Asset("ATLAS", "images/inventoryimages/mutantassassinhive.xml"),
    Asset("IMAGE", "images/inventoryimages/mutantshadowhive.tex"),
    Asset("ATLAS", "images/inventoryimages/mutantshadowhive.xml"),
    Asset("IMAGE", "images/inventoryimages/mutanthealerhive.tex"),
    Asset("ATLAS", "images/inventoryimages/mutanthealerhive.xml"),
    Asset("IMAGE", "images/inventoryimages/mutantbarrack.tex"),
    Asset("ATLAS", "images/inventoryimages/mutantbarrack.xml"),
    Asset("IMAGE", "images/inventoryimages/mutantteleportal.tex"),
    Asset("ATLAS", "images/inventoryimages/mutantteleportal.xml"),
    Asset("ATLAS", "images/inventoryimages/armor_honey.xml"),
    Asset("IMAGE", "images/inventoryimages/armor_honey.tex"),
    Asset("ATLAS", "images/inventoryimages/metapis_tab.xml"),
    Asset("IMAGE", "images/inventoryimages/metapis_tab.tex"),
    Asset("ATLAS", "images/inventoryimages/honey_sting_ball.xml"),
    Asset("IMAGE", "images/inventoryimages/honey_sting_ball.tex"),
    Asset("ATLAS", "images/inventoryimages/mutantbeehive.xml"),
    Asset("IMAGE", "images/inventoryimages/mutantbeehive.tex"),
    Asset("ATLAS", "images/inventoryimages/mutantcontainer.xml"),
    Asset("IMAGE", "images/inventoryimages/mutantcontainer.tex"),

    Asset("ATLAS", "images/skilltree_zeta.xml"),
    Asset("IMAGE", "images/skilltree_zeta.tex"),

    Asset("ATLAS", "images/skilltree_zeta_icons.xml"),
    Asset("IMAGE", "images/skilltree_zeta_icons.tex"),

    Asset("ATLAS", "images/inventoryimages/mutantbasebee_token.xml"),
    Asset("IMAGE", "images/inventoryimages/mutantbasebee_token.tex"),
    Asset("ATLAS", "images/inventoryimages/mutantdefenderbee_token.xml"),
    Asset("IMAGE", "images/inventoryimages/mutantdefenderbee_token.tex"),
    Asset("ATLAS", "images/inventoryimages/mutantrangerbee_token.xml"),
    Asset("IMAGE", "images/inventoryimages/mutantrangerbee_token.tex"),
    Asset("ATLAS", "images/inventoryimages/mutantassassinbee_token.xml"),
    Asset("IMAGE", "images/inventoryimages/mutantassassinbee_token.tex"),
    Asset("ATLAS", "images/inventoryimages/mutantshadowbee_token.xml"),
    Asset("IMAGE", "images/inventoryimages/mutantshadowbee_token.tex"),
    Asset("ATLAS", "images/inventoryimages/mutanthealerbee_token.xml"),
    Asset("IMAGE", "images/inventoryimages/mutanthealerbee_token.tex"),
}

RemapSoundEvent("dontstarve/characters/zeta/hurt", "zeta/zeta/hurt")
RemapSoundEvent("dontstarve/characters/zeta/talk_LP", "zeta/zeta/talk_LP")
RemapSoundEvent("dontstarve/characters/zeta/death_voice", "zeta/zeta/death_voice")
RemapSoundEvent("dontstarve/characters/zeta/emote", "zeta/zeta/emote") --dst
RemapSoundEvent("dontstarve/characters/zeta/pose", "zeta/zeta/pose") --dst
RemapSoundEvent("dontstarve/characters/zeta/yawn", "zeta/zeta/yawn") --dst
RemapSoundEvent("dontstarve/characters/zeta/ghost_LP", "zeta/zeta/ghost_LP") --dst

-- Stats
TUNING.ZETA_HEALTH = 175
TUNING.ZETA_SANITY = 100
TUNING.ZETA_HUNGER = 150
TUNING.ZETA_HEALTH_TYRANT = 250
TUNING.ZETA_SANITY_TYRANT = 150
TUNING.ZETA_HUNGER_TYRANT = 225
TUNING.ZETA_HEALTH_SHEPHERD = 130
TUNING.ZETA_SANITY_SHEPHERD = 75
TUNING.ZETA_HUNGER_SHEPHERD = 115

TUNING.OZZY_DEFAULT_DAMAGE_MULTIPLIER = 0.75
TUNING.OZZY_SHEPHERD_DAMAGE_MULTIPLIER = 0.6
TUNING.OZZY_TYRANT_DAMAGE_MULTIPLIER_0 = 1.05
TUNING.OZZY_TYRANT_DAMAGE_MULTIPLIER_1 = 1.15
TUNING.OZZY_TYRANT_DAMAGE_MULTIPLIER_2 = 1.3
TUNING.OZZY_TYRANT_DAMAGE_MULTIPLIER_3 = 1.5

TUNING.OZZY_HUNGER_SCALE = 1
TUNING.OZZY_NUM_POLLENS_PER_HONEY = 10
TUNING.OZZY_SPRING_SPEED_MULTIPLIER = 1.15
TUNING.OZZY_WINTER_SPEED_MULTIPLIER = 0.85
TUNING.OZZY_MAX_SUMMON_BEES = 4
TUNING.OZZY_SUMMON_CHANCE = 0.7
TUNING.OZZY_MAX_BEES_STORE = 6
TUNING.OZZY_HONEYED_FOOD_ABSORPTION = 1.25
TUNING.OZZY_NON_HONEYED_FOOD_ABSORPTION = 0.5
TUNING.OZZY_PICK_FLOWER_SANITY = -3 * TUNING.SANITY_TINY
TUNING.OZZY_TYRANT_REDIRECT_DAMAGE_MINIONS = 3
TUNING.OZZY_ENRAGE_BUFF_DURATION = 10

TUNING.GAMEMODE_STARTING_ITEMS.DEFAULT.ZETA = {
    "honeycomb",
    "honey",
    "honey",
    "honey"
}
TUNING.GAMEMODE_STARTING_ITEMS.LAVAARENA.ZETA = {}
TUNING.GAMEMODE_STARTING_ITEMS.QUAGMIRE.ZETA = {}

-- Mutant bee stats
TUNING.MUTANT_BEE_HEALTH = 100
TUNING.MUTANT_BEE_DAMAGE = 10
TUNING.MUTANT_BEE_ATTACK_PERIOD = 1.25
TUNING.MUTANT_BEE_TARGET_DIST = 8

TUNING.MUTANT_BEE_WEAPON_ATK_RANGE = 8
TUNING.MUTANT_BEE_RANGED_TARGET_DIST = 10
TUNING.MUTANT_BEE_RANGED_DAMAGE = 8
TUNING.MUTANT_BEE_RANGED_ATK_PERIOD = 3
TUNING.MUTANT_BEE_RANGED_HEALTH = 150
TUNING.MUTANT_BEE_RANGED_WISP_DAMAGE = 40

TUNING.MUTANT_BEE_DEFENDER_HEALTH = 400
TUNING.MUTANT_BEE_DEFENDER_DAMAGE = 10
TUNING.MUTANT_BEE_DEFENDER_ATTACK_PERIOD = 2
TUNING.MUTANT_BEE_DEFENDER_ATTACK_RANGE = 1.5
TUNING.MUTANT_BEE_DEFENDER_ABSORPTION = 0.5
TUNING.MUTANT_BEE_DEFENDER_TAUNT_DIST = 10
TUNING.MUTANT_BEE_DEFENDER_COLDNESS = 0.75
TUNING.MUTANT_BEE_FROSTBITE_SPEED_PENALTY = 0.5
TUNING.MUTANT_BEE_FROSTBITE_ATK_PERIOD_PENALTY = 1.25
TUNING.MUTANT_BEE_DEFENDER_MIN_ABSORPTION = 0.3
TUNING.MUTANT_BEE_DEFENDER_MAX_ABSORPTION = 0.8
TUNING.MUTANT_BEE_DEFENDER_MAX_ABSORPTION_THRESHOLD = 0.3

TUNING.MUTANT_BEE_ASSASSIN_ATTACK_PERIOD = 2
TUNING.MUTANT_BEE_ASSASSIN_BACKSTAB_DAMAGE_MULT = 0.5
TUNING.MUTANT_BEE_ASSSASIN_HEALTH = 250
TUNING.MUTANT_BEE_ASSSASIN_DAMAGE = 15
TUNING.MUTANT_BEE_MAX_POISON_TICKS = 10
TUNING.MUTANT_BEE_STACK_POISON_TICKS = 10
TUNING.MUTANT_BEE_POISON_DAMAGE = 7

TUNING.MUTANT_BEE_SOLDIER_HEALTH = 300
TUNING.MUTANT_BEE_SOLDIER_ABSORPTION = 0.25
TUNING.MUTANT_BEE_SOLDIER_COUNTER_ATK_CHANCE = 0.35

TUNING.MUTANT_BEE_SHADOW_HEALTH = 200
TUNING.MUTANT_BEE_SHADOW_DAMAGE = 8
TUNING.MUTANT_BEE_SHADOW_ATK_PERIOD = 2
TUNING.MUTANT_BEE_SHADOW_ATK_RANGE = 5

TUNING.MUTANT_SHADOWLING_HEALTH = 150
TUNING.MUTANT_SHADOWLING_DAMAGE = 5
TUNING.MUTANT_SHADOWLING_SPAWN_CHANCE = 0.25
TUNING.MUTANT_SHADOWLING_DECAY_RATE = 1.25
TUNING.MUTANT_SHADOWLING_DAMAGE_CAP = 0.15

TUNING.MUTANT_BEE_HEALER_HEALTH = 250
TUNING.MUTANT_BEE_HEALER_DAMAGE = 5
TUNING.MUTANT_BEE_HEALER_HEAL_COOLDOWN = 5
TUNING.MUTANT_BEE_HEALER_ATK_PERIOD = 2
TUNING.MUTANT_BEE_HEALER_HEAL_AMOUNT = 30
TUNING.MUTANT_BEE_HEALER_HEAL_ATK_AMOUNT = 10
TUNING.MUTANT_BEE_HEALER_HEAL_ORB_AMOUNT = 8
TUNING.MUTANT_BEE_HEALER_HEAL_ORB_COOLDOWN = 12
TUNING.MUTANT_BEE_HEALER_MAX_HEAL_ORB_MIN_DISTANCE = 2
TUNING.MUTANT_BEE_HEALER_MAX_HEAL_ORB_MAX_DISTANCE = 5

TUNING.MUTANT_BEE_RAGED_DAMAGE_BUFF = 1.25
TUNING.MUTANT_BEE_FRENZY_ATK_SPEED_BUFF = 0.5

-- Mutant beehive stats
TUNING.MUTANT_BEEHIVE_DEFAULT_EMERGENCY_BEES = 0
TUNING.MUTANT_BEEHIVE_EMERGENCY_BEES_PER_PLAYER = 500
TUNING.MUTANT_BEEHIVE_EMERGENCY_RADIUS = 30
TUNING.MUTANT_BEEHIVE_BEES = 4
TUNING.MUTANT_BEEHIVE_DEFAULT_RELEASE_TIME = 30
TUNING.MUTANT_BEEHIVE_DEFAULT_REGEN_TIME = 30
TUNING.MUTANT_BEEHIVE_DELTA_BEES = 3
TUNING.MUTANT_BEEHIVE_DELTA_RELEASE_TIME = 10
TUNING.MUTANT_BEEHIVE_DELTA_REGEN_TIME = 5
TUNING.MUTANT_BEEHIVE_UPGRADES_PER_STAGE = 3
TUNING.MUTANT_BEEHIVE_WATCH_DIST = 25
TUNING.MUTANT_BEEHIVE_RECOVER_PER_CHILD = 0.75
TUNING.MUTANT_BEEHIVE_MAX_HONEYS_PER_CYCLE = 3
TUNING.MUTANT_BEEHIVE_NUM_POLLENS_PER_HONEY = 5
TUNING.MUTANT_BEEHIVE_MASTER_SLAVE_DIST = 10
TUNING.MUTANT_BEEHIVE_CHILDREN_PER_SLAVE = 1
TUNING.MUTANT_BEEHIVE_CHILDREN_PER_BARRACK = 2
TUNING.MUTANT_BEEHIVE_BARRACK_MODIFIER = 0.05

-- Armor honey
TUNING.ARMORHONEY_MAX_ABSORPTION = 0.7
TUNING.ARMORHONEY_MIN_ABSORPTION = 0.55
TUNING.ARMORHONEY_HEAL_TICKS = 3
TUNING.ARMORHONEY_HEAL_INTERVAL = 3
TUNING.ARMORHONEY_MIN_HEAL_PERCENT = 0.03
TUNING.ARMORHONEY_MAX_HEAL_PERCENT = 0.05
TUNING.ARMORHONEY_ADD_STORE = 1
TUNING.ARMORHONEY_MULT_REGEN_TICK = 2 / 3

-- Melissa
TUNING.MELISSA_DAMAGE = 40
TUNING.MELISSA_DAMAGE_2 = 52
TUNING.MELISSA_USES = 150
TUNING.MELISSA_SWAP_USES = 20
TUNING.MELISSA_SLAM_DAMAGE_MULT = 3

-- Sting trap
TUNING.STING_TRAP_USES = 250
TUNING.STING_TRAP_DAMAGE = 10
TUNING.STING_TRAP_DEFAULT_SPEED_PENALTY = 0.6
TUNING.STING_TRAP_EPIC_SPEED_PENALTY = 0.75

-- The character select screen lines
STRINGS.CHARACTER_TITLES.zeta = "The Buzzy"
STRINGS.CHARACTER_NAMES.zeta = "Wuzzy"
STRINGS.CHARACTER_DESCRIPTIONS.zeta =
    "*Leads his own species and hive\n*Fights alongside his symbiotic bees\n*Can pick pollen from flowers\n*Loves honeyed foods"
STRINGS.CHARACTER_QUOTES.zeta = '"Bees together strong."'
STRINGS.CHARACTER_SURVIVABILITY.zeta = "Grim"
STRINGS.SKIN_NAMES.zeta_none = "Wuzzy"
STRINGS.SKIN_DESCRIPTIONS.zeta_none = "The look of the bee master"

-- Custom speech strings
STRINGS.CHARACTERS.ZETA = require "speech_zeta"

-- The character's name as appears in-game
STRINGS.NAMES.ZETA = "Wuzzy"

AddMinimapAtlas("images/map_icons/zeta.xml")
-- AddMinimapAtlas("images/map_icons/mutantbeecocoon.xml")
AddMinimapAtlas("images/map_icons/mutantbeehive.xml")
-- AddMinimapAtlas("images/map_icons/mutantdefenderhive.xml")
-- AddMinimapAtlas("images/map_icons/mutantrangerhive.xml")
-- AddMinimapAtlas("images/map_icons/mutantassassinhive.xml")
-- AddMinimapAtlas("images/map_icons/mutantshadowhive.xml")
-- AddMinimapAtlas("images/map_icons/mutanthealerhive.xml")
AddMinimapAtlas("images/map_icons/mutantteleportal.xml")


-- Skill tree
local function CreateSkillTree()
    local BuildSkillsData = require("prefabs/skilltree_zeta")
    if BuildSkillsData then
        local data = BuildSkillsData(SkillTreeDefs.FN)

        if data then
            SkillTreeDefs.CreateSkillTreeFor("zeta", data.SKILLS)
            SkillTreeDefs.SKILLTREE_ORDERS["zeta"] = data.ORDERS
            print("created skilltree")
        end
    end
end

RegisterSkilltreeBGForCharacter("images/skilltree_zeta.xml", "zeta")
RegisterSkilltreeIconsAtlas("images/skilltree_zeta_icons.xml", "zeta_metapis_assassin_1.tex")
RegisterSkilltreeIconsAtlas("images/skilltree_zeta_icons.xml", "zeta_metapis_assassin_2.tex")
RegisterSkilltreeIconsAtlas("images/skilltree_zeta_icons.xml", "zeta_metapis_shadow_1.tex")
RegisterSkilltreeIconsAtlas("images/skilltree_zeta_icons.xml", "zeta_metapis_shadow_2.tex")
RegisterSkilltreeIconsAtlas("images/skilltree_zeta_icons.xml", "zeta_metapis_defender_1.tex")
RegisterSkilltreeIconsAtlas("images/skilltree_zeta_icons.xml", "zeta_metapis_defender_2.tex")
RegisterSkilltreeIconsAtlas("images/skilltree_zeta_icons.xml", "zeta_metapis_ranger_1.tex")
RegisterSkilltreeIconsAtlas("images/skilltree_zeta_icons.xml", "zeta_metapis_ranger_2.tex")
RegisterSkilltreeIconsAtlas("images/skilltree_zeta_icons.xml", "zeta_metapis_mimic_1.tex")
RegisterSkilltreeIconsAtlas("images/skilltree_zeta_icons.xml", "zeta_metapis_healer_1.tex")
RegisterSkilltreeIconsAtlas("images/skilltree_zeta_icons.xml", "zeta_metapis_healer_2.tex")
RegisterSkilltreeIconsAtlas("images/skilltree_zeta_icons.xml", "zeta_metapimancer_tyrant_1.tex")
RegisterSkilltreeIconsAtlas("images/skilltree_zeta_icons.xml", "zeta_metapimancer_tyrant_2.tex")
RegisterSkilltreeIconsAtlas("images/skilltree_zeta_icons.xml", "zeta_metapimancer_shepherd_1.tex")
RegisterSkilltreeIconsAtlas("images/skilltree_zeta_icons.xml", "zeta_metapimancer_shepherd_2.tex")
RegisterSkilltreeIconsAtlas("images/skilltree_zeta_icons.xml", "zeta_honeysmith_melissa_1.tex")
RegisterSkilltreeIconsAtlas("images/skilltree_zeta_icons.xml", "zeta_honeysmith_melissa_2.tex")


CreateSkillTree()


PREFAB_SKINS["zeta"] = {
    "zeta_none"
}

PREFAB_SKINS_IDS["zeta"] = {}
for k, v in pairs(PREFAB_SKINS["zeta"]) do
    PREFAB_SKINS_IDS["zeta"][v] = k
end

-- Add mod character to mod character list. Also specify a gender. Possible genders are MALE, FEMALE, ROBOT, NEUTRAL, and PLURAL.
local skin_modes = {
    {
        type = "ghost_skin",
        anim_bank = "ghost",
        idle_anim = "idle",
        scale = 0.75,
        offset = {0, -25}
    }
}
AddModCharacter("zeta", "MALE", skin_modes)

-- Post init
local function HandleHoneyPerishingInMetapisHive(prefab)
    if prefab.components.perishable and prefab.components.inventoryitem then
        local OldOnPutInInventory = prefab.components.inventoryitem.onputininventoryfn or function()
                return
            end
        prefab.components.inventoryitem:SetOnPutInInventoryFn(
            function(inst, owner)
                if owner and owner.prefab == "mutantcontainer" then
                    inst.components.perishable:StopPerishing()
                end

                OldOnPutInInventory(inst, owner)
            end
        )

        local inventoryitem = prefab.components.inventoryitem
        local OldOnRemoved = inventoryitem.OnRemoved
        local onremovedfn = function(inst, owner)
            if owner.prefab == "mutantcontainer" then
                inst.components.perishable:StartPerishing()
            end
        end

        inventoryitem.OnRemoved = function(comp)
            if comp.owner then
                onremovedfn(comp.inst, comp.owner)
            end
            OldOnRemoved(comp)
        end
    end
end

AddPrefabPostInit("honey", HandleHoneyPerishingInMetapisHive)

local POLLEN_TICK_INTERVAL = 60
local POLLEN_MAX_TICKS = 16

local function ontick(inst)
    inst.pollenticks = inst.pollenticks - 1
    if inst.pollenticks > 0 then
        inst._pollentask = inst:DoTaskInTime(POLLEN_TICK_INTERVAL, ontick)
    else
        inst._pollentask = nil
        inst.pollenpicked = false
        inst.net_pollenpicked:set(false)
    end
end

local function startpollentask(inst)
    if inst.pollenticks > 0 and not inst._pollentask and GLOBAL.TheWorld.state.season ~= SEASONS.WINTER then
        inst._pollentask = inst:DoTaskInTime(POLLEN_TICK_INTERVAL, ontick)
    end
end

local function stoppollentask(inst)
    if inst._pollentask then
        inst._pollentask:Cancel()
        inst._pollentask = nil
    end
end

local function onpickedflowerfn(inst, picker)
    if picker ~= nil and not inst.pollenpicked then
        if picker.components.sanity ~= nil and not picker:HasTag("plantkin") then
            picker.components.sanity:DoDelta(TUNING.SANITY_SUPERTINY)
        end

        inst.pollenpicked = true
        inst.net_pollenpicked:set(true)
        inst.pollenticks = POLLEN_MAX_TICKS
        startpollentask(inst)
    end
end

local function onseasonchange(inst, season)
    if not season then
        season = GLOBAL.TheWorld.state.season
    end

    if season == SEASONS.WINTER then
        inst.pollenpicked = true
        inst.net_pollenpicked:set(true)
        inst.pollenticks = POLLEN_MAX_TICKS
        stoppollentask(inst)
    else
        startpollentask(inst)
    end
end

local function FlowerPostInit(prefab)
    prefab.net_pollenpicked = GLOBAL.net_bool(prefab.GUID, "flower.pollenpicked", "pollenpickeddirty")

    if not GLOBAL.TheWorld.ismastersim then
        return
    end

    prefab.pollenpicked = false
    prefab.net_pollenpicked:set(false)
    prefab:DoTaskInTime(
        0,
        function()
            prefab.net_pollenpicked:set(prefab.pollenpicked)
        end
    )

    prefab.pollenticks = 0

    prefab:DoTaskInTime(0, onseasonchange)

    prefab:WatchWorldState("season", onseasonchange)

    if prefab.components.pickable then
        local oldonpickedfn = prefab.components.pickable.onpickedfn
        prefab.components.pickable.onpickedfn = function(inst, picker)
            if picker and picker.prefab == "zeta" then
                if not inst.pollenpicked then
                    onpickedflowerfn(inst, picker)
                else
                    if oldonpickedfn ~= nil then
                        oldonpickedfn(inst, picker)
                    end
                    picker.components.sanity:DoDelta(TUNING.OZZY_PICK_FLOWER_SANITY)
                end

                return
            end

            if oldonpickedfn ~= nil then
                oldonpickedfn(inst, picker)
            end
        end

        local PickFn = prefab.components.pickable.Pick
        prefab.components.pickable.Pick = function(comp, picker, ...)
            if picker and picker.prefab == "zeta" then
                if not comp.inst.pollenpicked then
                    local product = comp.product
                    local numtoharvest = comp.numtoharvest
                    local remove_when_picked = comp.remove_when_picked

                    comp.product = "zetapollen"
                    comp.numtoharvest =
                        (GLOBAL.TheWorld.state.season == SEASONS.SPRING and math.random() <= 0.5) and 2 or 1
                    comp.remove_when_picked = false
                    PickFn(comp, picker, ...)

                    comp.product = product
                    comp.numtoharvest = numtoharvest
                    comp.remove_when_picked = remove_when_picked
                else
                    PickFn(comp, picker, ...)
                end

                return
            end

            PickFn(comp, picker, ...)
        end

        --Save/Load
        local OldOnSave = prefab.OnSave
        local OldOnLoad = prefab.OnLoad
        prefab.OnSave = function(inst, data)
            OldOnSave(inst, data)
            data.pollenpicked = inst.pollenpicked
            data.pollenticks = inst.pollenticks
        end

        prefab.OnLoad = function(inst, data)
            OldOnLoad(inst, data)
            inst.pollenpicked = data ~= nil and data.pollenpicked or false
            inst.net_pollenpicked:set(inst.pollenpicked)
            inst.pollenticks = data ~= nil and data.pollenticks or 0

            inst:DoTaskInTime(0, onseasonchange)
        end
    end
end

AddPrefabPostInit("flower", FlowerPostInit)

local function BeeBoxPostInit(prefab)
    if prefab.components.childspawner then
        local oldReleaseAllChildren = prefab.components.childspawner.ReleaseAllChildren
        prefab.components.childspawner.ReleaseAllChildren = function(comp, target, ...)
            if target and target:HasTag("beemaster") then
                return
            end

            oldReleaseAllChildren(comp, target, ...)
        end
    end
end

AddPrefabPostInit("beebox", BeeBoxPostInit)
AddPrefabPostInit("beebox_hermit", BeeBoxPostInit)

local function WaspHivePostInit(prefab)
    if prefab.components.playerprox then
        local oldOnNearFn = prefab.components.playerprox.onnear
        local onnearfn = function(inst, target)
            if target and target:HasTag("beemaster") then
                return
            end

            if oldOnNearFn ~= nil then
                oldOnNearFn(inst, target)
            end
        end
        prefab.components.playerprox:SetOnPlayerNear(onnearfn)
    end
end

AddPrefabPostInit("wasphive", WaspHivePostInit)

-- local function RangerHiveBlueprintPostInit(prefab)
--     if not GLOBAL.TheWorld.ismastersim then
--         return
--     end

--     if prefab.components.teacher then
--         local oldTeach = prefab.components.teacher.Teach
--         prefab.components.teacher.Teach = function(comp, target, ...)
--             if target and not target:HasTag("beemaster") then
--                 return false, "CANTLEARN"
--             end

--             return oldTeach(comp, target, ...)
--         end
--     end
-- end

-- AddPrefabPostInit("mutantrangerhive_blueprint", RangerHiveBlueprintPostInit)

local function wrapRetargetFn(fn)
    return function(...)
        local target = fn(...)
        if target and target:HasTag("beemutant") then
            return nil
        end
        return target
    end
end

local function AbigailPostInit(prefab)
    if not GLOBAL.TheWorld.ismastersim then
        return
    end

    if prefab.components.combat then
        local oldSetRetargetFunction = prefab.components.combat.SetRetargetFunction
        prefab.components.combat.SetRetargetFunction = function(comp, period, fn, ...)
            local newFn = wrapRetargetFn(fn)
            return oldSetRetargetFunction(comp, period, newFn, ...)
        end
    end
end

AddPrefabPostInit("abigail", AbigailPostInit)

local function beequeentrackattackers(inst, data)
    if data and data.attacker and data.attacker:HasTag("player") then
        inst._zeta_attackerids[data.attacker.userid] = true
    end
end

local function BeeQueenOnDeath(inst, data)
    for userid, v in pairs(inst._zeta_attackerids) do
        for i, player in ipairs(GLOBAL.AllPlayers) do
            if player:HasTag("beemaster") and player.userid == userid then
                player:IncrBeeQueenKilledCount()
                player:DoTaskInTime(0, player.OnBeeQueenKilled)
                break
            end
        end
    end
end

local function BeeQueenPostInit(inst)
    if not GLOBAL.TheWorld.ismastersim then
        return
    end

    inst._zeta_attackerids = {}
    inst:ListenForEvent("attacked", beequeentrackattackers)
    inst:ListenForEvent("death", BeeQueenOnDeath)

    local oldOnSave = inst.OnSave
    local oldOnLoad = inst.OnLoad

    inst.OnSave = function(inst, data)
        oldOnSave(inst, data)
        data._zeta_attackerids = inst._zeta_attackerids or nil
    end

    inst.OnLoad = function(inst, data)
        oldOnLoad(inst, data)

        if data ~= nil then
            inst._zeta_attackerids = data._zeta_attackerids or {}
        end
    end
end

AddPrefabPostInit("beequeen", BeeQueenPostInit)

local function MonkeyQueenPostInit(inst)
    if not GLOBAL.TheWorld.ismastersim then
        return
    end

    if inst.components.trader then
        local oldonaccept = inst.components.trader.onaccept
        inst.components.trader.onaccept = function(inst, giver, item, ...)
            if giver:HasTag("player") and giver:HasTag("beemaster") then
                SendRPCToClient(CLIENT_RPC.UpdateAccomplishment, giver.userid, "zeta_monkeyqueen_traded")
            end

            return oldonaccept(inst, giver, item, ...)
        end
    end
end

AddPrefabPostInit("monkeyqueen", MonkeyQueenPostInit)


local containers = GLOBAL.require("containers")
local mutantbeehive_level3_container = {
  widget =
  {
    slotpos = {},
    animbank = "ui_icepack_2x3",
    animbuild = "ui_icepack_2x3",
    pos = Vector3(50, 200, 0),
  },
  acceptsstacks = false,
  itemtestfn = function(inst, item, slot) return item and item:HasTag("beemutanttoken") end,
  type = "chest",
}
for y = 0, 2 do
    table.insert(mutantbeehive_level3_container.widget.slotpos, Vector3(-162, -75 * y + 75, 0))
    table.insert(mutantbeehive_level3_container.widget.slotpos, Vector3(-162 + 75, -75 * y + 75, 0))
end

local mutantcontainer_container = {
    widget =
    {
        slotpos = {},
        animbank = "ui_chest_3x3",
        animbuild = "ui_chest_3x3",
        pos = Vector3(0, 200, 0),
        side_align_tip = 160,
    },
    itemtestfn = function(inst, item, slot)
      return item and item.prefab and (
        item.prefab == "honey" or
        item.prefab == "zetapollen" or
        item.prefab == "armor_honey"
      )
    end,
    type = "chest",
}
for y = 2, 0, -1 do
    for x = 0, 2 do
        table.insert(mutantcontainer_container.widget.slotpos, Vector3(80 * x - 80 * 2 + 80, 80 * y - 80 * 2 + 80, 0))
    end
end

containers.params.mutantbeehive_level3 = mutantbeehive_level3_container
containers.params.mutantcontainer = mutantcontainer_container

-- Recipes
AddCharacterRecipe(
    "armor_honey",
    {
        Ingredient("log", 10),
        Ingredient("rope", 1),
        Ingredient("honey", 3)
    },
    TECH.NONE,
    {
        builder_tag = "beemaster",
        atlas = "images/inventoryimages/armor_honey.xml",
        image = "armor_honey.tex"
    },
    {
        "ARMOUR"
    }
)

AddCharacterRecipe(
    "melissa",
    {
        Ingredient("twigs", 2),
        Ingredient("goldnugget", 1),
        Ingredient("stinger", 5)
    },
    TECH.NONE,
    {
        builder_tag = "beemaster",
        atlas = "images/inventoryimages/melissa.xml",
        image = "melissa.tex"
    },
    {
        "WEAPONS"
    }
)

local function canbuildmotherhive(inst, builder)
    if builder.prefab == "zeta" then
        -- cannot build more than 1 Mother Hive
        if builder._hive and builder._hive:IsValid() then
            return false
        end

        return true
    end

    return false
end

AddCharacterRecipe(
    "mutantbeehive",
    {
        Ingredient(GLOBAL.CHARACTER_INGREDIENT.HEALTH, 30),
        Ingredient("honeycomb", 1),
        Ingredient("honey", 5)
    },
    TECH.NONE,
    {
        builder_tag = "beemaster",
        atlas = "images/inventoryimages/mutantbeehive.xml",
        image = "mutantbeehive.tex",
        placer = "mutantbeehive_placer",
        canbuild = canbuildmotherhive
    }
)

local function slavehivetestfn(pt, rot)
    local x, y, z = pt:Get()
    local possiblemasters =
        GLOBAL.TheSim:FindEntities(x, y, z, TUNING.MUTANT_BEEHIVE_MASTER_SLAVE_DIST, {"mutantbeehive"})

    if possiblemasters[1] ~= nil then
        return true
    end

    return false
end

AddCharacterRecipe(
    "mutantdefenderhive",
    {
        Ingredient("horn", 2),
        Ingredient("honeycomb", 1),
        Ingredient("moonrocknugget", 10)
    },
    TECH.CELESTIAL_ONE,
    {
        builder_tag = "beemaster",
        atlas = "images/inventoryimages/mutantdefenderhive.xml",
        image = "mutantdefenderhive.tex",
        placer = "mutantdefenderhive_placer",
        testfn = slavehivetestfn
    }
)

AddCharacterRecipe(
    "mutantrangerhive",
    {
        Ingredient("lightninggoathorn", 2),
        Ingredient("honeycomb", 1),
        Ingredient("cookiecuttershell", 8)
    },
    TECH.HERMITCRABSHOP_FIVE,
    {
        builder_tag = "beemaster",
        atlas = "images/inventoryimages/mutantrangerhive.xml",
        image = "mutantrangerhive.tex",
        placer = "mutantrangerhive_placer",
        testfn = slavehivetestfn
    }
)

AddCharacterRecipe(
    "mutantassassinhive",
    {
        Ingredient("moonbutterflywings", 8),
        Ingredient("honeycomb", 1),
        Ingredient("moonglass", 10)
    },
    TECH.CELESTIAL_THREE,
    {
        builder_tag = "beemaster",
        atlas = "images/inventoryimages/mutantassassinhive.xml",
        image = "mutantassassinhive.tex",
        placer = "mutantassassinhive_placer",
        testfn = slavehivetestfn
    }
)

AddCharacterRecipe(
    "mutantshadowhive",
    {
        Ingredient("nightmarefuel", 10),
        Ingredient("honeycomb", 1),
        Ingredient("thulecite", 6)
    },
    TECH.ANCIENT_FOUR,
    {
        builder_tag = "beemaster",
        atlas = "images/inventoryimages/mutantshadowhive.xml",
        image = "mutantshadowhive.tex",
        placer = "mutantshadowhive_placer",
        testfn = slavehivetestfn
    }
)

AddCharacterRecipe(
    "mutanthealerhive",
    {
        Ingredient("butterfly", 8),
        Ingredient("honeycomb", 1),
        Ingredient("papyrus", 6)
    },
    TECH.LOST,
    {
        builder_tag = "beemaster",
        atlas = "images/inventoryimages/mutanthealerhive.xml",
        image = "mutanthealerhive.tex",
        placer = "mutanthealerhive_placer",
        testfn = slavehivetestfn
    }
)

-- name ~= product to ignore recipe loots
AddCharacterRecipe(
    "mutantbarrack_recipe",
    {
        Ingredient("honey", 40),
        Ingredient("honeycomb", 1),
        Ingredient("killerbee", 4)
    },
    TECH.SCIENCE_TWO,
    {
        builder_tag = "beemaster",
        atlas = "images/inventoryimages/mutantbarrack.xml",
        image = "mutantbarrack.tex",
        placer = "mutantbarrack_placer",
        testfn = slavehivetestfn,
        product = "mutantbarrack"
    }
)

AddCharacterRecipe(
    "mutantteleportal",
    {
        Ingredient("honeycomb", 1),
        Ingredient("nightmarefuel", 4),
        Ingredient("purplegem", 3)
    },
    TECH.MAGIC_THREE,
    {
        builder_tag = "beemaster",
        atlas = "images/inventoryimages/mutantteleportal.xml",
        image = "mutantteleportal.tex",
        placer = "mutantteleportal_placer"
    }
)

AddCharacterRecipe(
    "mutantbasebee_token",
    {
        Ingredient("goldnugget", 1),
        Ingredient("stinger", 1)
    },
    TECH.NONE,
    {
        builder_tag = "beemaster",
        atlas = "images/inventoryimages/mutantbasebee_token.xml",
        image = "mutantbasebee_token.tex"
    }
)

AddCharacterRecipe(
    "mutantdefenderbee_token",
    {
        Ingredient("goldnugget", 1),
        Ingredient("stinger", 1)
    },
    TECH.LOST,
    {
        builder_tag = "beemaster",
        atlas = "images/inventoryimages/mutantdefenderbee_token.xml",
        image = "mutantdefenderbee_token.tex"
    }
)

AddCharacterRecipe(
    "mutantrangerbee_token",
    {
        Ingredient("goldnugget", 1),
        Ingredient("stinger", 1)
    },
    TECH.LOST,
    {
        builder_tag = "beemaster",
        atlas = "images/inventoryimages/mutantrangerbee_token.xml",
        image = "mutantrangerbee_token.tex"
    }
)

AddCharacterRecipe(
    "mutantassassinbee_token",
    {
        Ingredient("goldnugget", 1),
        Ingredient("stinger", 1)
    },
    TECH.LOST,
    {
        builder_tag = "beemaster",
        atlas = "images/inventoryimages/mutantassassinbee_token.xml",
        image = "mutantassassinbee_token.tex"
    }
)

AddCharacterRecipe(
    "mutantshadowbee_token",
    {
        Ingredient("goldnugget", 1),
        Ingredient("stinger", 1)
    },
    TECH.LOST,
    {
        builder_tag = "beemaster",
        atlas = "images/inventoryimages/mutantshadowbee_token.xml",
        image = "mutantshadowbee_token.tex"
    }
)

AddCharacterRecipe(
    "mutanthealerbee_token",
    {
        Ingredient("goldnugget", 1),
        Ingredient("stinger", 1)
    },
    TECH.LOST,
    {
        builder_tag = "beemaster",
        atlas = "images/inventoryimages/mutanthealerbee_token.xml",
        image = "mutanthealerbee_token.tex"
    }
)

local function canbuildcontainer(inst, builder)
    if builder.prefab == "zeta" then
        -- cannot build util if there is no Mother Hive yet
        if not builder._hive then
            return false
        end

        builder._hive:OnSlave()

        -- only allow 1 container per Mother Hive
        return not builder._hive._container
    end

    return false
end

AddCharacterRecipe(
    "mutantcontainer",
    {
        Ingredient("boards", 4),
        Ingredient("honeycomb", 1),
        Ingredient("honey", 3)
    },
    TECH.NONE,
    {
        builder_tag = "beemaster",
        atlas = "images/inventoryimages/mutantcontainer.xml",
        image = "mutantcontainer.tex",
        placer = "mutantcontainer_placer",
        testfn = slavehivetestfn,
        canbuild = canbuildcontainer
    },
    {
        "CONTAINERS"
    }
)

-- AddCharacterRecipe(
--     "honey_sting_ball",
--     {
--         Ingredient("honey", 5),
--         Ingredient("stinger", 5),
--         Ingredient("cutgrass", 2)
--     },
--     TECH.SCIENCE_ONE,
--     {
--         builder_tag = "beemaster",
--         atlas = "images/inventoryimages/honey_sting_ball.xml",
--         image = "honey_sting_ball.tex"
--     },
--     {
--         "WEAPONS"
--     }
-- )

GLOBAL.CONSTRUCTION_PLANS["mutantbeehive"] = {
    Ingredient("honeycomb", 3),
    Ingredient("honey", 40)
}
GLOBAL.CONSTRUCTION_PLANS["mutantbeehive_level2"] = {
    Ingredient("royal_jelly", 3),
    Ingredient("honeycomb", 3),
    Ingredient("honey", 40)
}

GLOBAL.ACTIONS.MUTANTBEE_DESPAWN = Action()
GLOBAL.ACTIONS.MUTANTBEE_DESPAWN.fn = function(act)
    if act.doer._lastcombattime ~= nil and GLOBAL.GetTime() <= act.doer._lastcombattime + 10 then
        return false
    end

    if act.target ~= nil then
        if act.target.components.beesummoner then
            return act.target.components.beesummoner:Despawn(act.doer)
        end

        act.doer:Remove()
        return true
    elseif act.pos ~= nil then
        act.doer:Remove()
        return true
    end
end

GLOBAL.ACTIONS.MUTANTBEE_HEAL = Action()
GLOBAL.ACTIONS.MUTANTBEE_HEAL.fn = function(act)
    if act.target ~= nil and act.target:IsValid() and act.target.components.health then
        act.doer:Heal(act.target)

        return true
    end

    return false
end

local function performSwap(doer, target, invobject)
    if target ~= nil and target:IsValid() and
        doer ~= nil and doer:IsValid() and
        invobject ~= nil
    then
        return invobject.components.blinkswap:Swap(doer, target)
    end

    return false
end

local swap_approx_dist = 2
local function findNearestMinion(pos, inst)
    local x,y,z = pos:Get()

    -- a bit longer than client find distance to compensate minion movement
    local radius = swap_approx_dist + 4
    local ents = GLOBAL.TheSim:FindEntities(
        x, y, z,
        radius,
        {"beemutantminion"},
        {"lesserminion", "INLIMBO"}
    )

    local closestEntity = nil
    local rangesq = radius * radius
    for i, v in ipairs(ents) do
        if v:IsValid() and (not GLOBAL.IsEntityDead(v)) and v:GetOwner() == inst then
            local distsq = v:GetDistanceSqToPoint(x, y, z)
            if distsq < rangesq then
                rangesq = distsq
                closestEntity = v
            end
        end
    end

    return closestEntity
end

local blink_swap_approx_act = AddAction("ZETA_BLINK_SWAP_APPROX", "Swap", function(act)
    -- print("BLINK SWAP APPROX", act.doer, act.invobject, act.target)

    local minion = findNearestMinion(act:GetActionPoint(), act.doer)
    if minion ~= nil then
        return performSwap(act.doer, minion, act.invobject)
    end

    return false, "NO_MINION"
end)
blink_swap_approx_act.priority = 10
blink_swap_approx_act.rmb = true
blink_swap_approx_act.distance = 25

local function hasNearbyMinion(pos)
    local x,y,z = pos:Get()
    local radius = swap_approx_dist
    local ents = GLOBAL.TheSim:FindEntities(
        x, y, z,
        radius,
        {"beemutantminion"},
        {"lesserminion"}
    )

    return #ents > 0
end

AddComponentAction("POINT", "blinkswap", function(inst, doer, pos, actions, right, target)
    local x,y,z = pos:Get()
    if right and
        inst:HasTag("beemaster_weapon") and
        doer:HasTag("beemaster") and not doer:HasTag("steeringboat") and not doer:HasTag("rotatingboat") and
        (GLOBAL.TheWorld.Map:IsAboveGroundAtPoint(x,y,z) or GLOBAL.TheWorld.Map:GetPlatformAtPoint(x,z) ~= nil) and
        not GLOBAL.TheWorld.Map:IsGroundTargetBlocked(pos)
    then
        if hasNearbyMinion(pos) then
            table.insert(actions, GLOBAL.ACTIONS.ZETA_BLINK_SWAP_APPROX)
        end
    end
end)

-- Badge
local Badge = require("widgets/badge")

local function OnRegenTick(inst, data)
    local percent = inst.components.beesummoner:GetRegenTickPercent()
    inst.symbiosis_percent:set(math.floor(percent * 100 + 0.5))
    inst.symbiosis_maxval:set(inst.components.beesummoner.maxticks)
    inst.symbiosis_numstore:set(inst.components.beesummoner.numstore)

    if data.currenttick > 0 then
        inst.symbiosis_pulse:set(true)
    else
        inst.symbiosis_pulse:set(false)
    end
end

local function OnNumStoreChange(inst, data)
    inst.symbiosis_numstore:set(inst.components.beesummoner.numstore)
end

local function CalcSymbiosisPosition(status)
    -- Assume that brain always stays in the middle, stomach on the left and heart on the right
    local brainPos = status.brain:GetPosition()
    local stomachPos = status.stomach:GetPosition()
    local heartPos = status.heart:GetPosition()

    local pos = GLOBAL.Vector3(2 * stomachPos.x - brainPos.x, brainPos.y, stomachPos.z)
    return pos
end

local function StatusPostConstruct(self)
    if self.owner.prefab == "zeta" then
        self.symbiosis = self:AddChild(Badge(nil, self.owner, {48 / 255, 169 / 255, 169 / 255, 1}, "status_symbiosis"))
        self.symbiosis.backing:GetAnimState():SetBuild("status_meter_symbiosis")

        self.symbiosis:Hide()
        self.symbiosis.num:Show()
        local OldOnLoseFocus = self.symbiosis.OnLoseFocus
        self.symbiosis.OnLoseFocus = function(badge)
            OldOnLoseFocus(badge)
            badge.num:Show()
        end

        self.owner.UpdateSymbiosisBadge = function()
            local percent = self.owner.symbiosis_percent and (self.owner.symbiosis_percent:value() / 100) or 0
            local maxval = self.owner.symbiosis_maxval and self.owner.symbiosis_maxval:value() or 0
            local numstore = self.owner.symbiosis_numstore and self.owner.symbiosis_numstore:value() or 0
            local pulse = self.owner.symbiosis_pulse and self.owner.symbiosis_pulse:value() or false
            local pos = CalcSymbiosisPosition(self)
            self.symbiosis:Show()
            self.symbiosis:SetPosition(pos:Get())
            self.symbiosis:SetScale(self.brain:GetLooseScale())
            self.symbiosis:SetPercent(percent, maxval)
            self.symbiosis.num:SetString(GLOBAL.tostring(numstore))
            if pulse then
                self.symbiosis:PulseGreen()
            end
        end
    end
end

AddClassPostConstruct("widgets/statusdisplays", StatusPostConstruct)

local function onsymbiosisdirty(inst)
    if GLOBAL.ThePlayer and GLOBAL.ThePlayer.UpdateSymbiosisBadge then
        GLOBAL.ThePlayer.UpdateSymbiosisBadge()
    end
end

local function PlayerPostConstruct(inst)
    if inst.prefab ~= "zeta" then
        return
    end

    inst.symbiosis_percent = GLOBAL.net_byte(inst.GUID, "symbiosis.percent", "symbiosisdirty")
    inst.symbiosis_maxval = GLOBAL.net_byte(inst.GUID, "symbiosis.maxval", "symbiosisdirty")
    inst.symbiosis_numstore = GLOBAL.net_byte(inst.GUID, "symbiosis.numstore", "symbiosisdirty")
    inst.symbiosis_pulse = GLOBAL.net_bool(inst.GUID, "symbiosis.pulse", "symbiosisdirty")

    if GLOBAL.TheWorld.ismastersim then
        inst:ListenForEvent("onregentick", OnRegenTick)
        inst:ListenForEvent("onnumstorechange", OnNumStoreChange)

        -- kick off badge
        inst:DoTaskInTime(
            0,
            function()
                inst:PushEvent("onregentick", {currenttick = 0})
            end
        )
    end

    if not GLOBAL.TheNet:IsDedicated() then
        inst:ListenForEvent("symbiosisdirty", onsymbiosisdirty)
    end
end

AddPlayerPostInit(PlayerPostConstruct)

local State = GLOBAL.State
local TimeEvent = GLOBAL.TimeEvent
local EventHandler = GLOBAL.EventHandler
local FRAMES = GLOBAL.FRAMES
local EQUIPSLOTS = GLOBAL.EQUIPSLOTS

local function spawn_land_fx(inst, target)
    local distance = 1.1

    if inst and target and inst:IsValid() and target:IsValid() then
        local x1, y1, z1 = inst.Transform:GetWorldPosition()
        local x2, y2, z2 = target.Transform:GetWorldPosition()

        -- Compute direction vector from inst to target
        local dir_x = x2 - x1
        local dir_z = z2 - z1
        local length = math.sqrt(dir_x * dir_x + dir_z * dir_z)

        -- Normalize the direction vector
        if length > 0 then
            dir_x = dir_x / length
            dir_z = dir_z / length
        end

        -- Calculate the spawn location at 'distance' from inst in the direction of the target
        local spawn_x = x1 + dir_x * distance
        local spawn_z = z1 + dir_z * distance

        -- Spawn the prefab at the computed location
        local spawned = SpawnPrefab("groundpound_fx")
        if spawned then
            spawned.Transform:SetPosition(spawn_x, 0, spawn_z)
        end

        inst.SoundEmitter:PlaySound("dontstarve_DLC001/creatures/bearger/groundpound")
    end
end

local perform_atk_frame = 9
AddStategraphState("wilson", State{
    name = "attack_zeta_smash",
    tags = { "attack", "notalking", "abouttoattack", "autopredict" },

    onenter = function(inst)
        if inst.components.combat:InCooldown() then
            inst.sg:RemoveStateTag("abouttoattack")
            inst:ClearBufferedAction()
            inst.sg:GoToState("idle", true)
            return
        end

        if inst.sg.laststate == inst.sg.currentstate then
            inst.sg.statemem.chained = true
        end

        local buffaction = inst:GetBufferedAction()
        local target = buffaction ~= nil and buffaction.target or nil
        -- local equip = inst.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)
        inst.components.combat:SetTarget(target)
        inst.components.combat:StartAttack()
        inst.components.locomotor:Stop()

        local cooldown = inst.components.combat.min_attack_period

        inst.AnimState:PlayAnimation("pickaxe_pre")
        inst.AnimState:PushAnimation("pickaxe_loop", false)
        inst.SoundEmitter:PlaySound("dontstarve/wilson/attack_whoosh", nil, nil, true)

        cooldown = math.max(cooldown, 21 * FRAMES)
        inst.sg:SetTimeout(cooldown)
        if target ~= nil then
            inst.components.combat:BattleCry()
            if target:IsValid() then
                inst:FacePoint(target:GetPosition())
                inst.sg.statemem.attacktarget = target
                inst.sg.statemem.retarget = target
            end
        end
    end,

    ontimeout = function(inst)
        inst.sg:RemoveStateTag("attack")
        inst.sg:AddStateTag("idle")
    end,

    timeline = {
        TimeEvent(perform_atk_frame * FRAMES, function(inst)
            local buffaction = inst:GetBufferedAction()
            local target = buffaction ~= nil and buffaction.target or nil
            spawn_land_fx(inst, target)

            local damagemultiplier = inst.components.combat.damagemultiplier
            inst.components.combat.damagemultiplier = (damagemultiplier or 1) * TUNING.MELISSA_SLAM_DAMAGE_MULT
            inst:PerformBufferedAction()
            inst.components.combat.damagemultiplier = damagemultiplier
            inst.sg:RemoveStateTag("abouttoattack")
        end)
    },

    events =
    {
        EventHandler("equip", function(inst) inst.sg:GoToState("idle") end),
        EventHandler("unequip", function(inst) inst.sg:GoToState("idle") end),
        EventHandler("animqueueover", function(inst)
            if inst.AnimState:AnimDone() then
                inst.AnimState:PlayAnimation("pickaxe_pst")
                inst.sg:GoToState("idle")
            end
        end),
    },

    onexit = function(inst)
        inst.components.combat:SetTarget(nil)
        if inst.sg:HasStateTag("abouttoattack") then
            inst.components.combat:CancelAttack()
        end
    end,
})

AddStategraphState("wilson_client", State{
    name = "attack_zeta_smash",
    tags = { "attack", "notalking", "abouttoattack" },

    onenter = function(inst)
        local combat = inst.replica.combat
        if combat:InCooldown() then
            inst.sg:RemoveStateTag("abouttoattack")
            inst:ClearBufferedAction()
            inst.sg:GoToState("idle", true)
            return
        end

        local cooldown = combat:MinAttackPeriod()
        if inst.sg.laststate == inst.sg.currentstate then
            inst.sg.statemem.chained = true
        end
        combat:StartAttack()
        inst.components.locomotor:Stop()
        -- local equip = inst.replica.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)

        inst.AnimState:PlayAnimation("pickaxe_pre")
        inst.AnimState:PushAnimation("pickaxe_loop", false)
        inst.SoundEmitter:PlaySound("dontstarve/wilson/attack_whoosh", nil, nil, true)
        if cooldown > 0 then
            cooldown = math.max(cooldown, 21 * FRAMES)
        end

        local buffaction = inst:GetBufferedAction()
        if buffaction ~= nil then
            inst:PerformPreviewBufferedAction()

            if buffaction.target ~= nil and buffaction.target:IsValid() then
                inst:FacePoint(buffaction.target:GetPosition())
                inst.sg.statemem.attacktarget = buffaction.target
                inst.sg.statemem.retarget = buffaction.target
            end
        end

        if cooldown > 0 then
            inst.sg:SetTimeout(cooldown)
        end
    end,

    timeline = {
        TimeEvent(perform_atk_frame * FRAMES, function(inst)
            local buffaction = inst:GetBufferedAction()
            local target = buffaction ~= nil and buffaction.target or nil

            inst:ClearBufferedAction()
            inst.sg:RemoveStateTag("abouttoattack")
        end)
    },

    ontimeout = function(inst)
        inst.sg:RemoveStateTag("attack")
        inst.sg:AddStateTag("idle")
    end,

    events = {
        EventHandler("animqueueover", function(inst)
            if inst.AnimState:AnimDone() then
                inst.AnimState:PlayAnimation("pickaxe_pst")
                inst.sg:GoToState("idle")
            end
        end),
    },

    onexit = function(inst)
        if inst.sg:HasStateTag("abouttoattack") then
            inst.replica.combat:CancelAttack()
        end
    end,
})
