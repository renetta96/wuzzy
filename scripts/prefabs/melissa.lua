local assets =
{
  Asset("ANIM", "anim/melissa.zip"),
  Asset("ANIM", "anim/swap_melissa.zip"),

  Asset("ANIM", "anim/floating_items.zip"),

  Asset("ATLAS", "images/inventoryimages/melissa.xml"),
  Asset("IMAGE", "images/inventoryimages/melissa.tex"),
}


local function onequip(inst, owner)
  owner.AnimState:OverrideSymbol("swap_object", "swap_melissa", "melissa")

  owner.AnimState:Show("ARM_carry")
  owner.AnimState:Hide("ARM_normal")
end

local function onunequip(inst, owner)
  owner.AnimState:Hide("ARM_carry")
  owner.AnimState:Show("ARM_normal")
end

local function OnAttack(inst)
  local owner = inst.components.inventoryitem:GetGrandOwner()

  if owner and owner.components.hunger and owner.components.hunger:GetPercent() > TUNING.MELISSA_MIN_DAMAGE_HUNGER_THRESHOLD then
    local penalty = math.max(
      TUNING.MELISSA_MIN_HUNGER_DRAIN,
      TUNING.MELISSA_PERCENT_HUNGER_DRAIN * owner.components.hunger.max
    )
    owner.components.hunger:DoDelta(-penalty)
  end
end

local function UpdateDamage(inst)
    local owner = inst.components.inventoryitem:GetGrandOwner()
    if owner and owner.components.hunger then
        local percent = owner.components.hunger:GetPercent()

        if percent >= TUNING.MELISSA_MAX_DAMAGE_HUNGER_THRESHOLD then
          inst.components.weapon:SetDamage(TUNING.MELISSA_MAX_DAMAGE)
        elseif percent <= TUNING.MELISSA_MIN_DAMAGE_HUNGER_THRESHOLD then
          inst.components.weapon:SetDamage(TUNING.MELISSA_MIN_DAMAGE)
        else
          local damage = Lerp(
            TUNING.MELISSA_MIN_DAMAGE,
            TUNING.MELISSA_MAX_DAMAGE,
            (percent - TUNING.MELISSA_MIN_DAMAGE_HUNGER_THRESHOLD) / (TUNING.MELISSA_MAX_DAMAGE_HUNGER_THRESHOLD - TUNING.MELISSA_MIN_DAMAGE_HUNGER_THRESHOLD)
          )
          inst.components.weapon:SetDamage(damage)
        end
    else
        inst.components.weapon:SetDamage(TUNING.MELISSA_MIN_DAMAGE)
    end
end

local function OnOwnerHungerDelta(inst)
    UpdateDamage(inst)
end

local function OnDrop(inst)
    if inst._owner then
        inst:RemoveEventCallback('hungerdelta', inst._onownerhungerdelta, inst._owner)
    end

    inst._owner = nil
    UpdateDamage(inst)
end

local function OnPutInInventory(inst, owner)
    inst._owner = owner
    inst:ListenForEvent('hungerdelta', inst._onownerhungerdelta, owner)
    UpdateDamage(inst)
end

local function OnInit(inst)
    local owner = inst.components.inventoryitem:GetGrandOwner()

    if owner then
        OnPutInInventory(inst, owner)
    else
        UpdateDamage(inst)
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

    local swap_data = {sym_build = "swap_melissa", bank = "melissa", sym_name = "melissa"}
    MakeInventoryFloatable(inst, "large", 0.05, {1.0, 0.4, 1.0}, true, -17.5, swap_data)

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("weapon")
    inst.components.weapon:SetDamage(TUNING.MELISSA_MIN_DAMAGE)
    inst.components.weapon:SetOnAttack(OnAttack)
    inst._onownerhungerdelta = function(owner)
      OnOwnerHungerDelta(inst)
    end

    inst:AddComponent("finiteuses")
    inst.components.finiteuses:SetMaxUses(TUNING.MELISSA_USES)
    inst.components.finiteuses:SetUses(TUNING.MELISSA_USES)
    inst.components.finiteuses:SetOnFinished(inst.Remove)

    inst:AddComponent("inspectable")

    inst:AddComponent("inventoryitem")
    inst.components.inventoryitem.imagename = "melissa"
    inst.components.inventoryitem.atlasname = "images/inventoryimages/melissa.xml"
    inst:ListenForEvent("onputininventory", OnPutInInventory)
    inst:ListenForEvent("ondropped", OnDrop)

    MakeHauntableLaunch(inst)

    inst:AddComponent("equippable")
    inst.components.equippable:SetOnEquip(onequip)
    inst.components.equippable:SetOnUnequip(onunequip)

    inst:DoTaskInTime(0, OnInit)

    return inst
end

STRINGS.MELISSA = "Melissa"
STRINGS.NAMES.MELISSA = "Melissa"
STRINGS.RECIPE_DESC.MELISSA = "Shiny and barbaric."
STRINGS.CHARACTERS.GENERIC.DESCRIBE.MELISSA = "A golden mace, named after Ancient Greek goddess of bees."

return Prefab("melissa", fn, assets)
