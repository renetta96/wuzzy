-- learnt from spider_buffs.lua

local assets = {
    Asset("ANIM", "anim/enrage_buff_fx.zip")
}

local function OnExtended(inst, target)
  if inst.decaytimer ~= nil then
    inst.decaytimer:Cancel()
  end

  if inst.extendedfn ~= nil then
    inst.extendedfn(inst, target)
  end

  inst.decaytimer = inst:DoTaskInTime(inst.duration, function() inst.components.debuff:Stop() end)
end

local function OnAttached(inst, target, followsymbol)
  if inst.attachfn ~= nil then
    inst.attachfn(inst, target, followsymbol)
  end

  OnExtended(inst, target)
end

local function OnDetached(inst, target)
  if inst.decaytimer ~= nil then
    inst.decaytimer:Cancel()
    inst.decaytimer = nil
  end

  if inst.detachfn ~= nil then
		inst.detachfn(inst, target)
  end

  inst:Remove()
end

local function haste_fn()
	local inst = CreateEntity()

  if not TheWorld.ismastersim then
    --Not meant for client!
    inst:DoTaskInTime(0, inst.Remove)

    return inst
  end

  inst.entity:AddTransform()

  --[[Non-networked entity]]
  --inst.entity:SetCanSleep(false)
  inst.entity:Hide()
  inst.persists = false

  inst:AddTag("CLASSIFIED")

  inst.duration = TUNING.OZZY_ENRAGE_BUFF_DURATION

  inst.extendedfn = function(buff, target)
    target.hasted_buff = true
    target.components.locomotor:SetExternalSpeedMultiplier(inst, "hasted_buff", 1.25)
  end

  inst.detachfn = function(buff, target)
    target.hasted_buff = false
    target.components.locomotor:RemoveExternalSpeedMultiplier(inst, "hasted_buff")
  end

  inst:AddComponent("debuff")
  inst.components.debuff:SetAttachedFn(OnAttached)
  inst.components.debuff:SetDetachedFn(OnDetached)
  inst.components.debuff:SetExtendedFn(OnExtended)

  return inst
end

local function rage_fn()
	local inst = CreateEntity()

  if not TheWorld.ismastersim then
    --Not meant for client!
    inst:DoTaskInTime(0, inst.Remove)

    return inst
  end

  inst.entity:AddTransform()

  --[[Non-networked entity]]
  --inst.entity:SetCanSleep(false)
  inst.entity:Hide()
  inst.persists = false

  inst:AddTag("CLASSIFIED")

  inst.duration = TUNING.OZZY_ENRAGE_BUFF_DURATION

  inst.attachfn = function(buff, target, followsymbol)
    -- print("RAGE ATTACH SPAWN FX")

    local fx = nil
    if target.prefab == "mutantdefenderbee" then
      fx = SpawnPrefab("metapis_rage_fx_big")
    else
      fx = SpawnPrefab("metapis_rage_fx_small")
    end

    if fx ~= nil then
      inst._fx = fx
      fx.entity:AddFollower():FollowSymbol(target.GUID, followsymbol, 0, 0, 0)

      fx:ListenForEvent("death", function() fx:Remove() end, target)
      fx:ListenForEvent("onremove", function() fx:Remove() end, target)
    end
  end

  inst.extendedfn = function(buff, target)
    target.raged_buff = true
    -- print("RAGE EXTEND REFRESH DAMAGE")
    target:RefreshBaseDamage()
  end

  inst.detachfn = function(buff, target)
    target.raged_buff = false

    if inst._fx ~= nil then
      inst._fx:Remove()
    end

    -- print("RAGE DETACH REFRESH DAMAGE")
    target:RefreshBaseDamage()
  end

  inst:AddComponent("debuff")
  inst.components.debuff:SetAttachedFn(OnAttached)
  inst.components.debuff:SetDetachedFn(OnDetached)
  inst.components.debuff:SetExtendedFn(OnExtended)

  return inst
end

local function MakeRageFX(scale)
  local function playAnim(inst)
    inst.entity:AddAnimState()
    inst.AnimState:SetBank("enrage_buff_fx")
    inst.AnimState:SetBuild("enrage_buff_fx")
    inst.AnimState:PlayAnimation("idle", true)
    inst.AnimState:SetMultColour(1.0, 1.0, 1.0, 0.3)
    inst.AnimState:SetBloomEffectHandle("shaders/anim.ksh")
    inst.AnimState:SetLightOverride(0.01)
    inst.AnimState:SetSortOrder(3)

    inst.Transform:SetScale(scale, scale, scale)

    inst.entity:SetCanSleep(false)
    inst.persists = false
  end

  local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddNetwork()

    inst:AddTag("FX")

    -- Dedicated server does not need to play the local fx anim
    if not TheNet:IsDedicated() then
      inst:DoTaskInTime(0, playAnim)
    end

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
      return inst
    end

    inst.entity:SetCanSleep(false)
    inst.persists = false

    return inst
  end

  return fn
end

return Prefab("metapis_haste_buff", haste_fn),
	Prefab("metapis_rage_buff", rage_fn),
  Prefab("metapis_rage_fx_small", MakeRageFX(2.5), assets),
  Prefab("metapis_rage_fx_big", MakeRageFX(5.5), assets)
