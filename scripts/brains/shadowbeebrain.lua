require "behaviours/chaseandattack"
require "behaviours/runaway"
require "behaviours/wander"
require "behaviours/doaction"
require "behaviours/findflower"
require "behaviours/panic"
require "behaviours/follow"
require "behaviours/faceentity"

local beecommon = require "brains/mutantbeecommon"

local MAX_CHASE_DIST = 30
local MAX_CHASE_TIME = 10

local RUN_AWAY_DIST = 3
local STOP_RUN_AWAY_DIST = 6

local MIN_FOLLOW_DIST = 2
local MAX_FOLLOW_DIST = 8
local TARGET_FOLLOW_DIST = 3

local function ShouldRunAway(guy)
  return guy:HasTag("monster") or
    (guy.components.combat ~= nil and guy.components.combat.target ~= nil and
      (guy.components.combat.target:HasTag("beemaster") or guy.components.combat.target:HasTag("beemutant")))
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

local ShadowBeeBrain =
  Class(
  Brain,
  function(self, inst)
    Brain._ctor(self, inst)
  end
)

function ShadowBeeBrain:OnStart()
  local root =
    PriorityNode(
    {
      beecommon.FrenzyNode(self.inst),
      beecommon.AvoidEpicAtkNode(self.inst),
      WhileNode(
        function()
          if self.inst.frenzy_buff then
            return false
          end

          return beecommon.IsBeingChased(self.inst, 4)
        end,
        "Dodge",
        RunAway(self.inst, ShouldRunAway, RUN_AWAY_DIST, STOP_RUN_AWAY_DIST)
      ),
      WhileNode(
        function()
          if self.inst.frenzy_buff then
            return false
          end

          return (not beecommon.IsBeingChased(self.inst, 4)) and self.inst.components.combat.target == nil or
            not self.inst.components.combat:InCooldown()
        end,
        "AttackMomentarily",
        ChaseAndAttack(self.inst, SpringCombatMod(MAX_CHASE_TIME), SpringCombatMod(MAX_CHASE_DIST))
      ),
      IfNode(
        function()
          return beecommon.ShouldDespawn(self.inst)
        end,
        "TryDespawn",
        DoAction(
          self.inst,
          function()
            return beecommon.DespawnAction(self.inst)
          end,
          "Despawn",
          true
        )
      ),
      Follow(
        self.inst,
        function()
          return GetLeader(self.inst)
        end,
        MIN_FOLLOW_DIST,
        TARGET_FOLLOW_DIST,
        MAX_FOLLOW_DIST
      ),
      IfNode(
        function()
          return GetLeader(self.inst) ~= nil
        end,
        "HasLeader",
        FaceEntity(self.inst, GetFaceTargetFn, KeepFaceTargetFn)
      ),
      IfNode(
        function()
          return beecommon.ShouldGoBackHome(self.inst)
        end,
        "TryGoHome",
        DoAction(
          self.inst,
          function()
            return beecommon.GoHomeAction(self.inst)
          end,
          "GoHome",
          true
        )
      ),
      Wander(
        self.inst,
        function()
          return self.inst.components.knownlocations:GetLocation("home")
        end,
        beecommon.MAX_WANDER_DIST
      )
    },
    1
  )

  self.bt = BT(self.inst, root)
end

function ShadowBeeBrain:OnInitializationComplete()
  self.inst.components.knownlocations:RememberLocation("home", Point(self.inst.Transform:GetWorldPosition()))
end

return ShadowBeeBrain
