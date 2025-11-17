local assets = {
  Asset("ANIM", "anim/melissa.zip"),
  Asset("ANIM", "anim/swap_melissa.zip"),
  Asset("ANIM", "anim/floating_items.zip"),
  Asset("ATLAS", "images/inventoryimages/melissa.xml"),
  Asset("IMAGE", "images/inventoryimages/melissa.tex")
}

local function OnSummonChild(inst, data)
  if data and data.child then
    data.child:Buff()
  end
end

local num_atks_smash = 4

local function onAttack(inst, owner)
  inst._atkcounter = inst._atkcounter + 1
  if inst._atkcounter > num_atks_smash then
    inst._atkcounter = inst._atkcounter - num_atks_smash
  end

  inst._netatkcounter:set(inst._atkcounter)
end

local function ShouldSmash(inst)
  return inst._atkcounter ~= nil and inst._atkcounter == num_atks_smash
end

local function ShouldSmashClient(inst)
  return inst._netatkcounter ~= nil and inst._netatkcounter:value() == num_atks_smash
end

local function onequip(inst, owner)
  owner.AnimState:OverrideSymbol("swap_object", "swap_melissa", "melissa")

  owner.AnimState:Show("ARM_carry")
  owner.AnimState:Hide("ARM_normal")

  owner:ListenForEvent("onsummonchild", OnSummonChild)
  inst:ListenForEvent("onattackother", inst._onowneratk, owner)
  inst:ListenForEvent("onmissother", inst._onowneratk, owner)
end

local function onunequip(inst, owner)
  inst._atkcounter = 0
  inst._netatkcounter:set(0)

  owner.AnimState:Hide("ARM_carry")
  owner.AnimState:Show("ARM_normal")

  owner:RemoveEventCallback("onsummonchild", OnSummonChild)
  inst:RemoveEventCallback("onattackother", inst._onowneratk, owner)
  inst:RemoveEventCallback("onmissother", inst._onowneratk, owner)
end

local function onatkcounterdirty(inst)
  -- print("CLIENT ATK COUNTER: ", inst._netatkcounter:value())
end

local function OnSave(inst, data)
  data._upgraded = inst._upgraded ~= nil and inst._upgraded or nil
  data._canblink = inst._canblink ~= nil and inst._canblink or nil
end

local function checkmaxuses(inst)
  if inst._upgraded ~= nil and inst._upgraded then
    inst.components.finiteuses:SetMaxUses(TUNING.MELISSA_USES_2)
  else
    inst.components.finiteuses:SetMaxUses(TUNING.MELISSA_USES)
  end
end

local function checkdamage(inst)
  if inst._canblink then -- upgraded with melissa II
    inst.components.weapon:SetDamage(TUNING.MELISSA_DAMAGE_2)
  else
    inst.components.weapon:SetDamage(TUNING.MELISSA_DAMAGE)
  end
end

local function initBlinkSwap(inst)
  if inst._canblink then
    if inst.components.blinkswap == nil then
      inst:AddComponent("blinkswap")
    end

    inst.components.blinkswap:SetOnBlinkDoerFn(
      function()
        inst.components.finiteuses:Use(TUNING.MELISSA_SWAP_USES)
      end
    )

    inst.components.blinkswap:SetOnBlinkTargetFn(
      function(staff, pt, caster)
        if caster:IsValid() and caster.components.debuffable then
          caster.components.debuffable:AddDebuff("metapis_frenzy_buff", "metapis_frenzy_buff")
          caster.components.debuffable:AddDebuff("metapis_haste_buff", "metapis_haste_buff")
          caster.components.debuffable:AddDebuff("metapis_rage_buff", "metapis_rage_buff")
        end
      end
    )
  end
end

local function OnLoad(inst, data)
  if data ~= nil then
    inst._upgraded = data._upgraded or false
    inst._canblink = data._canblink or false
  end

  checkmaxuses(inst)
  initBlinkSwap(inst)
  checkdamage(inst)
end

local function OnBuiltFn(inst, builder)
  if builder and builder:IsValid() and builder.prefab == "zeta" and builder.components.skilltreeupdater then
    if builder.components.skilltreeupdater:IsActivated("zeta_honeysmith_melissa_1") then
      inst._upgraded = true
      checkmaxuses(inst)
      inst.components.finiteuses:SetUses(TUNING.MELISSA_USES * 2)
    end

    if builder.components.skilltreeupdater:IsActivated("zeta_honeysmith_melissa_2") then
      inst._canblink = true
      initBlinkSwap(inst)
      checkdamage(inst)
    end
  end
end

local function fn()
  local inst = CreateEntity()

  inst.entity:AddTransform()
  inst.entity:AddAnimState()
  inst.entity:AddNetwork()

  MakeInventoryPhysics(inst)

  inst.AnimState:SetBank("melissa")
  inst.AnimState:SetBuild("melissa")
  inst.AnimState:PlayAnimation("idle")

  --weapon (from weapon component) added to pristine state for optimization
  inst:AddTag("weapon")
  inst:AddTag("beemaster_weapon")

  local swap_data = {sym_build = "swap_melissa", bank = "melissa", sym_name = "melissa"}
  MakeInventoryFloatable(inst, "large", 0.05, {1.0, 0.4, 1.0}, true, -17.5, swap_data)

  inst.entity:SetPristine()

  inst._netatkcounter = net_byte(inst.GUID, "melissa._atkcounter", "atkcounterdirty")
  inst.ShouldSmashClient = ShouldSmashClient

  if not TheNet:IsDedicated() then
    inst:ListenForEvent("atkcounterdirty", onatkcounterdirty)
  end

  if not TheWorld.ismastersim then
    return inst
  end

  inst:AddComponent("weapon")
  inst.components.weapon:SetDamage(TUNING.MELISSA_DAMAGE)

  inst:AddComponent("finiteuses")
  inst.components.finiteuses:SetMaxUses(TUNING.MELISSA_USES)
  inst.components.finiteuses:SetUses(TUNING.MELISSA_USES)
  inst.components.finiteuses:SetOnFinished(inst.Remove)
  inst.components.finiteuses:SetDoesNotStartFull(true)

  inst:AddComponent("inspectable")

  inst:AddComponent("inventoryitem")
  inst.components.inventoryitem.imagename = "melissa"
  inst.components.inventoryitem.atlasname = "images/inventoryimages/melissa.xml"

  MakeHauntableLaunch(inst)

  inst:AddComponent("equippable")
  inst.components.equippable:SetOnEquip(onequip)
  inst.components.equippable:SetOnUnequip(onunequip)

  inst._atkcounter = 0
  inst._netatkcounter:set(0)

  inst.ShouldSmash = ShouldSmash
  inst._onowneratk = function(owner)
    onAttack(inst, owner)
  end

  inst.OnBuiltFn = OnBuiltFn
  inst.OnSave = OnSave
  inst.OnLoad = OnLoad

  return inst
end

STRINGS.MELISSA = "Melissa"
STRINGS.NAMES.MELISSA = "Melissa"
STRINGS.RECIPE_DESC.MELISSA = "Shiny and barbaric."
STRINGS.CHARACTERS.GENERIC.DESCRIBE.MELISSA = "A golden mace, named after Ancient Greek goddess of bees."

return Prefab("melissa", fn, assets)
