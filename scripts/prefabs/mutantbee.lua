local beecommon = require "brains/mutantbeecommon"

--[[
Bees.lua

bee
Default bee type. Flies around to flowers and pollinates them, generally gets spawned out of beehives or player-made beeboxes

killerbee
Aggressive version of the bee. Doesn't pollinate anythihng, but attacks anything within range. If it has a home to go to and no target,
it should head back there. Killer bees come out to defend beehives when they, the hive or worker bees are attacked
]]--
local assets =
{
    Asset("ANIM", "anim/bee.zip"),
    Asset("ANIM", "anim/bee_build.zip"),
    Asset("ANIM", "anim/bee_angry_build.zip"),
    Asset("ANIM", "anim/mutantbee_build.zip"), -- New anim
    Asset("ANIM", "anim/mutantbee_angry_build.zip"), -- New anim
    Asset("SOUND", "sound/bee.fsb"),
}

local prefabs =
{
    "stinger",
    "honey",
    "explosive_small",
    "blowdart_walrus",
}

local workersounds =
{
    takeoff = "dontstarve/bee/bee_takeoff",
    attack = "dontstarve/bee/bee_attack",
    buzz = "dontstarve/bee/bee_fly_LP",
    hit = "dontstarve/bee/bee_hurt",
    death = "dontstarve/bee/bee_death",
}

local killersounds =
{
    takeoff = "dontstarve/bee/killerbee_takeoff",
    attack = "dontstarve/bee/killerbee_attack",
    buzz = "dontstarve/bee/killerbee_fly_LP",
    hit = "dontstarve/bee/killerbee_hurt",
    death = "dontstarve/bee/killerbee_death",
}

local function FindTarget(inst, dist)
    return FindEntity(inst, SpringCombatMod(dist),
        function(guy)
            return inst.components.combat:CanTarget(guy)
        end,
        { "_combat", "_health" },
        { "insect", "INLIMBO" },
        { "monster" })
        or FindEntity(inst, SpringCombatMod(dist),
        function(guy)
            return inst.components.combat:CanTarget(guy)
                and guy.components.combat and guy.components.combat.target
                and guy.components.combat.target:HasTag("player")
        end, 
        { "_combat", "_health" },
        { "mutant", "INLIMBO" },
        { "monster", "insect", "animal", "character" })
end

-- /* Mutant effects
local function DoPoisonDamage(inst)
    if inst._poisonticks <= 0 or inst.components.health:IsDead() then
        inst._poisontask:Cancel()
        inst._poisontask = nil
        return
    end

    inst.components.health:DoDelta(TUNING.MUTANT_BEE_POISON_DAMAGE, true, "poison_sting")

    local c_r, c_g, c_b, c_a = inst.AnimState:GetMultColour()
    inst.AnimState:SetMultColour(0.8, 0.2, 0.8, 1)
    inst:DoTaskInTime(0.2, function(inst)
            inst.AnimState:SetMultColour(c_r, c_g, c_b, c_a)       
        end)

    inst._poisonticks = inst._poisonticks - 1

    if inst._poisonticks <= 0 or inst.components.health:IsDead() then
        inst._poisontask:Cancel()
        inst._poisontask = nil
    end
end

local function OnAttackOtherWithPoison(inst, data)
    if data.target and data.target.components.health and not data.target.components.health:IsDead() then
        -- No target players.
        if not data.target:HasTag("player") then
            data.target._poisonticks = TUNING.MUTANT_BEE_MAX_POISON_TICKS
            if data.target._poisontask == nil then
                data.target._poisontask = data.target:DoPeriodicTask(TUNING.MUTANT_BEE_POISON_PERIOD, DoPoisonDamage)
            end
        end
    end
end

local function OnDeathExplosive(inst)
    inst.components.combat:DoAreaAttack(inst, TUNING.MUTANT_BEE_EXPLOSIVE_RANGE, nil, nil, nil, { "INLIMBO", "mutant" })
    SpawnPrefab("explode_small").Transform:SetPosition(inst.Transform:GetWorldPosition())    
    inst:Remove()
end

local rangedworkerbrain = require("brains/rangedbeebrain")
local rangedkillerbrain = require("brains/rangedkillerbeebrain")

local function OnSuicidalAttack(inst, data)    
    if data.projectile then
        local delta = -inst.components.health.maxhealth * TUNING.MUTANT_BEE_RANGED_ATK_HEALTH_PENALTY
        inst.components.health:DoDelta(delta, nil, "suicidal_attack", nil, nil, true)
    end
end

local function RangedRetarget(inst)
    return FindTarget(inst, TUNING.MUTANT_BEE_RANGED_TARGET_DIST)
end

local function MakeRangedWeapon(inst)
    if not inst.components.inventory then
        inst:AddComponent("inventory")        
    end

    inst.components.combat:SetRange(TUNING.MUTANT_BEE_WEAPON_ATK_RANGE)
    inst.components.combat:SetAttackPeriod(TUNING.MUTANT_BEE_RANGED_ATK_PERIOD)
    inst.components.combat:SetDefaultDamage(TUNING.MUTANT_BEE_RANGED_DAMAGE)
    inst.components.combat:SetRetargetFunction(0.25, RangedRetarget)

    if not inst.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS) then
        local weapon = CreateEntity()
        weapon.entity:AddTransform()
        MakeInventoryPhysics(weapon)
        weapon:AddComponent("weapon")
        weapon.components.weapon:SetDamage(inst.components.combat.defaultdamage)
        weapon.components.weapon:SetRange(inst.components.combat.attackrange)
        weapon.components.weapon:SetProjectile("blowdart_walrus")
        weapon:AddComponent("inventoryitem")
        weapon.persists = false
        weapon.components.inventoryitem:SetOnDroppedFn(weapon.Remove)
        weapon:AddComponent("equippable")
        inst.weapon = weapon
        inst.components.inventory:Equip(inst.weapon)
    end
    
    inst:ListenForEvent("onattackother", OnSuicidalAttack)

    if inst:HasTag("worker") then
        inst:SetBrain(rangedworkerbrain)
    else
        inst:SetBrain(rangedkillerbrain)
    end
end

local function OnAttackOtherWithFrostbite(inst, data)
    if data.target and data.target.components.locomotor 
        and data.target.components.health and not data.target.components.health:IsDead() then
        if not data.target:HasTag("player") then
            data.target._frostbite_expire = GetTime() + 4.75
            data.target.AnimState:SetAddColour(82 / 255, 115 / 255, 124 / 255, 0)
            if data.target.components.combat then
                if not data.target._currentattackperiod then
                    data.target._currentattackperiod = data.target.components.combat.min_attack_period
                    data.target.components.combat:SetAttackPeriod(data.target._currentattackperiod * TUNING.MUTANT_BEE_FROSTBITE_ATK_PERIOD_PENALTY)
                end
            end

            if data.target.components.locomotor.enablegroundspeedmultiplier then
                data.target.components.locomotor:SetExternalSpeedMultiplier(data.target, "frostbite", TUNING.MUTANT_BEE_FROSTBITE_SPEED_PENALTY)
                data.target:DoTaskInTime(5.0,
                    function (inst)
                        if GetTime() >= inst._frostbite_expire then
                            inst.AnimState:SetAddColour(0, 0, 0, 0)
                            inst.components.locomotor:RemoveExternalSpeedMultiplier(inst, "frostbite")
                            if inst.components.combat and inst._currentattackperiod then
                                inst.components.combat:SetAttackPeriod(inst._currentattackperiod)
                                inst._currentattackperiod = nil
                            end
                        end
                    end)
            else
                if not data.target._currentspeed then
                    data.target._currentspeed = data.target.components.locomotor.groundspeedmultiplier
                end
                data.target.components.locomotor.groundspeedmultiplier = TUNING.MUTANT_BEE_FROSTBITE_SPEED_PENALTY
                data.target:DoTaskInTime(5.0,
                    function (inst)
                        if GetTime() >= inst._frostbite_expire then
                            inst.AnimState:SetAddColour(0, 0, 0, 0)
                            if inst._currentspeed then
                                inst.components.locomotor.groundspeedmultiplier = inst._currentspeed
                                inst._currentspeed = nil
                            end
                            if inst.components.combat and inst._currentattackperiod then
                                inst.components.combat:SetAttackPeriod(inst._currentattackperiod)
                                inst._currentattackperiod = nil
                            end
                        end
                    end)
            end
        end
    end        
end
-- Mutant effects */

local function OnWorked(inst, worker)
    inst:PushEvent("detachchild")
    if worker.components.inventory ~= nil then
        inst.SoundEmitter:KillAllSounds()

        worker.components.inventory:GiveItem(inst, nil, inst:GetPosition())
    end
end

local function OnDropped(inst)
    if inst.buzzing and not inst:IsAsleep() then
        inst.SoundEmitter:PlaySound(inst.sounds.buzz, "buzz")
    end
    inst.sg:GoToState("catchbreath")
    if inst.components.workable ~= nil then
        inst.components.workable:SetWorkLeft(1)
    end
    if inst.brain ~= nil then
        inst.brain:Start()
    end
    if inst.sg ~= nil then
        inst.sg:Start()
    end
    if inst.components.stackable ~= nil and inst.components.stackable:IsStack() then
        local x, y, z = inst.Transform:GetWorldPosition()
        while inst.components.stackable:IsStack() do
            local item = inst.components.stackable:Get()
            if item ~= nil then
                if item.components.inventoryitem ~= nil then
                    item.components.inventoryitem:OnDropped()
                end
                item.Physics:Teleport(x, y, z)
            end
        end
    end
end

local function OnPickedUp(inst)
    inst.sg:GoToState("idle")
    inst.SoundEmitter:KillSound("buzz")
    inst.SoundEmitter:KillAllSounds()
end

local function EnableBuzz(inst, enable)
    if enable then
        if not inst.buzzing then
            inst.buzzing = true
            if not ((inst.components.inventoryitem and inst.components.inventoryitem:IsHeld()) 
                or inst:IsAsleep()) then
                inst.SoundEmitter:PlaySound(inst.sounds.buzz, "buzz")
            end
        end
    elseif inst.buzzing then
        inst.buzzing = false
        inst.SoundEmitter:KillSound("buzz")
    end
end

local function OnWake(inst)
    if inst.buzzing and 
        not (inst.components.inventoryitem and inst.components.inventoryitem:IsHeld()) then
        inst.SoundEmitter:PlaySound(inst.sounds.buzz, "buzz")
    end
end

local function OnSleep(inst)
    inst.SoundEmitter:KillSound("buzz")
end

local function KillerRetarget(inst)
    return FindTarget(inst, TUNING.MUTANT_BEE_TARGET_DIST)
end

local function MutantBeeRetarget(inst)
    return FindTarget(inst, TUNING.MUTANT_BEE_TARGET_DIST)
end

local function ChangeMutantOnSeason(inst)
    if TheWorld.state.isspring then
        inst.components.locomotor.groundspeedmultiplier = 1.3
        inst:ListenForEvent("onattackother", OnAttackOtherWithPoison)
    elseif TheWorld.state.issummer then
        inst.components.health:SetMaxHealth(TUNING.MUTANT_BEE_HEALTH / 2)
        inst.components.combat.areahitdamagepercent = TUNING.MUTANT_BEE_EXPLOSIVE_DAMAGE_MULTIPLIER
        inst:ListenForEvent("death", OnDeathExplosive)        
    elseif TheWorld.state.isautumn then
        MakeRangedWeapon(inst)
    else
        inst.components.locomotor.groundspeedmultiplier = 0.7
        inst.components.combat:SetAttackPeriod(TUNING.MUTANT_BEE_ATTACK_PERIOD * 2)
        inst:ListenForEvent("onattackother", OnAttackOtherWithFrostbite)
    end
end

local function GetBuildConfig()
    local actualname = KnownModIndex:GetModActualName("Ozzy The Buzzy")
    local usenewbuild = GetModConfigData("USE_NEW_BEE_BUILD", actualname)

    return usenewbuild
end

local function commonfn(build, tags)
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddLightWatcher()
    inst.entity:AddDynamicShadow()
    inst.entity:AddNetwork()

    MakeFlyingCharacterPhysics(inst, 1, .5)

    inst.DynamicShadow:SetSize(.8, .5)
    inst.Transform:SetFourFaced()
    
    inst:AddTag("insect")
    inst:AddTag("smallcreature")
    inst:AddTag("cattoyairborne")
    inst:AddTag("flying")
    inst:AddTag("mutant")

    for i, v in ipairs(tags) do
        inst:AddTag(v)
    end

    inst.AnimState:SetBank("bee")
    inst.AnimState:SetBuild(build)
    inst.AnimState:PlayAnimation("idle", true)
    inst.AnimState:SetRayTestOnBB(true)

    MakeFeedableSmallLivestockPristine(inst)

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("locomotor") -- locomotor must be constructed before the stategraph
    inst.components.locomotor:EnableGroundSpeedMultiplier(false)
    inst.components.locomotor:SetTriggersCreep(false)
    inst:SetStateGraph("SGbee")

    ---------------------

    inst:AddComponent("lootdropper")
    inst.components.lootdropper:AddRandomLoot("honey", 1)
    inst.components.lootdropper:AddRandomLoot("stinger", 2)   
    inst.components.lootdropper.numrandomloot = 1
    inst.components.lootdropper.chancerandomloot = 0.2 -- reduce number of loots

    ------------------

    MakeSmallBurnableCharacter(inst, "body", Vector3(0, -1, 1))
    MakeTinyFreezableCharacter(inst, "body", Vector3(0, -1, 1))

    ------------------

    inst:AddComponent("health")
    inst:AddComponent("combat")
    inst.components.combat:SetRange(TUNING.BEE_ATTACK_RANGE)
    inst.components.combat.hiteffectsymbol = "body"
    inst.components.combat:SetPlayerStunlock(PLAYERSTUNLOCK.RARELY)    

    ------------------

    inst:AddComponent("sleeper")
    ------------------

    inst:AddComponent("knownlocations")

    ------------------

    inst:AddComponent("inspectable")

    ------------------

    inst:ListenForEvent("attacked", beecommon.OnAttacked)    
    inst.Transform:SetScale(1.2, 1.2, 1.2)

    local usenewbuild = GetBuildConfig()
    if not usenewbuild then
        inst.AnimState:SetMultColour(0.7, 0.7, 0.7, 1)
    end

    inst.buzzing = true
    inst.EnableBuzz = EnableBuzz
    inst.OnEntityWake = OnWake
    inst.OnEntitySleep = OnSleep

    return inst
end

local workerbrain = require("brains/mutantbeebrain")
local killerbrain = require("brains/mutantkillerbeebrain")

local function workerbee()
    --pollinator (from pollinator component) added to pristine state for optimization
    --for searching: inst:AddTag("pollinator")
    local usenewbuild = GetBuildConfig()
    local inst = nil

    if usenewbuild then
        inst = commonfn("mutantbee_build", { "worker", "pollinator" })
    else
        inst = commonfn("bee_build", { "worker", "pollinator" })
    end

    if not TheWorld.ismastersim then
        return inst
    end    

    inst.components.health:SetMaxHealth(TUNING.MUTANT_BEE_HEALTH)
    inst.components.combat:SetDefaultDamage(TUNING.MUTANT_BEE_DAMAGE)
    inst.components.combat:SetAttackPeriod(TUNING.MUTANT_BEE_ATTACK_PERIOD)
    inst.components.combat:SetRetargetFunction(2, MutantBeeRetarget)
    inst:AddComponent("pollinator")
    inst:SetBrain(workerbrain)
    inst.sounds = workersounds

    MakeHauntableChangePrefab(inst, "mutantkillerbee")

    inst:DoTaskInTime(0, ChangeMutantOnSeason)

    return inst
end

local function OnSpawnedFromHaunt(inst)
    if inst.components.hauntable ~= nil then
        inst.components.hauntable:Panic()
    end
end

local function killerbee()
    local usenewbuild = GetBuildConfig()
    local inst = nil

    if usenewbuild then
        inst = commonfn("mutantbee_angry_build", { "killer", "scarytoprey" })
    else
        inst = commonfn("bee_angry_build", { "killer", "scarytoprey" })
    end

    if not TheWorld.ismastersim then
        return inst
    end    

    inst.components.health:SetMaxHealth(TUNING.MUTANT_BEE_HEALTH)
    inst.components.combat:SetDefaultDamage(TUNING.MUTANT_BEE_DAMAGE)
    inst.components.combat:SetAttackPeriod(TUNING.MUTANT_BEE_ATTACK_PERIOD)
    inst.components.combat:SetRetargetFunction(1, KillerRetarget)
    inst:SetBrain(killerbrain)
    inst.sounds = killersounds

    MakeHauntablePanic(inst)
    inst:ListenForEvent("spawnedfromhaunt", OnSpawnedFromHaunt)

    inst:DoTaskInTime(0, ChangeMutantOnSeason)

    return inst
end

STRINGS.MUTANTBEE = "Mutant Bee"
STRINGS.NAMES.MUTANTBEE = "Mutant Bee"
STRINGS.CHARACTERS.GENERIC.DESCRIBE.MUTANTBEE = "That bee looks weird..."

STRINGS.MUTANTKILLERBEE = "Mutant Killer Bee"
STRINGS.NAMES.MUTANTKILLERBEE = "Mutant Killer Bee"
STRINGS.CHARACTERS.GENERIC.DESCRIBE.MUTANTKILLERBEE = "Is it really OK to come near them ?"

return Prefab("mutantbee", workerbee, assets, prefabs),
        Prefab("mutantkillerbee", killerbee, assets, prefabs)
