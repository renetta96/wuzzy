PrefabFiles = {
  "mutantbeecocoon",
  "mutantbee",
  "mutantbeehive",
  "zeta",
  "armor_honey"
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
  Asset( "IMAGE", "images/map_icons/mutantbeehive.tex" ),
  Asset( "ATLAS", "images/map_icons/mutantbeehive.xml" ),

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

  Asset("SOUNDPACKAGE", "sound/zeta.fev"),
  Asset("SOUND", "sound/zeta.fsb"),

  Asset("ANIM", "anim/symbiosis.zip"),
}

local function CheckDlcEnabled(dlc)
  -- if the constant doesn't even exist, then they can't have the DLC
  if not GLOBAL.rawget(GLOBAL, dlc) then return false end
  GLOBAL.assert(GLOBAL.rawget(GLOBAL, "IsDLCEnabled"), "Old version of game, please update (IsDLCEnabled function missing)")
  return GLOBAL.IsDLCEnabled(GLOBAL[dlc])
end

RemapSoundEvent( "dontstarve/characters/zeta/hurt", "zeta/zeta/hurt" )
RemapSoundEvent( "dontstarve/characters/zeta/talk_LP", "zeta/zeta/talk_LP" )
RemapSoundEvent( "dontstarve/characters/zeta/death_voice", "zeta/zeta/death_voice" )


local require = GLOBAL.require
local STRINGS = GLOBAL.STRINGS
local TUNING = GLOBAL.TUNING
local Ingredient = GLOBAL.Ingredient
local RECIPETABS = GLOBAL.RECIPETABS
local TECH = GLOBAL.TECH

-- Stats
TUNING.OZZY_MAX_HEALTH = 175
TUNING.OZZY_MAX_SANITY = 100
TUNING.OZZY_MAX_HUNGER = 125
TUNING.OZZY_DEFAULT_DAMAGE_MULTIPLIER = 0.75
TUNING.OZZY_HUNGER_SCALE = 1.1
TUNING.OZZY_NUM_PETALS_PER_HONEY = 5
TUNING.OZZY_SHARE_TARGET_DIST = 30
TUNING.OZZY_MAX_SHARE_TARGETS = 20
TUNING.OZZY_DEFAUT_SPEED_MULTIPLIER = 0
TUNING.OZZY_SPRING_SPEED_MULTIPLIER = 0.15
TUNING.OZZY_WINTER_SPEED_MULTIPLIER = -0.15
TUNING.OZZY_MAX_SUMMON_BEES = 3
TUNING.OZZY_SUMMON_CHANCE = 0.3
TUNING.OZZY_MAX_BEES_STORE = 7

-- Mutant bee stats
TUNING.MUTANT_BEE_HEALTH = 100
TUNING.MUTANT_BEE_DAMAGE = 10
TUNING.MUTANT_BEE_ATTACK_PERIOD = 1
TUNING.MUTANT_BEE_TARGET_DIST = 8
TUNING.MUTANT_BEE_WATCH_DIST = 20
TUNING.MUTANT_BEE_MAX_POISON_TICKS = 5
TUNING.MUTANT_BEE_POISON_DAMAGE = 5
TUNING.MUTANT_BEE_POISON_PERIOD = 0.75
TUNING.MUTANT_BEE_EXPLOSIVE_DAMAGE_MULTIPLIER = 3.0
TUNING.MUTANT_BEE_EXPLOSIVE_RANGE = 8
TUNING.MUTANT_BEE_FROSTBITE_SPEED_PENALTY_MIN = 0.3
TUNING.MUTANT_BEE_FROSTBITE_SPEED_PENALTY_MAX = 0.6
TUNING.MUTANT_BEE_FROSTBITE_ATK_PERIOD_PENALTY_MIN = 1.35
TUNING.MUTANT_BEE_FROSTBITE_ATK_PERIOD_PENALTY_MAX = 1.65
TUNING.MUTANT_BEE_COLDNESS_ADD = 0.5
TUNING.MUTANT_BEE_WEAPON_ATK_RANGE = 10
TUNING.MUTANT_BEE_RANGED_TARGET_DIST = 10
TUNING.MUTANT_BEE_RANGED_ATK_HEALTH_PENALTY = 1 / 10
TUNING.MUTANT_BEE_RANGED_DAMAGE = 15
TUNING.MUTANT_BEE_RANGED_ATK_PERIOD = 2.5

-- Mutant beehive stats
TUNING.MUTANT_BEEHIVE_BEES = 5
TUNING.MUTANT_BEEHIVE_DEFAULT_RELEASE_TIME = 50
TUNING.MUTANT_BEEHIVE_DEFAULT_REGEN_TIME = 30
TUNING.MUTANT_BEEHIVE_DELTA_BEES = 1
TUNING.MUTANT_BEEHIVE_DELTA_RELEASE_TIME = 5
TUNING.MUTANT_BEEHIVE_DELTA_REGEN_TIME = 5
TUNING.MUTANT_BEEHIVE_UPGRADES_PER_STAGE = 3
TUNING.MUTANT_BEEHIVE_WATCH_DIST = 30
TUNING.MUTANT_BEEHIVE_RECOVER_PER_CHILD = 0.75
TUNING.MUTANT_BEEHIVE_GROW_TIME = {TUNING.TOTAL_DAY_TIME * 8, TUNING.TOTAL_DAY_TIME * 8}

-- Armor honey
TUNING.ARMORHONEY_MAX_ABSORPTION = 0.55
TUNING.ARMORHONEY_MIN_ABSORPTION = 0.3
TUNING.ARMORHONEY_HEAL_TICKS = 5
TUNING.ARMORHONEY_HEAL_INTERVAL = 1
TUNING.ARMORHONEY_MIN_HEAL_PERCENT = 0.01
TUNING.ARMORHONEY_MAX_HEAL_PERCENT = 0.03
TUNING.ARMORHONEY_MIN_HEAL_EXTRA = 1
TUNING.ARMORHONEY_MAX_HEAL_EXTRA = 3
TUNING.ARMORHONEY_ADD_STORE = 1
TUNING.ARMORHONEY_MULT_REGEN_TICK = 2 / 3

-- Parasite
TUNING.METAPIS_PARASITE_HEALTH_DIV = 200
TUNING.METAPIS_MAX_PARASITES_PER_VICTIM = 4
TUNING.METAPIS_PARASITE_NEAR_OWNER_SPAWN_RANGE = 20
TUNING.METAPIS_PARASITE_HEALTH_RATE = 0.5
TUNING.METAPIS_PARASITE_DAMAGE_RATE = 0.5
TUNING.METAPIS_PARASITE_LIFE_SPAN = 30

-- Mod config
local num_bees = GetModConfigData("NUM_BEES_IN_HIVE")
TUNING.MUTANT_BEEHIVE_BEES = TUNING.MUTANT_BEEHIVE_BEES + num_bees * 2
TUNING.MUTANT_BEEHIVE_DEFAULT_REGEN_TIME = TUNING.MUTANT_BEEHIVE_DEFAULT_REGEN_TIME - num_bees * 10

local bee_damage = GetModConfigData("BEE_DAMAGE")
TUNING.MUTANT_BEE_DAMAGE = TUNING.MUTANT_BEE_DAMAGE + bee_damage * 5
TUNING.MUTANT_BEE_ATTACK_PERIOD = TUNING.MUTANT_BEE_ATTACK_PERIOD - bee_damage * 0.5
TUNING.MUTANT_BEE_POISON_DAMAGE = TUNING.MUTANT_BEE_POISON_DAMAGE - bee_damage * 2
TUNING.MUTANT_BEE_RANGED_DAMAGE = TUNING.MUTANT_BEE_RANGED_DAMAGE + bee_damage * 5
TUNING.MUTANT_BEE_RANGED_ATK_PERIOD = TUNING.MUTANT_BEE_RANGED_ATK_PERIOD - bee_damage * 1


-- The character select screen lines
STRINGS.CHARACTER_TITLES.zeta = "The Buzzy"
STRINGS.CHARACTER_NAMES.zeta = "Ozzy"
STRINGS.CHARACTER_DESCRIPTIONS.zeta = "*Has his own hive\n*Produces honey by eating petals\n*Summons bees by chance on attack"
STRINGS.CHARACTER_QUOTES.zeta = "\"Let's beefriend!\""

-- Custom speech strings
STRINGS.CHARACTERS.ZETA = require "speech_zeta"

-- The character's name as appears in-game
STRINGS.NAMES.ZETA = "Ozzy"

AddMinimapAtlas("images/map_icons/zeta.xml")
AddMinimapAtlas("images/map_icons/mutantbeecocoon.xml")
AddMinimapAtlas("images/map_icons/mutantbeehive.xml")

-- Add mod character to mod character list. Also specify a gender. Possible genders are MALE, FEMALE, ROBOT, NEUTRAL, and PLURAL.
AddModCharacter("zeta", "MALE")

local function CanUpgradeMetapisHive(inst, target, doer)
  return doer:HasTag("beemaster")
end

local function MakeHoneycombUpgrader(prefab)
  if not prefab.components.upgrader then
    prefab:AddComponent("upgrader")
    prefab.components.upgrader.canupgradefn = CanUpgradeMetapisHive
    prefab.components.upgrader.upgradetype = "METAPIS"
  end
end

AddPrefabPostInit("honeycomb", MakeHoneycombUpgrader)

local function HandleHoneyPerishingInMetapisHive(prefab)
  if prefab.components.perishable and prefab.components.inventoryitem then
    local OldOnPutInInventory = prefab.components.inventoryitem.onputininventoryfn or function() return end
    prefab.components.inventoryitem:SetOnPutInInventoryFn(function(inst, owner)
      if owner.prefab == "mutantbeehive" then
        inst.components.perishable:StopPerishing()
      end

      OldOnPutInInventory(inst, owner)
    end)

    if CheckDlcEnabled("PORKLAND_DLC") then
      local OldOnRemoved = prefab.components.inventoryitem.onRemovedfn or function() return end
      prefab.components.inventoryitem:SetOnRemovedFn(function(inst, owner)
        if owner.prefab == "mutantbeehive" then
          inst.components.perishable:StartPerishing()
        end

        OldOnRemoved(inst, owner)
      end)
    else
      local inventoryitem = prefab.components.inventoryitem
      local OldOnRemoved = inventoryitem.OnRemoved
      local onremovedfn = function(inst, owner)
        if owner.prefab == "mutantbeehive" then
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
end

AddPrefabPostInit("honey", HandleHoneyPerishingInMetapisHive)

local Recipe = GLOBAL.Recipe

local myrecipe = Recipe("mutantbeecocoon",
  {
    Ingredient("honeycomb", 1),
    Ingredient("cutgrass", 4),
    Ingredient("honey", 1)
  },
  RECIPETABS.SURVIVAL,
  TECH.NONE
)
myrecipe.atlas = "images/inventoryimages/mutantbeecocoon.xml"

local myrecipe = Recipe("armorhoney",
  {
    Ingredient("log", 10),
    Ingredient("rope", 1),
    Ingredient("honey", 3)
  },
  RECIPETABS.WAR,
  TECH.NONE
)
myrecipe.atlas = "images/inventoryimages/armorhoney.xml"

local Badge = require("widgets/badge")

local function OnRegenTick(inst, data, badge)
  badge:SetPercent(inst.components.beesummoner:GetRegenTickPercent(), inst.components.beesummoner.maxticks)
  badge.num:SetString(GLOBAL.tostring(inst.components.beesummoner.numstore))
  if data.currenttick > 0 then
    badge:PulseGreen()
    -- GLOBAL.TheFrontEnd:GetSound():PlaySound("dontstarve/HUD/health_up")
  end
end

local function OnNumStoreChange(inst, data, badge)
  badge.num:SetString(GLOBAL.tostring(inst.components.beesummoner.numstore))
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
  if self.owner.components.beesummoner then
    local pos = CalcSymbiosisPosition(self)
    self.symbiosis = self:AddChild(Badge("health", self.owner))
    self.symbiosis.anim:GetAnimState():SetBuild("symbiosis")
    self.symbiosis:SetPosition(pos:Get())
    self.symbiosis:SetScale(self.brain:GetScale():Get())
    self.symbiosis:SetPercent(
      self.owner.components.beesummoner:GetRegenTickPercent(),
      self.owner.components.beesummoner.maxticks
    )
    self.symbiosis.num:SetString(GLOBAL.tostring(self.owner.components.beesummoner.numstore))
    self.symbiosis.num:Show()
    self.symbiosis.inst:ListenForEvent("onregentick",
      function(inst, data) OnRegenTick(inst, data, self.symbiosis) end,
      self.owner)
    self.symbiosis.inst:ListenForEvent("onnumstorechange",
      function(inst, data) OnNumStoreChange(inst, data, self.symbiosis) end,
      self.owner)

    local OldOnLoseFocus = self.symbiosis.OnLoseFocus
    self.symbiosis.OnLoseFocus = function(badge)
      OldOnLoseFocus(badge)
      badge.num:Show()
    end
  end
end

AddClassPostConstruct("widgets/statusdisplays", StatusPostConstruct)
