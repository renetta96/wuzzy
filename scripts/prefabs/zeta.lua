local MakePlayerCharacter = require "prefabs/player_common"
local metapisutil = require "metapisutil"

local assets = {
  Asset("SCRIPT", "scripts/prefabs/player_common.lua"),
  Asset("ANIM", "anim/zeta.zip"),
}
local prefabs = {
  "mutantbeecocoon",
  "honey"
}

-- Custom starting items
local start_inv = {
  "mutantbeecocoon",
  "honey",
  "honey",
  "honey"
}

local tagtoprefab = {
  defender="mutantdefenderbee",
  soldier="mutantkillerbee",
  ranger="mutantrangerbee",
  assassin="mutantassassinbee"
}

local function CanSummon(inst, prefab)
  if not inst._hive then
    return false
  end

  return inst._hive:CanSpawn(prefab)
end

local function GetChildPrefab(inst)
  local maxchildren = inst.components.beesummoner.maxchildren
  local expect = {
    mutantkillerbee = maxchildren,
    mutantdefenderbee = 0,
    mutantrangerbee = 0,
    mutantassassinbee = 0
  }

  local cansummon = {"mutantkillerbee"}

  for i, prefab in ipairs({"mutantdefenderbee", "mutantrangerbee", "mutantassassinbee"}) do
    if CanSummon(inst, prefab) then
      expect[prefab] = expect[prefab] + math.floor(maxchildren / 4)
      expect["mutantkillerbee"] = expect["mutantkillerbee"] - math.floor(maxchildren / 4)
      table.insert(cansummon, prefab)
    end
  end

  local prefabcount = {
    mutantdefenderbee = 0,
    mutantkillerbee = 0,
    mutantrangerbee = 0,
    mutantassassinbee = 0
  }

  for i, child in pairs(inst.components.beesummoner.children) do
    if child ~= nil and child:IsValid() then
      prefabcount[child.prefab] = prefabcount[child.prefab] + 1
    end
  end

  local prefabstopick = {}
  for prefab, cnt in pairs(prefabcount) do
    if cnt < expect[prefab] then
      table.insert(prefabstopick, prefab)

      -- Prioritize defender
      if prefab == "mutantdefenderbee" then
        return prefab
      end
    end
  end

  if #prefabstopick == 0 then
    prefabstopick = cansummon
  end

  return prefabstopick[math.random(#prefabstopick)]
end

local function OnEat(inst, data)
  if data.food and data.food.prefab == "zetapollen" then
    inst._eatenpollens = inst._eatenpollens + 1
    if (inst._eatenpollens >= TUNING.OZZY_NUM_POLLENS_PER_HONEY) then
      local honey = SpawnPrefab("honey")
      inst.components.inventory:GiveItem(honey)
      inst._eatenpollens = 0
    end

    return
  end

  if data.food and data.food:HasTag("honeyed") then
    local food = data.food
    local bonus = TUNING.OZZY_HONEYED_FOOD_BONUS

    if inst.components.health then
      local delta = food.components.edible:GetHealth(inst) * inst.components.eater.healthabsorption * bonus
      if delta > 0 then
        inst.components.health:DoDelta(delta, nil, food.prefab)
      end
    end

    if inst.components.hunger then
      local delta = food.components.edible:GetHunger(inst) * inst.components.eater.hungerabsorption * bonus
      if delta > 0 then
        inst.components.hunger:DoDelta(delta)
      end
    end

    if inst.components.sanity then
      local delta = food.components.edible:GetSanity(inst) * inst.components.eater.sanityabsorption * bonus
      if delta > 0 then
        inst.components.sanity:DoDelta(delta)
      end
    end
  end
end

local function OnAttacked(inst, data)
  local attacker = data and data.attacker

  if not attacker then
    return
  end

  if not (attacker:HasTag("mutant") or attacker:HasTag("player")) then
    inst.components.combat:ShareTarget(attacker, TUNING.OZZY_SHARE_TARGET_DIST,
      function(dude)
        return dude:HasTag("mutant") and not (dude:IsInLimbo() or dude.components.health:IsDead())
      end,
      TUNING.OZZY_MAX_SHARE_TARGETS)

    local hive = GetClosestInstWithTag("mutantbeehive", inst, TUNING.OZZY_SHARE_TARGET_DIST)
    if hive then
      hive:OnHit(attacker)
    end
  end
end

local function OnKillOther(inst, data)
  local victim = data.victim
  metapisutil.SpawnParasitesOnKill(inst, victim)
end

local function OnNumStoreChange(inst)
  local numstore = inst.components.beesummoner.numstore
  local maxstore = inst.components.beesummoner.maxstore

  inst.components.temperature.inherentinsulation = (TUNING.INSULATION_MED / maxstore) * numstore - TUNING.INSULATION_SMALL
end

-- When the character is revived from human
local function onbecamehuman(inst)
end

local function onbecameghost(inst)
end

-- When loading or spawning the character
local function onload(inst)
  inst:ListenForEvent("ms_respawnedfromghost", onbecamehuman)
  inst:ListenForEvent("ms_becameghost", onbecameghost)

  if inst:HasTag("playerghost") then
    onbecameghost(inst)
  else
    onbecamehuman(inst)
  end
end

local function SeasonalChanges(inst, season)
  if season == SEASONS.SPRING then
    inst.components.locomotor:SetExternalSpeedMultiplier(inst, "season_speed_mod", TUNING.OZZY_SPRING_SPEED_MULTIPLIER)
  elseif season == SEASONS.WINTER then
    inst.components.locomotor:SetExternalSpeedMultiplier(inst, "season_speed_mod", TUNING.OZZY_WINTER_SPEED_MULTIPLIER)
  else
    inst.components.locomotor:SetExternalSpeedMultiplier(inst, "season_speed_mod", TUNING.OZZY_DEFAULT_SPEED_MULTIPLIER)
  end
end

local function CheckHiveUpgrade(inst)
  if not inst._hive then
    return
  end

  local slaves = inst._hive:GetSlaves()
  inst.components.beesummoner:SetMaxChildren(
    TUNING.OZZY_MAX_SUMMON_BEES + math.floor(#slaves / 3)
  )
end

local function OnInit(inst)
  OnNumStoreChange(inst)
  inst:DoPeriodicTask(1, CheckHiveUpgrade)
end

-- This initializes for both the server and client. Tags can be added here.
local common_postinit = function(inst)
  inst.soundsname = "zeta"
  inst.carolsoundoverride = "dontstarve/characters/wilson/carol"
  -- Minimap icon
  inst.MiniMapEntity:SetIcon( "zeta.tex" )
  inst:AddTag("mutant")
  inst:AddTag("insect")
  inst:AddTag("beemaster")
  inst:AddTag(UPGRADETYPES.DEFAULT.."_upgradeuser")

  inst.components.talker.colour = Vector3(.9, .9, .3)
end

-- This initializes for the server only. Components are added here.
local master_postinit = function(inst)
  -- choose which sounds this character will play

  -- Uncomment if "wathgrithr"(Wigfrid) or "webber" voice is used
  -- inst.talker_path_override = "dontstarve_DLC001/characters/"

  -- Stats
  inst.components.health:SetMaxHealth(TUNING.OZZY_MAX_HEALTH)
  inst.components.hunger:SetMax(TUNING.OZZY_MAX_HUNGER)
  inst.components.sanity:SetMax(TUNING.OZZY_MAX_SANITY)
  inst.components.hunger.hungerrate = TUNING.WILSON_HUNGER_RATE * TUNING.OZZY_HUNGER_SCALE
  inst.components.combat.damagemultiplier = TUNING.OZZY_DEFAULT_DAMAGE_MULTIPLIER
  inst.components.temperature.inherentinsulation = -TUNING.INSULATION_SMALL

  inst:AddComponent("beesummoner")
  inst.components.beesummoner:SetMaxChildren(TUNING.OZZY_MAX_SUMMON_BEES)
  inst.components.beesummoner:SetSummonChance(TUNING.OZZY_SUMMON_CHANCE)
  inst.components.beesummoner:SetMaxStore(TUNING.OZZY_MAX_BEES_STORE)
  inst.components.beesummoner.childprefabfn = GetChildPrefab
  inst:ListenForEvent("onnumstorechange", OnNumStoreChange)

  SeasonalChanges(inst, TheWorld.state.season)
  inst:WatchWorldState("season", SeasonalChanges)

  inst._eatenpollens = 0
  inst:ListenForEvent("oneat", OnEat)
  inst:ListenForEvent("attacked", OnAttacked)
  -- inst:ListenForEvent("killed", OnKillOther)

  inst.OnLoad = onload
  inst.OnNewSpawn = onload

  inst:DoTaskInTime(0, OnInit)
end

return MakePlayerCharacter("zeta", prefabs, assets, common_postinit, master_postinit, start_inv)
