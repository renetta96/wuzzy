local assets = {
    Asset("ANIM", "anim/poison_fx.zip")
}

local function PlayAnim(proxy)
  local inst = CreateEntity()

  inst.entity:AddTransform()
  inst.entity:AddAnimState()
  inst.AnimState:SetBank("poison_fx")
  inst.AnimState:SetBuild("poison_fx")
  inst.AnimState:SetSortOrder(3)
  inst.AnimState:SetMultColour(1.0, 0.2, 1.0, 1)

  inst:AddTag("FX")
  --[[Non-networked entity]]
  inst.entity:SetCanSleep(false)
  inst.persists = false

  local parent = proxy.entity:GetParent()
  if parent ~= nil then
    inst.entity:SetParent(parent.entity)
  end

  inst.Transform:SetFromProxy(proxy.GUID)
  inst.AnimState:PlayAnimation("poison")

  inst:ListenForEvent("animover", inst.Remove)
end


local function fx()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddNetwork()

    inst:AddTag("FX")

    -- Dedicated server does not need to spawn the local fx
    if not TheNet:IsDedicated() then
        inst:DoTaskInTime(0, PlayAnim)
    end

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst.persists = false
    inst:DoTaskInTime(1, inst.Remove)

    return inst
end

return Prefab("poison_fx", fx, assets)
