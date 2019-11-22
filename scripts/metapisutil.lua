local function CalcNumParasites(victim)
	-- Must be a living and moving creature
	if not (victim and victim.components.health and victim.components.locomotor) then
		return 0
	end

	if victim.__parasites_spawned then
		return 0
	end

	local victimhealth = victim.components.health.maxhealth
	local numparasites = math.floor(victimhealth / TUNING.METAPIS_PARASITE_HEALTH_DIV)

	if numparasites < TUNING.METAPIS_MAX_PARASITES_PER_VICTIM then
		local remainhealth = victimhealth % TUNING.METAPIS_PARASITE_HEALTH_DIV
		if math.random() < remainhealth / TUNING.METAPIS_PARASITE_HEALTH_DIV then
			numparasites = numparasites + 1
		end
	end

	return math.min(numparasites, TUNING.METAPIS_MAX_PARASITES_PER_VICTIM)
end

local function OnPlayerLeft(inst, player, ownerid)
	if player.userid == ownerid then
		inst.components.health:Kill()
	end
end

local function KillSelf(inst)
	inst.components.health:Kill()
end

local function SpawnParasitesOnKill(killer, victim, prefab)
	if victim:HasTag("mutant") then
		return
	end

	local numparasites = CalcNumParasites(victim)

	if numparasites == 0 then
		return
	end

	local owner = nil

	if killer.prefab == 'zeta' then
		owner = killer
	elseif killer.components.follower and killer.components.follower.leader ~= nil then
		owner = killer.components.follower.leader
	elseif killer.components.homeseeker and killer.components.homeseeker.home and killer.components.homeseeker.home._owner then
		local player = killer.components.homeseeker.home._owner

		if not player:IsValid() then
			return
		end

		local x, y, z = killer.Transform:GetWorldPosition()
		local distsq = player:GetDistanceSqToPoint(x, y, z)
		local rangesq = TUNING.METAPIS_PARASITE_NEAR_OWNER_SPAWN_RANGE * TUNING.METAPIS_PARASITE_NEAR_OWNER_SPAWN_RANGE
		if distsq < rangesq then
			owner = player
		end
	end

	if not (owner and owner.userid) then
		return
	end

	for i = 1, numparasites do
		local bee = SpawnPrefab(prefab or "mutantparasitebee")
		bee.persists = false
		bee._onplayerleft = function(src, player) OnPlayerLeft(bee, player, owner.userid) end
		bee:ListenForEvent("ms_playerleft", bee._onplayerleft, TheWorld)
		bee.Transform:SetPosition(victim.Transform:GetWorldPosition())
		bee:DoTaskInTime(TUNING.METAPIS_PARASITE_LIFE_SPAN, KillSelf)

		if not bee.components.follower then
			bee:AddComponent("follower")
		end

		if owner.components.leader ~= nil then
			owner.components.leader:AddFollower(bee)
		end
	end

	victim.__parasites_spawned = true
end

return {
	SpawnParasitesOnKill = SpawnParasitesOnKill,
	CalcNumParasites = CalcNumParasites
}