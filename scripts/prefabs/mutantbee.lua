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
    Asset("SOUND", "sound/bee.fsb"),
}

local prefabs =
{
    "stinger",
    "honey",
    "explosive_small",
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

-- /* Mutant effects
local function DoPoisonDamage(inst)
    if inst._poisonticks <= 0 or inst.components.health:IsDead() then
        inst._poisontask:Cancel()
        inst._poisontask = nil
        return
    end

    inst.components.health:DoDelta(TUNING.MUTANT_BEE_POISON_DAMAGE, true, "poison_sting")  
    inst.AnimState:SetMultColour(0.8, 0.2, 0.8, 1)
    inst:DoTaskInTime(0.2, function(inst)
            inst.AnimState:SetMultColour(1, 1, 1, 1)       
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

local function OnBurtnExplosive(inst)
    inst.components.combat:DoAreaAttack(inst, TUNING.MUTANT_BEE_EXPLOSIVE_RANGE, nil, nil, nil, { "INLIMBO", "mutant" })
    SpawnPrefab("explode_small").Transform:SetPosition(inst.Transform:GetWorldPosition())    
end

local function OnAttackOtherWithFrostbite(inst, data)
    if data.target and data.target.components.locomotor and not data.target.components.health:IsDead() then
        if not data.target:HasTag("player") then
            data.target._frostbite_expire = GetTime() + 4.5
            data.target.AnimState:SetAddColour(82 / 255, 115 / 255, 124 / 255, 0)
            local x, y, z = data.target.Transform:GetWorldPosition()
            local ground = TheWorld.Map:GetTileAtPoint(x, 0, z)

            if data.target.components.locomotor.enablegroundspeedmultiplier then
                if not data.target._frostbite_task then
                    data.target._frostbite_task = data.target:DoPeriodicTask(0, 
                        function (inst)                                           
                            inst.components.locomotor:PushTempGroundSpeedMultiplier(TUNING.MUTANT_BEE_FROSTBITE_SPEED_PENALTY, ground)
                        end)
                end
                data.target:DoTaskInTime(5.0,
                    function (inst)
                        if GetTime() >= inst._frostbite_expire then
                            inst.AnimState:SetAddColour(0, 0, 0, 0)
                            inst._frostbite_task:Cancel()   
                            inst._frostbite_task = nil                         
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
                            inst.components.locomotor.groundspeedmultiplier = inst._currentspeed
                            inst._currentspeed = nil
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

local function KillerRetarget(inst)
    return FindTarget(inst, TUNING.MUTANT_BEE_TARGET_DIST)
end

local function MutantBeeRetarget(inst)
    return FindTarget(inst, TUNING.MUTANT_BEE_TARGET_DIST / 2)
end

local function ChangeMutantOnSeason(inst)
    if TheWorld.state.isspring then
        inst:ListenForEvent("onattackother", OnAttackOtherWithPoison)
    elseif TheWorld.state.issummer then
        inst.components.health:SetMaxHealth(TUNING.MUTANT_BEE_HEALTH / 2)
        inst.components.combat.areahitdamagepercent = TUNING.MUTANT_BEE_EXPLOSIVE_DAMAGE_MULTIPLIER
        inst:ListenForEvent("death", OnDeathExplosive)
        inst:ListenForEvent("onburnt", OnBurtnExplosive)
    elseif TheWorld.state.isautumn then
        print("AUTUMN")
    else
        inst.components.locomotor.groundspeedmultiplier = 0.6
        inst.components.combat:SetAttackPeriod(TUNING.MUTANT_BEE_ATTACK_PERIOD * 2)
        inst:ListenForEvent("onattackother", OnAttackOtherWithFrostbite)
    end
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

    -- inst:AddComponent("stackable")
    -- inst:AddComponent("inventoryitem")
    -- inst.components.inventoryitem.nobounce = true
    -- inst.components.inventoryitem:SetOnDroppedFn(OnDropped) Done in MakeFeedableSmallLivestock
    -- inst.components.inventoryitem:SetOnPutInInventoryFn(OnPickedUp)
    -- inst.components.inventoryitem.canbepickedup = false
    -- inst.components.inventoryitem.canbepickedupalive = true

    ---------------------

    inst:AddComponent("lootdropper")
    inst.components.lootdropper:AddRandomLoot("honey", 1)
    inst.components.lootdropper:AddRandomLoot("stinger", 5)   
    inst.components.lootdropper.numrandomloot = 1

    ------------------
    -- inst:AddComponent("workable")
    -- inst.components.workable:SetWorkAction(ACTIONS.NET)
    -- inst.components.workable:SetWorkLeft(1)
    -- inst.components.workable:SetOnFinishCallback(OnWorked)

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

    -- inst:AddComponent("tradable")    
    -- inst:ListenForEvent("worked", beecommon.OnWorked)
    -- MakeFeedableSmallLivestock(inst, TUNING.TOTAL_DAY_TIME * 2, OnPickedUp, OnDropped)

    inst:ListenForEvent("attacked", beecommon.OnAttacked)    
    inst.Transform:SetScale(1.2, 1.2, 1.2)
    inst.AnimState:SetMultColour(0.7, 0.7, 0.7, 1)    

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
    local inst = commonfn("bee_build", { "worker", "pollinator" })

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

    ChangeMutantOnSeason(inst)

    return inst
end

local function OnSpawnedFromHaunt(inst)
    if inst.components.hauntable ~= nil then
        inst.components.hauntable:Panic()
    end
end

local function killerbee()
    local inst = commonfn("bee_angry_build", { "killer", "scarytoprey" })

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

    ChangeMutantOnSeason(inst)

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
