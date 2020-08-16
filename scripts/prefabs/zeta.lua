local MakePlayerCharacter = require "prefabs/player_common"

local assets = {
  Asset("SCRIPT", "scripts/prefabs/player_common.lua"),
  Asset("ANIM", "anim/zeta.zip"),
}

local prefabs = {
  "mutantbeecocoon",
  "honey"
}

local start_inv = {}
for k, v in pairs(TUNING.GAMEMODE_STARTING_ITEMS) do
    start_inv[string.lower(k)] = v.ZETA or {}
end

prefabs = FlattenTree({ prefabs, start_inv }, true)

local tagtoprefab = {
  defender = "mutantdefenderbee",
  soldier = "mutantkillerbee",
  ranger = "mutantrangerbee",
  assassin = "mutantassassinbee"
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

  -- if data.food and data.food:HasTag("honeyed") then
  --   local food = data.food
  --   local bonus = TUNING.OZZY_HONEYED_FOOD_BONUS

  --   if inst.components.health then
  --     local delta = food.components.edible:GetHealth(inst) * inst.components.eater.healthabsorption * bonus
  --     if delta > 0 then
  --       inst.components.health:DoDelta(delta, nil, food.prefab)
  --     end
  --   end

  --   if inst.components.hunger then
  --     local delta = food.components.edible:GetHunger(inst) * inst.components.eater.hungerabsorption * bonus
  --     if delta > 0 then
  --       inst.components.hunger:DoDelta(delta)
  --     end
  --   end

  --   if inst.components.sanity then
  --     local delta = food.components.edible:GetSanity(inst) * inst.components.eater.sanityabsorption * bonus
  --     if delta > 0 then
  --       inst.components.sanity:DoDelta(delta)
  --     end
  --   end
  -- end
end

local function OnNumStoreChange(inst)
  local numstore = inst.components.beesummoner.numstore
  local maxstore = inst.components.beesummoner.maxstore

  inst.components.temperature.inherentinsulation = (TUNING.INSULATION_MED / maxstore) * numstore - TUNING.INSULATION_SMALL
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

  if inst.components.eater then
    local oldeatfn = inst.components.eater.Eat
    inst.components.eater.Eat = function (comp, food, ...)
      local healthabsorption = comp.healthabsorption
      local hungerabsorption = comp.hungerabsorption
      local sanityabsorption = comp.sanityabsorption

      if food and food:HasTag('honeyed') then
        comp.healthabsorption = TUNING.OZZY_HONEYED_FOOD_ABSORPTION
        comp.hungerabsorption = TUNING.OZZY_HONEYED_FOOD_ABSORPTION
        comp.sanityabsorption = TUNING.OZZY_HONEYED_FOOD_ABSORPTION
      else
        comp.healthabsorption = TUNING.OZZY_NON_HONEYED_FOOD_ABSORPTION
        comp.hungerabsorption = TUNING.OZZY_NON_HONEYED_FOOD_ABSORPTION
        comp.sanityabsorption = TUNING.OZZY_NON_HONEYED_FOOD_ABSORPTION
      end

      local result = oldeatfn(comp, food, ...)

      comp.healthabsorption = healthabsorption
      comp.hungerabsorption = hungerabsorption
      comp.sanityabsorption = sanityabsorption

      return result
    end
  end
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
  inst.starting_inventory = start_inv[TheNet:GetServerGameMode()] or start_inv.default

  -- Stats
  inst.components.health:SetMaxHealth(TUNING.ZETA_HEALTH)
  inst.components.hunger:SetMax(TUNING.ZETA_HUNGER)
  inst.components.sanity:SetMax(TUNING.ZETA_SANITY)
  inst.components.hunger.hungerrate = TUNING.WILSON_HUNGER_RATE * TUNING.OZZY_HUNGER_SCALE
  inst.components.combat.damagemultiplier = TUNING.OZZY_DEFAULT_DAMAGE_MULTIPLIER
  inst.components.temperature.inherentinsulation = -TUNING.INSULATION_SMALL

  inst.components.foodaffinity:AddPrefabAffinity("honeyham", TUNING.AFFINITY_15_CALORIES_LARGE)

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

  inst:DoTaskInTime(0, OnInit)
end

return MakePlayerCharacter("zeta", prefabs, assets, common_postinit, master_postinit)
