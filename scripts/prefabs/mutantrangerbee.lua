local metapis_common = require "metapis_common"

local IsAlly = metapis_common.IsAlly
local BarrackModifier = metapis_common.BarrackModifier
local FindTarget = metapis_common.FindTarget

local assets = {
    Asset("ANIM", "anim/mutantrangerbee.zip"),
    Asset("SOUND", "sound/bee.fsb")
}

local prefabs = {
    "stinger",
    "honey",
    "electric_bubble",
    "blowdart_pipe"
}

local function RangerBuff(inst)
    inst.components.combat:SetAttackPeriod(TUNING.MUTANT_BEE_RANGED_ATK_PERIOD - 1)
end

local function OnAttackDoubleHit(inst, data)
    if inst._doublehitnow then
        inst.components.combat:ResetCooldown()
        inst._doublehitnow = false
    end

    if not inst._doublehittask then
        inst._doublehittask =
            inst:DoTaskInTime(
            TUNING.MUTANT_BEE_RANGED_ATK_PERIOD * 4,
            function(inst)
                inst._doublehitnow = true
                inst._doublehittask = nil
            end
        )
    end
end

local function TurnOffLight(inst)
    inst.Light:Enable(false)
end


local function CheckRangerUpgrade(inst, stage)
    if stage >= 2 then
        if inst.weapon and inst.weapon:IsValid() and inst.weapon.components.weapon then
            inst.weapon.components.weapon:SetElectric()
            inst.weapon.components.weapon:SetProjectile("electric_bubble")
            -- inst.weapon.components.weapon:SetOnAttack(OnRangedWeaponAttack)
        end

        inst.AnimState:SetBloomEffectHandle("shaders/anim.ksh")
        inst.Light:Enable(true)

        inst:ListenForEvent('death', TurnOffLight)
    end

    if stage >= 3 then
        inst._doublehitnow = true
        inst:ListenForEvent("onattackother", OnAttackDoubleHit)
    end

    inst.components.health:SetMaxHealth(BarrackModifier(inst, TUNING.MUTANT_BEE_RANGED_HEALTH))
    inst.components.combat:SetDefaultDamage(BarrackModifier(inst, TUNING.MUTANT_BEE_RANGED_DAMAGE))
    inst.weapon.components.weapon:SetDamage(inst.components.combat.defaultdamage)

    return true
end

local function RangedRetarget(inst)
    return FindTarget(inst, TUNING.MUTANT_BEE_RANGED_TARGET_DIST)
end

local rangedkillerbrain = require("brains/rangedkillerbeebrain")
local function rangerbee()
    local inst = metapis_common.CommonInit(
    	"bee",
    	"mutantrangerbee",
    	{"killer", "ranger", "scarytoprey"},
    	{buff = RangerBuff, sounds = "killer"},
    	CheckRangerUpgrade)

    inst.entity:AddLight()
    inst.Light:Enable(false)
    inst.Light:SetRadius(.75)
    inst.Light:SetFalloff(0.5)
    inst.Light:SetIntensity(.6)
    inst.Light:SetColour(154 / 255, 214 / 255, 216 / 255)


    if not TheWorld.ismastersim then
        return inst
    end

    inst.components.health:SetMaxHealth(TUNING.MUTANT_BEE_RANGED_HEALTH)
    inst.components.combat:SetRange(TUNING.MUTANT_BEE_WEAPON_ATK_RANGE)
    inst.components.combat:SetAttackPeriod(TUNING.MUTANT_BEE_RANGED_ATK_PERIOD)
    inst.components.combat:SetDefaultDamage(TUNING.MUTANT_BEE_RANGED_DAMAGE)
    inst.components.combat:SetRetargetFunction(1, RangedRetarget)

    inst:SetBrain(rangedkillerbrain)

    MakeHauntablePanic(inst)

    inst:AddComponent("inventory")

    if not inst.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS) then
        local weapon = CreateEntity()
        weapon.entity:AddTransform()
        MakeInventoryPhysics(weapon)
        weapon:AddComponent("weapon")
        weapon.components.weapon:SetDamage(inst.components.combat.defaultdamage)
        weapon.components.weapon:SetRange(inst.components.combat.attackrange)
        weapon.components.weapon:SetProjectile("blowdart_pipe")

        weapon:AddComponent("inventoryitem")
        weapon.persists = false
        weapon.components.inventoryitem:SetOnDroppedFn(weapon.Remove)
        weapon:AddComponent("equippable")
        inst.weapon = weapon
        inst.components.inventory:Equip(inst.weapon)
    end

    return inst
end

STRINGS.MUTANTRANGERBEE = "Metapis Ranger"
STRINGS.NAMES.MUTANTRANGERBEE = "Metapis Ranger"
STRINGS.CHARACTERS.GENERIC.DESCRIBE.MUTANTRANGERBEE = "It always tries to keep distance."

return Prefab("mutantrangerbee", rangerbee, assets, prefabs)
