PrefabFiles = {
  "mutantbeecocoon",
  "mutantbee",
  "mutantbeehive",
  "zeta",
  "armor_honey",
  "zetapollen",
  "pollen_fx",
  "melissa"
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
  Asset( "IMAGE", "images/map_icons/mutantdefenderhive.tex" ),
  Asset( "ATLAS", "images/map_icons/mutantdefenderhive.xml" ),
  Asset( "IMAGE", "images/map_icons/mutantrangerhive.tex" ),
  Asset( "ATLAS", "images/map_icons/mutantrangerhive.xml" ),
  Asset( "IMAGE", "images/map_icons/mutantassassinhive.tex" ),
  Asset( "ATLAS", "images/map_icons/mutantassassinhive.xml" ),

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
  Asset("ANIM", "anim/pollen_fx.zip"),

  Asset( "IMAGE", "images/inventoryimages/mutantdefenderhive.tex" ),
  Asset( "ATLAS", "images/inventoryimages/mutantdefenderhive.xml" ),
  Asset( "IMAGE", "images/inventoryimages/mutantrangerhive.tex" ),
  Asset( "ATLAS", "images/inventoryimages/mutantrangerhive.xml" ),
  Asset( "IMAGE", "images/inventoryimages/mutantassassinhive.tex" ),
  Asset( "ATLAS", "images/inventoryimages/mutantassassinhive.xml" ),
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
local SpawnPrefab = GLOBAL.SpawnPrefab

-- Stats
TUNING.OZZY_MAX_HEALTH = 175
TUNING.OZZY_MAX_SANITY = 100
TUNING.OZZY_MAX_HUNGER = 125
TUNING.OZZY_DEFAULT_DAMAGE_MULTIPLIER = 0.75
TUNING.OZZY_HUNGER_SCALE = 1.1
TUNING.OZZY_NUM_POLLENS_PER_HONEY  = 5
TUNING.OZZY_SHARE_TARGET_DIST = 30
TUNING.OZZY_MAX_SHARE_TARGETS = 20
TUNING.OZZY_DEFAUT_SPEED_MULTIPLIER = 0
TUNING.OZZY_SPRING_SPEED_MULTIPLIER = 0.15
TUNING.OZZY_WINTER_SPEED_MULTIPLIER = -0.15
TUNING.OZZY_MAX_SUMMON_BEES = 4
TUNING.OZZY_SUMMON_CHANCE = 0.3
TUNING.OZZY_MAX_BEES_STORE = 7
TUNING.OZZY_HONEYED_FOOD_BONUS = 0.35
TUNING.OZZY_PICK_FLOWER_SANITY = -3 * TUNING.SANITY_TINY

-- Mutant bee stats
TUNING.MUTANT_BEE_HEALTH = 100
TUNING.MUTANT_BEE_DAMAGE = 7
TUNING.MUTANT_BEE_ATTACK_PERIOD = 1
TUNING.MUTANT_BEE_TARGET_DIST = 8
TUNING.MUTANT_BEE_WATCH_DIST = 20
TUNING.MUTANT_BEE_MAX_POISON_TICKS = 5
TUNING.MUTANT_BEE_POISON_DAMAGE = 5
TUNING.MUTANT_BEE_POISON_PERIOD = 0.75
TUNING.MUTANT_BEE_EXPLOSIVE_DAMAGE_MULTIPLIER = 1.0
TUNING.MUTANT_BEE_EXPLOSIVE_RANGE = 3
TUNING.MUTANT_BEE_FROSTBITE_SPEED_PENALTY = -0.5
TUNING.MUTANT_BEE_FROSTBITE_ATK_PERIOD_PENALTY = 0.65
TUNING.MUTANT_BEE_WEAPON_ATK_RANGE = 8
TUNING.MUTANT_BEE_RANGED_TARGET_DIST = 10
TUNING.MUTANT_BEE_RANGED_DAMAGE = 10
TUNING.MUTANT_BEE_RANGED_ATK_PERIOD = 2.5
TUNING.MUTANT_BEE_RANGED_HEATLH = 50
TUNING.MUTANT_BEE_DEFENDER_HEALTH = 300
TUNING.MUTANT_BEE_DEFENDER_DAMAGE = 5
TUNING.MUTANT_BEE_DEFENDER_ATTACK_PERIOD = 2
TUNING.MUTANT_BEE_DEFENDER_ATTACK_RANGE = 1.5
TUNING.MUTANT_BEE_DEFENDER_ABSORPTION = 0.5
TUNING.MUTANT_BEE_DEFENDER_TAUNT_DIST = 10
TUNING.MUTANT_BEE_ASSASSIN_ATTACK_PERIOD = 1.5
TUNING.MUTANT_BEE_ASSASSIN_BACKSTAB_DAMAGE_MULT = 1.5
TUNING.MUTANT_BEE_ASSSASIN_HEALTH = 75
TUNING.MUTANT_BEE_ASSSASIN_DAMAGE = 10
TUNING.MUTANT_BEE_SOLDIER_HEALTH = 150
TUNING.MUTANT_BEE_SOLDIER_ABSORPTION = 0.25

-- Mutant beehive stats
TUNING.MUTANT_BEEHIVE_BEES = 4
TUNING.MUTANT_BEEHIVE_DEFAULT_RELEASE_TIME = 30
TUNING.MUTANT_BEEHIVE_DEFAULT_REGEN_TIME = 30
TUNING.MUTANT_BEEHIVE_DELTA_BEES = 1
TUNING.MUTANT_BEEHIVE_DELTA_RELEASE_TIME = 10
TUNING.MUTANT_BEEHIVE_DELTA_REGEN_TIME = 5
TUNING.MUTANT_BEEHIVE_UPGRADES_PER_STAGE = 3
TUNING.MUTANT_BEEHIVE_WATCH_DIST = 30
TUNING.MUTANT_BEEHIVE_RECOVER_PER_CHILD = 0.75
TUNING.MUTANT_BEEHIVE_GROW_TIME = {TUNING.TOTAL_DAY_TIME * 8, TUNING.TOTAL_DAY_TIME * 8}
TUNING.MUTANT_BEEHIVE_MAX_HONEYS_PER_CYCLE = 3
TUNING.MUTANT_BEEHIVE_NUM_POLLENS_PER_HONEY = 3
TUNING.MUTANT_BEEHIVE_MASTER_SLAVE_DIST = 10
TUNING.MUTANT_BEEHIVE_CHILDREN_PER_SLAVE = 2

-- Armor honey
TUNING.ARMORHONEY_MAX_ABSORPTION = 0.65
TUNING.ARMORHONEY_MIN_ABSORPTION = 0.35
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

-- Melissa
TUNING.MELISSA_MIN_DAMAGE = 34
TUNING.MELISSA_MAX_DAMAGE = 34 * 2.25
TUNING.MELISSA_MAX_DAMAGE_HUNGER_THRESHOLD = 0.75
TUNING.MELISSA_MIN_DAMAGE_HUNGER_THRESHOLD = 0.15
TUNING.MELISSA_MIN_HUNGER_DRAIN = 1
TUNING.MELISSA_PERCENT_HUNGER_DRAIN = 0.01
TUNING.MELISSA_USES = 200


-- The character select screen lines
STRINGS.CHARACTER_TITLES.zeta = "The Buzzy"
STRINGS.CHARACTER_NAMES.zeta = "Wuzzy"
STRINGS.CHARACTER_DESCRIPTIONS.zeta = "*Leads his own species and hive\n*Has symbotic bees inside his body\n*Can pick pollen from flowers\n*Loves honeyed foods"
STRINGS.CHARACTER_QUOTES.zeta = "\"Bees together strong.\""

-- Custom speech strings
STRINGS.CHARACTERS.ZETA = require "speech_zeta"

-- The character's name as appears in-game
STRINGS.NAMES.ZETA = "Wuzzy"

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
      if owner and owner.prefab == "mutantbeehive" then
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

local function removefx(inst)
  print('REMOVE FX')
  if inst._pollenfx then
    inst._pollenfx:Remove()
    inst._pollenfx = nil
  end
end

local function spawnfx(inst)
  removefx(inst)

  local fx = SpawnPrefab("pollen_fx")
  fx.entity:SetParent(inst.entity)
  inst._pollenfx = fx
end

local function checkfx(inst)
  if not inst.pollenpicked then
    spawnfx(inst)
  else
    removefx(inst)
  end
end

local function ontick(inst)
  inst.pollenticks = inst.pollenticks - 1
  if inst.pollenticks > 0 then
    inst:DoTaskInTime(100, ontick)
  else
    inst.pollenpicked = false
    checkfx(inst)
  end
end

local function onpickedflowerfn(inst, picker)
  if picker ~= nil and not inst.pollenpicked then
    if picker.components.sanity ~= nil and not picker:HasTag("plantkin") then
      picker.components.sanity:DoDelta(TUNING.SANITY_TINY)
    end

    inst.pollenpicked = true
    inst.pollenticks = 5
    inst:DoTaskInTime(100, ontick)
    checkfx(inst)
  end
end

local function onplayerjoined(inst)
  if GLOBAL.GetPlayer():HasTag("beemaster") then
    checkfx(inst)
  else
    removefx(inst)
  end
end

local function FlowerPostInit(prefab)
  prefab.pollenpicked = false
  prefab.pollenticks = 0

  prefab:DoTaskInTime(0, onplayerjoined)

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
          comp.product = 'zetapollen'
          PickFn(comp, picker, ...)
          comp.product = product
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
      inst.pollenticks = data ~= nil and data.pollenticks or 0
      if inst.pollenticks > 0 then
        inst:DoTaskInTime(100, ontick)
      end

      checkfx(inst)
    end

  end
end

AddPrefabPostInit("flower", FlowerPostInit)
AddPrefabPostInit("flower_rainforest", FlowerPostInit)

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

local function WaspHivePostInit(prefab)
  if prefab.components.playerprox then
    local oldOnNearFn = prefab.components.playerprox.onnear
    local onnearfn = function(inst)
      if GLOBAL.GetPlayer():HasTag("beemaster") then
        return
      end

      if oldOnNearFn ~= nil then
        oldOnNearFn(inst)
      end
    end
    prefab.components.playerprox:SetOnPlayerNear(onnearfn)
  end
end

AddPrefabPostInit("wasphive", WaspHivePostInit)

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

local function UpdateSymbiosisPosScale(self)
  local pos = CalcSymbiosisPosition(self)
  self.symbiosis:SetPosition(pos:Get())
  self.symbiosis:SetScale(self.brain:GetScale():Get())
end

local function StatusPostConstruct(self)
  if self.owner.components.beesummoner then
    self.symbiosis = self:AddChild(Badge("health", self.owner))
    self.symbiosis.anim:GetAnimState():SetBuild("symbiosis")

    UpdateSymbiosisPosScale(self)

    self.symbiosis:SetPercent(
      self.owner.components.beesummoner:GetRegenTickPercent(),
      self.owner.components.beesummoner.maxticks
    )
    self.symbiosis.num:SetString(GLOBAL.tostring(self.owner.components.beesummoner.numstore))
    self.symbiosis.num:Show()
    self.symbiosis.inst:ListenForEvent("onregentick",
      function(inst, data)
        OnRegenTick(inst, data, self.symbiosis)
        UpdateSymbiosisPosScale(self)
      end,
      self.owner)
    self.symbiosis.inst:ListenForEvent("onnumstorechange",
      function(inst, data)
        OnNumStoreChange(inst, data, self.symbiosis)
        UpdateSymbiosisPosScale(self)
      end,
      self.owner)

    local OldOnLoseFocus = self.symbiosis.OnLoseFocus
    self.symbiosis.OnLoseFocus = function(badge)
      OldOnLoseFocus(badge)
      badge.num:Show()
    end
  end
end

AddClassPostConstruct("widgets/statusdisplays", StatusPostConstruct)
