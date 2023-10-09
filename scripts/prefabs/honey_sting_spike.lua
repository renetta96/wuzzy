local assets =
{
  Asset("ANIM", "anim/honey_sting_trap.zip"),
}

local function OnAttack(inst)
  inst.AnimState:PlayAnimation(inst.atk_anim)
  inst.AnimState:PushAnimation(inst.anim, true)
end

local function OnFinished(inst)
  inst.AnimState:PlayAnimation(anim, true)
  inst:DoTaskInTime(2, ErodeAway)
end

local function MakeSpike(anim, atk_anim)
  return function()
    local inst = CreateEntity()

    inst.entity:SetCanSleep(false)
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    inst:AddTag("NOCLICK")

    inst.AnimState:SetBank("honey_sting_trap")
    inst.AnimState:SetBuild("honey_sting_trap")
    inst.AnimState:SetLayer(LAYER_BACKGROUND)
    inst.AnimState:SetSortOrder(-2)

    inst.anim = anim
    inst.atk_anim = atk_anim

    inst.AnimState:PlayAnimation(anim, true)
    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
      return inst
    end


    inst.OnAttack = OnAttack
    inst.OnFinished = OnFinished
    inst.persists = false

    return inst
  end
end

return Prefab("honey_sting_spike_0", MakeSpike("spike_0", "spike_0_atk"), assets),
  Prefab("honey_sting_spike_1", MakeSpike("spike_1", "spike_1_atk"), assets)
