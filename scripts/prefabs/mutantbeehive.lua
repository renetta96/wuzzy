local prefabs =
{
	"mutantbee",
	"mutantkillerbee",
	"honey",
	"honeycomb",
	-- "honeyspill",
	"mutantbeecocoon",
	"collapse_big",
	"collapse_small"
}

local assets =
{
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
	ATTACK = {
		"LET'S KILL THEM ALL!!!",
		"ENEMY DETECTED!!!",
		"PROTECT MASTER!",
		"PREPARE TO GET STINGED!",
		"ONTO THE BATTLEFIELD!"
	},
	SPAWN = {
		"TO WORK SHALL WE?",
		"AHHHH WE SMELL FLOWERS!",
		"HARDWORKERS WE ARE!",
		"WE ARE HAPPY HONEYMAKERS!"
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
		"WE WERE WAITING FOR YOU!",
		"FINALLY WE'RE UNITED!"
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
		inst.components.childspawner:ReleaseAllChildren(attacker, "mutantkillerbee")
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
			nil,
			{ "insect", "INLIMBO" },
			{ "monster" })
			or FindEntity(inst, TUNING.MUTANT_BEEHIVE_WATCH_DIST,
				function(guy)
					return inst.components.combat:CanTarget(guy)
						and guy.components.combat and guy.components.combat.target
						and guy.components.combat.target:HasTag("player")
				end,
				nil,
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
			local numfixers = inst.components.childspawner.childreninside
			local recover = TUNING.MUTANT_BEEHIVE_RECOVER_PER_CHILD * numfixers
			inst.components.health:DoDelta(recover, true, "self_repair")
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

local function OnInit(inst)
	StartSpawning(inst)
	inst:ListenForEvent("dusktime", function() StopSpawning(inst) end, GetWorld())
    inst:ListenForEvent("daytime", function() StartSpawning(inst) end , GetWorld())

	inst.components.growable:SetStage(inst.components.upgradeable.stage)

	inst:DoPeriodicTask(3, SelfRepair)

	OnPlayerJoined(inst)
end

local function fn()
	local inst = CreateEntity()

	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddSoundEmitter()
	inst.entity:AddMiniMapEntity()
	inst.entity:AddLightWatcher()

	MakeObstaclePhysics(inst, 3)

	inst.MiniMapEntity:SetIcon("beehive.png")

	inst.AnimState:SetBank("mutantbeehive")
	inst.AnimState:SetBuild("mutantbeehive")


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

	MakeSnowCovered(inst)

	-------------------
	inst:AddComponent("health")

	-------------------
	inst:AddComponent("childspawner")
	inst.components.childspawner.childname = "mutantbee"
	inst.components.childspawner:SetMaxChildren(TUNING.MUTANT_BEEHIVE_BEES)

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
	MakeLargePropagator(inst)
	MakeSnowCovered(inst)

	---------------------

	inst:AddComponent("inspectable")
	inst.OnEntitySleep = OnEntitySleep
	inst.OnEntityWake = OnEntityWake
	inst.OnSave = OnSave
	inst.OnLoad = OnLoad
	inst.OnRemoveEntity = OnRemoveEntity

	return inst
end

STRINGS.MUTANTBEEHIVE = "Metapis Hive"
STRINGS.NAMES.MUTANTBEEHIVE = "Metapis Hive"
STRINGS.CHARACTERS.GENERIC.DESCRIBE.MUTANTBEEHIVE = "\"Apis\" is the Latin word for \"bee\"."

return Prefab("mutantbeehive", fn, assets, prefabs)
