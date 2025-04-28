local hive_common = require "hive_common"

local prefabs =
{
  "collapse_small",
}

local assets =
{
  Asset("ANIM", "anim/ui_chest_3x2.zip"),
  Asset("ANIM", "anim/mutantcontainer.zip"),
}


local function onchesthammered(inst, worker)
  if inst.components.burnable ~= nil and inst.components.burnable:IsBurning() then
        inst.components.burnable:Extinguish()
    end

  if inst.components.container ~= nil then
    inst.components.container:DropEverything()
  end

  inst.components.lootdropper:DropLoot()
  local fx = SpawnPrefab("collapse_small")
  fx.Transform:SetPosition(inst.Transform:GetWorldPosition())
  fx:SetMaterial("wood")
  inst:Remove()
end

local function onchestwork(inst, worker, workleft)
  if inst.components.container ~= nil then
    inst.components.container:DropEverything()
    inst.components.container:Close()

    inst.AnimState:PlayAnimation("click")
    inst.AnimState:PushAnimation("idle", true)
  end
end

local function onopen(inst)
  if not inst:HasTag("burnt") then
    inst.SoundEmitter:PlaySound("dontstarve/wilson/chest_open")
    inst.AnimState:PlayAnimation("click")
    inst.AnimState:PushAnimation("idle", true)
  end
end

local function onclose(inst)
  if not inst:HasTag("burnt") then
    inst.SoundEmitter:PlaySound("dontstarve/wilson/chest_close")
    inst.AnimState:PlayAnimation("click")
    inst.AnimState:PushAnimation("idle", true)
  end
end

local function chestfn()
  local inst = CreateEntity()

  inst.entity:AddTransform()
  inst.entity:AddAnimState()
  inst.entity:AddSoundEmitter()
  inst.entity:AddMiniMapEntity()
  inst.entity:AddNetwork()

  -- inst.MiniMapEntity:SetIcon("mutantteleportal.tex")

  inst.AnimState:SetBank("mutantcontainer")
  inst.AnimState:SetBuild("mutantcontainer")
  inst.AnimState:PlayAnimation("idle", true)

  inst:AddTag("mutantcontainer")
  inst:AddTag("mutantutil")
  inst:AddTag("beemutant")

  ---------------------------

  MakeSnowCoveredPristine(inst)

  inst.entity:SetPristine()

  if not TheWorld.ismastersim then
    return inst
  end

  inst:AddComponent("inspectable")

  MakeSmallBurnable(inst)

  inst:AddComponent("container")
  inst.components.container:WidgetSetup("mutantcontainer")
  inst.components.container.onopenfn = onopen
  inst.components.container.onclosefn = onclose

  inst:AddComponent("workable")
  inst.components.workable:SetWorkAction(ACTIONS.HAMMER)
  inst.components.workable:SetWorkLeft(5)
  inst.components.workable:SetOnFinishCallback(onchesthammered)
  inst.components.workable:SetOnWorkCallback(onchestwork)

  ---------------------
  inst:AddComponent("lootdropper")

  inst.OnSave = hive_common.OnSave
  inst.OnLoad = hive_common.OnLoad

  inst:ListenForEvent("onbuilt", hive_common.OnChildBuilt)

  return inst
end

STRINGS.MUTANTCONTAINER = "Metapis Container"
STRINGS.NAMES.MUTANTCONTAINER = "Metapis Container"
STRINGS.CHARACTERS.GENERIC.DESCRIBE.MUTANTCONTAINER = "The swarm's provisions."
STRINGS.RECIPE_DESC.MUTANTCONTAINER = "Stores Mother Hive's products."

return Prefab("mutantcontainer", chestfn, assets, prefabs),
  MakePlacer("mutantcontainer_placer", "mutantcontainer", "mutantcontainer", "idle")
