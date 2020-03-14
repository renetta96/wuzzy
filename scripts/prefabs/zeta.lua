local MakePlayerCharacter = require "prefabs/player_common"
local helpers = require "helpers"
local metapisutil = require "metapisutil"

local assets = {
	Asset("SCRIPT", "scripts/prefabs/player_common.lua"),
	Asset("ANIM", "anim/zeta.zip"),
}

local prefabs = {
	"mutantbeecocoon",
	"honey",
	"armorhoney",
	"melissa"
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

local tagtoprefab = {
  defender="mutantdefenderbee",
  soldier="mutantkillerbee",
  ranger="mutantrangerbee",
  assassin="mutantassassinbee"
}

local function CanSummon(inst, prefab)
  if not inst._hive then
    return false
  end

  return inst._hive:CanSpawn(prefab)
end

local function GetChildPrefab(inst)
	local maxchildren = inst.components.beesummoner.maxchildren
  local expect = {
    mutantkillerbee = maxchildren,
    mutantdefenderbee = 0,
    mutantrangerbee = 0,
    mutantassassinbee = 0
  }

  local cansummon = {"mutantkillerbee"}

  for i, prefab in ipairs({"mutantdefenderbee", "mutantrangerbee", "mutantassassinbee"}) do
    if CanSummon(inst, prefab) then
      expect[prefab] = expect[prefab] + math.floor(maxchildren / 4)
      expect["mutantkillerbee"] = expect["mutantkillerbee"] - math.floor(maxchildren / 4)
      table.insert(cansummon, prefab)
    end
  end

  local prefabcount = {
    mutantdefenderbee = 0,
    mutantkillerbee = 0,
    mutantrangerbee = 0,
    mutantassassinbee = 0
  }

  for i, child in pairs(inst.components.beesummoner.children) do
    if child ~= nil and child:IsValid() then
      prefabcount[child.prefab] = prefabcount[child.prefab] + 1
    end
  end

  local prefabstopick = {}
  for prefab, cnt in pairs(prefabcount) do
    if cnt < expect[prefab] then
      table.insert(prefabstopick, prefab)

      -- Prioritize defender
      if prefab == "mutantdefenderbee" then
        return prefab
      end
    end
  end

  if #prefabstopick == 0 then
    prefabstopick = cansummon
  end

  return prefabstopick[math.random(#prefabstopick)]
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

local function CheckHiveUpgrade(inst)
  if not inst._hive then
    return
  end

  local slaves = inst._hive:GetSlaves()
  inst.components.beesummoner:SetMaxChildren(
    TUNING.OZZY_MAX_SUMMON_BEES + math.floor(#slaves / 3)
  )
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

local function GetDefenderHiveIngredients()
	if SaveGameIndex:IsModePorkland() then
		return {
			Ingredient("hippo_antler", 2),
	    Ingredient("honeycomb", 1),
	    Ingredient("alloy", 3)
		}
	elseif SaveGameIndex:IsModeShipwrecked() then
		return {
			Ingredient("ox_horn", 2),
	    Ingredient("honeycomb", 1),
	    Ingredient("limestone", 5)
		}
	else
		return {
			Ingredient("horn", 2),
	    Ingredient("honeycomb", 1),
	    Ingredient("cutstone", 10)
		}
	end
end

local function GetRangerHiveIngredients()
	if SaveGameIndex:IsModePorkland() then
		return {
	    Ingredient("bill_quill", 2),
	    Ingredient("honeycomb", 1),
	    Ingredient("chitin", 30)
	  }
	elseif SaveGameIndex:IsModeShipwrecked() then
		return {
			Ingredient("feather_robin_winter", 2),
	    Ingredient("honeycomb", 1),
	    Ingredient("sand", 30)
		}
	else
		return {
			Ingredient("feather_robin", 4),
	    Ingredient("honeycomb", 1),
	    Ingredient("cutstone", 10)
		}
	end
end

local function GetAssassinHiveIngredients()
	if SaveGameIndex:IsModePorkland() then
		return {
	    Ingredient("venomgland", 3),
	    Ingredient("honeycomb", 1),
	    Ingredient("nightmarefuel", 20)
	  }
	elseif SaveGameIndex:IsModeShipwrecked() then
		return {
			Ingredient("mosquitosack_yellow", 2),
	    Ingredient("honeycomb", 1),
	    Ingredient("nightmarefuel", 20)
		}
	else
		return {
			Ingredient("mosquitosack", 4),
	    Ingredient("honeycomb", 1),
	    Ingredient("nightmarefuel", 20)
		}
	end
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
	inst.components.beesummoner.childprefabfn = GetChildPrefab
	inst:ListenForEvent("onnumstorechange", OnNumStoreChange)
	inst:DoPeriodicTask(1, CheckHiveUpgrade)

	SeasonalChanges(inst)
	inst:ListenForEvent("seasonChange", function() SeasonalChanges(inst) end, GetWorld())

	inst._eatenpollens = 0
	inst:ListenForEvent("oneat", OnEat)
	inst:ListenForEvent("attacked", OnAttacked)

	inst:ListenForEvent("equip", OnEquip)
	inst:ListenForEvent("unequip", OnUnequip)

	InitFn(inst)

	-- Recipes
	local cocoonrecipe = Recipe("mutantbeecocoon",
	  {
	    Ingredient("honeycomb", 1),
	    Ingredient("cutgrass", 4),
	    Ingredient("honey", 1)
	  },
	  RECIPETABS.SURVIVAL,
	  TECH.NONE
	)
	cocoonrecipe.atlas = "images/inventoryimages/mutantbeecocoon.xml"

	local armorhoneyrecipe = Recipe("armorhoney",
	  {
	    Ingredient("log", 10),
	    Ingredient("rope", 1),
	    Ingredient("honey", 3)
	  },
	  RECIPETABS.WAR,
	  TECH.NONE
	)
	armorhoneyrecipe.atlas = "images/inventoryimages/armorhoney.xml"

	local melissarecipe = Recipe("melissa",
	  {
	    Ingredient("twigs", 2),
	    Ingredient("goldnugget", 1),
	    Ingredient("stinger", 5)
	  },
	  RECIPETABS.WAR,
	  TECH.NONE
	)
	melissarecipe.atlas = "images/inventoryimages/melissa.xml"

	melissarecipe.sortkey = 1
	armorhoneyrecipe.sortkey = 2

	local mutantdefenderhive_rec = Recipe("mutantdefenderhive",
	  GetDefenderHiveIngredients(),
	  RECIPETABS.TOWN,
	  TECH.SCIENCE_TWO,
	  nil,
	  "mutantdefenderhive_placer"
  )
  mutantdefenderhive_rec.atlas = "images/inventoryimages/mutantdefenderhive.xml"

	local mutantrangerhive_rec = Recipe("mutantrangerhive",
		GetRangerHiveIngredients(),
	  RECIPETABS.TOWN,
	  TECH.SCIENCE_TWO,
	  nil,
	  "mutantrangerhive_placer"
	)
	mutantrangerhive_rec.atlas = "images/inventoryimages/mutantrangerhive.xml"

	local mutantassassinhive_rec = Recipe("mutantassassinhive",
		GetAssassinHiveIngredients(),
	  RECIPETABS.TOWN,
	  TECH.SCIENCE_TWO,
	  nil,
	  "mutantassassinhive_placer"
	)
	mutantassassinhive_rec.atlas = "images/inventoryimages/mutantassassinhive.xml"
end

return MakePlayerCharacter("zeta", prefabs, assets, postinit, start_inv)
