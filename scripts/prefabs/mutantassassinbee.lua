local metapis_common = require "metapis_common"

local IsAlly = metapis_common.IsAlly
local BarrackModifier = metapis_common.BarrackModifier
local FindTarget = metapis_common.FindTarget
local IsPoisonable = metapis_common.IsPoisonable
local MakePoisonable = metapis_common.MakePoisonable

local assets = {
    Asset("ANIM", "anim/mutantassassinbee.zip"),
    Asset("SOUND", "sound/bee.fsb")
}

local prefabs = {
    "stinger",
    "honey"
}

local function AssassinBuff(inst)
    inst.components.combat:SetDefaultDamage(TUNING.MUTANT_BEE_ASSSASIN_DAMAGE + 3)
end

local function OnStealthAttack(inst, data)
    if not data.target then
        return
    end

    if data.stimuli and data.stimuli == "stealthattack" then
        return
    end

    local target = data.target

    if not target.components.combat or not target.components.combat:TargetIs(inst) then
        local damagemult = TUNING.MUTANT_BEE_ASSASSIN_BACKSTAB_DAMAGE_MULT
        if target.components.health then
            damagemult = damagemult + (1 - target.components.health:GetPercent())
        end
        inst.components.combat:DoAttack(
            target,
            nil,
            nil,
            "stealthattack",
            TUNING.MUTANT_BEE_ASSASSIN_BACKSTAB_DAMAGE_MULT
        )
    end
end

local function OnAttackOtherWithPoison(inst, data)
    if data and IsPoisonable(data.target) then
        local source = "single_poison"
        local basedamage = TUNING.MUTANT_BEE_POISON_DAMAGE
        local numticks = TUNING.MUTANT_BEE_MAX_POISON_TICKS

        local owner = inst:GetOwner()
        if owner and owner:HasTag("beemaster") and owner.components.skilltreeupdater:IsActivated("zeta_metapis_assassin_1") then
            source = "stackable_poison"
            basedamage = TUNING.MUTANT_BEE_POISON_DAMAGE * 0.5
            numticks = TUNING.MUTANT_BEE_STACK_POISON_TICKS
        end

        MakePoisonable(data.target)

        basedamage = BarrackModifier(inst, basedamage)

        data.target.components.dotable:Add(source, basedamage, numticks)
    end

    local owner = inst:GetOwner()
    if owner and owner:IsValid() and owner:HasTag("beemaster") and not IsEntityDeadOrGhost(owner) then
        if owner.components.skilltreeupdater:IsActivated("zeta_metapis_assassin_2") and math.random() <= 0.25 then
            owner:EnablePoisonAttack()
        end
    end
end



local function CheckAssassinUpgrade(inst, stage)
    if stage >= 2 then
        inst:ListenForEvent("onattackother", OnStealthAttack)
    end

    if stage >= 3 then
        inst:ListenForEvent("onattackother", OnAttackOtherWithPoison)
    end

    inst.components.health:SetMaxHealth(BarrackModifier(inst, TUNING.MUTANT_BEE_ASSSASIN_HEALTH))
    inst.components.combat:SetDefaultDamage(BarrackModifier(inst, TUNING.MUTANT_BEE_ASSSASIN_DAMAGE))

    return true
end

local function Stealth(inst)
    local r, g, b = inst.AnimState:GetMultColour()
    inst.AnimState:SetMultColour(r, g, b, 0.4)
end

local function Unstealth(inst)
    local r, g, b = inst.AnimState:GetMultColour()
    inst.AnimState:SetMultColour(r, g, b, 1)
end


local function retargetfn(inst)
    return FindTarget(inst, TUNING.MUTANT_BEE_TARGET_DIST)
end

local assassinbeebrain = require "brains/assassinbeebrain"
local function assassinbee()
    local inst = metapis_common.CommonInit(
    	"bee", "mutantassassinbee",
    	{"killer", "assassin", "scarytoprey"},
        {buff = AssassinBuff, sounds = "killer"},
    	CheckAssassinUpgrade)

    if not TheWorld.ismastersim then
        return inst
    end

    inst.components.locomotor.groundspeedmultiplier = 1.5

    inst.components.health:SetMaxHealth(TUNING.MUTANT_BEE_ASSSASIN_HEALTH)
    inst.components.combat:SetDefaultDamage(TUNING.MUTANT_BEE_ASSSASIN_DAMAGE)
    inst.components.combat:SetAttackPeriod(TUNING.MUTANT_BEE_ASSASSIN_ATTACK_PERIOD)
    inst.components.combat:SetRetargetFunction(1, retargetfn)
    inst.components.combat:SetRange(3, 6)
    inst:SetBrain(assassinbeebrain)

    MakeHauntablePanic(inst)

    Stealth(inst)

    inst:ListenForEvent("newcombattarget", Unstealth)
    inst:ListenForEvent("droppedtarget", Stealth)

    inst.Stealth = Stealth
    inst.Unstealth = Unstealth

    return inst
end

STRINGS.MUTANTASSASSINBEE = "Metapis Mutant"
STRINGS.NAMES.MUTANTASSASSINBEE = "Metapis Mutant"
STRINGS.CHARACTERS.GENERIC.DESCRIBE.MUTANTASSASSINBEE = "Horrifying."

return Prefab("mutantassassinbee", assassinbee, assets, prefabs)