local ORDERS =
{
    -- {"torch",           { -214+18   , 176 + 30 }},
    {"metapis",         { -62       , 176 + 30 }},
    -- {"beard",           { 66+18     , 176 + 30 }},
    -- {"allegiance",      { 204       , 176 + 30 }},
}

local H_GAP = 38
local W_GAP = 38

local function BuildSkillsData(SkillTreeFns)
    local function MakeMetapisLock(pos, connects, opentag)
        return {
            desc = "Cannot activate more than 3 Metapis skilltrees.",
            pos = pos,
            group = "metapis",
            tags = {"metapis_minion", "lock"},
            root = true,
            lock_open = function(prefabname, activatedskills, readonly)
                return SkillTreeFns.CountTags(prefabname, "metapis_minion_root", activatedskills) < 3
                    or SkillTreeFns.CountTags(prefabname, opentag, activatedskills) > 0
            end,
            connects = connects,
        }
    end


    local skills = {
        zeta_metapis_lock_1 = MakeMetapisLock({-62-W_GAP,176}, {"zeta_metapis_assassin_1"}, "metapis_assassin"),
        zeta_metapis_assassin_1 = {
            title = "Metapis Mutant I",
            desc = "Less poison base damage but it becomes stackable. Maximum 20 stacks.",
            icon = "zeta_metapis_assassin_1",
            pos = {-62,176},
            group = "metapis",
            tags = {"metapis_minion_root", "metapis_minion", "metapis_assassin"},
            onactivate = function(inst, fromload)
                inst:AddTag("metapis_assassin_1")
            end,
            connects = {
                "zeta_metapis_assassin_2",
            },
        },
        zeta_metapis_assassin_2 = {
            title = "Metapis Mutant II",
            desc = "Directly summoned Metapis Mutants have a chance to coat Wuzzy's attacks in poison. This effect lasts 10 seconds.",
            icon = "zeta_metapis_assassin_2",
            pos = {-62+W_GAP,176},
            group = "metapis",
            tags = {"metapis_minion", "metapis_assassin"},
            onactivate = function(inst, fromload)
                inst:AddTag("metapis_assassin_2")
            end,
        },

        zeta_metapis_lock_2 = MakeMetapisLock({-62-W_GAP,176-H_GAP}, {"zeta_metapis_shadow_1"}, "metapis_shadow"),
        zeta_metapis_shadow_1 = {
            title = "Metapis Shadow I",
            desc = "Metapis Shadows can summon Shadowlings to attack enemies. These melee minions have health decay over time and any damage received is capped at 15% max health.",
            icon = "zeta_metapis_shadow_1",
            pos = {-62,176-H_GAP},
            group = "metapis",
            tags = {"metapis_minion_root", "metapis_minion", "metapis_shadow"},
            onactivate = function(inst, fromload)
                inst:AddTag("zeta_metapis_shadow_1")
            end,
            connects = {
                "zeta_metapis_shadow_2",
            },
        },
        zeta_metapis_shadow_2 = {
            title = "Metapis Shadow II",
            desc = "When Shadowlings die, they have a chance to damage nearby enemies with spikes.",
            icon = "zeta_metapis_shadow_2",
            pos = {-62+W_GAP,176-H_GAP},
            group = "metapis",
            tags = {"metapis_minion", "metapis_shadow"},
            onactivate = function(inst, fromload)
                inst:AddTag("zeta_metapis_shadow_2")
            end,
            connects = {
                "zeta_metapis_shadow_3",
            },
        },
        zeta_metapis_shadow_3 = {
            title = "Metapis Shadow III",
            desc = "When a Metapis dies, there is a chance for it to spawn Shadowlings.",
            icon = "zeta_metapis_shadow_3",
            pos = {-62+W_GAP+W_GAP,176-H_GAP},
            group = "metapis",
            tags = {"metapis_minion", "metapis_shadow"},
            onactivate = function(inst, fromload)
                inst:AddTag("zeta_metapis_shadow_3")
            end,
        },


        zeta_metapis_lock_3 = MakeMetapisLock({-62-W_GAP,176-H_GAP-H_GAP}, {"zeta_metapis_defender_1"}, "metapis_defender"),
        zeta_metapis_defender_1 = {
            title = "Metapis Moonguard I",
            desc = "Metapis Moonguards now reduce incoming damage by 30% to 80%, depending on their missing health, reaching maximum reduction at 30% health. Additionally, they possess a chance to shield nearby ally Metapises from any incoming damage.",
            icon = "zeta_metapis_defender_1",
            pos = {-62,176-H_GAP-H_GAP},
            group = "metapis",
            tags = {"metapis_minion_root", "metapis_minion", "metapis_defender"},
            onactivate = function(inst, fromload)
                inst:AddTag("zeta_metapis_defender_1")
            end,
            connects = {
                "zeta_metapis_defender_2",
            },
        },
        zeta_metapis_defender_2 = {
            title = "Metapis Moonguard II",
            desc = "Metapis Moonguards have a chance to retaliate with an ice nova upon receiving any damage. This also applies to damage received from shielding allies.",
            icon = "zeta_metapis_defender_2",
            pos = {-62+W_GAP,176-H_GAP-H_GAP},
            group = "metapis",
            tags = {"metapis_minion", "metapis_defender"},
            onactivate = function(inst, fromload)
                inst:AddTag("zeta_metapis_defender_2")
            end,
        },
    }

    return {
        SKILLS = skills,
        ORDERS = ORDERS,
    }
end

return BuildSkillsData
