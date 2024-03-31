local metapis_common = require "metapis_common"
local easing = require "easing"

local IsAlly = metapis_common.IsAlly
local BarrackModifier = metapis_common.BarrackModifier
local FindTarget = metapis_common.FindTarget

local assets = {
  Asset("ANIM", "anim/mutanthealerbee.zip"),
  Asset("SOUND", "sound/bee.fsb")
}

local prefabs = {
  "stinger",
  "honey",
  "explode_small",
  "heal_fx",
  "heal_projectile"
}

local function CheckHealerUpgrade(inst, stage)
  if stage >= 2 then
    inst._bounceheal = true
    inst._numbounce = 2
  end

  if stage >= 3 then
    inst._bounceheal = true
    inst._numbounce = 3

    if not inst.components.timer:TimerExists("heal_orb_cooldown") then
      inst.components.timer:StartTimer("heal_orb_cooldown", GetRandomWithVariance(inst._healorbcooldown, 2))
    end
  end

  inst.components.health:SetMaxHealth(BarrackModifier(inst, TUNING.MUTANT_BEE_HEALER_HEALTH))
  inst._healamount = BarrackModifier(inst, TUNING.MUTANT_BEE_HEALER_HEAL_AMOUNT)
  inst._healcumatk = BarrackModifier(inst, TUNING.MUTANT_BEE_HEALER_HEAL_ATK_AMOUNT)

  return true
end

local function HealerBuff(inst)
    inst.components.combat:SetAttackPeriod(TUNING.MUTANT_BEE_ATTACK_PERIOD - 0.5)
end

local function HealOrb(inst)
  local radius = math.random(TUNING.MUTANT_BEE_HEALER_MAX_HEAL_ORB_MIN_DISTANCE, TUNING.MUTANT_BEE_HEALER_MAX_HEAL_ORB_MAX_DISTANCE)

  local currentdist = radius - TUNING.MUTANT_BEE_HEALER_MAX_HEAL_ORB_MIN_DISTANCE
  local maxdist = TUNING.MUTANT_BEE_HEALER_MAX_HEAL_ORB_MAX_DISTANCE - TUNING.MUTANT_BEE_HEALER_MAX_HEAL_ORB_MIN_DISTANCE
  local speed = easing.linear(
    currentdist * currentdist,
    7, 3,
    maxdist * maxdist)

  local offset = FindWalkableOffset(inst:GetPosition(), math.random() * 2 * PI, radius, 12, true, false, nil, true)
  if offset ~= nil then
    local orb = SpawnPrefab("heal_projectile")
    local pos = inst:GetPosition()
    offset.x = offset.x + pos.x
    offset.z = offset.z + pos.z

    orb._healamount = inst._healorbamount
    orb:Launch(inst, offset, speed)
  end

  if not inst.components.timer:TimerExists("heal_orb_cooldown") then
    inst.components.timer:StartTimer("heal_orb_cooldown", GetRandomWithVariance(inst._healorbcooldown, 2))
  end
end

local function OnTimerDone(inst, data)
  if data.name == "heal_cooldown" then
    inst._canheal = true
  end

  if data.name == "heal_orb_cooldown" then
    HealOrb(inst)
  end
end

local function ishealable(inst, guy)
  return guy and guy:IsValid() and guy.components.health:IsHurt()
    and not (guy.components.combat and guy.components.combat.target and guy.components.combat.target:HasTag("beemutant")) -- don't heal bees fighting bees
    and inst:GetOwner() == guy:GetOwner() -- nil owner will heal nil owner
end

local HEAL_MUST_TAGS = {"_combat", "_health"}
local HEAL_MUST_NOT_TAGS = {"player", "INLIMBO"}
local HEAL_MUST_ONE_OF_TAGS = {"beemutantminion"}

local function FindHealingTarget(inst, origin)
  if not origin then
    origin = inst
  end


  local ally = FindEntity(origin, 8, function(guy)
    return ishealable(inst, guy)
  end, HEAL_MUST_TAGS, HEAL_MUST_NOT_TAGS, HEAL_MUST_ONE_OF_TAGS)

  return ally
end

local function DoHeal(inst, ally)
  local healamount = inst._healamount + inst._healcumatk * inst._numatks
  ally.components.health:DoDelta(healamount, nil, "mutantbee_heal", nil, inst)

  local fx = SpawnPrefab("heal_fx")
  fx:Attach(ally)
end

local function BounceHeal(inst, ally, num_bounced)
  local x, y, z = ally.Transform:GetWorldPosition()
  local allies = TheSim:FindEntities(
    x, y, z,
    8,
    HEAL_MUST_TAGS, HEAL_MUST_NOT_TAGS, HEAL_MUST_ONE_OF_TAGS
  )

  local bounce_left = inst._numbounce
  for i, e in pairs(allies) do
    if e ~= ally and ishealable(inst, e) then
      DoHeal(inst, e)
      bounce_left = bounce_left - 1
      if bounce_left <= 0 then
        break
      end
    end
  end
end

local function Heal(inst, ally)
  if ally and ally:IsValid() and ally:HasTag("beemutantminion") and ally.components.health then
    DoHeal(inst, ally)
    DoHeal(inst, inst) -- heal itself

    inst._canheal = false
    inst._numatks = 0

    if not inst.components.timer:TimerExists("heal_cooldown") then
      inst.components.timer:StartTimer("heal_cooldown", GetRandomWithVariance(inst._healcooldown, 2))
    end

    if inst._bounceheal then
      BounceHeal(inst, ally)
    end
  end
end

local function retargetfn(inst)
    return FindTarget(inst, TUNING.MUTANT_BEE_TARGET_DIST)
end

local function OnAttackOther(inst)
    inst._numatks = inst._numatks + 1
end

local brain = require("brains/mutanthealerbeebrain")
local function healerbee()
  local inst =
    metapis_common.CommonInit(
    "bee",
    "mutanthealerbee",
    {"healer", "killer", "scarytoprey"},
    {buff = HealerBuff, sounds = "killer"},
    CheckHealerUpgrade
  )

  inst.Transform:SetScale(0.85, 0.85, 0.85)

  if not TheWorld.ismastersim then
      return inst
  end

  inst.components.locomotor.groundspeedmultiplier = 1.25

  inst.components.health:SetMaxHealth(TUNING.MUTANT_BEE_HEALER_HEALTH)

  inst.components.combat:SetDefaultDamage(TUNING.MUTANT_BEE_HEALER_DAMAGE)
  inst.components.combat:SetAttackPeriod(TUNING.MUTANT_BEE_HEALER_ATK_PERIOD)
  inst.components.combat:SetRetargetFunction(1, retargetfn)
  inst.components.combat:SetRange(3, 6)

  inst:SetBrain(brain)

  inst._canheal = true
  inst._bounceheal = false
  inst._numbounce = 0
  inst._numatks = 0
  inst._healamount = TUNING.MUTANT_BEE_HEALER_HEAL_AMOUNT
  inst._healcumatk = TUNING.MUTANT_BEE_HEALER_HEAL_ATK_AMOUNT
  inst._healcooldown = TUNING.MUTANT_BEE_HEALER_HEAL_COOLDOWN

  inst._healorbamount = TUNING.MUTANT_BEE_HEALER_HEAL_ORB_AMOUNT
  inst._healorbcooldown = TUNING.MUTANT_BEE_HEALER_HEAL_ORB_COOLDOWN

  inst.Heal = Heal
  inst.FindHealingTarget = FindHealingTarget
  inst:AddComponent("timer")
  inst:ListenForEvent("timerdone", OnTimerDone)
  inst:ListenForEvent("onattackother", OnAttackOther)

  MakeHauntablePanic(inst)

  return inst
end

STRINGS.MUTANTHEALERBEE = "Metapis Alchemist"
STRINGS.NAMES.MUTANTHEALERBEE = "Metapis Alchemist"
STRINGS.CHARACTERS.GENERIC.DESCRIBE.MUTANTHEALERBEE = "Looks like a vial full of honey."

return Prefab("mutanthealerbee", healerbee, assets, prefabs)
