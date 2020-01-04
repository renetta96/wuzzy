local assets =
{
  Asset("ANIM", "anim/zetapollen.zip"),
  Asset("ATLAS", "images/inventoryimages/zetapollen.xml"),
  Asset("IMAGE", "images/inventoryimages/zetapollen.tex")
}

local function OnPutInInventory(inst, owner)
  if owner and owner.prefab == 'mutantbeehive' then
    inst.components.perishable:StopPerishing()
  end
end

local function onremovedfn(inst, owner)
  if owner and owner.prefab == "mutantbeehive" then
    inst.components.perishable:StartPerishing()
  end
end

local function onperish(inst)
  inst:Remove()
end

local function fn()
  local inst = CreateEntity()

  inst.entity:AddTransform()
  inst.entity:AddAnimState()

  MakeInventoryPhysics(inst)

  inst.AnimState:SetBank("zetapollen")
  inst.AnimState:SetBuild("zetapollen")
  inst.AnimState:PlayAnimation("idle")

  -----------------
  inst:AddComponent("inventoryitem")
  inst.components.inventoryitem.imagename = "zetapollen"
  inst.components.inventoryitem.atlasname = "images/inventoryimages/zetapollen.xml"
  inst.components.inventoryitem:SetOnPutInInventoryFn(OnPutInInventory)
  local OldOnRemoved = inst.components.inventoryitem.OnRemoved
  inst.components.inventoryitem.OnRemoved = function(comp)
    onremovedfn(comp.inst, comp.owner)
    OldOnRemoved(comp)
  end

  inst:AddComponent("stackable")
  inst.components.stackable.maxsize = TUNING.STACK_SIZE_SMALLITEM
  inst:AddComponent("tradable")

  -----------------

  inst:AddComponent("edible")
  inst.components.edible.healthvalue = TUNING.HEALING_TINY
  inst.components.edible.hungervalue = TUNING.CALORIES_TINY / 4

  inst:AddComponent("inspectable")

  inst:AddComponent("perishable")
  inst.components.perishable:SetPerishTime(TUNING.PERISH_MED)
  inst.components.perishable:StartPerishing()
  inst.components.perishable:SetOnPerishFn(onperish)

  MakeSmallBurnable(inst, TUNING.TINY_BURNTIME)
  MakeSmallPropagator(inst)

  return inst
end

STRINGS.ZETAPOLLEN = "Pollen"
STRINGS.NAMES.ZETAPOLLEN = "Pollen"
STRINGS.CHARACTERS.GENERIC.DESCRIBE.ZETAPOLLEN = "Gathered from flowers by bees."

return Prefab("zetapollen", fn, assets)
