local assets =
{
    Asset("ANIM", "anim/shadowspike_fx.zip"),
}

local strike_anims = {
	"strike_0", "strike_1", "strike_2",
	"strike_0", "strike_1", "strike_2"
}

local function PlayStrikeAnim(proxy)
  local inst = CreateEntity()

  inst.entity:AddTransform()
  inst.entity:AddAnimState()

  inst:AddTag("FX")
  inst:AddTag("shadowspikefx")
  --[[Non-networked entity]]
  inst.entity:SetCanSleep(false)
  inst.persists = false

  local r, g, b = inst.AnimState:GetMultColour()
  inst.AnimState:SetMultColour(r, g, b, 0.6)

  local parent = proxy.entity:GetParent()
  if parent ~= nil then
    inst.entity:SetParent(parent.entity)
  end

  inst.Transform:SetFromProxy(proxy.GUID)

	local anim = strike_anims[math.random( #strike_anims )]

	inst.AnimState:PlayAnimation(anim)
	inst:ListenForEvent("animover", inst.Remove)
end

local function fn()
	local inst = CreateEntity()

  inst.entity:AddTransform()
  inst.entity:AddNetwork()

  inst:AddTag("FX")
  inst:AddTag("shadowspikefx")

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
