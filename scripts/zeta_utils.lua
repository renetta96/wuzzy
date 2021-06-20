local function OnPutInHive(inst, owner)
  if owner and owner.prefab == 'mutantbeehive' and inst.components.perishable then
    inst.components.perishable:StopPerishing()
  end
end

local function OnRemovedFromHive(inst, owner)
  if owner and owner.prefab == "mutantbeehive" and inst.components.perishable then
    inst.components.perishable:StartPerishing()
  end
end

local function MakeStopPerishingInHive(inst)
	if not(inst.components.inventoryitem and inst.components.perishable) then
		return
	end

	inst.components.inventoryitem:SetOnPutInInventoryFn(OnPutInHive)
	local OldOnRemoved = inst.components.inventoryitem.OnRemoved
	inst.components.inventoryitem.OnRemoved = function(comp)
		OnRemovedFromHive(comp.inst, comp.owner)
		OldOnRemoved(comp)
	end
end

return {
	MakeStopPerishingInHive = MakeStopPerishingInHive
}
