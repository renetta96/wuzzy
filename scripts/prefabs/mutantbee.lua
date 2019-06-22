local beecommon = require "brains/mutantbeecommon"

local assets =
{
	Asset("ANIM", "anim/bee.zip"),
	Asset("ANIM", "anim/mutantbee_build.zip"), -- New anim
	Asset("ANIM", "anim/mutantbee_angry_build.zip"), -- New anim
	Asset("SOUND", "sound/bee.fsb"),
}

local prefabs =
{
	"stinger",
	"honey",
	"explode_small",
	"blowdart_walrus",
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
	local nearbyplayer, range = FindClosestPlayerToInst(inst, dist, true)

	return (nearbyplayer and FindEntity(inst, dist,
		function(guy)
			return inst.components.combat:CanTarget(guy)
		end,
		{ "_combat", "_health" },
		{ "insect", "INLIMBO", "player" },
		{ "monster" }))
		or FindEntity(inst, dist,
		function(guy)
			return inst.components.combat:CanTarget(guy)
				and guy.components.combat and guy.components.combat.target
				and guy.components.combat.target:HasTag("player")
		end,
		{ "_combat", "_health" },
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

	inst.components.health:DoDelta(TUNING.MUTANT_BEE_POISON_DAMAGE, true, "poison_sting")

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
	if data.target and data.target.components.health and not data.target.components.health:IsDead() then
		-- No target players.
		if not data.target:HasTag("player") then
			data.target._poisonticks = TUNING.MUTANT_BEE_MAX_POISON_TICKS
			if data.target._poisontask == nil then
				data.target._poisontask = data.target:DoPeriodicTask(TUNING.MUTANT_BEE_POISON_PERIOD, DoPoisonDamage)
			end
		end
	end
end

local function OnDeathExplosive(inst)
	inst.components.combat:DoAreaAttack(inst, TUNING.MUTANT_BEE_EXPLOSIVE_RANGE, nil, nil, nil, { "INLIMBO", "mutant" })
	SpawnPrefab("explode_small").Transform:SetPosition(inst.Transform:GetWorldPosition())
	inst:Remove()
end

local rangedworkerbrain = require("brains/rangedbeebrain")
local rangedkillerbrain = require("brains/rangedkillerbeebrain")

local function OnSuicidalAttack(inst, data)
	if data.projectile then
		local delta = -inst.components.health.maxhealth * TUNING.MUTANT_BEE_RANGED_ATK_HEALTH_PENALTY
		inst.components.health:DoDelta(delta, nil, "suicidal_attack", nil, nil, true)
	end
end

local function RangedRetarget(inst)
	return FindTarget(inst, TUNING.MUTANT_BEE_RANGED_TARGET_DIST)
end

local function MakeRangedWeapon(inst)
	if not inst.components.inventory then
		inst:AddComponent("inventory")
	end

	inst.components.combat:SetRange(TUNING.MUTANT_BEE_WEAPON_ATK_RANGE)
	inst.components.combat:SetAttackPeriod(TUNING.MUTANT_BEE_RANGED_ATK_PERIOD)
	inst.components.combat:SetDefaultDamage(TUNING.MUTANT_BEE_RANGED_DAMAGE)
	inst.components.combat:SetRetargetFunction(0.25, RangedRetarget)

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

	inst:ListenForEvent("onattackother", OnSuicidalAttack)

	if inst:HasTag("worker") then
		inst:SetBrain(rangedworkerbrain)
	else
		inst:SetBrain(rangedkillerbrain)
	end
end

local function OnAttackOtherWithFrostbite(inst, data)
	if data.target and data.target.components.locomotor
		and data.target.components.health and not data.target.components.health:IsDead() then
		if not data.target:HasTag("player") then
			data.target._frostbite_expire = GetTime() + 4.75
			data.target.AnimState:SetAddColour(82 / 255, 115 / 255, 124 / 255, 0)
			if data.target.components.combat then
				if not data.target._currentattackperiod then
					data.target._currentattackperiod = data.target.components.combat.min_attack_period
					data.target.components.combat:SetAttackPeriod(data.target._currentattackperiod * TUNING.MUTANT_BEE_FROSTBITE_ATK_PERIOD_PENALTY)
				end
			end

			if data.target.components.locomotor.enablegroundspeedmultiplier then
				data.target.components.locomotor:SetExternalSpeedMultiplier(data.target, "frostbite", TUNING.MUTANT_BEE_FROSTBITE_SPEED_PENALTY)
				data.target:DoTaskInTime(5.0,
					function (inst)
						if GetTime() >= inst._frostbite_expire then
							inst.AnimState:SetAddColour(0, 0, 0, 0)
							inst.components.locomotor:RemoveExternalSpeedMultiplier(inst, "frostbite")
							if inst.components.combat and inst._currentattackperiod then
								inst.components.combat:SetAttackPeriod(inst._currentattackperiod)
								inst._currentattackperiod = nil
							end
						end
					end)
			else
				if not data.target._currentspeed then
					data.target._currentspeed = data.target.components.locomotor.groundspeedmultiplier
				end
				data.target.components.locomotor.groundspeedmultiplier = TUNING.MUTANT_BEE_FROSTBITE_SPEED_PENALTY
				data.target:DoTaskInTime(5.0,
					function (inst)
						if GetTime() >= inst._frostbite_expire then
							inst.AnimState:SetAddColour(0, 0, 0, 0)
							if inst._currentspeed then
								inst.components.locomotor.groundspeedmultiplier = inst._currentspeed
								inst._currentspeed = nil
							end
							if inst.components.combat and inst._currentattackperiod then
								inst.components.combat:SetAttackPeriod(inst._currentattackperiod)
								inst._currentattackperiod = nil
							end
						end
					end)
			end
		end
	end
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

local function ChangeMutantOnSeason(inst)
	if TheWorld.state.isspring then
		inst.components.locomotor.groundspeedmultiplier = 1.3
		inst:ListenForEvent("onattackother", OnAttackOtherWithPoison)
	elseif TheWorld.state.issummer then
		inst.components.health:SetMaxHealth(TUNING.MUTANT_BEE_HEALTH / 2)
		inst.components.combat.areahitdamagepercent = TUNING.MUTANT_BEE_EXPLOSIVE_DAMAGE_MULTIPLIER
		inst:ListenForEvent("death", OnDeathExplosive)
	elseif TheWorld.state.isautumn then
		MakeRangedWeapon(inst)
	else
		inst.components.locomotor.groundspeedmultiplier = 0.7
		inst.components.combat:SetAttackPeriod(TUNING.MUTANT_BEE_ATTACK_PERIOD * 2)
		inst:ListenForEvent("onattackother", OnAttackOtherWithFrostbite)
	end
end

local WAKE_TO_FOLLOW_DISTANCE = 15

local function ShouldWakeUp(inst)
	return DefaultWakeTest(inst)
	or (inst.components.follower
		and not inst.components.follower:IsNearLeader(WAKE_TO_FOLLOW_DISTANCE))
end

local SLEEP_NEAR_LEADER_DISTANCE = 8

local function ShouldSleep(inst)
	return DefaultSleepTest(inst)
	and (inst.components.follower == nil or
		inst.components.follower:IsNearLeader(SLEEP_NEAR_LEADER_DISTANCE))
end

local function commonfn(build, tags)
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

	inst.AnimState:SetBank("bee")
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
	inst:SetStateGraph("SGbee")

	---------------------

	inst:AddComponent("lootdropper")
	inst.components.lootdropper:AddRandomLoot("honey", 2)
	inst.components.lootdropper:AddRandomLoot("stinger", 3)
	inst.components.lootdropper.numrandomloot = 1
	inst.components.lootdropper.chancerandomloot = 0.5

	------------------

	MakeSmallBurnableCharacter(inst, "body", Vector3(0, -1, 1))
	MakeTinyFreezableCharacter(inst, "body", Vector3(0, -1, 1))

	------------------

	inst:AddComponent("health")
	inst:AddComponent("combat")
	inst.components.combat:SetRange(TUNING.BEE_ATTACK_RANGE)
	inst.components.combat.hiteffectsymbol = "body"
	inst.components.combat:SetPlayerStunlock(PLAYERSTUNLOCK.RARELY)

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

local workerbrain = require("brains/mutantbeebrain")
local killerbrain = require("brains/mutantkillerbeebrain")

local function workerbee()
	--pollinator (from pollinator component) added to pristine state for optimization
	--for searching: inst:AddTag("pollinator")
	local inst = nil

	inst = commonfn("mutantbee_build", { "worker", "pollinator" })

	if not TheWorld.ismastersim then
		return inst
	end

	inst.components.health:SetMaxHealth(TUNING.MUTANT_BEE_HEALTH)
	inst.components.combat:SetDefaultDamage(TUNING.MUTANT_BEE_DAMAGE)
	inst.components.combat:SetAttackPeriod(TUNING.MUTANT_BEE_ATTACK_PERIOD)
	inst.components.combat:SetRetargetFunction(2, MutantBeeRetarget)
	inst:AddComponent("pollinator")
	inst:SetBrain(workerbrain)
	inst.sounds = workersounds

	MakeHauntableChangePrefab(inst, "mutantkillerbee")

	inst:DoTaskInTime(0, ChangeMutantOnSeason)

	return inst
end

local function OnSpawnedFromHaunt(inst)
	if inst.components.hauntable ~= nil then
		inst.components.hauntable:Panic()
	end
end

local function killerbee()
	local inst = nil

	inst = commonfn("mutantbee_angry_build", { "killer", "scarytoprey" })

	if not TheWorld.ismastersim then
		return inst
	end

	inst.components.health:SetMaxHealth(TUNING.MUTANT_BEE_HEALTH)
	inst.components.combat:SetDefaultDamage(TUNING.MUTANT_BEE_DAMAGE)
	inst.components.combat:SetAttackPeriod(TUNING.MUTANT_BEE_ATTACK_PERIOD)
	inst.components.combat:SetRetargetFunction(1, KillerRetarget)
	inst:SetBrain(killerbrain)
	inst.sounds = killersounds

	MakeHauntablePanic(inst)
	inst:ListenForEvent("spawnedfromhaunt", OnSpawnedFromHaunt)
	inst:ListenForEvent("startfollowing", OnStartFollowing)
	inst:ListenForEvent("stopfollowing", OnStopFollowing)

	inst:DoTaskInTime(0, ChangeMutantOnSeason)

	return inst
end

STRINGS.MUTANTBEE = "Metapis"
STRINGS.NAMES.MUTANTBEE = "Metapis"
STRINGS.CHARACTERS.GENERIC.DESCRIBE.MUTANTBEE = "Meta...apis? Metabee? Like metahuman?"

STRINGS.MUTANTKILLERBEE = "Metapis Soldier"
STRINGS.NAMES.MUTANTKILLERBEE = "Metapis Soldier"
STRINGS.CHARACTERS.GENERIC.DESCRIBE.MUTANTKILLERBEE = "Is it really OK to come near them?"

return Prefab("mutantbee", workerbee, assets, prefabs),
		Prefab("mutantkillerbee", killerbee, assets, prefabs)
