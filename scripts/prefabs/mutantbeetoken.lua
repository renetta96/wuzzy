local assets =
{
  Asset("ANIM", "anim/mutantbasebee_token.zip"),
  Asset("ANIM", "anim/mutantdefenderbee_token.zip"),
  Asset("ANIM", "anim/mutantrangerbee_token.zip"),
  Asset("ANIM", "anim/mutantassassinbee_token.zip"),
  Asset("ANIM", "anim/mutantshadowbee_token.zip"),
  Asset("ANIM", "anim/mutanthealerbee_token.zip")
}

local prefabs =
{

}

local function MakeToken(name, minion_prefab, is_base)
  local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    inst.AnimState:SetBank("mutantbasebee_token")
    inst.AnimState:SetBuild(name)
    inst.AnimState:PlayAnimation("idle")

    MakeInventoryPhysics(inst)

    inst:AddTag("beemutant")
    inst:AddTag("beemutanttoken")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inspectable")

    inst:AddComponent("inventoryitem")
    inst.components.inventoryitem.imagename = name
    inst.components.inventoryitem.atlasname = "images/inventoryimages/"..name..".xml"

    inst:AddComponent("stackable")
    inst.components.stackable.maxsize = TUNING.STACK_SIZE_LARGEITEM

    MakeSmallBurnable(inst, TUNING.SMALL_BURNTIME)
    MakeSmallPropagator(inst)

    inst.minion_prefab = minion_prefab
    inst.is_base = is_base

    return inst
  end

  return Prefab(name, fn, assets, prefabs)
end

STRINGS.MUTANTBASEBEE_TOKEN = "Soldier/Mimic Token"
STRINGS.NAMES.MUTANTBASEBEE_TOKEN = "Soldier/Mimic Token"
STRINGS.CHARACTERS.GENERIC.DESCRIBE.MUTANTBASEBEE_TOKEN = "Clink."
STRINGS.RECIPE_DESC.MUTANTBASEBEE_TOKEN = "Controls number of summoned Metapis Soldiers or Mimics."

STRINGS.MUTANTDEFENDERBEE_TOKEN = "Moonguard Token"
STRINGS.NAMES.MUTANTDEFENDERBEE_TOKEN = "Moonguard Token"
STRINGS.CHARACTERS.GENERIC.DESCRIBE.MUTANTDEFENDERBEE_TOKEN = "Clink."
STRINGS.RECIPE_DESC.MUTANTDEFENDERBEE_TOKEN = "Controls number of summoned Metapis Moonguards."

STRINGS.MUTANTRANGERBEE_TOKEN = "Voltwing Token"
STRINGS.NAMES.MUTANTRANGERBEE_TOKEN = "Voltwing Token"
STRINGS.CHARACTERS.GENERIC.DESCRIBE.MUTANTRANGERBEE_TOKEN = "Clink."
STRINGS.RECIPE_DESC.MUTANTRANGERBEE_TOKEN = "Controls number of summoned Metapis Voltwings."

STRINGS.MUTANTASSASSINBEE_TOKEN = "Mutant Token"
STRINGS.NAMES.MUTANTASSASSINBEE_TOKEN = "Mutant Token"
STRINGS.CHARACTERS.GENERIC.DESCRIBE.MUTANTASSASSINBEE_TOKEN = "Clink."
STRINGS.RECIPE_DESC.MUTANTASSASSINBEE_TOKEN = "Controls number of summoned Metapis Mutants."

STRINGS.MUTANTSHADOWBEE_TOKEN = "Shadow Token"
STRINGS.NAMES.MUTANTSHADOWBEE_TOKEN = "Shadow Token"
STRINGS.CHARACTERS.GENERIC.DESCRIBE.MUTANTSHADOWBEE_TOKEN = "Clink."
STRINGS.RECIPE_DESC.MUTANTSHADOWBEE_TOKEN = "Controls number of summoned Metapis Shadows."

STRINGS.MUTANTHEALERBEE_TOKEN = "Alchemist Token"
STRINGS.NAMES.MUTANTHEALERBEE_TOKEN = "Alchemist Token"
STRINGS.CHARACTERS.GENERIC.DESCRIBE.MUTANTHEALERBEE_TOKEN = "Clink."
STRINGS.RECIPE_DESC.MUTANTHEALERBEE_TOKEN = "Controls number of summoned Metapis Alchemists."

local hive_defs = require "hive_defs"
local returnPrefabs = {
  MakeToken("mutantbasebee_token", nil, true), -- special case for base child (soldier or mimic)
}

for i, def in ipairs(hive_defs.HiveDefs) do
  table.insert(returnPrefabs, MakeToken(def.token_prefab, def.minion_prefab))
end

return unpack(returnPrefabs)
