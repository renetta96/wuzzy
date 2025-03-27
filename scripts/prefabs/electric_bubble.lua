local metapis_common = require "metapis_common"
local BarrackModifier = metapis_common.BarrackModifier

local assets = {
    Asset("ANIM", "anim/electric_bubble.zip")
}

local function OnHit(inst, owner, target)
    SpawnPrefab("electric_bubble_hit").Transform:SetPosition(inst.Transform:GetWorldPosition())
    inst:Remove()
end

local function OnAnimOver(inst)
    inst:DoTaskInTime(0.3, inst.Remove)
end

local function OnThrown(inst)
    inst:ListenForEvent("animover", OnAnimOver)
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()
    inst.entity:AddLight()

    inst.Light:Enable(true)
    inst.Light:SetRadius(0.3)
    inst.Light:SetFalloff(0.5)
    inst.Light:SetIntensity(.75)
    inst.Light:SetColour(154 / 255, 214 / 255, 216 / 255)

    inst.Transform:SetScale(0.6, 0.6, 0.6)

    MakeInventoryPhysics(inst)
    RemovePhysicsColliders(inst)

    inst.Transform:SetFourFaced()

    inst.AnimState:SetBank("electric_bubble")
    inst.AnimState:SetBuild("electric_bubble")
    inst.AnimState:PlayAnimation("idle")

    inst.AnimState:SetBloomEffectHandle("shaders/anim.ksh")
    inst.AnimState:SetLightOverride(0.05)

    --projectile (from projectile component) added to pristine state for optimization
    inst:AddTag("projectile")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst.persists = false

    inst:AddComponent("projectile")
    inst.components.projectile:SetSpeed(60)
    inst.components.projectile:SetHoming(false)
    inst.components.projectile:SetHitDist(2)
    inst.components.projectile:SetOnHitFn(OnHit)
    inst.components.projectile:SetOnMissFn(inst.Remove)
    inst.components.projectile:SetOnThrownFn(OnThrown)
    inst.components.projectile:SetLaunchOffset(Vector3(0.5, 1, 0))

    return inst
end

local function PlayHitSound(proxy)
    local inst = CreateEntity()

    --[[Non-networked entity]]
    inst.entity:AddTransform()
    inst.entity:AddSoundEmitter()

    inst.Transform:SetFromProxy(proxy.GUID)

    inst.SoundEmitter:PlaySound("dontstarve/characters/wx78/spark")

    inst:Remove()
end

local function hit_fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddNetwork()

    --Dedicated server does not need to spawn the local fx
    if not TheNet:IsDedicated() then
        --Delay one frame in case we are about to be removed
        inst:DoTaskInTime(0, PlayHitSound)
    end

    inst:AddTag("FX")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst.persists = false
    inst:DoTaskInTime(0.5, inst.Remove)

    return inst
end

local function Attach(inst, target)
    if target.components.combat then
        inst.entity:AddFollower():FollowSymbol(target.GUID, target.components.combat.hiteffectsymbol, 0, 0, 0)
    else
        inst.Transform:SetPosition(target.Transform:GetWorldPosition())
    end
end

local function charge_fx()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    inst.Transform:SetFourFaced()
    inst.Transform:SetScale(0.8, 0.8, 0.8)

    inst.AnimState:SetBank("electric_bubble")
    inst.AnimState:SetBuild("electric_bubble")
    inst.AnimState:PlayAnimation("charge_loop", true)
    inst.AnimState:SetBloomEffectHandle("shaders/anim.ksh")
    inst.AnimState:SetLightOverride(0.3)

    inst:AddTag("FX")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst.persists = false
    inst.Attach = Attach

    return inst
end

local function OnThrownWisp(inst)
    inst:DoPeriodicTask(
        0.33,
        function(inst)
            inst._speed = inst._speed * 1.4
            -- print("SPEED", inst._speed)
            inst.components.projectile:SetSpeed(inst._speed)
            inst.Physics:SetMotorVel(inst._speed, 0, 0)
        end
    )
end

local function wisp()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()
    inst.entity:AddLight()

    inst.Light:Enable(true)
    inst.Light:SetRadius(1)
    inst.Light:SetFalloff(0.8)
    inst.Light:SetIntensity(.75)
    inst.Light:SetColour(154 / 255, 214 / 255, 216 / 255)

    inst.Transform:SetFourFaced()
    inst.Transform:SetScale(1.2, 1.2, 1.2)

    inst.AnimState:SetBank("electric_bubble")
    inst.AnimState:SetBuild("electric_bubble")
    inst.AnimState:PlayAnimation("orb", true)
    inst.AnimState:SetBloomEffectHandle("shaders/anim.ksh")
    inst.AnimState:SetLightOverride(0.8)

    MakeInventoryPhysics(inst)
    RemovePhysicsColliders(inst)

    inst:AddTag("projectile")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst.persists = false

    inst:AddComponent("projectile")
    inst.components.projectile:SetHoming(true)
    inst.components.projectile:SetHitDist(2)
    inst.components.projectile:SetOnHitFn(OnHit)
    inst.components.projectile:SetOnMissFn(inst.Remove)

    inst._speed = 1
    inst.components.projectile:SetSpeed(inst._speed)
    inst.components.projectile:SetOnThrownFn(OnThrownWisp)

    inst:AddComponent("weapon")
    inst.components.weapon:SetDamage(TUNING.MUTANT_BEE_RANGED_WISP_DAMAGE)

    inst:DoTaskInTime(10, inst.Remove)

    return inst
end

local function Launch(inst, attacker, pos, speed)
    local x, y, z = attacker.Transform:GetWorldPosition()
    inst.Transform:SetPosition(x, y, z)

    if speed ~= nil then
        inst.components.complexprojectile:SetHorizontalSpeed(speed)
    end

    inst.components.complexprojectile:Launch(pos, attacker)
end

local function OnHitGround(inst)
    if inst._target ~= nil and inst._owner ~= nil then
        local w = SpawnPrefab("electric_wisp")
        w.components.weapon:SetDamage(BarrackModifier(inst._owner, TUNING.MUTANT_BEE_RANGED_WISP_DAMAGE))

        w.Transform:SetPosition(inst.Transform:GetWorldPosition())
        w.components.projectile.overridestartpos = inst:GetPosition()
        w.components.projectile:Throw(inst._owner, inst._target)
    end

    inst:Remove()
end

local function wisp_launch()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()
    inst.entity:AddLight()

    inst.Light:Enable(true)
    inst.Light:SetRadius(1)
    inst.Light:SetFalloff(0.8)
    inst.Light:SetIntensity(.75)
    inst.Light:SetColour(154 / 255, 214 / 255, 216 / 255)

    MakeProjectilePhysics(inst)
    RemovePhysicsColliders(inst)

    inst.Transform:SetFourFaced()
    inst.Transform:SetScale(1.2, 1.2, 1.2)

    inst.AnimState:SetBank("electric_bubble")
    inst.AnimState:SetBuild("electric_bubble")
    inst.AnimState:PlayAnimation("orb", true)
    inst.AnimState:SetBloomEffectHandle("shaders/anim.ksh")
    inst.AnimState:SetLightOverride(0.8)

    --projectile (from projectile component) added to pristine state for optimization
    inst:AddTag("projectile")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst.persists = false

    inst:AddComponent("locomotor")
    inst:AddComponent("complexprojectile")

    inst.components.complexprojectile:SetHorizontalSpeed(10)
    inst.components.complexprojectile:SetGravity(-25)
    inst.components.complexprojectile:SetLaunchOffset(Vector3(0, 2.5, 0))
    inst.components.complexprojectile:SetOnHit(OnHitGround)

    inst.Launch = Launch

    return inst
end

return Prefab("electric_bubble", fn, assets),
Prefab("electric_bubble_hit", hit_fn),
Prefab("charge_fx",charge_fx,assets),
Prefab("electric_wisp", wisp, assets),
Prefab("electric_wisp_launch", wisp_launch, assets)
