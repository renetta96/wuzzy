local MakePlayerCharacter = require "prefabs/player_common"
local helpers = require "helpers"
local metapisutil = require "metapisutil"

local assets = {
	Asset("SCRIPT", "scripts/prefabs/player_common.lua"),
	Asset("ANIM", "anim/zeta.zip"),
}

local prefabs = {
	"mutantbeecocoon",
	"honey"
}

local opentop_hats = {
	"eyebrellahat",
	"gasmaskhat",
	"earmuffshat",
	"flowerhat",
	"shark_teethhat",
	"double_umbrellahat",
	"ruinshat"
}

-- Custom starting items
local start_inv = {
	"mutantbeecocoon",
	"honey",
	"honey",
	"honey"
}

local function OnKillOther(inst, data)
	local victim = data.victim
	metapisutil.SpawnParasitesOnKill(inst, victim)
end

local function OnNumStoreChange(inst)
  local numstore = inst.components.beesummoner.numstore
  local maxstore = inst.components.beesummoner.maxstore

  inst.components.temperature.inherentinsulation = (TUNING.INSULATION_MED / maxstore) * numstore - TUNING.INSULATION_SMALL
end

local function OnEat(inst, data)
	if data.food and data.food.prefab == "zetapollen" then
    inst._eatenpollens = inst._eatenpollens + 1
    if (inst._eatenpollens >= TUNING.OZZY_NUM_POLLENS_PER_HONEY) then
      local honey = SpawnPrefab("honey")
      inst.components.inventory:GiveItem(honey)
      inst._eatenpollens = 0
    end

    return
  end

	if data.food and data.food:HasTag("honeyed") then
		local food = data.food
		local bonus = TUNING.OZZY_HONEYED_FOOD_BONUS

		if inst.components.health then
			local delta = food.components.edible:GetHealth(inst) * inst.components.eater.healthabsorption * bonus
			if delta > 0 then
				inst.components.health:DoDelta(delta, nil, food.prefab)
			end
		end

		if inst.components.hunger then
			local delta = food.components.edible:GetHunger(inst) * inst.components.eater.hungerabsorption * bonus
			if delta > 0 then
				inst.components.hunger:DoDelta(delta)
			end
		end

		if inst.components.sanity then
			local delta = food.components.edible:GetSanity(inst) * inst.components.eater.sanityabsorption * bonus
			if delta > 0 then
				inst.components.sanity:DoDelta(delta)
			end
		end
	end
end

local function OnAttacked(inst, data)
	local attacker = data and data.attacker

	if not attacker then
		return
	end

	if not (attacker:HasTag("mutant") or attacker:HasTag("player")) then
		inst.components.combat:ShareTarget(attacker, TUNING.OZZY_SHARE_TARGET_DIST,
			function(dude)
				return dude:HasTag("mutant") and not (dude:IsInLimbo() or dude.components.health:IsDead())
			end,
			TUNING.OZZY_MAX_SHARE_TARGETS)

		local hive = GetClosestInstWithTag("mutantbeehive", inst, TUNING.OZZY_SHARE_TARGET_DIST)
		if hive then
			hive:OnHit(attacker)
		end
	end
end

local function IsSpringEquivalent()
	local seasonmanager = GetSeasonManager()

	if SaveGameIndex:IsModePorkland() then
		return seasonmanager:IsLushSeason()
	elseif SaveGameIndex:IsModeShipwrecked() then
		return seasonmanager:IsGreenSeason()
	else
		return seasonmanager:IsSpring()
	end

	return false
end

local function IsWinterEquivalent()
	local seasonmanager = GetSeasonManager()

	if SaveGameIndex:IsModePorkland() then
		return seasonmanager:IsHumidSeason()
	elseif SaveGameIndex:IsModeShipwrecked() then
		return seasonmanager:IsWetSeason()
	else
		return seasonmanager:IsWinter()
	end

	return false
end

local function SeasonalChanges(inst)
	if IsSpringEquivalent() then
		inst.components.locomotor:AddSpeedModifier_Mult("season_speed_mod", TUNING.OZZY_SPRING_SPEED_MULTIPLIER)
	elseif IsWinterEquivalent() then
		inst.components.locomotor:AddSpeedModifier_Mult("season_speed_mod", TUNING.OZZY_WINTER_SPEED_MULTIPLIER)
	else
		inst.components.locomotor:AddSpeedModifier_Mult("season_speed_mod", TUNING.OZZY_DEFAULT_SPEED_MULTIPLIER)
	end
end

local function OnEquip(inst)
	local head = inst.components.inventory:GetEquippedItem(EQUIPSLOTS.HEAD)

	if head then
		local isopentop = false
		for i, hat in ipairs(opentop_hats) do
			if head.prefab == hat then
				isopentop = true
				break
			end
		end

		if isopentop then
			inst.AnimState:Show("HEAD")
	    	inst.AnimState:Hide("HEAD_HAT")
		else
			inst.AnimState:Hide("HEAD")
	    	inst.AnimState:Show("HEAD_HAT")
		end
	end
end

local function OnUnequip(inst)
	local head = inst.components.inventory:GetEquippedItem(EQUIPSLOTS.HEAD)

	if not head then
		inst.AnimState:Show("HEAD")
        inst.AnimState:Hide("HEAD_HAT")
	end
end

local function InitFn(inst)
	OnEquip(inst)
	OnUnequip(inst)
end

local postinit = function(inst)
	-- Minimap icon
	inst.MiniMapEntity:SetIcon( "zeta.tex" )
	inst.soundsname = "zeta"

	inst:AddTag("mutant")
	inst:AddTag("insect")
	inst:AddTag("beemaster")

	-- Stats
	inst.components.health:SetMaxHealth(TUNING.OZZY_MAX_HEALTH)
	inst.components.hunger:SetMax(TUNING.OZZY_MAX_HUNGER)
	inst.components.sanity:SetMax(TUNING.OZZY_MAX_SANITY)
	inst.components.hunger.hungerrate = TUNING.WILSON_HUNGER_RATE * TUNING.OZZY_HUNGER_SCALE
	inst.components.combat.damagemultiplier = TUNING.OZZY_DEFAULT_DAMAGE_MULTIPLIER
	inst.components.temperature.inherentinsulation = -TUNING.INSULATION_SMALL

	inst.components.talker.colour = Vector3(.9, .9, .3)

	inst:AddComponent("beesummoner")
	inst.components.beesummoner:SetMaxChildren(TUNING.OZZY_MAX_SUMMON_BEES)
	inst.components.beesummoner:SetSummonChance(TUNING.OZZY_SUMMON_CHANCE)
	inst.components.beesummoner:SetMaxStore(TUNING.OZZY_MAX_BEES_STORE)
	inst:ListenForEvent("onnumstorechange", OnNumStoreChange)

	SeasonalChanges(inst)
	inst:ListenForEvent("seasonChange", function() SeasonalChanges(inst) end, GetWorld())

	inst._eatenpollens = 0
	inst:ListenForEvent("oneat", OnEat)
	inst:ListenForEvent("attacked", OnAttacked)

	inst:ListenForEvent("equip", OnEquip)
	inst:ListenForEvent("unequip", OnUnequip)
	inst:ListenForEvent("killed", OnKillOther)

	InitFn(inst)
end

return MakePlayerCharacter("zeta", prefabs, assets, postinit, start_inv)
