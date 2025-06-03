require "behaviours/chaseandattack"
require "behaviours/runaway"
require "behaviours/wander"
require "behaviours/doaction"
require "behaviours/findflower"
require "behaviours/panic"
local beecommon = require "brains/mutantbeecommon"

local MAX_CHASE_DIST = 15
local MAX_CHASE_TIME = 8

local RUN_AWAY_DIST = 6
local STOP_RUN_AWAY_DIST = 10

local BeeBrain =
  Class(
  Brain,
  function(self, inst)
    Brain._ctor(self, inst)
  end
)

local function IsHomeOnFire(inst)
  return inst.components.homeseeker and inst.components.homeseeker.home and
    inst.components.homeseeker.home.components.burnable and
    inst.components.homeseeker.home.components.burnable:IsBurning()
end

local function ShouldRetreat(inst)
  return inst.components.combat:HasTarget() or
    (inst.components.homeseeker and inst.components.homeseeker.home and inst.components.homeseeker.home.incombat)
end

function BeeBrain:OnStart()
  local root =
    PriorityNode(
    {
      WhileNode(
        function()
          return self.inst.components.hauntable and self.inst.components.hauntable.panic
        end,
        "PanicHaunted",
        Panic(self.inst)
      ),
      WhileNode(
        function()
          return self.inst.components.health.takingfiredamage
        end,
        "OnFire",
        Panic(self.inst)
      ),
      WhileNode(
        function()
          return ShouldRetreat(self.inst)
        end,
        "Retreat",
        DoAction(
          self.inst,
          function()
            return beecommon.GoHomeAction(self.inst)
          end,
          "go home",
          true
        )
      ),
      WhileNode(
        function()
          return self.inst.components.combat:HasTarget()
        end,
        "Dodge",
        RunAway(
          self.inst,
          function()
            return self.inst.components.combat.target
          end,
          RUN_AWAY_DIST,
          STOP_RUN_AWAY_DIST
        )
      ),
      WhileNode(
        function()
          return IsHomeOnFire(self.inst)
        end,
        "HomeOnFire",
        Panic(self.inst)
      ),
      IfNode(
        function()
          return not TheWorld.state.iscaveday or not self.inst.LightWatcher:IsInLight()
        end,
        "IsNight",
        DoAction(
          self.inst,
          function()
            return beecommon.GoHomeAction(self.inst)
          end,
          "go home",
          true
        )
      ),
      IfNode(
        function()
          return self.inst.components.pollinator:HasCollectedEnough()
        end,
        "IsFullOfPollen",
        DoAction(
          self.inst,
          function()
            return beecommon.GoHomeAction(self.inst)
          end,
          "go home",
          true
        )
      ),
      FindFlower(self.inst),
      Wander(
        self.inst,
        function()
          return self.inst.components.knownlocations:GetLocation("home")
        end,
        beecommon.MAX_WANDER_DIST
      )
    },
    1.0
  )

  self.bt = BT(self.inst, root)
end

function BeeBrain:OnInitializationComplete()
  self.inst.components.knownlocations:RememberLocation("home", Point(self.inst.Transform:GetWorldPosition()))
end

return BeeBrain
