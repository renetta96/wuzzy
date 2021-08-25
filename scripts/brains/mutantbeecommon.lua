local MAX_WANDER_DIST = 32
local MAX_TARGET_SHARES = 10
local SHARE_TARGET_DIST = 30

local function OnAttacked(inst, data)
	local attacker = data and data.attacker

	if not attacker then
		return
	end

	inst.components.combat:SetTarget(attacker)

	-- If attacker has tag "beemutant" or "beemaster" then don't share target
	if attacker:HasTag("beemutant") or attacker:HasTag("beemaster") then
		return
	end

	local targetshares = MAX_TARGET_SHARES
	if inst.components.homeseeker and inst.components.homeseeker.home then
		local home = inst.components.homeseeker.home
		if home and home.components.childspawner then
			targetshares = targetshares - home.components.childspawner.childreninside

			if home.OnHit then
				home:OnHit(attacker)
			end
		end
	end
	inst.components.combat:ShareTarget(attacker, SHARE_TARGET_DIST, function(dude)
		if inst.components.homeseeker and dude.components.homeseeker then  --don't bring bees from other hives
			if dude.components.homeseeker.home and dude.components.homeseeker.home ~= inst.components.homeseeker.home then
				return false
			end
		end

		if dude.components.follower and dude.components.follower.leader then
			return false
		end

		return dude:HasTag("beemutant") and
			not (dude:IsInLimbo() or (dude.components.health and dude.components.health:IsDead()))
	end, targetshares)
end

local function GoHomeAction(inst)
	local homeseeker = inst.components.homeseeker
	if homeseeker
		and homeseeker.home
		and homeseeker.home:IsValid()
		and homeseeker.home.components.childspawner
		and (not homeseeker.home.components.burnable or not homeseeker.home.components.burnable:IsBurning()) then
		return BufferedAction(inst, homeseeker.home, ACTIONS.GOHOME)
	end
end

local function ShouldDespawn(inst)
	if inst._lastcombattime ~= nil and GetTime() <= inst._lastcombattime + 10 then
		return false
	end

	return true
end

local function ShouldGoBackHome(inst)
	if inst._lastcombattime ~= nil and GetTime() <= inst._lastcombattime + math.random(4, 7) then
		return false
	end

	return true
end

local function DespawnAction(inst)
	local follower = inst.components.follower
	if follower and follower.leader
		and follower.leader:IsValid()
		and follower.leader.components.health
		and not follower.leader.components.health:IsDead()
	then
		return BufferedAction(inst, follower.leader, ACTIONS.MUTANTBEE_DESPAWN)
	end
end

return {
	GoHomeAction = GoHomeAction,
	ShouldDespawn = ShouldDespawn,
	ShouldGoBackHome = ShouldGoBackHome,
	DespawnAction = DespawnAction,
	OnAttacked = OnAttacked,
	MAX_WANDER_DIST = MAX_WANDER_DIST,
}
