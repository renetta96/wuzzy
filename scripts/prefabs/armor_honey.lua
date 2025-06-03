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
  local owner = nil

  if inst.components.inventoryitem and inst.components.perishable then
    owner = inst.components.inventoryitem:GetGrandOwner()
    if owner and owner.components.health then
      local percent =
        Lerp(
        TUNING.ARMORHONEY_MIN_HEAL_PERCENT,
        TUNING.ARMORHONEY_MAX_HEAL_PERCENT,
        inst.components.perishable:GetPercent()
      )
      local delta =
        math.max(1, math.floor((owner.components.health.maxhealth - owner.components.health.currenthealth) * percent))
      owner.components.health:DoDelta(delta, nil, "armorhoney_health")
    end
  end

  inst._healtick = inst._healtick - 1
  if inst._healtick <= 0 or (owner and owner.components.health and owner.components.health:IsDead()) then
    StopHealing(inst)
  end
end

local function StartHealing(inst)
  inst._healtick = TUNING.ARMORHONEY_HEAL_TICKS

  if inst._healtask == nil then
    inst._healtask = inst:DoPeriodicTask(TUNING.ARMORHONEY_HEAL_INTERVAL, DoHealing)
  end
end

local function OnTakeDamage(inst, amount)
  StartHealing(inst)
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

  return nil
end

local function onequip(inst, owner)
  owner.AnimState:OverrideSymbol("swap_body", "armor_honey", "swap_body")
  inst:ListenForEvent("blocked", OnBlocked, owner)

  if owner.components.beesummoner then
    owner.components.beesummoner:AddStoreModifier_Additive("armorhoney", TUNING.ARMORHONEY_ADD_STORE)
    owner.components.beesummoner:AddRegenTickModifier_Mult("armorhoney", CalcStoreModifier(inst))
  end
end

local function onunequip(inst, owner)
  owner.AnimState:ClearOverrideSymbol("swap_body")
  inst:RemoveEventCallback("blocked", OnBlocked, owner)
  StopHealing(inst)

  if owner.components.beesummoner then
    owner.components.beesummoner:RemoveRegenTickModifier_Mult("armorhoney")
    owner.components.beesummoner:RemoveStoreModifier_Additive("armorhoney")
  end
end

local function OnPerishChange(inst, data)
  if inst.components.armor and inst.components.perishable then
    local absorption =
      Lerp(TUNING.ARMORHONEY_MIN_ABSORPTION, TUNING.ARMORHONEY_MAX_ABSORPTION, inst.components.perishable:GetPercent())
    inst.components.armor:SetAbsorption(absorption)

    if inst.components.inventoryitem and inst.components.equippable then
      local owner = inst.components.inventoryitem:GetGrandOwner()
      if inst.components.equippable:IsEquipped() and owner.components.beesummoner then
        owner.components.beesummoner:AddRegenTickModifier_Mult("armorhoney", CalcStoreModifier(inst))
      end
    end
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

  inst:AddComponent("perishable")
  inst.components.perishable:SetPerishTime(TUNING.PERISH_MED)
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
