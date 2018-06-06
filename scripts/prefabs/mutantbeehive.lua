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

local function Shake(inst, ignore_frozen)
    if ignore_frozen or not (inst.components.freezable and inst.components.freezable:IsFrozen()) then
        inst.SoundEmitter:PlaySound("dontstarve/bee/beehive_hit")
        inst.AnimState:PlayAnimation("cocoon_small_hit")
        inst.AnimState:PushAnimation("cocoon_small", true)
    end
end

local function UnlinkPlayer(inst)
    local owner = inst._owner
    inst._ownerid = nil
    inst._owner = nil
    if owner ~= nil then
        owner._hive = nil
    end
end

local function OnRemoveEntity(inst)
    RemoveFX(inst)
    UnlinkPlayer(inst)
    inst:RemoveEventCallback("ms_playerjoined", inst._onplayerjoined, TheWorld)

    if inst.components.childspawner then
        for k, v in pairs(inst.components.childspawner.childrenoutside) do
            if v then
                v:Remove()
            end
        end
        for k, v in pairs(inst.components.childspawner.emergencychildrenoutside) do
            if v then
                v:Remove()
            end
        end
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

local function OnIsCaveDay(inst, isday)
    if not isday then
        StopSpawning(inst)
    elseif inst.LightWatcher:IsInLight() then
        StartSpawning(inst)
    end
end

local function OnEnterLight(inst)
    if TheWorld.state.iscaveday then
        StartSpawning(inst)
    end
end

local function OnEnterDark(inst)
    StopSpawning(inst)
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

local function SpawnCocoon(inst)
    local cocoon = SpawnPrefab("mutantbeecocoon")
    local owner = inst._owner
    UnlinkPlayer(inst)
    cocoon:LinkToPlayer(owner)
    cocoon.Transform:SetPosition(inst.Transform:GetWorldPosition())
end

local function OnKilled(inst)
    inst:RemoveComponent("childspawner")
    inst.AnimState:PlayAnimation("cocoon_dead", true)
    RemovePhysicsColliders(inst)

    inst.SoundEmitter:KillSound("loop")

    inst.SoundEmitter:PlaySound("dontstarve/bee/beehive_destroy")
    inst.components.lootdropper:DropLoot(inst:GetPosition())
    SpawnCocoon(inst)

    RemoveFX(inst)
end

local function OnHammered(inst, worker)
    inst:RemoveComponent("childspawner")
    inst.SoundEmitter:KillSound("loop")
    inst.SoundEmitter:PlaySound("dontstarve/bee/beehive_destroy")
    inst.components.lootdropper:DropLoot(inst:GetPosition())
    SpawnCocoon(inst)
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
    SpawnCocoon(inst)
end

local function OnHit(inst, attacker, damage)    
    if inst.components.childspawner ~= nil and not attacker:HasTag("beemaster") then
        inst.components.childspawner:ReleaseAllChildren(attacker, "mutantkillerbee")
    end
    if not inst.components.health:IsDead() then        
        Shake(inst)
    end
end

-- /* Upgrade and Grow
local function MakeSetStageFn(stage)
    return function(inst)
        if stage > 1 then
            Shake(inst)
        end

        local scale = UPGRADE_STAGES[stage].SIZE_SCALE
        inst.Transform:SetScale(scale, scale, scale)
        inst.components.health:SetMaxHealth(UPGRADE_STAGES[stage].HEALTH)

        inst.components.childspawner:SetRegenPeriod(TUNING.MUTANT_BEEHIVE_DEFAULT_REGEN_TIME - (stage - 1) * TUNING.MUTANT_BEEHIVE_DELTA_REGEN_TIME)
        inst.components.childspawner:SetSpawnPeriod(TUNING.MUTANT_BEEHIVE_DEFAULT_RELEASE_TIME - (stage - 1) * TUNING.MUTANT_BEEHIVE_DELTA_RELEASE_TIME)
        inst.components.childspawner:SetMaxChildren(TUNING.MUTANT_BEEHIVE_DEFAULT_BEES + stage * TUNING.MUTANT_BEEHIVE_DELTA_BEES)

        SetFX(inst)
        inst.components.upgradeable:SetStage(stage)

        local loots = {}
        local numhoneycombs = math.floor(TUNING.MUTANT_BEEHIVE_UPGRADES_PER_STAGE * (stage - 1) / 2)
        for i = 1, numhoneycombs do
            table.insert(loots, "honeycomb")
        end    

        inst.components.lootdropper:SetLoot(loots)
    end
end

local function OnUpgrade(inst)
    Shake(inst)
end

local function OnStageAdvance(inst)
    inst.components.growable:DoGrowth()
    return true
end

local function GetGrowTime(inst, stage)
    return TUNING.MUTANT_BEEHIVE_GROW_TIME[stage] * (1 + math.random())
end

local growth_stages =
{
    { name = "small", time = GetGrowTime, fn = MakeSetStageFn(1) },
    { name = "med", time = GetGrowTime, fn = MakeSetStageFn(2) },
    { name = "large", fn = MakeSetStageFn(3) },
}

-- Upgrade and Grow */

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

local function SelfRepair(inst)
    if inst and inst.components.childspawner and inst.components.health then
        if not inst.components.health:IsDead() then
            local numfixers = inst.components.childspawner.childreninside + inst.components.childspawner.emergencychildreninside
            local recover = TUNING.MUTANT_BEEHIVE_RECOVER_PER_CHILD * numfixers
            inst.components.health:DoDelta(recover, true, "self_repair")
        end
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

local function IsValidOwner(inst, owner)
    if not owner then
        return false
    end

    if inst._ownerid then
        return owner.userid and owner.userid == inst._ownerid
            and owner:HasTag("beemaster") and not owner._cocoon
            and not (owner._hive and owner._hive ~= inst)
    else
        return owner.userid and owner:HasTag("beemaster") and not owner._cocoon
            and not (owner._hive and owner._hive ~= inst)
    end
end

local function LinkToPlayer(inst, player)
    if IsValidOwner(inst, player) then
        inst._ownerid = player.userid
        inst._owner = player
        player._hive = inst
        return true
    end

    return false
end

local function CalcSanityAura(inst, observer)    
    if inst._ownerid and IsValidOwner(inst, observer) then
        return TUNING.SANITYAURA_SMALL_TINY
    end

    return 0
end

local function OnSave(inst, data)
    if inst._ownerid then
        data._ownerid = inst._ownerid
    end
end

local function OnPlayerJoined(inst, player)
    print("PLAYER JOINED HIVE", player)
    local linksuccess = LinkToPlayer(inst, player)
    if not linksuccess then
        if inst._ownerid and player.userid and player.userid == inst._ownerid then
            print("SAME PLAYER, DIFFERENT CHARACTER")
            inst:DoTaskInTime(0, function(inst) inst:Remove() end)
        end
    end
end

local function OnLoad(inst, data)
    if data and data._ownerid then
        inst._ownerid = data._ownerid        
    end    
end

local function OnInit(inst)
    inst:WatchWorldState("iscaveday", OnIsCaveDay)
    inst:ListenForEvent("enterlight", OnEnterLight)
    inst:ListenForEvent("enterdark", OnEnterDark)    
    if TheWorld.state.isday then
        StartSpawning(inst)
    end 

    inst.components.growable:SetStage(inst.components.upgradeable.stage)    
    
    inst:DoPeriodicTask(3, SelfRepair)
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddMiniMapEntity()
    inst.entity:AddNetwork()
    inst.entity:AddLightWatcher()

    MakeObstaclePhysics(inst, .5)

    inst.MiniMapEntity:SetIcon("beehive.png")

    inst.AnimState:SetBank("beehive")
    inst.AnimState:SetBuild("beehive")
    inst.AnimState:PlayAnimation("cocoon_small", true)
    inst.AnimState:SetMultColour(0.7, 0.5, 0.7, 1)

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

    inst:AddComponent("growable")
    inst.components.growable.springgrowth = true
    inst.components.growable.stages = growth_stages    
    inst.components.growable:StartGrowing()

    ---------------------
    inst:AddComponent("workable")
    inst.components.workable:SetWorkAction(ACTIONS.HAMMER)
    inst.components.workable:SetWorkLeft(5)
    inst.components.workable:SetOnFinishCallback(OnHammered)
    inst.components.workable:SetOnWorkCallback(OnHit)

    ---------------------
    inst:AddComponent("lootdropper")    

    ---------------------
    inst:AddComponent("sanityaura")
    inst.components.sanityaura.aurafn = CalcSanityAura
    
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
    inst.OnSave = OnSave
    inst.OnLoad = OnLoad
    inst.OnRemoveEntity = OnRemoveEntity
    inst.LinkToPlayer = LinkToPlayer
    inst._onplayerjoined = function(src, player) OnPlayerJoined(inst, player) end
    inst:ListenForEvent("ms_playerjoined", inst._onplayerjoined, TheWorld)

    return inst
end

STRINGS.MUTANTBEEHIVE = "Mutant Beehive"
STRINGS.NAMES.MUTANTBEEHIVE = "Mutant Beehive"
STRINGS.CHARACTERS.GENERIC.DESCRIBE.MUTANTBEEHIVE = "They will protect us."

return Prefab("mutantbeehive", fn, assets, prefabs)
