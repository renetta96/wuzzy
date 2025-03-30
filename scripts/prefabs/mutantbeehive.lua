local hive_common = require "hive_common"

local prefabs =
{
  "mutantbee",
  "mutantkillerbee",
  "mutantdefenderbee",
  "mutantrangerbee",
  "mutantassassinbee",
  "mutantshadowbee",
  "mutanthealerbee",
  "mutantmimicbee",


  "honey",
  "honeycomb",
  "collapse_big",
  "collapse_small",
  "mutantbeehive_lamp",
}


local assets =
{
  Asset("ANIM", "anim/mutantbeehive.zip"),
  Asset("ANIM", "anim/mutantteleportal.zip"),
  Asset("SOUND", "sound/bee.fsb"),
}

local SPEECH =
{
  ATTACK = {
    "SLAY 'EM ALL!!!",
    "ATTACC!!!",
    "TO WARRRR!!!"
  },
  SPAWN = {
    "NO WORKY NO HONEY.",
    "AHHHH FLOWERS!",
    "MORNIN'!"
  },
  IGNITE = {
    "THIS IS FINE.",
    "SHIT ON FIRE YO!",
    "HOT HOT HOT!!!"
  },
  FREEZE = {
    "OUCH! IT'S FREEZING!",
    "BING CHILLING.",
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
    "MOARRRR!"
  },
  WELCOME = {
    "WELCOME BACK, MASTER!",
    "WE ARE GLAD TO SEE YOU!",
    "WE'VE BEEN WAITING FOR YOU!",
    "FINALLY WE'RE UNITED!"
  }
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

local function gettocheck(inst)
  if inst.prefab == 'mutantteleportal' then
    inst = GetSource(inst)
  end

  local owner = inst._owner

  local basechild = "mutantkillerbee"
  if owner and owner:HasTag("beemaster") then
    if owner.components.skilltreeupdater:IsActivated("zeta_metapis_mimic_1") then
      basechild = "mutantmimicbee"
    end
  end


  return {
    mutantdefenderbee = "mutantdefenderhive",
    mutantrangerbee = "mutantrangerhive",
    mutantassassinbee = "mutantassassinhive",
    mutantshadowbee = "mutantshadowhive",
    [basechild] = true,
    mutanthealerbee = "mutanthealerhive",
  }, basechild
end

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
    inst.AnimState:PlayAnimation(inst._stage.HIT_ANIM)
    inst.AnimState:PushAnimation(inst._stage.IDLE_ANIM, true)

    if inst._stage.LEVEL == 3 then
      inst._lamp.AnimState:PlayAnimation("lamp_big_hit")
      inst._lamp.AnimState:PushAnimation("lamp_big", true)
    end
  end
end

local function UnlinkPlayer(inst)
  local owner = inst._owner
  inst._ownerid = nil
  inst._owner = nil

  -- if _hive is already set to something else, do not set to nil
  if owner ~= nil and owner._hive == inst then
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

  inst._lamp:Remove()
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

local function RefreshLight(inst)
  if inst._stage.LEVEL == 3 and
    (not inst.components.freezable:IsFrozen()) and
    (not TheWorld.state.iscaveday)
  then
    inst._lamp.AnimState:SetBloomEffectHandle("shaders/anim.ksh")
    inst._lamp.AnimState:SetLightOverride(0.8)
    inst._lamp.Light:Enable(true)
  else
    inst._lamp.AnimState:ClearBloomEffectHandle()
    inst._lamp.AnimState:SetLightOverride(0.0)
    inst._lamp.Light:Enable(false)
  end
end

local function OnIsCaveDay(inst, isday)
  RefreshLight(inst)

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
  inst.AnimState:PlayAnimation(inst._stage.FROZEN_ANIM, true)
  inst.AnimState:OverrideSymbol("swap_frozen", "frozen", "frozen")

  StopSpawning(inst)

  inst._lamp:Hide()
  RefreshLight(inst)
end

local function OnThaw(inst)
  inst.AnimState:PlayAnimation(inst._stage.FROZEN_LOOP_ANIM, true)
  inst.SoundEmitter:PlaySound("dontstarve/common/freezethaw", "thawing")
  inst.AnimState:OverrideSymbol("swap_frozen", "frozen", "frozen")

  inst._lamp:Hide()
  RefreshLight(inst)
end

local function OnUnFreeze(inst)
  inst.AnimState:PlayAnimation(inst._stage.IDLE_ANIM, true)
  inst.SoundEmitter:KillSound("thawing")
  inst.AnimState:ClearOverrideSymbol("swap_frozen")

  StartSpawning(inst)

  if inst._stage.LEVEL == 3 then
    inst._lamp:Show()
    inst._lamp.AnimState:PlayAnimation("lamp_big", true)

    RefreshLight(inst)
  end
end

local function OnKilled(inst)
  inst:RemoveComponent("childspawner")
  inst.AnimState:PlayAnimation(inst._stage.DEAD_ANIM, true)
  RemovePhysicsColliders(inst)

  inst.SoundEmitter:KillSound("loop")

  inst.SoundEmitter:PlaySound("dontstarve/bee/beehive_destroy")
  inst.components.lootdropper:DropLoot(inst:GetPosition())

  if inst.components.container ~= nil then
    inst.components.container:DropEverything()
  end

  inst._lamp:Remove()
end

local function OnHammered(inst, worker)
  inst:RemoveComponent("childspawner")
  inst.SoundEmitter:KillSound("loop")
  inst.SoundEmitter:PlaySound("dontstarve/bee/beehive_destroy")
  inst.components.lootdropper:DropLoot(inst:GetPosition())

  if inst.components.container ~= nil then
    inst.components.container:DropEverything()
  end

  local collapse = inst._stage.LEVEL >= 2 and "collapse_big" or "collapse_small"
  local fx = SpawnPrefab(collapse)
  fx.Transform:SetPosition(inst.Transform:GetWorldPosition())
  fx:SetMaterial("straw")

  inst:Remove()
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
  if inst.components.container ~= nil then
    inst.components.container:DropEverything()
    inst.components.container:Close()
  end

  if IsValidOwner(inst, worker) then
    inst:Say(SPEECH.HAMMER)
  else
    OnHit(inst, worker, 1)
  end
end

local function IsSlave(inst, slave)
  return slave:IsValid() and slave._ownerid == inst._ownerid
end

local function GetSlaves(inst, moremusttags)
  local x, y, z = inst.Transform:GetWorldPosition()
  local musttags = { "mutantslavehive" }

  if moremusttags ~= nil and type(moremusttags) == "table" then
    for i, tag in ipairs(moremusttags) do
      table.insert(musttags, tag)
    end
  end

  local entities = TheSim:FindEntities(x, y, z,
    TUNING.MUTANT_BEEHIVE_MASTER_SLAVE_DIST,
    { "_combat", "_health" },
    { "INLIMBO", "player" },
    musttags
  )

  local slaves = {}

  for i, e in ipairs(entities) do
    if IsSlave(inst, e) then
      table.insert(slaves, e)
    end
  end

  return slaves
end

-- get utility hives around
local function GetUtils(inst)
  local x, y, z = inst.Transform:GetWorldPosition()

  local entities = TheSim:FindEntities(x, y, z,
    TUNING.MUTANT_BEEHIVE_MASTER_SLAVE_DIST,
    {},
    { "INLIMBO", "player" },
    { "mutantutil" }
  )

  local utils = {}

  for i, e in ipairs(entities) do
    if IsSlave(inst, e) then
      table.insert(utils, e)
    end
  end

  return utils
end

local function GetNumChildrenRegen(inst)
  local barracks = GetSlaves(inst, { "mutantbarrack" })
  local numbarracks = #barracks

  if numbarracks < 1 then
    return 0
  end

  return math.ceil(math.log(numbarracks))
end

local function GetNumChildrenFromSlaves(slaves)
  if not slaves then
    return 0
  end

  local num = 0
  for i, slave in ipairs(slaves) do
    if slave.prefab == "mutantbarrack" then
      num = num + TUNING.MUTANT_BEEHIVE_CHILDREN_PER_BARRACK
    else
      num = num + TUNING.MUTANT_BEEHIVE_CHILDREN_PER_SLAVE
    end
  end

  return num
end

local function OnSlave(inst)
  if inst.components.childspawner then
    local slaves = GetSlaves(inst)

    inst.components.childspawner.maxemergencychildren =
      TUNING.MUTANT_BEEHIVE_DEFAULT_EMERGENCY_BEES
      + (inst._stage.LEVEL - 1) * TUNING.MUTANT_BEEHIVE_DELTA_BEES
      + GetNumChildrenFromSlaves(slaves)
    inst.components.childspawner:TryStopUpdate()
    inst.components.childspawner:StartUpdate()

    local numbarracks = 0
    for i, slave in ipairs(slaves) do
      if slave.prefab == "mutantbarrack" then
          numbarracks = numbarracks + 1
      end
    end


    inst._numbarracks = numbarracks
  end

  local utils = GetUtils(inst)
  inst._container = nil

  for i, util in ipairs(utils) do
    if util.prefab == "mutantcontainer" then
      inst._container = util
    end
  end
end


local function CanSpawn(inst, prefab)
  if inst.prefab == 'mutantteleportal' then
    inst = GetSource(inst)
  end

  if not inst then
    return false
  end

  local tocheck, basechild = gettocheck(inst)

  if tocheck[prefab] == true then
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
  local numprefabs = 0
  local ratio = {}

  local tocheck, basechild = gettocheck(inst)

  for prefab, v in pairs(tocheck) do
    ratio[prefab] = 0
    numprefabs = numprefabs + 1
  end

  ratio[basechild] = numprefabs

  local canspawnprefabs = {basechild}

  for prefab, v in pairs(ratio) do
    if prefab ~= basechild and CanSpawn(inst, prefab) then
      ratio[prefab] = 1
      ratio[basechild] = ratio[basechild] - 1
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

local function SetStage(inst, stage)
	if stage > 1 then
    Shake(inst)
  end

  local scale = inst._stage.SIZE_SCALE
  inst.Transform:SetScale(scale, scale, scale)
  inst.components.health:SetMaxHealth(inst._stage.HEALTH)

  inst.components.childspawner:SetRegenPeriod(TUNING.MUTANT_BEEHIVE_DEFAULT_REGEN_TIME - (stage - 1) * TUNING.MUTANT_BEEHIVE_DELTA_REGEN_TIME)
  inst.components.childspawner:SetSpawnPeriod(TUNING.MUTANT_BEEHIVE_DEFAULT_RELEASE_TIME - (stage - 1) * TUNING.MUTANT_BEEHIVE_DELTA_RELEASE_TIME)
  inst.components.childspawner:SetMaxEmergencyChildren(TUNING.MUTANT_BEEHIVE_DEFAULT_EMERGENCY_BEES + (stage - 1) * TUNING.MUTANT_BEEHIVE_DELTA_BEES)

  local loots = {}
  local numhoneycombs = TUNING.MUTANT_BEEHIVE_UPGRADES_PER_STAGE * (math.min(stage, 2) - 1)
  for i = 1, numhoneycombs do
    table.insert(loots, "honeycomb")
  end

  inst.components.lootdropper:SetLoot(loots)

  if stage == 3 then
    inst._lamp:Show()
    RefreshLight(inst)
  else
    inst._lamp:Hide()
  end
end

local function FindEnemy(inst)
  return FindEntity(inst, TUNING.MUTANT_BEEHIVE_WATCH_DIST,
      function(guy)
        return inst.components.combat:CanTarget(guy)
          and guy.components.combat and guy.components.combat.target
          and (guy.components.combat.target:HasTag("beemaster")
            or guy.components.combat.target:HasTag("beemutant"))
      end,
      { "_combat", "_health" },
      { "beemutant", "INLIMBO", "player" },
      { "monster", "insect", "animal", "character" }
    )
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

local function onwallattacked(inst, wall, data)
  if not data.attacker then
    return
  end

  local attacker = data.attacker

  if not attacker:IsValid() then
    return
  end

  if not(attacker:HasTag("monster") or attacker:HasTag("animal")
    or attacker:HasTag("insect") or attacker:HasTag("character")) then
    return
  end

  if attacker:HasTag("player") or attacker:HasTag("beemutant") then
    return
  end

  if inst.components.childspawner then
    inst.components.childspawner:ReleaseAllChildren(attacker)
  end
end

local function onwallremoved(inst, wall)
  inst:RemoveEventCallback("onremove", inst._onwallattacked, wall)
  inst._watched_walls[wall] = nil
end

local function WatchWalls(inst)
  local x, y, z = inst.Transform:GetWorldPosition()
  local walls = TheSim:FindEntities(x, y, z, TUNING.MUTANT_BEEHIVE_WATCH_DIST,
    { "_combat", "_health" },
    { "INLIMBO" },
    { "wall" }
  )

  for i, wall in ipairs(walls) do
    if not inst._watched_walls[wall] then
      inst:ListenForEvent("attacked", inst._onwallattacked, wall)
      inst:ListenForEvent("onremove", inst._onwallremoved, wall)

      inst._watched_walls[wall] = true
    end
  end
end

local function MakeWatchWalls(inst)
  inst._onwallattacked = function(wall, data)
    onwallattacked(inst, wall, data)
  end

  inst._onwallremoved = function(wall)
    onwallremoved(inst, wall)
  end

  inst._watched_walls = {}


  inst:DoPeriodicTask(10, WatchWalls)
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

local function InheritOwner(inst, origin)
  inst._ownerid = origin._ownerid

  if origin._owner then
    inst._owner = origin._owner
    origin._owner._hive = inst
  end
end

local function CalcSanityAura(inst, observer)
  if inst._ownerid and IsValidOwner(inst, observer) then
    return TUNING.SANITYAURA_SMALL
  end

  return 0
end

local function OnPlayerJoined(inst, player)
  print("PLAYER JOINED HIVE", player)

  local linksuccess = LinkToPlayer(inst, player)

  if not linksuccess then
    -- if the player is the owner, and is not a seamless character (like Wonkey), which means the player despawned and joined using another character
    -- then destroy the mother hive
    if inst._ownerid and player.userid and player.userid == inst._ownerid and (not table.contains(SEAMLESSSWAP_CHARACTERLIST, player.prefab)) then
      print("SAME PLAYER, DIFFERENT CHARACTER, NOT SEAMLESS")
      -- inst:DoTaskInTime(0,
      --   function(inst)
      --     inst.components.lootdropper:DropLoot(inst:GetPosition())
      --     inst:Remove()
      --   end)
    end
  end
end

local function has_valid_container(inst)
  return inst._container and inst._container:IsValid() and inst._container.components.container ~= nil
end

local function GiveHoney(inst)
  if not has_valid_container(inst) then
    return
  end

  local honey = SpawnPrefab("honey")
  inst._container.components.container:GiveItem(honey)
end

local function ConvertPollenToHoney(inst)
  if not has_valid_container(inst) then
    return
  end

  local maxhoneys = TUNING.MUTANT_BEEHIVE_MAX_HONEYS_PER_CYCLE

  for i=1,maxhoneys do
    local numpollens = math.random(
      TUNING.MUTANT_BEEHIVE_NUM_POLLENS_PER_HONEY,
      TUNING.MUTANT_BEEHIVE_NUM_POLLENS_PER_HONEY + 2)
    local has, numfound = inst._container.components.container:Has("zetapollen", numpollens)
    if not has then
      break
    end

    inst._container.components.container:ConsumeByName("zetapollen", numpollens)
    GiveHoney(inst)
  end
end

local function RefreshHoneyArmor(inst)
  if not has_valid_container(inst) then
    return
  end

  local armors = inst._container.components.container:FindItems(
    function(item) return item.prefab and item.prefab == "armor_honey" and item:IsValid() end
  )

  local chunk = 0.2

  for i, armor in ipairs(armors) do
    if armor.components.perishable then
      local percent = armor.components.perishable:GetPercent()

      if percent < 1 - chunk then
        local need = math.ceil((1 - percent) / chunk)
        local has, numfound = inst._container.components.container:Has("honey", need)
        numfound = math.min(numfound, need)

        if numfound > 0 then
          armor.components.perishable:SetPercent(percent + numfound * chunk)
          inst._container.components.container:ConsumeByName("honey", numfound)
        end
      end
    end
  end
end

local function AddHoneyProgress(inst, child)
  if not has_valid_container(inst) then
    return
  end

  local numpollens = 1

  if child then
    numpollens = 1 + inst._stage.LEVEL
  end

  local pollen = SpawnPrefab("zetapollen")
  pollen.components.stackable:SetStackSize(numpollens)
  inst._container.components.container:GiveItem(pollen)
end

local function onchildgoinghome(inst, data)
  if not inst:HasTag("burnt") then
    if data.child and data.child.components.pollinator and data.child.components.pollinator:HasCollectedEnough() then
      AddHoneyProgress(inst, data.child)
    end
  end
end

local function DoGather(inst)
  inst._gathertick = inst._gathertick or 0

  local x, y, z = inst.Transform:GetWorldPosition()
  local entities = TheSim:FindEntities(x, y, z, TUNING.MUTANT_BEEHIVE_WATCH_DIST, { "flower" })
  local numflowers = #entities

  if numflowers >= 5 - (inst._stage.LEVEL - 1) then
    inst._gathertick = inst._gathertick + 1
  end

  -- stage 1: 8 ticks, stage 2: 7 ticks, stage 3: 6 ticks
  local requiredticks = 9 - inst._stage.LEVEL
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

local function OnConstructed(inst, doer)
  local concluded = true
  for i, v in ipairs(CONSTRUCTION_PLANS[inst.prefab] or {}) do
    if inst.components.constructionsite:GetMaterialCount(v.type) < v.amount then
      concluded = false
      break
    end
  end

  if concluded then
    local x,y,z = inst.Transform:GetWorldPosition()
    local new_hive = SpawnPrefab(inst._stage.CONSTRUCT_PRODUCT)
    InheritOwner(new_hive, inst)
    new_hive.Transform:SetPosition(x,y,z)
    inst:Remove()
  end
end

local function OnBuilt(inst, data)
  local builder = data.builder
  if builder and builder:HasTag("player") and builder.prefab == "zeta" then
    inst._ownerid = builder.userid
    LinkToPlayer(inst, builder)
  end
end

local function OnInit(inst)
  inst._lamp = SpawnPrefab("mutantbeehive_lamp")
  inst._lamp.entity:SetParent(inst.entity)

  inst:WatchWorldState("iscaveday", OnIsCaveDay)
  inst:ListenForEvent("enterlight", OnEnterLight)
  inst:ListenForEvent("enterdark", OnEnterDark)
  if TheWorld.state.isday then
    StartSpawning(inst)
  end

  SetStage(inst, inst._stage.LEVEL)
  OnSlave(inst)

  -- On init, emergencychildreninside always start at 0, so fill half the pool for quickstart
  inst.components.childspawner.emergencychildreninside = math.floor(inst.components.childspawner.maxemergencychildren / 2)

  inst:DoPeriodicTask(3, SelfRepair)
  inst:DoPeriodicTask(30, ConvertPollenToHoney)
  inst:DoPeriodicTask(2, OnSlave)
  inst:DoPeriodicTask(30, RefreshHoneyArmor)

  MakeWatchWalls(inst)

  -- compat with old container component, drop everything
  if inst.components.container ~= nil then
    inst.components.container:DropEverything(inst.Transform:GetWorldPosition())
    inst:DoTaskInTime(0, function() inst:RemoveComponent("container") end)
  end

  -- compat with old upgradeable component, drop upgrade materials
  if inst.components.upgradeable ~= nil then
    local x,y,z = inst.Transform:GetWorldPosition()

    if inst.components.upgradeable.stage == 2 then
      local honeycomb = SpawnPrefab("honeycomb")
      honeycomb.components.stackable:SetStackSize(3)
      honeycomb.Transform:SetPosition(x,y,z)
    elseif inst.components.upgradeable.stage == 3 then
      local royal_jelly = SpawnPrefab("royal_jelly")
      royal_jelly.components.stackable:SetStackSize(3)
      royal_jelly.Transform:SetPosition(x,y,z)
    end

    inst:DoTaskInTime(0, function() inst:RemoveComponent("upgradeable") end)
  end
end

local function MakeMotherHive(name, stage_conf)
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
    inst.AnimState:PlayAnimation(stage_conf.IDLE_ANIM, true)

    inst:AddTag("mutantbeehive")
    inst:AddTag("companion")
    inst:AddTag("beemutant")

    inst:AddComponent("talker")
    inst.components.talker.fontsize = 28
    inst.components.talker.font = TALKINGFONT
    inst.components.talker.colour = Vector3(.9, .9, .3)
    inst.components.talker.offset_fn = GetTalkerOffset
    inst.Say = Say
    inst:ListenForEvent("firedamage", onfiredamagefn)
    inst:ListenForEvent("startfiredamage", onfiredamagefn)

    MakeSnowCoveredPristine(inst)

    inst.entity:SetPristine()

    inst._stage = stage_conf

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
    inst.components.childspawner.canemergencyspawn = true
    inst.components.childspawner:SetEmergencyRadius(TUNING.MUTANT_BEEHIVE_EMERGENCY_RADIUS)
    inst.components.childspawner:SetMaxChildren(TUNING.MUTANT_BEEHIVE_BEES)
    inst:ListenForEvent("childgoinghome", onchildgoinghome)

    local oldSpawnChild = inst.components.childspawner.SpawnChild
    local oldSpawnEmergencyChild = inst.components.childspawner.SpawnEmergencyChild
    local oldDoRegen = inst.components.childspawner.DoRegen

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

    inst.components.childspawner.DoRegen = function(comp, ...)
      local result = oldDoRegen(comp, ...)

      if comp.regening then
        if not comp:IsEmergencyFull() then
          comp:AddEmergencyChildrenInside(GetNumChildrenRegen(inst))
        end
      end

      return result
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
    -- inst:ListenForEvent("onburnt", OnBurnt)
    inst:DoPeriodicTask(1, WatchEnemy)
    inst.OnHit = OnHit

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
    inst:AddComponent("container") -- legacy
    inst:AddComponent("upgradeable") -- legacy

    ---------------------

    if stage_conf.LEVEL < 3 then
      inst:AddComponent("constructionsite")
      inst.components.constructionsite:SetConstructionPrefab("construction_container")
      inst.components.constructionsite:SetOnConstructedFn(OnConstructed)
    end

    inst:AddComponent("inspectable")
    inst.incombat = false
    inst.OnEntitySleep = OnEntitySleep
    inst.OnEntityWake = OnEntityWake
    inst.OnSave = hive_common.OnSave
    inst.OnLoad = hive_common.OnLoad
    inst.OnRemoveEntity = OnRemoveEntity
    inst.OnSlave = OnSlave
    inst.InheritOwner = InheritOwner
    inst.CanSpawn = CanSpawn
    inst.GetSlaves = GetSlaves
    inst._onplayerjoined = function(src, player) OnPlayerJoined(inst, player) end
    inst:ListenForEvent("ms_playerjoined", inst._onplayerjoined, TheWorld)
    inst:ListenForEvent("onbuilt", OnBuilt)

    return inst
  end

  return Prefab(name, fn, assets, prefabs)
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
  inst:AddTag("beemutant")

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
  inst.components.childspawner.canemergencyspawn = true
  inst.components.childspawner.emergencychildname = "mutantkillerbee"
  inst.components.childspawner.emergencychildrenperplayer = TUNING.MUTANT_BEEHIVE_EMERGENCY_BEES_PER_PLAYER
  inst.components.childspawner:SetEmergencyRadius(TUNING.MUTANT_BEEHIVE_EMERGENCY_RADIUS)
  inst.components.childspawner:SetMaxChildren(0)
  inst.components.childspawner:SetMaxEmergencyChildren(250) -- effectively no limit, but still put a cap just in case
  inst.components.childspawner:SetRegenPeriod(0.01)
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

  inst.OnSave = hive_common.OnSave
  inst.OnLoad = hive_common.OnLoad
  inst.GetSource = GetSource

  inst:ListenForEvent("onbuilt", hive_common.OnChildBuilt)

  inst:DoTaskInTime(0, MakeWatchWalls)

  return inst
end



STRINGS.MUTANTBEEHIVE = "Metapis Mother Hive"
STRINGS.NAMES.MUTANTBEEHIVE = "Metapis Mother Hive"
STRINGS.CHARACTERS.GENERIC.DESCRIBE.MUTANTBEEHIVE = "\"Apis\" is \"bee\" in Latin."
STRINGS.RECIPE_DESC.MUTANTBEEHIVE = "Starts building your Metapis army."

STRINGS.MUTANTBEEHIVE_LEVEL2 = "Metapis Mother Hive"
STRINGS.NAMES.MUTANTBEEHIVE_LEVEL2 = "Metapis Mother Hive"
STRINGS.CHARACTERS.GENERIC.DESCRIBE.MUTANTBEEHIVE_LEVEL2 = "\"Apis\" is \"bee\" in Latin."

STRINGS.MUTANTBEEHIVE_LEVEL3 = "Metapis Mother Hive"
STRINGS.NAMES.MUTANTBEEHIVE_LEVEL3 = "Metapis Mother Hive"
STRINGS.CHARACTERS.GENERIC.DESCRIBE.MUTANTBEEHIVE_LEVEL3 = "\"Apis\" is \"bee\" in Latin."


STRINGS.MUTANTTELEPORTAL = "Metapis Teleportal"
STRINGS.NAMES.MUTANTTELEPORTAL = "Metapis Teleportal"
STRINGS.CHARACTERS.GENERIC.DESCRIBE.MUTANTTELEPORTAL = "Magical transportation."
STRINGS.RECIPE_DESC.MUTANTTELEPORTAL = "Summons Metapis from Mother Hive."


STRINGS.MUTANTTELEPORTAL = "Metapis Teleportal"
STRINGS.NAMES.MUTANTTELEPORTAL = "Metapis Teleportal"
STRINGS.CHARACTERS.GENERIC.DESCRIBE.MUTANTTELEPORTAL = "Magical transportation."
STRINGS.RECIPE_DESC.MUTANTTELEPORTAL = "Summons Metapis from Mother Hive."

STRINGS.MUTANTCONTAINER = "Metapis Container"
STRINGS.NAMES.MUTANTCONTAINER = "Metapis Container"
STRINGS.CHARACTERS.GENERIC.DESCRIBE.MUTANTCONTAINER = "The swarm's provisions."
STRINGS.RECIPE_DESC.MUTANTCONTAINER = "Stores Mother Hive's products."

return MakeMotherHive("mutantbeehive", {
    SIZE_SCALE = 1.45,
    HEALTH = 700,
    IDLE_ANIM = "cocoon_tiny",
    DEAD_ANIM = "cocoon_tiny_dead",
    HIT_ANIM = "cocoon_tiny_hit",
    FROZEN_ANIM = "frozen_tiny",
    FROZEN_LOOP_ANIM = "frozen_tiny_loop_pst",
    LEVEL = 1,
    CONSTRUCT_PRODUCT = "mutantbeehive_level2"
  }),
  MakeMotherHive("mutantbeehive_level2", {
    SIZE_SCALE = 1.35,
    HEALTH = 1100,
    IDLE_ANIM = "cocoon_medium",
    DEAD_ANIM = "cocoon_medium_dead",
    HIT_ANIM = "cocoon_medium_hit",
    FROZEN_ANIM = "frozen_medium",
    FROZEN_LOOP_ANIM = "frozen_medium_loop_pst",
    LEVEL = 2,
    CONSTRUCT_PRODUCT = "mutantbeehive_level3"
  }),
  MakeMotherHive("mutantbeehive_level3", {
    SIZE_SCALE = 1.45,
    HEALTH = 1500,
    IDLE_ANIM = "cocoon_big",
    DEAD_ANIM = "cocoon_big_dead",
    HIT_ANIM = "cocoon_big_hit",
    FROZEN_ANIM = "frozen_big",
    FROZEN_LOOP_ANIM = "frozen_big_loop_pst",
    LEVEL = 3
  }),
  Prefab("mutantteleportal", teleportal, assets, prefabs),
  MakePlacer("mutantbeehive_placer", "mutantbeehive", "mutantbeehive", "cocoon_tiny", nil, nil, nil, 1.45),
  MakePlacer("mutantteleportal_placer", "mutantteleportal", "mutantteleportal", "idle")
