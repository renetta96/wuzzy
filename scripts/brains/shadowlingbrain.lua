require "behaviours/chaseandattack"
require "behaviours/runaway"
require "behaviours/wander"

local beecommon = require "brains/mutantbeecommon"

local MAX_CHASE_DIST = 30
local MAX_CHASE_TIME = 10

local RUN_AWAY_DIST = 3
local STOP_RUN_AWAY_DIST = 6

local MIN_FOLLOW_DIST = 2
local MAX_FOLLOW_DIST = 8
local TARGET_FOLLOW_DIST = 3


local function ShouldRunAway(guy)
    return guy:HasTag("monster")
        or (guy.components.combat ~= nil and guy.components.combat.target ~= nil
            and (guy.components.combat.target:HasTag("beemaster") or guy.components.combat.target:HasTag("beemutant")))
end

local ShadowlingBrain = Class(Brain, function(self, inst)
	Brain._ctor(self, inst)
end)

function ShadowlingBrain:OnStart()
	local root =
		PriorityNode(
		{
			WhileNode(
				function() return self.inst.components.combat.target and self.inst.components.combat:InCooldown() end,
				"Dodge",
				RunAway(self.inst, function() return self.inst.components.combat.target end, RUN_AWAY_DIST, STOP_RUN_AWAY_DIST)
			),
			WhileNode(
				function()
					return (not beecommon.IsBeingChased(self.inst, 4)) and
						self.inst.components.combat.target == nil or
						not self.inst.components.combat:InCooldown()
				end,
				"AttackMomentarily",
				ChaseAndAttack(self.inst, SpringCombatMod(MAX_CHASE_TIME), SpringCombatMod(MAX_CHASE_DIST))
			),

			Wander(self.inst, function() return self.inst.components.knownlocations:GetLocation("home") end, beecommon.MAX_WANDER_DIST)
		}, 1 + math.random() * 1.5) -- much longer because shadowlings are a lot


	self.bt = BT(self.inst, root)
end

function ShadowlingBrain:OnInitializationComplete()
	self.inst.components.knownlocations:RememberLocation("home", Point(self.inst.Transform:GetWorldPosition()))
end

return ShadowlingBrain
