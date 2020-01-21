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
  Asset("ANIM", "anim/mutantbeehive.zip"), -- New anim
  Asset("SOUND", "sound/bee.fsb"),
  Asset("ANIM", "anim/ui_chest_3x2.zip"),
}

local UPGRADE_STAGES = {
  [1] = {
    SIZE_SCALE = 1.0,
    HEALTH = 700
  },
  [2] = {
    SIZE_SCALE = 1.15,
    HEALTH = 1100
  },
  [3] = {
    SIZE_SCALE = 1.3,
    HEALTH = 1500
  }
}

local SPEECH =
{
  ATTACK = {
    "KILL 'EM ALL!!!",
    "ENEMY DETECTED!!!",
    "PROTECT MASTER!",
    "PREPARE TO GET STUNG!",
    "ONTO THE BATTLEFIELD!"
  },
  SPAWN = {
    "TO WORK SHALL WE?",
    "AHHHH WE SMELL FLOWERS!",
    "HARDWORKERS WE ARE!",
    "WE ARE HAPPY HONEYMAKER!"
  },
  IGNITE = {
    "HOME IS BURNING!!!",
    "HELP US MASTER!!!",
    "IT'S SO HOT IN THERE!",
    "BRING SOME WATER!"
  },
  FREEZE = {
    "OUCH! IT'S COLD OUT!",
    "WE COULD MAKE ICECREAM OUT OF THIS.",
    "BRRRRRR!"
  },
  HAMMER = {
    "WELL IF THAT'S YOUR CHOICE THEN...",
    "BUT... WHY ?",
    "IF DOING THIS MAY HELP, THEN JUST DO IT!",
    "AIN'T WE GOOD ENOUGH, MASTER ?"
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

local function OnEntityWake(inst)
  inst.SoundEmitter:PlaySound("dontstarve/bee/bee_hive_LP", "loop")
end

local function OnEntitySleep(inst)
  inst.SoundEmitter:KillSound("loop")
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
  -- inst.AnimState:OverrideSymbol("swap_frozen", "frozen", "frozen")
  inst.AnimState:Show("frozen_fx")

  StopSpawning(inst)
end

local function OnThaw(inst)
  inst.AnimState:PlayAnimation("frozen_loop_pst", true)
  inst.SoundEmitter:PlaySound("dontstarve/common/freezethaw", "thawing")
  -- inst.AnimState:OverrideSymbol("swap_frozen", "frozen", "frozen")
  inst.AnimState:Show("frozen_fx")
end

local function OnUnFreeze(inst)
  inst.AnimState:PlayAnimation("cocoon_small", true)
  inst.SoundEmitter:KillSound("thawing")
  -- inst.AnimState:ClearOverrideSymbol("swap_frozen")
  inst.AnimState:Hide("frozen_fx")

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

local function OnSlave(inst)
  local x, y, z = inst.Transform:GetWorldPosition()
  local slaves = TheSim:FindEntities(x, y, z,
    TUNING.MUTANT_BEEHIVE_MASTER_SLAVE_DIST,
    { "_combat", "_health" },
    { "INLIMBO", "player" },
    { "mutantslavehive" }
  )

  local numslaves = 0

  for i, slave in ipairs(slaves) do
    if IsSlave(inst, slave) then
      numslaves = numslaves + 1
    end
  end

  local stage = inst.components.upgradeable.stage
  local numchildren = TUNING.MUTANT_BEEHIVE_DEFAULT_EMERGENCY_BEES + (stage - 1) * TUNING.MUTANT_BEEHIVE_DELTA_BEES
    + numslaves * TUNING.MUTANT_BEEHIVE_CHILDREN_PER_SLAVE
  inst.components.childspawner:SetMaxEmergencyChildren(numchildren)
end

local tocheck = {
  mutantdefenderbee = "mutantdefenderhive",
  mutantrangerbee = "mutantrangerhive",
  mutantassassinbee = "mutantassassinhive",
  mutantkillerbee = true
}

local function CanSpawn(inst, prefab)
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
  local ratio = {
    mutantkillerbee = 4,
    mutantdefenderbee = 0,
    mutantrangerbee = 0,
    mutantassassinbee = 0
  }

  local canspawnprefabs = {"mutantkillerbee"}

  for i, prefab in ipairs({"mutantdefenderbee", "mutantrangerbee", "mutantassassinbee"}) do
    if CanSpawn(inst, prefab) then
      ratio[prefab] = 1
      ratio["mutantkillerbee"] = ratio["mutantkillerbee"] - 1
      table.insert(canspawnprefabs, prefab)
    end
  end

  local currentcount = {
    mutantkillerbee = 0,
    mutantdefenderbee = 0,
    mutantrangerbee = 0,
    mutantassassinbee = 0
  }
  local total = 0

  for child, c in pairs(inst.components.childspawner.childrenoutside) do
    if child:IsValid() and tocheck[child.prefab] then
      currentcount[child.prefab] = currentcount[child.prefab] + 1
      total = total + 1
    end
  end

  for child, c in pairs(inst.components.childspawner.emergencychildrenoutside) do
    if child:IsValid() and tocheck[child.prefab] then
      currentcount[child.prefab] = currentcount[child.prefab] + 1
      total = total + 1
    end
  end

  local prefabstopick = {}
  for prefab, cnt in pairs(currentcount) do
    if cnt / total < ratio[prefab] / 4 then
      table.insert(prefabstopick, prefab)
    end
  end

  if #prefabstopick == 0 then
    prefabstopick = canspawnprefabs
  end

  print("PREFABS TO PICK:")
  for k,v in ipairs(prefabstopick) do
    print(v)
  end

  return prefabstopick[math.random(#prefabstopick)]
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
    inst.components.childspawner:SetMaxEmergencyChildren(TUNING.MUTANT_BEEHIVE_DEFAULT_EMERGENCY_BEES + (stage - 1) * TUNING.MUTANT_BEEHIVE_DELTA_BEES)

    inst.components.upgradeable:SetStage(stage)

    local loots = {}
    local numhoneycombs = math.floor(TUNING.MUTANT_BEEHIVE_UPGRADES_PER_STAGE * (stage - 1))
    for i = 1, numhoneycombs do
      table.insert(loots, "honeycomb")
    end

    inst.components.lootdropper:SetLoot(loots)
    OnSlave(inst)
  end
end

local function OnUpgrade(inst)
  inst:Say(SPEECH.UPGRADE)
  Shake(inst)
end

local function OnStageAdvance(inst)
  inst:Say(SPEECH.STAGE_ADVANCE)
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
  local nearbyplayer, range = FindClosestPlayerToInst(inst, TUNING.MUTANT_BEEHIVE_WATCH_DIST, true)

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
          and guy.components.combat.target:HasTag("player")
      end,
      { "_combat", "_health" },
      { "mutant", "INLIMBO", "player" },
      { "monster", "insect", "animal", "character" }
    )

  if enemy then
    inst:Say(SPEECH.ATTACK)
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

  inst.components.growable:SetStage(inst.components.upgradeable.stage)

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

  inst:AddTag("structure")
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
  inst.OnEntitySleep = OnEntitySleep
  inst.OnEntityWake = OnEntityWake
  inst.OnSave = OnSave
  inst.OnLoad = OnLoad
  inst.OnRemoveEntity = OnRemoveEntity
  inst.OnSlave = OnSlave
  inst.InheritOwner = InheritOwner
  inst.CanSpawn = CanSpawn
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

local function SetMaster(inst, master)
  if master then
    inst.entity:SetParent(master.entity)
    master:OnSlave()
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

  local master = FindEntity(inst, TUNING.MUTANT_BEEHIVE_MASTER_SLAVE_DIST,
    function(guy)
      return guy:IsValid()
        and guy.prefab == 'mutantbeehive'
        and guy._ownerid == inst._ownerid
    end,
    { "_combat", "_health" },
    { "INLIMBO", "player" },
    { "mutantbeehive" }
  )

  if not master then
    OnSlaveHammered(inst)
    return
  end

  -- SetMaster(inst, master)
end

local function commonslavefn(bank, build, tags)
  local inst = CreateEntity()

  inst.entity:AddTransform()
  inst.entity:AddAnimState()
  inst.entity:AddSoundEmitter()
  inst.entity:AddMiniMapEntity()
  inst.entity:AddNetwork()

  MakeObstaclePhysics(inst, 1)

  inst.MiniMapEntity:SetIcon("beehive.png")

  inst.AnimState:SetBank(bank)
  inst.AnimState:SetBuild(build)
  inst.AnimState:PlayAnimation("cocoon_small", true)

  inst:AddTag("structure")
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
  MakeMediumFreezableCharacter(inst)
  inst:ListenForEvent("freeze", OnFreeze)
  inst:ListenForEvent("onthaw", OnThaw)
  inst:ListenForEvent("unfreeze", OnUnFreeze)
  ---------------------

  inst:AddComponent("combat")

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
  inst:ListenForEvent("onbuilt", onbuilt)
  inst:DoPeriodicTask(5, CheckMaster)

  return inst
end

local function defenderhive()
  local inst = commonslavefn("beehive", "beehive", {"mutantdefenderhive"})
  return inst
end

local function rangerhive()
  local inst = commonslavefn("beehive", "beehive", {"mutantrangerhive"})
  return inst
end

local function assassinhive()
  local inst = commonslavefn("beehive", "beehive", {"mutantassassinhive"})
  return inst
end

STRINGS.MUTANTBEEHIVE = "Metapis Hive"
STRINGS.NAMES.MUTANTBEEHIVE = "Metapis Hive"
STRINGS.CHARACTERS.GENERIC.DESCRIBE.MUTANTBEEHIVE = "\"Apis\" is the Latin word for \"bee\"."

STRINGS.MUTANTDEFENDERHIVE = "Metapis Defender Hive"
STRINGS.NAMES.MUTANTDEFENDERHIVE = "Metapis Defender Hive"

return Prefab("mutantbeehive", fn, assets, prefabs),
  Prefab("mutantdefenderhive", defenderhive, assets, prefabs),
  MakePlacer("mutantdefenderhive_placer", "beehive", "beehive", "cocoon_small"),
  Prefab("mutantrangerhive", rangerhive, assets, prefabs),
  MakePlacer("mutantrangerhive_placer", "beehive", "beehive", "cocoon_small"),
  Prefab("mutantassassinhive", assassinhive, assets, prefabs),
  MakePlacer("mutantassassinhive_placer", "beehive", "beehive", "cocoon_small")
