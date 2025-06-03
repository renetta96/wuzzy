local metapis_common = require "metapis_common"

local BarrackModifier = metapis_common.BarrackModifier
local FindTarget = metapis_common.FindTarget
local FindEnemies = metapis_common.FindEnemies
local DealPoison = metapis_common.DealPoison
local FindHealingTarget = metapis_common.FindHealingTarget

local assets = {
  Asset("ANIM", "anim/mutantmimicbee.zip"),
  Asset("ANIM", "anim/mutantbee_teleport.zip"),
  Asset("ANIM", "anim/mutantmimicbee_defender.zip"),
  Asset("ANIM", "anim/mutantmimicbee_ranger.zip"),
  Asset("ANIM", "anim/mutantmimicbee_shadow.zip"),
  Asset("ANIM", "anim/mutantmimicbee_assassin.zip"),
  Asset("ANIM", "anim/mutantmimicbee_healer.zip"),
  Asset("SOUND", "sound/bee.fsb")
}

local prefabs = {
  "stinger",
  "honey",
  "shadowspike_ring_4s"
}

local function MorphDefault(inst)
  inst.AnimState:OverrideSymbol("body", "mutantmimicbee", "body")
  inst.AnimState:OverrideSymbol("stinger", "mutantmimicbee", "stinger")
end

local function OnAttackOtherDefender(inst, data)
  local target = data.target

  if not target then
    return
  end

  if target.components.freezable and math.random() < 0.2 then
    target.components.freezable:AddColdness(TUNING.MUTANT_BEE_DEFENDER_COLDNESS)
    target.components.freezable:SpawnShatterFX()
  end

  if target._icebreaker_end == nil then
    target._icebreaker_end = GetTime() + 10

    target:ListenForEvent(
      "unfreeze",
      function()
        if GetTime() <= target._icebreaker_end and target.components.health and not target.components.health:IsDead() then
          if target._icebreaker_time == nil or target._icebreaker_time + 5 <= GetTime() then
            -- print("ICE BREAKER")
            local delta = BarrackModifier(inst, math.max(target.components.health.maxhealth * 0.005, 40))
            target.components.health:DoDelta(-delta)
            target._icebreaker_time = GetTime()
          end
        end
      end
    )
  else
    target._icebreaker_end = GetTime() + 10
  end
end

local function MorphDefender(inst)
  inst.AnimState:OverrideSymbol("body", "mutantmimicbee_defender", "body")
  inst.AnimState:OverrideSymbol("stinger", "mutantmimicbee_defender", "stinger")
end

local function MimicDefender(inst)
end

local function UnmimicDefender(inst)
end

local function OnAttackOtherRanger(inst, data)
  local target = data.target

  if not target then
    return
  end

  if target:IsValid() and inst:IsValid() then
    SpawnPrefab("electrichitsparks"):AlignToTarget(target, inst, true)
  end

  local owner = inst:GetOwner()

  if math.random() <= 0.35 then
    local ranger =
      FindEntity(
      target,
      15,
      function(guy)
        return guy:IsValid() and not guy.components.health:IsDead() and guy:GetOwner() == owner
      end,
      {"_combat", "_health", "beemutantminion"},
      {"INLIMBO", "player"},
      {"ranger"}
    )

    if ranger ~= nil then
      ranger.components.combat:DoAttack(target)
    end
  end
end

local function MorphRanger(inst)
  inst.AnimState:OverrideSymbol("body", "mutantmimicbee_ranger", "body")
  inst.AnimState:OverrideSymbol("stinger", "mutantmimicbee_ranger", "stinger")
  inst.AnimState:SetBloomEffectHandle("shaders/anim.ksh")
  inst.AnimState:SetLightOverride(0.02)
end

local function MimicRanger(inst)
  if not inst.components.electricattacks then
    inst:AddComponent("electricattacks")
  end
end

local function UnmimicRanger(inst)
  inst.AnimState:ClearBloomEffectHandle()
  inst.AnimState:SetLightOverride(0)

  if inst.components.electricattacks then
    inst:RemoveComponent("electricattacks")
  end
end

local function shredTarget(target)
  if not target.components.debuffable then
    target:AddComponent("debuffable")
  end

  target.components.debuffable:AddDebuff("metapis_shred_buff", "metapis_shred_buff")
end

local function OnAttackOtherShadow(inst, data)
  if data.stimuli and data.stimuli == "spikeattack" then
    return
  end

  local target = data.target
  if not target then
    return
  end

  -- 30% chance
  if math.random() > 0.3 then
    return
  end

  local spikefx = SpawnPrefab("shadowspike_ring_4s")
  if spikefx then
    spikefx.Transform:SetPosition(target.Transform:GetWorldPosition())
  end

  inst:DoTaskInTime(
    0.25,
    function()
      local enemies = FindEnemies(inst, 2)
      for i, target in ipairs(enemies) do
        if i > 4 then
          break
        end

        inst.components.combat:DoAttack(target, nil, nil, "spikeattack")
        shredTarget(target)
      end
    end
  )

  inst:DoTaskInTime(
    0.5,
    function()
      local enemies = FindEnemies(inst, 4)
      for i, target in ipairs(enemies) do
        if i > 4 then
          break
        end

        inst.components.combat:DoAttack(target, nil, nil, "spikeattack")
        shredTarget(target)
      end
    end
  )
end

local function MimicShadow(inst)
end

local function UnmimicShadow(inst)
  local r, g, b = inst.AnimState:GetMultColour()
  inst.AnimState:SetMultColour(r, g, b, 1.0)
end

local function MorphShadow(inst)
  inst.AnimState:OverrideSymbol("body", "mutantmimicbee_shadow", "body")
  inst.AnimState:OverrideSymbol("stinger", "mutantmimicbee_shadow", "stinger")

  local r, g, b = inst.AnimState:GetMultColour()
  inst.AnimState:SetMultColour(1, 1, 1, 0.6)
end

local function OnAttackOtherAssassin(inst, data)
  local target = data.target
  if not target then
    return
  end

  DealPoison(inst, target)

  target._crit_poison_end_time = GetTime() + 5
end

local function MimicAssassin(inst)
  inst.components.locomotor.groundspeedmultiplier = 1.5
end

local function UnmimicAssassin(inst)
  local r, g, b = inst.AnimState:GetMultColour()
  inst.AnimState:SetMultColour(r, g, b, 1.0)
  inst.components.locomotor.groundspeedmultiplier = 1.0
end

local function MorphAssassin(inst)
  local r, g, b = inst.AnimState:GetMultColour()
  inst.AnimState:SetMultColour(r, g, b, 0.6)

  inst.AnimState:OverrideSymbol("body", "mutantmimicbee_assassin", "body")
  inst.AnimState:OverrideSymbol("stinger", "mutantmimicbee_assassin", "stinger")
end

local function MimicHealer(inst)
end

local function UnmimicHealer(inst)
end

local function MorphHealer(inst)
  inst.AnimState:OverrideSymbol("body", "mutantmimicbee_healer", "body")
  inst.AnimState:OverrideSymbol("stinger", "mutantmimicbee_healer", "stinger")
end

local HEAL_MUST_TAGS = {"_combat", "_health"}
local HEAL_MUST_NOT_TAGS = {"player", "INLIMBO", "lesserminion"}
local HEAL_MUST_ONE_OF_TAGS = {"beemutantminion"}

local function OnAttackOtherHealer(inst, data)
  local target = data.target
  if not target then
    return
  end

  if math.random() > 0.3 then
    return
  end

  local ally = FindHealingTarget(inst)
  if ally then
    print("ATTACK HEALER", ally)
    ally.components.health:DoDelta(BarrackModifier(inst, 5), nil, "mutantmimic_heal", nil, inst)

    SpawnPrefab("heal_fx"):Attach(ally)
  end
end

-- mimicfn: setup functionalities, like components
-- morphfn: setup appearance, like AnimState:OverrrideSymbol, light, colors, etc
-- unmimicfn: cleanup both mimicfn and morphfn
-- onattackfn: for onattackother event
local canmimic = {
  mutantdefenderbee = {
    mimicfn = MimicDefender,
    unmimicfn = UnmimicDefender,
    morphfn = MorphDefender,
    onattackfn = OnAttackOtherDefender
  },
  mutantrangerbee = {
    mimicfn = MimicRanger,
    unmimicfn = UnmimicRanger,
    morphfn = MorphRanger,
    onattackfn = OnAttackOtherRanger
  },
  mutantshadowbee = {
    mimicfn = MimicShadow,
    unmimicfn = UnmimicShadow,
    morphfn = MorphShadow,
    onattackfn = OnAttackOtherShadow
  },
  mutantassassinbee = {
    mimicfn = MimicAssassin,
    unmimicfn = UnmimicAssassin,
    morphfn = MorphAssassin,
    onattackfn = OnAttackOtherAssassin
  },
  mutanthealerbee = {
    mimicfn = MimicHealer,
    unmimicfn = UnmimicHealer,
    morphfn = MorphHealer,
    onattackfn = OnAttackOtherHealer
  }
}

local function Unmimic(inst)
  -- print("UNMIMIC")

  if #inst._mimics > 0 then
    inst._mimics[1].unmimicfn(inst)
    table.remove(inst._mimics, 1)
  end
end

local function Mimic(inst, prefab)
  local mimic = canmimic[prefab]
  if not mimic then
    return
  end

  table.insert(inst._mimics, mimic)
  mimic.mimicfn(inst)

  local maxmimics = inst._maxmimics
  if math.random() < 0.25 then
    maxmimics = maxmimics + 1
  end

  while #inst._mimics > maxmimics do
    Unmimic(inst)
  end

  -- print("MIMIC", prefab, #inst._mimics)
  inst:PushEvent("mimic")
end

local function TryMimic(inst)
  -- if busy, try again in much shorter time
  if inst.sg:HasStateTag("busy") then
    inst:DoTaskInTime(1, TryMimic)
    return
  end

  local canmorph = {}

  for prefab, v in pairs(canmimic) do
    local entity =
      FindEntity(
      inst,
      20,
      function(guy, inst)
        return guy.prefab == prefab and guy:IsValid() and not guy.components.health:IsDead() and
          guy:GetOwner() == inst:GetOwner()
      end,
      {"_combat", "_health"},
      {"INLIMBO", "player", "lesserminion"},
      {"beemutantminion"}
    )
    if entity ~= nil then
      table.insert(canmorph, prefab)
    end
  end

  if #canmorph > 0 then
    Mimic(inst, canmorph[math.random(#canmorph)])
  else
    local currentsize = #inst._mimics
    Unmimic(inst)

    -- no unmimic animation, unless unmimic back to 0
    if currentsize > 0 and #inst._mimics == 0 then
      inst:PushEvent("mimic")
    end
  end

  inst:DoTaskInTime(GetRandomWithVariance(15, 5), TryMimic)
end

local function Morph(inst)
  if #inst._mimics > 0 then
    inst._mimics[#inst._mimics].morphfn(inst)
  else
    MorphDefault(inst)
  end
end

local function CounterAttack(inst)
  if inst:IsValid() and math.random() <= BarrackModifier(inst, TUNING.MUTANT_BEE_SOLDIER_COUNTER_ATK_CHANCE) then
    inst.components.combat:ResetCooldown()
  end
end

local function OnAttackOther(inst, data)
  for i, mimic in pairs(inst._mimics) do
    mimic.onattackfn(inst, data)
  end
end

local function CheckMimicUpgrade(inst, stage)
  local owner = inst:GetOwner()
  if owner and owner:HasTag("beemaster") then
    if owner.components.skilltreeupdater:IsActivated("zeta_metapis_mimic_2") then
      inst._maxmimics = 2
    end
  end

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

  inst:DoTaskInTime(GetRandomWithVariance(5, 2), TryMimic)

  inst:ListenForEvent("onattackother", OnAttackOther)

  return true
end

local function calcAtkPeriod(inst)
  if inst.buffed then
    return TUNING.MUTANT_BEE_ATTACK_PERIOD - 0.5
  end

  return TUNING.MUTANT_BEE_ATTACK_PERIOD
end

local function MimicBuff(inst)
  inst:RefreshAtkPeriod()
end

local function retargetfn(inst)
  return FindTarget(inst, TUNING.MUTANT_BEE_TARGET_DIST)
end

local brain = require("brains/mutantkillerbeebrain")
local function mimicbee()
  local inst =
    metapis_common.CommonInit(
    "bee",
    "mutantmimicbee",
    {"mimic", "killer", "scarytoprey"},
    {
      buff = MimicBuff,
      sounds = "killer",
      basedamagefn = function()
        return TUNING.MUTANT_BEE_DAMAGE
      end,
      atkperiodfn = calcAtkPeriod,
      rage_fx_scale_fn = function()
        return 2.5
      end,
      frenzy_fx_offset = {x = -5, y = 40, z = 0}
    },
    CheckMimicUpgrade
  )

  inst.Transform:SetScale(1.0, 1.0, 1.0)

  if not TheWorld.ismastersim then
    return inst
  end

  inst.components.health:SetMaxHealth(TUNING.MUTANT_BEE_SOLDIER_HEALTH)

  inst.components.combat:SetDefaultDamage(TUNING.MUTANT_BEE_DAMAGE)
  inst.components.combat:SetAttackPeriod(TUNING.MUTANT_BEE_ATTACK_PERIOD)
  inst.components.combat:SetRetargetFunction(1, retargetfn)
  inst.components.combat:SetRange(3, 6)

  inst:SetBrain(brain)

  MakeHauntablePanic(inst)

  inst.Mimic = Mimic
  inst.Unmimic = Unmimic
  inst.Morph = Morph
  inst._mimics = {}
  inst._maxmimics = 1

  return inst
end

STRINGS.MUTANTMIMICBEE = "Metapis Mimic"
STRINGS.NAMES.MUTANTMIMICBEE = "Metapis Mimic"
STRINGS.CHARACTERS.GENERIC.DESCRIBE.MUTANTMIMICBEE = "Improvise. Adapt. Overcome."

return Prefab("mutantmimicbee", mimicbee, assets, prefabs)
