local easing = require("easing")

local assets = {
  Asset("ANIM", "anim/heal_projectile.zip")
}

local function OnHit(inst, owner, target)
  local orb = SpawnPrefab("heal_orb")
  orb._healamount = inst._healamount
  orb.Transform:SetPosition(inst.Transform:GetWorldPosition())

  inst:Remove()
end

local function Launch(inst, attacker, pos, speed)
  local x, y, z = attacker.Transform:GetWorldPosition()
  inst.Transform:SetPosition(x, y, z)

  if speed ~= nil then
    inst.components.complexprojectile:SetHorizontalSpeed(speed)
  end

  inst.components.complexprojectile:Launch(pos, attacker)
end

local function fn()
  local inst = CreateEntity()

  inst.entity:AddTransform()
  inst.entity:AddAnimState()
  inst.entity:AddNetwork()

  MakeProjectilePhysics(inst)
  RemovePhysicsColliders(inst)

  inst.Transform:SetFourFaced()

  inst.AnimState:SetBank("heal_projectile")
  inst.AnimState:SetBuild("heal_projectile")
  inst.AnimState:PlayAnimation("launch_loop", true)
  inst.Transform:SetScale(3.5, 3.5, 3.5)

  inst.AnimState:SetBloomEffectHandle("shaders/anim.ksh")
  inst.AnimState:SetLightOverride(0.3)

  --projectile (from projectile component) added to pristine state for optimization
  inst:AddTag("projectile")

  inst.entity:SetPristine()

  if not TheWorld.ismastersim then
    return inst
  end

  inst.persists = false
  inst._healamount = TUNING.MUTANT_BEE_HEALER_HEAL_ORB_AMOUNT -- default

  inst:AddComponent("locomotor")
  inst:AddComponent("complexprojectile")

  inst.components.complexprojectile:SetHorizontalSpeed(10)
  inst.components.complexprojectile:SetGravity(-25)
  inst.components.complexprojectile:SetLaunchOffset(Vector3(0, 2.5, 0))
  inst.components.complexprojectile:SetOnHit(OnHit)

  inst.Launch = Launch

  return inst
end

local function Heal(inst, other)
  if other ~= nil and other:IsValid() and inst:IsValid() and other:HasTag("beemaster") then
    local healeffect = other._healorbeffect ~= nil and other._healorbeffect or 1.0
    other.components.health:DoDelta(inst._healamount * healeffect, nil, "mutantbee_heal")
    other:OnConsumeHealOrb()

    inst:Remove()

    local fx = SpawnPrefab("player_heal_fx")
    fx:Attach(other)
  end
end

local function CheckPlayer(inst)
  local x, y, z = inst.Transform:GetWorldPosition()
  local rangesq = 2 * 2 -- pick up within 2 units

  local closest = nil
  for i, v in ipairs(AllPlayers) do
    if
      not (v.components.health:IsDead() or v:HasTag("playerghost")) and v.entity:IsVisible() and v:IsValid() and
        v:HasTag("beemaster")
     then
      local distsq = v:GetDistanceSqToPoint(x, y, z)
      if distsq < rangesq then
        rangesq = distsq
        closest = v
      end
    end
  end

  if closest ~= nil then
    Heal(inst, closest)
  end
end

local function orb_fn()
  local inst = CreateEntity()

  inst.entity:AddTransform()
  inst.entity:AddAnimState()
  inst.entity:AddSoundEmitter()
  inst.entity:AddNetwork()

  MakeProjectilePhysics(inst)
  RemovePhysicsColliders(inst)

  inst.Transform:SetFourFaced()

  inst.AnimState:SetBank("heal_projectile")
  inst.AnimState:SetBuild("heal_projectile")
  inst.AnimState:PlayAnimation("idle", true)
  inst.Transform:SetScale(3.5, 3.5, 3.5)

  inst.AnimState:SetBloomEffectHandle("shaders/anim.ksh")
  inst.AnimState:SetLightOverride(0.3)

  inst.entity:SetPristine()

  if not TheWorld.ismastersim then
    return inst
  end

  inst._healamount = TUNING.MUTANT_BEE_HEALER_HEAL_ORB_AMOUNT -- default

  inst:DoPeriodicTask(0.2, CheckPlayer)

  inst:DoTaskInTime(10, inst.Remove)

  return inst
end

local function PlayAnim(proxy)
  local inst = CreateEntity()

  inst.entity:AddTransform()
  inst.entity:AddAnimState()
  inst.AnimState:SetBank("heal_projectile")
  inst.AnimState:SetBuild("heal_projectile")
  inst.AnimState:SetBloomEffectHandle("shaders/anim.ksh")
  inst.AnimState:SetLightOverride(0.7)
  inst.AnimState:SetSortOrder(3)

  if proxy._scale ~= nil then
    inst.AnimState:SetScale(proxy._scale, proxy._scale, proxy._scale)
  end

  inst:AddTag("FX")
  --[[Non-networked entity]]
  inst.entity:SetCanSleep(false)
  inst.persists = false

  local parent = proxy.entity:GetParent()
  if parent ~= nil then
    inst.entity:SetParent(parent.entity)
  end

  inst.Transform:SetFromProxy(proxy.GUID)

  inst.AnimState:PlayAnimation("fx")
  inst:ListenForEvent("animover", inst.Remove)
end

local function Attach(inst, target)
  if target.components.combat then
    inst.entity:AddFollower():FollowSymbol(target.GUID, target.components.combat.hiteffectsymbol, 0, 0, 0)
  else
    inst.Transform:SetPosition(target.Transform:GetWorldPosition())
  end
end

local function makefx(scale)
  return function()
    local inst = CreateEntity()
    inst._scale = scale

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

    inst.Attach = Attach
    inst.persists = false
    inst:DoTaskInTime(1, inst.Remove)

    return inst
  end
end

return Prefab("heal_projectile", fn, assets), Prefab("heal_orb", orb_fn, assets), Prefab("heal_fx", makefx(), assets), Prefab(
  "player_heal_fx",
  makefx(1.5),
  assets
)
