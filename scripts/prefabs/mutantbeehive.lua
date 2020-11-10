local prefabs =
{
  "mutantbee",
  "mutantkillerbee",
  "honey",
  "honeycomb",
  "mutantbeecocoon",
  "collapse_big",
  "collapse_small"
}

local assets =
{
  Asset("ANIM", "anim/mutantbeehive.zip"),
  Asset("ANIM", "anim/mutantdefenderhive.zip"),
  Asset("ANIM", "anim/mutantassassinhive.zip"),
  Asset("ANIM", "anim/mutantrangerhive.zip"),
  Asset("ANIM", "anim/mutantshadowhive.zip"),
  Asset("ANIM", "anim/mutantteleportal.zip"),
  Asset("SOUND", "sound/bee.fsb"),
  Asset("ANIM", "anim/ui_chest_3x2.zip"),
}

local UPGRADE_STAGES = {
  [1] = {
    SIZE_SCALE = 1.15,
    HEALTH = 700
  },
  [2] = {
    SIZE_SCALE = 1.3,
    HEALTH = 1100
  },
  [3] = {
    SIZE_SCALE = 1.45,
    HEALTH = 1500
  }
}

local SPEECH =
{
  ATTACK = {
    "KILL 'EM ALL!!!",
    "ATTACC!!!",
    "YOU AIN'T MESS WITH US!",
    "ONTO THE BATTLEFIELD!"
  },
  SPAWN = {
    "TO WORK SHALL WE?",
    "AHHHH FLOWERS!",
    "WORK HARD PARTY HARDER!",
    "LET'S START WORKING COMRADES."
  },
  IGNITE = {
    "THIS IS FINE.",
    "HELP US MASTER!!!",
    "SHIT ON FIRE YO!",
    "BRING SOME WATER!"
  },
  FREEZE = {
    "OUCH! IT'S COLD OUT!",
    "JUST CHILLING IN HERE.",
    "BRRRRRR!"
  },
  HAMMER = {
    "WELL IF THAT'S YOUR CHOICE THEN...",
    "BUT... WHY?",
    "IF DOING THIS MAY HELP, THEN JUST DO IT!",
    "AIN'T WE GOOD ENOUGH, MASTER?"
  },
  HIT = {
    "THE HIVE IS UNDER ATTACK!!!",
    "PROTECT THE HIVE!",
    "HOW DARE YOU?",
    "WE WILL KILL YOU INTRUDER!"
  },
  STAGE_ADVANCE = {
    "BIGGER HIVE COME STRONGER BEES.",
    "MORE BEES TO COME.",
    "UNLIMITED POWERRRR!!!"
  },
  UPGRADE = {
    "THANKS, MASTER!",
    "WE ARE GRATEFUL OF THAT!",
    "GIVE US MORE!"
  },
  WELCOME = {
    "WELCOME BACK, MASTER!",
    "WE ARE GLAD TO SEE YOU!",
    "WE'VE BEEN WAITING FOR YOU!",
    "FINALLY WE'RE UNITED!"
  }
}

local function Say(inst, script)
  if not script then
    return
  end

  if type(script) == "string" then
    inst.components.talker:Say(script)
  elseif type(script) == "table" then
    local i = math.random(#script)
    inst.components.talker:Say(script[i])
  end
end

local function GetTalkerOffset(inst)
  return Vector3(0, -400, 0)
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

local function StartSpawning(inst)
  if inst.components.childspawner ~= nil
    and not (inst.components.freezable ~= nil and inst.components.freezable:IsFrozen()) then
    inst:Say(SPEECH.SPAWN)
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
  inst:Say(SPEECH.IGNITE)
  if inst.components.childspawner ~= nil then
    inst.components.childspawner:ReleaseAllChildren()
  end
  inst.SoundEmitter:KillSound("loop")
  DefaultBurnFn(inst)
end

local function onfiredamagefn(inst)
  inst:Say(SPEECH.IGNITE)
end

local function OnFreeze(inst)
  inst:Say(SPEECH.FREEZE)
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
  cocoon:InheritOwner(inst)
  UnlinkPlayer(inst)
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
end

local function OnHammered(inst, worker)
  inst:RemoveComponent("childspawner")
  inst.SoundEmitter:KillSound("loop")
  inst.SoundEmitter:PlaySound("dontstarve/bee/beehive_destroy")
  inst.components.lootdropper:DropLoot(inst:GetPosition())
  SpawnCocoon(inst)

  local collapse = inst.components.upgradeable.stage >= 2 and "collapse_big" or "collapse_small"
  local fx = SpawnPrefab(collapse)
  fx.Transform:SetPosition(inst.Transform:GetWorldPosition())
  fx:SetMaterial("straw")

  inst:Remove()
end

local function OnBurnt(inst)
  -- To make sure a cocoon is still spawned after the hive is burnt
  SpawnCocoon(inst)
end

local function IsValidOwner(inst, owner)
  if not owner then
    return false
  end

  if inst._ownerid then
    return owner.userid and owner.userid == inst._ownerid
      and owner.prefab == 'zeta'
      and not (owner._hive and owner._hive ~= inst)
  end

  return false
end

local function OnHit(inst, attacker, damage)
  if damage ~= nil then
    if not IsValidOwner(inst, attacker) then
      inst:Say(SPEECH.HIT)
    else
      inst:Say(SPEECH.HAMMER)
    end
  end

  if inst.components.childspawner ~= nil and not IsValidOwner(inst, attacker) then
    inst.components.childspawner:ReleaseAllChildren(attacker)
  end
  if not inst.components.health:IsDead() then
    Shake(inst)
  end
end

local function OnWork(inst, worker, workleft)
  if IsValidOwner(inst, worker) then
    inst:Say(SPEECH.HAMMER)
  else
    OnHit(inst, worker, 1)
  end
end

local function IsSlave(inst, slave)
  return slave:IsValid() and slave._ownerid == inst._ownerid
end

local function GetSlaves(inst)
  local x, y, z = inst.Transform:GetWorldPosition()
  local entities = TheSim:FindEntities(x, y, z,
    TUNING.MUTANT_BEEHIVE_MASTER_SLAVE_DIST,
    { "_combat", "_health" },
    { "INLIMBO", "player" },
    { "mutantslavehive" }
  )

  local slaves = {}

  for i, e in ipairs(entities) do
    if IsSlave(inst, e) then
      table.insert(slaves, e)
    end
  end

  return slaves
end

local function OnSlave(inst)
  if inst.components.childspawner then
    local slaves = GetSlaves(inst)
    inst.components.childspawner.maxemergencychildren =
      TUNING.MUTANT_BEEHIVE_DEFAULT_EMERGENCY_BEES
      + (inst.components.upgradeable.stage - 1) * TUNING.MUTANT_BEEHIVE_DELTA_BEES
      + #slaves * TUNING.MUTANT_BEEHIVE_CHILDREN_PER_SLAVE
  end
end

local tocheck = {
  mutantdefenderbee = "mutantdefenderhive",
  mutantrangerbee = "mutantrangerhive",
  mutantassassinbee = "mutantassassinhive",
  mutantshadowbee = "mutantshadowhive",
  mutantkillerbee = true
}

local function GetSource(inst)
  if not inst._ownerid then
    return nil
  end

  for i, player in ipairs(AllPlayers) do
    if player:HasTag('player') and player.userid == inst._ownerid then
      return player._hive
    end
  end

  return nil
end

local function CanSpawn(inst, prefab)
  if inst.prefab == 'mutantteleportal' then
    inst = GetSource(inst)
  end

  if not inst then
    return false
  end

  if prefab == "mutantkillerbee" then
    return true
  end

  if not tocheck[prefab] then
    return false
  end

  local hive = FindEntity(inst, TUNING.MUTANT_BEEHIVE_MASTER_SLAVE_DIST,
    function(guy) return IsSlave(inst, guy) end,
    { "_combat", "_health" },
    { "INLIMBO", "player" },
    { tocheck[prefab] }
  )

  if hive then
    return true
  end

  return false
end

local function PickChildPrefab(inst)
  local numprefabs = 5
  local ratio = {
    mutantkillerbee = numprefabs,
    mutantdefenderbee = 0,
    mutantrangerbee = 0,
    mutantassassinbee = 0,
    mutantshadowbee = 0
  }

  local canspawnprefabs = {"mutantkillerbee"}

  for prefab, v in pairs(ratio) do
    if prefab ~= "mutantkillerbee" and CanSpawn(inst, prefab) then
      ratio[prefab] = 1
      ratio["mutantkillerbee"] = ratio["mutantkillerbee"] - 1
      table.insert(canspawnprefabs, prefab)
    end
  end

  local currentcount = {}
  for k,v in pairs(ratio) do
    currentcount[k] = 0
  end

  local total = 0

  if inst.components.childspawner then
    for child, c in pairs(inst.components.childspawner.emergencychildrenoutside) do
      if child:IsValid() and tocheck[child.prefab] then
        currentcount[child.prefab] = currentcount[child.prefab] + 1
        total = total + 1
      end
    end
  end

  local prefabstopick = {}

  if total > 0 then
    for prefab, cnt in pairs(currentcount) do
      if cnt / total < ratio[prefab] / numprefabs then
        table.insert(prefabstopick, prefab)
      end
    end
  end

  if #prefabstopick == 0 then
    prefabstopick = canspawnprefabs
  end

  return prefabstopick[math.random(#prefabstopick)]
end

-- /* Upgrade
local function OnUpgrade(inst)
  inst:Say(SPEECH.UPGRADE)
  Shake(inst)
end

local function SetStage(inst, stage)
	if stage > 1 then
    Shake(inst)
  end

  local scale = UPGRADE_STAGES[stage].SIZE_SCALE
  inst.Transform:SetScale(scale, scale, scale)
  inst.components.health:SetMaxHealth(UPGRADE_STAGES[stage].HEALTH)

  inst.components.childspawner:SetRegenPeriod(TUNING.MUTANT_BEEHIVE_DEFAULT_REGEN_TIME - (stage - 1) * TUNING.MUTANT_BEEHIVE_DELTA_REGEN_TIME)
  inst.components.childspawner:SetSpawnPeriod(TUNING.MUTANT_BEEHIVE_DEFAULT_RELEASE_TIME - (stage - 1) * TUNING.MUTANT_BEEHIVE_DELTA_RELEASE_TIME)
  inst.components.childspawner:SetMaxEmergencyChildren(TUNING.MUTANT_BEEHIVE_DEFAULT_EMERGENCY_BEES + (stage - 1) * TUNING.MUTANT_BEEHIVE_DELTA_BEES)

  inst.components.upgradeable:SetStage(stage)

  local loots = {}
  local numhoneycombs = TUNING.MUTANT_BEEHIVE_UPGRADES_PER_STAGE * (math.min(stage, 2) - 1)
  for i = 1, numhoneycombs do
    table.insert(loots, "honeycomb")
  end

  inst.components.lootdropper:SetLoot(loots)
  OnSlave(inst)
end

local function OnStageAdvance(inst)
  inst:Say(SPEECH.STAGE_ADVANCE)

  SetStage(inst, inst.components.upgradeable.stage)

  return true
end
-- Upgrade */

local function FindEnemy(inst)
  local nearbyplayer = GetClosestInstWithTag("beemaster", inst, TUNING.MUTANT_BEEHIVE_WATCH_DIST)

  local enemy = (nearbyplayer and
    FindEntity(inst, TUNING.MUTANT_BEEHIVE_WATCH_DIST,
      function(guy)
        return inst.components.combat:CanTarget(guy)
      end,
      { "_combat", "_health" },
      { "insect", "INLIMBO", "player" },
      { "monster" }
    )) or
    FindEntity(inst, TUNING.MUTANT_BEEHIVE_WATCH_DIST,
      function(guy)
        return inst.components.combat:CanTarget(guy)
          and guy.components.combat and guy.components.combat.target
          and (guy.components.combat.target:HasTag("beemaster")
            or guy.components.combat.target:HasTag("mutant"))
      end,
      { "_combat", "_health" },
      { "mutant", "INLIMBO", "player" },
      { "monster", "insect", "animal", "character" }
    )

  return enemy
end

local function WatchEnemy(inst)
  local enemy = FindEnemy(inst)

  if enemy then
    inst:Say(SPEECH.ATTACK)
    inst.incombat = true
    OnHit(inst, enemy)
  else
    inst.incombat = false
  end
end

local function SelfRepair(inst)
  if inst and inst.components.childspawner and inst.components.health then
    if not inst.components.health:IsDead() then
      local numfixers = inst.components.childspawner.childreninside + inst.components.childspawner.emergencychildreninside
      local recover = TUNING.MUTANT_BEEHIVE_RECOVER_PER_CHILD * numfixers
      inst.components.health:DoDelta(recover, true, "self_repair")

      local slaves = GetSlaves(inst)
      for i, slave in ipairs(slaves) do
        if slave.components.health and not slave.components.health:IsDead() then
          slave.components.health:DoDelta(recover, true, "self_repair")
        end
      end
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

local function LinkToPlayer(inst, player)
  if IsValidOwner(inst, player) then
    inst:Say(SPEECH.WELCOME)
    inst._ownerid = player.userid
    inst._owner = player
    player._hive = inst
    return true
  end

  return false
end

local function InheritOwner(inst, cocoon)
  inst._ownerid = cocoon._ownerid
  if cocoon._owner then
    inst._owner = cocoon._owner
    cocoon._owner._hive = inst
  end
end

local function CalcSanityAura(inst, observer)
  if inst._ownerid and IsValidOwner(inst, observer) then
    return TUNING.SANITYAURA_SMALL
  end

  return 0
end

local function OnSave(inst, data)
  if inst._ownerid then
    data._ownerid = inst._ownerid
  end

  if inst._gathertick then
    data._gathertick = inst._gathertick
  end
end

local function OnPlayerJoined(inst, player)
  print("PLAYER JOINED HIVE", player)

  local linksuccess = LinkToPlayer(inst, player)

  if not linksuccess then
    if inst._ownerid and player.userid and player.userid == inst._ownerid then
      print("SAME PLAYER, DIFFERENT CHARACTER")
      inst:DoTaskInTime(0,
        function(inst)
          inst.components.lootdropper:DropLoot(inst:GetPosition())
          inst:Remove()
        end)
    end
  end
end

local function OnLoad(inst, data)
  if data and data._ownerid then
    inst._ownerid = data._ownerid
  end

  if data and data._gathertick then
    inst._gathertick = data._gathertick
  end
end

local function GiveHoney(inst)
  if not inst.components.container then
    return
  end

  local honey = SpawnPrefab("honey")
  inst.components.container:GiveItem(honey)
end

local function ConvertPollenToHoney(inst)
  if not inst.components.container then
    return
  end

  local maxhoneys = TUNING.MUTANT_BEEHIVE_MAX_HONEYS_PER_CYCLE

  for i=1,maxhoneys do
    local numpollens = math.random(
      TUNING.MUTANT_BEEHIVE_NUM_POLLENS_PER_HONEY,
      TUNING.MUTANT_BEEHIVE_NUM_POLLENS_PER_HONEY + 1)
    local has, numfound = inst.components.container:Has("zetapollen", numpollens)
    if not has then
      break
    end

    inst.components.container:ConsumeByName("zetapollen", numpollens)
    GiveHoney(inst)
  end
end

local function OnInit(inst)
  inst:WatchWorldState("iscaveday", OnIsCaveDay)
  inst:ListenForEvent("enterlight", OnEnterLight)
  inst:ListenForEvent("enterdark", OnEnterDark)
  if TheWorld.state.isday then
    StartSpawning(inst)
  end

  SetStage(inst, inst.components.upgradeable.stage)

  inst:DoPeriodicTask(3, SelfRepair)
  inst:DoPeriodicTask(60, ConvertPollenToHoney)
  inst:DoPeriodicTask(2, OnSlave)
end

local function onopen(inst)
    if not inst:HasTag("burnt") then
        inst.SoundEmitter:PlaySound("dontstarve/wilson/chest_open")
    end
end

local function onclose(inst)
    if not inst:HasTag("burnt") then
        inst.SoundEmitter:PlaySound("dontstarve/wilson/chest_close")
    end
end

local function AddHoneyProgress(inst)
  if not inst.components.container then
    return
  end

  local pollen = SpawnPrefab("zetapollen")
  inst.components.container:GiveItem(pollen)
end

local function itemtestfn(inst, item, slot)
  return item and item.prefab and (item.prefab == "honey" or item.prefab == "zetapollen")
end

local function onchildgoinghome(inst, data)
  if not inst:HasTag("burnt") then
    if data.child and data.child.components.pollinator and data.child.components.pollinator:HasCollectedEnough() then
      AddHoneyProgress(inst)
    end
  end
end

local function DoGather(inst)
  if not inst.components.upgradeable then
    return
  end

  inst._gathertick = inst._gathertick or 0

  local x, y, z = inst.Transform:GetWorldPosition()
  local entities = TheSim:FindEntities(x, y, z, TUNING.MUTANT_BEEHIVE_WATCH_DIST, { "flower" })
  local numflowers = #entities

  if numflowers >= 5 - (inst.components.upgradeable.stage - 1) then
    inst._gathertick = inst._gathertick + 1
  end

  -- stage 1: 8 ticks, stage 2: 7 ticks, stage 3: 6 ticks
  local requiredticks = 9 - inst.components.upgradeable.stage
  if inst._gathertick >= requiredticks then
    inst._gathertick = inst._gathertick - requiredticks
    AddHoneyProgress(inst)
  end
end

local function StartBackgroundGatherTask(inst)
  if inst._gathertask == nil then
    inst._gathertask = inst:DoPeriodicTask(10, DoGather)
  end
end

local function StopBackgroundGatherTask(inst)
  if inst._gathertask then
    inst._gathertask:Cancel()
    inst._gathertask = nil
  end
end

local function OnEntityWake(inst)
  inst.SoundEmitter:PlaySound("dontstarve/bee/bee_hive_LP", "loop")
  StopBackgroundGatherTask(inst)
end

local function OnEntitySleep(inst)
  inst.SoundEmitter:KillSound("loop")
  StartBackgroundGatherTask(inst)
end

local function canupgrade(inst, obj, performer)
	if not performer or not performer:HasTag("beemaster") then
		return false
	end

	if inst.components.upgradeable.stage == 1 and obj.prefab ~= "honeycomb" then
		return false
	end

	if inst.components.upgradeable.stage == 2 and obj.prefab ~= "royal_jelly" then
		return false
	end

	return true
end

local function fn()
  local inst = CreateEntity()

  inst.entity:AddTransform()
  inst.entity:AddAnimState()
  inst.entity:AddSoundEmitter()
  inst.entity:AddMiniMapEntity()
  inst.entity:AddNetwork()
  inst.entity:AddLightWatcher()

  MakeObstaclePhysics(inst, 1)

  inst.MiniMapEntity:SetIcon("mutantbeehive.tex")

  inst.AnimState:SetBank("mutantbeehive")
  inst.AnimState:SetBuild("mutantbeehive")
  inst.AnimState:PlayAnimation("cocoon_small", true)

  inst:AddTag("mutantbeehive")
  inst:AddTag("companion")
  inst:AddTag("mutant")

  ---------------------------
  inst:AddComponent("talker")
  inst.components.talker.fontsize = 28
  inst.components.talker.font = TALKINGFONT
  inst.components.talker.colour = Vector3(.9, .9, .3)
  inst.components.talker.offset_fn = GetTalkerOffset
  inst.Say = Say
  inst:ListenForEvent("firedamage", onfiredamagefn)
  inst:ListenForEvent("startfiredamage", onfiredamagefn)
  ---------------------------

  MakeSnowCoveredPristine(inst)

  inst.entity:SetPristine()

  if not TheWorld.ismastersim then
    return inst
  end

  -------------------
  inst:AddComponent("health")

  -------------------
  inst:AddComponent("childspawner")
  inst.components.childspawner.allowwater = true
  inst.components.childspawner.allowboats = true
  inst.components.childspawner.childname = "mutantbee"
  inst.components.childspawner.emergencychildname = "mutantkillerbee"
  inst.components.childspawner.emergencychildrenperplayer = TUNING.MUTANT_BEEHIVE_EMERGENCY_BEES_PER_PLAYER
  inst.components.childspawner:SetEmergencyRadius(TUNING.MUTANT_BEEHIVE_EMERGENCY_RADIUS)
  inst.components.childspawner:SetMaxChildren(TUNING.MUTANT_BEEHIVE_BEES)
  inst:ListenForEvent("childgoinghome", onchildgoinghome)

  local oldSpawnChild = inst.components.childspawner.SpawnChild
  local oldSpawnEmergencyChild = inst.components.childspawner.SpawnEmergencyChild
  inst.components.childspawner.SpawnChild = function(comp, target, prefab, ...)
    local newprefab = prefab
    if target ~= nil then
      newprefab = PickChildPrefab(inst)
    end
    return oldSpawnChild(comp, target, newprefab, ...)
  end

  inst.components.childspawner.SpawnEmergencyChild = function(comp, target, prefab, ...)
    local newprefab = PickChildPrefab(inst)
    return oldSpawnEmergencyChild(comp, target, newprefab, ...)
  end

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
  inst:DoPeriodicTask(1, WatchEnemy)
  inst.OnHit = OnHit

  ---------------------

  inst:AddComponent("upgradeable")
  inst.components.upgradeable.onupgradefn = OnUpgrade
  inst.components.upgradeable.onstageadvancefn = OnStageAdvance
  inst.components.upgradeable.upgradesperstage = TUNING.MUTANT_BEEHIVE_UPGRADES_PER_STAGE
  local oldUpgrade = inst.components.upgradeable.Upgrade
  inst.components.upgradeable.Upgrade = function(comp, obj, upgrade_performer)
  	if not canupgrade(comp.inst, obj, upgrade_performer) then return false end
  	return oldUpgrade(comp, obj, upgrade_performer)
	end

  ---------------------
  inst:AddComponent("workable")
  inst.components.workable:SetWorkAction(ACTIONS.HAMMER)
  inst.components.workable:SetWorkLeft(5)
  inst.components.workable:SetOnFinishCallback(OnHammered)
  inst.components.workable:SetOnWorkCallback(OnWork)

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
  inst:AddComponent("container")
  inst.components.container.itemtestfn = itemtestfn
  inst.components.container:WidgetSetup("mutantbeehive")
  inst.components.container.onopenfn = onopen
  inst.components.container.onclosefn = onclose

  ---------------------

  inst:AddComponent("inspectable")
  inst.incombat = false
  inst.OnEntitySleep = OnEntitySleep
  inst.OnEntityWake = OnEntityWake
  inst.OnSave = OnSave
  inst.OnLoad = OnLoad
  inst.OnRemoveEntity = OnRemoveEntity
  inst.OnSlave = OnSlave
  inst.InheritOwner = InheritOwner
  inst.CanSpawn = CanSpawn
  inst.GetSlaves = GetSlaves
  inst._onplayerjoined = function(src, player) OnPlayerJoined(inst, player) end
  inst:ListenForEvent("ms_playerjoined", inst._onplayerjoined, TheWorld)

  return inst
end

local function OnSlaveHammered(inst, worker)
  inst.SoundEmitter:PlaySound("dontstarve/bee/beehive_destroy")
  inst.components.lootdropper:DropLoot(inst:GetPosition())

  local fx = SpawnPrefab("collapse_small")
  fx.Transform:SetPosition(inst.Transform:GetWorldPosition())
  fx:SetMaterial("straw")

  inst:Remove()
end

local function SetOwner(inst, owner)
  if owner and owner:HasTag("player") and owner.prefab == 'zeta' then
    inst._ownerid = owner.userid
  end
end

local function onbuilt(inst, data)
  local builder = data.builder
  SetOwner(inst, builder)
end

local function CheckMaster(inst)
  if not inst._ownerid then
    OnSlaveHammered(inst)
    return
  end
end

local function OnSlaveKilled(inst)
  inst.AnimState:PlayAnimation("dead", true)
  RemovePhysicsColliders(inst)

  inst.SoundEmitter:KillSound("loop")

  inst.SoundEmitter:PlaySound("dontstarve/bee/beehive_destroy")
  inst.components.lootdropper:DropLoot(inst:GetPosition())
end

local function OnSlaveHit(inst)
  if not inst.components.health:IsDead() then
    inst.SoundEmitter:PlaySound("dontstarve/bee/beehive_hit")
    inst.AnimState:PlayAnimation("hit")
    inst.AnimState:PushAnimation("idle", true)
  end
end

local function commonslavefn(bank, build, tags, mapicon)
  local inst = CreateEntity()

  inst.entity:AddTransform()
  inst.entity:AddAnimState()
  inst.entity:AddSoundEmitter()
  inst.entity:AddMiniMapEntity()
  inst.entity:AddNetwork()

  MakeObstaclePhysics(inst, 1)

  inst.MiniMapEntity:SetIcon(mapicon)

  inst.AnimState:SetBank(bank)
  inst.AnimState:SetBuild(build)
  inst.AnimState:PlayAnimation("idle", true)

  inst:AddTag("companion")
  inst:AddTag("mutantslavehive")
  inst:AddTag("mutant")
  for i, v in ipairs(tags) do
    inst:AddTag(v)
  end

  MakeSnowCoveredPristine(inst)

  inst.entity:SetPristine()

  if not TheWorld.ismastersim then
    return inst
  end

  -------------------
  inst:AddComponent("health")
  inst.components.health:SetMaxHealth(400)

  ---------------------
  MakeLargeBurnable(inst)
  ---------------------

  ---------------------

  inst:AddComponent("combat")
  inst.components.combat:SetOnHit(OnSlaveHit)

  ---------------------

  inst:AddComponent("workable")
  inst.components.workable:SetWorkAction(ACTIONS.HAMMER)
  inst.components.workable:SetWorkLeft(5)
  inst.components.workable:SetOnFinishCallback(OnSlaveHammered)

  ---------------------
  inst:AddComponent("lootdropper")

  ---------------------
  MakeLargePropagator(inst)
  MakeSnowCovered(inst)

  inst:AddComponent("inspectable")
  inst.OnSave = OnSave
  inst.OnLoad = OnLoad
  inst:ListenForEvent("death", OnSlaveKilled)
  inst:ListenForEvent("onbuilt", onbuilt)
  inst:DoPeriodicTask(5, CheckMaster)

  return inst
end

local function defenderhive()
  local inst = commonslavefn("mutantdefenderhive", "mutantdefenderhive", {"mutantdefenderhive"}, "mutantdefenderhive.tex")
  return inst
end

local function rangerhive()
  local inst = commonslavefn("mutantrangerhive", "mutantrangerhive", {"mutantrangerhive"}, "mutantrangerhive.tex")
  return inst
end

local function assassinhive()
  local inst = commonslavefn("mutantassassinhive", "mutantassassinhive", {"mutantassassinhive"}, "mutantassassinhive.tex")
  return inst
end

local function shadowhive()
  local inst = commonslavefn("mutantshadowhive", "mutantshadowhive", {"mutantshadowhive"}, "mutantshadowhive.tex")
  return inst
end

local function onteleportback(inst)
  local source = GetSource(inst)

  if source and source.components.childspawner then
    source.components.childspawner:AddEmergencyChildrenInside(1)
  end
end

local function WatchEnemyTeleportal(inst)
  local enemy = FindEnemy(inst)

  if enemy then
    inst.components.childspawner:ReleaseAllChildren(enemy)
  end
end

local function onteleporthammered(inst)
  if inst.components.burnable ~= nil and inst.components.burnable:IsBurning() then
    inst.components.burnable:Extinguish()
  end
  inst.components.lootdropper:DropLoot()
  local fx = SpawnPrefab("collapse_small")
  fx.Transform:SetPosition(inst.Transform:GetWorldPosition())
  fx:SetMaterial("straw")
  inst:Remove()
end

local function teleportal()
  local inst = CreateEntity()

  inst.entity:AddTransform()
  inst.entity:AddAnimState()
  inst.entity:AddSoundEmitter()
  inst.entity:AddMiniMapEntity()
  inst.entity:AddNetwork()

  MakeObstaclePhysics(inst, 0.5)

  inst.MiniMapEntity:SetIcon("mutantteleportal.tex")

  inst.AnimState:SetBank("mutantteleportal")
  inst.AnimState:SetBuild("mutantteleportal")
  inst.AnimState:PlayAnimation("idle", true)

  inst:AddTag("mutantteleportal")

  ---------------------------

  MakeSnowCoveredPristine(inst)

  inst.entity:SetPristine()

  if not TheWorld.ismastersim then
    return inst
  end

  -------------------

  inst:AddComponent("childspawner")
  inst.components.childspawner.allowwater = true
  inst.components.childspawner.allowboats = true
  inst.components.childspawner.emergencychildname = "mutantkillerbee"
  inst.components.childspawner.emergencychildrenperplayer = TUNING.MUTANT_BEEHIVE_EMERGENCY_BEES_PER_PLAYER
  inst.components.childspawner:SetEmergencyRadius(TUNING.MUTANT_BEEHIVE_EMERGENCY_RADIUS)
  inst.components.childspawner:SetMaxChildren(0)
  inst.components.childspawner:SetMaxEmergencyChildren(5)
  inst.components.childspawner:SetRegenPeriod(5)
  inst:ListenForEvent("childgoinghome", onteleportback)

  local oldSpawnEmergencyChild = inst.components.childspawner.SpawnEmergencyChild
  inst.components.childspawner.SpawnEmergencyChild = function(comp, target, prefab, ...)
    local source = GetSource(inst)

    if not source then
      return
    end

    local newprefab = PickChildPrefab(inst)
    local child = oldSpawnEmergencyChild(comp, target, newprefab, ...)

    if child ~= nil then
      source.components.childspawner.emergencychildreninside = source.components.childspawner.emergencychildreninside - 1
    end

    return child
  end

  local oldCanEmergencySpawn = inst.components.childspawner.CanEmergencySpawn
  inst.components.childspawner.CanEmergencySpawn = function(comp)
    local source = GetSource(inst)

    if source and source:IsValid() and
      source.components.childspawner and
      source.components.childspawner.emergencychildreninside > 0 then
        return oldCanEmergencySpawn(comp)
    end

    return false
  end

  inst:AddComponent("combat")

  inst:DoPeriodicTask(1, WatchEnemyTeleportal)

  ---------------------
  MakeLargeBurnable(inst)
  ---------------------

  ---------------------
  inst:AddComponent("workable")
  inst.components.workable:SetWorkAction(ACTIONS.HAMMER)
  inst.components.workable:SetWorkLeft(5)
  inst.components.workable:SetOnFinishCallback(onteleporthammered)

  ---------------------
  inst:AddComponent("lootdropper")

  ---------------------
  MakeLargePropagator(inst)
  MakeSnowCovered(inst)

  ---------------------

  inst:AddComponent("inspectable")

  inst.OnSave = OnSave
  inst.OnLoad = OnLoad
  inst.GetSource = GetSource

  inst:ListenForEvent("onbuilt", onbuilt)

  return inst
end

STRINGS.MUTANTBEEHIVE = "Metapis Mother Hive"
STRINGS.NAMES.MUTANTBEEHIVE = "Metapis Mother Hive"
STRINGS.CHARACTERS.GENERIC.DESCRIBE.MUTANTBEEHIVE = "\"Apis\" is the Latin word for \"bee\"."

STRINGS.MUTANTDEFENDERHIVE = "Metapis Guardian Hive"
STRINGS.NAMES.MUTANTDEFENDERHIVE = "Metapis Guardian Hive"
STRINGS.CHARACTERS.GENERIC.DESCRIBE.MUTANTDEFENDERHIVE = "Why does it have tusks?"
STRINGS.RECIPE_DESC.MUTANTDEFENDERHIVE = "Adds Metapis Guardian to Mother Hive."

STRINGS.MUTANTRANGERHIVE = "Metapis Ranger Hive"
STRINGS.NAMES.MUTANTRANGERHIVE = "Metapis Ranger Hive"
STRINGS.CHARACTERS.GENERIC.DESCRIBE.MUTANTRANGERHIVE = "Looks like an ancient symbol."
STRINGS.RECIPE_DESC.MUTANTRANGERHIVE = "Adds Metapis Ranger to Mother Hive."

STRINGS.MUTANTASSASSINHIVE = "Metapis Assassin Hive"
STRINGS.NAMES.MUTANTASSASSINHIVE = "Metapis Assassin Hive"
STRINGS.CHARACTERS.GENERIC.DESCRIBE.MUTANTASSASSINHIVE = "Spiky."
STRINGS.RECIPE_DESC.MUTANTASSASSINHIVE = "Adds Metapis Assassin to Mother Hive."

STRINGS.MUTANTSHADOWHIVE = "Metapis Shadow Hive"
STRINGS.NAMES.MUTANTSHADOWHIVE = "Metapis Shadow Hive"
STRINGS.CHARACTERS.GENERIC.DESCRIBE.MUTANTSHADOWHIVE = "It's made from ancient technology."
STRINGS.RECIPE_DESC.MUTANTSHADOWHIVE = "Adds Metapis Shadow to Mother Hive."

STRINGS.MUTANTTELEPORTAL = "Metapis Teleportal"
STRINGS.NAMES.MUTANTTELEPORTAL = "Metapis Teleportal"
STRINGS.CHARACTERS.GENERIC.DESCRIBE.MUTANTTELEPORTAL = "Magical transportation."
STRINGS.RECIPE_DESC.MUTANTTELEPORTAL = "Summons Metapis from Mother Hive."

return Prefab("mutantbeehive", fn, assets, prefabs),
  Prefab("mutantdefenderhive", defenderhive, assets, prefabs),
  MakePlacer("mutantdefenderhive_placer", "mutantdefenderhive", "mutantdefenderhive", "idle"),
  Prefab("mutantrangerhive", rangerhive, assets, prefabs),
  MakePlacer("mutantrangerhive_placer", "mutantrangerhive", "mutantrangerhive", "idle"),
  Prefab("mutantassassinhive", assassinhive, assets, prefabs),
  MakePlacer("mutantassassinhive_placer", "mutantassassinhive", "mutantassassinhive", "idle"),
  Prefab("mutantshadowhive", shadowhive, assets, prefabs),
  MakePlacer("mutantshadowhive_placer", "mutantshadowhive", "mutantshadowhive", "idle"),
  Prefab("mutantteleportal", teleportal, assets, prefabs),
  MakePlacer("mutantteleportal_placer", "mutantteleportal", "mutantteleportal", "idle")
