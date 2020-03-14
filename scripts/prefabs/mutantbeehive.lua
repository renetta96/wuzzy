local prefabs =
{
	"mutantbee",
	"mutantkillerbee",
	"honey",
	"zetapollen",
	"honeycomb",
	"mutantbeecocoon",
	"collapse_big",
	"collapse_small"
}

local assets =
{
	Asset("ANIM", "anim/ui_chest_3x3.zip"),
	Asset("ANIM", "anim/mutantbeehive.zip"),
  Asset("ANIM", "anim/mutantdefenderhive.zip"),
  Asset("ANIM", "anim/mutantassassinhive.zip"),
  Asset("ANIM", "anim/mutantrangerhive.zip"),
	Asset("SOUND", "sound/bee.fsb"),
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
		"AREN'T WE GOOD ENOUGH, MASTER?"
	},
	HIT = {
		"THE HIVE IS UNDER ATTACKED!!!",
		"PROTECT THE HIVE!",
		"HOW DARE YOU?",
		"WE WILL KILL YOU INTRUDER!"
	},
	STAGE_ADVANCE = {
		"BIGGER HIVE COMES STRONGER BEES.",
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
		"AT LAST WE'RE UNITED!"
	},
	GOODNIGHT = {
		"HAVE A GOOD SLEEP, MASTER!",
		"GOOD NIGHT!",
		"HAVE A NICE DREAM, SHALL WE?",
		"WELCOME HOME!"
	},
	WAKEUP = {
		"DID YOU SLEEP WELL, MASTER?",
		"IS OUR HIVE COMFORTABLE?",
		"YOU HAVE NIGHTMARE?",
		"EARLY BEE GETS MORE HONEY."
	},
	SNORE = "Zzz...Zzz..."
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

local function SetFX(inst)
	-- local stage = inst.components.upgradeable.stage
	-- if not inst._honeyspill then
	-- 	local fx = SpawnPrefab("honeyspill")
	-- 	fx.Transform:SetPosition(inst.Transform:GetWorldPosition())
	-- 	fx:SetVariation(7, 1.0 + 0.25 * (stage - 1))
	-- 	inst._honeyspill = fx
	-- else
	-- 	inst._honeyspill:SetVariation(7, 1.0 + 0.25 * (stage - 1))
	-- end
end

local function RemoveFX(inst)
	-- if inst._honeyspill then
	-- 	inst._honeyspill:Remove()
	-- end
end

local function Shake(inst, ignore_frozen)
	if ignore_frozen or not (inst.components.freezable and inst.components.freezable:IsFrozen()) then
		inst.SoundEmitter:PlaySound("dontstarve/bee/beehive_hit")
		inst.AnimState:PlayAnimation("cocoon_small_hit")
		inst.AnimState:PushAnimation("cocoon_small", true)
	end
end

local function UnlinkPlayer(inst)
	local owner = GetPlayer()
	inst.isowned = false
	owner._hive = nil
end

local function OnRemoveEntity(inst)
	RemoveFX(inst)
	UnlinkPlayer(inst)

	if inst.components.childspawner then
		for k, v in pairs(inst.components.childspawner.childrenoutside) do
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
	cocoon.Transform:SetPosition(inst.Transform:GetWorldPosition())
end

local function OnDeath(inst)
	SpawnCocoon(inst)
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
	SpawnCocoon(inst)
	RemoveFX(inst)

	local collapse = inst.components.upgradeable.stage >= 2 and "collapse_big" or "collapse_small"
	local fx = SpawnPrefab(collapse)
	fx.Transform:SetPosition(inst.Transform:GetWorldPosition())
	inst.SoundEmitter:PlaySound("dontstarve/common/destroy_straw")

	inst:Remove()
end

local function IsValidOwner(owner)
	if not owner then
		return false
	end

	return owner:HasTag("beemaster")
end

local function OnHit(inst, attacker, damage)
	if damage ~= nil then
		if not IsValidOwner(attacker) then
			inst:Say(SPEECH.HIT)
		else
			inst:Say(SPEECH.HAMMER)
		end
	end

	if inst.components.childspawner ~= nil and not IsValidOwner(attacker) then
		inst.components.childspawner:ReleaseAllChildren(attacker)
	end
	if not inst.components.health:IsDead() then
		Shake(inst)
	end
end

local function OnWork(inst, worker, workleft)
	if IsValidOwner(worker) then
		inst:Say(SPEECH.HAMMER)
	else
		OnHit(inst, worker, 1)
	end
end

local function IsSlave(inst, slave)
  return slave:IsValid() and inst.isowned
end

local function GetSlaves(inst)
  local x, y, z = inst.Transform:GetWorldPosition()
  local entities = TheSim:FindEntities(x, y, z,
    TUNING.MUTANT_BEEHIVE_MASTER_SLAVE_DIST,
    nil,
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
    inst.components.childspawner.maxchildren =
    	TUNING.MUTANT_BEEHIVE_BEES
    	+ (inst.components.upgradeable.stage - 1) * TUNING.MUTANT_BEEHIVE_DELTA_BEES
    	+ #slaves * TUNING.MUTANT_BEEHIVE_CHILDREN_PER_SLAVE
  end
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
    nil,
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

  if inst.components.childspawner then
    for child, c in pairs(inst.components.childspawner.childrenoutside) do
      if child:IsValid() and tocheck[child.prefab] then
        currentcount[child.prefab] = currentcount[child.prefab] + 1
        total = total + 1
      end
    end
  end

  local prefabstopick = {}

  if total > 0 then
    for prefab, cnt in pairs(currentcount) do
      if cnt / total < ratio[prefab] / 4 then
        table.insert(prefabstopick, prefab)
      end
    end
  end

  if #prefabstopick == 0 then
    prefabstopick = canspawnprefabs
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
		inst.components.childspawner:SetMaxChildren(TUNING.MUTANT_BEEHIVE_BEES + (stage - 1) * TUNING.MUTANT_BEEHIVE_DELTA_BEES)

		SetFX(inst)
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
	local enemy = (GetPlayer():IsNear(inst, TUNING.MUTANT_BEEHIVE_WATCH_DIST) and
		FindEntity(inst, TUNING.MUTANT_BEEHIVE_WATCH_DIST,
			function(guy)
				return inst.components.combat:CanTarget(guy)
			end,
			nil,
			{ "insect", "INLIMBO", "player" },
			{ "monster" })
		)
			or FindEntity(inst, TUNING.MUTANT_BEEHIVE_WATCH_DIST,
				function(guy)
					return inst.components.combat:CanTarget(guy)
						and guy.components.combat and guy.components.combat.target
						and (
							guy.components.combat.target:HasTag("player")
							or guy.components.combat.target:HasTag("mutant")
						)
				end,
				nil,
				{ "mutant", "INLIMBO", "player" },
				{ "monster", "insect", "animal", "character" })
	if enemy then
		inst:Say(SPEECH.ATTACK)
		OnHit(inst, enemy)
		inst.incombat = true
	else
		inst.incombat = false
	end
end

local function SelfRepair(inst)
	if inst and inst.components.childspawner and inst.components.health then
		if not inst.components.health:IsDead() then
			local numfixers = inst.components.childspawner.childreninside
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

local function LinkToPlayer(inst, player)
	if IsValidOwner(player) and inst.isowned then
		inst:Say(SPEECH.WELCOME)
		player._hive = inst
	end
end

local function CalcSanityAura(inst, observer)
	if inst.isowned and IsValidOwner(observer) then
		return TUNING.SANITYAURA_MED
	end

	return 0
end

local function OnSave(inst, data)
	if inst.isowned then
		data.isowned = inst.isowned
	end
end

local function OnLoad(inst, data)
	if data and data.isowned then
		inst.isowned = data.isowned
	end
end

local function OnPlayerJoined(inst)
	local player = GetPlayer()
	LinkToPlayer(inst, player)
end

local function onopen(inst)
	inst.SoundEmitter:PlaySound("dontstarve/wilson/chest_open")
end

local function onclose(inst)
	inst.SoundEmitter:PlaySound("dontstarve/wilson/chest_close")
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

local function AddHoneyProgress(inst)
	if not inst.components.container then
    return
  end

  local pollen = SpawnPrefab("zetapollen")
  inst.components.container:GiveItem(pollen)

  -- One more pollen when fully upgraded
  if inst.components.upgradeable.stage >= 3 then
    local pollen = SpawnPrefab("zetapollen")
    inst.components.container:GiveItem(pollen)
  end
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

local function OnInit(inst)
	StartSpawning(inst)
	inst:ListenForEvent("dusktime", function() StopSpawning(inst) end, GetWorld())
  inst:ListenForEvent("daytime", function() StartSpawning(inst) end , GetWorld())

	inst.components.growable:SetStage(inst.components.upgradeable.stage)

	inst:DoPeriodicTask(3, SelfRepair)
	inst:DoPeriodicTask(60, ConvertPollenToHoney)
	inst:DoPeriodicTask(2, OnSlave)

	OnPlayerJoined(inst)
end

local slotpos = {}

for y = 2, 0, -1 do
	for x = 0, 2 do
		table.insert(slotpos, Vector3(80*x-80*2+80, 80*y-80*2+80, 0))
	end
end

local function fn()
	local inst = CreateEntity()

	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddSoundEmitter()
	inst.entity:AddMiniMapEntity()
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

	MakeSnowCovered(inst)

	-------------------
	inst:AddComponent("health")

	-------------------
	inst:AddComponent("childspawner")
	inst.components.childspawner.childname = "mutantbee"
	inst.components.childspawner:SetMaxChildren(TUNING.MUTANT_BEEHIVE_BEES)
	inst:ListenForEvent("childgoinghome", onchildgoinghome)

	local oldSpawnChild = inst.components.childspawner.SpawnChild
  inst.components.childspawner.SpawnChild = function(comp, target, prefab, ...)
    local newprefab = prefab
    if target ~= nil then
      newprefab = PickChildPrefab(inst)
    end
    return oldSpawnChild(comp, target, newprefab, ...)
  end

	inst:DoTaskInTime(0, OnInit)

	---------------------
	MakeLargeBurnable(inst)
	inst.components.burnable:SetOnIgniteFn(OnIgnite)
	local onburntfn = inst.components.burnable.onburnt
	inst.components.burnable.onburnt = function(inst)
		SpawnCocoon(inst)
		onburntfn(inst)
	end
	---------------------

	---------------------
	MakeLargeFreezableCharacter(inst)
	inst:ListenForEvent("freeze", OnFreeze)
	inst:ListenForEvent("onthaw", OnThaw)
	inst:ListenForEvent("unfreeze", OnUnFreeze)
	---------------------

	inst:AddComponent("combat")
	inst.components.combat:SetOnHit(OnHit)
	inst:ListenForEvent("death", OnKilled)
	inst:DoPeriodicTask(2, WatchEnemy)
	inst.OnHit = OnHit

	inst:ListenForEvent("death", OnDeath)

	---------------------

	inst:AddComponent("upgradeable")
	inst.components.upgradeable.onupgradefn = OnUpgrade
	inst.components.upgradeable.onstageadvancefn = OnStageAdvance
	inst.components.upgradeable.upgradesperstage = TUNING.MUTANT_BEEHIVE_UPGRADES_PER_STAGE
	inst.components.upgradeable.upgradetype = "METAPIS"

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
	inst:AddComponent("container")
	inst.components.container:SetNumSlots(#slotpos)
	inst.components.container.onopenfn = onopen
	inst.components.container.onclosefn = onclose
	inst.components.container.itemtestfn = itemtestfn

	inst.components.container.widgetslotpos = slotpos
	inst.components.container.widgetanimbank = "ui_chest_3x3"
	inst.components.container.widgetanimbuild = "ui_chest_3x3"
	inst.components.container.widgetpos = Vector3(0, 200, 0)
	inst.components.container.side_align_tip = 160

	---------------------
	MakeLargePropagator(inst)
	MakeSnowCovered(inst)

	---------------------

	inst:AddComponent("inspectable")
	inst.incombat = false
	inst.OnEntitySleep = OnEntitySleep
	inst.OnEntityWake = OnEntityWake
	inst.CanSpawn = CanSpawn
	inst.GetSlaves = GetSlaves
	inst.OnSave = OnSave
	inst.OnLoad = OnLoad
	inst.OnRemoveEntity = OnRemoveEntity

	return inst
end

local function OnSlaveHammered(inst, worker)
  inst.SoundEmitter:PlaySound("dontstarve/bee/beehive_destroy")
  inst.components.lootdropper:DropLoot(inst:GetPosition())

  local fx = SpawnPrefab("collapse_small")
  fx.Transform:SetPosition(inst.Transform:GetWorldPosition())
  inst.SoundEmitter:PlaySound("dontstarve/common/destroy_straw")

  inst:Remove()
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

local function slavehivetestfn(inst, pt)
  local x, y, z = pt:Get()
  local possiblemasters = TheSim:FindEntities(x, y, z,
    TUNING.MUTANT_BEEHIVE_MASTER_SLAVE_DIST,
    { "mutantbeehive" }
  )

  if possiblemasters[1] ~= nil then
    return true
  end

  return false
end

local function commonslavefn(bank, build, tags, mapicon)
  local inst = CreateEntity()

  inst.entity:AddTransform()
  inst.entity:AddAnimState()
  inst.entity:AddSoundEmitter()
  inst.entity:AddMiniMapEntity()

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

STRINGS.MUTANTASSASSINHIVE = "Metapis Assasin Hive"
STRINGS.NAMES.MUTANTASSASSINHIVE = "Metapis Assasin Hive"
STRINGS.CHARACTERS.GENERIC.DESCRIBE.MUTANTASSASSINHIVE = "Spiky."
STRINGS.RECIPE_DESC.MUTANTASSASSINHIVE = "Adds Metapis Assasin to Mother Hive."

return Prefab("mutantbeehive", fn, assets, prefabs),
  Prefab("mutantdefenderhive", defenderhive, assets, prefabs),
  MakePlacer("mutantdefenderhive_placer", "mutantdefenderhive", "mutantdefenderhive", "idle", nil, nil, nil, nil, nil, nil, nil, nil, nil, slavehivetestfn),
  Prefab("mutantrangerhive", rangerhive, assets, prefabs),
  MakePlacer("mutantrangerhive_placer", "mutantrangerhive", "mutantrangerhive", "idle", nil, nil, nil, nil, nil, nil, nil, nil, nil, slavehivetestfn),
  Prefab("mutantassassinhive", assassinhive, assets, prefabs),
  MakePlacer("mutantassassinhive_placer", "mutantassassinhive", "mutantassassinhive", "idle", nil, nil, nil, nil, nil, nil, nil, nil, nil, slavehivetestfn)
