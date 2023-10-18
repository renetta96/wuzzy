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

local AVOID_EPIC_DIST = TUNING.DEERCLOPS_AOE_RANGE + 5
local STOP_AVOID_EPIC_DIST = TUNING.DEERCLOPS_AOE_RANGE + 5

local function FindEpicEnemy(inst)
	return GetClosestInstWithTag({"epic"}, inst, AVOID_EPIC_DIST)
end


local function IsEpicAttackComing(inst)
	local epic = FindEpicEnemy(inst)

  if not epic then
  	return false
  end

  -- calc avoid timed atk time
  if epic.components.timer and epic.components.timer.timers then
  	local min_end_time = nil

    for k, v in pairs(epic.components.timer.timers) do
      if v ~= nil and (not epic.components.timer:IsPaused(k)) and epic.components.timer:GetTimeLeft(k) <= 1 then
      	if min_end_time == nil or min_end_time > v.end_time then
      		min_end_time = v.end_time
      	end
      end
    end

    if min_end_time ~= nil then
    	inst._avoidendtime = min_end_time + 2 + math.random() * 2 -- avoid for 2-4 secs more
    end
  end

  -- avoid attack
  if epic.components.combat then
    if epic.components.combat.laststartattacktime ~= nil and epic.components.combat.laststartattacktime + 1 >= GetTime() then
			return true
		end

		if epic.components.combat:GetCooldown() <= 1 then
			return true
		end
	end

	if inst._braveendtime ~= nil and inst._braveendtime >= GetTime() then
  	return false
  end

  if inst._avoidendtime ~= nil and inst._avoidendtime >= GetTime() then
  	-- 25% to be brave, fuck it we ball
  	if math.random() <= 0.25 then
  		inst._avoidendtime = nil
  		inst._braveendtime = GetTime() + 1 + math.random() * 2
  		-- print("FUCK IT WE BALL ", GetTime(), inst._braveendtime)
  		return false
  	end

  	-- print("AVOID TIMED ATTACK ", GetTime(), inst._avoidendtime)
  	return true
  end

	return false
end

local function IsEpicAttackComing_Defender(inst)
	local epic = FindEpicEnemy(inst)

	if not epic then
		return false
	end

	local x, y, z = epic.Transform:GetWorldPosition()
	local defenders = TheSim:FindEntities(x, y, z, 10, { "beemutant", "defender" })

	-- if no defenders engaging boss, then engage
	if #defenders == 0 then
		return false
	end

	local min_fate = 1000000 + 1
	for i, d in pairs(defenders) do
		if d:IsValid() and d._fate ~= nil then
			min_fate = math.min(min_fate, d._fate)
		end
	end

	-- if having min fate, do not run
	if inst._fate ~= nil and inst._fate == min_fate then
		return false
	end

	return IsEpicAttackComing(inst)
end

local function AvoidEpicAtkNode(inst)
	return WhileNode(
		function()
			local iscoming = IsEpicAttackComing(inst)
			-- print("IS EPIC COMING ", iscoming)
			return iscoming
		end,
		"AvoidEpicAttack",
		RunAway(
			inst,
			function() return FindEpicEnemy(inst) end,
			AVOID_EPIC_DIST, STOP_AVOID_EPIC_DIST
		)
	)
end

local function AvoidEpicAtkNode_Defender(inst)
	return WhileNode(
		function()
			return IsEpicAttackComing_Defender(inst)
		end,
		"AvoidEpicAttack",
		RunAway(
			inst,
			function() return FindEpicEnemy(inst) end,
			AVOID_EPIC_DIST, STOP_AVOID_EPIC_DIST
		)
	)
end

local function IsBeingChased(inst, dist)
	if dist == nil then
		dist = 8
	end

	local enemy = FindEntity(inst, dist,
		function(guy)
			return guy.components.combat and guy.components.combat:TargetIs(inst)
		end,
		{ "_combat", "_health" },
		{ "beemutant", "INLIMBO", "player" },
		{ "monster", "insect", "animal", "character", "epic" })

	if enemy then
		return true
	end

	return false
end

return {
	GoHomeAction = GoHomeAction,
	ShouldDespawn = ShouldDespawn,
	ShouldGoBackHome = ShouldGoBackHome,
	DespawnAction = DespawnAction,
	OnAttacked = OnAttacked,
	IsBeingChased = IsBeingChased,
	IsEpicAttackComing = IsEpicAttackComing,

  AvoidEpicAtkNode = AvoidEpicAtkNode,
  AvoidEpicAtkNode_Defender = AvoidEpicAtkNode_Defender,

	MAX_WANDER_DIST = MAX_WANDER_DIST,
}
