local assets =
{
  Asset("ANIM", "anim/melissa.zip"),
  Asset("ANIM", "anim/swap_melissa.zip"),

  Asset("ANIM", "anim/floating_items.zip"),

  Asset("ATLAS", "images/inventoryimages/melissa.xml"),
  Asset("IMAGE", "images/inventoryimages/melissa.tex"),
}

local function OnSummonChild(inst, data)
  if data and data.child then
    data.child:Buff()
  end
end

local function onequip(inst, owner)
  owner.AnimState:OverrideSymbol("swap_object", "swap_melissa", "melissa")

  owner.AnimState:Show("ARM_carry")
  owner.AnimState:Hide("ARM_normal")

  owner:ListenForEvent("onsummonchild", OnSummonChild)
end

local function onunequip(inst, owner)
  owner.AnimState:Hide("ARM_carry")
  owner.AnimState:Show("ARM_normal")

  owner:RemoveEventCallback("onsummonchild", OnSummonChild)
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

    local swap_data = {sym_build = "swap_melissa", bank = "melissa", sym_name = "melissa"}
    MakeInventoryFloatable(inst, "large", 0.05, {1.0, 0.4, 1.0}, true, -17.5, swap_data)

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("weapon")
    inst.components.weapon:SetDamage(TUNING.MELISSA_DAMAGE)

    inst:AddComponent("finiteuses")
    inst.components.finiteuses:SetMaxUses(TUNING.MELISSA_USES)
    inst.components.finiteuses:SetUses(TUNING.MELISSA_USES)
    inst.components.finiteuses:SetOnFinished(inst.Remove)

    inst:AddComponent("inspectable")

    inst:AddComponent("inventoryitem")
    inst.components.inventoryitem.imagename = "melissa"
    inst.components.inventoryitem.atlasname = "images/inventoryimages/melissa.xml"

    MakeHauntableLaunch(inst)

    inst:AddComponent("equippable")
    inst.components.equippable:SetOnEquip(onequip)
    inst.components.equippable:SetOnUnequip(onunequip)

    return inst
end

STRINGS.MELISSA = "Melissa"
STRINGS.NAMES.MELISSA = "Melissa"
STRINGS.RECIPE_DESC.MELISSA = "Shiny and barbaric."
STRINGS.CHARACTERS.GENERIC.DESCRIBE.MELISSA = "A golden mace, named after Ancient Greek goddess of bees."

return Prefab("melissa", fn, assets)
