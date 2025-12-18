local assets = {
    Asset("ANIM", "anim/stinger_nova.zip")
}

local function PlayAnim(proxy)
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.AnimState:SetBank("stinger_nova")
    inst.AnimState:SetBuild("stinger_nova")
    inst.AnimState:SetOrientation(ANIM_ORIENTATION.OnGround)
    inst.AnimState:SetLayer(LAYER_BACKGROUND)

    inst:AddTag("FX")

    --[[Non-networked entity]]
    inst.entity:SetCanSleep(false)
    inst.persists = false

    local parent = proxy.entity:GetParent()
    if parent ~= nil then
        inst.entity:SetParent(parent.entity)
    end

    inst.Transform:SetFromProxy(proxy.GUID)
    inst.AnimState:PlayAnimation("nova")
    inst.SoundEmitter:PlaySound("dontstarve/bee/beemine_explo")
    inst:ListenForEvent("animover", inst.Remove)
end

local function Attach(inst, target)
  if target.components.combat then
    inst.entity:AddFollower():FollowSymbol(target.GUID, target.components.combat.hiteffectsymbol, 0, 0, 0)
  else
    inst.Transform:SetPosition(target.Transform:GetWorldPosition())
  end
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddNetwork()

    inst:AddTag("FX")

    inst.entity:SetPristine()

    if not TheNet:IsDedicated() then
        inst:DoTaskInTime(0, PlayAnim)
    end

    if not TheWorld.ismastersim then
        return inst
    end

    inst.persists = false
    inst.Attach = Attach
    inst:DoTaskInTime(1, inst.Remove)

    return inst
end

local function SetStage(inst, stage)
  local anim = "status_" .. stage
  inst.AnimState:PlayAnimation(anim)
end

local function AlignToTarget(inst, target)
  inst.Transform:SetRotation(target.Transform:GetRotation())
end

local function Follow(inst, target)
  inst.entity:SetParent(target.entity)
  inst.Transform:SetPosition(0, 0, 0)

  if inst._followtask ~= nil then
    inst._followtask:Cancel()
  end

  AlignToTarget(inst, target)
  inst._followtask = inst:DoPeriodicTask(0, AlignToTarget, nil, target)
end

local function onremove(inst)
  if inst._followtask ~= nil then
    inst._followtask:Cancel()
  end
end

local function status_fn()
  local inst = CreateEntity()

  inst.entity:AddTransform()
  inst.entity:AddNetwork()
  inst.entity:AddAnimState()
  inst.AnimState:SetBank("stinger_nova")
  inst.AnimState:SetBuild("stinger_nova")
  inst.AnimState:SetOrientation(ANIM_ORIENTATION.OnGround)
  inst.AnimState:SetLayer(LAYER_BACKGROUND)
  inst.AnimState:PlayAnimation("status_5")
  inst.Transform:SetScale(1.2, 1.2, 1.2)

  inst:AddTag("FX")

  inst.entity:SetPristine()

  if not TheWorld.ismastersim then
    return inst
  end

  inst.persists = false
  inst.SetStage = SetStage
  inst.Follow = Follow
  inst:ListenForEvent("onremove", onremove)

  return inst
end

return Prefab("stinger_nova_fx", fn, assets), Prefab("stinger_nova_status", status_fn, assets)
