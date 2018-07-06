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

local function UnlinkPlayer(inst)
    local owner = inst._owner
    inst._ownerid = nil
    inst._owner = nil
    if owner ~= nil then
        owner._cocoon = nil
    end
end

local function OnRemoveEntity(inst)
    UnlinkPlayer(inst)
    inst:RemoveEventCallback("ms_playerjoined", inst._onplayerjoined, TheWorld)
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
            and owner:HasTag("beemaster") and not (owner._cocoon and owner._cocoon ~= inst)
            and not owner._hive
    else
        return owner.userid and owner:HasTag("beemaster") and not (owner._cocoon and owner._cocoon ~= inst)
            and not owner._hive
    end
end

local function LinkToPlayer(inst, owner)
    -- A bit redundant check
    if IsValidOwner(inst, owner) then
        inst._ownerid = owner.userid
        inst._owner = owner
        owner._cocoon = inst
        return true
    end

    return false
end

local function InheritOwner(inst, hive)
    inst._ownerid = hive._ownerid
    if hive._owner then
        inst._owner = hive._owner
        hive._owner._cocoon = inst
    end
end

local function OnPutInInventory(inst, owner)    
    local linksuccess = LinkToPlayer(inst, owner)
    if not linksuccess then
        inst:DoTaskInTime(0, Drop)        
    end
end

local function OnSave(inst, data)
    if inst._ownerid then
        data._ownerid = inst._ownerid
    end
end

local function OnPlayerJoined(inst, player)
    print("PLAYER JOINED COCOON", player)    
    local linksuccess = LinkToPlayer(inst, player)
    if not linksuccess then
        if inst._ownerid and player.userid and player.userid == inst._ownerid then
            print("SAME PLAYER, DIFFERENT CHARACTER")
            inst:DoTaskInTime(0, function(inst) inst:Remove() end)
        end
    end
end

local function OnLoad(inst, data)
    if data and data._ownerid then
        inst._ownerid = data._ownerid        
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

    inst:AddTag("mutant")
    inst:AddTag("cocoon")

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

    inst:AddComponent("deployable")
    --inst.components.deployable:SetDeployMode(DEPLOYMODE.ANYWHERE)
    inst.components.deployable:SetDeploySpacing(DEPLOYSPACING.NONE)
    inst.components.deployable.ondeploy = ondeploy

    inst.OnSave = OnSave
    inst.OnLoad = OnLoad
    inst.OnRemoveEntity = OnRemoveEntity
    inst.InheritOwner = InheritOwner
    inst._onplayerjoined = function(src, player) OnPlayerJoined(inst, player) end
    inst:ListenForEvent("ms_playerjoined", inst._onplayerjoined, TheWorld)

    return inst
end

STRINGS.MUTANTBEECOCOON = "Mutant Bee Cocoon"
STRINGS.NAMES.MUTANTBEECOCOON = "Mutant Bee Cocoon"
STRINGS.RECIPE_DESC.MUTANTBEECOCOON = "Build an ally beehive."
STRINGS.CHARACTERS.GENERIC.DESCRIBE.MUTANTBEECOCOON = "It has something inside."

return Prefab("mutantbeecocoon", fn, assets, prefabs),
    MakePlacer("mutantbeecocoon_placer", "beehive", "beehive", "cocoon_small")
