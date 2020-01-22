PrefabFiles = {
  "mutantbeecocoon",
  "mutantbee",
  "mutantbeehive",
  "zeta",
  "zeta_none",
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

  Asset("ANIM", "anim/status_symbiosis.zip"),
  Asset("ANIM", "anim/status_meter_symbiosis.zip"),
  Asset("ANIM", "anim/pollen_fx.zip"),
}

RemapSoundEvent( "dontstarve/characters/zeta/hurt", "zeta/zeta/hurt" )
RemapSoundEvent( "dontstarve/characters/zeta/talk_LP", "zeta/zeta/talk_LP" )
RemapSoundEvent( "dontstarve/characters/zeta/death_voice", "zeta/zeta/death_voice" )
RemapSoundEvent( "dontstarve/characters/zeta/emote", "zeta/zeta/emote" ) --dst
RemapSoundEvent( "dontstarve/characters/zeta/pose", "zeta/zeta/pose" ) --dst
RemapSoundEvent( "dontstarve/characters/zeta/yawn", "zeta/zeta/yawn" ) --dst
RemapSoundEvent( "dontstarve/characters/zeta/ghost_LP", "zeta/zeta/ghost_LP" ) --dst


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
TUNING.OZZY_NUM_POLLENS_PER_HONEY = 5
TUNING.OZZY_SHARE_TARGET_DIST = 30
TUNING.OZZY_MAX_SHARE_TARGETS = 20
TUNING.OZZY_DEFAUT_SPEED_MULTIPLIER = 1.0
TUNING.OZZY_SPRING_SPEED_MULTIPLIER = 1.15
TUNING.OZZY_WINTER_SPEED_MULTIPLIER = 0.85
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
TUNING.MUTANT_BEE_FROSTBITE_SPEED_PENALTY = 0.5
TUNING.MUTANT_BEE_FROSTBITE_ATK_PERIOD_PENALTY = 1.65
TUNING.MUTANT_BEE_WEAPON_ATK_RANGE = 8
TUNING.MUTANT_BEE_RANGED_TARGET_DIST = 10
TUNING.MUTANT_BEE_RANGED_DAMAGE = 15
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
TUNING.MUTANT_BEEHIVE_DEFAULT_EMERGENCY_BEES = 2
TUNING.MUTANT_BEEHIVE_EMERGENCY_BEES_PER_PLAYER = 100
TUNING.MUTANT_BEEHIVE_EMERGENCY_RADIUS = 30
TUNING.MUTANT_BEEHIVE_BEES = 4
TUNING.MUTANT_BEEHIVE_DEFAULT_RELEASE_TIME = 30
TUNING.MUTANT_BEEHIVE_DEFAULT_REGEN_TIME = 30
TUNING.MUTANT_BEEHIVE_DELTA_BEES = 1
TUNING.MUTANT_BEEHIVE_DELTA_RELEASE_TIME = 10
TUNING.MUTANT_BEEHIVE_DELTA_REGEN_TIME = 5
TUNING.MUTANT_BEEHIVE_UPGRADES_PER_STAGE = 3
TUNING.MUTANT_BEEHIVE_WATCH_DIST = 30
TUNING.MUTANT_BEEHIVE_RECOVER_PER_CHILD = 0.75
TUNING.MUTANT_BEEHIVE_GROW_TIME = {TUNING.TOTAL_DAY_TIME * 10, TUNING.TOTAL_DAY_TIME * 10}
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

-- Mod config
local num_bees = GetModConfigData("NUM_BEES_IN_HIVE")
TUNING.MUTANT_BEEHIVE_DEFAULT_EMERGENCY_BEES = TUNING.MUTANT_BEEHIVE_DEFAULT_EMERGENCY_BEES + num_bees * 2
TUNING.MUTANT_BEEHIVE_DEFAULT_REGEN_TIME = TUNING.MUTANT_BEEHIVE_DEFAULT_REGEN_TIME - num_bees * 10

local bee_damage = GetModConfigData("BEE_DAMAGE")
TUNING.MUTANT_BEE_DAMAGE = TUNING.MUTANT_BEE_DAMAGE + bee_damage * 5
TUNING.MUTANT_BEE_ATTACK_PERIOD = TUNING.MUTANT_BEE_ATTACK_PERIOD - bee_damage * 0.5
TUNING.MUTANT_BEE_POISON_DAMAGE = TUNING.MUTANT_BEE_POISON_DAMAGE - bee_damage * 2
TUNING.MUTANT_BEE_RANGED_DAMAGE = TUNING.MUTANT_BEE_RANGED_DAMAGE + bee_damage * 5
TUNING.MUTANT_BEE_RANGED_ATK_PERIOD = TUNING.MUTANT_BEE_RANGED_ATK_PERIOD - bee_damage * 1


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

local function MakeHoneycombUpgrader(prefab)
  if not GLOBAL.TheWorld.ismastersim then
    return
  end

  if not prefab.components.upgrader then
    prefab:AddComponent("upgrader")
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

AddPrefabPostInit("honey", HandleHoneyPerishingInMetapisHive)

local function removefx(inst)
  if inst._pollenfx then
    inst._pollenfx:Remove()
    inst._pollenfx = nil
  end
end

local function spawnfx(inst)
  removefx(inst)

  local fx = SpawnPrefab("pollen_fx")
  fx.entity:SetParent(inst.entity)
  fx.entity:AddFollower():FollowSymbol(inst.GUID, 'flowers01', 0, 0, 0)
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

local function onplayerjoined(inst, player)
  if player:HasTag("beemaster") then
    checkfx(inst)
  else
    removefx(inst)
  end
end

local function FlowerPostInit(prefab)
  if not GLOBAL.TheWorld.ismastersim then
    return
  end

  if not GLOBAL.TheNet:IsDedicated() then
    prefab:ListenForEvent("ms_playerjoined", function(src, player)
      onplayerjoined(prefab, player)
    end, GLOBAL.TheWorld)
  end

  prefab.pollenpicked = false
  prefab.pollenticks = 0

  prefab:DoTaskInTime(0, checkfx)

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

local containers = GLOBAL.require("containers")
local oldwidgetsetup = containers.widgetsetup
local MyChests = {
  mutantbeehive = "treasurechest",
}

containers.widgetsetup = function(container, prefab, data)
  prefab = MyChests[prefab or container.inst.prefab] or prefab
  oldwidgetsetup(container, prefab, data)
end

AddRecipe("mutantbeecocoon",
  {
    Ingredient("honeycomb", 1),
    Ingredient("cutgrass", 4),
    Ingredient("honey", 1)
  },
  RECIPETABS.SURVIVAL,
  TECH.NONE,
  nil, nil, nil, nil,
  "beemaster",
  "images/inventoryimages/mutantbeecocoon.xml",
  "mutantbeecocoon.tex"
)

local armorhoney_rec = AddRecipe("armorhoney",
  {
    Ingredient("log", 10),
    Ingredient("rope", 1),
    Ingredient("honey", 3)
  },
  RECIPETABS.WAR,
  TECH.NONE,
  nil, nil, nil, nil,
  "beemaster",
  "images/inventoryimages/armor_honey.xml",
  "armor_honey.tex"
)
armorhoney_rec.sortkey = -1

local melissa_rec = AddRecipe("melissa",
  {
    Ingredient("twigs", 2),
    Ingredient("goldnugget", 1),
    Ingredient("stinger", 5)
  },
  RECIPETABS.WAR,
  TECH.NONE,
  nil, nil, nil, nil,
  "beemaster",
  "images/inventoryimages/melissa.xml",
  "melissa.tex"
)
melissa_rec.sortkey = -2

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

local mutantdefenderhive_rec = AddRecipe("mutantdefenderhive",
  {
    Ingredient("cutgrass", 1)
  },
  RECIPETABS.TOWN,
  TECH.SCIENCE_TWO,
  "mutantdefenderhive_placer",
  nil, nil, nil,
  "beemaster",
  nil,nil,
  slavehivetestfn
)

local mutantrangerhive_rec = AddRecipe("mutantrangerhive",
  {
    Ingredient("cutgrass", 1)
  },
  RECIPETABS.TOWN,
  TECH.SCIENCE_TWO,
  "mutantrangerhive_placer",
  nil, nil, nil,
  "beemaster",
  nil,nil,
  slavehivetestfn
)

local mutantassassinhive_rec = AddRecipe("mutantassassinhive",
  {
    Ingredient("cutgrass", 1)
  },
  RECIPETABS.TOWN,
  TECH.SCIENCE_TWO,
  "mutantassassinhive_placer",
  nil, nil, nil,
  "beemaster",
  nil,nil,
  slavehivetestfn
)

GLOBAL.ACTIONS.UPGRADE.priority = GLOBAL.ACTIONS.STORE.priority + 1 -- To show over ACTIONS.STORE

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
      self.symbiosis:SetScale(self.brain:GetScale():Get())
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
