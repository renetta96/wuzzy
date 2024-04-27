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

    local dist = inst._leader_dist or MAX_DIST_FROM_LEADER

    if inst.components.follower and inst.components.follower.leader and inst.components.follower.leader:IsValid() then
        return inst:GetDistanceSqToInst(inst.components.follower.leader) < dist * dist
    end

    return true
end

local TARGET_MUST_TAGS = {"_combat", "_health"}
local TARGET_MUST_ONE_OF_TAGS = {"monster", "insect", "animal", "character"}
local TARGET_IGNORE_TAGS = {"beemutant", "INLIMBO", "player"}

local function FindEnemies(inst, dist, checkfn)
    local x, y, z = inst.Transform:GetWorldPosition()
    local entities = TheSim:FindEntities(
        x, y, z,
        dist,
        TARGET_MUST_TAGS,
        TARGET_IGNORE_TAGS,
        TARGET_MUST_ONE_OF_TAGS
    )


    local validtargets = {}
    for i, e in ipairs(entities) do
        if inst.components.combat:CanTarget(e)
            and e.components.combat and (IsAlly(e.components.combat.target) or IsHostile(e))
            and e.components.health and not e.components.health:IsDead()
        then
            if checkfn == nil or checkfn(e) then
                table.insert(validtargets, e)
            end
        end
    end


    return validtargets
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
    return lowestenemy, not (inst._focusatktime ~= nil and inst._focusatktime >= GetTime()) and math.random() <= 0.5
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

local function SpawnShadowlings(inst, num_spawn)
    local spikeondeath = false
    local owner = inst:GetOwner()
    if owner and owner:HasTag("beemaster") then
        if owner.components.skilltreeupdater:IsActivated("zeta_metapis_shadow_2") then
            spikeondeath = true
        end
    end

    for i = 1, num_spawn do
        local s = SpawnPrefab("mutantshadowling")
        local offset = FindWalkableOffset(inst:GetPosition(), math.random() * 2 * PI, 2, 5, true, false, nil, true, true)
        local pos = inst:GetPosition()
        if offset ~= nil then
            pos.x = pos.x + offset.x
            pos.z = pos.z + offset.z
        end

        s.Transform:SetPosition(pos:Get())
        s.components.combat:SetTarget(inst.components.combat.target)

        if spikeondeath then
            s:ListenForEvent("death", s.SpikeOnDeath)
        end
    end
end

local function OnCommonInit(inst)
    if inst.buffed then
        inst:Buff()
    end

    local owner = inst:GetOwner()
    if owner and owner:HasTag("beemaster") then
        if owner.components.skilltreeupdater:IsActivated("zeta_metapis_shadow_3") then
            inst:ListenForEvent("death",
                function(inst)
                    if math.random() <= TUNING.MUTANT_SHADOWLING_SPAWN_CHANCE then
                        SpawnShadowlings(inst, math.random(2, 3))
                    end
                end
            )
        end
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

    if not (inst._focusatktime ~= nil and inst._focusatktime >= GetTime()) then
        inst.components.combat:SetTarget(attacker)
    end

    -- If attacker has tag "beemutant" or "beemaster" then don't share target
    if attacker:HasTag("beemutant") or attacker:HasTag("beemaster") then
        return
    end

    local targetshares = MAX_TARGET_SHARES
    inst.components.combat:ShareTarget(attacker, SHARE_TARGET_DIST, function(dude)
        if dude:IsInLimbo() or (dude.components.health and dude.components.health:IsDead()) then
            return false
        end

        if dude.GetOwner ~= nil and dude:GetOwner() ~= inst:GetOwner() then
            return false
        end

        if dude.components.follower and dude.components.follower.leader then -- don't share to Wuzzy's summoned bees
            return false
        end

        return true
    end, targetshares, {"_combat", "_health", "beemutantminion"})
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

-- get owner, prefer player, otherwise hive
local function GetOwner(inst)
    -- wuzzy summoned bees
    if inst.components.follower and inst.components.follower.leader ~= nil then
        return inst.components.follower.leader
    end

    -- mother hive or teleportal
    if inst.components.homeseeker and inst.components.homeseeker.home then
        -- mother hive
        if inst.components.homeseeker.home._owner then
            return inst.components.homeseeker.home._owner
        end

        -- both mother hive and teleportal
        if inst.components.homeseeker.home._ownerid then
            for i, player in ipairs(AllPlayers) do
                if player:HasTag('player') and player.userid == inst.components.homeseeker.home._ownerid then
                  return player
                end
            end
        end

        -- wuzzy is not online
        return inst.components.homeseeker.home
    end

    return nil
end

local function findprotector(inst)
    return FindEntity(inst, 10, function(guy)
        return not guy.components.health:IsDead() and guy._protectaura and guy:GetOwner() == inst:GetOwner()
    end, {"beemutant", "_combat", "_health"}, {"INLIMBO"}, {"defender"})
end

local function MakeProtectable(inst)
    if not inst.components.health or not inst.components.combat then
        return
    end

    local oldDoDelta = inst.components.health.DoDelta
    inst.components.health.DoDelta = function(comp, amount, ...)
        if amount < 0 and inst.components.health.currenthealth + amount < 0.5 * inst.components.health.maxhealth and math.random() <= 0.25 then
            local owner = inst:GetOwner()
            if owner and owner:HasTag("beemaster") and owner.components.skilltreeupdater:IsActivated("zeta_metapis_defender_1") then
                local protector = findprotector(inst)
                if protector ~= nil then
                    -- print("FOUND PROTECTOR", protector, amount)
                    protector.components.health:DoDelta(amount, ...)
                    return 0
                end
            end
        end

        return oldDoDelta(comp, amount, ...)
    end
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

    if not (options and options.notprotectable) then
        MakeProtectable(inst)
    end

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

    if checkupgradefn ~= nil then
        inst:DoTaskInTime(
            0,
            function(inst)
                OnInitUpgrade(inst, checkupgradefn, 0)
            end
        )
    end
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
    inst.Transform:SetScale(1.2, 1.2, 1.2)

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


local function IsPoisonable(guy)
    return guy and guy:IsValid() and guy.components.health
        and not guy.components.health:IsDead()
        and not guy:HasTag("player")
end

local function poisoncolor(inst)
    local c_r, c_g, c_b, c_a = inst.AnimState:GetMultColour()
    inst.AnimState:SetMultColour(0.8, 0.2, 0.8, 1)
    inst:DoTaskInTime(
        0.2,
        function(inst)
            inst.AnimState:SetMultColour(c_r, c_g, c_b, c_a)
        end
    )
end

local function MakePoisonable(inst)
    if not inst.components.dotable then
        inst:AddComponent('dotable')
    end

    inst.components.dotable:AddSource("single_poison", 1)
    inst.components.dotable:AddSource("stackable_poison", 20)
    if not inst.components.dotable.ontickfn then
        inst.components.dotable.ontickfn = function(inst, damaged_sources)
            if #damaged_sources > 0 then
                poisoncolor(inst)
            end
        end
    end
end

return {
    CommonInit = CommonInit,
    CommonMasterInit = CommonMasterInit,
    BarrackModifier = BarrackModifier,
    IsAlly = IsAlly,
    IsHostile = IsHostile,
    FindTarget = FindTarget,
    FindEnemies = FindEnemies,
    IsPoisonable = IsPoisonable,
    MakePoisonable = MakePoisonable,
    SpawnShadowlings = SpawnShadowlings,
}
