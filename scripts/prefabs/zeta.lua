
local MakePlayerCharacter = require "prefabs/player_common"


local assets = {
    Asset("SCRIPT", "scripts/prefabs/player_common.lua"),
}
local prefabs = {
	"spoiled_food"
}

-- Custom starting items
local start_inv = {
	"meat", "meat", "meat", "meat"
}

local function DoVirusDamage(inst)
	if inst._virusticks <= 0 or inst.components.health:IsDead() then
		inst.virustask:Cancel()
		inst.virustask = nil
		return
	end

    inst.components.health:DoDelta(TUNING.FRANZ_VIRUS_DAMAGE, true, "virus")  
    inst.AnimState:SetMultColour(1, 0, 1, 1) -- Purple
    inst:DoTaskInTime(0.2, function(inst) inst.AnimState:SetMultColour(1, 1, 1, 1) end)
    inst._virusticks = inst._virusticks - 1

    if inst._virusticks <= 0 or inst.components.health:IsDead() then
		inst.virustask:Cancel()
		inst.virustask = nil
	end
end

local function onattackother(inst, data)
	if data.target and data.target.components.health and not data.target.components.health:IsDead() then
		-- No target players.
		if not data.target:HasTag("player") then
			data.target._virusticks = TUNING.FRANZ_MAX_VIRUS_TICKS
			if data.target.virustask == nil then
				data.target.virustask = data.target:DoPeriodicTask(TUNING.FRANZ_VIRUS_PERIOD, DoVirusDamage)
        	end
    	end
	end
end

local function UpdateDamageMultiplier(inst)
	local multiplier = TUNING.FRANZ_DEFAULT_DAMAGE_MULTIPLIER + TUNING.FRANZ_BONUS_DAMAGE_MULTIPLIER * (1 - inst.components.hunger:GetPercent())
	inst.components.combat.damagemultiplier = multiplier
end

local function UpdateSpeedMultiplier(inst)
	local multiplier = TUNING.FRANZ_DEFAUT_SPEED_MULTIPLIER + TUNING.FRANZ_BONUS_SPEED_MULTIPLIER * (1 - inst.components.hunger:GetPercent())
	inst.components.locomotor:SetExternalSpeedMultiplier(inst, "bloodlust", multiplier)
end

local function RemoveSpeedMultiplier(inst)
	inst.components.locomotor:RemoveExternalSpeedMultiplier(inst, "bloodlust")
end

local function onhungerdelta(inst, data, forcesilent)
	UpdateDamageMultiplier(inst)
	UpdateSpeedMultiplier(inst)
end

-- When the character is revived from human
local function onbecamehuman(inst)
	UpdateDamageMultiplier(inst)
	UpdateSpeedMultiplier(inst)
	inst:ListenForEvent("hungerdelta", onhungerdelta)
end

local function onbecameghost(inst)	
	inst:RemoveEventCallback("hungerdelta", onhungerdelta)
	RemoveSpeedMultiplier(inst)
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
	inst.components.health:SetMaxHealth(TUNING.FRANZ_MAX_HEALTH)
	inst.components.hunger:SetMax(TUNING.FRANZ_MAX_HUNGER)
	inst.components.sanity:SetMax(TUNING.FRANZ_MAX_SANITY)
	inst.components.hunger.hungerrate = TUNING.WILSON_HUNGER_RATE * TUNING.FRANZ_HUNGER_SCALE
	inst.components.combat.damagemultiplier = TUNING.FRANZ_DEFAULT_DAMAGE_MULTIPLIER

	-- Virus damage
	inst:ListenForEvent("onattackother", onattackother)
	
	inst.OnLoad = onload
    inst.OnNewSpawn = onload

    -- Drop rot randomly
    inst:AddComponent("periodicspawner")
    inst.components.periodicspawner:SetPrefab("spoiled_food")
    inst.components.periodicspawner:SetRandomTimes(60, 5)
    inst.components.periodicspawner:SetDensityInRange(10, 3)
    inst.components.periodicspawner:Start()

    -- Eater
    inst.components.eater:SetDiet({ FOODGROUP.OMNI }, { FOODTYPE.MEAT, FOODTYPE.GOODIES })
    inst.components.eater:SetCanEatRaw()
    inst.components.eater:SetCanEatHorrible()
    inst.components.eater:SetAbsorptionModifiers(1, 1, 0.7)
end

return MakePlayerCharacter("zeta", prefabs, assets, common_postinit, master_postinit, start_inv)
