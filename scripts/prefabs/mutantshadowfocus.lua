local assets = {
  Asset("ANIM", "anim/mutantshadowfocus.zip"),
  Asset("ANIM", "anim/mutantshadowsigil.zip"),
  Asset("ANIM", "anim/spell_icons_zeta.zip")
}

local prefabs = {
  "reticuleaoe",
  "reticuleaoeping"
}

--------------------------------------------------------------------------

local function ReticuleTargetFn()
  return Vector3(ThePlayer.entity:LocalToWorldSpace(7, 0.001, 0))
end

local MUST_TAGS = {"_combat", "_health"}
local MUST_NOT_TAGS = {"player", "INLIMBO", "lesserminion", "worker"}
local MUST_ONE_OF_TAGS = {"beemutantminion"}
local SIGIL_LAUNCH_TIMES = 4
local SIGIL_RADIUS = 5

local function launchShadowAOE(inst)
	inst.components.counter:Decrement("shadow_launch_times")
	inst.AnimState:PlayAnimation("pulse")

  local x, y, z = inst.Transform:GetWorldPosition()
  local allies = TheSim:FindEntities(x, y, z, SIGIL_RADIUS, MUST_TAGS, MUST_NOT_TAGS, MUST_ONE_OF_TAGS)

  for i, e in ipairs(allies) do
    local owner = e:GetOwner()
    if e:IsValid() and not e.components.health:IsDead() and owner ~= nil and owner:HasTag("beemaster") and owner.userid == inst._userid then
      e:LaunchShadow()
    end
  end

	if inst.components.counter:GetCount("shadow_launch_times") == 0 then
		inst:ListenForEvent("animover", function()
			inst:DoTaskInTime(1, function()
				inst.AnimState:PlayAnimation("idle_pst")
				inst:ListenForEvent("animover", inst.Remove)
			end)
		end)
	else
		inst.AnimState:PushAnimation("idle", true)
		inst.components.timer:StartTimer("shadow_launch_cd", 3)
	end
end


local function onSigilTimerDone(inst, data)
  if data and data.name == "shadow_launch_cd" then
    launchShadowAOE(inst)
  end
end

local function OnSigilSave(inst, data)
  data._userid = inst._userid or nil
end

local function OnSigilLoad(inst, data)
  if data and data._userid then
    inst._userid = data._userid
  end
end

local function onSigilInit(inst)
  -- for the rare case when counter is 0 but the game quits before it's removed
  if inst.components.counter:GetCount("shadow_launch_times") == 0 then
    inst:Remove()
    return
  end
end

local function sigil_fn()
  local inst = CreateEntity()

  inst.entity:AddTransform()
  inst.entity:AddAnimState()
  -- inst.entity:AddSoundEmitter()
  inst.entity:AddNetwork()

  inst.AnimState:SetBank("mutantshadowsigil")
  inst.AnimState:SetBuild("mutantshadowsigil")
  inst.AnimState:PlayAnimation("idle_pre")
	inst.AnimState:PushAnimation("idle", true)

  inst.AnimState:SetOrientation(ANIM_ORIENTATION.OnGround)
  inst.AnimState:SetLayer(LAYER_BACKGROUND)

  inst.AnimState:SetScale(3.5, 3.5, 3.5)
  inst.AnimState:SetMultColour(0, 0, 0, 0.7)
  inst:AddTag("FX")

  inst.entity:SetPristine()

  if not TheWorld.ismastersim then
    return inst
  end

  inst:AddComponent("timer")
	inst.components.timer:StartTimer("shadow_launch_cd", 3)
  inst:ListenForEvent("timerdone", onSigilTimerDone)

  inst:AddComponent("counter")
  inst.components.counter:Set("shadow_launch_times", SIGIL_LAUNCH_TIMES)

  inst:DoTaskInTime(0, onSigilInit)

  inst.OnSave = OnSigilSave
  inst.OnLoad = OnSigilLoad

  return inst
end

local function ReticuleTargetAllowWaterFn()
  local player = ThePlayer
  local ground = TheWorld.Map
  local pos = Vector3()
  --Cast range is 8, leave room for error
  --4 is the aoe range
  for r = 7, 0, -.25 do
    pos.x, pos.y, pos.z = player.entity:LocalToWorldSpace(r, 0, 0)
    if ground:IsPassableAtPoint(pos.x, 0, pos.z, true) and not ground:IsGroundTargetBlocked(pos) then
      return pos
    end
  end
  return pos
end

local function StartAOETargeting(inst)
  local playercontroller = ThePlayer.components.playercontroller
  if playercontroller ~= nil then
    playercontroller:StartAOETargetingUsing(inst)
  end
end

local ICON_SCALE = .6
local ICON_RADIUS = 50
local SPELLBOOK_RADIUS = 100

local MAX_USES = 1000
local DECAY_USES = 100
local DECAY_RATE = 10
local SPELL_COSTS = {
	["sigil_shadow_launch"] = 250
}
local SPELL_COOLDOWNS = {
	["sigil_shadow_launch"] = 17
}

local function SigilShadowLaunchSpellFn(inst, doer, pos)
	if doer.components.spellbookcooldowns and doer.components.spellbookcooldowns:IsInCooldown("sigil_shadow_launch") then
		return false, "SPELL_ON_COOLDOWN"
	end

	if inst.components.finiteuses:GetUses() < SPELL_COSTS["sigil_shadow_launch"] then
		return false, "NOT_ENOUGH_ENERGY"
	end

  local sigil = SpawnPrefab("mutantshadowsigil")
  sigil.Transform:SetPosition(pos:Get())

  if doer:HasTag("player") and doer:HasTag("beemaster") then
    sigil._userid = doer.userid
  end

	inst.components.finiteuses:Use(SPELL_COSTS["sigil_shadow_launch"])

	if doer.components.spellbookcooldowns then
		doer.components.spellbookcooldowns:RestartSpellCooldown("sigil_shadow_launch", SPELL_COOLDOWNS["sigil_shadow_launch"])
	end

  return true
end

local SPELLS = {
  {
    label = STRINGS.MELISSOMANCY.SIGIL_SHADOW_LAUNCH,
    onselect = function(inst)
      inst.components.spellbook:SetSpellName(STRINGS.MELISSOMANCY.SIGIL_SHADOW_LAUNCH)
      inst.components.spellbook:SetSpellAction(nil)
      inst.components.aoetargeting:SetDeployRadius(0)
      inst.components.aoetargeting.reticule.reticuleprefab = "reticuleaoe_mutantshadow"
      inst.components.aoetargeting.reticule.pingprefab = "reticuleaoeping_mutantshadow"
      inst.components.aoetargeting.reticule.targetfn = ReticuleTargetFn

      if TheWorld.ismastersim then
        inst.components.aoetargeting:SetTargetFX(nil)
        inst.components.aoespell:SetSpellFn(SigilShadowLaunchSpellFn)
        inst.components.spellbook:SetSpellFn(nil)
      end
    end,
    execute = StartAOETargeting,
    widget_scale = ICON_SCALE,
    bank = "spell_icons_zeta",
		build = "spell_icons_zeta",
		anims =
		{
			idle = { anim = "sigil_shadow_launch" },
			focus = { anim = "sigil_shadow_launch_focus", loop = true },
			down = { anim = "sigil_shadow_launch_pressed" },
			cooldown = { anim = "sigil_shadow_launch_cooldown" },
		},
		checkcooldown = function(user)
			--client safe
			return user
				and user.components.spellbookcooldowns
				and user.components.spellbookcooldowns:GetSpellCooldownPercent("sigil_shadow_launch")
				or nil
		end,
		cooldowncolor = { 0.5,0.5,0.5, 0.75 },
  }
}

local function onPickUp(inst, pickupguy, src_pos)
  -- src_pos is nil when the item is moved between inventory slots, not nil when picked up from the ground
  if src_pos == nil then
    return
  end

  if pickupguy.prefab == "zeta" and pickupguy.components.skilltreeupdater and not pickupguy.components.skilltreeupdater:IsActivated("zeta_allegiance_shadow_2") and pickupguy.components.talker then
    pickupguy.components.talker:Say(STRINGS.MUTANTSHADOWFOCUS_UNSKILLED)
  end
end

local function startDecay(inst)
  if inst._decaytask == nil then
    inst._decaytask = inst:DoPeriodicTask(DECAY_RATE, function()
      inst.components.finiteuses:Use(math.min(inst.components.finiteuses:GetUses(), DECAY_USES))
    end)
  end
end

local function stopDecay(inst)
  if inst._decaytask ~= nil then
    inst._decaytask:Cancel()
    inst._decaytask = nil
  end
end

-- everytime this func is called, it re-evaluates owner and sets or unsets states correctly
local function hookOwner(inst)
  local owner = inst.components.inventoryitem:GetGrandOwner()

  if owner == nil or owner.prefab ~= "zeta" or
    not (owner.components.skilltreeupdater and owner.components.skilltreeupdater:IsActivated("zeta_allegiance_shadow_2"))
  then
    inst._owner = nil
    startDecay(inst)
    -- clear just in case
    if owner ~= nil then
      inst:RemoveEventCallback("onminionattack", inst._onminionattack, owner)
      inst:RemoveEventCallback("onattackother", inst._onownerattack, owner)
    end

    return
  end

  inst._owner = owner
  inst:RemoveEventCallback("onminionattack", inst._onminionattack, owner)
  inst:RemoveEventCallback("onattackother", inst._onownerattack, owner)
  inst:ListenForEvent("onminionattack", inst._onminionattack, owner)
  inst:ListenForEvent("onattackother", inst._onownerattack, owner)
  stopDecay(inst)
end

local function onPutInInventory(inst, owner)
  if not owner or owner.prefab ~= "zeta" then
    return
  end

  local existing = owner.components.inventory:FindItem(function (item)
    return item.prefab == "mutantshadowfocus" and item ~= inst
  end)
  if existing ~= nil then
    owner:DoTaskInTime(0, function()
      owner.components.inventory:DropItem(inst, true, true)
      if owner.components.talker then
        owner.components.talker:Say(STRINGS.MUTANTSHADOWFOCUS_AUTO_DROP)
      end
    end)
    return
  end

  -- reset callbacks
  inst:RemoveEventCallback("onactivateskill_server", inst._onownerskillchange, owner)
  inst:RemoveEventCallback("ondeactivateskill_server", inst._onownerskillchange, owner)
  inst:RemoveEventCallback("ms_skilltreeinitialized", inst._onownerskillchange, owner)
  inst:ListenForEvent("onactivateskill_server", inst._onownerskillchange, owner)
  inst:ListenForEvent("ondeactivateskill_server", inst._onownerskillchange, owner)
  inst:ListenForEvent("ms_skilltreeinitialized", inst._onownerskillchange, owner)

  inst._inv_owner = owner

  hookOwner(inst)
end

local function onDropped(inst)
  if inst._owner then
    inst:RemoveEventCallback("onminionattack", inst._onminionattack, inst._owner)
    inst:RemoveEventCallback("onattackother", inst._onownerattack, inst._owner)

    inst._owner = nil
  end

  if inst._inv_owner then
    inst:RemoveEventCallback("onactivateskill_server", inst._onownerskillchange, inst._inv_owner)
    inst:RemoveEventCallback("ondeactivateskill_server", inst._onownerskillchange, inst._inv_owner)
    inst:RemoveEventCallback("ms_skilltreeinitialized", inst._onownerskillchange, inst._inv_owner)

    inst._inv_owner = nil
  end

  startDecay(inst)
end

local function fn()
  local inst = CreateEntity()

  inst.entity:AddTransform()
  inst.entity:AddAnimState()
  inst.entity:AddSoundEmitter()
  inst.entity:AddNetwork()

  MakeInventoryPhysics(inst)

  inst.AnimState:SetBank("mutantshadowfocus")
  inst.AnimState:SetBuild("mutantshadowfocus")
  inst.AnimState:PlayAnimation("idle", true)

  inst:AddTag("mutantspellfocus")

  MakeInventoryFloatable(inst, "med", nil, 0.75)

  inst:AddComponent("spellbook")
  inst.components.spellbook:SetRequiredTag("melissomancer_shadow")
  inst.components.spellbook:SetRadius(SPELLBOOK_RADIUS)
  inst.components.spellbook:SetFocusRadius(SPELLBOOK_RADIUS)
  inst.components.spellbook:SetItems(SPELLS)

  inst:AddComponent("aoetargeting")
  inst.components.aoetargeting:SetAllowWater(true)
  inst.components.aoetargeting.reticule.targetfn = ReticuleTargetAllowWaterFn
  inst.components.aoetargeting.reticule.validcolour = {1, .75, 0, 1}
  inst.components.aoetargeting.reticule.invalidcolour = {.5, 0, 0, 1}
  inst.components.aoetargeting.reticule.ease = true
  inst.components.aoetargeting.reticule.mouseenabled = true
  inst.components.aoetargeting.reticule.twinstickmode = 1
  inst.components.aoetargeting.reticule.twinstickrange = 8

  inst.entity:SetPristine()

  if not TheWorld.ismastersim then
    return inst
  end

  MakeSmallBurnable(inst, TUNING.MED_BURNTIME)
  MakeSmallPropagator(inst)

  inst:AddComponent("inspectable")

  inst:AddComponent("inventoryitem")
  inst.components.inventoryitem:SetOnPutInInventoryFn(onPutInInventory)
  inst.components.inventoryitem:SetOnDroppedFn(onDropped)
  inst.components.inventoryitem:SetOnPickupFn(onPickUp)

	inst:AddComponent("finiteuses")
	inst.components.finiteuses:SetMaxUses(MAX_USES)
  inst.components.finiteuses:SetUses(MAX_USES)
  inst.components.finiteuses:SetDoesNotStartFull(true)

  inst:AddComponent("aoespell")

  inst.castsound = "maxwell_rework/shadow_magic/cast"
  inst.fxcolour = {0, 0, 0} -- shadow

  inst._onminionattack = function(owner, data)
    if data.minion ~= nil and owner:IsNear(data.minion, 10) then
      inst.components.finiteuses:Repair(TUNING.SHADOW_FOCUS_MINION_CHARGE)
    end
  end

  inst._onownerattack = function(owner)
    inst.components.finiteuses:Repair(TUNING.SHADOW_FOCUS_ZETA_CHARGE)
  end

  inst._onownerskillchange = function(owner)
    hookOwner(inst)
  end

  onDropped(inst)

  inst:DoTaskInTime(0, hookOwner)

  return inst
end

local function reticuleaoe()
  local inst = SpawnPrefab("reticuleaoe")

  inst.AnimState:SetScale(2, 2, 2)

  return inst
end

local function reticuleaeoping()
  local inst = SpawnPrefab("reticuleaoeping")

  inst.AnimState:SetScale(2, 2, 2)

  return inst
end

STRINGS.MUTANTSHADOWFOCUS = "Shadow Nectar"
STRINGS.MUTANTSHADOWFOCUS_AUTO_DROP = "It doesn't like to share spaces."
STRINGS.MUTANTSHADOWFOCUS_UNSKILLED = "It doesn't acknowledge me though."
STRINGS.NAMES.MUTANTSHADOWFOCUS = "Shadow Nectar"
STRINGS.RECIPE_DESC.MUTANTSHADOWFOCUS = "For-bee-den magic of darkness."
STRINGS.CHARACTERS.GENERIC.DESCRIBE.MUTANTSHADOWFOCUS = "It craves violence."

return Prefab("mutantshadowfocus", fn, assets, prefabs), Prefab("reticuleaoe_mutantshadow", reticuleaoe, {}, prefabs), Prefab(
  "reticuleaoeping_mutantshadow",
  reticuleaeoping,
  {},
  prefabs
), Prefab("mutantshadowsigil", sigil_fn, assets, prefabs)

