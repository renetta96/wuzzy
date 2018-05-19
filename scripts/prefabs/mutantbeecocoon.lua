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
}

local function ondeploy(inst, pt)
    inst.SoundEmitter:PlaySound("dontstarve/bee/beehive_hit")
    local tree = SpawnPrefab("mutantbeehive")
    if tree ~= nil then
        tree.Transform:SetPosition(pt:Get())
        inst.components.stackable:Get():Remove()
    end
end

local function onpickup(inst)
    inst.SoundEmitter:PlaySound("dontstarve/creatures/spider/spider_egg_sack")
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)

    inst.AnimState:SetBank("mutantbeecocoon")
    inst.AnimState:SetBuild("mutantbeecocoon")
    inst.AnimState:PlayAnimation("idle")    

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("stackable")
    inst.components.stackable.maxsize = TUNING.STACK_SIZE_LARGEITEM    
    inst:AddComponent("inspectable")

    -- inst:AddComponent("fuel")
    -- inst.components.fuel.fuelvalue = TUNING.LARGE_FUEL

    -- MakeSmallBurnable(inst, TUNING.LARGE_BURNTIME)
    MakeSmallPropagator(inst)
    -- MakeHauntableLaunchAndIgnite(inst)

    inst:AddComponent("inventoryitem")
    inst.components.inventoryitem.imagename = "mutantbeecocoon"
    inst.components.inventoryitem.atlasname = "images/inventoryimages/mutantbeecocoon.xml"
    -- inst:AddComponent("tradable")

    -- inst.components.inventoryitem:SetOnPickupFn(onpickup)

    inst:AddComponent("deployable")
    --inst.components.deployable:SetDeployMode(DEPLOYMODE.ANYWHERE)
    inst.components.deployable:SetDeploySpacing(DEPLOYSPACING.NONE)
    inst.components.deployable.ondeploy = ondeploy

    return inst
end

STRINGS.MUTANTBEECOCOON = "Mutant Bee Cocoon"
STRINGS.NAMES.MUTANTBEECOCOON = "Mutant Bee Cocoon"
STRINGS.RECIPE_DESC.MUTANTBEECOCOON = "Build an ally beehive."
STRINGS.CHARACTERS.GENERIC.DESCRIBE.MUTANTBEECOCOON = "It has something inside."

return Prefab("mutantbeecocoon", fn, assets, prefabs),
    MakePlacer("mutantbeecocoon_placer", "beehive", "beehive", "cocoon_small")
