local workersounds = {
    takeoff = "dontstarve/bee/bee_takeoff",
    attack = "dontstarve/bee/bee_attack",
    buzz = "dontstarve/bee/bee_fly_LP",
    hit = "dontstarve/bee/bee_hurt",
    death = "dontstarve/bee/bee_death"
}

local killersounds = {
    takeoff = "dontstarve/bee/killerbee_takeoff",
    attack = "dontstarve/bee/killerbee_attack",
    buzz = "dontstarve/bee/killerbee_fly_LP",
    hit = "dontstarve/bee/killerbee_hurt",
    death = "dontstarve/bee/killerbee_death"
}

local function IsHostile(inst)
    -- Webber's spiders
    if inst.components.follower and
        inst.components.follower.leader ~= nil and
        inst.components.follower.leader:HasTag("player")
    then
        return false
    end


    return inst:HasTag("hostile")
end

local function IsAlly(inst)
    return inst and (inst:HasTag("beemaster") or inst:HasTag("beemutant"))
end

local MAX_DIST_FROM_LEADER = 10
local function IsWithinLeaderRange(inst)
    if not inst:IsValid() then
        return false
    end

    if inst.components.follower and inst.components.follower.leader and inst.components.follower.leader:IsValid() then
        return inst:GetDistanceSqToInst(inst.components.follower.leader) < MAX_DIST_FROM_LEADER * MAX_DIST_FROM_LEADER
    end

    return true
end

local TARGET_MUST_TAGS = {"_combat", "_health"}
local TARGET_MUST_ONE_OF_TAGS = {"monster", "insect", "animal", "character"}
local TARGET_IGNORE_TAGS = {"beemutant", "INLIMBO", "player"}

local function FindEnemies(inst, dist)
    local x, y, z = inst.Transform:GetWorldPosition()
    local enemies = TheSim:FindEntities(
        x, y, z,
        dist,
        TARGET_MUST_TAGS,
        TARGET_IGNORE_TAGS,
        TARGET_MUST_ONE_OF_TAGS
    )
    return enemies
end

local function FindTarget(inst, dist)
    if not IsWithinLeaderRange(inst) then
        return nil
    end

    local x, y, z = inst.Transform:GetWorldPosition()
    local enemies = TheSim:FindEntities(
        x, y, z,
        dist,
        TARGET_MUST_TAGS,
        TARGET_IGNORE_TAGS,
        TARGET_MUST_ONE_OF_TAGS
    )

    if #enemies == 0 then
        return nil
    end

    local lowesthealth = math.huge
    local lowestenemy = nil

    for i, guy in ipairs(enemies) do
        if inst.components.combat:CanTarget(guy) and guy.components.combat and
            (IsAlly(guy.components.combat.target) or IsHostile(guy)) then

            if guy.components.health.currenthealth < lowesthealth then
                lowesthealth = guy.components.health.currenthealth
                lowestenemy = guy
            end
        end
    end

    if lowestenemy == nil then
        return nil
    end

    -- 50% force retarget
    return lowestenemy, math.random() <= 0.5
end

local function IsFollowing(inst)
    return inst.components.follower and inst.components.follower.leader ~= nil
end

local function EnableBuzz(inst, enable)
    if enable then
        if IsFollowing(inst) and not inst.components.combat:HasTarget() then
            inst.buzzing = false
            inst.SoundEmitter:KillSound("buzz")
            return
        end

        if not inst.buzzing then
            inst.buzzing = true
            if not inst:IsAsleep() then
                inst.SoundEmitter:PlaySound(inst.sounds.buzz, "buzz")
            end
        end
    elseif inst.buzzing then
        inst.buzzing = false
        inst.SoundEmitter:KillSound("buzz")
    end
end


local function OnNewCombatTarget(inst, data)
    if IsFollowing(inst) then
        EnableBuzz(inst, true)
    end
end

local function OnDroppedTarget(inst, data)
    if IsFollowing(inst) then
        EnableBuzz(inst, false)
    end
end

local function OnStartFollowing(inst)
    EnableBuzz(inst, false)
    inst:ListenForEvent("newcombattarget", OnNewCombatTarget)
    inst:ListenForEvent("droppedtarget", OnDroppedTarget)
end

local function OnStopFollowing(inst)
    EnableBuzz(inst, true)
    inst:RemoveEventCallback("newcombattarget", OnNewCombatTarget)
    inst:RemoveEventCallback("droppedtarget", OnDroppedTarget)
end

local function MakeLessNoise(inst)
    inst:ListenForEvent("startfollowing", OnStartFollowing)
    inst:ListenForEvent("stopfollowing", OnStopFollowing)
end

local function OnWake(inst)
    if inst.buzzing then
        inst.SoundEmitter:PlaySound(inst.sounds.buzz, "buzz")
    end
end

local function OnSleep(inst)
    inst.SoundEmitter:KillSound("buzz")
end

local SLEEP_NEAR_LEADER_DISTANCE = 8
local function ShouldSleep(inst)
    return DefaultSleepTest(inst) and
        (inst.components.follower == nil or inst.components.follower:IsNearLeader(SLEEP_NEAR_LEADER_DISTANCE))
end

local WAKE_TO_FOLLOW_DISTANCE = 15
local function ShouldWakeUp(inst)
    return DefaultWakeTest(inst) or
        (inst.components.follower and not inst.components.follower:IsNearLeader(WAKE_TO_FOLLOW_DISTANCE))
end


local function keeptargetfn(inst, target)
    return IsWithinLeaderRange(inst)
end

local function OnCommonSave(inst, data)
    data.buffed = inst.buffed
end

local function OnCommonLoad(inst, data)
    if data then
        inst.buffed = data.buffed
    end
end

local function OnCommonInit(inst)
    if inst.buffed then
        inst:Buff()
    end
end

local function GetHiveUpgradeStage(inst)
    local hive = nil
    if inst.components.homeseeker and inst.components.homeseeker.home then
        hive = inst.components.homeseeker.home
    elseif inst.components.follower and inst.components.follower.leader and inst.components.follower.leader._hive then
        hive = inst.components.follower.leader._hive
    end

    if hive and hive.prefab == "mutantteleportal" then
        hive = hive:GetSource()
    end

    if not hive or not hive:HasTag("mutantbeehive") or not hive:IsValid() then
        return 0
    end

    inst._numbarracks = hive._numbarracks

    return hive._stage.LEVEL
end

local MAX_TARGET_SHARES = 10
local SHARE_TARGET_DIST = 30
local function OnAttacked(inst, data)
    local attacker = data and data.attacker

    if not attacker then
        return
    end

    inst.components.combat:SetTarget(attacker)

    -- If attacker has tag "beemutant" or "beemaster" then don't share target
    if attacker:HasTag("beemutant") or attacker:HasTag("beemaster") then
        return
    end

    local targetshares = MAX_TARGET_SHARES
    inst.components.combat:ShareTarget(attacker, SHARE_TARGET_DIST, function(dude)
        if inst.components.homeseeker and dude.components.homeseeker then  --don't bring bees from other hives
            if dude.components.homeseeker.home and dude.components.homeseeker.home ~= inst.components.homeseeker.home then
                return false
            end
        end

        if dude.components.follower and dude.components.follower.leader then
            return false
        end

        return dude:HasTag("beemutant") and
            not (dude:IsInLimbo() or (dude.components.health and dude.components.health:IsDead()))
    end, targetshares)
end

local function OnInitUpgrade(inst, checkupgradefn, retries)
    retries = retries + 1

    if retries >= 5 then
        return
    end

    local stage = GetHiveUpgradeStage(inst)
    if stage == 0 then
        inst:DoTaskInTime(
            1,
            function(inst)
                OnInitUpgrade(inst, checkupgradefn, retries)
            end
        )
    end

    local check = checkupgradefn(inst, stage)

    -- Not check upgrade successfully, retry upto 5 times
    if not check then
        inst:DoTaskInTime(
            1,
            function(inst)
                OnInitUpgrade(inst, checkupgradefn, retries)
            end
        )
    end
end

local function TrackLastCombatTime(inst)
    inst._lastcombattime = GetTime()
    inst:ListenForEvent(
        "onattackother",
        function(inst)
            inst._lastcombattime = GetTime()
        end
    )
    inst:ListenForEvent(
        "attacked",
        function(inst)
            inst._lastcombattime = GetTime()
        end
    )
end

local function GetOwner(inst)
    if inst.components.follower and inst.components.follower.leader ~= nil then
        return inst.components.follower.leader
    end

    if inst.components.homeseeker and inst.components.homeseeker.home then
        if inst.components.homeseeker.home._owner then
            return inst.components.homeseeker.home._owner
        end

        return inst.components.homeseeker.home
    end

    return nil
end

local function CommonMasterInit(inst, options, checkupgradefn)
    inst:AddComponent("inspectable")
    inst:AddComponent("knownlocations")

    inst:AddComponent("locomotor") -- locomotor must be constructed before the stategraph
    inst.components.locomotor:EnableGroundSpeedMultiplier(false)
    inst.components.locomotor:SetTriggersCreep(false)

    inst:AddComponent("lootdropper")
    inst.components.lootdropper:AddRandomLoot("honey", 1)
    inst.components.lootdropper:AddRandomLoot("stinger", 4)
    inst.components.lootdropper.numrandomloot = 1
    inst.components.lootdropper.chancerandomloot = 0.5

    if not (options and options.notburnable) then
        MakeSmallBurnableCharacter(inst, "body", Vector3(0, -1, 1))
    end

    if not (options and options.notfreezable) then
        MakeTinyFreezableCharacter(inst, "body", Vector3(0, -1, 1))
    end

    inst:AddComponent("health")
    inst:AddComponent("combat")
    inst.components.combat:SetRange(TUNING.BEE_ATTACK_RANGE)
    inst.components.combat.hiteffectsymbol = "body"
    inst.components.combat:SetPlayerStunlock(PLAYERSTUNLOCK.RARELY)
    inst.components.combat:SetKeepTargetFunction(keeptargetfn)

    if not (options and options.notsleep) then
        inst:AddComponent("sleeper")
        inst.components.sleeper:SetSleepTest(ShouldSleep)
        inst.components.sleeper:SetWakeTest(ShouldWakeUp)
    end

    inst:ListenForEvent("attacked", OnAttacked)
    TrackLastCombatTime(inst)
    MakeLessNoise(inst)

    inst.buzzing = true
    inst.EnableBuzz = EnableBuzz
    inst.OnEntityWake = OnWake
    inst.OnEntitySleep = OnSleep
    inst.OnSave = OnCommonSave
    inst.OnLoad = OnCommonLoad
    inst.Buff = function(inst)
        inst.buffed = true
        if options.buff then
            options.buff(inst)
        end
    end
    inst.GetOwner = GetOwner

    inst:DoTaskInTime(0, OnCommonInit)
    inst:DoTaskInTime(
        0,
        function(inst)
            OnInitUpgrade(inst, checkupgradefn, 0)
        end
    )
end

local function CommonInit(bank, build, tags, options, checkupgradefn)
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddLightWatcher()
    inst.entity:AddDynamicShadow()
    inst.entity:AddNetwork()

    MakeFlyingCharacterPhysics(inst, 1, 0.1)

    inst.DynamicShadow:SetSize(.8, .5)
    inst.Transform:SetFourFaced()

    inst:AddTag("insect")
    inst:AddTag("smallcreature")
    inst:AddTag("cattoyairborne")
    inst:AddTag("flying")
    inst:AddTag("beemutant")
    inst:AddTag("beemutantminion")
    inst:AddTag("companion")

    for i, v in ipairs(tags) do
        inst:AddTag(v)
    end

    inst.AnimState:SetBank(bank)
    inst.AnimState:SetBuild(build)
    inst.AnimState:PlayAnimation("idle", true)
    inst.AnimState:SetRayTestOnBB(true)

    MakeFeedableSmallLivestockPristine(inst)

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    CommonMasterInit(inst, options, checkupgradefn)


    inst:SetStateGraph("SGmutantbee")

    inst.Transform:SetScale(1.2, 1.2, 1.2)

    if options and options.sounds == "killer" then
        inst.sounds = killersounds
    else
        inst.sounds = workersounds
    end

    return inst
end

local function BarrackModifier(inst, v)
    local numbarracks = inst._numbarracks or 0

    return v * (1.0 + TUNING.MUTANT_BEEHIVE_BARRACK_MODIFIER * numbarracks)
end



return {
    CommonInit = CommonInit,
    CommonMasterInit = CommonMasterInit,
    BarrackModifier = BarrackModifier,
    IsAlly = IsAlly,
    IsHostile = IsHostile,
    FindTarget = FindTarget,
    FindEnemies = FindEnemies
}
