
local MakePlayerCharacter = require "prefabs/player_common"


local assets = {
    Asset("SCRIPT", "scripts/prefabs/player_common.lua"),
}
local prefabs = {
	"mutantbeecocoon",
	"honey"
}

-- Custom starting items
local start_inv = {
	"mutantbeecocoon"
}

local function OnEat(inst, data)
	if data.food 
		and (data.food.prefab == "petals" or data.food.prefab == "petals_evil") then
		inst._eatenpetals = inst._eatenpetals + 1
		if (inst._eatenpetals >= TUNING.OZZY_NUM_PETALS_PER_HONEY) then
			local honey = SpawnPrefab("honey")
			honey.Transform:SetPosition(inst.Transform:GetWorldPosition())
			inst._eatenpetals = 0
		end
	end
end

local function OnAttacked(inst, data)
	local attacker = data.attacker
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

-- When the character is revived from human
local function onbecamehuman(inst)
end

local function onbecameghost(inst)	
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
	inst:AddTag("mutant")
	inst:AddTag("insect")
	inst:AddTag("beemaster")
	inst:AddTag(UPGRADETYPES.DEFAULT.."_upgradeuser")
end

-- This initializes for the server only. Components are added here.
local master_postinit = function(inst)
	-- choose which sounds this character will play
	inst.soundsname = "webber"
	
	-- Uncomment if "wathgrithr"(Wigfrid) or "webber" voice is used
    inst.talker_path_override = "dontstarve_DLC001/characters/"
	
	-- Stats	
	inst.components.health:SetMaxHealth(TUNING.OZZY_MAX_HEALTH)
	inst.components.hunger:SetMax(TUNING.OZZY_MAX_HUNGER)
	inst.components.sanity:SetMax(TUNING.OZZY_MAX_SANITY)
	inst.components.hunger.hungerrate = TUNING.WILSON_HUNGER_RATE * TUNING.OZZY_HUNGER_SCALE
	inst.components.combat.damagemultiplier = TUNING.OZZY_DEFAULT_DAMAGE_MULTIPLIER

	inst._eatenpetals = 0
	inst:ListenForEvent("oneat", OnEat)
	inst:ListenForEvent("attacked", OnAttacked)
	
	inst.OnLoad = onload
    inst.OnNewSpawn = onload
end

return MakePlayerCharacter("zeta", prefabs, assets, common_postinit, master_postinit, start_inv)
