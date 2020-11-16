local assets =
{
    Asset("ANIM", "anim/pollen_fx.zip"),
}

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    --[[Non-networked entity]]

    inst:AddTag("FX")
    inst:AddTag("CLASSIFIED")
    inst:AddTag("pollenfx")

    inst.AnimState:SetBank("pollen_fx")
    inst.AnimState:SetBuild("pollen_fx")
    inst.AnimState:PlayAnimation("idle", true)
    -- inst.AnimState:SetLayer(LAYER_WORLD)
    inst.AnimState:SetSortOrder(3)
    inst.Transform:SetScale(3, 3, 3)

    inst.persists = false

    return inst
end

return Prefab("pollen_fx", fn, assets)
