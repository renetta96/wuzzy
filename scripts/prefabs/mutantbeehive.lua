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
	Asset("ANIM", "anim/mutantbeehive.zip"), -- New anim
	Asset("SOUND", "sound/bee.fsb"),
}

local UPGRADE_STAGES = {
	[1] = {
		SIZE_SCALE = 1.2,
		HEALTH = 700
	},
	[2] = {
		SIZE_SCALE = 1.45,
		HEALTH = 1100
	},
	[3] = {
		SIZE_SCALE = 1.7,
		HEALTH = 1500
	}
}

local SPEECH =
{
	REJECT_SLEEPER = {
		"SLEEP ELSEWHERE, DUDE.",
		"YOU ARE NOT OUR MASTER!",
		"GET OUT!!!",
		"THIS HIVE IS NOT FOR YOU."
	},
	ATTACK = {
		"LET'S KILL THEM ALL!!!",
		"ENEMY DETECTED!!!",
		"PROTECT MASTER!",
		"PREPARE TO GET STINGED!",
		"ONTO THE BATTLEFIELD!"
	},
	SPAWN = {
		"TO WORK SHALL WE ?",
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
		"AREN'T WE GOOD ENOUGH, MASTER ?"
	},
	HIT = {
		"THE HIVE IS UNDER ATTACKED!!!",
		"PROTECT THE HIVE!",
		"HOW DARE YOU ?",
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
		"WE WERE WAITING FOR YOU!",
		"FINALLY WE'RE UNITED!"
	},
	GOODNIGHT = {
		"HAVE A GOOD SLEEP, MASTER!",
		"GOOD NIGHT!",
		"HAVE A NICE DREAM, SHALL WE ?",
		"WELCOME HOME!"
	},
	WAKEUP = {
		"DID YOU SLEEP WELL, MASTER ?",
		"IS OUR HIVE COMFORTABLE ?",
		"YOU HAVE NIGHTMARE ?",
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

local function OnHit(inst, attacker, damage)
	if damage ~= nil then
		if not IsValidOwner(inst, attacker) then
			inst:Say(SPEECH.HIT)
		else
			inst:Say(SPEECH.HAMMER)
		end
	end

	if inst.components.childspawner ~= nil and not IsValidOwner(inst, attacker) then
		inst.components.childspawner:ReleaseAllChildren(attacker, "mutantkillerbee")
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

		SetFX(inst)
		inst.components.upgradeable:SetStage(stage)

		local loots = {}
		local numhoneycombs = math.floor(TUNING.MUTANT_BEEHIVE_UPGRADES_PER_STAGE * (stage - 1))
		for i = 1, numhoneycombs do
			table.insert(loots, "honeycomb")
		end

		inst.components.lootdropper:SetLoot(loots)
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
		return TUNING.SANITYAURA_SMALL_TINY
	end

	return 0
end

-- /* Sleep stuff
local function wakeuptest(inst, phase)
	if phase ~= inst.sleep_phase then
		inst.components.sleepingbag:DoWakeUp()
	end
end

local function onignite(inst)
	inst.components.sleepingbag:DoWakeUp()
end

local function onsleeptick(inst, sleeper)
	local isstarving = false

	if sleeper.components.hunger ~= nil then
		sleeper.components.hunger:DoDelta(inst.hunger_tick, true, true)
		isstarving = sleeper.components.hunger:IsStarving()
	end

	if sleeper.components.sanity ~= nil and sleeper.components.sanity:GetPercentWithPenalty() < 1 then
		sleeper.components.sanity:DoDelta(TUNING.SLEEP_SANITY_PER_TICK * TUNING.MUTANT_BEEHIVE_SLEEP_SANITY_RATE, true)
	end

	if not isstarving and sleeper.components.health ~= nil then
		sleeper.components.health:DoDelta(TUNING.SLEEP_HEALTH_PER_TICK * 2 * TUNING.MUTANT_BEEHIVE_SLEEP_HEALTH_RATE, true, inst.prefab, true)
	end

	if sleeper.components.temperature ~= nil then
		if inst.is_cooling then
			if sleeper.components.temperature:GetCurrent() > TUNING.SLEEP_TARGET_TEMP_TENT then
				sleeper.components.temperature:SetTemperature(sleeper.components.temperature:GetCurrent() - TUNING.SLEEP_TEMP_PER_TICK * TUNING.MUTANT_BEEHIVE_SLEEP_TEMP_RATE)
			end
		elseif sleeper.components.temperature:GetCurrent() < TUNING.SLEEP_TARGET_TEMP_TENT then
			sleeper.components.temperature:SetTemperature(sleeper.components.temperature:GetCurrent() + TUNING.SLEEP_TEMP_PER_TICK * TUNING.MUTANT_BEEHIVE_SLEEP_TEMP_RATE)
		end
	end

	if isstarving then
		inst.components.sleepingbag:DoWakeUp()
	end
end

local function onsleepreward(inst, sleeper)
	if sleeper and sleeper.components.inventory then
		local honey = SpawnPrefab("honey")
		local acceptcount = sleeper.components.inventory:CanAcceptCount(honey)
		if acceptcount > 0 then
			sleeper.components.inventory:GiveItem(honey)
		else
			honey:Remove()
		end
	end
end

local function onsleep(inst, sleeper)
	inst:WatchWorldState("phase", wakeuptest)
	sleeper:ListenForEvent("onignite", onignite, inst)

	if inst.sleeptask ~= nil then
		inst.sleeptask:Cancel()
	end

	inst.sleeptask = inst:DoPeriodicTask(TUNING.SLEEP_TICK_PERIOD, onsleeptick, nil, sleeper)
	inst.rewardtask = inst:DoPeriodicTask(TUNING.MUTANT_BEEHIVE_REWARD_TICKS * TUNING.SLEEP_TICK_PERIOD, onsleepreward, nil, sleeper)
	inst.snoretask = inst:DoPeriodicTask(3, function() inst:Say(SPEECH.SNORE) end)

	if not IsValidOwner(inst, sleeper) then
		inst:DoTaskInTime(0, function()
			inst._rejectingsleeper = true
			inst.components.sleepingbag:DoWakeUp()
		end)
	else
		inst:Say(SPEECH.GOODNIGHT)
	end
end

local function onwake(inst, sleeper, nostatechange)
	if inst.sleeptask ~= nil then
		inst.sleeptask:Cancel()
		inst.sleeptask = nil
	end

	if inst.snoretask ~= nil then
		inst.snoretask:Cancel()
		inst.snoretask = nil
	end

	if inst.rewardtask ~= nil then
		inst.rewardtask:Cancel()
		inst.rewardtask = nil
	end

	inst:StopWatchingWorldState("phase", wakeuptest)
	sleeper:RemoveEventCallback("onignite", onignite, inst)

	if not nostatechange then
		if not inst._rejectingsleeper then
			inst:Say(SPEECH.WAKEUP)
			if sleeper.sg:HasStateTag("tent") then
				sleeper.sg.statemem.iswaking = true
			end
			sleeper.sg:GoToState("wakeup")
		else
			inst:Say(SPEECH.REJECT_SLEEPER)

			sleeper.sg:GoToState("idle")
			sleeper.AnimState:PlayAnimation("emoteXL_annoyed")
			sleeper.AnimState:PushAnimation("idle")
			inst._rejectingsleeper = false
		end
	end
end
-- Sleep stuff /*

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

local function GetBuildConfig()
	local actualname = KnownModIndex:GetModActualName("Ozzy The Buzzy")
	local usenewbuild = GetModConfigData("USE_NEW_HIVE_BUILD", actualname)

	return usenewbuild
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

	local usenewbuild = GetBuildConfig()
	if usenewbuild then
		inst.AnimState:SetBuild("mutantbeehive")
	else
		inst.AnimState:SetBuild("beehive")
		inst.AnimState:SetMultColour(0.7, 0.5, 0.7, 1)
	end


	inst.AnimState:PlayAnimation("cocoon_small", true)

	inst:AddTag("structure")
	inst:AddTag("hive")
	inst:AddTag("beehive")
	inst:AddTag("mutantbeehive")
	inst:AddTag("tent")

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
	-- SeasonalSpawnChanges(inst, TheWorld.state.season)
	-- inst:WatchWorldState("season", SeasonalSpawnChanges)
	inst.components.childspawner.emergencychildname = "mutantkillerbee"
	inst.components.childspawner.emergencychildrenperplayer = TUNING.MUTANT_BEEHIVE_EMERGENCY_BEES_PER_PLAYER
	inst.components.childspawner:SetEmergencyRadius(TUNING.MUTANT_BEEHIVE_EMERGENCY_RADIUS)
	inst.components.childspawner:SetMaxChildren(TUNING.MUTANT_BEEHIVE_BEES)

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

	inst:AddComponent("sleepingbag")
	inst.components.sleepingbag.onsleep = onsleep
	inst.components.sleepingbag.onwake = onwake
	inst.components.sleepingbag.dryingrate = math.max(0, -TUNING.SLEEP_WETNESS_PER_TICK / TUNING.SLEEP_TICK_PERIOD)
	inst.sleep_phase = "night"
	inst.hunger_tick = TUNING.SLEEP_HUNGER_PER_TICK * TUNING.MUTANT_BEEHIVE_SLEEP_HUNGER_RATE

	---------------------

	inst:AddComponent("inspectable")
	inst.OnEntitySleep = OnEntitySleep
	inst.OnEntityWake = OnEntityWake
	inst.OnSave = OnSave
	inst.OnLoad = OnLoad
	inst.OnRemoveEntity = OnRemoveEntity
	inst.InheritOwner = InheritOwner
	inst._onplayerjoined = function(src, player) OnPlayerJoined(inst, player) end
	inst:ListenForEvent("ms_playerjoined", inst._onplayerjoined, TheWorld)

	return inst
end

STRINGS.MUTANTBEEHIVE = "Metapis Hive"
STRINGS.NAMES.MUTANTBEEHIVE = "Metapis Hive"
STRINGS.CHARACTERS.GENERIC.DESCRIBE.MUTANTBEEHIVE = "\"Apis\" is the Latin word for \"bee\"."

return Prefab("mutantbeehive", fn, assets, prefabs)
