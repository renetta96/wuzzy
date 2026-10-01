local function OnSave(inst, data)
  if inst._ownerid then
    data._ownerid = inst._ownerid
  end

  if inst._gathertick then
    data._gathertick = inst._gathertick
  end
end

local function OnLoad(inst, data)
  if data and data._ownerid then
    inst._ownerid = data._ownerid
  end

  if data and data._gathertick then
    inst._gathertick = data._gathertick
  end
end

local function OnChildBuilt(inst, data)
  local owner = data.builder
  if owner and owner:HasTag("player") and owner.prefab == "zeta" then
    inst._ownerid = owner.userid

    if owner._hive ~= nil then
      owner._hive:OnSlave()
    end
  end
end

local function onPutInHive(inst, owner)
  if owner and owner.prefab == "mutantcontainer" and inst.components.perishable then
    inst.components.perishable:StopPerishing()
  end
end

local function onRemovedFromHive(inst, owner)
  if inst.components.perishable and not inst.components.perishable:IsPerishing() then
    inst.components.perishable:StartPerishing()
  end
end

local function MakeStopPerishingInHive(inst)
  if not (inst.components.inventoryitem and inst.components.perishable) then
    return
  end

  inst.components.inventoryitem:SetOnPutInInventoryFn(onPutInHive)

  local oldOnRemoved = inst.components.inventoryitem.OnRemoved
  inst.components.inventoryitem.OnRemoved = function(comp)
    onRemovedFromHive(comp.inst, comp.owner)
    oldOnRemoved(comp)
  end
end

return {
  OnSave = OnSave,
  OnLoad = OnLoad,
  OnChildBuilt = OnChildBuilt,
  MakeStopPerishingInHive = MakeStopPerishingInHive
}
