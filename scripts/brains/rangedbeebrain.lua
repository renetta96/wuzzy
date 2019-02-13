require "behaviours/chaseandattack"
require "behaviours/wander"
require "behaviours/runaway"
require "behaviours/doaction"
require "behaviours/panic"
require "behaviours/findflower"

local beecommon = require "brains/mutantbeecommon"

local RUN_START_DIST = 8
local RUN_STOP_DIST = 10

local MAX_CHASE_TIME = 8
local MAX_CHASE_DIST = 25

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
    local clock = GetClock()

    return not IsValidTarget(inst.components.combat.target)
        and (clock and not clock:IsDay())
end

local function IsHomeOnFire(inst)
    return inst.components.homeseeker
        and inst.components.homeseeker.home
        and inst.components.homeseeker.home.components.burnable
        and inst.components.homeseeker.home.components.burnable:IsBurning()
end

local RangedBeeBrain = Class(Brain, function(self, inst)
    Brain._ctor(self, inst)
end)

function RangedBeeBrain:OnStart()
    local root = PriorityNode(
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

        WhileNode(function() return IsHomeOnFire(self.inst) end, "HomeOnFire", Panic(self.inst)),
        IfNode(function() return ShouldGoHome(self.inst) end, "TryGoHome",
            DoAction(self.inst, function() return beecommon.GoHomeAction(self.inst) end, "go home", true )),

        FindFlower(self.inst),
        Wander(self.inst, function() return self.inst.components.knownlocations:GetLocation("home") end, beecommon.MAX_WANDER_DIST),
    }, 0.5)

    self.bt = BT(self.inst, root)
end

function RangedBeeBrain:OnInitializationComplete()
    self.inst.components.knownlocations:RememberLocation("home", Point(self.inst.Transform:GetWorldPosition()))
end

return RangedBeeBrain
