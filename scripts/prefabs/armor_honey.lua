local metapis_common = require "metapis_common"
local FindEnemies = metapis_common.FindEnemies

local zeta_utils = require "zeta_utils"

local assets = {
  Asset("ANIM", "anim/armor_honey.zip"),
  Asset("ATLAS", "images/inventoryimages/armor_honey.xml"),
  Asset("IMAGE", "images/inventoryimages/armor_honey.tex")
}

local prefabs = {
  "spoiled_food"
}

local function StopHealing(inst)
  inst._healtick = 0

  if inst._healtask then
    inst._healtask:Cancel()
    inst._healtask = nil
  end
end

local function DoHealing(inst)
  if not inst.components.inventoryitem or not inst.components.perishable then
    return
  end

  local owner = inst.components.inventoryitem:GetGrandOwner()
  if not owner or not owner.components.health then
    return
  end

  local minpercent = TUNING.ARMORHONEY_MIN_HEAL_PERCENT
  local maxpercent = TUNING.ARMORHONEY_MAX_HEAL_PERCENT

  if owner.components.skilltreeupdater and owner.components.skilltreeupdater:IsActivated("zeta_honeysmith_armor_honey_1") then
    minpercent = TUNING.ARMORHONEY_MIN_HEAL_PERCENT_UPGRADED
    maxpercent = TUNING.ARMORHONEY_MAX_HEAL_PERCENT_UPGRADED
  end

  local percent = Lerp(minpercent, maxpercent, inst.components.perishable:GetPercent())
  local delta = math.max(
    1,
    math.floor((owner.components.health.maxhealth - owner.components.health.currenthealth) * percent)
  )
  owner.components.health:DoDelta(delta, nil, "armorhoney_heal")

  inst._healtick = inst._healtick - 1
  if inst._healtick <= 0 or owner.components.health:IsDead() then
    StopHealing(inst)
  end
end

local function StartHealing(inst)
  inst._healtick = TUNING.ARMORHONEY_HEAL_TICKS

  if inst.components.inventoryitem then
    local owner = inst.components.inventoryitem:GetGrandOwner()
    if owner and owner.components.skilltreeupdater and owner.components.skilltreeupdater:IsActivated("zeta_honeysmith_armor_honey_1") then
      inst._healtick = TUNING.ARMORHONEY_HEAL_TICKS_UPGRADED
    end
  end

  if inst._healtask == nil then
    inst._healtask = inst:DoPeriodicTask(TUNING.ARMORHONEY_HEAL_INTERVAL, DoHealing)
  end
end

local function doStingerNova(owner)
  local fx = SpawnPrefab("stinger_nova_fx")
  fx:Attach(owner)

  local enemies = FindEnemies(owner, TUNING.ARMORHONEY_RETALIATE_RANGE)
  local damage = (owner.components.beesummoner.numchildren + owner.components.beesummoner:GetNumExtraChildren()) *
    TUNING.ARMORHONEY_RETALIATE_DAMAGE_MULT + TUNING.ARMORHONEY_RETALIATE_DAMAGE_BASE

  local targets = PickSome(math.min(TUNING.ARMORHONEY_RETALIATE_NUM_TARGETS, GetTableSize(enemies)), enemies)
  for i, e in ipairs(targets) do
    e.components.combat:GetAttacked(owner, damage)
  end

  if owner.components.skilltreeupdater:IsActivated("zeta_honeysmith_armor_honey_2") then
    for i = 1, TUNING.ARMORHONEY_RETALIATE_NUM_SUMMONS do
      owner.components.beesummoner:SummonChild(GetRandomItem(targets), "armorhoney_attacked")
    end
  end
end

local function updateStingerStatus(inst)
  local status_idx = math.min(8, math.ceil(inst._accdmg / (TUNING.ARMORHONEY_RETALIATE_ACC_DAMAGE_THRESHOLD / 8)))
  inst._status:SetStage(status_idx)
end

local function decayAccDmg(inst)
  inst._accdmg = math.max(0, inst._accdmg - (TUNING.ARMORHONEY_RETALIATE_ACC_DAMAGE_THRESHOLD / 16))

  updateStingerStatus(inst)
end

local function startDecay(inst)
  inst._decaytask = inst:DoPeriodicTask(1, decayAccDmg)
  inst._startdecaytask = nil
end

local function tryStingerNova(inst, amount)
  if not inst.components.inventoryitem then
    return
  end

  local owner = inst.components.inventoryitem:GetGrandOwner()
  if owner ~= nil and owner.prefab == "zeta"
      and owner:IsValid() and not owner.components.health:IsDead()
      and owner.components.skilltreeupdater and owner.components.skilltreeupdater:IsActivated("zeta_honeysmith_armor_honey_1")
      and owner.components.beesummoner then
    inst._accdmg = (inst._accdmg or 0) + amount

    if inst._status == nil then
      local status = SpawnPrefab("stinger_nova_status")
      status:Follow(owner)
      inst._status = status
    end

    if inst._accdmg >= TUNING.ARMORHONEY_RETALIATE_ACC_DAMAGE_THRESHOLD then
      local times = math.floor(inst._accdmg / TUNING.ARMORHONEY_RETALIATE_ACC_DAMAGE_THRESHOLD)
      inst._accdmg = inst._accdmg - times * TUNING.ARMORHONEY_RETALIATE_ACC_DAMAGE_THRESHOLD

      for i = 1, times do
        doStingerNova(owner)
      end
    end

    updateStingerStatus(inst)
    if inst._startdecaytask ~= nil then
      inst._startdecaytask:Cancel()
      inst._startdecaytask = nil
    end
    if inst._decaytask ~= nil then
      inst._decaytask:Cancel()
      inst._decaytask = nil
    end

    inst._startdecaytask = inst:DoTaskInTime(10, startDecay)
  end
end

local function OnTakeDamage(inst, amount)
  StartHealing(inst)
  tryStingerNova(inst, amount)
end

local function OnBlocked(owner)
  owner.SoundEmitter:PlaySound("dontstarve/wilson/hit_armour")
end

local function CalcStoreModifier(inst)
  if inst.components.perishable then
    local percent = inst.components.perishable:GetPercent()
    local mod = Lerp(TUNING.ARMORHONEY_MULT_REGEN_TICK, 1, 1 - percent)

    return mod
  end

  return 1.0
end

local function onattacked(owner, data)
  local attacker = data.attacker
  if not attacker then
    return
  end

  if owner.prefab == "zeta"
      and owner.components.skilltreeupdater
      and owner.components.skilltreeupdater:IsActivated("zeta_honeysmith_armor_honey_2")
      and owner.components.beesummoner then
    owner.components.beesummoner:AddExtraSource("armorhoney_attacked", function()
      return owner.components.beesummoner.maxchildren
    end)

    if math.random() <= TUNING.ARMORHONEY_ATTACKED_SUMMON_CHANCE then
      owner.components.beesummoner:SummonChild(attacker, "armorhoney_attacked")
    end
  end
end

local function onequip(inst, owner)
  owner.AnimState:OverrideSymbol("swap_body", "armor_honey", "swap_body")
  inst:ListenForEvent("blocked", OnBlocked, owner)

  if owner.components.beesummoner then
    owner.components.beesummoner:AddStoreModifier_Additive("armorhoney", TUNING.ARMORHONEY_ADD_STORE)
    owner.components.beesummoner:AddRegenTickModifier_Mult("armorhoney", function() return CalcStoreModifier(inst) end)

    inst:ListenForEvent("attacked", onattacked, owner)
  end
end

local function onunequip(inst, owner)
  owner.AnimState:ClearOverrideSymbol("swap_body")
  inst:RemoveEventCallback("blocked", OnBlocked, owner)
  StopHealing(inst)

  if owner.components.beesummoner then
    owner.components.beesummoner:RemoveRegenTickModifier_Mult("armorhoney")
    owner.components.beesummoner:RemoveStoreModifier_Additive("armorhoney")

    owner.components.beesummoner:RemoveExtraSource("armorhoney_attacked")
    inst:RemoveEventCallback("attacked", onattacked, owner)
  end

  if inst._status ~= nil then
    inst._status:Remove()
    inst._status = nil
  end

  if inst._startdecaytask ~= nil then
    inst._startdecaytask:Cancel()
    inst._startdecaytask = nil
  end

  if inst._decaytask ~= nil then
    inst._decaytask:Cancel()
    inst._decaytask = nil
  end

  inst._accdmg = 0
end

local function OnPerishChange(inst, data)
  if inst.components.armor and inst.components.perishable then
    local absorption =
        Lerp(TUNING.ARMORHONEY_MIN_ABSORPTION, TUNING.ARMORHONEY_MAX_ABSORPTION, inst.components.perishable:GetPercent())
    inst.components.armor:SetAbsorption(absorption)
  end
end

local function InitFn(inst)
  OnPerishChange(inst)
end

local function fn()
  local inst = CreateEntity()

  inst.entity:AddTransform()
  inst.entity:AddAnimState()
  inst.entity:AddNetwork()

  MakeInventoryPhysics(inst)

  inst.AnimState:SetBank("armor_honey")
  inst.AnimState:SetBuild("armor_honey")
  inst.AnimState:PlayAnimation("anim")

  inst:AddTag("wood")
  inst:AddTag("show_spoilage")
  inst:AddTag("icebox_valid")

  inst.foleysound = "dontstarve/movement/foley/logarmour"
  MakeInventoryFloatable(inst, "small", 0.2, 0.80)
  inst.entity:SetPristine()

  if not TheWorld.ismastersim then
    return inst
  end

  inst:AddComponent("inspectable")

  inst:AddComponent("inventoryitem")
  inst.components.inventoryitem.atlasname = "images/inventoryimages/armor_honey.xml"

  inst:AddComponent("armor")
  inst.components.armor:InitIndestructible(TUNING.ARMORHONEY_MAX_ABSORPTION)
  inst.components.armor.ontakedamage = OnTakeDamage

  inst:AddComponent("equippable")
  inst.components.equippable.equipslot = EQUIPSLOTS.BODY
  inst.components.equippable:SetOnEquip(onequip)
  inst.components.equippable:SetOnUnequip(onunequip)
  inst.components.equippable.restrictedtag = "beemaster"

  inst:AddComponent("perishable")
  inst.components.perishable:SetPerishTime(TUNING.PERISH_FASTISH)
  inst.components.perishable:StartPerishing()
  inst.components.perishable.onperishreplacement = "spoiled_food"
  inst:ListenForEvent("perishchange", OnPerishChange)

  MakeHauntableLaunch(inst)
  zeta_utils.MakeStopPerishingInHive(inst)

  inst:DoTaskInTime(0, InitFn)

  return inst
end

STRINGS.ARMOR_HONEY = "Honey Suit"
STRINGS.NAMES.ARMOR_HONEY = "Honey Suit"
STRINGS.RECIPE_DESC.ARMOR_HONEY = "Sweet and protective."
STRINGS.CHARACTERS.GENERIC.DESCRIBE.ARMOR_HONEY = "It's so sticky wearing it."

return Prefab("armor_honey", fn, assets, prefabs)
