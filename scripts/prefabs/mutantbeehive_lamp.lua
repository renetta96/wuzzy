local assets =
{
  Asset("ANIM", "anim/mutantbeehive.zip"),
}

local function fn()
    local inst = CreateEntity()

  inst.entity:AddTransform()
  inst.entity:AddAnimState()
  inst.entity:AddNetwork()
  inst.entity:AddLight()

  inst.Light:SetIntensity(.75)
  inst.Light:SetColour(255 / 255, 200 / 255, 50 / 255)
  inst.Light:SetFalloff(.5)
  inst.Light:SetRadius(2)

  inst:AddTag("FX")
  inst:AddTag("DECOR")
  inst:AddTag("NOCLICK")

  inst.AnimState:SetBank("mutantbeehive")
  inst.AnimState:SetBuild("mutantbeehive")
  inst.AnimState:PlayAnimation("lamp_big", true)
  inst.AnimState:SetFinalOffset(1)

  inst:Hide()
  inst.Light:Enable(false)

  inst.entity:SetPristine()

  if not TheWorld.ismastersim then
    return inst
  end

  inst.persists = false

  return inst
end

return Prefab("mutantbeehive_lamp", fn, assets)
