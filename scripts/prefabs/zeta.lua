local MakePlayerCharacter = require "prefabs/player_common"

local metapis_common = require "metapis_common"
local IsPoisonable = metapis_common.IsPoisonable
local MakePoisonable = metapis_common.MakePoisonable
local PickChildPrefab = metapis_common.PickChildPrefab

local hive_defs = require "hive_defs"

local assets = {
  Asset("SCRIPT", "scripts/prefabs/player_common.lua"),
  Asset("ANIM", "anim/zeta.zip"),
  Asset("SCRIPT", "scripts/prefabs/skilltree_zeta.lua")
}

local prefabs = {
  "honey",
  "pollen_fx"
}

local start_inv = {}
for k, v in pairs(TUNING.GAMEMODE_STARTING_ITEMS) do
  start_inv[string.lower(k)] = v.ZETA or {}
end

prefabs = FlattenTree({ prefabs, start_inv }, true)

local function GetChildPrefab(inst, source)
  if source == nil then
    return PickChildPrefab(
      inst,
      inst._hive,
      inst.components.beesummoner.children,
      inst.components.beesummoner.maxchildren,
      "mutantdefenderbee"
    )
  end

  if inst.components.beesummoner.maxextrachildren[source] ~= nil then
    return PickChildPrefab(
      inst,
      inst._hive,
      inst.components.beesummoner.extrachildren[source],
      inst.components.beesummoner:GetMaxExtraChildren(source)
    )
  end

  return nil
end

local function OnEat(inst, data)
  if data.food and data.food.prefab == "zetapollen" then
    inst._eatenpollens = inst._eatenpollens + 1
    if (inst._eatenpollens >= TUNING.ZETA_NUM_POLLENS_PER_HONEY) then
      local honey = SpawnPrefab("honey")
      inst.components.inventory:GiveItem(honey)
      inst._eatenpollens = 0
    end

    return
  end
end

local function OnNumStoreChange(inst)
  local numstore = inst.components.beesummoner.numstore
  local maxstore = inst.components.beesummoner.maxstore

  inst.components.temperature.inherentinsulation =
      (TUNING.INSULATION_MED / maxstore) * numstore - TUNING.INSULATION_SMALL
end

local function SeasonalChanges(inst, season)
  if season == SEASONS.SPRING then
    inst.components.locomotor:SetExternalSpeedMultiplier(inst, "season_speed_mod", TUNING.ZETA_SPRING_SPEED_MULTIPLIER)
  elseif season == SEASONS.WINTER then
    inst.components.locomotor:SetExternalSpeedMultiplier(inst, "season_speed_mod", TUNING.ZETA_WINTER_SPEED_MULTIPLIER)
  else
    inst.components.locomotor:RemoveExternalSpeedMultiplier(inst, "season_speed_mod")
  end
end

local function CheckHiveUpgrade(inst)
  if not inst._hive then
    inst.components.beesummoner:RemoveStoreModifier_Additive("motherhive")
    inst.components.beesummoner:RemoveStoreModifier_Additive("childhives")

    if inst.components.skilltreeupdater:IsActivated("zeta_metapimancer_tyrant_1") then
      inst.components.combat.damagemultiplier = TUNING.ZETA_TYRANT_DAMAGE_MULTIPLIER_0
    end

    return
  end

  if inst.components.skilltreeupdater:IsActivated("zeta_metapimancer_tyrant_1") then
    if inst._hive._stage.LEVEL == 1 then
      inst.components.combat.damagemultiplier = TUNING.ZETA_TYRANT_DAMAGE_MULTIPLIER_1
    elseif inst._hive._stage.LEVEL == 2 then
      inst.components.combat.damagemultiplier = TUNING.ZETA_TYRANT_DAMAGE_MULTIPLIER_2
    elseif inst._hive._stage.LEVEL == 3 then
      inst.components.combat.damagemultiplier = TUNING.ZETA_TYRANT_DAMAGE_MULTIPLIER_3
    end
  end

  inst.components.beesummoner:AddStoreModifier_Additive("motherhive", inst._hive._stage.LEVEL - 1)

  local slaves = inst._hive:GetSlaves()
  local numchilrenfromslaves = 0

  for i, slave in ipairs(slaves) do
    if slave.prefab == "mutantbarrack" then
      numchilrenfromslaves = numchilrenfromslaves + 1
    else
      numchilrenfromslaves = numchilrenfromslaves + 0.5
    end
  end

  inst.components.beesummoner:AddStoreModifier_Additive("childhives", math.floor(numchilrenfromslaves))

  local count = 0
  local checked = {}

  for i, slave in ipairs(slaves) do
    if not checked[slave.prefab] and slave.prefab ~= "mutantbarrack" then
      count = count + 1
      checked[slave.prefab] = true
    end
  end

  inst.components.beesummoner:SetMaxChildren(math.max(TUNING.ZETA_MAX_SUMMON_BEES, count + 1))
end

local hiveTokenRecipes = {}
for i, def in ipairs(hive_defs.HiveDefs) do
  hiveTokenRecipes[def.hive_prefab] = def.token_prefab
end

local function CheckRecipes(inst)
  for hive, token in pairs(hiveTokenRecipes) do
    if inst.components.builder:KnowsRecipe(hive, true) and not inst.components.builder:KnowsRecipe(token, true) then
      inst.components.builder:UnlockRecipe(token)
    end
  end
end

local honeyed_foods = {
  leafymeatsouffle = true,
  sweettea = true,
  icecream = true
}

local function OnInit(inst)
  OnNumStoreChange(inst)
  inst:DoPeriodicTask(1, CheckHiveUpgrade)

  CheckRecipes(inst)

  local _custom_stats_mod_fn = inst.components.eater.custom_stats_mod_fn
  inst.components.eater.custom_stats_mod_fn = function(inst, health_delta, hunger_delta, sanity_delta, food, feeder, ...)
    if _custom_stats_mod_fn then
      health_delta, hunger_delta, sanity_delta =
          _custom_stats_mod_fn(inst, health_delta, hunger_delta, sanity_delta, food, feeder, ...)
    end

    if food and (food:HasTag("honeyed") or honeyed_foods[food.prefab]) then
      health_delta = health_delta * TUNING.ZETA_HONEYED_FOOD_ABSORPTION
      hunger_delta = hunger_delta * TUNING.ZETA_HONEYED_FOOD_ABSORPTION
      sanity_delta = sanity_delta * TUNING.ZETA_HONEYED_FOOD_ABSORPTION
    else
      health_delta = health_delta * TUNING.ZETA_NON_HONEYED_FOOD_ABSORPTION
      hunger_delta = hunger_delta * TUNING.ZETA_NON_HONEYED_FOOD_ABSORPTION
      sanity_delta = sanity_delta * TUNING.ZETA_NON_HONEYED_FOOD_ABSORPTION
    end

    return health_delta, hunger_delta, sanity_delta
  end
end

local function OnBeeQueenKilled(inst)
  local numkilled = inst._numbeequeenkilled ~= nil and inst._numbeequeenkilled or 0

  if numkilled >= 2 and inst.components.builder and not inst.components.builder:KnowsRecipe("mutanthealerhive") then
    inst.components.builder:UnlockRecipe("mutanthealerhive")
  end
end

local function IncrBeeQueenKilledCount(inst)
  inst._numbeequeenkilled = math.min(10, (inst._numbeequeenkilled ~= nil and inst._numbeequeenkilled or 0) + 1) -- cap at 10
end

local function OnConsumeHealOrb(inst)
  inst._healorbeffect = math.max(inst._healorbeffect * 0.7, 0.3) -- 20% decay, to minimum of 30%

  if inst._firsthealorb then
    inst._firsthealorb = false

    -- reset heal orb effectiveness after 10 secs
    inst:DoTaskInTime(
      10,
      function(inst)
        inst._firsthealorb = true
        inst._healorbeffect = 1.0
      end
    )
  end

  if inst.components.skilltreeupdater:IsActivated("zeta_metapis_healer_1") then
    inst.components.debuffable:AddDebuff("heal_orb_haste_buff", "metapis_stack_haste_buff")
  end
end

local function EnablePoisonAttack(inst)
  if not inst._poisonatk then
    inst._poisonatk = true
    inst:DoTaskInTime(
      10,
      function(inst)
        inst._poisonatk = false
      end
    )
  end
end

local function calcChance(inst, minchance, maxchance, minthreshold)
  local healthpercent = inst.components.health:GetPercentWithPenalty()

  if healthpercent <= minthreshold then
    return maxchance
  end

  return Lerp(minchance, maxchance, (1.0 - healthpercent) / (1.0 - minthreshold))
end

local function findNearbyMinions(inst, num)
  local x, y, z = inst.Transform:GetWorldPosition()
  local minions =
      TheSim:FindEntities(
        x,
        y,
        z,
        10,
        { "beemutant", "_combat", "_health" },
        { "INLIMBO", "lesserminion" },
        { "beemutantminion" }
      )

  local res = {}
  local cnt = 0
  for i, e in ipairs(minions) do
    table.insert(res, e)
    cnt = cnt + 1
    if cnt >= num then
      break
    end
  end

  return res
end

local function calcNumEnrageMinions(inst)
  local healthpercent = inst.components.health:GetPercentWithPenalty()

  if healthpercent <= 0.33 then
    return 8
  elseif healthpercent <= 0.67 then
    return 6
  else
    return 4
  end
end

local function enrageMinions(inst)
  local minions = findNearbyMinions(inst, calcNumEnrageMinions(inst))

  for i, m in ipairs(minions) do
    m.components.debuffable:AddDebuff("metapis_haste_buff", "metapis_haste_buff")
    m.components.debuffable:AddDebuff("metapis_rage_buff", "metapis_rage_buff")
  end
end

local function OnAttackOther(inst, data)
  if data and data.target and data.target:IsValid() then
    local x, y, z = inst.Transform:GetWorldPosition()
    local allies = TheSim:FindEntities(x, y, z, 15, { "_combat", "_health", "beemutantminion" }, { "INLIMBO", "player" })

    for i, e in pairs(allies) do
      if e ~= data.target and e:GetOwner() == inst and not (e:IsInLimbo() or e.components.health:IsDead()) then
        e.components.combat:SetTarget(data.target)
        e._focusatktime = GetTime() + 5
      end
    end
  end

  if data and IsPoisonable(data.target) and inst._poisonatk then
    MakePoisonable(data.target)

    data.target.components.dotable:Add("stackable_poison", 5, TUNING.MUTANT_BEE_STACK_POISON_TICKS)
    data.target._crit_poison_end_time = GetTime() + 5
  end

  if
      inst.components.skilltreeupdater:IsActivated("zeta_metapimancer_shepherd_2") and
      math.random() <= calcChance(inst, 0.15, 0.3, 0.3)
  then
    enrageMinions(inst)
  end

  if math.random() <= 0.25 and inst.components.skilltreeupdater:IsActivated("zeta_metapis_ranger_2") then
    local x, y, z = inst.Transform:GetWorldPosition()
    local rangers =
        TheSim:FindEntities(x, y, z, 10, { "_combat", "_health", "beemutantminion", "ranger" }, { "INLIMBO", "player" })

    local cnt = 0
    local limit = math.random(2, 4)
    for i, e in pairs(rangers) do
      if
          e ~= data.target and e._shouldcharge and e:GetOwner() == inst and
          not (e:IsInLimbo() or e.components.health:IsDead())
      then
        -- print("CHARGE WUZZY", e)
        e:Charge()
        cnt = cnt + 1
        if cnt >= limit then
          break
        end
      end
    end
  end
end

local function ModifySGClient(sg)
  print("GOT CLIENT SG ", sg.name)
  local atk_handler = sg.actionhandlers[ACTIONS.ATTACK]
  local atk_deststate_fn = atk_handler.deststate

  local new_handler =
      ActionHandler(
        ACTIONS.ATTACK,
        function(inst, action, ...)
          local state = atk_deststate_fn(inst, action, ...)
          local equip = inst.replica.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)
          local rider = inst.replica.rider

          if
              inst.prefab == "zeta" and state == "attack" and inst.components.skilltreeupdater ~= nil and
              inst.components.skilltreeupdater:IsActivated("zeta_honeysmith_melissa_1") and
              not (rider ~= nil and rider:IsRiding()) and
              equip ~= nil and
              equip:HasTag("beemaster_weapon") and
              equip.ShouldSmashClient ~= nil and
              equip:ShouldSmashClient()
          then
            return "attack_zeta_smash"
          end

          return state
        end,
        atk_handler.condition
      )

  local blink_swap_handler =
      ActionHandler(
        ACTIONS.ZETA_BLINK_SWAP_APPROX,
        function(inst, action)
          return "quicktele"
        end
      )

  sg.actionhandlers[new_handler.action] = new_handler
  sg.actionhandlers[blink_swap_handler.action] = blink_swap_handler
end

local function ModifySGMaster(sg)
  print("GOT MASTER SG ", sg.name)
  local atk_handler = sg.actionhandlers[ACTIONS.ATTACK]
  local atk_deststate_fn = atk_handler.deststate

  local new_handler =
      ActionHandler(
        ACTIONS.ATTACK,
        function(inst, action, ...)
          local state = atk_deststate_fn(inst, action, ...)
          local weapon = inst.components.combat ~= nil and inst.components.combat:GetWeapon() or nil

          if
              inst.prefab == "zeta" and state == "attack" and inst.components.skilltreeupdater ~= nil and
              inst.components.skilltreeupdater:IsActivated("zeta_honeysmith_melissa_1") and
              not (inst.components.rider ~= nil and inst.components.rider:IsRiding()) and
              weapon ~= nil and
              weapon:HasTag("beemaster_weapon") and
              weapon.ShouldSmash ~= nil and
              weapon:ShouldSmash()
          then
            return "attack_zeta_smash"
          end

          return state
        end,
        atk_handler.condition
      )

  local blink_swap_handler =
      ActionHandler(
        ACTIONS.ZETA_BLINK_SWAP_APPROX,
        function(inst, action)
          return "quicktele"
        end
      )

  sg.actionhandlers[new_handler.action] = new_handler
  sg.actionhandlers[blink_swap_handler.action] = blink_swap_handler
end

-- because I don't want to affect other characters' stategraph.
-- I only want to isolate and make changes to Wuzzy stategraph
-- and try to do it every second (with cached flag) because state graph can be cleared and set to anything any time
local function ModifySG(inst)
  if inst.sg ~= nil and inst.sg.sg ~= nil and inst.sg.sg._modified_zeta == nil then
    if inst.sg.sg.name == "wilson" then
      ModifySGMaster(inst.sg.sg)
    end

    if inst.sg.sg.name == "wilson_client" then
      ModifySGClient(inst.sg.sg)
    end

    inst.sg.sg._modified_zeta = true
  end
end

local function tryModifySG(inst)
  ModifySG(inst)

  if inst._modifysgtask == nil then
    inst._modifysgtask = inst:DoPeriodicTask(1, ModifySG)
  end
end

-- client side
local function updateMotherHiveDisplay(inst)
  if inst.UpdateMotherHiveDisplay ~= nil then
    inst.UpdateMotherHiveDisplay()
  end
end

-- This initializes for both the server and client. Tags can be added here.
local common_postinit = function(inst)
  inst.soundsname = "zeta"
  inst.carolsoundoverride = "dontstarve/characters/wilson/carol"

  -- Minimap icon
  inst.MiniMapEntity:SetIcon("zeta.tex")
  inst:AddTag("beemutant")
  inst:AddTag("insect")
  inst:AddTag("beemaster")

  inst.components.talker.colour = Vector3(.9, .9, .3)

  inst:DoTaskInTime(0, tryModifySG)

  inst.net_hivechildren = net_shortint(inst.GUID, "zeta.hivechildren", "hivechildren_dirty")
  inst.net_hivechildren:set(-1)
  inst.net_hivemaxchildren = net_shortint(inst.GUID, "zeta.hivemaxchildren", "hivemaxchildren_dirty")
  inst.net_hivemaxchildren:set(-1)
  inst.net_hivehoney = net_shortint(inst.GUID, "zeta.hivehoney", "hivehoney_dirty")
  inst.net_hivehoney:set(-1)

  if not TheNet:IsDedicated() then
    inst:ListenForEvent("hivechildren_dirty", updateMotherHiveDisplay)
    inst:ListenForEvent("hivemaxchildren_dirty", updateMotherHiveDisplay)
    inst:ListenForEvent("hivehoney_dirty", updateMotherHiveDisplay)
  end
end

local function OnSave(inst, data)
  data._numbeequeenkilled = inst._numbeequeenkilled ~= nil and inst._numbeequeenkilled or nil

  data._zeta_health = inst.components.health.currenthealth
  data._zeta_hunger = inst.components.hunger.current
  data._zeta_sanity = inst.components.sanity.current
end

local function OnLoad(inst, data)
  if data ~= nil then
    inst._numbeequeenkilled = data._numbeequeenkilled or 0

    -- learnt from WX78, current stats have to be saved manually due to these components' save/load logic
    if data._zeta_health ~= nil then
      inst.components.health.currenthealth = data._zeta_health
    end

    if data._zeta_hunger ~= nil then
      inst.components.hunger.current = data._zeta_hunger
    end

    if data._zeta_sanity ~= nil then
      inst.components.sanity.current = data._zeta_sanity
    end
  end
end

local function setMaxHealth(inst, amount)
  inst.components.health.maxhealth = amount
  inst.components.health:ForceUpdateHUD(true)
end

local function setMaxHunger(inst, amount)
  inst.components.hunger.max = amount
  inst.components.hunger:DoDelta(0)
end

local function setMaxSanity(inst, amount)
  inst.components.sanity.max = amount
  inst.components.sanity:DoDelta(0)
end

local function doRegenHungerDelta(inst, delta)
  if inst:IsValid() and inst.components.hunger and not IsEntityDeadOrGhost(inst) then
    inst.components.hunger:DoDelta(delta)
  end
end

local function setTyrantStats(inst)
  setMaxHealth(inst, TUNING.ZETA_HEALTH_TYRANT)
  setMaxHunger(inst, TUNING.ZETA_HUNGER_TYRANT)
  setMaxSanity(inst, TUNING.ZETA_SANITY_TYRANT)
  inst.components.beesummoner:SetSummonChance(TUNING.ZETA_SUMMON_CHANCE_TYRANT)

  -- tyrant damage multiplier -> CheckHiveUpgrade

  inst.components.beesummoner.onregenfn = function(num)
    doRegenHungerDelta(inst, -num * TUNING.ZETA_SUMMON_REGEN_HUNGER_COST_TYRANT)
  end
end

local function setShepherdStats(inst)
  setMaxHealth(inst, TUNING.ZETA_HEALTH_SHEPHERD)
  setMaxHunger(inst, TUNING.ZETA_HUNGER_SHEPHERD)
  setMaxSanity(inst, TUNING.ZETA_SANITY_SHEPHERD)
  inst.components.combat.damagemultiplier = TUNING.ZETA_SHEPHERD_DAMAGE_MULTIPLIER
  inst.components.beesummoner:SetSummonChance(TUNING.ZETA_SUMMON_CHANCE_SHEPHERD)

  inst.components.beesummoner.onregenfn = function(num)
    doRegenHungerDelta(inst, -num * TUNING.ZETA_SUMMON_REGEN_HUNGER_COST_SHEPHERD)
  end
end

local function setDefaultStats(inst)
  setMaxHealth(inst, TUNING.ZETA_HEALTH)
  setMaxHunger(inst, TUNING.ZETA_HUNGER)
  setMaxSanity(inst, TUNING.ZETA_SANITY)
  inst.components.combat.damagemultiplier = TUNING.ZETA_DEFAULT_DAMAGE_MULTIPLIER
  inst.components.beesummoner:SetSummonChance(TUNING.ZETA_SUMMON_CHANCE)

  inst.components.beesummoner.onregenfn = function(num)
    doRegenHungerDelta(inst, -num * TUNING.ZETA_SUMMON_REGEN_HUNGER_COST)
  end
end

local function OnActivateSkill(inst, data)
  -- print("ON ACTIVATE", data.skill, GetTime())
  if data and data.skill then
    if data.skill == "zeta_metapimancer_tyrant_1" then
      setTyrantStats(inst)
    end

    if data.skill == "zeta_metapimancer_shepherd_1" then
      setShepherdStats(inst)
    end
  end
end

local function OnDeactivateSkill(inst, data)
  -- print("ON DEACTIVATE", data.skill, GetTime())
  if data and data.skill then
    if data.skill == "zeta_metapimancer_tyrant_1" then
      setDefaultStats(inst)
    end

    if data.skill == "zeta_metapimancer_shepherd_1" then
      setDefaultStats(inst)
    end
  end
end

local function OnSkillTreeInitialized(inst)
  -- print("ON SKILL TREE INIT", GetTime())

  local skilltreeupdater = inst.components.skilltreeupdater
  if not skilltreeupdater then
    return
  end

  if skilltreeupdater:IsActivated("zeta_metapimancer_tyrant_1") then
    setTyrantStats(inst)
  elseif skilltreeupdater:IsActivated("zeta_metapimancer_shepherd_1") then
    setShepherdStats(inst)
  else
    setDefaultStats(inst)
  end
end

local function tryStartRegen(inst)
  if inst.components.beesummoner then
    inst.components.beesummoner:StartRegen(inst.components.beesummoner.currenttick) -- try resume regen
  end
end

-- This initializes for the server only. Components are added here.
local master_postinit = function(inst)
  inst.starting_inventory = start_inv[TheNet:GetServerGameMode()] or start_inv.default

  -- Stats
  inst.components.health:SetMaxHealth(TUNING.ZETA_HEALTH)
  inst.components.hunger:SetMax(TUNING.ZETA_HUNGER)
  inst.components.sanity:SetMax(TUNING.ZETA_SANITY)
  inst.components.combat.damagemultiplier = TUNING.ZETA_DEFAULT_DAMAGE_MULTIPLIER
  inst.components.temperature.inherentinsulation = -TUNING.INSULATION_SMALL

  inst.components.foodaffinity:AddPrefabAffinity("honeyham", TUNING.AFFINITY_15_CALORIES_LARGE)

  inst:AddComponent("beesummoner")
  inst.components.beesummoner:SetMaxChildren(TUNING.ZETA_MAX_SUMMON_BEES)
  inst.components.beesummoner:SetSummonChance(TUNING.ZETA_SUMMON_CHANCE)
  inst.components.beesummoner:SetMaxStore(TUNING.ZETA_MAX_BEES_STORE)
  inst.components.beesummoner.childprefabfn = GetChildPrefab
  inst.components.beesummoner.shouldregenfn = function()
    return inst.components.hunger:GetPercent() >= TUNING.ZETA_SUMMON_REGEN_HUNGER_THRESHOLD and not IsEntityDeadOrGhost(inst)
  end
  inst.components.beesummoner.onregenfn = function(num)
    doRegenHungerDelta(inst, -num * TUNING.ZETA_SUMMON_REGEN_HUNGER_COST)
  end
  inst:ListenForEvent("hungerdelta", tryStartRegen)
  inst:ListenForEvent("ms_respawnedfromghost", tryStartRegen)

  inst:ListenForEvent("onnumstorechange", OnNumStoreChange)

  SeasonalChanges(inst, TheWorld.state.season)
  inst:WatchWorldState("season", SeasonalChanges)

  inst._eatenpollens = 0
  inst:ListenForEvent("oneat", OnEat)

  inst:DoTaskInTime(0, OnInit)
  inst:DoTaskInTime(3, OnBeeQueenKilled)

  inst.IncrBeeQueenKilledCount = IncrBeeQueenKilledCount
  inst.OnBeeQueenKilled = OnBeeQueenKilled

  inst._firsthealorb = true
  inst._healorbeffect = 1.0
  inst.OnConsumeHealOrb = OnConsumeHealOrb

  inst._poisonatk = false
  inst.EnablePoisonAttack = EnablePoisonAttack
  inst:ListenForEvent("onattackother", OnAttackOther)

  inst:ListenForEvent("onactivateskill_server", OnActivateSkill)
  inst:ListenForEvent("ondeactivateskill_server", OnDeactivateSkill)
  inst:ListenForEvent("ms_skilltreeinitialized", OnSkillTreeInitialized)

  inst:ListenForEvent(
    "unlockrecipe",
    function()
      CheckRecipes(inst)
    end
  )

  local _deltamodifierfn = inst.components.health.deltamodifierfn
  inst.components.health.deltamodifierfn = function (inst, amount, overtime, cause, ignore_invincible, afflicter, ignore_absorb, ...)
    if _deltamodifierfn ~= nil then
      amount = _deltamodifierfn(inst, amount, overtime, cause, ignore_invincible, afflicter, ignore_absorb, ...)
    end

    if amount < 0 and afflicter ~= nil and not overtime then -- taking damage from enemies
      local skilltreeupdater = inst.components.skilltreeupdater
      if
        skilltreeupdater:IsActivated("zeta_metapimancer_tyrant_2") and math.random() <= calcChance(inst, 0.25, 1.0, 0.3)
      then
        local minions = findNearbyMinions(inst, TUNING.ZETA_TYRANT_REDIRECT_DAMAGE_MINIONS)

        if #minions >= TUNING.ZETA_TYRANT_REDIRECT_DAMAGE_MINIONS then
          for i, m in ipairs(minions) do
            -- print("DIRECT DAMAGE ", m)
            m.components.health:DoDelta(10 * amount)
            local explode_fx = SpawnPrefab("explode_small")
            if explode_fx ~= nil then
              explode_fx.entity:AddFollower():FollowSymbol(m.GUID, m.components.combat.hiteffectsymbol, 0, 0, 0)
            end
          end

          return 0
        end
      end

      if
        skilltreeupdater:IsActivated("zeta_metapimancer_shepherd_2") and
        math.random() <= calcChance(inst, 0.2, 0.5, 0.3)
      then
        enrageMinions(inst)
      end
    end

    return amount
  end

  inst._onhivenumchildren = function()
    if inst._hive ~= nil and inst._hive.components.childspawner then
      inst.net_hivechildren:set(inst._hive.components.childspawner:NumChildren() +
      inst._hive.components.childspawner:NumEmergencyChildren())
      inst.net_hivemaxchildren:set(inst._hive.components.childspawner.maxchildren +
      inst._hive.components.childspawner.maxemergencychildren)
    else
      inst.net_hivechildren:set(-1)
      inst.net_hivemaxchildren:set(-1)
    end
  end

  inst._onhivenumhoney = function()
    if inst._hive ~= nil and inst._hive._container ~= nil then
      local has, numhoney = inst._hive._container.components.container:Has("honey", 1)
      inst.net_hivehoney:set(numhoney)
    else
      inst.net_hivehoney:set(-1)
    end
  end

  inst.OnSave = OnSave
  inst.OnLoad = OnLoad
end

return MakePlayerCharacter("zeta", prefabs, assets, common_postinit, master_postinit)
