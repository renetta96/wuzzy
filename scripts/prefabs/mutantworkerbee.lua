local metapis_common = require "metapis_common"

local assets = {
    Asset("ANIM", "anim/mutantworkerbee.zip"),
    Asset("SOUND", "sound/bee.fsb")
}

local prefabs = {
    "stinger",
    "honey"
}

local function CheckWorkerUpgrade(inst, stage)
    inst.components.pollinator.collectcount = math.max(5 - (stage - 1), 1)

    return true
end

local workerbrain = require("brains/mutantbeebrain")

local function workerbee()
    --pollinator (from pollinator component) added to pristine state for optimization
    --for searching: inst:AddTag("pollinator")
    local inst = metapis_common.CommonInit(
    	"bee",
    	"mutantworkerbee",
    	{"worker", "pollinator"},
    	{ sounds = "worker" },
    	CheckWorkerUpgrade
    )

    if not TheWorld.ismastersim then
        return inst
    end

    inst.components.health:SetMaxHealth(TUNING.MUTANT_BEE_HEALTH)
    inst.components.combat:SetDefaultDamage(TUNING.MUTANT_BEE_DAMAGE)
    inst.components.combat:SetAttackPeriod(TUNING.MUTANT_BEE_ATTACK_PERIOD)

    inst:AddComponent("pollinator")
    inst.components.pollinator.collectcount = 5

    inst:SetBrain(workerbrain)

    MakeHauntableChangePrefab(inst, "mutantkillerbee")


    return inst
end

STRINGS.MUTANTBEE = "Metapis Worker"
STRINGS.NAMES.MUTANTBEE = "Metapis Worker"
STRINGS.CHARACTERS.GENERIC.DESCRIBE.MUTANTBEE = "Meta...apis? Metabee? Like metahuman?"

return Prefab("mutantbee", workerbee, assets, prefabs)