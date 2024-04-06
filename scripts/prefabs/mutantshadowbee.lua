local metapis_common = require "metapis_common"

local IsAlly = metapis_common.IsAlly
local IsHostile = metapis_common.IsHostile
local BarrackModifier = metapis_common.BarrackModifier
local FindTarget = metapis_common.FindTarget
local FindEnemies = metapis_common.FindEnemies
local SpawnShadowlings = metapis_common.SpawnShadowlings

local assets = {
    Asset("ANIM", "anim/mutantshadowbee.zip"),
    Asset("ANIM", "anim/mutantbee_teleport.zip"),
    Asset("SOUND", "sound/bee.fsb")
}

local prefabs = {
    "stinger",
    "honey"
}

local function DoSpike(inst, target, onlyfx)
    if not target or not inst:IsValid() or not inst.components.combat:CanTarget(target) then
        return
    end

    local spikefx = SpawnPrefab("shadowspike_fx")
    if spikefx then
        spikefx.Transform:SetPosition(target.Transform:GetWorldPosition())
    end

    if not onlyfx then
        inst.components.combat:DoAttack(target, nil, nil, "spikeattack")
    end
end

local function Spike(inst, origin, numspikes, spike_origin)
    local entities = FindEnemies(origin, 5)

    if spike_origin == nil then
        spike_origin = true
    end

    local validtargets = {}
    for i, e in ipairs(entities) do
        if inst.components.combat:CanTarget(e) then
            if e.components.combat and (IsAlly(e.components.combat.target) or IsHostile(e)) then
                if e ~= origin then
                    table.insert(validtargets, e)
                end
            end
        end
    end

    if spike_origin then
        DoSpike(inst, origin, true)
    end

    if not (numspikes and numspikes > 0) then
        return
    end

    -- strike origin if not enough targets
    if spike_origin and #validtargets < numspikes then
        local remain = numspikes - #validtargets
        for i = 1,remain do
            table.insert(validtargets, origin)
        end
    end

    for i, target in ipairs(validtargets) do
        if i > numspikes then
            break
        end

        -- random delay from 0.25 to 1 sec
        inst:DoTaskInTime(
            math.random(25, 100) / 100,
            function()
                DoSpike(inst, target)
            end
        )
    end
end

local function OnShadowAttack(inst, data)
    if data.stimuli and data.stimuli == "spikeattack" then
        return
    end

    if data.target then
        Spike(inst, data.target, inst._numspikes)
    end
end

local function CheckShadowUpgrade(inst, stage)
    -- Add teleport
    if stage >= 2 then
        inst.canteleport = true
    end

    -- Add 1 more spike
    if stage >= 3 then
        inst._numspikes = TUNING.MUTANT_BEE_SHADOW_DEFAULT_NUM_SPIKES + 1
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
    Spike(inst, inst, math.random(2, 5), false)
end

local function OnTimerDone(inst, data)
  if data.name == "shadowling_cooldown" then
    SpawnShadowlings(inst, math.random(3, 5))

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

    inst._numspikes = TUNING.MUTANT_BEE_SHADOW_DEFAULT_NUM_SPIKES
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
        {notburnable = true, notfreezable = true, notsleep = true, sounds = "killer"}
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
