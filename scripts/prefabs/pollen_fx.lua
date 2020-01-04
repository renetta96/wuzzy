local assets =
{
    Asset("ANIM", "anim/pollen_fx.zip"),
}

local function checkplayer(inst)
	if not GetPlayer() then
		-- print("ThePlayer is still nil")
		return
	end

	-- print("ThePlayer is ", ThePlayer)
	inst.task:Cancel()
	if not GetPlayer():HasTag("beemaster") then
		inst:DoTaskInTime(0, inst.Remove)
	end
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()

    inst:AddTag("FX")
    inst:AddTag("pollenfx")

    inst.AnimState:SetBank("pollen_fx")
    inst.AnimState:SetBuild("pollen_fx")
    inst.AnimState:PlayAnimation("idle", true)
    inst.AnimState:SetSortOrder(3)
    inst.Transform:SetScale(3, 3, 3)

    inst.persists = false
    inst.task = inst:DoPeriodicTask(1, checkplayer)

    return inst
end

return Prefab("pollen_fx", fn, assets)
