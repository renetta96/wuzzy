local assets = {
  Asset("ANIM", "anim/shadowspike_fx.zip")
}

local strike_anims = {
  "strike_0",
  "strike_1",
  "strike_2",
  "strike_0",
  "strike_1",
  "strike_2"
}

local function PlayStrikeAnim(proxy, anim, scale)
  local inst = CreateEntity()

  inst.entity:AddTransform()
  inst.entity:AddAnimState()
  inst.AnimState:SetBank("shadowspike_fx")
  inst.AnimState:SetBuild("shadowspike_fx")

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
  if scale ~= nil then
    inst.Transform:SetScale(scale, scale, scale)
  end

  if not anim then
    anim = strike_anims[math.random(#strike_anims)]
  end

  inst.AnimState:PlayAnimation(anim)
  inst:ListenForEvent("animover", inst.Remove)
end

local function MakeSpike(anim, scale)
  return function()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddNetwork()

    inst:AddTag("FX")
    inst:AddTag("shadowspikefx")

    if not TheNet:IsDedicated() then
      inst:DoTaskInTime(
        0,
        function()
          PlayStrikeAnim(inst, anim, scale)
        end
      )
    end

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
      return inst
    end

    inst.persists = false
    inst:DoTaskInTime(1, inst.Remove) -- cleanup just in case

    return inst
  end
end

local function doSpikeAnim(proxy, anim, position, scale)
  local inst = CreateEntity()

  inst.entity:AddTransform()
  inst.entity:AddAnimState()
  inst.AnimState:SetBank("shadowspike_fx")
  inst.AnimState:SetBuild("shadowspike_fx")

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

  inst.Transform:SetPosition(position:Get())
  inst.Transform:SetScale(scale, scale, scale)

  inst.AnimState:PlayAnimation(anim)
  inst:ListenForEvent("animover", inst.Remove)
end

local function PlaySpikeRing(proxy, rings)
  local pos = Point(proxy.Transform:GetWorldPosition())
  local seed = math.random() * PI

  for idx, ring in ipairs(rings) do
    proxy:DoTaskInTime(
      ring.delay,
      function()
        for i = 1, ring.num do
          local angle = seed + (2 * PI * i / ring.num)
          if angle > 2 * PI then
            angle = angle - 2 * PI
          end

          local offset = Vector3(ring.radius * math.cos(angle), 0, -ring.radius * math.sin(angle))
          local newPos = pos + offset
          doSpikeAnim(proxy, ring.anim, newPos, ring.scale)
        end
      end
    )
  end
end

local function MakeSpikeRing(rings)
  return function()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddNetwork()

    inst:AddTag("FX")
    inst:AddTag("shadowspikefx")

    if not TheNet:IsDedicated() then
      inst:DoTaskInTime(
        0,
        function()
          PlaySpikeRing(inst, rings)
        end
      )
    end

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
      return inst
    end

    inst.persists = false
    inst:DoTaskInTime(3, inst.Remove) -- cleanup just in case

    return inst
  end
end

local ring_6s = {
  {
    scale = 1.5,
    anim = "strike_0",
    delay = 0,
    radius = 0,
    num = 1
  },
  {
    scale = 1.0,
    anim = "strike_0",
    delay = 0.25,
    radius = 3,
    num = 6
  },
  {
    scale = 0.5,
    anim = "strike_0",
    delay = 0.5,
    radius = 6,
    num = 6
  }
}

local ring_4s = {
  {
    scale = 1.5,
    anim = "strike_0",
    delay = 0,
    radius = 0,
    num = 1
  },
  {
    scale = 1.0,
    anim = "strike_0",
    delay = 0.25,
    radius = 2,
    num = 4
  },
  {
    scale = 0.5,
    anim = "strike_0",
    delay = 0.5,
    radius = 4,
    num = 4
  }
}

local ring_3s = {
  {
    scale = 0.75,
    anim = "strike_0",
    delay = 0.25,
    radius = 2,
    num = 3
  },
  {
    scale = 0.25,
    anim = "strike_0",
    delay = 0.5,
    radius = 4,
    num = 6
  }
}

return Prefab("shadowspike_fx", MakeSpike(), assets), Prefab("big_shadowspike_fx_0", MakeSpike("strike_0"), assets), Prefab(
  "shadowspike_ring_6s",
  MakeSpikeRing(ring_6s),
  assets
), Prefab("shadowspike_ring_4s", MakeSpikeRing(ring_4s), assets), Prefab(
  "shadowspike_ring_3s",
  MakeSpikeRing(ring_3s),
  assets
)
