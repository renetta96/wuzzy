require "prefabutil"

local assets =
{
  Asset("ANIM", "anim/mutantbeecocoon.zip"),
  Asset("ATLAS", "images/inventoryimages/mutantbeecocoon.xml"),
  Asset("IMAGE", "images/inventoryimages/mutantbeecocoon.tex"),
  Asset("SOUND", "sound/bee.fsb"),
}

local prefabs =
{
  "mutantbeehive",
  "honeycomb",
  "honey",
  "cutgrass"
}

local function UnlinkPlayer(inst)
  inst._ownerid = nil
  inst._owner = nil
end

local function OnRemoveEntity(inst)
  UnlinkPlayer(inst)
  inst:RemoveEventCallback("ms_playerjoined", inst._onplayerjoined, TheWorld)
end

local function ondeploy(inst, pt, deployer)
  inst.SoundEmitter:PlaySound("dontstarve/bee/beehive_hit")
  local hive = SpawnPrefab("mutantbeehive")
  if hive ~= nil then
    hive:InheritOwner(inst)
    UnlinkPlayer(inst)
    hive.Transform:SetPosition(pt:Get())
    inst:Remove()
  end
end

local function candeploy(inst)
  return inst and not inst._hive
end

local function Destroy(inst)
  if inst.components.lootdropper then
    inst.components.lootdropper:DropLoot(inst:GetPosition())
  end

  inst:Remove()
end

local function StopDestroyTask(inst)
  if inst.destroytask then
    inst.destroytask:Cancel()
    inst.destroytask = nil
  end
end

local function StartDestroyTask(inst)
  if not inst.destroytask then
    inst.destroytask = inst:DoTaskInTime(30, Destroy)
  end
end

local function Drop(inst)
  local owner = inst.components.inventoryitem:GetGrandOwner()
  if owner == nil or owner.components.inventory == nil then
    return
  end
  owner.components.inventory:DropItem(inst, true, true)
end

local function IsValidOwner(inst, owner)
  if not owner then
    return false
  end

  if inst._ownerid then
    return owner.userid and owner.userid == inst._ownerid
      and owner.prefab == 'zeta'
  else
    return owner.userid and owner.prefab == 'zeta'
  end
end

local function LinkToPlayer(inst, owner)
  -- A bit redundant check
  if IsValidOwner(inst, owner) then
    inst._ownerid = owner.userid
    inst._owner = owner
    return true
  end

  return false
end

local function InheritOwner(inst, hive)
  inst._ownerid = hive._ownerid
  if hive._owner then
    inst._owner = hive._owner
  end
end

local function OnPutInInventory(inst, owner)
  StopDestroyTask(inst)

  local linksuccess = LinkToPlayer(inst, owner)
  if not linksuccess then
    inst:DoTaskInTime(0, Drop)
  end
end

local function OnDrop(inst)
  StartDestroyTask(inst)
end

local function OnSave(inst, data)
  if inst._ownerid then
    data._ownerid = inst._ownerid
  end
end

local function OnPlayerJoined(inst, player)
  print("PLAYER JOINED COCOON", player)
  -- Don't link to player if this cocoon has no owner
  if not inst._ownerid then
    return
  end

  local linksuccess = LinkToPlayer(inst, player)
  if not linksuccess then
    if inst._ownerid and player.userid and player.userid == inst._ownerid then
      print("SAME PLAYER, DIFFERENT CHARACTER")
      inst:DoTaskInTime(0, function(inst) Destroy(inst) end)
    end
  end
end

local function OnLoad(inst, data)
  if data and data._ownerid then
    inst._ownerid = data._ownerid
  end
end

local function InitFn(inst)
  if inst.components.inventoryitem and not inst.components.inventoryitem:IsHeld() then
    StartDestroyTask(inst)
  end
end

local function fn()
  local inst = CreateEntity()

  inst.entity:AddTransform()
  inst.entity:AddAnimState()
  inst.entity:AddSoundEmitter()
  inst.entity:AddNetwork()
  inst.entity:AddMiniMapEntity()

  MakeInventoryPhysics(inst)

  inst.AnimState:SetBank("mutantbeecocoon")
  inst.AnimState:SetBuild("mutantbeecocoon")
  inst.AnimState:PlayAnimation("idle")
  inst.MiniMapEntity:SetIcon("mutantbeecocoon.tex")

  inst:AddTag("beemutant")
  inst:AddTag("cocoon")

  MakeInventoryFloatable(inst, "med", 0.4, {0.85, 0.6, 0.85})
  inst.entity:SetPristine()

  if not TheWorld.ismastersim then
    return inst
  end

  inst:AddComponent("inspectable")

  MakeSmallPropagator(inst)

  inst:AddComponent("inventoryitem")
  inst.components.inventoryitem.imagename = "mutantbeecocoon"
  inst.components.inventoryitem.atlasname = "images/inventoryimages/mutantbeecocoon.xml"
  inst:ListenForEvent("onputininventory", OnPutInInventory)
  inst:ListenForEvent("ondropped", OnDrop)

  inst:AddComponent("deployable")
  inst.components.deployable:SetDeploySpacing(DEPLOYSPACING.NONE)
  inst.components.deployable.ondeploy = ondeploy
  local OldCanDeploy = inst.components.deployable.CanDeploy
  inst.components.deployable.CanDeploy = function(comp, pt, mouseover)
    return candeploy(inst._owner) and OldCanDeploy(comp, pt, mouseover)
  end

  inst:AddComponent("lootdropper")

  inst.OnSave = OnSave
  inst.OnLoad = OnLoad
  inst.OnRemoveEntity = OnRemoveEntity
  inst.InheritOwner = InheritOwner
  inst._onplayerjoined = function(src, player) OnPlayerJoined(inst, player) end
  inst:ListenForEvent("ms_playerjoined", inst._onplayerjoined, TheWorld)

  inst:DoTaskInTime(0, InitFn)

  return inst
end

STRINGS.MUTANTBEECOCOON = "Metapis Cocoon"
STRINGS.NAMES.MUTANTBEECOCOON = "Metapis Cocoon"
STRINGS.RECIPE_DESC.MUTANTBEECOCOON = "The core of a Metapis hive."
STRINGS.CHARACTERS.GENERIC.DESCRIBE.MUTANTBEECOCOON = "Something is screeching inside."

return Prefab("mutantbeecocoon", fn, assets, prefabs),
  MakePlacer("mutantbeecocoon_placer", "mutantbeehive", "mutantbeehive", "cocoon_small")
