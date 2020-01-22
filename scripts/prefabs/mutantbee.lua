local beecommon = require "brains/mutantbeecommon"
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
	"blowdart_yellow",
	"electrichitsparks"
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
	local nearbyplayer, range = FindClosestPlayerToInst(inst, TUNING.MUTANT_BEE_WATCH_DIST, true)

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
			inst.components.combat:DoAreaAttack(target, TUNING.MUTANT_BEE_EXPLOSIVE_RANGE, nil, nil, nil, { "INLIMBO", "mutant", "player" })
			SpawnPrefab("explode_small").Transform:SetPosition(target.Transform:GetWorldPosition())
		end
	end
end

local function OnSuicidalAttack(inst, data)
	if data.projectile then
		local delta = -inst.components.health.maxhealth * TUNING.MUTANT_BEE_RANGED_ATK_HEALTH_PENALTY
		inst.components.health:DoDelta(delta, nil, "suicidal_attack", nil, nil, true)
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

local function OnKillOther(inst, data)
	local victim = data.victim
	metapisutil.SpawnParasitesOnKill(inst, victim)
end

local function KillerRetarget(inst)
	return FindTarget(inst, TUNING.MUTANT_BEE_TARGET_DIST)
end

local function MutantBeeRetarget(inst)
	return FindTarget(inst, TUNING.MUTANT_BEE_TARGET_DIST)
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

local function MakeLessNoise(inst)
	inst:ListenForEvent("startfollowing", OnStartFollowing)
	inst:ListenForEvent("stopfollowing", OnStopFollowing)
end

local function commonfn(bank, build, tags)
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
local rangedkillerbrain = require("brains/rangedkillerbeebrain")

local function workerbee()
	--pollinator (from pollinator component) added to pristine state for optimization
	--for searching: inst:AddTag("pollinator")
	local inst = nil

	inst = commonfn("mutantworkerbee", "mutantworkerbee", { "worker", "pollinator" })

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

	-- inst:ListenForEvent("killed", OnKillOther)

	MakeHauntableChangePrefab(inst, "mutantkillerbee")

	return inst
end

local function OnSpawnedFromHaunt(inst)
	if inst.components.hauntable ~= nil then
		inst.components.hauntable:Panic()
	end
end

local function killerbee()
	local inst = nil

	inst = commonfn("mutantsoldierbee", "mutantsoldierbee", { "soldier", "killer", "scarytoprey" })

	if not TheWorld.ismastersim then
		return inst
	end

	inst.components.health:SetMaxHealth(TUNING.MUTANT_BEE_SOLDIER_HEALTH)
	inst.components.health:SetAbsorptionAmount(TUNING.MUTANT_BEE_SOLDIER_ABSORPTION)

	inst.components.combat:SetDefaultDamage(TUNING.MUTANT_BEE_DAMAGE)
	inst.components.combat:SetAttackPeriod(TUNING.MUTANT_BEE_ATTACK_PERIOD)
	inst.components.combat:SetRetargetFunction(1, KillerRetarget)
	inst.components.combat.areahitdamagepercent = TUNING.MUTANT_BEE_EXPLOSIVE_DAMAGE_MULTIPLIER

	inst:SetBrain(killerbrain)
	inst.sounds = killersounds
	inst._attackcount = 0

	inst:ListenForEvent("onattackother", OnAttackExplosive)
	-- inst:ListenForEvent("killed", OnKillOther)

	MakeHauntablePanic(inst)
	inst:ListenForEvent("spawnedfromhaunt", OnSpawnedFromHaunt)

	MakeLessNoise(inst)

	return inst
end

local function parasitebee()
	local inst = nil

	inst = commonfn("bee", "mutantbee_angry_build", { "killer", "parasite", "scarytoprey" })

	if not TheWorld.ismastersim then
		return inst
	end

	inst:AddComponent("follower")

	inst.components.health:SetMaxHealth(TUNING.MUTANT_BEE_HEALTH * TUNING.METAPIS_PARASITE_HEALTH_RATE)
	inst.components.combat:SetDefaultDamage(TUNING.MUTANT_BEE_DAMAGE * TUNING.METAPIS_PARASITE_DAMAGE_RATE )
	inst.components.combat:SetAttackPeriod(TUNING.MUTANT_BEE_ATTACK_PERIOD)
	inst.components.combat:SetRetargetFunction(1, KillerRetarget)

	inst.components.lootdropper.numrandomloot = 0 -- No loot for parasite

	inst:SetBrain(killerbrain)
	inst.sounds = killersounds

	MakeHauntablePanic(inst)
	MakeLessNoise(inst)

	inst.Transform:SetScale(0.8, 0.8, 0.8)

	return inst
end

local function OnRangedWeaponAttack(inst, attacker, target)
  --target could be killed or removed in combat damage phase
  if target:IsValid() then
    SpawnPrefab("electrichitsparks"):AlignToTarget(target, inst)
  end
end

local function rangerbee()
	local inst = commonfn("mutantrangerbee", "mutantrangerbee", { "killer", "ranger", "scarytoprey" })

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
		weapon.components.weapon:SetElectric()
		weapon.components.weapon:SetOnAttack(OnRangedWeaponAttack)
		weapon:AddComponent("inventoryitem")
		weapon.persists = false
		weapon.components.inventoryitem:SetOnDroppedFn(weapon.Remove)
		weapon:AddComponent("equippable")
		inst.weapon = weapon
		inst.components.inventory:Equip(inst.weapon)
	end

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
		inst.components.combat:DoAttack(target, nil, nil, "stealthattack", TUNING.MUTANT_BEE_ASSASSIN_BACKSTAB_DAMAGE_MULT)
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

local assassinbeebrain = require "brains/assassinbeebrain"

local function assassinbee()
	local inst = commonfn("mutantassassinbee", "mutantassassinbee", { "killer", "assassin", "scarytoprey" })

	if not TheWorld.ismastersim then
		return inst
	end

	inst.components.locomotor.groundspeedmultiplier = 1.3
	inst:ListenForEvent("onattackother", OnAttackOtherWithPoison)

	inst.components.health:SetMaxHealth(TUNING.MUTANT_BEE_ASSSASIN_HEALTH)
	inst.components.combat:SetDefaultDamage(TUNING.MUTANT_BEE_ASSSASIN_DAMAGE)
	inst.components.combat:SetAttackPeriod(TUNING.MUTANT_BEE_ASSASSIN_ATTACK_PERIOD)
	inst.components.combat:SetRetargetFunction(1, KillerRetarget)
	inst:SetBrain(assassinbeebrain)
	inst.sounds = killersounds

	MakeHauntablePanic(inst)
	MakeLessNoise(inst)

	inst:ListenForEvent("onattackother", OnStealthAttack)

	inst.Stealth = Stealth
	inst.Unstealth = Unstealth

	return inst
end

local poofysounds =
{
    attack = "dontstarve/bee/killerbee_attack",
    --attack = "dontstarve/creatures/together/bee_queen/beeguard/attack",
    buzz = "dontstarve/bee/killerbee_fly_LP",
    hit = "dontstarve/creatures/together/bee_queen/beeguard/hurt",
    death = "dontstarve/creatures/together/bee_queen/beeguard/death",
}

local function IsTaunted(guy)
	return guy.components.combat and guy.components.combat:HasTarget()
		and guy.components.combat.target:HasTag("defender")
end

local function Taunt(inst)
	local x, y, z = inst.Transform:GetWorldPosition()
	local entities = TheSim:FindEntities(x, y, z,
		TUNING.MUTANT_BEE_DEFENDER_TAUNT_DIST,
		{ "_combat", "_health" },
		{ "mutant", "INLIMBO", "player" },
		{ "monster", "insect", "animal", "character" })

	local nearbyplayer, range = FindClosestPlayerToInst(inst, TUNING.MUTANT_BEE_WATCH_DIST, true)

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

	inst._taunttask = inst:DoPeriodicTask(1, Taunt)
end

local function OnDefenderStopCombat(inst)
	if inst._taunttask then
		inst._taunttask:Cancel()
		inst._taunttask = nil
	end
end

local function CauseFrostBite(inst)
	inst._frostbite_expire = GetTime() + 4.75
	inst.AnimState:SetAddColour(82 / 255, 115 / 255, 124 / 255, 0)

	if inst.components.combat and not inst._currentattackperiod then
		inst._currentattackperiod = inst.components.combat.min_attack_period
		inst.components.combat:SetAttackPeriod(inst._currentattackperiod * TUNING.MUTANT_BEE_FROSTBITE_ATK_PERIOD_PENALTY)
	end

	if inst.components.locomotor.enablegroundspeedmultiplier then
		inst.components.locomotor:SetExternalSpeedMultiplier(inst, "frostbite", TUNING.MUTANT_BEE_FROSTBITE_SPEED_PENALTY)
		inst:DoTaskInTime(5.0,
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

		return
	end

	if not inst._currentspeed then
		inst._currentspeed = inst.components.locomotor.groundspeedmultiplier
	end
	inst.components.locomotor.groundspeedmultiplier = TUNING.MUTANT_BEE_FROSTBITE_SPEED_PENALTY
	inst:DoTaskInTime(5.0,
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

  -- MakeFlyingCharacterPhysics(inst, 1.5, .75)
  MakeFlyingCharacterPhysics(inst, 1.5, 0.1)

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
  inst.components.locomotor.pathcaps = { allowocean = true }

  inst:AddComponent("health")
  inst.components.health:SetMaxHealth(TUNING.MUTANT_BEE_DEFENDER_HEALTH)
  inst.components.health:SetAbsorptionAmount(TUNING.MUTANT_BEE_DEFENDER_ABSORPTION)

  inst:AddComponent("combat")
  inst.components.combat:SetDefaultDamage(TUNING.MUTANT_BEE_DEFENDER_DAMAGE)
  inst.components.combat:SetAttackPeriod(TUNING.MUTANT_BEE_DEFENDER_ATTACK_PERIOD)
  inst.components.combat:SetRange(TUNING.MUTANT_BEE_DEFENDER_ATTACK_RANGE)
  inst.components.combat:SetRetargetFunction(1, KillerRetarget)
  inst.components.combat.battlecryenabled = false
  inst.components.combat.hiteffectsymbol = "mane"

  inst:AddComponent("knownlocations")

  inst:ListenForEvent("attacked", beecommon.OnAttacked)
  inst:ListenForEvent("attacked", OnDefenderAttacked)

  MakeSmallBurnableCharacter(inst, "mane")
  MakeSmallFreezableCharacter(inst, "mane")
  inst.components.freezable:SetResistance(2)
  inst.components.freezable.diminishingreturns = true

  inst:SetStateGraph("SGdefenderbee")
  inst:SetBrain(defenderbeebrain)

  MakeHauntablePanic(inst)
  MakeLessNoise(inst)

	inst:ListenForEvent("newcombattarget", OnDefenderStartCombat)
	inst:ListenForEvent("droppedtarget", OnDefenderStopCombat)

  inst.sounds = poofysounds

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
STRINGS.CHARACTERS.GENERIC.DESCRIBE.MUTANTKILLERBEE = "Is it really OK to come near them?"

STRINGS.MUTANTPARASITEBEE = "Metapis Parasite"
STRINGS.NAMES.MUTANTPARASITEBEE = "Metapis Parasite"
STRINGS.CHARACTERS.GENERIC.DESCRIBE.MUTANTPARASITEBEE = "It spawned from the dead body of an enemy."

STRINGS.MUTANTRANGERBEE = "Metapis Ranger"
STRINGS.NAMES.MUTANTRANGERBEE = "Metapis Ranger"
STRINGS.CHARACTERS.GENERIC.DESCRIBE.MUTANTRANGERBEE = "Is it really OK to come near them?"

STRINGS.MUTANTASSASSINBEE = "Metapis Assassin"
STRINGS.NAMES.MUTANTASSASSINBEE = "Metapis Assassin"
STRINGS.CHARACTERS.GENERIC.DESCRIBE.MUTANTASSASSINBEE = "Is it really OK to come near them?"

STRINGS.MUTANTDEFENDERBEE = "Metapis Defender"
STRINGS.NAMES.MUTANTDEFENDERBEE = "Metapis Defender"
STRINGS.CHARACTERS.GENERIC.DESCRIBE.MUTANTDEFENDERBEE = "Is it really OK to come near them?"

return Prefab("mutantbee", workerbee, assets, prefabs),
	Prefab("mutantkillerbee", killerbee, assets, prefabs),
	Prefab("mutantparasitebee", parasitebee, assets, prefabs),
	Prefab("mutantrangerbee", rangerbee, assets, prefabs),
	Prefab("mutantassassinbee", assassinbee, assets, prefabs),
	Prefab("mutantdefenderbee", defenderbee, assets, prefabs)
