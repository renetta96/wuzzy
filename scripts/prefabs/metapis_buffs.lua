-- learnt from spider_buffs.lua

local function OnExtended(inst, target)
  if inst.decaytimer ~= nil then
    inst.decaytimer:Cancel()
  end

  if inst.extendedfn ~= nil then
    inst.extendedfn(inst, target)
  end

  inst.decaytimer =
    inst:DoTaskInTime(
    inst.duration,
    function()
      inst.components.debuff:Stop()
    end
  )
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
    if target:IsValid() and target.components.locomotor then
      target.components.locomotor:SetExternalSpeedMultiplier(inst, "hasted_buff", 1.25)
    end
  end

  inst.detachfn = function(buff, target)
    target.hasted_buff = false

    if target:IsValid() and target.components.locomotor then
      target.components.locomotor:RemoveExternalSpeedMultiplier(inst)
    end
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

    local fx = target:EnableRageFX()
    if fx ~= nil then
      inst._fx = fx
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

local function frenzy_fn()
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

  inst.duration = GetRandomWithVariance(7, 3)

  inst.attachfn = function(buff, target, followsymbol)
    -- print("FRENZY ATTACHED")

    local fx = target:EnableFrenzyFx()
    if fx ~= nil then
      inst._fx = fx
    end
  end

  inst.extendedfn = function(buff, target)
    -- print("FRENZY EXTENDED")
    target.frenzy_buff = true
    target:RefreshAtkPeriod()

    if target:IsValid() and target.components.health then
      target.components.health.externalabsorbmodifiers:SetModifier(inst, -1.0 + math.random() * 0.5)
    end
  end

  inst.detachfn = function(buff, target)
    -- print("FRENZY DETACHED")
    target.frenzy_buff = false
    target:RefreshAtkPeriod()

    if inst._fx ~= nil then
      inst._fx:Remove()
    end

    if target:IsValid() and target.components.health then
      target.components.health.externalabsorbmodifiers:RemoveModifier(inst)
    end
  end

  inst:AddComponent("debuff")
  inst.components.debuff:SetAttachedFn(OnAttached)
  inst.components.debuff:SetDetachedFn(OnDetached)
  inst.components.debuff:SetExtendedFn(OnExtended)

  return inst
end

local enrage_assets = {
  Asset("ANIM", "anim/enrage_buff_fx.zip")
}

local function rage_fx()
  local function playAnim(inst)
    inst.entity:AddAnimState()
    inst.AnimState:SetBank("enrage_buff_fx")
    inst.AnimState:SetBuild("enrage_buff_fx")
    inst.AnimState:PlayAnimation("idle", true)
    inst.AnimState:SetMultColour(1.0, 1.0, 1.0, 0.3)
    inst.AnimState:SetBloomEffectHandle("shaders/anim.ksh")
    inst.AnimState:SetLightOverride(0.01)
    inst.AnimState:SetSortOrder(3)

    inst.entity:SetCanSleep(false)
    inst.persists = false
  end

  local function attach(inst, target)
    if target.components.debuffable then
      local followoffset = target.components.debuffable.followoffset
      local followsymbol = target.components.debuffable.followsymbol

      inst.entity:AddFollower():FollowSymbol(target.GUID, followsymbol, followoffset.x, followoffset.y, followoffset.z)

      inst:ListenForEvent(
        "death",
        function()
          inst:Remove()
        end,
        target
      )
      inst:ListenForEvent(
        "onremove",
        function()
          inst:Remove()
        end,
        target
      )
    end
  end

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

  inst.Attach = attach

  return inst
end

local frenzy_assets = {
  Asset("ANIM", "anim/frenzy_buff_fx.zip")
}

local function frenzy_fx()
  local function playAnim(inst)
    inst.entity:AddAnimState()
    inst.AnimState:SetBank("frenzy_buff_fx")
    inst.AnimState:SetBuild("frenzy_buff_fx")
    inst.AnimState:PlayAnimation("idle", true)
    inst.AnimState:SetMultColour(1.0, 1.0, 1.0, 0.3)
    inst.AnimState:SetBloomEffectHandle("shaders/anim.ksh")
    inst.AnimState:SetLightOverride(0.75)
    inst.AnimState:SetSortOrder(3)

    inst.entity:SetCanSleep(false)
  end

  local function attach(inst, target, symbol, offset_x, offset_y, offset_z)
    inst.entity:AddFollower():FollowSymbol(target.GUID, symbol, offset_x, offset_y, offset_z)

    inst:ListenForEvent(
      "death",
      function()
        inst:Remove()
      end,
      target
    )
    inst:ListenForEvent(
      "onremove",
      function()
        inst:Remove()
      end,
      target
    )
  end

  local inst = CreateEntity()

  inst.entity:AddTransform()
  inst.entity:AddNetwork()

  inst:AddTag("FX")

  if not TheNet:IsDedicated() then
    inst:DoTaskInTime(0, playAnim)
  end

  inst.entity:SetPristine()

  if not TheWorld.ismastersim then
    return inst
  end

  inst.entity:SetCanSleep(false)
  inst.persists = false

  inst.Attach = attach

  return inst
end

local function shred_fn()
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

  inst.duration = 5
  inst._stacks = 0

  inst.attachfn = function(buff, target, followsymbol)
    print("SHRED ATTACHED")
  end

  inst.extendedfn = function(buff, target)
    print("SHRED EXTENDED")
    inst._stacks = math.min(inst._stacks + 1, 20)

    if target:IsValid() and target.components.health then
      target.components.health.externalabsorbmodifiers:SetModifier(inst, -0.01 * inst._stacks)
      print("SHRED ", target.components.health.externalabsorbmodifiers:Get())
    end
  end

  inst.detachfn = function(buff, target)
    print("SHRED DETACHED")

    if target:IsValid() and target.components.health then
      target.components.health.externalabsorbmodifiers:RemoveModifier(inst)
    end
  end

  inst:AddComponent("debuff")
  inst.components.debuff:SetAttachedFn(OnAttached)
  inst.components.debuff:SetDetachedFn(OnDetached)
  inst.components.debuff:SetExtendedFn(OnExtended)

  return inst
end

local function stack_haste_fn()
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

  inst.duration = 3
  inst._stacks = 0

  inst.extendedfn = function(buff, target)
    inst._stacks = math.min(inst._stacks + 1, 3)
    print("HASTE BUFF", inst._stacks)

    if target:IsValid() and target.components.locomotor then
      target.components.locomotor:SetExternalSpeedMultiplier(inst, "stack_hasted_buff", 1.0 + 0.2 * inst._stacks)
    end
  end

  inst.detachfn = function(buff, target)
    if target:IsValid() and target.components.locomotor then
      target.components.locomotor:RemoveExternalSpeedMultiplier(inst)
    end
  end

  inst:AddComponent("debuff")
  inst.components.debuff:SetAttachedFn(OnAttached)
  inst.components.debuff:SetDetachedFn(OnDetached)
  inst.components.debuff:SetExtendedFn(OnExtended)

  return inst
end

local function frostbite_fn()
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

  inst.duration = 10
  inst._stacks = 0

  inst.extendedfn = function(buff, target)
    inst._stacks = math.min(inst._stacks + 1, 5)

    print("FROSTBITE EXTENDED", inst._stacks)

    if target:IsValid() then
      if target.components.locomotor then
        target.components.locomotor:SetExternalSpeedMultiplier(inst, "mutant_frostbite", 1.0 - 0.1 * inst._stacks)
      end

      if target.components.combat then
        target.components.combat.externaldamagemultipliers:SetModifier(inst, 1.0 - 0.02 * inst._stacks)
      end
    end
  end

  inst.detachfn = function(buff, target)
    print("FROSTBITE DETACHED")

    if target:IsValid() then
      if target.components.locomotor then
        target.components.locomotor:RemoveExternalSpeedMultiplier(inst)
      end

      if target.components.combat then
        target.components.combat.externaldamagemultipliers:RemoveModifier(inst)
      end
    end
  end

  inst:AddComponent("debuff")
  inst.components.debuff:SetAttachedFn(OnAttached)
  inst.components.debuff:SetDetachedFn(OnDetached)
  inst.components.debuff:SetExtendedFn(OnExtended)

  return inst
end

return Prefab("metapis_haste_buff", haste_fn), Prefab("metapis_rage_buff", rage_fn), Prefab(
  "metapis_frenzy_buff",
  frenzy_fn
), Prefab("metapis_rage_fx", rage_fx, enrage_assets), Prefab("metapis_frenzy_fx", frenzy_fx, frenzy_assets), Prefab(
  "metapis_shred_buff",
  shred_fn
), Prefab("metapis_stack_haste_buff", stack_haste_fn), Prefab("metapis_frostbite_buff", frostbite_fn)
