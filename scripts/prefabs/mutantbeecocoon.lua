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
	local owner = inst._owner
	inst.isowned = false
	inst._owner = nil
	if owner ~= nil then
		owner._cocoon = nil
	end
end

local function OnRemoveEntity(inst)
	UnlinkPlayer(inst)
	inst:RemoveEventCallback("ms_playerjoined", inst._onplayerjoined, TheWorld)
end

local function test_ground(inst, pt)
    local basetile = GROUND.DIRT
    if GetWorld():HasTag("shipwrecked") then
        basetile = GROUND.BEACH
    end
    local tile = inst:GetCurrentTileType(pt.x, pt.y, pt.z)

    local ground = GetWorld()
    local onWater = ground.Map:IsWater(tile)
    return not onWater
end

local function ondeploy(inst, pt)
	inst.SoundEmitter:PlaySound("dontstarve/bee/beehive_hit")
	local hive = SpawnPrefab("mutantbeehive")
	if hive ~= nil then
		hive:InheritOwner(inst)
		UnlinkPlayer(inst)
		hive.Transform:SetPosition(pt:Get())
		inst:Remove()
	end
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

	return owner:HasTag("beemaster") and not (owner._cocoon and owner._cocoon ~= inst)
		and not owner._hive
end

local function LinkToPlayer(inst, owner)
	-- A bit redundant check
	if IsValidOwner(inst, owner) then
		inst.isowned = true
		inst._owner = owner
		owner._cocoon = inst
		return true
	end

	return false
end

local function InheritOwner(inst, hive)
	inst.isowned = hive.isowned
	if hive._owner then
		inst._owner = hive._owner
		hive._owner._cocoon = inst
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
	if inst.isowned then
		data.isowned = inst.isowned
	end
end

local function OnPlayerJoined(inst)
	local player = GetPlayer()
	local linksuccess = LinkToPlayer(inst, player)

	if not linksuccess then
		inst:DoTaskInTime(0, function(inst) Destroy(inst) end)
	end
end

local function OnLoad(inst, data)
	if data and data.isowned then
		inst.isowned = data.isowned
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
	inst.entity:AddMiniMapEntity()

	MakeInventoryPhysics(inst)
	MakeInventoryFloatable(inst, "idle_water", "idle")

	inst.AnimState:SetBank("mutantbeecocoon")
	inst.AnimState:SetBuild("mutantbeecocoon")
	inst.AnimState:PlayAnimation("idle")
	inst.MiniMapEntity:SetIcon("mutantbeecocoon.tex")

	inst:AddTag("mutant")
	inst:AddTag("cocoon")

	inst:AddComponent("inspectable")

	MakeSmallPropagator(inst)

	inst:AddComponent("inventoryitem")
	inst.components.inventoryitem.imagename = "mutantbeecocoon"
	inst.components.inventoryitem.atlasname = "images/inventoryimages/mutantbeecocoon.xml"
	inst:ListenForEvent("onputininventory", OnPutInInventory)
	inst:ListenForEvent("ondropped", OnDrop)

	inst:AddComponent("deployable")
    inst.components.deployable.test = test_ground
    inst.components.deployable.ondeploy = ondeploy

	inst:AddComponent("lootdropper")

	inst.OnSave = OnSave
	inst.OnLoad = OnLoad
	inst.OnRemoveEntity = OnRemoveEntity
	inst.InheritOwner = InheritOwner
	OnPlayerJoined(inst)

	inst:DoTaskInTime(0, InitFn)

	return inst
end

STRINGS.MUTANTBEECOCOON = "Metapis Cocoon"
STRINGS.NAMES.MUTANTBEECOCOON = "Metapis Cocoon"
STRINGS.RECIPE_DESC.MUTANTBEECOCOON = "The core of a Metapis hive."
STRINGS.CHARACTERS.GENERIC.DESCRIBE.MUTANTBEECOCOON = "Something is screeching inside."

return Prefab("mutantbeecocoon", fn, assets, prefabs),
	MakePlacer("mutantbeecocoon_placer", "beehive", "mutantbeehive", "cocoon_small")
