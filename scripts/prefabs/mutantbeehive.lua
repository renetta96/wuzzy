local prefabs =
{
    "mutantbee",
    "mutantkillerbee",
    "honey",
    "honeycomb",
    "honeyspill",
    "mutantbeecocoon",
    "collapse_big",
    "collapse_small"
}

local assets =
{
    Asset("ANIM", "anim/beehive.zip"),
    Asset("SOUND", "sound/bee.fsb"),
}

local UPGRADE_STAGES = {
    [1] = {
        SIZE_SCALE = 1.0,
        HEALTH = 700
    },
    [2] = {
        SIZE_SCALE = 1.35,
        HEALTH = 1100
    },
    [3] = {
        SIZE_SCALE = 1.7,
        HEALTH = 1500
    }
}

local function SetFX(inst)
    local stage = inst.components.upgradeable.stage
    if not inst._honeyspill then
        local fx = SpawnPrefab("honeyspill")
        fx.Transform:SetPosition(inst.Transform:GetWorldPosition())
        fx:SetVariation(7, 1.0 + 0.25 * (stage - 1))
        inst._honeyspill = fx
    else
        inst._honeyspill:SetVariation(7, 1.0 + 0.25 * (stage - 1))
    end
end

local function RemoveFX(inst)
    if inst._honeyspill then
        inst._honeyspill:Remove()
    end
end

local function OnEntityWake(inst)
    inst.SoundEmitter:PlaySound("dontstarve/bee/bee_hive_LP", "loop")
end

local function OnEntitySleep(inst)
    inst.SoundEmitter:KillSound("loop")
end

local function StartSpawning(inst)
    if inst.components.childspawner ~= nil        
        and not (inst.components.freezable ~= nil and inst.components.freezable:IsFrozen()) then
        inst.components.childspawner:StartSpawning()
    end
end

local function StopSpawning(inst)
    if inst.components.childspawner ~= nil then
        inst.components.childspawner:StopSpawning()
    end
end

local function OnIsDay(inst, isday)
    if isday then
        StartSpawning(inst)
    else
        StopSpawning(inst)
    end
end

local function OnIgnite(inst)
    if inst.components.childspawner ~= nil then
        inst.components.childspawner:ReleaseAllChildren()
    end
    inst.SoundEmitter:KillSound("loop")
    DefaultBurnFn(inst)
end

local function OnFreeze(inst)
    inst.SoundEmitter:PlaySound("dontstarve/common/freezecreature")
    inst.AnimState:PlayAnimation("frozen", true)
    inst.AnimState:OverrideSymbol("swap_frozen", "frozen", "frozen")

    StopSpawning(inst)
end

local function OnThaw(inst)
    inst.AnimState:PlayAnimation("frozen_loop_pst", true)
    inst.SoundEmitter:PlaySound("dontstarve/common/freezethaw", "thawing")
    inst.AnimState:OverrideSymbol("swap_frozen", "frozen", "frozen")
end

local function OnUnFreeze(inst)
    inst.AnimState:PlayAnimation("cocoon_small", true)
    inst.SoundEmitter:KillSound("thawing")
    inst.AnimState:ClearOverrideSymbol("swap_frozen")

    StartSpawning(inst)
end

local function OnKilled(inst)
    inst:RemoveComponent("childspawner")
    inst.AnimState:PlayAnimation("cocoon_dead", true)
    RemovePhysicsColliders(inst)

    inst.SoundEmitter:KillSound("loop")

    inst.SoundEmitter:PlaySound("dontstarve/bee/beehive_destroy")
    inst.components.lootdropper:DropLoot(inst:GetPosition())

    RemoveFX(inst)
end

local function OnHammered(inst, worker)
    inst:RemoveComponent("childspawner")
    inst.SoundEmitter:KillSound("loop")
    inst.SoundEmitter:PlaySound("dontstarve/bee/beehive_destroy")
    inst.components.lootdropper:DropLoot(inst:GetPosition())
    RemoveFX(inst)

    local collapse = inst.components.upgradeable.stage >= 2 and "collapse_big" or "collapse_small"
    local fx = SpawnPrefab(collapse)
    fx.Transform:SetPosition(inst.Transform:GetWorldPosition())
    fx:SetMaterial("straw")

    inst:Remove()
end

local function OnBurnt(inst)
    RemoveFX(inst)

    -- To make sure a cocoon is still spawned after the hive is burnt
    local cocoon = SpawnPrefab("mutantbeecocoon")
    cocoon.Transform:SetPosition(inst.Transform:GetWorldPosition())
end

local function OnHit(inst, attacker, damage)    
    if inst.components.childspawner ~= nil and not attacker:HasTag("beemaster") then
        inst.components.childspawner:ReleaseAllChildren(attacker, "mutantkillerbee")
    end
    if not inst.components.health:IsDead() then
        inst.SoundEmitter:PlaySound("dontstarve/bee/beehive_hit")
        inst.AnimState:PlayAnimation("cocoon_small_hit")
        inst.AnimState:PushAnimation("cocoon_small", true)
    end
end

local function OnUpgrade(inst)
    inst.SoundEmitter:PlaySound("dontstarve/bee/beehive_hit")
    inst.AnimState:PlayAnimation("cocoon_small_hit")
    inst.AnimState:PushAnimation("cocoon_small", true)
end

local function OnUpgradeStage(inst)
    local stage = inst.components.upgradeable.stage
    local scale = UPGRADE_STAGES[stage].SIZE_SCALE
    inst.Transform:SetScale(scale, scale, scale)
    inst.components.health:SetMaxHealth(UPGRADE_STAGES[stage].HEALTH)

    inst.components.childspawner:SetRegenPeriod(TUNING.MUTANT_BEEHIVE_DEFAULT_REGEN_TIME - (stage - 1) * TUNING.MUTANT_BEEHIVE_DELTA_REGEN_TIME)
    inst.components.childspawner:SetSpawnPeriod(TUNING.MUTANT_BEEHIVE_DEFAULT_RELEASE_TIME - (stage - 1) * TUNING.MUTANT_BEEHIVE_DELTA_RELEASE_TIME)
    inst.components.childspawner:SetMaxChildren(TUNING.MUTANT_BEEHIVE_DEFAULT_BEES + stage * TUNING.MUTANT_BEEHIVE_DELTA_BEES)

    SetFX(inst)
end

local function OnStageAdvance(inst)
    OnUpgradeStage(inst)
    return true
end

local function WatchEnemy(inst)
    local enemy = FindEntity(inst, TUNING.MUTANT_BEEHIVE_WATCH_DIST,
            function(guy)
                return inst.components.combat:CanTarget(guy)
            end,
            { "_combat", "_health" },
            { "insect", "INLIMBO" },
            { "monster" })
            or FindEntity(inst, TUNING.MUTANT_BEEHIVE_WATCH_DIST, 
                function(guy)
                    return inst.components.combat:CanTarget(guy)
                        and guy.components.combat and guy.components.combat.target
                        and guy.components.combat.target:HasTag("player")                        
                end, 
                { "_combat", "_health" },
                { "mutant", "INLIMBO" },
                { "monster", "insect", "animal", "character" })            
    if enemy then
        OnHit(inst, enemy)
    end
end

local function SeasonalSpawnChanges(inst, season)
    if inst.components.childspawner ~= nil then
        if season == SEASONS.SPRING then
            inst.components.childspawner:SetRegenPeriod(TUNING.BEEBOX_REGEN_TIME / TUNING.SPRING_COMBAT_MOD)
            inst.components.childspawner:SetSpawnPeriod(TUNING.BEEBOX_RELEASE_TIME / TUNING.SPRING_COMBAT_MOD)
            inst.components.childspawner:SetMaxChildren(TUNING.BEEBOX_BEES * TUNING.SPRING_COMBAT_MOD)
        else
            inst.components.childspawner:SetRegenPeriod(TUNING.BEEBOX_REGEN_TIME)
            inst.components.childspawner:SetSpawnPeriod(TUNING.BEEBOX_RELEASE_TIME)
            inst.components.childspawner:SetMaxChildren(TUNING.BEEBOX_BEES)
        end
    end
end

local function OnHaunt(inst)
    if inst.components.childspawner == nil or
        not inst.components.childspawner:CanSpawn() or
        math.random() > TUNING.HAUNT_CHANCE_HALF then
        return false
    end

    local target = FindEntity(
        inst,
        25,
        function(guy)
            return inst.components.combat:CanTarget(guy)
        end,
        { "_combat" }, --See entityreplica.lua (re: "_combat" tag)
        { "insect", "playerghost", "INLIMBO" },
        { "character", "animal", "monster" }
    )

    if target ~= nil then
        OnHit(inst, target)
        return true
    end
    return false
end

local function OnInit(inst)
    inst:WatchWorldState("isday", OnIsDay)
    OnIsDay(inst, TheWorld.state.isday)

    SetFX(inst)

    OnUpgradeStage(inst)

    local loots = {"mutantbeecocoon"}
    local numhoneycombs = TUNING.MUTANT_BEEHIVE_UPGRADES_PER_STAGE * (inst.components.upgradeable.stage - 1)
    for i = 1, numhoneycombs do
        table.insert(loots, "honeycomb")
    end    

    inst.components.lootdropper:SetLoot(loots)
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddMiniMapEntity()
    inst.entity:AddNetwork()

    MakeObstaclePhysics(inst, .5)

    inst.MiniMapEntity:SetIcon("beehive.png")

    inst.AnimState:SetBank("beehive")
    inst.AnimState:SetBuild("beehive")
    inst.AnimState:PlayAnimation("cocoon_small", true)
    inst.AnimState:SetMultColour(0.7, 0.7, 0.7)

    inst:AddTag("structure")    
    inst:AddTag("hive")
    inst:AddTag("beehive")
    inst:AddTag("mutantbeehive")

    MakeSnowCoveredPristine(inst)

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    -------------------
    inst:AddComponent("health")    

    -------------------
    inst:AddComponent("childspawner")
    inst.components.childspawner.childname = "mutantbee"
    -- SeasonalSpawnChanges(inst, TheWorld.state.season)
    -- inst:WatchWorldState("season", SeasonalSpawnChanges)
    inst.components.childspawner.emergencychildname = "mutantkillerbee"
    inst.components.childspawner.emergencychildrenperplayer = TUNING.MUTANT_BEEHIVE_EMERGENCY_BEES_PER_PLAYER
    inst.components.childspawner:SetMaxEmergencyChildren(TUNING.MUTANT_BEEHIVE_EMERGENCY_BEES)
    inst.components.childspawner:SetEmergencyRadius(TUNING.MUTANT_BEEHIVE_EMERGENCY_RADIUS)

    inst:DoTaskInTime(0, OnInit)    

    ---------------------
    MakeLargeBurnable(inst)
    inst.components.burnable:SetOnIgniteFn(OnIgnite)
    ---------------------

    ---------------------
    MakeMediumFreezableCharacter(inst)
    inst:ListenForEvent("freeze", OnFreeze)
    inst:ListenForEvent("onthaw", OnThaw)
    inst:ListenForEvent("unfreeze", OnUnFreeze)
    ---------------------

    inst:AddComponent("combat")
    inst.components.combat:SetOnHit(OnHit)
    inst:ListenForEvent("death", OnKilled)
    inst:ListenForEvent("onburnt", OnBurnt)
    inst:DoPeriodicTask(2, WatchEnemy)
    inst.OnHit = OnHit

    ---------------------

    inst:AddComponent("upgradeable")    
    inst.components.upgradeable.onupgradefn = OnUpgrade
    inst.components.upgradeable.onstageadvancefn = OnStageAdvance
    inst.components.upgradeable.upgradesperstage = TUNING.MUTANT_BEEHIVE_UPGRADES_PER_STAGE    

    ---------------------
    inst:AddComponent("workable")
    inst.components.workable:SetWorkAction(ACTIONS.HAMMER)
    inst.components.workable:SetWorkLeft(5)
    inst.components.workable:SetOnFinishCallback(OnHammered)
    inst.components.workable:SetOnWorkCallback(OnHit)

    ---------------------
    inst:AddComponent("lootdropper")    

    ---------------------
    MakeLargePropagator(inst)
    MakeSnowCovered(inst)

    inst:AddComponent("hauntable")
    inst.components.hauntable:SetHauntValue(TUNING.HAUNT_SMALL)
    inst.components.hauntable:SetOnHauntFn(OnHaunt)

    ---------------------    

    inst:AddComponent("inspectable")
    inst.OnEntitySleep = OnEntitySleep
    inst.OnEntityWake = OnEntityWake    

    return inst
end

STRINGS.MUTANTBEEHIVE = "Mutant Beehive"
STRINGS.NAMES.MUTANTBEEHIVE = "Mutant Beehive"
STRINGS.CHARACTERS.GENERIC.DESCRIBE.MUTANTBEEHIVE = "They will protect us."

return Prefab("mutantbeehive", fn, assets, prefabs)
