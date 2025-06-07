local metapis_common = require "metapis_common"
local easing = require "easing"

local IsAlly = metapis_common.IsAlly
local BarrackModifier = metapis_common.BarrackModifier
local FindTarget = metapis_common.FindTarget

local assets = {
  Asset("ANIM", "anim/mutantrangerbee.zip"),
  Asset("ANIM", "anim/mutantbee_teleport.zip"),
  Asset("SOUND", "sound/bee.fsb")
}

local prefabs = {
  "stinger",
  "honey",
  "electric_bubble",
  "blowdart_pipe"
}

local function calcAtkPeriod(inst)
  if inst.buffed then
    return TUNING.MUTANT_BEE_RANGED_ATK_PERIOD - 1
  end

  return TUNING.MUTANT_BEE_RANGED_ATK_PERIOD
end

local function RangerBuff(inst)
  inst:RefreshAtkPeriod()
end

local function TurnOffLight(inst)
  inst.Light:Enable(false)
  inst.AnimState:ClearBloomEffectHandle()
  inst.AnimState:SetLightOverride(0)
end

local function TurnOnLight(inst)
  inst.Light:Enable(true)

  inst.AnimState:SetBloomEffectHandle("shaders/anim.ksh")
  inst.AnimState:SetLightOverride(0.01)
end

local function OnStartCombat(inst)
  TurnOnLight(inst)
end

local function OnStopCombat(inst)
  inst:DoTaskInTime(
    5,
    function()
      if not inst.components.combat:HasTarget() then
        TurnOffLight(inst)
      end
    end
  )
end

local function SetLight(inst, override, radius, intensity)
  inst.Light:Enable(true)
  inst.AnimState:SetBloomEffectHandle("shaders/anim.ksh")
  inst.AnimState:SetLightOverride(override)

  inst.Light:SetRadius(radius)
  inst.Light:SetIntensity(intensity)
end

local function enable_chargefx(inst)
  if inst._chargefx == nil then
    local fx = SpawnPrefab("charge_fx")
    fx.entity:SetParent(inst.entity)
    fx:Attach(inst)
    inst._chargefx = fx
  end
end

local function disable_chargefx(inst)
  if inst._chargefx ~= nil then
    inst._chargefx:Remove()
    inst._chargefx = nil
  end
end

local function SpawnWisp(inst, target, damage)
  local min_radius = 12
  local max_radius = 15
  local radius = math.random(min_radius, max_radius)

  local currentdist = radius - min_radius
  local maxdist = max_radius - min_radius
  local speed = easing.linear(currentdist * currentdist, 17, 3, maxdist * maxdist) -- scale speed

  local pt = target:GetPosition()
  local startpos = inst:GetPosition()

  -- if inst ~= target, angle is the opposite direction from inst->target
  -- otherwise, use a random angle
  local angle = math.random(2 * PI)
  if inst ~= target then
    angle = VecUtil_GetAngleInRads(startpos.x - pt.x, startpos.z - pt.z) + PI
  end

  local offset = FindWalkableOffset(inst:GetPosition(), angle, radius, 12, false, true, nil, true, true)
  if offset ~= nil then
    local w_launch = SpawnPrefab("electric_wisp_launch")
    offset.x = offset.x + startpos.x
    offset.z = offset.z + startpos.z

    w_launch._target = target
    w_launch._dmg = damage
    w_launch:Launch(inst, offset, speed)
  end
end

local function Charge(inst)
  inst._charge = inst._charge + 1

  if inst._charge >= 15 and inst.components.combat:HasTarget() then
    -- snapshot damage
    SpawnWisp(inst, inst.components.combat.target, BarrackModifier(inst, TUNING.MUTANT_BEE_RANGED_WISP_DAMAGE))
    inst._charge = 0
  end

  if inst._charge >= 12 then
    SetLight(inst, 1.0, 2, 0.9)
    enable_chargefx(inst)
  elseif inst._charge >= 9 then
    SetLight(inst, 0.6, 1.5, 0.7)
    enable_chargefx(inst)
  elseif inst._charge >= 6 then
    SetLight(inst, 0.3, 1.25, 0.4)
    disable_chargefx(inst)
  elseif inst._charge >= 3 then
    SetLight(inst, 0.05, 0.75, 0.2)
    disable_chargefx(inst)
  else
    disable_chargefx(inst)
    TurnOffLight(inst)
    inst.Light:SetRadius(0)
    inst.Light:SetIntensity(0)
  end
end

local function LightningStrike(inst)
  if not inst.components.combat:HasTarget() then
    return
  end

  local target = inst.components.combat.target
  if target and target:IsValid() and not target.components.health:IsDead() then
    -- print("DO ATTACK", target, inst._resetatks)
    inst.components.combat:DoAttack(target)
  end
end

local function extendDischarge(inst, target)
  if target._discharge_task == nil then
    local dmg = BarrackModifier(inst, TUNING.MUTANT_BEE_RANGED_WISP_DAMAGE)

    target._discharge_fn = function()
      for i = 1, math.random(2, 4) do
        SpawnWisp(target, target, dmg)
      end
    end

    target:ListenForEvent("unfreeze", target._discharge_fn)
  else
    target._discharge_task:Cancel()
  end

  target._discharge_task =
    target:DoTaskInTime(
    10,
    function()
      if target._discharge_fn then
        target:RemoveEventCallback("unfreeze", target._discharge_fn)
      end
      target._discharge_fn = nil
      target._discharge_task = nil
    end
  )
end

local function OnAttack(inst, data)
  if inst._shouldicebreak and data and data.target then
    extendDischarge(inst, data.target)
  end

  if inst._shouldcharge then
    Charge(inst)
  end

  if inst._resetatks > 0 then
    -- print("RESET ATK", inst._resetatks)
    inst._resetatks = inst._resetatks - 1
  elseif not inst._resettime or inst._resettime + 5 < GetTime() then
    if inst._tripplechance ~= nil and math.random() <= inst._tripplechance then
      -- print("TRIPPLE")
      inst._resetatks = 2
      inst._resettime = GetTime()
    elseif inst._doublechance ~= nil and math.random() <= inst._doublechance then
      -- print("DOUBLE")
      inst._resetatks = 1
      inst._resettime = GetTime()
    end
  end

  if inst._resetatks > 0 then
    if not inst._shouldcircleatk then
      inst.components.combat:ResetCooldown()
    else
      LightningStrike(inst)
    end
  end
end

local function doCircleAtk(inst)
  inst._circleAtkTask = nil

  LightningStrike(inst)

  inst._circleAtkTask = inst:DoTaskInTime(inst.components.combat.min_attack_period, doCircleAtk)
end

local brains = require("brains/rangedkillerbeebrain")
local function CheckRangerUpgrade(inst, stage)
  local owner = inst:GetOwner()

  local shouldcircleatk = false
  local shouldcharge = false
  local shouldicebreak = false

  if owner and owner:HasTag("beemaster") then
    if owner.components.skilltreeupdater:IsActivated("zeta_metapis_ranger_1") then
      shouldcircleatk = true
      shouldcharge = true
    end

    if owner.components.skilltreeupdater:IsActivated("zeta_metapis_ranger_2") then
      shouldicebreak = true
    end
  end

  if shouldcircleatk then
    inst._shouldcircleatk = shouldcircleatk
    inst._leader_dist = 20
    inst:SetBrain(brains.circle_brain)
    inst.components.locomotor.groundspeedmultiplier = 1.75

    -- make sure one task at a time
    if inst._circleAtkTask ~= nil then
      inst._circleAtkTask:Cancel()
      inst._circleAtkTask = nil
    end

    inst._circleAtkTask = inst:DoTaskInTime(inst.components.combat.min_attack_period, doCircleAtk)
  end

  if shouldcharge then
    inst._shouldcharge = shouldcharge
    -- inst.components.combat:SetAttackPeriod(0)
    TurnOffLight(inst) -- just in case

    inst:ListenForEvent(
      "death",
      function()
        disable_chargefx(inst)
      end
    )
    inst:ListenForEvent(
      "onremove",
      function()
        disable_chargefx(inst)
      end
    )
  else
    inst:ListenForEvent("newcombattarget", OnStartCombat)
    inst:ListenForEvent("droppedtarget", OnStopCombat)
    if inst.components.combat:HasTarget() then
      OnStartCombat(inst)
    end
  end

  inst._shouldicebreak = shouldicebreak

  if stage >= 2 then
    inst._doublechance = 0.3
  end

  if stage >= 3 then
    inst._doublechance = 0.35
    inst._tripplechance = 0.2
  end

  inst.components.health:SetMaxHealth(BarrackModifier(inst, TUNING.MUTANT_BEE_RANGED_HEALTH))
  inst:RefreshBaseDamage()

  return true
end

local function RangedRetarget(inst)
  return FindTarget(inst, TUNING.MUTANT_BEE_RANGED_TARGET_DIST)
end

local function onweaponattack(inst, attacker, target)
  --target could be killed or removed in combat damage phase
  if target:IsValid() then
    SpawnPrefab("electrichitsparks"):AlignToTarget(target, inst)
  end
end

local function rangerbee()
  local inst =
    metapis_common.CommonInit(
    "bee",
    "mutantrangerbee",
    {"killer", "ranger", "scarytoprey"},
    {
      buff = RangerBuff,
      sounds = "killer",
      basedamagefn = function()
        return TUNING.MUTANT_BEE_RANGED_DAMAGE
      end,
      atkperiodfn = calcAtkPeriod,
      rage_fx_scale_fn = function()
        return 2.5
      end,
      frenzy_fx_offset = {x = -5, y = 45, z = 0}
    },
    CheckRangerUpgrade
  )

  inst.entity:AddLight()
  inst.Light:Enable(false)
  inst.Light:SetRadius(.75)
  inst.Light:SetFalloff(0.7)
  inst.Light:SetIntensity(.2)
  inst.Light:SetColour(154 / 255, 214 / 255, 216 / 255)

  if not TheWorld.ismastersim then
    return inst
  end

  inst.components.health:SetMaxHealth(TUNING.MUTANT_BEE_RANGED_HEALTH)
  inst.components.combat:SetRange(TUNING.MUTANT_BEE_WEAPON_ATK_RANGE)
  inst.components.combat:SetAttackPeriod(TUNING.MUTANT_BEE_RANGED_ATK_PERIOD)
  inst.components.combat:SetDefaultDamage(TUNING.MUTANT_BEE_RANGED_DAMAGE)
  inst.components.combat:SetRetargetFunction(1, RangedRetarget)

  inst:SetBrain(brains.normal_brain)

  MakeHauntablePanic(inst)

  inst:AddComponent("inventory")

  if not inst.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS) then
    local weapon = CreateEntity()
    weapon.entity:AddTransform()
    MakeInventoryPhysics(weapon)
    weapon:AddComponent("weapon")
    weapon.components.weapon:SetDamage(TUNING.MUTANT_BEE_RANGED_DAMAGE)
    weapon.components.weapon:SetRange(TUNING.MUTANT_BEE_WEAPON_ATK_RANGE)
    weapon.components.weapon:SetProjectile("electric_bubble")
    weapon.components.weapon:SetElectric()
    weapon.components.weapon:SetOnAttack(onweaponattack)

    weapon:AddComponent("inventoryitem")
    weapon.persists = false
    weapon.components.inventoryitem:SetOnDroppedFn(weapon.Remove)
    weapon:AddComponent("equippable")
    inst.weapon = weapon
    inst.components.inventory:Equip(inst.weapon)
  end

  inst:ListenForEvent("onattackother", OnAttack)
  inst:ListenForEvent("death", TurnOffLight)

  inst._resetatks = 0
  inst._shouldcircleatk = false
  inst._shouldcharge = false
  inst._charge = 0
  inst.Charge = Charge

  return inst
end

STRINGS.MUTANTRANGERBEE = "Metapis Voltwing"
STRINGS.NAMES.MUTANTRANGERBEE = "Metapis Voltwing"
STRINGS.CHARACTERS.GENERIC.DESCRIBE.MUTANTRANGERBEE = "It always tries to keep distance."

return Prefab("mutantrangerbee", rangerbee, assets, prefabs)
