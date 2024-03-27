local metapis_common = require "metapis_common"

local IsAlly = metapis_common.IsAlly
local IsHostile = metapis_common.IsHostile
local BarrackModifier = metapis_common.BarrackModifier
local FindTarget = metapis_common.FindTarget
local FindEnemies = metapis_common.FindEnemies

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

local function Spike(inst, origin)
    local entities = FindEnemies(origin, 5)

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

    DoSpike(inst, origin, true)

    if not (inst._numspikes and inst._numspikes > 0) then
        return
    end

    -- strike origin if not enough targets
    if #validtargets < inst._numspikes then
        local remain = inst._numspikes - #validtargets
        for i = 1,remain do
            table.insert(validtargets, origin)
        end
    end

    for i, target in ipairs(validtargets) do
        if i > inst._numspikes then
            break
        end

        -- random delay from 0.25 to 0.75 sec
        inst:DoTaskInTime(
            math.random(25, 75) / 100,
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
        inst._numspikes = TUNING.MUTANT_BEE_SHADOW_DEFAULT_NUM_SPIKES + 1
    end

    inst.components.health:SetMaxHealth(BarrackModifier(inst, TUNING.MUTANT_BEE_SHADOW_HEALTH))
    inst.components.combat:SetDefaultDamage(BarrackModifier(inst, TUNING.MUTANT_BEE_SHADOW_DAMAGE))

    return true
end

local function ShadowBuff(inst)
    inst.components.combat:SetDefaultDamage(TUNING.MUTANT_BEE_SHADOW_DAMAGE + 3)
end

local function retargetfn(inst)
    return FindTarget(inst, TUNING.MUTANT_BEE_TARGET_DIST)
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

STRINGS.MUTANTSHADOWBEE = "Metapis Shadow"
STRINGS.NAMES.MUTANTSHADOWBEE = "Metapis Shadow"
STRINGS.CHARACTERS.GENERIC.DESCRIBE.MUTANTSHADOWBEE = "Nightmare."

return Prefab("mutantshadowbee", shadowbee, assets, prefabs)
