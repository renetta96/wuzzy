local metapis_common = require "metapis_common"

local IsAlly = metapis_common.IsAlly
local BarrackModifier = metapis_common.BarrackModifier
local FindTarget = metapis_common.FindTarget

local assets = {
  Asset("ANIM", "anim/mutantsoldierbee.zip"),
  Asset("ANIM", "anim/mutantbee_teleport.zip"),
  Asset("SOUND", "sound/bee.fsb")
}

local prefabs = {
  "stinger",
  "honey"
}

local function CounterAttack(inst)
  if inst:IsValid() and math.random() <= BarrackModifier(inst, TUNING.MUTANT_BEE_SOLDIER_COUNTER_ATK_CHANCE) then
    -- print("COUNTER ATTACK")
    inst.components.combat:ResetCooldown()
  end
end

local function CheckSoldierUpgrade(inst, stage)
  if stage >= 2 then
    inst.components.health.externalabsorbmodifiers:SetModifier(
      "motherhive_stage2",
      TUNING.MUTANT_BEE_SOLDIER_ABSORPTION
    )
  end

  if stage >= 3 then
    inst:ListenForEvent("attacked", CounterAttack)
  end

  inst.components.health:SetMaxHealth(BarrackModifier(inst, TUNING.MUTANT_BEE_SOLDIER_HEALTH))
  inst:RefreshBaseDamage()

  return true
end

local function calcAtkPeriod(inst)
  if inst.buffed then
    return TUNING.MUTANT_BEE_ATTACK_PERIOD - 0.5
  end

  return TUNING.MUTANT_BEE_ATTACK_PERIOD
end

local function SoldierBuff(inst)
  inst:RefreshAtkPeriod()
end

local function retargetfn(inst)
  return FindTarget(inst, TUNING.MUTANT_BEE_TARGET_DIST)
end

local killerbrain = require("brains/mutantkillerbeebrain")
local function killerbee()
  local inst =
    metapis_common.CommonInit(
    "bee",
    "mutantsoldierbee",
    {"soldier", "killer", "scarytoprey"},
    {
      buff = SoldierBuff,
      sounds = "killer",
      basedamagefn = function()
        return TUNING.MUTANT_BEE_DAMAGE
      end,
      atkperiodfn = calcAtkPeriod,
      rage_fx_scale_fn = function()
        return 2.5
      end,
      frenzy_fx_offset = {x = -3, y = 42, z = 0}
    },
    CheckSoldierUpgrade
  )

  if not TheWorld.ismastersim then
    return inst
  end

  inst.components.health:SetMaxHealth(TUNING.MUTANT_BEE_SOLDIER_HEALTH)

  inst.components.combat:SetDefaultDamage(TUNING.MUTANT_BEE_DAMAGE)
  inst.components.combat:SetAttackPeriod(TUNING.MUTANT_BEE_ATTACK_PERIOD)
  inst.components.combat:SetRetargetFunction(1, retargetfn)
  inst.components.combat:SetRange(3, 6)

  inst:SetBrain(killerbrain)

  MakeHauntablePanic(inst)

  return inst
end

STRINGS.MUTANTKILLERBEE = "Metapis Soldier"
STRINGS.NAMES.MUTANTKILLERBEE = "Metapis Soldier"
STRINGS.CHARACTERS.GENERIC.DESCRIBE.MUTANTKILLERBEE = "Little grunt."

return Prefab("mutantkillerbee", killerbee, assets, prefabs)
