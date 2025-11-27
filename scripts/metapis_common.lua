local hive_defs = require "hive_defs"

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
  if
    inst.components.follower and inst.components.follower.leader ~= nil and
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
  local entities = TheSim:FindEntities(x, y, z, dist, TARGET_MUST_TAGS, TARGET_IGNORE_TAGS, TARGET_MUST_ONE_OF_TAGS)

  local validtargets = {}
  for i, e in ipairs(entities) do
    if
      inst.components.combat:CanTarget(e) and e.components.combat and
        (IsAlly(e.components.combat.target) or IsHostile(e)) and
        e.components.health and
        not e.components.health:IsDead()
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
  local enemies = TheSim:FindEntities(x, y, z, dist, TARGET_MUST_TAGS, TARGET_IGNORE_TAGS, TARGET_MUST_ONE_OF_TAGS)

  if #enemies == 0 then
    return nil
  end

  local lowesthealth = math.huge
  local lowestenemy = nil

  for i, guy in ipairs(enemies) do
    if
      inst.components.combat:CanTarget(guy) and guy.components.combat and
        (IsAlly(guy.components.combat.target) or IsHostile(guy))
     then
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

local function SpawnShadowlings(inst, num_spawn, frenzy)
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

    -- frenzy til death
    if frenzy then
      s.components.debuffable:AddDebuff("metapis_frenzy_buff", "metapis_frenzy_buff")
      s:DoPeriodicTask(
        1,
        function()
          s.components.debuffable:AddDebuff("metapis_frenzy_buff", "metapis_frenzy_buff")
        end
      )
    end
  end
end

local function OnKilledOther(inst, data)
  if data ~= nil and data.victim then
    local victim = data.victim
    if victim:HasTag("shadow") and victim.sanityreward ~= nil then
      local owner = inst:GetOwner()
      if
        owner and owner:HasTag("beemaster") and
          owner.components.skilltreeupdater:IsActivated("zeta_metapimancer_shepherd_1")
       then
        owner.components.sanity:DoDelta(victim.sanityreward * 0.5)
      end
    end
  end
end

local function OnCommonInit(inst)
  if inst.buffed then
    inst:Buff()
  end

  local owner = inst:GetOwner()
  if owner and owner:HasTag("beemaster") then
    if owner.components.skilltreeupdater:IsActivated("zeta_metapis_shadow_2") then
      inst:ListenForEvent(
        "death",
        function(inst)
          if owner.components.skilltreeupdater:IsActivated("zeta_metapis_healer_2") and inst.frenzy_buff then
            SpawnShadowlings(inst, math.random(2, 3), true)
          elseif math.random() <= 0.25 then
            SpawnShadowlings(inst, math.random(2, 3))
          end
        end
      )
    end

    if owner.components.skilltreeupdater:IsActivated("zeta_metapimancer_shepherd_1") then
      inst:AddTag("crazy") -- able to attack shadows, this is server-side
      inst:ListenForEvent("killed", OnKilledOther)
    end

    if owner.components.skilltreeupdater:IsActivated("zeta_metapis_healer_2") then
      inst._frenzy_explode = true
    end
  end
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
  inst.components.combat:ShareTarget(
    attacker,
    SHARE_TARGET_DIST,
    function(dude)
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
    end,
    targetshares,
    {"_combat", "_health", "beemutantminion"}
  )
end

local function getMotherHive(inst)
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
    return nil
  end

  return hive
end

local function OnInitUpgrade(inst, checkupgradefn, retries)
  retries = retries + 1

  if retries >= 5 then
    -- is a homeless minion, e.g. hive/portal destroyed
    if inst:GetOwner() == nil then
      inst:DoTaskInTime(
        math.random(2, 8),
        function()
          inst.components.health:Kill()
        end
      )
    end

    return
  end

  local hive = getMotherHive(inst)
  if not hive then
    inst:DoTaskInTime(
      0.3,
      function(inst)
        OnInitUpgrade(inst, checkupgradefn, retries)
      end
    )
    return
  end

  inst._numbarracks = hive._numbarracks

  local check = checkupgradefn(inst, hive._stage.LEVEL)
  if not check then
    print("check upgrade failed", inst)
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
  if inst.components.follower and inst.components.follower.leader ~= nil and inst.components.follower.leader:IsValid() then
    return inst.components.follower.leader
  end

  -- mother hive or teleportal
  if inst.components.homeseeker and inst.components.homeseeker.home ~= nil and inst.components.homeseeker.home:IsValid() then
    -- mother hive
    if inst.components.homeseeker.home._owner then
      return inst.components.homeseeker.home._owner
    end

    -- both mother hive and teleportal
    if inst.components.homeseeker.home._ownerid then
      for i, player in ipairs(AllPlayers) do
        if player:HasTag("player") and player.userid == inst.components.homeseeker.home._ownerid then
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
  return FindEntity(
    inst,
    10,
    function(guy)
      return not guy.components.health:IsDead() and guy._protectaura and guy:GetOwner() == inst:GetOwner()
    end,
    {"beemutant", "_combat", "_health"},
    {"INLIMBO"},
    {"defender"}
  )
end

local function MakeProtectable(inst)
  if not inst.components.health or not inst.components.combat then
    return
  end

  local oldDoDelta = inst.components.health.DoDelta
  inst.components.health.DoDelta = function(comp, amount, ...)
    if
      amount < 0 and inst.components.health.currenthealth + amount < 0.5 * inst.components.health.maxhealth and
        math.random() <= 0.25
     then
      local owner = inst:GetOwner()
      if
        owner and owner:HasTag("beemaster") and owner.components.skilltreeupdater:IsActivated("zeta_metapis_defender_1")
       then
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

local function BarrackModifier(inst, v)
  local numbarracks = inst._numbarracks or 0

  local barrack_modifier = 0
  if numbarracks > 0 then
    -- add 1, which is the default modifier for having at least 1 barrack
    barrack_modifier = 1 + (math.log(numbarracks) / math.log(1.5))
  end

  local owner = inst:GetOwner()
  local leader_modifier = 1.0
  if owner and owner:IsValid() and owner.components.skilltreeupdater then
    if owner.components.skilltreeupdater:IsActivated("zeta_metapimancer_tyrant_1") then
      leader_modifier = 0.5
    elseif owner.components.skilltreeupdater:IsActivated("zeta_metapimancer_shepherd_1") then
      leader_modifier = 1.25
    end
  end

  return v * (1.0 + TUNING.MUTANT_BEEHIVE_BARRACK_MODIFIER * barrack_modifier) * leader_modifier
end

local function calcBaseDamage(inst)
  local basedamage = inst._basedamagefn(inst)

  if inst.raged_buff ~= nil and inst.raged_buff then
    basedamage = basedamage * TUNING.MUTANT_BEE_RAGED_DAMAGE_BUFF
  end

  return basedamage
end

local function RefreshBaseDamage(inst)
  if inst:IsValid() and inst.components.combat then
    local basedamage = calcBaseDamage(inst)

    inst.components.combat:SetDefaultDamage(BarrackModifier(inst, basedamage))

    -- ranged bee
    if inst.weapon ~= nil then
      inst.weapon.components.weapon:SetDamage(BarrackModifier(inst, basedamage))
    end
  end
end

local function RefreshAtkPeriod(inst)
  if inst:IsValid() and inst.components.combat then
    if inst.frenzy_buff then
      if inst.prefab == "mutantrangerbee" and inst._shouldcircleatk then
        inst.components.combat:SetAttackPeriod(0.5)
      else
        inst.components.combat:SetAttackPeriod(0.1)
      end

      return
    end

    inst.components.combat:SetAttackPeriod(inst._atkperiodfn(inst))
  end
end

local function EnableRageFX(inst)
  local fx = SpawnPrefab("metapis_rage_fx")
  if fx then
    local scale = inst._rage_fx_scale_fn(inst)

    fx.Transform:SetScale(scale, scale, scale)
    fx:Attach(inst)
  end

  return fx
end

local function EnableFrenzyFx(inst)
  local fx = SpawnPrefab("metapis_frenzy_fx")
  if fx then
    fx:Attach(inst, "stinger", inst._frenzy_fx_offset.x, inst._frenzy_fx_offset.y, inst._frenzy_fx_offset.z)
  end

  return fx
end

local function Explode(inst)
  local explode_fx = SpawnPrefab("explode_small")
  if explode_fx ~= nil then
    local x, y, z = inst.Transform:GetWorldPosition()
    explode_fx.Transform:SetPosition(x, 0.5, z)
  end

  local enemies = FindEnemies(inst, 3)
  for i, target in ipairs(enemies) do
    inst.components.combat:DoAttack(target, nil, nil, "frenzy_explode", 2)
  end
end

local function CommonMasterInit(inst, options, checkupgradefn)
  inst:AddComponent("inspectable")
  inst:AddComponent("knownlocations")
  inst:AddComponent("debuffable")

  local hitsymbol = options ~= nil and options.hitsymbol ~= nil and options.hitsymbol or "body"

  inst.components.debuffable:SetFollowSymbol(hitsymbol, 0, 0, 0)

  inst:AddComponent("locomotor") -- locomotor must be constructed before the stategraph
  inst.components.locomotor:EnableGroundSpeedMultiplier(false)
  inst.components.locomotor:SetTriggersCreep(false)

  inst:AddComponent("lootdropper")
  inst.components.lootdropper:AddRandomLoot("honey", 1)
  inst.components.lootdropper:AddRandomLoot("stinger", 4)
  inst.components.lootdropper.numrandomloot = 1
  inst.components.lootdropper.chancerandomloot = 0.5

  if not (options and options.notburnable) then
    MakeSmallBurnableCharacter(inst, hitsymbol, Vector3(0, -1, 1))
  end

  if not (options and options.notfreezable) then
    MakeTinyFreezableCharacter(inst, hitsymbol, Vector3(0, -1, 1))
  end

  inst:AddComponent("health")
  inst:AddComponent("combat")
  inst.components.combat:SetRange(TUNING.BEE_ATTACK_RANGE)
  inst.components.combat.hiteffectsymbol = hitsymbol
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

  -- required
  assert(options ~= nil)
  assert(options.basedamagefn ~= nil)
  assert(options.atkperiodfn ~= nil)
  assert(options.rage_fx_scale_fn ~= nil)
  assert(options.frenzy_fx_offset ~= nil)

  inst._basedamagefn = options.basedamagefn
  inst._atkperiodfn = options.atkperiodfn
  inst._rage_fx_scale_fn = options.rage_fx_scale_fn
  inst._frenzy_fx_offset = options.frenzy_fx_offset

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
  inst.RefreshBaseDamage = RefreshBaseDamage
  inst.RefreshAtkPeriod = RefreshAtkPeriod
  inst.EnableRageFX = EnableRageFX
  inst.EnableFrenzyFx = EnableFrenzyFx
  inst.Explode = Explode

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

local function IsPoisonable(guy)
  return guy and guy:IsValid() and guy.components.health and not guy.components.health:IsDead() and
    not guy:HasTag("player")
end

local function poisoncolor(inst, mr, mg, mb)
  local c_r, c_g, c_b, c_a = inst.AnimState:GetMultColour()

  inst.AnimState:SetMultColour(mr, mg, mb, c_a)
  inst:DoTaskInTime(
    0.2,
    function(inst)
      inst.AnimState:SetMultColour(c_r, c_g, c_b, c_a)
    end
  )
end

local function MakePoisonable(inst)
  if not inst.components.dotable then
    inst:AddComponent("dotable")
  end

  inst.components.dotable:AddSource("single_poison", 1)
  inst.components.dotable:AddSource("crit_poison", 1)
  inst.components.dotable:AddSource("stackable_poison", 20)

  if inst.components.dotable.ontickfn ~= nil then
    return
  end

  inst.components.dotable.ontickfn = function(inst, damaged_sources, all_damage)
    local r, g, b = 0.8, 0.2, 0.8

    if inst._crit_poison_end_time ~= nil and inst._crit_poison_end_time > GetTime() and math.random() <= 0.3 then
      inst.components.dotable:DoDamage("crit_poison", all_damage * 2)

      -- local fx = SpawnPrefab("poison_fx")
      -- if fx ~= nil then
      --   local scale = math.max(inst:GetPhysicsRadius(0.5) * 8, 4.0) -- min 4 to be visible
      --   fx.Transform:SetScale(scale, scale, scale)

      --   if inst.components.combat then
      --     fx.entity:AddFollower():FollowSymbol(inst.GUID, inst.components.combat.hiteffectsymbol, 0, 0, 0)
      --   end
      -- end

      r, g, b = 0.8, 0.2, 0.2
    end

    if #damaged_sources > 0 then
      poisoncolor(inst, r, g, b)
    end
  end
end

local function DoAreaDamage(inst, target, radius)
  if not target:IsValid() then
    return
  end

  inst.components.combat:DoAreaAttack(
    target,
    radius,
    nil,
    function(guy)
      return IsHostile(guy) or (guy.components.combat and IsAlly(guy.components.combat.target))
    end,
    nil,
    {"INLIMBO", "player", "beemutant"}
  )
end

local function DealPoison(inst, target)
  if IsPoisonable(target) then
    MakePoisonable(target)

    local source = "single_poison"
    local basedamage = TUNING.MUTANT_BEE_POISON_DAMAGE
    local numticks = TUNING.MUTANT_BEE_MAX_POISON_TICKS

    local owner = inst:GetOwner()
    if owner and owner:HasTag("beemaster") and owner.components.skilltreeupdater:IsActivated("zeta_metapis_assassin_1") then
      source = "stackable_poison"
      basedamage = TUNING.MUTANT_BEE_POISON_DAMAGE * 0.5
      numticks = TUNING.MUTANT_BEE_STACK_POISON_TICKS
    end

    basedamage = BarrackModifier(inst, basedamage)
    target.components.dotable:Add(source, basedamage, numticks)
  end
end

local function debugtable(t)
  for k, v in pairs(t) do
    print(k, v)
  end
end

local function getChildTokens(inst, basechild, hivetags)
  if not inst.components.container then
    return nil
  end

  local tokens = {}
  for i, item in ipairs(inst.components.container:GetAllItems()) do
    if item and item:HasTag("beemutanttoken") then
      if item.is_base then
        table.insert(tokens, basechild)
      elseif inst:HasSlaveWithTag(hivetags[item.minion_prefab]) then
        table.insert(tokens, item.minion_prefab)
      end
    end
  end

  return tokens, inst.components.container:GetNumSlots()
end

local function calcExpect(hive, basechild, canspawnprefabs, checkchildtags)
  -- init expect
  local expect = {}
  for prefab, v in pairs(checkchildtags) do
    expect[prefab] = 0
  end

  if hive ~= nil and hive.components.container ~= nil then
    local tokens, numslots = getChildTokens(hive, basechild, checkchildtags)

    local totalexpect = 60 -- LCM of (1,2,3,4,5,6), a nice enough number
    local expectPerSlot = totalexpect / numslots
    for i, token in ipairs(tokens) do
      expect[token] = expect[token] + expectPerSlot
    end

    local numRandomTokens = (numslots - #tokens) * expectPerSlot
    for i, prefab in ipairs(canspawnprefabs) do
      expect[prefab] = expect[prefab] + (numRandomTokens / #canspawnprefabs)
    end

    return expect, totalexpect
  end

  local totalexpect = #canspawnprefabs
  expect[basechild] = totalexpect
  for i, prefab in ipairs(canspawnprefabs) do
    if prefab ~= basechild then
      expect[prefab] = 1
      expect[basechild] = expect[basechild] - 1
    end
  end

  return expect, totalexpect
end

local function getcheckchildtags(basechild)
  local res = {
    [basechild] = true
  }

  for i, def in ipairs(hive_defs.HiveDefs) do
    res[def.minion_prefab] = def.hive_tag
  end

  return res
end

local function PickChildPrefab(owner, hive, children, maxchildren, prioritychild)
  -- owner and hive can be nil
  children = children or {}

  local basechild = "mutantkillerbee"
  if owner ~= nil and owner.components.skilltreeupdater:IsActivated("zeta_metapis_mimic_1") then
    basechild = "mutantmimicbee"
  end

  local checkchildtags = getcheckchildtags(basechild)

  local canspawnprefabs = {}
  for prefab, tag in pairs(checkchildtags) do
    if tag == true or (hive ~= nil and hive:HasSlaveWithTag(tag)) then
      table.insert(canspawnprefabs, prefab)
    end
  end

  local totalexpect = #canspawnprefabs

  -- must spawn
  local expect, totalexpect = calcExpect(hive, basechild, canspawnprefabs, checkchildtags)

  -- print("EXPECT: ")
  -- debugtable(expect)
  -- print("CAN SPAWN: ")
  -- debugtable(canspawnprefabs)

  local currentcount = {}
  for i, child in pairs(children) do
    currentcount[child.prefab] = currentcount[child.prefab] or 0

    if child:IsValid() and checkchildtags[child.prefab] ~= nil then
      currentcount[child.prefab] = currentcount[child.prefab] + 1
    end
  end

  -- print("CURRENT COUNT: ")
  -- debugtable(currentcount)

  local function expectedCnt(prefab)
    return math.floor(maxchildren * expect[prefab] / totalexpect)
  end

  local function expectedDiff(prefab)
    return math.max(0, expectedCnt(prefab) - (currentcount[prefab] or 0))
  end

  local topick = {}
  for i, prefab in ipairs(canspawnprefabs) do
    local cnt = currentcount[prefab] or 0
    if cnt < expectedCnt(prefab) then
      table.insert(topick, prefab)
    end
  end

  if #topick == 0 then
    -- if expect cnt is 0, make sure never pick
    for prefab, v in pairs(expect) do
      if v > 0 then
        table.insert(topick, prefab)
      end
    end
  end

  -- print("TO PICK: ")
  -- debugtable(topick)

  -- prioritize summon this child if there is none right now
  if prioritychild ~= nil then
    for i, prefab in ipairs(topick) do
      if prefab == prioritychild then
        if (currentcount[prioritychild] or 0) == 0 then
          return prioritychild
        end
      end
    end
  end

  topick = shuffleArray(topick)

  local chosen = topick[1]
  -- diff between expected count vs current count, cap to 0 to handle negative diff
  local maxdiff = expectedDiff(chosen)
  for i, prefab in ipairs(topick) do
    local diff = expectedDiff(prefab)
    if diff > maxdiff then
      maxdiff = diff
      chosen = prefab
    end
  end

  return chosen
end

local function IsHealable(inst, guy)
  return inst:IsValid() and guy and guy:IsValid() and guy.components.health:IsHurt() and
    not (guy.components.combat and guy.components.combat.target and guy.components.combat.target:HasTag("beemutant")) and -- don't heal bees fighting bees
    inst:GetOwner() == guy:GetOwner() -- nil owner will heal nil owner
end

local HEAL_MUST_TAGS = {"_combat", "_health"}
local HEAL_MUST_NOT_TAGS = {"player", "INLIMBO", "lesserminion"}
local HEAL_MUST_ONE_OF_TAGS = {"beemutantminion"}

local function FindHealingTarget(inst, origin)
  if not origin then
    origin = inst
  end

  local ally =
    FindEntity(
    origin,
    8,
    function(guy)
      return IsHealable(inst, guy)
    end,
    HEAL_MUST_TAGS,
    HEAL_MUST_NOT_TAGS,
    HEAL_MUST_ONE_OF_TAGS
  )

  return ally
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
  DoAreaDamage = DoAreaDamage,
  DealPoison = DealPoison,
  PickChildPrefab = PickChildPrefab,
  FindHealingTarget = FindHealingTarget,
  IsHealable = IsHealable
}
