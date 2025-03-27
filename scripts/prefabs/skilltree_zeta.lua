local ORDERS =
{
    {"metapimancer", { -214+18, 176 + 30 }},
    {"metapis", { -62, 176 + 30 }},
    {"honeysmith", { 66+18, 176 + 30 }},
    -- {"allegiance",      { 204       , 176 + 30 }},
}

local H_GAP = 38
local W_GAP = 38
local MAX_METAPIS_SKILLS = 4

local function BuildSkillsData(SkillTreeFns)
    local function MakeMetapisLock(pos, connects, opentag)
        return {
            desc = string.format("Cannot activate more than %d Metapis skilltrees.", MAX_METAPIS_SKILLS) ,
            pos = pos,
            group = "metapis",
            tags = {"metapis_minion", "lock"},
            root = true,
            lock_open = function(prefabname, activatedskills, readonly)
                return SkillTreeFns.CountTags(prefabname, "metapis_minion_root", activatedskills) < MAX_METAPIS_SKILLS
                    or SkillTreeFns.CountTags(prefabname, opentag, activatedskills) > 0
            end,
            connects = connects,
        }
    end


    local skills = {
        -- metapimancer
        zeta_metapimancer_lock_1 = {
            desc = "Shepherd skills are not unlocked.",
            pos = {-214+18-W_GAP, 176},
            group = "metapimancer",
            tags = {"metapimancer", "lock"},
            root = true,
            lock_open = function(prefabname, activatedskills, readonly)
                return SkillTreeFns.CountTags(prefabname, "metapimancer_shepherd", activatedskills) < 1
            end,
            connects = {
                "zeta_metapimancer_tyrant_1",
            },
        },
        zeta_metapimancer_tyrant_1 = {
            title = "Tyrant I",
            desc = "Halve all Metapises' health and damage. Boost Wuzzy’s stats by 50% and set damage multiplier to 1.5x.",
            icon = "zeta_metapimancer_tyrant_1",
            pos = {-214+18, 176},
            group = "metapimancer",
            tags = {"metapimancer", "metapimancer_tyrant"},
            connects = {
                "zeta_metapimancer_tyrant_2"
            },
        },
        zeta_metapimancer_tyrant_2 = {
            title = "Tyrant II",
            desc = string.format("When attacked, Wuzzy may redirect 10x damage to %d nearby Metapises, guaranteed at 30%% HP. If too few Metapises are nearby, Wuzzy takes the hit.", TUNING.OZZY_TYRANT_REDIRECT_DAMAGE_MINIONS),
            icon = "zeta_metapimancer_tyrant_2",
            pos = {-214+18+W_GAP, 176},
            group = "metapimancer",
            tags = {"metapimancer", "metapimancer_tyrant"},
        },

        zeta_metapimancer_lock_2 = {
            desc = "Tyrant skills are not unlocked.",
            pos = {-214+18-W_GAP, 176-H_GAP},
            group = "metapimancer",
            tags = {"metapimancer", "lock"},
            root = true,
            lock_open = function(prefabname, activatedskills, readonly)
                return SkillTreeFns.CountTags(prefabname, "metapimancer_tyrant", activatedskills) < 1
            end,
            connects = {
                "zeta_metapimancer_shepherd_1",
            },
        },
        zeta_metapimancer_shepherd_1 = {
            title = "Shepherd I",
            desc = "Reduce Wuzzy's stats by 25%, set damage multipler to 0.6x. Boost all Metapises' health and damage by 25%.",
            icon = "zeta_metapimancer_shepherd_1",
            pos = {-214+18, 176-H_GAP},
            group = "metapimancer",
            tags = {"metapimancer", "metapimancer_shepherd"},
            connects = {
                "zeta_metapimancer_shepherd_2"
            }
        },
        zeta_metapimancer_shepherd_2 = {
            title = "Shepherd II",
            desc = "When attacked, Wuzzy may enrage nearby Metapises, boosting their damage and speed. The chance and number affected increase as Wuzzy's health drops.",
            icon = "zeta_metapimancer_shepherd_2",
            pos = {-214+18+W_GAP, 176-H_GAP},
            group = "metapimancer",
            tags = {"metapimancer", "metapimancer_shepherd"},
        },

        -- metapis
        zeta_metapis_lock_1 = MakeMetapisLock({-62-W_GAP,176}, {"zeta_metapis_assassin_1"}, "metapis_assassin"),
        zeta_metapis_assassin_1 = {
            title = "Metapis Mutant I",
            desc = "Less poison base damage but it becomes stackable. Maximum 20 stacks.",
            icon = "zeta_metapis_assassin_1",
            pos = {-62,176},
            group = "metapis",
            tags = {"metapis_minion_root", "metapis_minion", "metapis_assassin"},
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
        },

        zeta_metapis_lock_2 = MakeMetapisLock({-62-W_GAP,176-H_GAP}, {"zeta_metapis_shadow_1"}, "metapis_shadow"),
        zeta_metapis_shadow_1 = {
            title = "Metapis Shadow I",
            desc = "Metapis Shadows can summon Shadowlings to attack enemies. These melee minions have health decay over time and any damage received is capped at 15% max health.",
            icon = "zeta_metapis_shadow_1",
            pos = {-62,176-H_GAP},
            group = "metapis",
            tags = {"metapis_minion_root", "metapis_minion", "metapis_shadow"},
            connects = {
                "zeta_metapis_shadow_2",
            },
        },
        zeta_metapis_shadow_2 = {
            title = "Metapis Shadow II",
            desc = "When a Metapis dies, there is a chance to spawn Shadowlings. When Shadowlings die, they have a chance to damage nearby enemies with spikes.",
            icon = "zeta_metapis_shadow_2",
            pos = {-62+W_GAP,176-H_GAP},
            group = "metapis",
            tags = {"metapis_minion", "metapis_shadow"},
        },
        zeta_metapis_lock_3 = MakeMetapisLock({-62-W_GAP,176-H_GAP-H_GAP}, {"zeta_metapis_defender_1"}, "metapis_defender"),
        zeta_metapis_defender_1 = {
            title = "Metapis Moonguard I",
            desc = "Metapis Moonguards now reduce incoming damage by 30% to 80%, depending on their missing health, reaching maximum reduction at 30% health. Additionally, they possess a chance to shield nearby ally Metapises from any incoming damage. Activates only at Mother Hive level 2.",
            icon = "zeta_metapis_defender_1",
            pos = {-62,176-H_GAP-H_GAP},
            group = "metapis",
            tags = {"metapis_minion_root", "metapis_minion", "metapis_defender"},
            connects = {
                "zeta_metapis_defender_2",
            },
        },
        zeta_metapis_defender_2 = {
            title = "Metapis Moonguard II",
            desc = "Metapis Moonguards have a chance to retaliate with an ice nova upon receiving any damage. This also applies to damage received from shielding allies. Activates only at Mother Hive level 3.",
            icon = "zeta_metapis_defender_2",
            pos = {-62+W_GAP,176-H_GAP-H_GAP},
            group = "metapis",
            tags = {"metapis_minion", "metapis_defender"},
        },

        zeta_metapis_lock_4 = MakeMetapisLock({-62-W_GAP,176-H_GAP-H_GAP-H_GAP}, {"zeta_metapis_ranger_1"}, "metapis_ranger"),
        zeta_metapis_ranger_1 = {
            title = "Metapis Voltwing I",
            desc = "Metapis Voltwings orbit around their target, periodically firing electric balls.",
            icon = "zeta_metapis_ranger_1",
            pos = {-62,176-H_GAP-H_GAP-H_GAP},
            group = "metapis",
            tags = {"metapis_minion_root", "metapis_minion", "metapis_ranger"},
            connects = {
                "zeta_metapis_ranger_2",
            },
        },
        zeta_metapis_ranger_2 = {
            title = "Metapis Voltwing II",
            desc = "Metapis Voltwings charge up electricity with each attack. At maximum charge, an electric wisp spawns and accelerates toward their target.",
            icon = "zeta_metapis_ranger_2",
            pos = {-62+W_GAP,176-H_GAP-H_GAP-H_GAP},
            group = "metapis",
            tags = {"metapis_minion", "metapis_ranger"},
        },

        zeta_metapis_lock_5 = MakeMetapisLock({-62-W_GAP,176-H_GAP-H_GAP-H_GAP-H_GAP}, {"zeta_metapis_mimic_1"}, "metapis_mimic"),
        zeta_metapis_mimic_1 = {
            title = "Metapis Mimic I",
            desc = "Evolve Metapis Soldiers into Metapis Mimics, which randomly change their attacks based on nearby Metapises.",
            icon = "zeta_metapis_mimic_1",
            pos = {-62,176-H_GAP-H_GAP-H_GAP-H_GAP},
            group = "metapis",
            tags = {"metapis_minion_root", "metapis_minion", "metapis_mimic"},
        },

        -- honeysmith
        zeta_honeysmith_melissa_1 = {
            title = "Melissa I",
            desc = "Every 4th attack with Melissa, Wuzzy slams the target for 2x damage. Also double Melissa's max uses.",
            icon = "zeta_honeysmith_melissa_1",
            root = true,
            pos = {66+18-W_GAP, 176},
            group = "honeysmith",
            tags = {"honeysmith", "melissa"},
        }
    }

    return {
        SKILLS = skills,
        ORDERS = ORDERS,
    }
end

return BuildSkillsData
