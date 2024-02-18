local function on_put_in_hive(inst, owner)
  if owner and owner.prefab == 'mutantcontainer' and inst.components.perishable then
    inst.components.perishable:StopPerishing()
  end
end

local function on_removed_from_hive(inst, owner)
  if owner and owner.prefab == "mutantcontainer" and inst.components.perishable then
    inst.components.perishable:StartPerishing()
  end
end

local function MakeStopPerishingInHive(inst)
	if not(inst.components.inventoryitem and inst.components.perishable) then
		return
	end

	inst.components.inventoryitem:SetOnPutInInventoryFn(on_put_in_hive)
	local OldOnRemoved = inst.components.inventoryitem.OnRemoved
	inst.components.inventoryitem.OnRemoved = function(comp)
		on_removed_from_hive(comp.inst, comp.owner)
		OldOnRemoved(comp)
	end
end

return {
	MakeStopPerishingInHive = MakeStopPerishingInHive
}
