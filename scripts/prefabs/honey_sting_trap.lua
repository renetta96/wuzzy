local assets =
{
  Asset("ANIM", "anim/honey_sting_trap.zip"),
}

local prefabs =
{
    "spoiled_food",
    "honey_sting_spike_0",
    "honey_sting_spike_1"
}

local watch_slow_radius = 8
local radius = 3
local should_tags = { "monster", "insect", "animal", "character" }
local must_tags = { "_combat", "_health"}
local must_not_tags = { "beemutant", "INLIMBO", "player", "notraptrigger", "flying", "ghost", "playerghost", "spawnprotection" }

local function isenemy(guy)
  if not guy:IsValid() then
    return false
  end

  return guy:HasTag("monster") or (
    guy.components.combat and guy.components.combat.target
    and (
      guy.components.combat.target:HasTag("player")
      or guy.components.combat.target:HasTag("beemutant")
    )
  )
end

local function DoDamage(inst)
  local x, y, z = inst.Transform:GetWorldPosition()
  local enemies = TheSim:FindEntities(x, y, z,
    radius,
    must_tags,
    must_not_tags,
    should_tags
  )

  local foundenemy = false

  for i, e in ipairs(enemies) do
    if isenemy(e) and e.components.health and (not e.components.health:IsDead()) then
      e.components.combat:GetAttacked(inst, TUNING.STING_TRAP_DAMAGE)

      if not foundenemy then
        inst.AnimState:PlayAnimation("attack")
        inst.AnimState:PushAnimation("idle", true)
        inst:PushEvent("_attack")
      end

      if inst.components.finiteuses then
        inst.components.finiteuses:Use(1)
      end

      foundenemy = true
    end
  end
end

local function StopDoingDamage(inst)
  if inst._dmgtask ~= nil then
    inst._dmgtask:Cancel()
  end
end

local function StartDoingDamage(inst)
  if inst._dmgtask == nil then
    inst._dmgtask = inst:DoPeriodicTask(2 + math.random(), DoDamage, .9 + math.random() * .4)
  end
end

local function DoSlow(inst)
  local x, y, z = inst.Transform:GetWorldPosition()
  local enemies = TheSim:FindEntities(x, y, z,
    radius,
    must_tags,
    must_not_tags,
    should_tags
  )

  for i, e in ipairs(enemies) do
    if e.components.locomotor and isenemy(e) then
      if e:HasTag("epic") then
        e.components.locomotor:PushTempGroundSpeedMultiplier(TUNING.STING_TRAP_EPIC_SPEED_PENALTY)
      else
        e.components.locomotor:PushTempGroundSpeedMultiplier(TUNING.STING_TRAP_DEFAULT_SPEED_PENALTY)
      end
    end
  end
end

local function StartSlow(inst)
  if inst._slowtask == nil then
    inst._slowtask = inst:DoPeriodicTask(0, DoSlow)
  end
end

local function StopSlow(inst)
  if inst._slowtask ~= nil then
    inst._slowtask:Cancel()
    inst._slowtask = nil
  end
end

local function TryFindSlow(inst)
  local enemy = FindEntity(
    inst,
    watch_slow_radius,
    isenemy,
    must_tags,
    must_not_tags,
    should_tags
  )

  if enemy then
    StartSlow(inst)
  else
    StopSlow(inst)
  end
end

local function onfinished(inst)
  StopDoingDamage(inst)

  inst.AnimState:PlayAnimation("idle", true)
  inst:AddTag("NOCLICK")
  inst.persists = false
  inst:DoTaskInTime(2, ErodeAway)
  inst:PushEvent("_trapfinished")
end

local function ondeploy(inst, pt, deployer)
  local trap = SpawnPrefab("honey_sting_trap")

  if trap ~= nil then
    trap.AnimState:PlayAnimation("idle", true)
    trap.Transform:SetPosition(pt:Get())

    if trap.components.perishable and inst.components.perishable then
      trap.components.perishable:SetPercent(inst.components.perishable:GetPercent())
    end

    inst:Remove()
  end
end

local function CreateSpike(parent, offset)
  local inst = SpawnPrefab("honey_sting_spike_" .. math.random(0, 1))

  inst.entity:SetParent(parent.entity)

  if parent.components.placer ~= nil then
    parent.components.placer:LinkEntity(inst)
  end

  if offset ~= nil then
    inst.Transform:SetPosition(offset:Get())
  end

  inst:ListenForEvent("_attack", function() inst:OnAttack() end, parent)
  inst:ListenForEvent("_trapfinished", function() inst:OnFinished() end, parent)
end

local function CreateSpikes(inst)
  CreateSpike(inst)

  local acc = 0

  for i = 0, 5 do
    if acc > 340 then
      break
    end

    local rx = math.random() * 0.5 + 0.8
    local ry = math.random() * 0.5 + 0.8

    CreateSpike(inst, Vector3(rx * math.sin(acc*DEGREES), 0, ry * math.cos(acc*DEGREES)))

    acc = acc + math.random(50, 70)
  end
end


local function OnInit(inst)
  StartDoingDamage(inst)
  inst:DoPeriodicTask(1, TryFindSlow)

  CreateSpikes(inst)
end

local function OnRemoveEntity(inst)
  StopDoingDamage(inst)
end


local function fn()
  local inst = CreateEntity()

  inst.entity:AddTransform()
  inst.entity:AddAnimState()
  inst.entity:AddNetwork()

  inst.AnimState:SetBank("honey_sting_trap")
  inst.AnimState:SetBuild("honey_sting_trap")
  inst.AnimState:PlayAnimation("idle", true)
  inst.AnimState:SetOrientation(ANIM_ORIENTATION.OnGround)
  inst.AnimState:SetLayer(LAYER_BACKGROUND)
  inst.AnimState:SetSortOrder(-3)

  inst:AddTag("beemutant")
  inst:AddTag("trap")

  inst:SetDeployExtraSpacing(4)

  inst.entity:SetPristine()

  if not TheWorld.ismastersim then
    return inst
  end

  inst:AddComponent("inspectable")

  inst:AddComponent("finiteuses")
  inst.components.finiteuses:SetMaxUses(TUNING.STING_TRAP_USES)
  inst.components.finiteuses:SetUses(TUNING.STING_TRAP_USES)
  inst.components.finiteuses:SetOnFinished(onfinished)

  inst:AddComponent("perishable")
  inst.components.perishable:SetPerishTime(TUNING.PERISH_FASTISH)
  inst.components.perishable:StartPerishing()
  inst.components.perishable:SetOnPerishFn(onfinished)

  inst:DoTaskInTime(0, OnInit)
  inst.OnRemoveEntity = OnRemoveEntity

  return inst
end

local function ball_fn()
  local inst = CreateEntity()

  inst.entity:AddTransform()
  inst.entity:AddAnimState()
  inst.entity:AddNetwork()

  inst.AnimState:SetBank("honey_sting_trap")
  inst.AnimState:SetBuild("honey_sting_trap")
  inst.AnimState:PlayAnimation("ball_idle")

  MakeInventoryPhysics(inst)

  inst:AddTag("beemutant")
  inst:AddTag("show_spoilage")

  inst.entity:SetPristine()

  if not TheWorld.ismastersim then
      return inst
  end

  inst:AddComponent("inspectable")

  inst:AddComponent("inventoryitem")
  inst.components.inventoryitem.imagename = "honey_sting_ball"
  inst.components.inventoryitem.atlasname = "images/inventoryimages/honey_sting_ball.xml"

  inst:AddComponent("deployable")
  inst.components.deployable.ondeploy = ondeploy
  inst.components.deployable:SetDeploySpacing(DEPLOYSPACING.PLACER_DEFAULT)

  inst:AddComponent("perishable")
  inst.components.perishable:SetPerishTime(TUNING.PERISH_FASTISH)
  inst.components.perishable:StartPerishing()
  inst.components.perishable.onperishreplacement = "spoiled_food"

  inst:AddComponent("stackable")
  inst.components.stackable.maxsize = TUNING.STACK_SIZE_LARGEITEM

  return inst
end

STRINGS.HONEY_STING_TRAP = "Sting Trap"
STRINGS.NAMES.HONEY_STING_TRAP = "Sting Trap"
STRINGS.CHARACTERS.GENERIC.DESCRIBE.HONEY_STING_TRAP = "Sticky and deadly."

STRINGS.HONEY_STING_BALL = "Sting Trap"
STRINGS.NAMES.HONEY_STING_BALL = "Sting Trap"
STRINGS.CHARACTERS.GENERIC.DESCRIBE.HONEY_STING_BALL = "Sticky and deadly."
STRINGS.RECIPE_DESC.HONEY_STING_BALL = "A sweet and stingy trap."

return Prefab("honey_sting_trap", fn, assets),
  Prefab("honey_sting_ball", ball_fn, assets, prefabs),
  MakePlacer("honey_sting_ball_placer", "honey_sting_trap", "honey_sting_trap", "idle", true)
