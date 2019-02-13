require "prefabutil"
local helpers = require "helpers"

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

local function test_ground(inst, pt)
    local basetile = GROUND.DIRT
    if GetWorld():HasTag("shipwrecked") then
        basetile = GROUND.BEACH
    end
    local tile = inst:GetCurrentTileType(pt.x, pt.y, pt.z)

    local ground = GetWorld()
    local onWater = ground.Map:IsWater(tile)

    local player = GetPlayer()
    local hasHive = player._hive

    return not (onWater or hasHive)
end

local function ondeploy(inst, pt)
	inst.SoundEmitter:PlaySound("dontstarve/bee/beehive_hit")
	local hive = SpawnPrefab("mutantbeehive")
	if hive ~= nil then
		hive.isowned = true
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

local function IsValidOwner(owner)
	if not owner then
		return false
	end

	return owner:HasTag("beemaster")
end

local function OnPutInInventory(inst)
	StopDestroyTask(inst)

	local owner = inst.components.inventoryitem:GetGrandOwner()

	if not IsValidOwner(owner) then
		inst:DoTaskInTime(0, Drop)
	end
end

local function OnDrop(inst)
	StartDestroyTask(inst)
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
	inst.components.deployable.ondeploy = ondeploy
    inst.components.deployable.test = test_ground


	inst:AddComponent("lootdropper")

	inst:DoTaskInTime(0, InitFn)

	return inst
end

STRINGS.MUTANTBEECOCOON = "Metapis Cocoon"
STRINGS.NAMES.MUTANTBEECOCOON = "Metapis Cocoon"
STRINGS.RECIPE_DESC.MUTANTBEECOCOON = "The core of a Metapis hive."
STRINGS.CHARACTERS.GENERIC.DESCRIBE.MUTANTBEECOCOON = "Something is screeching inside."

return Prefab("mutantbeecocoon", fn, assets, prefabs),
	MakePlacer("mutantbeecocoon_placer", "beehive", "mutantbeehive", "cocoon_small")
