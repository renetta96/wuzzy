
local MakePlayerCharacter = require "prefabs/player_common"


local assets = {
    Asset("SCRIPT", "scripts/prefabs/player_common.lua"),
}
local prefabs = {
	"spoiled_food"
}

-- Custom starting items
local start_inv = {
}

local function ondeath(inst, data)
	inst._toughness = math.min(inst._toughness + 0.05, TUNING.ATEZAROTH_MAX_TOUGHNESS)
end

local function becomebloodlust_1(inst)
	if inst._state == "bloodlust_1" then
		return
	end

	inst:AddTag("bloodlust")
	inst.components.combat.damagemultiplier = 1.75
	inst.components.locomotor:SetExternalSpeedMultiplier(inst, "bloodlust", 1.5)
	inst._state = "bloodlust_1"
	inst.sg:PushEvent("powerup")
	inst.components.talker:Say(GetString(inst, "ANNOUNCE_BLOODLUST_1"))
end

local function becomebloodlust_2(inst)
	if inst._state == "bloodlust_2" then
		return
	end
	
	inst:AddTag("bloodlust")
	inst.components.combat.damagemultiplier = 1.5
	inst.components.locomotor:SetExternalSpeedMultiplier(inst, "bloodlust", 1.25)

	if inst._state == "bloodlust_1" then
		inst.sg:PushEvent("powerdown")
	elseif inst._state == "normal" then
		inst.sg:PushEvent("powerup")
		inst.components.talker:Say(GetString(inst, "ANNOUNCE_BLOODLUST_2"))
	end

	inst._state = "bloodlust_2"
end

local function becomenormal(inst)
	if inst._state == "normal" then
		return
	end

	inst:RemoveTag("bloodlust")
	inst.components.combat.damagemultiplier = TUNING.ATEZAROTH_DEFAULT_DAMAGE_MULTIPLIER
	inst.components.locomotor:RemoveExternalSpeedMultiplier(inst, "bloodlust")
	inst._state = "normal"
	inst.sg:PushEvent("powerdown")
	inst.components.talker:Say(GetString(inst, "ANNOUNCE_NORMAL"))
end

local function onhungerchange(inst, data, forcesilent)
	if inst:HasTag("playerghost") or inst.components.health:IsDead() then
        return
    end

    if inst.components.hunger:GetPercent() < TUNING.ATEZAROTH_BLOODLUST_THRESHOLD_1 then
    	becomebloodlust_1(inst)
    elseif inst.components.hunger:GetPercent() < TUNING.ATEZAROTH_BLOODLUST_THRESHOLD_2 then
    	becomebloodlust_2(inst)
    else
    	becomenormal(inst)
    end
end

-- When the character is revived from human
local function onbecamehuman(inst)
	-- Toughness
	inst.components.health:SetAbsorptionAmount(inst._toughness)
	-- Bloodlust
	inst:ListenForEvent("hungerdelta", onhungerchange)
	onhungerchange(inst)
end

local function onbecameghost(inst)
	becomenormal(inst)
	inst:RemoveEventCallback("hungerdelta", onhungerchange)
end

-- When loading or spawning the character
local function onload(inst)
    inst:ListenForEvent("ms_respawnedfromghost", onbecamehuman)
    inst:ListenForEvent("ms_becameghost", onbecameghost)

    if inst:HasTag("playerghost") then
        onbecameghost(inst)
    else
        onbecamehuman(inst)
    end
end

local function oneat(inst, food)
	-- Handle eating rot
	if food and food.components.edible and food.prefab == "spoiled_food" then
		local stack_mult = inst.components.eater.eatwholestack and food.components.stackable ~= nil and food.components.stackable:StackSize() or 1

		local health_delta = food.components.edible:GetHealth(inst) * inst.components.eater.healthabsorption
		if health_delta < 0 then
			inst.components.health:DoDelta(-health_delta * stack_mult, nil)
		end

		--[[
		local hunger_delta = food.components.edible:GetHunger(inst) * inst.components.eater.hungerabsorption
		if hunger_delta < 0 then
			inst.components.hunger:DoDelta(-hunger_delta * stack_mult)
		end
		]]

		inst.components.health:DoDelta(15, nil)
	end
end

-- This initializes for both the server and client. Tags can be added here.
local common_postinit = function(inst) 
	-- Minimap icon
	inst.MiniMapEntity:SetIcon( "zeta.tex" )
end

-- This initializes for the server only. Components are added here.
local master_postinit = function(inst)
	-- choose which sounds this character will play
	inst.soundsname = "webber"
	
	-- Uncomment if "wathgrithr"(Wigfrid) or "webber" voice is used
    inst.talker_path_override = "dontstarve_DLC001/characters/"
	
	-- Stats	
	inst.components.health:SetMaxHealth(TUNING.ATEZAROTH_MAX_HEALTH)
	inst.components.hunger:SetMax(TUNING.ATEZAROTH_MAX_HUNGER)
	inst.components.sanity:SetMax(TUNING.ATEZAROTH_MAX_SANITY)
	inst.components.hunger.hungerrate = TUNING.WILSON_HUNGER_RATE * 1.55

	-- Initial state
	inst._state = "normal"

	-- Can eat rot
	inst.components.eater:SetOnEatFn(oneat)

	-- Handle death
	inst._toughness = 0.0
	inst:ListenForEvent('death', ondeath)
	
	inst.OnLoad = onload
    inst.OnNewSpawn = onload

    -- Drop rotten food randomly
    inst:AddComponent("periodicspawner")
    inst.components.periodicspawner:SetPrefab("spoiled_food")
    inst.components.periodicspawner:SetRandomTimes(20, 5)
    inst.components.periodicspawner:SetDensityInRange(10, 3)
    inst.components.periodicspawner:Start()
	
end

return MakePlayerCharacter("zeta", prefabs, assets, common_postinit, master_postinit, start_inv)
