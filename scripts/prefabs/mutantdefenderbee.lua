local metapis_common = require "metapis_common"

local IsAlly = metapis_common.IsAlly
local BarrackModifier = metapis_common.BarrackModifier
local FindTarget = metapis_common.FindTarget
local FindEnemies = metapis_common.FindEnemies
local CommonMasterInit = metapis_common.CommonMasterInit

local assets = {
    Asset("ANIM", "anim/mutantdefenderbee.zip"),
    Asset("SOUND", "sound/bee.fsb")
}

local prefabs = {
    "stinger",
    "honey"
}


local function PushColour(inst, src, r, g, b, a)
    if inst.components.colouradder ~= nil then
        inst.components.colouradder:PushColour(src, r, g, b, a)
    else
        inst.AnimState:SetAddColour(r, g, b, a)
    end
end

local function PopColour(inst, src)
    if inst.components.colouradder ~= nil then
        inst.components.colouradder:PopColour(src)
    else
        inst.AnimState:SetAddColour(0, 0, 0, 0)
    end
end

local poofysounds = {
    attack = "dontstarve/bee/killerbee_attack",
    --attack = "dontstarve/creatures/together/bee_queen/beeguard/attack",
    buzz = "dontstarve/bee/killerbee_fly_LP",
    hit = "dontstarve/creatures/together/bee_queen/beeguard/hurt",
    death = "dontstarve/creatures/together/bee_queen/beeguard/death"
}

local function IsTaunted(guy)
    return guy.components.combat and guy.components.combat:HasTarget() and
        guy.components.combat.target:HasTag("defender")
end

local function Taunt(inst)
    local entities = FindEnemies(inst, TUNING.MUTANT_BEE_DEFENDER_TAUNT_DIST)

    for i, e in ipairs(entities) do
        -- to handle noobs that set combat.target directly!!!
        if e.components.combat and e.components.combat.losetargetcallback and not IsTaunted(e) then
            if IsAlly(e.components.combat.target) then
                e.components.combat:SetTarget(inst)
            end
        end
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
    inst._frostbite_expire = GetTime() + 9.75
    -- PushColour(inst, "mutant_frostbite", 82 / 255, 115 / 255, 124 / 255, 0)

    if inst.components.combat and not inst._currentattackperiod then
        inst._currentattackperiod = inst.components.combat.min_attack_period
        inst.components.combat:SetAttackPeriod(
            inst._currentattackperiod * TUNING.MUTANT_BEE_FROSTBITE_ATK_PERIOD_PENALTY
        )
    end

    if inst.components.locomotor.enablegroundspeedmultiplier then
        inst.components.locomotor:SetExternalSpeedMultiplier(
            inst,
            "mutant_frostbite",
            TUNING.MUTANT_BEE_FROSTBITE_SPEED_PENALTY
        )
        inst:DoTaskInTime(
            10,
            function(inst)
                if GetTime() >= inst._frostbite_expire then
                    -- PopColour(inst, "mutant_frostbite")
                    inst.components.locomotor:RemoveExternalSpeedMultiplier(inst, "mutant_frostbite")
                    if inst.components.combat and inst._currentattackperiod then
                        inst.components.combat:SetAttackPeriod(inst._currentattackperiod)
                        inst._currentattackperiod = nil
                    end
                end
            end
        )

        return
    end

    if not inst._currentspeed then
        inst._currentspeed = inst.components.locomotor.groundspeedmultiplier
    end
    inst.components.locomotor.groundspeedmultiplier = TUNING.MUTANT_BEE_FROSTBITE_SPEED_PENALTY
    inst:DoTaskInTime(
        10,
        function(inst)
            if GetTime() >= inst._frostbite_expire then
                -- PopColour(inst, "mutant_frostbite")
                if inst._currentspeed then
                    inst.components.locomotor.groundspeedmultiplier = inst._currentspeed
                    inst._currentspeed = nil
                end
                if inst.components.combat and inst._currentattackperiod then
                    inst.components.combat:SetAttackPeriod(inst._currentattackperiod)
                    inst._currentattackperiod = nil
                end
            end
        end
    )
end

local function OnDefenderAttacked(inst, data)
    local attacker = data and data.attacker

    if
        not (attacker and attacker.components.locomotor and attacker.components.health and
            not attacker.components.health:IsDead())
     then
        return
    end

    if attacker:HasTag("player") then
        return
    end

    if not attacker.components.colouradder then
        attacker:AddComponent("colouradder")
    end

    CauseFrostBite(attacker)

    if attacker.components.freezable ~= nil then
        attacker.components.freezable:AddColdness(TUNING.MUTANT_BEE_DEFENDER_COLDNESS)
        attacker.components.freezable:SpawnShatterFX()
    end
end

local function CheckDefenderUpgrade(inst, stage)
    if stage >= 2 then
        inst.components.health:SetAbsorptionAmount(TUNING.MUTANT_BEE_DEFENDER_ABSORPTION)
    end

    if stage >= 3 then
        inst:ListenForEvent("attacked", OnDefenderAttacked)
    end

    inst.components.health:SetMaxHealth(BarrackModifier(inst, TUNING.MUTANT_BEE_DEFENDER_HEALTH))
    inst.components.combat:SetDefaultDamage(BarrackModifier(inst, TUNING.MUTANT_BEE_DEFENDER_DAMAGE))

    return true
end

local function GuardianBuff(inst)
    inst:DoTaskInTime(1, function()
        inst.components.health:SetMaxHealth(BarrackModifier(inst, TUNING.MUTANT_BEE_DEFENDER_HEALTH) + 250)
    end)
end

local function retargetfn(inst)
    return FindTarget(inst, TUNING.MUTANT_BEE_TARGET_DIST)
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

    CommonMasterInit(inst, {notburnable = true, notfreezable = true, buff = GuardianBuff}, CheckDefenderUpgrade)
    inst.components.locomotor.walkspeed = 3
    inst.components.locomotor.pathcaps = {allowocean = true}

    inst.components.health:SetMaxHealth(TUNING.MUTANT_BEE_DEFENDER_HEALTH)

    inst.components.combat:SetDefaultDamage(TUNING.MUTANT_BEE_DEFENDER_DAMAGE)
    inst.components.combat:SetAttackPeriod(TUNING.MUTANT_BEE_DEFENDER_ATTACK_PERIOD)
    inst.components.combat:SetRange(TUNING.MUTANT_BEE_DEFENDER_ATTACK_RANGE)
    inst.components.combat:SetRetargetFunction(1, retargetfn)
    inst.components.combat.battlecryenabled = false
    inst.components.combat.hiteffectsymbol = "mane"

    MakeSmallFreezableCharacter(inst, "mane")
    inst.components.freezable:SetResistance(8)
    inst.components.freezable.diminishingreturns = true

    inst:SetStateGraph("SGdefenderbee")
    inst:SetBrain(defenderbeebrain)

    MakeHauntablePanic(inst)

    inst:ListenForEvent("newcombattarget", OnDefenderStartCombat)
    inst:ListenForEvent("droppedtarget", OnDefenderStopCombat)
    inst.sounds = poofysounds

    return inst
end

STRINGS.MUTANTDEFENDERBEE = "Metapis Moonguard"
STRINGS.NAMES.MUTANTDEFENDERBEE = "Metapis Moonguard"
STRINGS.CHARACTERS.GENERIC.DESCRIBE.MUTANTDEFENDERBEE = "Hard rock."

return Prefab("mutantdefenderbee", defenderbee, assets, prefabs)
