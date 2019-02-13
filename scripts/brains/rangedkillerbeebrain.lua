require "behaviours/chaseandattack"
require "behaviours/wander"
require "behaviours/runaway"
require "behaviours/doaction"
require "behaviours/panic"
require "behaviours/follow"
require "behaviours/faceentity"

local beecommon = require "brains/mutantbeecommon"

local RUN_START_DIST = 8
local RUN_STOP_DIST = 10

local MAX_CHASE_TIME = 10
local MAX_CHASE_DIST = 30

local MIN_FOLLOW_DIST = 4
local MAX_FOLLOW_DIST = 8
local TARGET_FOLLOW_DIST = 6

local function ShouldRunAway(guy)
    return guy:HasTag("monster")
        or (guy.components.combat ~= nil and guy.components.combat.target ~= nil
            and (guy.components.combat.target:HasTag("player") or guy.components.combat.target:HasTag("mutant")))
end

local function IsValidTarget(target)
    return target ~= nil and target:IsValid() and not (target.components.health and target.components.health:IsDead())
end

local function CanAttackNow(inst)
    local target = inst.components.combat.target
    return target == nil
        or (IsValidTarget(target) and not inst.components.combat:InCooldown())
end

local function ShouldDodgeNow(inst)
    return IsValidTarget(inst.components.combat.target) and inst.components.combat:InCooldown()
end

local function ShouldGoHome(inst)
    return not IsValidTarget(inst.components.combat.target)
end

local function GetLeader(inst)
    return inst.components.follower and inst.components.follower.leader
end

local function GetFaceTargetFn(inst)
    return inst.components.follower and inst.components.follower.leader
end

local function KeepFaceTargetFn(inst, target)
    return inst.components.follower ~= nil and inst.components.follower.leader == target
end

local RangedKillerBeeBrain = Class(Brain, function(self, inst)
    Brain._ctor(self, inst)
end)

function RangedKillerBeeBrain:OnStart()
    local root =
        PriorityNode(
        {
            WhileNode(
                function() return self.inst.components.health.takingfiredamage end,
                "OnFire",
                Panic(self.inst)
            ),

        	WhileNode(
                function() return CanAttackNow(self.inst) end,
                "AttackMomentarily",
                ChaseAndAttack(self.inst, MAX_CHASE_TIME, MAX_CHASE_DIST)
            ),
            WhileNode(
                function() return ShouldDodgeNow(self.inst) end,
                "Dodge",
                RunAway(
                    self.inst,
                    function(inst)
                        return FindEntity(inst, RUN_START_DIST, ShouldRunAway, nil, {'notarget'})
                    end,
                    RUN_START_DIST,
                    RUN_STOP_DIST
                )
            ),

            Follow(
                self.inst,
                function() return GetLeader(self.inst) end,
                MIN_FOLLOW_DIST, TARGET_FOLLOW_DIST, MAX_FOLLOW_DIST
            ),
            IfNode(function() return GetLeader(self.inst) ~= nil end, "HasLeader",
                FaceEntity(self.inst, GetFaceTargetFn, KeepFaceTargetFn )),

            IfNode(function() return ShouldGoHome(self.inst) end, "TryGoHome",
                DoAction(self.inst, function() return beecommon.GoHomeAction(self.inst) end, "go home", true )),
            Wander(
                self.inst,
                function() return self.inst.components.knownlocations:GetLocation("home") end,
                beecommon.MAX_WANDER_DIST
            )
        }, 0.5)


    self.bt = BT(self.inst, root)
end

function RangedKillerBeeBrain:OnInitializationComplete()
    self.inst.components.knownlocations:RememberLocation("home", Point(self.inst.Transform:GetWorldPosition()))
end

return RangedKillerBeeBrain