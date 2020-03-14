local beecommon = require "brains/mutantbeecommon"
local helpers = require "helpers"
local metapisutil = require "metapisutil"

local assets =
{
  Asset("ANIM", "anim/mutantrangerbee.zip"),
  Asset("ANIM", "anim/mutantassassinbee.zip"),
  Asset("ANIM", "anim/mutantdefenderbee.zip"),
  Asset("ANIM", "anim/mutantworkerbee.zip"),
  Asset("ANIM", "anim/mutantsoldierbee.zip"),
  Asset("SOUND", "sound/bee.fsb"),
}

local prefabs =
{
  "stinger",
  "honey",
  "explode_small",
  "blowdart_walrus"
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
  return (GetPlayer():IsNear(inst, TUNING.MUTANT_BEE_WATCH_DIST) and
  FindEntity(inst, dist,
    function(guy)
      return inst.components.combat:CanTarget(guy)
    end,
    nil,
    { "insect", "INLIMBO", "player" },
    { "monster" })
  ) or
  FindEntity(inst, dist,
    function(guy)
      return inst.components.combat:CanTarget(guy)
        and guy.components.combat and guy.components.combat.target
        and guy.components.combat.target:HasTag("player")
    end,
    nil,
    { "mutant", "INLIMBO", "player" },
    { "monster", "insect", "animal", "character" })
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
  if data.target and data.target.components.health and not data.target.components.health:IsDead() and data.target.components.combat then
    -- No target players.
    if not data.target:HasTag("player") then
      data.target._poisonticks = TUNING.MUTANT_BEE_MAX_POISON_TICKS
      if data.target._poisontask == nil then
        data.target._poisontask = data.target:DoPeriodicTask(TUNING.MUTANT_BEE_POISON_PERIOD, DoPoisonDamage)
      end
    end
  end
end

local function OnAttackExplosive(inst, data)
  inst._attackcount = inst._attackcount + 1

  if inst._attackcount >= 7 then
    inst._attackcount = 0
    local target = data.target

    if target then
      inst.components.combat:DoAreaAttack(target, TUNING.MUTANT_BEE_EXPLOSIVE_RANGE, nil,
        function(guy)
          if guy:HasTag("player") or guy:HasTag("mutant") then
            return false
          end

          return guy:HasTag("monster") or
            (
              guy.components.combat and guy.components.combat.target ~= nil
              and (
                guy.components.combat.target:HasTag("player")
                or guy.components.combat.target:HasTag("mutant")
              )
            )
        end
      )
      SpawnPrefab("explode_small").Transform:SetPosition(target.Transform:GetWorldPosition())
    end
  end
end

local function RangedRetarget(inst)
  return FindTarget(inst, TUNING.MUTANT_BEE_RANGED_TARGET_DIST)
end

local function ForceRetarget(inst)
  if inst.components.combat.target == nil then
    return
  end

  local target = inst.components.combat.target
  if not inst.components.combat:CanTarget(target)
  or (target.components.health and target.components.health:IsDead()) then
    inst.components.combat:GiveUp()
  end
end
-- Mutant effects */

local function IsFollowing(inst)
  return inst.components.follower and inst.components.follower.leader ~= nil
end

local function EnableBuzz(inst, enable)
  if enable then
    if IsFollowing(inst) and not inst.components.combat.target then
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
  else
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

local function OnCheckBuzzing(inst)
  if IsFollowing(inst) and not inst.components.combat.target then
    EnableBuzz(inst, false)
  end
end

local function OnStopFollowing(inst)
  EnableBuzz(inst, true)
  inst:RemoveEventCallback("newcombattarget", OnNewCombatTarget)
  inst:RemoveEventCallback("giveuptarget", OnDroppedTarget)
  inst:RemoveEventCallback("losttarget", OnDroppedTarget)
  if inst._check_buzzing then
    inst._check_buzzing:Cancel()
    inst._check_buzzing = nil
  end
end

local function KillerRetarget(inst)
  return FindTarget(inst, TUNING.MUTANT_BEE_TARGET_DIST)
end

local function MutantBeeRetarget(inst)
  return FindTarget(inst, TUNING.MUTANT_BEE_TARGET_DIST)
end

WAKE_TO_FOLLOW_DISTANCE = 15

local function ShouldWakeUp(inst)
  return DefaultWakeTest(inst)
  or (inst.components.follower
    and not inst.components.follower:IsNearLeader(WAKE_TO_FOLLOW_DISTANCE))
end

SLEEP_NEAR_LEADER_DISTANCE = 8

local function ShouldSleep(inst)
  return DefaultSleepTest(inst)
  and (inst.components.follower == nil or
    inst.components.follower:IsNearLeader(SLEEP_NEAR_LEADER_DISTANCE))
end

local function OnStartFollowing(inst, data)
  EnableBuzz(inst, false)
  inst:ListenForEvent("newcombattarget", OnNewCombatTarget)
  inst:ListenForEvent("giveuptarget", OnDroppedTarget)
  inst:ListenForEvent("losttarget", OnDroppedTarget)
  inst._check_buzzing = inst:DoPeriodicTask(1, OnCheckBuzzing)
end

local function MakeLessNoise(inst)
  inst:ListenForEvent("startfollowing", OnStartFollowing)
  inst:ListenForEvent("stopfollowing", OnStopFollowing)
end

local function StartCheckingTarget(inst, fn)
  if not inst.components.combat then
    return
  end

  inst:DoPeriodicTask(1,
    function(inst)
      if inst.components.combat and not inst.components.combat.target then
        fn(inst)
      end
    end
  )
end

local function commonfn(bank, build, tags)
  local inst = CreateEntity()

  inst.entity:AddTransform()
  inst.entity:AddAnimState()
  inst.entity:AddSoundEmitter()
  inst.entity:AddLightWatcher()
  inst.entity:AddDynamicShadow()
  inst.DynamicShadow:SetSize(.8, .5)
  inst.Transform:SetFourFaced()

  MakePoisonableCharacter(inst)

  MakeAmphibiousCharacterPhysics(inst, 1, 0.1)

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

  inst:AddComponent("locomotor") -- locomotor must be constructed before the stategraph
  inst.components.locomotor:EnableGroundSpeedMultiplier(false)
  inst.components.locomotor:SetTriggersCreep(false)
  inst:SetStateGraph("SGbee")

  ---------------------

  inst:AddComponent("lootdropper")
  inst.components.lootdropper:AddRandomLoot("honey", 1)
  inst.components.lootdropper:AddRandomLoot("stinger", 4)
  inst.components.lootdropper.numrandomloot = 1
  inst.components.lootdropper.chancerandomloot = 0.5

  ------------------

  MakeSmallBurnableCharacter(inst, "body", Vector3(0, -1, 1))
  MakeTinyFreezableCharacter(inst, "body", Vector3(0, -1, 1))

  ------------------

  inst:AddComponent("health")
  inst:AddComponent("combat")
  inst.components.combat.hiteffectsymbol = "body"

  ------------------

  inst:AddComponent("sleeper")
  inst.components.sleeper:SetSleepTest(ShouldSleep)
  inst.components.sleeper:SetWakeTest(ShouldWakeUp)
  ------------------

  inst:AddComponent("knownlocations")

  ------------------

  inst:AddComponent("inspectable")

  ------------------

  inst:ListenForEvent("attacked", beecommon.OnAttacked)
  inst.Transform:SetScale(1.2, 1.2, 1.2)

  inst.buzzing = true
  inst.EnableBuzz = EnableBuzz
  inst.OnEntityWake = OnWake
  inst.OnEntitySleep = OnSleep

  return inst
end

local function GetHiveUpgradeStage(inst)
  local hive = nil
  if inst.components.homeseeker and inst.components.homeseeker.home then
    hive = inst.components.homeseeker.home
  elseif inst.components.follower and inst.components.follower.leader and inst.components.follower.leader._hive then
    hive = inst.components.follower.leader._hive
  end

  if not hive or hive.prefab ~= 'mutantbeehive' or not hive:IsValid() then
    return 0
  end

  if not hive.components.upgradeable then
    return 0
  end

  return hive.components.upgradeable.stage
end

local function OnInitUpgrade(inst, checkupgradefn, retries)
  retries = retries + 1

  local check = checkupgradefn(inst)

  if retries >= 5 then
    return
  end

  -- Not check upgrade successfully, retry upto 5 times
  if not check then
    inst:DoTaskInTime(1, function(inst) OnInitUpgrade(inst, checkupgradefn, retries) end)
  end
end

local function CheckWorkerUpgrade(inst)
  local stage = GetHiveUpgradeStage(inst)

  if stage == 0 then
    return false
  end

  inst.components.pollinator.collectcount = math.max(
    5 - (stage - 1),
    1
  )

  return true
end

local workerbrain = require("brains/mutantbeebrain")
local function workerbee()
  --pollinator (from pollinator component) added to pristine state for optimization
  --for searching: inst:AddTag("pollinator")
  local inst = commonfn("mutantworkerbee", "mutantworkerbee", { "worker", "pollinator" })

  inst.components.health:SetMaxHealth(TUNING.MUTANT_BEE_HEALTH)

  inst.components.combat:SetDefaultDamage(TUNING.MUTANT_BEE_DAMAGE)
  inst.components.combat:SetAttackPeriod(TUNING.MUTANT_BEE_ATTACK_PERIOD)
  inst.components.combat:SetRetargetFunction(2, MutantBeeRetarget)

  inst:AddComponent("pollinator")
  inst.components.pollinator.collectcount = 5

  inst:SetBrain(workerbrain)
  inst.sounds = workersounds

  inst:DoTaskInTime(0, function(inst) OnInitUpgrade(inst, CheckWorkerUpgrade, 0) end)

  return inst
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
    inst.components.combat.areahitdamagepercent = TUNING.MUTANT_BEE_EXPLOSIVE_DAMAGE_MULTIPLIER
    inst:ListenForEvent("onattackother", OnAttackExplosive)
  end

  return true
end

local killerbrain = require("brains/mutantkillerbeebrain")
local function killerbee()
  local inst = commonfn("mutantsoldierbee", "mutantsoldierbee", { "soldier", "killer", "scarytoprey" })

  inst:AddComponent("follower")
  inst.components.follower:SetFollowExitDestinations({EXIT_DESTINATION.LAND, EXIT_DESTINATION.WATER})

  inst.components.health:SetMaxHealth(TUNING.MUTANT_BEE_SOLDIER_HEALTH)

  inst.components.combat:SetDefaultDamage(TUNING.MUTANT_BEE_DAMAGE)
  inst.components.combat:SetAttackPeriod(TUNING.MUTANT_BEE_ATTACK_PERIOD)
  inst.components.combat:SetRetargetFunction(1, KillerRetarget)

  inst:SetBrain(killerbrain)
  inst.sounds = killersounds
  inst._attackcount = 0

  inst:DoTaskInTime(0, function(inst) OnInitUpgrade(inst, CheckSoldierUpgrade, 0) end)

  MakeLessNoise(inst)

  return inst
end

local function OnAttackDoubleHit(inst, data)
  if inst._doublehitnow then
    inst.components.combat:ResetCooldown()
    inst._doublehitnow = false
  end

  if not inst._doublehittask then
    inst._doublehittask = inst:DoTaskInTime(TUNING.MUTANT_BEE_RANGED_ATK_PERIOD * 4,
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
    inst.components.combat:SetDefaultDamage(TUNING.MUTANT_BEE_RANGED_DAMAGE * 1.5)
    if inst.weapon and inst.weapon:IsValid() and inst.weapon.components.weapon then
      inst.weapon.components.weapon:SetDamage(inst.components.combat.defaultdamage)
    end
  end

  if stage >= 3 then
    inst._doublehitnow = true
    inst:ListenForEvent("onattackother", OnAttackDoubleHit)
  end

  return true
end

local rangedkillerbrain = require("brains/rangedkillerbeebrain")
local function rangerbee()
  local inst = commonfn("mutantrangerbee", "mutantrangerbee", { "killer", "ranger", "scarytoprey" })

  inst.components.health:SetMaxHealth(TUNING.MUTANT_BEE_RANGED_HEATLH)

  inst.components.combat:SetRange(TUNING.MUTANT_BEE_WEAPON_ATK_RANGE)
  inst.components.combat:SetAttackPeriod(TUNING.MUTANT_BEE_RANGED_ATK_PERIOD)
  inst.components.combat:SetDefaultDamage(TUNING.MUTANT_BEE_RANGED_DAMAGE)
  inst.components.combat:SetRetargetFunction(0.25, RangedRetarget)

  inst:SetBrain(rangedkillerbrain)
  inst.sounds = killersounds

  MakeLessNoise(inst)

  inst:AddComponent("inventory")

  -- Fix for non-Hamlet DLC, don't know why
  if not helpers.CheckDlcEnabled("PORKLAND_DLC") then
    inst:DoPeriodicTask(1, ForceRetarget)
  end

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

  inst:DoTaskInTime(0, function(inst) OnInitUpgrade(inst, CheckRangerUpgrade, 0) end)

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

  if not target.components.combat or target.components.combat.target ~= inst then
    local damagemult = TUNING.MUTANT_BEE_ASSASSIN_BACKSTAB_DAMAGE_MULT
    if target.components.health then
      damagemult = damagemult + (1 - target.components.health:GetPercent())
    end
    inst.components.combat:DoAttack(target, nil, nil, "stealthattack", TUNING.MUTANT_BEE_ASSASSIN_BACKSTAB_DAMAGE_MULT)
  end
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

local function Stealth(inst)
  local r, g, b = inst.AnimState:GetMultColour()
  inst.AnimState:SetMultColour(r, g, b, 0.4)
end

local function Unstealth(inst)
  local r, g, b = inst.AnimState:GetMultColour()
  inst.AnimState:SetMultColour(r, g, b, 1)
end

local assassinbeebrain = require "brains/assassinbeebrain"
local function assassinbee()
  local inst = commonfn("mutantassassinbee", "mutantassassinbee", { "killer", "assassin", "scarytoprey" })

  inst.components.locomotor.groundspeedmultiplier = 1.3


  inst.components.health:SetMaxHealth(TUNING.MUTANT_BEE_ASSSASIN_HEALTH)
  inst.components.combat:SetDefaultDamage(TUNING.MUTANT_BEE_ASSSASIN_DAMAGE)
  inst.components.combat:SetAttackPeriod(TUNING.MUTANT_BEE_ASSASSIN_ATTACK_PERIOD)
  inst.components.combat:SetRetargetFunction(1, KillerRetarget)

  inst:SetBrain(assassinbeebrain)
  inst.sounds = killersounds

  MakeLessNoise(inst)

  Stealth(inst)
  inst:DoTaskInTime(0, function(inst) OnInitUpgrade(inst, CheckAssassinUpgrade, 0) end)

  inst:ListenForEvent("newcombattarget", Unstealth)
  StartCheckingTarget(inst, Stealth)

  return inst
end

local function IsTaunted(guy)
  return guy.components.combat and guy.components.combat.target ~= nil
    and guy.components.combat.target:HasTag("defender")
end

local function Taunt(inst)
  print("TAUNT")
  local x, y, z = inst.Transform:GetWorldPosition()
  local entities = TheSim:FindEntities(x, y, z,
    TUNING.MUTANT_BEE_DEFENDER_TAUNT_DIST,
    nil,
    { "mutant", "INLIMBO", "player" },
    { "monster", "insect", "animal", "character" })

  local nearbyplayer = GetPlayer():IsNear(inst, TUNING.MUTANT_BEE_WATCH_DIST)

  for i, e in ipairs(entities) do
    if e.components.combat and e.components.combat.target and not IsTaunted(e) then
      local target = e.components.combat.target
      if target:HasTag("player") or target:HasTag("mutant") then
        e.components.combat:SetTarget(inst)
      end
    end

    if nearbyplayer and e:HasTag("monster") and e.components.combat and not IsTaunted(e) then
      e.components.combat:SetTarget(inst)
    end
  end
end

local function OnDefenderStartCombat(inst)
  Taunt(inst)

  if inst._taunttask then
    inst._taunttask:Cancel()
  end

  inst._taunttask = inst:DoPeriodicTask(0.25, Taunt)
end

local function OnDefenderStopCombat(inst)
  if inst._taunttask then
    inst._taunttask:Cancel()
    inst._taunttask = nil
  end
end

local function CauseFrostBite(inst)
  if not inst.components.highlight then
    inst:AddComponent("highlight")
  end

  inst._frostbite_expire = GetTime() + 4.75
  inst.components.highlight:SetAddColour(Vector3(82/255,115/255,124/255))

  if inst.components.combat then
    inst.components.combat:AddPeriodModifier("frostbite", TUNING.MUTANT_BEE_FROSTBITE_ATK_PERIOD_PENALTY)
  end

  if inst.components.locomotor then
    inst.components.locomotor:AddSpeedModifier_Mult("frostbite", TUNING.MUTANT_BEE_FROSTBITE_SPEED_PENALTY, 5.0)
  end

  inst:DoTaskInTime(5.0,
    function(inst)
      if GetTime() >= inst._frostbite_expire then
        if inst.components.highlight then
          inst.components.highlight:SetAddColour(Vector3(0, 0, 0))
        end

        if inst.components.combat then
          inst.components.combat:RemovePeriodModifier("frostbite")
        end
      end
    end
  )
end

local function OnDefenderAttacked(inst, data)
  local attacker = data and data.attacker

  if not(attacker and attacker.components.locomotor and attacker.components.health
    and not attacker.components.health:IsDead()) then
    return
  end

  if attacker:HasTag("player") then
    return
  end

  CauseFrostBite(attacker)
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

local defenderbeebrain = require "brains/defenderbeebrain"
local function defenderbee()
  local inst = CreateEntity()

  inst.entity:AddTransform()
  inst.entity:AddAnimState()
  inst.entity:AddLightWatcher()
  inst.entity:AddDynamicShadow()
  inst.entity:AddSoundEmitter()

  inst.Transform:SetSixFaced()
  inst.Transform:SetScale(1.4, 1.4, 1.4)

  inst.DynamicShadow:SetSize(1.2, .75)

  MakeAmphibiousCharacterPhysics(inst, 1.5, 0.1)

  inst.AnimState:SetBank("mutantdefenderbee")
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

  inst:AddComponent("health")
  inst.components.health:SetMaxHealth(TUNING.MUTANT_BEE_DEFENDER_HEALTH)

  inst:AddComponent("combat")
  inst.components.combat:SetDefaultDamage(TUNING.MUTANT_BEE_DEFENDER_DAMAGE)
  inst.components.combat:SetAttackPeriod(TUNING.MUTANT_BEE_DEFENDER_ATTACK_PERIOD)
  inst.components.combat:SetRange(TUNING.MUTANT_BEE_DEFENDER_ATTACK_RANGE)
  inst.components.combat:SetRetargetFunction(1, KillerRetarget)
  inst.components.combat.hiteffectsymbol = "mane"

  inst:AddComponent("knownlocations")

  inst:ListenForEvent("attacked", beecommon.OnAttacked)

  MakeSmallBurnableCharacter(inst, "mane")
  MakeSmallFreezableCharacter(inst, "mane")
  inst.components.freezable:SetResistance(2)

  inst:SetStateGraph("SGdefenderbee")
  inst:SetBrain(defenderbeebrain)

  MakeLessNoise(inst)
  inst:DoTaskInTime(0, function(inst) OnInitUpgrade(inst, CheckDefenderUpgrade, 0) end)

  inst:ListenForEvent("newcombattarget", OnDefenderStartCombat)
  StartCheckingTarget(inst, OnDefenderStopCombat)

  inst.sounds = killersounds

  inst.buzzing = true
  inst.EnableBuzz = EnableBuzz
  inst.OnEntityWake = OnWake
  inst.OnEntitySleep = OnSleep

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

STRINGS.MUTANTASSASSINBEE = "Metapis Assassin"
STRINGS.NAMES.MUTANTASSASSINBEE = "Metapis Assassin"
STRINGS.CHARACTERS.GENERIC.DESCRIBE.MUTANTASSASSINBEE = "Seems deadly."

STRINGS.MUTANTDEFENDERBEE = "Metapis Guardian"
STRINGS.NAMES.MUTANTDEFENDERBEE = "Metapis Guardian"
STRINGS.CHARACTERS.GENERIC.DESCRIBE.MUTANTDEFENDERBEE = "Buff and fluffy."


return Prefab("mutantbee", workerbee, assets, prefabs),
  Prefab("mutantkillerbee", killerbee, assets, prefabs),
  Prefab("mutantrangerbee", rangerbee, assets, prefabs),
  Prefab("mutantassassinbee", assassinbee, assets, prefabs),
  Prefab("mutantdefenderbee", defenderbee, assets, prefabs)
