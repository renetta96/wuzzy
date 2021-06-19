local beecommon = require "brains/mutantbeecommon"

local assets = {
    Asset("ANIM", "anim/mutantrangerbee.zip"),
    Asset("ANIM", "anim/mutantassassinbee.zip"),
    Asset("ANIM", "anim/mutantdefenderbee.zip"),
    Asset("ANIM", "anim/mutantworkerbee.zip"),
    Asset("ANIM", "anim/mutantsoldierbee.zip"),
    Asset("ANIM", "anim/mutantshadowbee.zip"),
    Asset("ANIM", "anim/mutantbee_teleport.zip"),
    Asset("SOUND", "sound/bee.fsb")
}

local prefabs = {
    "stinger",
    "honey",
    "explode_small",
    "blowdart_yellow",
    "electrichitsparks"
}

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

local function IsNearbyPlayer(inst)
    return GetClosestInstWithTag("beemaster", inst, TUNING.MUTANT_BEE_WATCH_DIST)
end

local function IsAlly(inst)
    return inst and (inst:HasTag("beemaster") or inst:HasTag("mutant"))
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

local function keeptargetfn(inst, target)
    return IsWithinLeaderRange(inst)
end

local function FindTarget(inst, dist)
    if not IsWithinLeaderRange(inst) then
        return nil
    end

    local nearbyplayer = IsNearbyPlayer(inst)

    return (nearbyplayer and
        FindEntity(
            inst,
            dist,
            function(guy)
                return inst.components.combat:CanTarget(guy)
            end,
            {"_combat", "_health"},
            {"insect", "INLIMBO", "player"},
            {"monster"}
        )) or
        FindEntity(
            inst,
            dist,
            function(guy)
                return inst.components.combat:CanTarget(guy) and guy.components.combat and
                    IsAlly(guy.components.combat.target)
            end,
            {"_combat", "_health"},
            {"mutant", "INLIMBO", "player"},
            {"monster", "insect", "animal", "character"}
        )
end

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

-- /* Mutant effects
local function DoPoisonDamage(inst)
    if inst._poisonticks <= 0 or inst.components.health:IsDead() then
        inst._poisontask:Cancel()
        inst._poisontask = nil
        return
    end

    -- Leave at least 1 health
    local delta = math.min(TUNING.MUTANT_BEE_POISON_DAMAGE, inst.components.health.currenthealth - 1)
    inst.components.health:DoDelta(-delta, true, "poison_sting")

    local c_r, c_g, c_b, c_a = inst.AnimState:GetMultColour()
    inst.AnimState:SetMultColour(0.8, 0.2, 0.8, 1)
    inst:DoTaskInTime(
        0.2,
        function(inst)
            inst.AnimState:SetMultColour(c_r, c_g, c_b, c_a)
        end
    )

    inst._poisonticks = inst._poisonticks - 1

    if inst._poisonticks <= 0 or inst.components.health:IsDead() then
        inst._poisontask:Cancel()
        inst._poisontask = nil
    end
end

local function OnAttackOtherWithPoison(inst, data)
    if
        data.target and data.target.components.health and not data.target.components.health:IsDead() and
            data.target.components.combat
     then
        -- No target players.
        if not data.target:HasTag("player") then
            data.target._poisonticks = TUNING.MUTANT_BEE_MAX_POISON_TICKS
            if data.target._poisontask == nil then
                data.target._poisontask = data.target:DoPeriodicTask(TUNING.MUTANT_BEE_POISON_PERIOD, DoPoisonDamage)
            end
        end
    end
end

local function HealAllies(inst, amount)
    local x, y, z = inst.Transform:GetWorldPosition()
    local allies =
        TheSim:FindEntities(
        x,
        y,
        z,
        TUNING.MUTANT_BEE_SOLDIER_HEAL_DIST,
        {"_combat", "_health"},
        {"INLIMBO", "soldier"},
        {"mutant", "beemaster"}
    )

    for i, ally in ipairs(allies) do
        if
            ally:IsValid() and ally.components.health and not ally.components.health:IsDead() and
                ally.components.locomotor and
                ally.components.combat and
                not IsAlly(ally.components.combat.target)
         then
            ally.components.health:DoDelta(amount)
        end
    end
end

local function OnAttackRegen(inst, data)
    if inst.components.health then
        local amount = Lerp(1, 5, 1 - inst.components.health:GetPercent())
        inst.components.health:DoDelta(amount)

        HealAllies(inst, amount / 2)
    end
end

local function RangedRetarget(inst)
    return FindTarget(inst, TUNING.MUTANT_BEE_RANGED_TARGET_DIST)
end
-- Mutant effects */

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

local function OnWake(inst)
    if inst.buzzing then
        inst.SoundEmitter:PlaySound(inst.sounds.buzz, "buzz")
    end
end

local function OnSleep(inst)
    inst.SoundEmitter:KillSound("buzz")
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

local function KillerRetarget(inst)
    return FindTarget(inst, TUNING.MUTANT_BEE_TARGET_DIST)
end

local function MutantBeeRetarget(inst)
    return FindTarget(inst, TUNING.MUTANT_BEE_TARGET_DIST)
end

local WAKE_TO_FOLLOW_DISTANCE = 15

local function ShouldWakeUp(inst)
    return DefaultWakeTest(inst) or
        (inst.components.follower and not inst.components.follower:IsNearLeader(WAKE_TO_FOLLOW_DISTANCE))
end

local SLEEP_NEAR_LEADER_DISTANCE = 8

local function ShouldSleep(inst)
    return DefaultSleepTest(inst) and
        (inst.components.follower == nil or inst.components.follower:IsNearLeader(SLEEP_NEAR_LEADER_DISTANCE))
end

local function MakeLessNoise(inst)
    inst:ListenForEvent("startfollowing", OnStartFollowing)
    inst:ListenForEvent("stopfollowing", OnStopFollowing)
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

    if not hive or hive.prefab ~= "mutantbeehive" or not hive:IsValid() then
        return 0
    end

    if not hive.components.upgradeable then
        return 0
    end

    return hive.components.upgradeable.stage
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

local function commonfn(bank, build, tags, options)
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
    inst:AddTag("mutant")
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

    inst:AddComponent("locomotor") -- locomotor must be constructed before the stategraph
    inst.components.locomotor:EnableGroundSpeedMultiplier(false)
    inst.components.locomotor:SetTriggersCreep(false)
    inst:SetStateGraph("SGmutantbee")

    ---------------------

    inst:AddComponent("lootdropper")
    inst.components.lootdropper:AddRandomLoot("honey", 1)
    inst.components.lootdropper:AddRandomLoot("stinger", 4)
    inst.components.lootdropper.numrandomloot = 1
    inst.components.lootdropper.chancerandomloot = 0.5

    ------------------

    if not (options and options.notburnable) then
        MakeSmallBurnableCharacter(inst, "body", Vector3(0, -1, 1))
    end

    if not (options and options.notfreezable) then
        MakeTinyFreezableCharacter(inst, "body", Vector3(0, -1, 1))
    end

    ------------------

    inst:AddComponent("health")
    inst:AddComponent("combat")
    inst.components.combat:SetRange(TUNING.BEE_ATTACK_RANGE)
    inst.components.combat.hiteffectsymbol = "body"
    inst.components.combat:SetPlayerStunlock(PLAYERSTUNLOCK.RARELY)
    inst.components.combat:SetKeepTargetFunction(keeptargetfn)

    ------------------

    if not (options and options.notsleep) then
        inst:AddComponent("sleeper")
        inst.components.sleeper:SetSleepTest(ShouldSleep)
        inst.components.sleeper:SetWakeTest(ShouldWakeUp)
    end
    ------------------

    inst:AddComponent("knownlocations")

    ------------------

    inst:AddComponent("inspectable")

    ------------------

    inst:ListenForEvent("attacked", beecommon.OnAttacked)
    inst.Transform:SetScale(1.2, 1.2, 1.2)

    TrackLastCombatTime(inst)

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
    inst:DoTaskInTime(0, OnCommonInit)

    return inst
end

local function OnInitUpgrade(inst, checkupgradefn, retries)
    retries = retries + 1

    local check = checkupgradefn(inst)

    if retries >= 5 then
        return
    end

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

local function CheckWorkerUpgrade(inst)
    local stage = GetHiveUpgradeStage(inst)

    if stage == 0 then
        return false
    end

    inst.components.pollinator.collectcount = math.max(5 - (stage - 1), 1)

    return true
end

local workerbrain = require("brains/mutantbeebrain")
local function workerbee()
    --pollinator (from pollinator component) added to pristine state for optimization
    --for searching: inst:AddTag("pollinator")
    local inst = commonfn("bee", "mutantworkerbee", {"worker", "pollinator"})

    if not TheWorld.ismastersim then
        return inst
    end

    inst.components.health:SetMaxHealth(TUNING.MUTANT_BEE_HEALTH)
    inst.components.combat:SetDefaultDamage(TUNING.MUTANT_BEE_DAMAGE)
    inst.components.combat:SetAttackPeriod(TUNING.MUTANT_BEE_ATTACK_PERIOD)
    inst.components.combat:SetRetargetFunction(2, MutantBeeRetarget)

    inst:AddComponent("pollinator")
    inst.components.pollinator.collectcount = 5

    inst:SetBrain(workerbrain)
    inst.sounds = workersounds

    MakeHauntableChangePrefab(inst, "mutantkillerbee")
    inst:DoTaskInTime(
        0,
        function(inst)
            OnInitUpgrade(inst, CheckWorkerUpgrade, 0)
        end
    )

    return inst
end

local function OnSpawnedFromHaunt(inst)
    if inst.components.hauntable ~= nil then
        inst.components.hauntable:Panic()
    end
end

local function CheckSoldierUpgrade(inst)
    local stage = GetHiveUpgradeStage(inst)

    if stage == 0 then
        return false
    end

    if stage >= 2 then
        inst.components.health:SetAbsorptionAmount(TUNING.MUTANT_BEE_SOLDIER_ABSORPTION)
    end

    if stage >= 3 then
        inst:ListenForEvent("onattackother", OnAttackRegen)
    end

    return true
end

local function SoldierBuff(inst)
    inst.components.combat:SetAttackPeriod(TUNING.MUTANT_BEE_ATTACK_PERIOD - 0.5)
end

local killerbrain = require("brains/mutantkillerbeebrain")
local function killerbee()
    local inst = commonfn("bee", "mutantsoldierbee", {"soldier", "killer", "scarytoprey"}, {buff = SoldierBuff})

    if not TheWorld.ismastersim then
        return inst
    end

    inst.components.health:SetMaxHealth(TUNING.MUTANT_BEE_SOLDIER_HEALTH)

    inst.components.combat:SetDefaultDamage(TUNING.MUTANT_BEE_DAMAGE)
    inst.components.combat:SetAttackPeriod(TUNING.MUTANT_BEE_ATTACK_PERIOD)
    inst.components.combat:SetRetargetFunction(0.5, KillerRetarget)
    inst.components.combat:SetRange(3, 6)

    inst:SetBrain(killerbrain)
    inst.sounds = killersounds

    MakeHauntablePanic(inst)
    inst:ListenForEvent("spawnedfromhaunt", OnSpawnedFromHaunt)

    MakeLessNoise(inst)
    inst:DoTaskInTime(
        0,
        function(inst)
            OnInitUpgrade(inst, CheckSoldierUpgrade, 0)
        end
    )

    return inst
end

local function OnRangedWeaponAttack(inst, attacker, target)
    --target could be killed or removed in combat damage phase
    if target:IsValid() then
        SpawnPrefab("electrichitsparks"):AlignToTarget(target, inst)
    end
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

local function CheckRangerUpgrade(inst)
    local stage = GetHiveUpgradeStage(inst)

    if stage == 0 then
        return false
    end

    if stage >= 2 then
        if inst.weapon and inst.weapon:IsValid() and inst.weapon.components.weapon then
            inst.weapon.components.weapon:SetElectric()
            inst.weapon.components.weapon:SetOnAttack(OnRangedWeaponAttack)
        end
    end

    if stage >= 3 then
        inst._doublehitnow = true
        inst:ListenForEvent("onattackother", OnAttackDoubleHit)
    end

    return true
end

local function RangerBuff(inst)
    inst.components.combat:SetAttackPeriod(TUNING.MUTANT_BEE_RANGED_ATK_PERIOD - 1)
end

local rangedkillerbrain = require("brains/rangedkillerbeebrain")
local function rangerbee()
    local inst = commonfn("bee", "mutantrangerbee", {"killer", "ranger", "scarytoprey"}, {buff = RangerBuff})

    if not TheWorld.ismastersim then
        return inst
    end

    inst.components.health:SetMaxHealth(TUNING.MUTANT_BEE_RANGED_HEATLH)
    inst.components.combat:SetRange(TUNING.MUTANT_BEE_WEAPON_ATK_RANGE)
    inst.components.combat:SetAttackPeriod(TUNING.MUTANT_BEE_RANGED_ATK_PERIOD)
    inst.components.combat:SetDefaultDamage(TUNING.MUTANT_BEE_RANGED_DAMAGE)
    inst.components.combat:SetRetargetFunction(0.25, RangedRetarget)

    inst:SetBrain(rangedkillerbrain)
    inst.sounds = killersounds

    MakeHauntablePanic(inst)
    MakeLessNoise(inst)

    inst:AddComponent("inventory")

    if not inst.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS) then
        local weapon = CreateEntity()
        weapon.entity:AddTransform()
        MakeInventoryPhysics(weapon)
        weapon:AddComponent("weapon")
        weapon.components.weapon:SetDamage(inst.components.combat.defaultdamage)
        weapon.components.weapon:SetRange(inst.components.combat.attackrange)
        weapon.components.weapon:SetProjectile("blowdart_yellow")

        weapon:AddComponent("inventoryitem")
        weapon.persists = false
        weapon.components.inventoryitem:SetOnDroppedFn(weapon.Remove)
        weapon:AddComponent("equippable")
        inst.weapon = weapon
        inst.components.inventory:Equip(inst.weapon)
    end

    inst:DoTaskInTime(
        0,
        function(inst)
            OnInitUpgrade(inst, CheckRangerUpgrade, 0)
        end
    )

    return inst
end

local function OnStealthAttack(inst, data)
    if not data.target then
        return
    end

    if data.stimuli and data.stimuli == "stealthattack" then
        return
    end

    local target = data.target

    if not target.components.combat or not target.components.combat:TargetIs(inst) then
        local damagemult = TUNING.MUTANT_BEE_ASSASSIN_BACKSTAB_DAMAGE_MULT
        if target.components.health then
            damagemult = damagemult + (1 - target.components.health:GetPercent())
        end
        inst.components.combat:DoAttack(
            target,
            nil,
            nil,
            "stealthattack",
            TUNING.MUTANT_BEE_ASSASSIN_BACKSTAB_DAMAGE_MULT
        )
    end
end

local function Stealth(inst)
    local r, g, b = inst.AnimState:GetMultColour()
    inst.AnimState:SetMultColour(r, g, b, 0.4)
end

local function Unstealth(inst)
    local r, g, b = inst.AnimState:GetMultColour()
    inst.AnimState:SetMultColour(r, g, b, 1)
end

local function CheckAssassinUpgrade(inst)
    local stage = GetHiveUpgradeStage(inst)

    if stage == 0 then
        return false
    end

    if stage >= 2 then
        inst:ListenForEvent("onattackother", OnAttackOtherWithPoison)
    end

    if stage >= 3 then
        inst:ListenForEvent("onattackother", OnStealthAttack)
    end

    return true
end

local function AssassinBuff(inst)
    inst.components.combat:SetDefaultDamage(TUNING.MUTANT_BEE_ASSSASIN_DAMAGE + 3)
end

local assassinbeebrain = require "brains/assassinbeebrain"
local function assassinbee()
    local inst = commonfn("bee", "mutantassassinbee", {"killer", "assassin", "scarytoprey"}, {buff = AssassinBuff})

    if not TheWorld.ismastersim then
        return inst
    end

    inst.components.locomotor.groundspeedmultiplier = 1.5

    inst.components.health:SetMaxHealth(TUNING.MUTANT_BEE_ASSSASIN_HEALTH)
    inst.components.combat:SetDefaultDamage(TUNING.MUTANT_BEE_ASSSASIN_DAMAGE)
    inst.components.combat:SetAttackPeriod(TUNING.MUTANT_BEE_ASSASSIN_ATTACK_PERIOD)
    inst.components.combat:SetRetargetFunction(0.25, KillerRetarget)
    inst.components.combat:SetRange(3, 6)
    inst:SetBrain(assassinbeebrain)
    inst.sounds = killersounds

    MakeHauntablePanic(inst)
    MakeLessNoise(inst)

    Stealth(inst)

    inst:DoTaskInTime(
        0,
        function(inst)
            OnInitUpgrade(inst, CheckAssassinUpgrade, 0)
        end
    )

    inst:ListenForEvent("newcombattarget", Unstealth)
    inst:ListenForEvent("droppedtarget", Stealth)

    inst.Stealth = Stealth
    inst.Unstealth = Unstealth

    return inst
end

local function DoSpike(inst, target, onlyfx)
    if not target or not inst:IsValid() or not inst.components.combat:CanTarget(target) then
        return
    end

    local spikefx = SpawnPrefab("shadowspike_fx")
    if spikefx then
        spikefx.Transform:SetPosition(target.Transform:GetWorldPosition())
    end

    if not onlyfx then
        inst.components.combat:DoAttack(target, nil, nil, "spikeattack")
    end
end

local function Spike(inst, origin)
    local x, y, z = origin.Transform:GetWorldPosition()
    local entities =
        TheSim:FindEntities(
        x,
        y,
        z,
        5,
        {"_combat", "_health"},
        {"mutant", "INLIMBO", "player"},
        {"monster", "insect", "animal", "character"}
    )

    local nearbyplayer = IsNearbyPlayer(inst)

    local validtargets = {}

    for i, e in ipairs(entities) do
        local valid = false

        if inst.components.combat:CanTarget(e) then
            if e.components.combat and IsAlly(e.components.combat.target) then
                valid = true
            end

            if nearbyplayer and e:HasTag("monster") then
                valid = true
            end
        end

        if valid and e ~= origin then
            table.insert(validtargets, e)
        end
    end

    DoSpike(inst, origin, true)

    if not (inst._numspikes and inst._numspikes > 0) then
        return
    end

    for i, target in ipairs(validtargets) do
        if i > inst._numspikes then
            break
        end

        -- random delay from 0.25 to 0.75 sec
        inst:DoTaskInTime(
            math.random(25, 75) / 100,
            function()
                DoSpike(inst, target)
            end
        )
    end
end

local function OnShadowAttack(inst, data)
    if data.stimuli and data.stimuli == "spikeattack" then
        return
    end

    if data.target then
        Spike(inst, data.target)
    end
end

local function CheckShadowUpgrade(inst)
    local stage = GetHiveUpgradeStage(inst)

    if stage == 0 then
        return false
    end

    -- Add teleport
    if stage >= 2 then
        inst.canteleport = true
    end

    -- Add 1 more spike
    if stage >= 3 then
        inst._numspikes = TUNING.MUTANT_BEE_SHADOW_DEFAULT_NUM_SPIKES + 1
    end

    return true
end

local function ShadowBuff(inst)
    inst.components.combat:SetDefaultDamage(TUNING.MUTANT_BEE_SHADOW_DAMAGE + 3)
end

local shadowbeebrain = require "brains/shadowbeebrain"
local function shadowbee()
    local inst =
        commonfn(
        "bee",
        "mutantshadowbee",
        {"shadowbee", "killer", "scarytoprey"},
        {notburnable = true, notfreezable = true, notsleep = true, buff = ShadowBuff}
    )

    local r, g, b = inst.AnimState:GetMultColour()
    inst.AnimState:SetMultColour(r, g, b, 0.6)

    if not TheWorld.ismastersim then
        return inst
    end

    inst.components.health:SetMaxHealth(TUNING.MUTANT_BEE_SHADOW_HEALTH)

    inst.components.combat:SetDefaultDamage(TUNING.MUTANT_BEE_SHADOW_DAMAGE)
    inst.components.combat:SetAttackPeriod(TUNING.MUTANT_BEE_SHADOW_ATK_PERIOD)
    inst.components.combat:SetRange(TUNING.MUTANT_BEE_SHADOW_ATK_RANGE, TUNING.MUTANT_BEE_SHADOW_ATK_RANGE + 3)
    inst.components.combat:SetRetargetFunction(0.5, KillerRetarget)

    inst._numspikes = TUNING.MUTANT_BEE_SHADOW_DEFAULT_NUM_SPIKES
    inst.canteleport = false
    inst:ListenForEvent("onattackother", OnShadowAttack)

    inst:SetBrain(shadowbeebrain)
    inst.sounds = killersounds

    MakeLessNoise(inst)
    inst:DoTaskInTime(
        0,
        function(inst)
            OnInitUpgrade(inst, CheckShadowUpgrade, 0)
        end
    )

    return inst
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
    local x, y, z = inst.Transform:GetWorldPosition()
    local entities =
        TheSim:FindEntities(
        x,
        y,
        z,
        TUNING.MUTANT_BEE_DEFENDER_TAUNT_DIST,
        {"_combat", "_health"},
        {"mutant", "INLIMBO", "player"},
        {"monster", "insect", "animal", "character"}
    )

    local nearbyplayer = IsNearbyPlayer(inst)

    for i, e in ipairs(entities) do
        -- to handle noobs that set combat.target directly!!!
        if e.components.combat and e.components.combat.losetargetcallback and not IsTaunted(e) then
            if IsAlly(e.components.combat.target) or (nearbyplayer and e:HasTag("monster")) then
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

local function CheckDefenderUpgrade(inst)
    local stage = GetHiveUpgradeStage(inst)

    if stage == 0 then
        return false
    end

    if stage >= 2 then
        inst.components.health:SetAbsorptionAmount(TUNING.MUTANT_BEE_DEFENDER_ABSORPTION)
    end

    if stage >= 3 then
        inst:ListenForEvent("attacked", OnDefenderAttacked)
    end

    return true
end

local function GuardianBuff(inst)
    inst.buffed = true
    inst.components.health:SetMaxHealth(TUNING.MUTANT_BEE_DEFENDER_HEALTH + 25)
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
    inst:AddTag("mutant")
    inst:AddTag("companion")
    inst:AddTag("defender")
    inst:AddTag("ignorewalkableplatformdrowning")

    MakeInventoryFloatable(inst)

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inspectable")

    inst:AddComponent("lootdropper")
    inst.components.lootdropper:AddRandomLoot("honey", 1)
    inst.components.lootdropper:AddRandomLoot("stinger", 4)
    inst.components.lootdropper.numrandomloot = 1
    inst.components.lootdropper.chancerandomloot = 0.5

    inst:AddComponent("sleeper")
    inst.components.sleeper:SetSleepTest(ShouldSleep)
    inst.components.sleeper:SetWakeTest(ShouldWakeUp)

    inst:AddComponent("locomotor")
    inst.components.locomotor:EnableGroundSpeedMultiplier(false)
    inst.components.locomotor:SetTriggersCreep(false)
    inst.components.locomotor.walkspeed = 3
    inst.components.locomotor.pathcaps = {allowocean = true}

    inst:AddComponent("health")
    inst.components.health:SetMaxHealth(TUNING.MUTANT_BEE_DEFENDER_HEALTH)

    inst:AddComponent("combat")
    inst.components.combat:SetDefaultDamage(TUNING.MUTANT_BEE_DEFENDER_DAMAGE)
    inst.components.combat:SetAttackPeriod(TUNING.MUTANT_BEE_DEFENDER_ATTACK_PERIOD)
    inst.components.combat:SetRange(TUNING.MUTANT_BEE_DEFENDER_ATTACK_RANGE)
    inst.components.combat:SetRetargetFunction(0.5, KillerRetarget)
    inst.components.combat:SetKeepTargetFunction(keeptargetfn)
    inst.components.combat.battlecryenabled = false
    inst.components.combat.hiteffectsymbol = "mane"

    inst:AddComponent("knownlocations")

    inst:ListenForEvent("attacked", beecommon.OnAttacked)

    MakeSmallBurnableCharacter(inst, "mane")
    MakeSmallFreezableCharacter(inst, "mane")
    inst.components.freezable:SetResistance(4)
    inst.components.freezable.diminishingreturns = true

    inst:SetStateGraph("SGdefenderbee")
    inst:SetBrain(defenderbeebrain)

    MakeHauntablePanic(inst)
    MakeLessNoise(inst)

    inst:ListenForEvent("newcombattarget", OnDefenderStartCombat)
    inst:ListenForEvent("droppedtarget", OnDefenderStopCombat)

    TrackLastCombatTime(inst)

    inst:DoTaskInTime(
        0,
        function(inst)
            OnInitUpgrade(inst, CheckDefenderUpgrade, 0)
        end
    )

    inst.sounds = poofysounds

    inst.buzzing = true
    inst.EnableBuzz = EnableBuzz
    inst.OnEntityWake = OnWake
    inst.OnEntitySleep = OnSleep
    inst.OnSave = OnCommonSave
    inst.OnLoad = OnCommonLoad
    inst.Buff = GuardianBuff
    inst:DoTaskInTime(0, OnCommonInit)

    return inst
end

STRINGS.MUTANTBEE = "Metapis Worker"
STRINGS.NAMES.MUTANTBEE = "Metapis Worker"
STRINGS.CHARACTERS.GENERIC.DESCRIBE.MUTANTBEE = "Meta...apis? Metabee? Like metahuman?"

STRINGS.MUTANTKILLERBEE = "Metapis Soldier"
STRINGS.NAMES.MUTANTKILLERBEE = "Metapis Soldier"
STRINGS.CHARACTERS.GENERIC.DESCRIBE.MUTANTKILLERBEE = "Little grunt."

STRINGS.MUTANTRANGERBEE = "Metapis Ranger"
STRINGS.NAMES.MUTANTRANGERBEE = "Metapis Ranger"
STRINGS.CHARACTERS.GENERIC.DESCRIBE.MUTANTRANGERBEE = "It always tries to keep distance."

STRINGS.MUTANTASSASSINBEE = "Metapis Mutant"
STRINGS.NAMES.MUTANTASSASSINBEE = "Metapis Mutant"
STRINGS.CHARACTERS.GENERIC.DESCRIBE.MUTANTASSASSINBEE = "Horrifying."

STRINGS.MUTANTDEFENDERBEE = "Metapis Moonguard"
STRINGS.NAMES.MUTANTDEFENDERBEE = "Metapis Moonguard"
STRINGS.CHARACTERS.GENERIC.DESCRIBE.MUTANTDEFENDERBEE = "Hard rock."

STRINGS.MUTANTSHADOWBEE = "Metapis Shadow"
STRINGS.NAMES.MUTANTSHADOWBEE = "Metapis Shadow"
STRINGS.CHARACTERS.GENERIC.DESCRIBE.MUTANTSHADOWBEE = "Nightmare."

return Prefab("mutantbee", workerbee, assets, prefabs),
    Prefab("mutantkillerbee", killerbee, assets, prefabs),
    Prefab("mutantrangerbee", rangerbee, assets, prefabs),
    Prefab("mutantassassinbee", assassinbee, assets, prefabs),
    Prefab("mutantdefenderbee", defenderbee, assets, prefabs),
    Prefab("mutantshadowbee", shadowbee, assets, prefabs)
