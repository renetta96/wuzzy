local hive_common = require "hive_common"

local prefabs =
{
  "honeycomb",
  "collapse_small",
}

local assets =
{
  Asset("ANIM", "anim/mutantdefenderhive.zip"),
  Asset("ANIM", "anim/mutantassassinhive.zip"),
  Asset("ANIM", "anim/mutantrangerhive.zip"),
  Asset("ANIM", "anim/mutantshadowhive.zip"),
  Asset("ANIM", "anim/mutanthealerhive.zip"),
  Asset("ANIM", "anim/mutantbarrack.zip"),
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

local function defenderhive()
  local inst = commonslavefn("mutantdefenderhive", "mutantdefenderhive", {"mutantdefenderhive"}, "mutantdefenderhive.tex")
  return inst
end

local function rangerhive()
  local inst = commonslavefn("mutantrangerhive", "mutantrangerhive", {"mutantrangerhive"}, "mutantrangerhive.tex")
  return inst
end

local function assassinhive()
  local inst = commonslavefn("mutantassassinhive", "mutantassassinhive", {"mutantassassinhive"}, "mutantassassinhive.tex")
  return inst
end

local function shadowhive()
  local inst = commonslavefn("mutantshadowhive", "mutantshadowhive", {"mutantshadowhive"}, "mutantshadowhive.tex")
  return inst
end

local function healerhive()
  -- TODO: update art
  local inst = commonslavefn("mutanthealerhive", "mutanthealerhive", {"mutanthealerhive"}, "mutanthealerhive.tex")
  return inst
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

STRINGS.MUTANTRANGERHIVE = "Metapis Ranger Hive"
STRINGS.NAMES.MUTANTRANGERHIVE = "Metapis Ranger Hive"
STRINGS.CHARACTERS.GENERIC.DESCRIBE.MUTANTRANGERHIVE = "Looks like an ancient symbol."
STRINGS.RECIPE_DESC.MUTANTRANGERHIVE = "Adds Metapis Ranger to Mother Hive."

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

return Prefab("mutantdefenderhive", defenderhive, assets, prefabs),
  MakePlacer("mutantdefenderhive_placer", "mutantdefenderhive", "mutantdefenderhive", "idle"),
  Prefab("mutantrangerhive", rangerhive, assets, prefabs),
  MakePlacer("mutantrangerhive_placer", "mutantrangerhive", "mutantrangerhive", "idle"),
  Prefab("mutantassassinhive", assassinhive, assets, prefabs),
  MakePlacer("mutantassassinhive_placer", "mutantassassinhive", "mutantassassinhive", "idle"),
  Prefab("mutantshadowhive", shadowhive, assets, prefabs),
  MakePlacer("mutantshadowhive_placer", "mutantshadowhive", "mutantshadowhive", "idle"),
  Prefab("mutanthealerhive", healerhive, assets, prefabs),
  MakePlacer("mutanthealerhive_placer", "mutanthealerhive", "mutanthealerhive", "idle"),
  Prefab("mutantbarrack", barrackhive, assets, prefabs),
  MakePlacer("mutantbarrack_placer", "mutantbarrack", "mutantbarrack", "idle")
