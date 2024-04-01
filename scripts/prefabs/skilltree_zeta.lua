local ORDERS =
{
    -- {"torch",           { -214+18   , 176 + 30 }},
    {"metapis",         { -62       , 176 + 30 }},
    -- {"beard",           { 66+18     , 176 + 30 }},
    -- {"allegiance",      { 204       , 176 + 30 }},
}

local function BuildSkillsData(SkillTreeFns)
    local skills = {
        zeta_metapis_lock_1 = {
            desc = "Cannot activate more than 3 Metapis skilltrees.",
            pos = {-62-38,176},
            group = "metapis",
            tags = {"metapis_minion","lock"},
            root = true,
            lock_open = function(prefabname, activatedskills, readonly)
                return SkillTreeFns.CountTags(prefabname, "metapis_minion_root", activatedskills) < 3
            end,
            connects = {
                "zeta_metapis_assassin_1",
            },
        },
        zeta_metapis_assassin_1 = {
            title = "Metapis Mutant I",
            desc = "Less poison base damage but it becomes stackable. Maximum 20 stacks.",
            icon = "zeta_metapis_assassin_1",
            pos = {-62,176},
            group = "metapis",
            tags = {"metapis_minion_root", "metapis_minion"},
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
            pos = {-62+38,176},
            group = "metapis",
            tags = {"metapis_minion"},
            onactivate = function(inst, fromload)
                inst:AddTag("metapis_assassin_2")
            end,
        },
    }

    return {
        SKILLS = skills,
        ORDERS = ORDERS,
    }
end

return BuildSkillsData
