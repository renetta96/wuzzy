local metapis_common = require "metapis_common"

local BarrackModifier = metapis_common.BarrackModifier
local FindTarget = metapis_common.FindTarget
local FindEnemies = metapis_common.FindEnemies
local SpawnShadowlings = metapis_common.SpawnShadowlings
local DoAreaDamage = metapis_common.DoAreaDamage

local assets = {
    Asset("ANIM", "anim/mutantshadowbee.zip"),
    Asset("ANIM", "anim/mutantbee_teleport.zip"),
    Asset("SOUND", "sound/bee.fsb")
}

local prefabs = {
    "stinger",
    "honey",
    "shadowspike_ring_4s",
    "shadowspike_ring_6s",
    "shadowspike_ring_3s"
}


local function SpikeRingSmall(inst, target)
    if not target or not inst:IsValid() or not inst.components.combat:CanTarget(target) then
        return
    end

    local spikefx = SpawnPrefab("shadowspike_ring_4s")
    if spikefx then
        spikefx.Transform:SetPosition(target.Transform:GetWorldPosition())
    end

    inst:DoTaskInTime(0.25, function()
        -- because area damage ignores current target
        if target:IsValid() and not target.components.health:IsDead() then
            inst.components.combat:DoAttack(target, nil, nil, "spikeattack")
        end

        DoAreaDamage(inst, target, 2)
    end)

    inst:DoTaskInTime(0.5, function()
        if target:IsValid() and not target.components.health:IsDead() then
            inst.components.combat:DoAttack(target, nil, nil, "spikeattack")
        end

        DoAreaDamage(inst, target, 4)
    end)
end

local function SpikeRingBig(inst, target)
    if not target or not inst:IsValid() or not inst.components.combat:CanTarget(target) then
        return
    end

    local spikefx = SpawnPrefab("shadowspike_ring_6s")
    if spikefx then
        spikefx.Transform:SetPosition(target.Transform:GetWorldPosition())
    end

    inst:DoTaskInTime(0.25, function()
        -- because area damage ignores current target
        if target:IsValid() and not target.components.health:IsDead() then
            inst.components.combat:DoAttack(target, nil, nil, "spikeattack")
        end

        DoAreaDamage(inst, target, 3)
    end)

    inst:DoTaskInTime(0.5, function()
        if target:IsValid() and not target.components.health:IsDead() then
            inst.components.combat:DoAttack(target, nil, nil, "spikeattack")
        end

        DoAreaDamage(inst, target, 6)
    end)
end

local function Spike(inst, target)
    if inst._spikefn ~= nil then
        inst._spikefn(inst, target)
    end
end

local function OnShadowAttack(inst, data)
    if data.stimuli and data.stimuli == "spikeattack" then
        return
    end

    if data.target then
        Spike(inst, data.target)
    end
end

local function CheckShadowUpgrade(inst, stage)
    -- Add teleport
    if stage >= 2 then
        inst.canteleport = true
    end

    -- Add 1 more spike
    if stage >= 3 then
        inst._spikefn = SpikeRingBig
    end

    inst.components.health:SetMaxHealth(BarrackModifier(inst, TUNING.MUTANT_BEE_SHADOW_HEALTH))
    inst.components.combat:SetDefaultDamage(BarrackModifier(inst, TUNING.MUTANT_BEE_SHADOW_DAMAGE))

    local owner = inst:GetOwner()
    if owner and owner:HasTag("beemaster") then
        if owner.components.skilltreeupdater:IsActivated("zeta_metapis_shadow_1") then
            if not inst.components.timer:TimerExists("shadowling_cooldown") then
              inst.components.timer:StartTimer("shadowling_cooldown", GetRandomWithVariance(15, 5))
            end
        end
    end

    return true
end

local function ShadowBuff(inst)
    inst.components.combat:SetDefaultDamage(TUNING.MUTANT_BEE_SHADOW_DAMAGE + 3)
end

local function retargetfn(inst)
    return FindTarget(inst, TUNING.MUTANT_BEE_TARGET_DIST)
end

local function SpikeOnDeath(inst)
    -- 15% chance
    if math.random() > 0.15 then
        return
    end

    local spikefx = SpawnPrefab("shadowspike_ring_3s")
    if spikefx ~= nil then
        spikefx.Transform:SetPosition(inst.Transform:GetWorldPosition())
    end

    inst:DoTaskInTime(0.25, function()
        local enemies = FindEnemies(inst, 2)
        for i, target in ipairs(enemies) do
            if i > 3 then
                break
            end

            inst.components.combat:DoAttack(target, nil, nil, "spikeattack")
        end
    end)


    inst:DoTaskInTime(0.5, function()
        local enemies = FindEnemies(inst, 4)
        for i, target in ipairs(enemies) do
            if i > 3 then
                break
            end

            inst.components.combat:DoAttack(target, nil, nil, "spikeattack")
        end
    end)
end

local function OnTimerDone(inst, data)
  if data.name == "shadowling_cooldown" then
    if inst.components.combat:HasTarget() then
        SpawnShadowlings(inst, math.random(3, 5))
    end

    if not inst.components.timer:TimerExists("shadowling_cooldown") then
      inst.components.timer:StartTimer("shadowling_cooldown", GetRandomWithVariance(15, 5))
    end
  end
end


local shadowbeebrain = require "brains/shadowbeebrain"
local function shadowbee()
    local inst =
        metapis_common.CommonInit(
        "bee",
        "mutantshadowbee",
        {"shadowbee", "killer", "scarytoprey"},
        {notburnable = true, notfreezable = true, notsleep = true, buff = ShadowBuff, sounds = "killer"},
        CheckShadowUpgrade
    )

    local r, g, b = inst.AnimState:GetMultColour()
    inst.AnimState:SetMultColour(r, g, b, 0.6)

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("timer")
    inst:ListenForEvent("timerdone", OnTimerDone)

    inst.components.health:SetMaxHealth(TUNING.MUTANT_BEE_SHADOW_HEALTH)
    inst.components.combat:SetDefaultDamage(TUNING.MUTANT_BEE_SHADOW_DAMAGE)
    inst.components.combat:SetAttackPeriod(TUNING.MUTANT_BEE_SHADOW_ATK_PERIOD)
    inst.components.combat:SetRange(TUNING.MUTANT_BEE_SHADOW_ATK_RANGE, TUNING.MUTANT_BEE_SHADOW_ATK_RANGE + 3)
    inst.components.combat:SetRetargetFunction(1, retargetfn)

    inst._spikefn = SpikeRingSmall
    inst.canteleport = false

    inst:ListenForEvent("onattackother", OnShadowAttack)

    inst:SetBrain(shadowbeebrain)

    return inst
end

local function DecayHealth(inst)
    local pct = math.pow(1.25, inst._decayticks) -- decay in ~20 secs
    local amount = inst.components.health.maxhealth * pct / 100

    inst.components.health:DoDelta(-amount, nil, "lesser_shadow_health_decay")
    inst._decayticks = inst._decayticks + 1
end

local shadowlingbrain = require("brains/shadowlingbrain")
local function lessershadowfn()
    local inst = metapis_common.CommonInit(
        "bee",
        "mutantshadowbee",
        {"lessershadowbee", "killer", "scarytoprey"},
        {notburnable = true, notfreezable = true, notsleep = true, notprotectable = true, sounds = "killer"}
    )

    local r, g, b = inst.AnimState:GetMultColour()
    inst.AnimState:SetMultColour(r, g, b, 0.6)
    inst.Transform:SetScale(.7, .7, .7)

    if not TheWorld.ismastersim then
        return inst
    end

    inst.components.locomotor.groundspeedmultiplier = 2

    inst.components.health:SetMaxHealth(TUNING.MUTANT_SHADOWLING_HEALTH)
    inst.components.combat:SetDefaultDamage(TUNING.MUTANT_SHADOWLING_DAMAGE)
    inst.components.combat:SetAttackPeriod(TUNING.MUTANT_BEE_ATTACK_PERIOD)
    inst.components.combat:SetRange(1, 3)
    inst.components.combat:SetRetargetFunction(1, retargetfn)

    inst.components.lootdropper.numrandomloot = 0 -- no loot

    local oldDoDelta = inst.components.health.DoDelta
    inst.components.health.DoDelta = function(comp, amount, overtime, cause, ...)
        -- cannot be healed
        if amount > 0 then
            amount = 0
        end

        -- cap damage at x% max health, except decay health
        if amount < 0 and cause ~= "lesser_shadow_health_decay" then
            amount = math.max(amount,  -inst.components.health.maxhealth * TUNING.MUTANT_SHADOWLING_DAMAGE_CAP)
        end

        return oldDoDelta(comp, amount, overtime, cause, ...)
    end

    inst._decayticks = 0
    inst:DoPeriodicTask(1, DecayHealth)

    inst:SetBrain(shadowlingbrain)

    inst.SpikeOnDeath = SpikeOnDeath

    inst.persists = false

    return inst
end

STRINGS.MUTANTSHADOWBEE = "Metapis Shadow"
STRINGS.NAMES.MUTANTSHADOWBEE = "Metapis Shadow"
STRINGS.CHARACTERS.GENERIC.DESCRIBE.MUTANTSHADOWBEE = "Nightmare."

STRINGS.MUTANTSHADOWLING = "Metapis Shadowling"
STRINGS.NAMES.MUTANTSHADOWLING = "Metapis Shadowling"
STRINGS.CHARACTERS.GENERIC.DESCRIBE.MUTANTSHADOWLING = "Nightmare."

return Prefab("mutantshadowbee", shadowbee, assets, prefabs),
    Prefab("mutantshadowling", lessershadowfn, assets, prefabs)
