local hive_common = require "hive_common"
local hive_defs = require "hive_defs"

local prefabs =
{
  "honeycomb",
  "collapse_small",
}

local function OnSlaveKilled(inst)
  inst.AnimState:PlayAnimation("dead", true)
  RemovePhysicsColliders(inst)

  inst.SoundEmitter:KillSound("loop")

  inst.SoundEmitter:PlaySound("dontstarve/bee/beehive_destroy")
  inst.components.lootdropper:DropLoot(inst:GetPosition())
end

local function OnSlaveHit(inst)
  if not inst.components.health:IsDead() then
    inst.SoundEmitter:PlaySound("dontstarve/bee/beehive_hit")
    inst.AnimState:PlayAnimation("hit")
    inst.AnimState:PushAnimation("idle", true)
  end
end

local function OnSlaveHammered(inst, worker)
  inst.SoundEmitter:PlaySound("dontstarve/bee/beehive_destroy")
  inst.components.lootdropper:DropLoot(inst:GetPosition())

  local fx = SpawnPrefab("collapse_small")
  fx.Transform:SetPosition(inst.Transform:GetWorldPosition())
  fx:SetMaterial("straw")

  inst:Remove()
end

local function CheckMaster(inst)
  if not inst._ownerid then
    OnSlaveHammered(inst)
    return
  end
end


local function commonslavefn(bank, build, tags, mapicon)
  local inst = CreateEntity()

  inst.entity:AddTransform()
  inst.entity:AddAnimState()
  inst.entity:AddSoundEmitter()
  inst.entity:AddMiniMapEntity()
  inst.entity:AddNetwork()

  MakeObstaclePhysics(inst, 1)

  if mapicon then
    inst.MiniMapEntity:SetIcon(mapicon)
  end

  inst.AnimState:SetBank(bank)
  inst.AnimState:SetBuild(build)
  inst.AnimState:PlayAnimation("idle", true)

  inst:AddTag("companion")
  inst:AddTag("mutantslavehive")
  inst:AddTag("beemutant")
  for i, v in ipairs(tags) do
    inst:AddTag(v)
  end

  MakeSnowCoveredPristine(inst)

  inst.entity:SetPristine()

  if not TheWorld.ismastersim then
    return inst
  end

  -------------------
  inst:AddComponent("health")
  inst.components.health:SetMaxHealth(600)

  ---------------------
  MakeLargeBurnable(inst)
  ---------------------

  ---------------------

  inst:AddComponent("combat")
  inst.components.combat:SetOnHit(OnSlaveHit)

  ---------------------

  inst:AddComponent("workable")
  inst.components.workable:SetWorkAction(ACTIONS.HAMMER)
  inst.components.workable:SetWorkLeft(5)
  inst.components.workable:SetOnFinishCallback(OnSlaveHammered)

  ---------------------
  inst:AddComponent("lootdropper")

  ---------------------
  MakeLargePropagator(inst)
  MakeSnowCovered(inst)

  inst:AddComponent("inspectable")
  inst.OnSave = hive_common.OnSave
  inst.OnLoad = hive_common.OnLoad
  inst:ListenForEvent("death", OnSlaveKilled)
  inst:ListenForEvent("onbuilt", hive_common.OnChildBuilt)
  inst:DoPeriodicTask(5, CheckMaster)

  return inst
end

local function MakeChildHive(name, tag)
  local assets = {
    Asset("ANIM", "anim/".. name .. ".zip"),
  }

  local function fn()
    local inst = commonslavefn(name, name, {tag}, name..".tex")
    return inst
  end

  return Prefab(name, fn, assets, prefabs)
end

local function barrackhive()
  local inst = commonslavefn("mutantbarrack", "mutantbarrack", {"mutantbarrack"}, nil)

  if not TheWorld.ismastersim then
    return inst
  end

  inst.components.lootdropper:SetLoot({
    "honeycomb",
    "stinger",
    "stinger",
    "stinger",
    "stinger"
  })

  return inst
end


STRINGS.MUTANTDEFENDERHIVE = "Metapis Moonguard Hive"
STRINGS.NAMES.MUTANTDEFENDERHIVE = "Metapis Moonguard Hive"
STRINGS.CHARACTERS.GENERIC.DESCRIBE.MUTANTDEFENDERHIVE = "As hard as moon rock."
STRINGS.RECIPE_DESC.MUTANTDEFENDERHIVE = "Adds Metapis Moonguard to Mother Hive."

STRINGS.MUTANTRANGERHIVE = "Metapis Voltwing Hive"
STRINGS.NAMES.MUTANTRANGERHIVE = "Metapis Voltwing Hive"
STRINGS.CHARACTERS.GENERIC.DESCRIBE.MUTANTRANGERHIVE = "Looks like an ancient symbol."
STRINGS.RECIPE_DESC.MUTANTRANGERHIVE = "Adds Metapis Voltwing to Mother Hive."

STRINGS.MUTANTASSASSINHIVE = "Metapis Mutant Hive"
STRINGS.NAMES.MUTANTASSASSINHIVE = "Metapis Mutant Hive"
STRINGS.CHARACTERS.GENERIC.DESCRIBE.MUTANTASSASSINHIVE = "Spiky."
STRINGS.RECIPE_DESC.MUTANTASSASSINHIVE = "Adds Metapis Mutant to Mother Hive."

STRINGS.MUTANTSHADOWHIVE = "Metapis Shadow Hive"
STRINGS.NAMES.MUTANTSHADOWHIVE = "Metapis Shadow Hive"
STRINGS.CHARACTERS.GENERIC.DESCRIBE.MUTANTSHADOWHIVE = "It's made from ancient technology."
STRINGS.RECIPE_DESC.MUTANTSHADOWHIVE = "Adds Metapis Shadow to Mother Hive."

STRINGS.MUTANTHEALERHIVE = "Metapis Alchemist Hive"
STRINGS.NAMES.MUTANTHEALERHIVE = "Metapis Alchemist Hive"
STRINGS.CHARACTERS.GENERIC.DESCRIBE.MUTANTHEALERHIVE = "Oozes with honey."
STRINGS.RECIPE_DESC.MUTANTHEALERHIVE = "Adds Metapis Alchemist to Mother Hive."

STRINGS.MUTANTBARRACK = "Metapis Barrack"
STRINGS.NAMES.MUTANTBARRACK = "Metapis Barrack"
STRINGS.CHARACTERS.GENERIC.DESCRIBE.MUTANTBARRACK = "For the swarm."
STRINGS.RECIPE_DESC.MUTANTBARRACK = "Grows your Metapis swarm."

local returnPrefabs = {}

for i, def in ipairs(hive_defs.HiveDefs) do
  table.insert(returnPrefabs, MakeChildHive(def.hive_prefab, def.hive_tag))
  table.insert(returnPrefabs,
    MakePlacer(
      def.hive_prefab.."_placer",
      def.hive_prefab,
      def.hive_prefab,
      "idle"
    )
  )
end

table.insert(returnPrefabs, Prefab("mutantbarrack", barrackhive, {Asset("ANIM", "anim/mutantbarrack.zip")}, prefabs))
table.insert(returnPrefabs, MakePlacer("mutantbarrack_placer", "mutantbarrack", "mutantbarrack", "idle"))

return unpack(returnPrefabs)
