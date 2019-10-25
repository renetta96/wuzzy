local assets =
{
    Asset("ANIM", "anim/pollen_fx.zip"),
}

local function checkplayer(inst)
	if not ThePlayer then
		-- print("ThePlayer is still nil")
		return
	end

	-- print("ThePlayer is ", ThePlayer)
	inst.task:Cancel()
	if not ThePlayer:HasTag("beemaster") then
		inst:DoTaskInTime(0, inst.Remove)
	end
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    inst:AddTag("FX")
    inst:AddTag("pollenfx")

    inst.AnimState:SetBank("pollen_fx")
    inst.AnimState:SetBuild("pollen_fx")
    inst.AnimState:PlayAnimation("idle", true)
    -- inst.AnimState:SetLayer(LAYER_WORLD)
    inst.AnimState:SetSortOrder(3)
    inst.Transform:SetScale(3, 3, 3)

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
   		inst.task = inst:DoPeriodicTask(1, checkplayer)
    	-- print("THIS IS CLIENT ", ThePlayer)

     	return inst
    end


    inst.persists = false
    -- print("THIS SERVER IS DEDICATED? ", TheNet:IsDedicated(), ThePlayer)

    -- Dedicated server always keep the fx
    if not TheNet:IsDedicated() then
    	inst.task = inst:DoPeriodicTask(1, checkplayer)
    end

    return inst
end

return Prefab("pollen_fx", fn, assets)
