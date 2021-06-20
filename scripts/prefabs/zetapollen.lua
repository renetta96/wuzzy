local zeta_utils = require "zeta_utils"

local assets =
{
  Asset("ANIM", "anim/zetapollen.zip"),
  Asset("ATLAS", "images/inventoryimages/zetapollen.xml"),
  Asset("IMAGE", "images/inventoryimages/zetapollen.tex")
}

local function checkiswet(inst)
	if inst.components.perishable then
	  if inst:GetIsWet() then
	    inst.components.perishable:SetLocalMultiplier(5)
	  else
	    inst.components.perishable:SetLocalMultiplier(1)
	  end
	end
end

local function onperish(inst)
  inst:Remove()
end

local function fn()
  local inst = CreateEntity()

  inst.entity:AddTransform()
  inst.entity:AddAnimState()
  inst.entity:AddNetwork()

  MakeInventoryPhysics(inst)

  inst.AnimState:SetBank("zetapollen")
  inst.AnimState:SetBuild("zetapollen")
  inst.AnimState:PlayAnimation("idle")

  inst.entity:SetPristine()
  inst:AddTag('honeyed')

  if not TheWorld.ismastersim then
      return inst
  end

  -----------------
  inst:AddComponent("inventoryitem")
  inst.components.inventoryitem.imagename = "zetapollen"
  inst.components.inventoryitem.atlasname = "images/inventoryimages/zetapollen.xml"

  inst:AddComponent("stackable")
  inst.components.stackable.maxsize = TUNING.STACK_SIZE_SMALLITEM
  inst:AddComponent("tradable")

  -----------------

  inst:AddComponent("edible")
  inst.components.edible.healthvalue = TUNING.HEALING_TINY
  inst.components.edible.hungervalue = 0

  inst:AddComponent("inspectable")

  inst:AddComponent("perishable")
  inst.components.perishable:SetPerishTime(TUNING.PERISH_MED)
  inst.components.perishable:StartPerishing()
  inst.components.perishable:SetOnPerishFn(onperish)

  MakeSmallBurnable(inst, TUNING.TINY_BURNTIME)
  MakeSmallPropagator(inst)
  MakeHauntableLaunchAndPerish(inst)
  zeta_utils.MakeStopPerishingInHive(inst)

  inst:DoPeriodicTask(1, checkiswet)

  return inst
end

STRINGS.ZETAPOLLEN = "Pollen"
STRINGS.NAMES.ZETAPOLLEN = "Pollen"
STRINGS.CHARACTERS.GENERIC.DESCRIBE.ZETAPOLLEN = "Gathered from flowers by bees."

return Prefab("zetapollen", fn, assets)
