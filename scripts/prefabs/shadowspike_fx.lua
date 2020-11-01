local assets =
{
    Asset("ANIM", "anim/shadowspike_fx.zip"),
}

local strike_anims = {
	"strike_0", "strike_1", "strike_2",
	"strike_0", "strike_1", "strike_2"
}

local function PlayStrikeAnim(inst)
	local r, g, b = inst.AnimState:GetMultColour()
	inst.AnimState:SetMultColour(r, g, b, 0.6)

	local anim = strike_anims[math.random( #strike_anims )]

	inst.AnimState:PlayAnimation(anim)
	inst:ListenForEvent("animover", inst.Remove)
end

local function fn()
	local inst = CreateEntity()

  inst.entity:AddTransform()
  inst.entity:AddAnimState()
  inst.entity:AddNetwork()

  inst:AddTag("FX")
  inst:AddTag("shadowspikefx")

  inst.AnimState:SetBank("shadowspike_fx")
  inst.AnimState:SetBuild("shadowspike_fx")

  if not TheNet:IsDedicated() then
  	inst:DoTaskInTime(0, PlayStrikeAnim)
  end

  inst.entity:SetPristine()

  if not TheWorld.ismastersim then
    return inst
  end

  inst.persists = false
  inst:DoTaskInTime(1, inst.Remove) -- cleanup just in case

  return inst
end

return Prefab("shadowspike_fx", fn, assets)
