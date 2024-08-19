local metapis_common = require "metapis_common"

local IsAlly = metapis_common.IsAlly
local BarrackModifier = metapis_common.BarrackModifier
local FindTarget = metapis_common.FindTarget

local assets = {
    Asset("ANIM", "anim/mutantsoldierbee.zip"),
    Asset("SOUND", "sound/bee.fsb")
}

local prefabs = {
    "stinger",
    "honey"
}

-- local HEAL_IGNORE_TAGS = {"INLIMBO", "soldier"}
-- local HEAL_MUST_ONE_OF_TAGS = {"beemutant", "beemaster"}
-- local TARGET_MUST_TAGS = {"_combat", "_health"}

-- local function HealAllies(inst, amount)
--     local x, y, z = inst.Transform:GetWorldPosition()
--     local allies =
--         TheSim:FindEntities(
--         x,
--         y,
--         z,
--         TUNING.MUTANT_BEE_SOLDIER_HEAL_DIST,
--         TARGET_MUST_TAGS,
--         HEAL_IGNORE_TAGS,
--         HEAL_MUST_ONE_OF_TAGS
--     )

--     for i, ally in ipairs(allies) do
--         if
--             ally:IsValid() and ally.components.health and not ally.components.health:IsDead() and
--                 ally.components.locomotor and
--                 ally.components.combat and
--                 not IsAlly(ally.components.combat.target)
--          then
--             ally.components.health:DoDelta(amount)
--         end
--     end
-- end


-- local function OnAttackRegen(inst, data)
--     if inst.components.health then
--         local amount = Lerp(1, 5, 1 - inst.components.health:GetPercent())
--         inst.components.health:DoDelta(amount)

--         HealAllies(inst, amount / 2)
--     end
-- end

local function CounterAttack(inst)
    if inst:IsValid() and math.random() <= BarrackModifier(inst, TUNING.MUTANT_BEE_SOLDIER_COUNTER_ATK_CHANCE) then
        -- print("COUNTER ATTACK")
        inst.components.combat:ResetCooldown()
    end
end

local function CheckSoldierUpgrade(inst, stage)
    if stage >= 2 then
        inst.components.health:SetAbsorptionAmount(TUNING.MUTANT_BEE_SOLDIER_ABSORPTION)
    end

    if stage >= 3 then
        inst:ListenForEvent("attacked", CounterAttack)
    end

    inst.components.health:SetMaxHealth(BarrackModifier(inst, TUNING.MUTANT_BEE_SOLDIER_HEALTH))
    inst.components.combat:SetDefaultDamage(BarrackModifier(inst, TUNING.MUTANT_BEE_DAMAGE))

    return true
end

local function SoldierBuff(inst)
    inst.components.combat:SetAttackPeriod(TUNING.MUTANT_BEE_ATTACK_PERIOD - 0.5)
end

local function retargetfn(inst)
    return FindTarget(inst, TUNING.MUTANT_BEE_TARGET_DIST)
end

local killerbrain = require("brains/mutantkillerbeebrain")
local function killerbee()
    local inst = metapis_common.CommonInit(
    	"bee",
    	"mutantsoldierbee",
    	{"soldier", "killer", "scarytoprey"},
    	{buff = SoldierBuff, sounds = "killer"},
    	CheckSoldierUpgrade)

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
