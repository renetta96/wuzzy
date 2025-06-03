local metapis_common = require "metapis_common"

local IsAlly = metapis_common.IsAlly
local BarrackModifier = metapis_common.BarrackModifier
local FindTarget = metapis_common.FindTarget
local FindEnemies = metapis_common.FindEnemies
local CommonMasterInit = metapis_common.CommonMasterInit

local assets = {
  Asset("ANIM", "anim/mutantdefenderbee.zip"),
  Asset("ANIM", "anim/mutantdefenderbee_stomp.zip"),
  Asset("SOUND", "sound/bee.fsb")
}

local prefabs = {
  "stinger",
  "honey"
}

local poofysounds = {
  attack = "dontstarve/bee/killerbee_attack",
  -- attack = "dontstarve/creatures/together/bee_queen/beeguard/attack",
  buzz = "dontstarve/bee/killerbee_fly_LP",
  hit = "dontstarve/creatures/together/bee_queen/beeguard/hurt",
  death = "dontstarve/creatures/together/bee_queen/beeguard/death"
}

local function IsTaunted(guy)
  return guy.components.combat and guy.components.combat:HasTarget() and guy.components.combat.target:HasTag("defender")
end

local function Taunt(inst)
  local entities =
    FindEnemies(
    inst,
    TUNING.MUTANT_BEE_DEFENDER_TAUNT_DIST,
    function(e)
      -- to handle noobs that set combat.target directly!!!
      return e.components.combat and e.components.combat.losetargetcallback and not IsTaunted(e)
    end
  )

  for i, e in ipairs(entities) do
    e.components.combat:SetTarget(inst)
  end
end

local function OnDefenderStartCombat(inst)
  Taunt(inst)

  if inst._taunttask then
    inst._taunttask:Cancel()
  end

  inst._taunttask = inst:DoPeriodicTask(1, Taunt)
end

local function OnDefenderStopCombat(inst)
  if inst._taunttask then
    inst._taunttask:Cancel()
    inst._taunttask = nil
  end
end

local function CauseFrostBite(inst)
  if not inst.components.debuffable then
    inst:AddComponent("debuffable")
  end

  inst.components.debuffable:AddDebuff("metapis_frostbite_buff", "metapis_frostbite_buff")
end

local function AddColdness(inst, mult)
  if inst.components.freezable ~= nil then
    inst.components.freezable:AddColdness(TUNING.MUTANT_BEE_DEFENDER_COLDNESS * (mult or 1.0))
    inst.components.freezable:SpawnShatterFX()
  end
end

local function IceNova(inst)
  if not inst._retaliate then
    return
  end

  local enemies = FindEnemies(inst, 4)

  for i, e in ipairs(enemies) do
    -- print("RETALIATE", e)
    AddColdness(e, 2)
    inst.components.combat:DoAttack(e)
  end

  local fx = SpawnPrefab("icenova_fx")
  if fx ~= nil then
    fx.Transform:SetPosition(inst.Transform:GetWorldPosition())
  end
end

local function Retaliate(inst)
  if inst.components.health:IsDead() then
    return
  end

  if inst.sg:HasStateTag("stomp") then
    return
  end

  inst.sg:GoToState("stomp")
end

local function OnDefenderAttacked(inst, data)
  local attacker = data and data.attacker

  if not attacker or not attacker:IsValid() or (attacker.components.health and attacker.components.health:IsDead()) then
    return
  end

  if attacker:HasTag("beemaster") then
    return
  end

  if not attacker.components.colouradder then
    attacker:AddComponent("colouradder")
  end

  CauseFrostBite(attacker)

  if math.random() < 0.4 then
    AddColdness(attacker)
  end
end

local function calcMaxHealth(inst)
  if inst.buffed then
    return TUNING.MUTANT_BEE_DEFENDER_HEALTH + 250
  end

  return TUNING.MUTANT_BEE_DEFENDER_HEALTH
end

local function CheckDefenderUpgrade(inst, stage)
  local owner = inst:GetOwner()

  local protectaura = false
  local retaliate = false
  if owner and owner:HasTag("beemaster") then
    if owner.components.skilltreeupdater:IsActivated("zeta_metapis_defender_1") then
      protectaura = true
    end

    if owner.components.skilltreeupdater:IsActivated("zeta_metapis_defender_2") then
      retaliate = true
    end
  end

  if stage >= 2 then
    if not protectaura then
      inst.components.health.externalabsorbmodifiers:SetModifier(
        "motherhive_stage2",
        TUNING.MUTANT_BEE_DEFENDER_ABSORPTION
      )
    end

    inst._protectaura = protectaura
  end

  if stage >= 3 then
    inst._retaliate = retaliate
    inst:ListenForEvent("attacked", OnDefenderAttacked)
  end

  inst.components.health:SetMaxHealth(BarrackModifier(inst, calcMaxHealth(inst)))
  inst:RefreshBaseDamage()

  return true
end

local function GuardianBuff(inst)
  inst.components.health:SetMaxHealth(BarrackModifier(inst, calcMaxHealth(inst)))
end

local function retargetfn(inst)
  return FindTarget(inst, TUNING.MUTANT_BEE_TARGET_DIST)
end

local function GetDamageAbsorption(inst)
  local pcthealth = inst.components.health:GetPercent()
  local minabsoprtion = TUNING.MUTANT_BEE_DEFENDER_MIN_ABSORPTION
  local maxabsoprtion = TUNING.MUTANT_BEE_DEFENDER_MAX_ABSORPTION
  local threshold = TUNING.MUTANT_BEE_DEFENDER_MAX_ABSORPTION_THRESHOLD

  if pcthealth <= threshold then
    return maxabsoprtion
  end

  return Lerp(minabsoprtion, maxabsoprtion, (1.0 - pcthealth) / (1.0 - threshold))
end

local defenderbeebrain = require "brains/defenderbeebrain"
local function defenderbee()
  local inst = CreateEntity()

  inst.entity:AddTransform()
  inst.entity:AddAnimState()
  inst.entity:AddLight()
  inst.entity:AddDynamicShadow()
  inst.entity:AddSoundEmitter()
  inst.entity:AddNetwork()

  inst.Transform:SetSixFaced()
  inst.Transform:SetScale(1.4, 1.4, 1.4)

  inst.DynamicShadow:SetSize(1.2, .75)

  MakeFlyingCharacterPhysics(inst, 1.5, 0.1)

  inst.AnimState:SetBank("bee_guard")
  inst.AnimState:SetBuild("mutantdefenderbee")
  inst.AnimState:PlayAnimation("idle", true)

  inst:AddTag("insect")
  inst:AddTag("smallcreature")
  inst:AddTag("cattoyairborne")
  inst:AddTag("flying")
  inst:AddTag("beemutant")
  inst:AddTag("beemutantminion")
  inst:AddTag("companion")
  inst:AddTag("defender")
  inst:AddTag("ignorewalkableplatformdrowning")

  MakeInventoryFloatable(inst)

  inst.entity:SetPristine()

  if not TheWorld.ismastersim then
    return inst
  end

  CommonMasterInit(
    inst,
    {
      notburnable = true,
      notfreezable = true,
      notprotectable = true,
      buff = GuardianBuff,
      hitsymbol = "mane",
      basedamagefn = function()
        return TUNING.MUTANT_BEE_DEFENDER_DAMAGE
      end,
      atkperiodfn = function()
        return TUNING.MUTANT_BEE_DEFENDER_ATTACK_PERIOD
      end,
      rage_fx_scale_fn = function()
        return 5.5
      end,
      frenzy_fx_offset = {x = -3, y = 52, z = 0}
    },
    CheckDefenderUpgrade
  )
  inst.components.locomotor.walkspeed = 3
  inst.components.locomotor.pathcaps = {allowocean = true}

  inst.components.health:SetMaxHealth(TUNING.MUTANT_BEE_DEFENDER_HEALTH)
  local oldDoDelta = inst.components.health.DoDelta
  inst.components.health.DoDelta = function(comp, amount, ...)
    if amount < 0 then
      if inst._retaliate and math.random() <= 0.25 then
        Retaliate(inst)
      end

      if inst._protectaura then
        local finalamount = 0
        local numticks = 5
        -- print("ORIGIN AMOUNT", amount)
        for i = 1, numticks do
          local absorption = GetDamageAbsorption(inst)
          local subamount = (amount / numticks) * (1.0 - absorption)
          -- print("SUB AMOUNT", i, subamount, absorption)
          finalamount = finalamount + oldDoDelta(comp, subamount, ...)

          if inst.components.health:IsDead() then
            -- print("DEAD BREAK")
            break
          end
        end

        return finalamount
      end
    end

    -- default
    return oldDoDelta(comp, amount, ...)
  end

  inst.components.combat:SetDefaultDamage(TUNING.MUTANT_BEE_DEFENDER_DAMAGE)
  inst.components.combat:SetAttackPeriod(TUNING.MUTANT_BEE_DEFENDER_ATTACK_PERIOD)
  inst.components.combat:SetRange(TUNING.MUTANT_BEE_DEFENDER_ATTACK_RANGE)
  inst.components.combat:SetRetargetFunction(1, retargetfn)
  inst.components.combat.battlecryenabled = false

  MakeSmallFreezableCharacter(inst, "mane")
  inst.components.freezable:SetResistance(8)
  inst.components.freezable.diminishingreturns = true

  inst:SetStateGraph("SGdefenderbee")
  inst:SetBrain(defenderbeebrain)

  MakeHauntablePanic(inst)

  inst:ListenForEvent("newcombattarget", OnDefenderStartCombat)
  inst:ListenForEvent("droppedtarget", OnDefenderStopCombat)
  inst.sounds = poofysounds

  inst._protectaura = false
  inst._retaliate = false
  inst.IceNova = IceNova

  return inst
end

STRINGS.MUTANTDEFENDERBEE = "Metapis Moonguard"
STRINGS.NAMES.MUTANTDEFENDERBEE = "Metapis Moonguard"
STRINGS.CHARACTERS.GENERIC.DESCRIBE.MUTANTDEFENDERBEE = "Hard rock."

return Prefab("mutantdefenderbee", defenderbee, assets, prefabs)
