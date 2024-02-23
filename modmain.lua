local require = GLOBAL.require
local STRINGS = GLOBAL.STRINGS
local TUNING = GLOBAL.TUNING
local Ingredient = GLOBAL.Ingredient
local TECH = GLOBAL.TECH
local SpawnPrefab = GLOBAL.SpawnPrefab
local Action = GLOBAL.Action
local SEASONS = GLOBAL.SEASONS
local RECIPETABS = GLOBAL.RECIPETABS
--
local _G = GLOBAL
local PREFAB_SKINS = _G.PREFAB_SKINS
local PREFAB_SKINS_IDS = _G.PREFAB_SKINS_IDS
-- local SKIN_AFFINITY_INFO = GLOBAL.require("skin_affinity_info")

PrefabFiles = {
  "mutantbee",
  "mutantbeehive",
  "mutantchildhive",
  "mutantcontainer",
  "zeta",
  "zeta_none",
  "armor_honey",
  "zetapollen",
  "pollen_fx",
  "melissa",
  "shadowspike_fx",
  "electric_bubble",
  "mutantbeehive_lamp",
  "honey_sting_spike",
  "honey_sting_trap"
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
  Asset( "IMAGE", "images/map_icons/mutantbeehive.tex" ),
  Asset( "ATLAS", "images/map_icons/mutantbeehive.xml" ),
  Asset( "IMAGE", "images/map_icons/mutantdefenderhive.tex" ),
  Asset( "ATLAS", "images/map_icons/mutantdefenderhive.xml" ),
  Asset( "IMAGE", "images/map_icons/mutantrangerhive.tex" ),
  Asset( "ATLAS", "images/map_icons/mutantrangerhive.xml" ),
  Asset( "IMAGE", "images/map_icons/mutantassassinhive.tex" ),
  Asset( "ATLAS", "images/map_icons/mutantassassinhive.xml" ),
  Asset( "IMAGE", "images/map_icons/mutantshadowhive.tex" ),
  Asset( "ATLAS", "images/map_icons/mutantshadowhive.xml" ),
  Asset( "IMAGE", "images/map_icons/mutantteleportal.tex" ),
  Asset( "ATLAS", "images/map_icons/mutantteleportal.xml" ),

  Asset( "IMAGE", "images/avatars/avatar_zeta.tex" ),
  Asset( "ATLAS", "images/avatars/avatar_zeta.xml" ),
  Asset( "IMAGE", "images/crafting_menu_avatars/avatar_zeta.tex" ),
  Asset( "ATLAS", "images/crafting_menu_avatars/avatar_zeta.xml" ),
  Asset( "IMAGE", "images/avatars/avatar_ghost_zeta.tex" ),
  Asset( "ATLAS", "images/avatars/avatar_ghost_zeta.xml" ),
  Asset( "IMAGE", "images/avatars/self_inspect_zeta.tex" ),
  Asset( "ATLAS", "images/avatars/self_inspect_zeta.xml" ),

  Asset( "IMAGE", "images/names_zeta.tex" ),
  Asset( "ATLAS", "images/names_zeta.xml" ),

  Asset( "IMAGE", "bigportraits/zeta_none.tex" ),
  Asset( "ATLAS", "bigportraits/zeta_none.xml" ),

  Asset("SOUNDPACKAGE", "sound/zeta.fev"),
  Asset("SOUND", "sound/zeta.fsb"),

  Asset("ANIM", "anim/status_symbiosis.zip"),
  Asset("ANIM", "anim/status_meter_symbiosis.zip"),

  Asset( "IMAGE", "images/inventoryimages/mutantdefenderhive.tex" ),
  Asset( "ATLAS", "images/inventoryimages/mutantdefenderhive.xml" ),
  Asset( "IMAGE", "images/inventoryimages/mutantrangerhive.tex" ),
  Asset( "ATLAS", "images/inventoryimages/mutantrangerhive.xml" ),
  Asset( "IMAGE", "images/inventoryimages/mutantassassinhive.tex" ),
  Asset( "ATLAS", "images/inventoryimages/mutantassassinhive.xml" ),
  Asset( "IMAGE", "images/inventoryimages/mutantshadowhive.tex" ),
  Asset( "ATLAS", "images/inventoryimages/mutantshadowhive.xml" ),
  Asset( "IMAGE", "images/inventoryimages/mutantbarrack.tex" ),
  Asset( "ATLAS", "images/inventoryimages/mutantbarrack.xml" ),
  Asset( "IMAGE", "images/inventoryimages/mutantteleportal.tex" ),
  Asset( "ATLAS", "images/inventoryimages/mutantteleportal.xml" ),
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
}

RemapSoundEvent( "dontstarve/characters/zeta/hurt", "zeta/zeta/hurt" )
RemapSoundEvent( "dontstarve/characters/zeta/talk_LP", "zeta/zeta/talk_LP" )
RemapSoundEvent( "dontstarve/characters/zeta/death_voice", "zeta/zeta/death_voice" )
RemapSoundEvent( "dontstarve/characters/zeta/emote", "zeta/zeta/emote" ) --dst
RemapSoundEvent( "dontstarve/characters/zeta/pose", "zeta/zeta/pose" ) --dst
RemapSoundEvent( "dontstarve/characters/zeta/yawn", "zeta/zeta/yawn" ) --dst
RemapSoundEvent( "dontstarve/characters/zeta/ghost_LP", "zeta/zeta/ghost_LP" ) --dst

-- Stats
TUNING.ZETA_HEALTH = 175
TUNING.ZETA_SANITY = 100
TUNING.ZETA_HUNGER = 150
TUNING.OZZY_DEFAULT_DAMAGE_MULTIPLIER = 0.75
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
TUNING.MUTANT_BEE_DAMAGE = 11
TUNING.MUTANT_BEE_ATTACK_PERIOD = 1.25
TUNING.MUTANT_BEE_TARGET_DIST = 8
TUNING.MUTANT_BEE_WATCH_DIST = 20
TUNING.MUTANT_BEE_MAX_POISON_TICKS = 5
TUNING.MUTANT_BEE_POISON_DAMAGE = 7
TUNING.MUTANT_BEE_POISON_PERIOD = 0.75
TUNING.MUTANT_BEE_FROSTBITE_SPEED_PENALTY = 0.5
TUNING.MUTANT_BEE_FROSTBITE_ATK_PERIOD_PENALTY = 1.25
TUNING.MUTANT_BEE_WEAPON_ATK_RANGE = 8
TUNING.MUTANT_BEE_RANGED_TARGET_DIST = 10
TUNING.MUTANT_BEE_RANGED_DAMAGE = 13
TUNING.MUTANT_BEE_RANGED_ATK_PERIOD = 3
TUNING.MUTANT_BEE_RANGED_HEALTH = 250
TUNING.MUTANT_BEE_DEFENDER_HEALTH = 400
TUNING.MUTANT_BEE_DEFENDER_DAMAGE = 11
TUNING.MUTANT_BEE_DEFENDER_ATTACK_PERIOD = 2
TUNING.MUTANT_BEE_DEFENDER_ATTACK_RANGE = 1.5
TUNING.MUTANT_BEE_DEFENDER_ABSORPTION = 0.5
TUNING.MUTANT_BEE_DEFENDER_TAUNT_DIST = 10
TUNING.MUTANT_BEE_DEFENDER_COLDNESS = 0.75
TUNING.MUTANT_BEE_ASSASSIN_ATTACK_PERIOD = 2
TUNING.MUTANT_BEE_ASSASSIN_BACKSTAB_DAMAGE_MULT = 1.25
TUNING.MUTANT_BEE_ASSSASIN_HEALTH = 300
TUNING.MUTANT_BEE_ASSSASIN_DAMAGE = 17
TUNING.MUTANT_BEE_SOLDIER_HEALTH = 350
TUNING.MUTANT_BEE_SOLDIER_ABSORPTION = 0.25
TUNING.MUTANT_BEE_SOLDIER_HEAL_DIST = 8
TUNING.MUTANT_BEE_SHADOW_HEALTH = 250
TUNING.MUTANT_BEE_SHADOW_DAMAGE = 13
TUNING.MUTANT_BEE_SHADOW_ATK_PERIOD = 4
TUNING.MUTANT_BEE_SHADOW_ATK_RANGE = 5
TUNING.MUTANT_BEE_SHADOW_DEFAULT_NUM_SPIKES = 2

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
TUNING.MELISSA_USES = 200

-- Sting trap
TUNING.STING_TRAP_USES = 250
TUNING.STING_TRAP_DAMAGE = 10
TUNING.STING_TRAP_DEFAULT_SPEED_PENALTY = 0.6
TUNING.STING_TRAP_EPIC_SPEED_PENALTY = 0.75

-- The character select screen lines
STRINGS.CHARACTER_TITLES.zeta = "The Buzzy"
STRINGS.CHARACTER_NAMES.zeta = "Wuzzy"
STRINGS.CHARACTER_DESCRIPTIONS.zeta = "*Leads his own species and hive\n*Fights alongside his symbiotic bees\n*Can pick pollen from flowers\n*Loves honeyed foods"
STRINGS.CHARACTER_QUOTES.zeta = "\"Bees together strong.\""
STRINGS.CHARACTER_SURVIVABILITY.zeta = "Grim"
STRINGS.SKIN_NAMES.zeta_none = 'Wuzzy'
STRINGS.SKIN_DESCRIPTIONS.zeta_none = 'The look of the bee master'

-- Custom speech strings
STRINGS.CHARACTERS.ZETA = require "speech_zeta"

-- The character's name as appears in-game
STRINGS.NAMES.ZETA = "Wuzzy"

AddMinimapAtlas("images/map_icons/zeta.xml")
AddMinimapAtlas("images/map_icons/mutantbeecocoon.xml")
AddMinimapAtlas("images/map_icons/mutantbeehive.xml")
AddMinimapAtlas("images/map_icons/mutantdefenderhive.xml")
AddMinimapAtlas("images/map_icons/mutantrangerhive.xml")
AddMinimapAtlas("images/map_icons/mutantassassinhive.xml")
AddMinimapAtlas("images/map_icons/mutantshadowhive.xml")
AddMinimapAtlas("images/map_icons/mutantteleportal.xml")

--Skins api
-- modimport("scripts/tools/skins_api")
PREFAB_SKINS["zeta"] = {
  "zeta_none"
}
PREFAB_SKINS_IDS = {}
for prefab,skins in pairs(PREFAB_SKINS) do
    PREFAB_SKINS_IDS[prefab] = {}
    for k,v in pairs(skins) do
          PREFAB_SKINS_IDS[prefab][v] = k
    end
end

-- Add mod character to mod character list. Also specify a gender. Possible genders are MALE, FEMALE, ROBOT, NEUTRAL, and PLURAL.
local skin_modes = {
  {
    type = "ghost_skin",
    anim_bank = "ghost",
    idle_anim = "idle",
    scale = 0.75,
    offset = { 0, -25 }
  },
}
AddModCharacter("zeta", "MALE", skin_modes)

-- Post init
local function HandleHoneyPerishingInMetapisHive(prefab)
  if prefab.components.perishable and prefab.components.inventoryitem then
    local OldOnPutInInventory = prefab.components.inventoryitem.onputininventoryfn or function() return end
    prefab.components.inventoryitem:SetOnPutInInventoryFn(function(inst, owner)
      if owner and owner.prefab == "mutantcontainer" then
        inst.components.perishable:StopPerishing()
      end

      OldOnPutInInventory(inst, owner)
    end)


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
  if inst.pollenticks > 0 and
    not inst._pollentask and
    GLOBAL.TheWorld.state.season ~= SEASONS.WINTER then
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
  prefab:DoTaskInTime(0, function()
    prefab.net_pollenpicked:set(prefab.pollenpicked)
  end)

  prefab.pollenticks = 0

  prefab:DoTaskInTime(0, onseasonchange)

  prefab:WatchWorldState("season", onseasonchange)

  if prefab.components.pickable then
    local oldonpickedfn = prefab.components.pickable.onpickedfn
    prefab.components.pickable.onpickedfn = function(inst, picker)
      if picker and picker.prefab == 'zeta' then
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
      if picker and picker.prefab == 'zeta' then
        if not comp.inst.pollenpicked then
          local product = comp.product
          local numtoharvest = comp.numtoharvest
          local remove_when_picked = comp.remove_when_picked

          comp.product = 'zetapollen'
          comp.numtoharvest = (GLOBAL.TheWorld.state.season == SEASONS.SPRING and math.random() <= 0.5) and 2 or 1
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


local function RangerHiveBlueprintPostInit(prefab)
  if not GLOBAL.TheWorld.ismastersim then
    return
  end

  if prefab.components.teacher then
    local oldTeach = prefab.components.teacher.Teach
    prefab.components.teacher.Teach = function(comp, target, ...)
      if target and not target:HasTag("beemaster") then
        return false, "CANTLEARN"
      end

      return oldTeach(comp, target, ...)
    end
  end
end

AddPrefabPostInit("mutantrangerhive_blueprint", RangerHiveBlueprintPostInit)

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

-- Recipes
local containers = GLOBAL.require("containers")
local oldwidgetsetup = containers.widgetsetup
local MyChests = {
  mutantcontainer = "treasurechest",
}

containers.widgetsetup = function(container, prefab, data)
  prefab = MyChests[prefab or container.inst.prefab] or prefab
  oldwidgetsetup(container, prefab, data)
end

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
  local possiblemasters = GLOBAL.TheSim:FindEntities(x, y, z,
    TUNING.MUTANT_BEEHIVE_MASTER_SLAVE_DIST,
    { "mutantbeehive" }
  )

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
  TECH.LOST,
  {
    atlas = "images/inventoryimages/mutantrangerhive.xml",
    image = "mutantrangerhive.tex",
    placer = "mutantrangerhive_placer",
    testfn = slavehivetestfn
  },
  {
    "CHARACTER"
  }
)

AddCharacterRecipe(
  "hermitshop_mutantrangerhive_blueprint",
  {
    Ingredient("messagebottleempty", 3)
  },
  TECH.HERMITCRABSHOP_FIVE,
  {
    builder_tag = "beemaster",
    image = "blueprint.tex",
    product = "mutantrangerhive_blueprint"
  }
)

STRINGS.RECIPE_DESC.MUTANTRANGERHIVE_BLUEPRINT = "Adds Metapis Ranger to Mother Hive."
STRINGS.NAMES.MUTANTRANGERHIVE_BLUEPRINT = "Metapis Ranger Hive Blueprint"

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
    Ingredient("purplegem", 3),
  },
  TECH.MAGIC_THREE,
  {
    builder_tag = "beemaster",
    atlas = "images/inventoryimages/mutantteleportal.xml",
    image = "mutantteleportal.tex",
    placer = "mutantteleportal_placer"
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

AddCharacterRecipe(
  "honey_sting_ball",
  {
    Ingredient("honey", 5),
    Ingredient("stinger", 5),
    Ingredient("cutgrass", 2),
  },
  TECH.SCIENCE_ONE,
  {
    builder_tag = "beemaster",
    atlas = "images/inventoryimages/honey_sting_ball.xml",
    image = "honey_sting_ball.tex",
  },
  {
    "WEAPONS"
  }
)

GLOBAL.CONSTRUCTION_PLANS["mutantbeehive"] = { Ingredient("honeycomb", 3) }
GLOBAL.CONSTRUCTION_PLANS["mutantbeehive_level2"] = { Ingredient("royal_jelly", 3) }

GLOBAL.ACTIONS.MUTANTBEE_DESPAWN = Action()
GLOBAL.ACTIONS.MUTANTBEE_DESPAWN.fn = function(act)
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
  if self.owner.prefab == 'zeta' then
    self.symbiosis = self:AddChild(Badge(nil, self.owner, { 48 / 255, 169 / 255, 169 / 255, 1 }, "status_symbiosis"))
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
  if inst.prefab ~= 'zeta' then
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
    inst:DoTaskInTime(0, function() inst:PushEvent("onregentick", {currenttick = 0}) end)
  end

  if not GLOBAL.TheNet:IsDedicated() then
    inst:ListenForEvent("symbiosisdirty", onsymbiosisdirty)
  end
end

AddPlayerPostInit(PlayerPostConstruct)
