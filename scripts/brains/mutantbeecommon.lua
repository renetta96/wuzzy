local MAX_WANDER_DIST = 32

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

local AVOID_EPIC_DIST = 15
local STOP_AVOID_EPIC_DIST = 15

local function FindEpicEnemy(inst, dist)
	return GetClosestInstWithTag({"epic"}, inst, dist or AVOID_EPIC_DIST)
end

-- special cases when epic doesn't explicitly have AOE damage, but still does AOE damage attack
local aoe_bosses = {
	deerclops = {
		estimated_atk_time = 1
	},
	bearger = {
		estimated_atk_time = 1
	},
	alterguardian_phase1 = {
		estimated_atk_time = 3
	},
	shadow_bishop = {
		estimated_atk_time = 4.5
	}
}

local function canareaattack(epic)
	for prefab_or_tag, v in pairs(aoe_bosses) do
		if epic:HasTag(prefab_or_tag) or epic.prefab == prefab_or_tag then
			return true
		end
	end

	return
		epic.components.combat and
		epic.components.combat.areahitdamagepercent ~= nil and
		epic.components.combat.areahitdamagepercent > 0
end

local function estimate_atk_time(epic)
	for prefab_or_tag, v in pairs(aoe_bosses) do
		if epic:HasTag(prefab_or_tag) or epic.prefab == prefab_or_tag then
			return v.estimated_atk_time or 1
		end
	end

	return 1
end

local function IsEpicAttackComing(inst, dist)
	if inst.components.health and inst.components.health:GetPercent() >= 0.5 then
		return false
	end


	local epic = FindEpicEnemy(inst, dist)

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

  -- avoid aoe attack
  if canareaattack(epic) then
  	-- print("EPIC ", epic)
  	local estimated_epic_atk_time = estimate_atk_time(epic)
  	-- print("ATK TIME ", estimated_epic_atk_time)


    if epic.components.combat.laststartattacktime ~= nil and epic.components.combat.laststartattacktime + estimated_epic_atk_time >= GetTime() then
			return true
		end

		-- should leave at least 2 secs to engage
		local start_avoid_cd = epic.components.combat.min_attack_period - estimated_epic_atk_time - 2
		-- print("AVOID CD ", start_avoid_cd)
		if start_avoid_cd >= 0.1 and epic.components.combat:GetCooldown() <= math.min(1, start_avoid_cd) then
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
  		inst._braveendtime = GetTime() + 10 + math.random() * 2 -- for 10 - 12 secs
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

local function AvoidEpicAtkNode(inst, dist)
	return WhileNode(
		function()
			if inst.frenzy_buff then
				return false -- if in frenzy buff, do not avoid
			end

			local iscoming = IsEpicAttackComing(inst, dist)
			-- print("IS EPIC COMING ", iscoming)
			return iscoming
		end,
		"AvoidEpicAttack",
		RunAway(
			inst,
			function() return FindEpicEnemy(inst, dist) end,
			AVOID_EPIC_DIST, STOP_AVOID_EPIC_DIST
		)
	)
end

local function AvoidEpicAtkNode_Defender(inst)
	return WhileNode(
		function()
			if inst.frenzy_buff then
				return false
			end

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

local function FrenzyNode(inst)
	return WhileNode(
		function()
			return inst.frenzy_buff == true
		end,
		"FrenzyAttack",
		ChaseAndAttack(inst, 30, 10)
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

local CircleAroundTarget = Class(BehaviourNode, function(self, inst, radius, avoid_radius, thetaincrement, max_time)
	BehaviourNode._ctor(self, "CircleAroundTarget")

	self.inst = inst
	self.radius = radius
	self.avoid_radius = avoid_radius
	self.theta = 0
  self.thetaincrement = thetaincrement or 1
  self.lasttick = nil
  self.max_time = max_time
end)

function CircleAroundTarget:Visit()
	local combat = self.inst.components.combat

	-- print("VISIT")

	if self.status == READY then
		-- print("READY")

		combat:ValidateTarget()

    if combat.target ~= nil then
      self.inst.components.combat:BattleCry()
      self.startruntime = GetTime()

      -- local pt = Point(combat.target.Transform:GetWorldPosition())
      -- local mypos = Point(self.inst.Transform:GetWorldPosition())
      -- self.theta = VecUtil_GetAngleInRads(mypos.x - pt.x, mypos.z - pt.z)

      self.theta = math.random() * 2 * PI

      self.status = RUNNING
    else
      self.status = FAILED
    end
	end

	if self.status == RUNNING then
		-- recalculate theta
		if self.lasttick ~= nil and GetTick() > self.lasttick then
			local dt = (GetTick() - self.lasttick) * GetTickTime()
			self.theta = self.theta + (dt * self.thetaincrement)
			if self.theta > 2 * PI then
				self.theta = self.theta - 2 * PI
			end
		end

		combat:ValidateTarget()
		if combat.target == nil then
			combat:TryRetarget() -- try retarget once to make movement smooth
		end

		-- print("RUNNING", self.theta)

		if combat.target == nil or not combat.target.entity:IsValid() then
      self.status = FAILED
      combat:SetTarget(nil)
      self.inst.components.locomotor:Stop()
    elseif combat.target.components.health ~= nil and combat.target.components.health:IsDead() then
      self.status = SUCCESS
      combat:SetTarget(nil)
      self.inst.components.locomotor:Stop()
    else
    	local pt = Point(combat.target.Transform:GetWorldPosition())

    	local radius = self.radius
    	if IsEpicAttackComing(self.inst) then
    		radius = self.avoid_radius
    	end

    	local offset = Vector3(radius * math.cos(self.theta), 0, -radius * math.sin(self.theta))
    	local destpos = pt + offset
    	local mypos = Point(self.inst.Transform:GetWorldPosition())
    	-- print("POS", mypos, destpos, pt, offset)

    	if distsq(destpos, mypos) >= 0.15 then	--if you're almost at your target just stop.
				self.inst.components.locomotor:GoToPoint(destpos)
			end

			if self.max_time ~= nil and self.startruntime ~= nil and GetTime() - self.startruntime >= self.max_time then
				self.status = FAILED
        self.inst.components.combat:GiveUp()
        self.inst.components.locomotor:Stop()
        return
			end
    end

    self.lasttick = GetTick()
	end
end

return {
	GoHomeAction = GoHomeAction,
	ShouldDespawn = ShouldDespawn,
	ShouldGoBackHome = ShouldGoBackHome,
	DespawnAction = DespawnAction,
	IsBeingChased = IsBeingChased,
	IsEpicAttackComing = IsEpicAttackComing,
  AvoidEpicAtkNode = AvoidEpicAtkNode,
  AvoidEpicAtkNode_Defender = AvoidEpicAtkNode_Defender,
  CircleAroundTarget = CircleAroundTarget,
  FrenzyNode = FrenzyNode,

	MAX_WANDER_DIST = MAX_WANDER_DIST,
}
