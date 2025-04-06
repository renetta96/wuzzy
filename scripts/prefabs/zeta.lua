local MakePlayerCharacter = require "prefabs/player_common"

local metapis_common = require "metapis_common"
local IsPoisonable = metapis_common.IsPoisonable
local MakePoisonable = metapis_common.MakePoisonable

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

local function CanSummon(inst, prefab)
  if not inst._hive then
    return false
  end

  return inst._hive:CanSpawn(prefab)
end

local function GetChildPrefab(inst)
  local maxchildren = inst.components.beesummoner.maxchildren

  local basechild = "mutantkillerbee"
  if inst.components.skilltreeupdater:IsActivated("zeta_metapis_mimic_1") then
    basechild = "mutantmimicbee"
  end

  local expect = {
    [basechild] = maxchildren,
    mutantdefenderbee = 0,
    mutantrangerbee = 0,
    mutantassassinbee = 0,
    mutantshadowbee = 0,
    mutanthealerbee = 0,
  }

  local cansummon = {basechild}

  for prefab, v in pairs(expect) do
    if prefab ~= basechild and CanSummon(inst, prefab) then
      expect[prefab] = expect[prefab] + 1
      expect[basechild] = expect[basechild] - 1
      table.insert(cansummon, prefab)
    end
  end

  local prefabcount = {}
  for k, v in pairs(expect) do
    prefabcount[k] = 0
  end

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
    inst.components.locomotor:RemoveExternalSpeedMultiplier(inst, "season_speed_mod")
  end
end

local function CheckHiveUpgrade(inst)
  if not inst._hive then
    inst.components.beesummoner:RemoveStoreModifier_Additive('motherhive')
    inst.components.beesummoner:RemoveStoreModifier_Additive('childhives')
    return
  end

  inst.components.beesummoner:AddStoreModifier_Additive(
    'motherhive',
    inst._hive._stage.LEVEL - 1
  )

  local slaves = inst._hive:GetSlaves()
  local numchilrenfromslaves = 0

  for i, slave in ipairs(slaves) do
    if slave.prefab == "mutantbarrack" then
      numchilrenfromslaves = numchilrenfromslaves + 1
    else
      numchilrenfromslaves = numchilrenfromslaves + 0.5
    end
  end

  inst.components.beesummoner:AddStoreModifier_Additive('childhives', math.floor(numchilrenfromslaves))

  local count = 0
  local checked = {}

  for i, slave in ipairs(slaves) do
    if not checked[slave.prefab] and slave.prefab ~= "mutantbarrack" then
      count = count + 1
      checked[slave.prefab] = true
    end
  end

  inst.components.beesummoner:SetMaxChildren(
    math.max(TUNING.OZZY_MAX_SUMMON_BEES, count + 1)
  )
end

local honeyed_foods = {
  leafymeatsouffle = true,
  sweettea = true,
  icecream = true
}

local function OnInit(inst)
  OnNumStoreChange(inst)
  inst:DoPeriodicTask(1, CheckHiveUpgrade)

  if inst.components.eater then
    local oldeatfn = inst.components.eater.Eat
    inst.components.eater.Eat = function (comp, food, ...)
      local healthabsorption = comp.healthabsorption
      local hungerabsorption = comp.hungerabsorption
      local sanityabsorption = comp.sanityabsorption

      if food and (food:HasTag('honeyed') or honeyed_foods[food.prefab]) then
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

local function UpdatePollenFx(inst)
  local oldfx = {}
  for flower, fx in pairs(inst._activefx) do
    oldfx[flower] = fx
  end

  local x, y, z = inst.Transform:GetWorldPosition()
  local flowers = TheSim:FindEntities(x, y, z, 25, {"flower"})

  for i, flower in ipairs(flowers) do
    if flower.net_pollenpicked ~= nil then
      local pollenpicked = flower.net_pollenpicked:value()

      if not pollenpicked then
        if inst._activefx[flower] == nil then
          local fx = SpawnPrefab("pollen_fx")
          fx.entity:SetParent(flower.entity)
          fx.entity:AddFollower():FollowSymbol(flower.GUID, 'flowers01', 0, 0, 0)

          inst._activefx[flower] = fx
        else
          oldfx[flower] = nil
        end
      else
        if inst._activefx[flower] ~= nil then
          inst._activefx[flower]:Remove()
          inst._activefx[flower] = nil
          oldfx[flower] = nil
        end
      end
    end
  end

  for flower, fx in pairs(oldfx) do
    inst._activefx[flower] = nil
    if fx:IsValid() then
      ErodeAway(fx, 0.5)
    end
  end
end

local function DisablePollenFx(inst)
  if inst._pollenfx_task then
    inst._pollenfx_task:Cancel()
    inst._pollenfx_task = nil
  end

  for flower, fx in pairs(inst._activefx) do
    if fx:IsValid() then
      fx:Remove()
    end
  end

  inst._activefx = {}
end

local function EnablePollenFx(inst)
  if inst.player_classified ~= nil then
    inst:ListenForEvent("playerdeactivated", DisablePollenFx)
    if inst._pollenfx_task == nil then
      inst._pollenfx_task = inst:DoPeriodicTask(0.1, UpdatePollenFx)
    end
  else
    inst:RemoveEventCallback("playeractivated", EnablePollenFx)
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
    inst:DoTaskInTime(10, function(inst)
      inst._firsthealorb = true
      inst._healorbeffect = 1.0
    end)
  end
end

local function EnablePoisonAttack(inst)
  if not inst._poisonatk then
    inst._poisonatk = true
    inst:DoTaskInTime(10, function(inst) inst._poisonatk = false end)
  end
end

local function OnAttackOther(inst, data)
  if data and data.target and data.target:IsValid() then
    local x, y, z = inst.Transform:GetWorldPosition()
    local allies = TheSim:FindEntities(
      x, y, z,
      15,
      {"_combat", "_health"}, {"INLIMBO", "player"}, {"beemutantminion"}
    )

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
  end
end

local function ModifySGClient(sg)
  print("GOT CLIENT SG ", sg.name)
  local atk_handler = sg.actionhandlers[ACTIONS.ATTACK]
  local atk_deststate_fn = atk_handler.deststate

  local new_handler = ActionHandler(
    ACTIONS.ATTACK,
    function(inst, action, ...)
      local state = atk_deststate_fn(inst, action, ...)
      local equip = inst.replica.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)
      local rider = inst.replica.rider

      if inst.prefab == "zeta" and state == "attack" and
        inst.components.skilltreeupdater ~= nil and
        inst.components.skilltreeupdater:IsActivated("zeta_honeysmith_melissa_1") and
        not (rider ~= nil and rider:IsRiding()) and
        equip ~= nil and equip:HasTag("beemaster_weapon") and
        equip.ShouldSmashClient ~= nil and equip:ShouldSmashClient()
      then
          return "attack_zeta_smash"
      end

      return state
    end,
    atk_handler.condition
  )

  local blink_swap_handler = ActionHandler(
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

  local new_handler = ActionHandler(
    ACTIONS.ATTACK,
    function(inst, action, ...)
      local state = atk_deststate_fn(inst, action, ...)
      local weapon = inst.components.combat ~= nil and inst.components.combat:GetWeapon() or nil

      if inst.prefab == "zeta" and state == "attack" and
        inst.components.skilltreeupdater ~= nil and
        inst.components.skilltreeupdater:IsActivated("zeta_honeysmith_melissa_1") and
        not (inst.components.rider ~= nil and inst.components.rider:IsRiding()) and
        weapon ~= nil and weapon:HasTag("beemaster_weapon") and
        weapon.ShouldSmash ~= nil and weapon:ShouldSmash()
      then
        return "attack_zeta_smash"
      end

      return state
    end,
    atk_handler.condition
  )

  local blink_swap_handler = ActionHandler(
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
  if inst ~= ThePlayer then
    print("NOT THE PLAYER")
    return
  end

  inst:DoTaskInTime(0, ModifySG)
  if inst._modifysgtask == nil then
    inst._modifysgtask = inst:DoPeriodicTask(1, ModifySG)
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

  if not TheNet:IsDedicated() then
    inst._activefx = {}
    inst:ListenForEvent("playeractivated", EnablePollenFx)
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
  inst.components.health.currenthealth = math.min(
    inst.components.health.currenthealth,
    inst.components.health:GetMaxWithPenalty()
  )
end

local function setMaxHunger(inst, amount)
  inst.components.hunger.max = amount
  inst.components.hunger.current = math.min(inst.components.hunger.current, inst.components.hunger.max)
end

local function setMaxSanity(inst, amount)
  inst.components.sanity.max = amount
  inst.components.sanity.current = math.min(
    inst.components.sanity.current,
    inst.components.sanity:GetMaxWithPenalty()
  )
end

local function OnSkillChange(inst)
  -- print("ON SKILL CHANGE")

  local skilltreeupdater = inst.components.skilltreeupdater
  if not skilltreeupdater then
    return
  end

  -- no changes to current health/hunger/sanity, only affect max values
  if skilltreeupdater:IsActivated("zeta_metapimancer_tyrant_1") then
    setMaxHealth(inst, math.floor(TUNING.ZETA_HEALTH * 1.5))
    setMaxHunger(inst, math.floor(TUNING.ZETA_HUNGER * 1.5))
    setMaxSanity(inst, math.floor(TUNING.ZETA_SANITY * 1.5))
    inst.components.combat.damagemultiplier = TUNING.OZZY_TYRANT_DAMAGE_MULTIPLIER
  elseif skilltreeupdater:IsActivated("zeta_metapimancer_shepherd_1") then
    setMaxHealth(inst, math.ceil(TUNING.ZETA_HEALTH * 0.75))
    setMaxHunger(inst, math.ceil(TUNING.ZETA_HUNGER * 0.75))
    setMaxSanity(inst, math.ceil(TUNING.ZETA_SANITY * 0.75))
    inst.components.combat.damagemultiplier = TUNING.OZZY_SHEPHERD_DAMAGE_MULTIPLIER
  else
    setMaxHealth(inst, TUNING.ZETA_HEALTH)
    setMaxHunger(inst, TUNING.ZETA_HUNGER)
    setMaxSanity(inst, TUNING.ZETA_SANITY)
    inst.components.combat.damagemultiplier = TUNING.OZZY_DEFAULT_DAMAGE_MULTIPLIER
  end
end

local function OnActivateSkill(inst, data)
  OnSkillChange(inst)
end

local function OnDeactivateSkill(inst, data)
  OnSkillChange(inst)
end

local function OnSkillTreeInitialized(inst)
  OnSkillChange(inst)
end

local function calcChance(inst, minchance, maxchance, minthreshold)
  local healthpercent = inst.components.health:GetPercent()

  if healthpercent <= minthreshold then
    return maxchance
  end

  return Lerp(minchance, maxchance, (1.0 - healthpercent) / (1.0 - minthreshold))
end

local function calcNumEnrageMinions(inst)
  local healthpercent = inst.components.health:GetPercent()

  if healthpercent <= 0.33 then
    return 8
  elseif healthpercent <= 0.67 then
    return 6
  else
    return 4
  end
end

local function findNearbyMinion(inst)
  return FindEntity(
    inst,
    10,
    function(guy)
      return not guy.components.health:IsDead() and guy:IsValid() and guy:GetOwner() == inst
    end,
    {"beemutant", "_combat", "_health"}, {"INLIMBO", "lesserminion"}, {"beemutantminion"})
end

local function findNearbyMinions(inst, num)
  local x, y, z = inst.Transform:GetWorldPosition()
  local minions = TheSim:FindEntities(
    x, y, z,
    10,
    {"beemutant", "_combat", "_health"}, {"INLIMBO", "lesserminion"}, {"beemutantminion"})

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

-- This initializes for the server only. Components are added here.
local master_postinit = function(inst)
  inst.starting_inventory = start_inv[TheNet:GetServerGameMode()] or start_inv.default

  -- Stats
  inst.components.health:SetMaxHealth(TUNING.ZETA_HEALTH)
  inst.components.hunger:SetMax(TUNING.ZETA_HUNGER)
  inst.components.sanity:SetMax(TUNING.ZETA_SANITY)
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
  inst:DoTaskInTime(3, OnBeeQueenKilled)

  inst.IncrBeeQueenKilledCount = IncrBeeQueenKilledCount
  inst.OnBeeQueenKilled = OnBeeQueenKilled

  inst._firsthealorb = true
  inst._healorbeffect = 1.0
  inst.OnConsumeHealOrb = OnConsumeHealOrb

  inst._poisonatk = false
  inst.EnablePoisonAttack = EnablePoisonAttack
  inst:ListenForEvent("onattackother", OnAttackOther)

  inst:DoTaskInTime(0, ModifySG)
  if inst._modifysgtask == nil then
    inst._modifysgtask = inst:DoPeriodicTask(1, ModifySG)
  end

  inst:ListenForEvent("onactivateskill_server", OnActivateSkill)
  inst:ListenForEvent("ondeactivateskill_server", OnDeactivateSkill)
  inst:ListenForEvent("ms_skilltreeinitialized", OnSkillTreeInitialized)

  local oldDoDelta = inst.components.health.DoDelta
  inst.components.health.DoDelta = function(comp, amount, ...)
    if amount < 0 then -- taking damage from any source
      local skilltreeupdater = inst.components.skilltreeupdater

      if skilltreeupdater:IsActivated("zeta_metapimancer_tyrant_2") and math.random() <= calcChance(inst, 0.25, 1.0, 0.3) then
        local minions = findNearbyMinions(inst, TUNING.OZZY_TYRANT_REDIRECT_DAMAGE_MINIONS)

        if #minions >= TUNING.OZZY_TYRANT_REDIRECT_DAMAGE_MINIONS then
          for i, m in ipairs(minions) do
            -- print("DIRECT DAMAGE ", m)
            m.components.health:DoDelta(10 * amount)
            local explode_fx = SpawnPrefab("explode_small")
            if explode_fx ~= nil then
              explode_fx.entity:AddFollower():FollowSymbol(
                m.GUID,
                m.components.combat.hiteffectsymbol,
                0, 0, 0)
            end
          end

          return 0
        end
      end

      if skilltreeupdater:IsActivated("zeta_metapimancer_shepherd_2") and math.random() <= calcChance(inst, 0.2, 0.5, 0.3) then
        local minions = findNearbyMinions(inst, TUNING.OZZY_SHEPHERD_BUFF_MINIONS)

        for i, m in ipairs(minions) do
          m.components.debuffable:AddDebuff("metapis_haste_buff", "metapis_haste_buff")
          m.components.debuffable:AddDebuff("metapis_rage_buff", "metapis_rage_buff")
        end
      end
    end

    -- default
    return oldDoDelta(comp, amount, ...)
  end

  inst.OnSave = OnSave
  inst.OnLoad = OnLoad
end

return MakePlayerCharacter("zeta", prefabs, assets, common_postinit, master_postinit)
