local H_GAP = 35
local W_GAP = 38

local METAPISMANCER_ANCHOR_X = -214 + 18
local METAPIS_ANCHOR_X = -62
local HONEYSMITH_ANCHOR_X = 66 + 18
local ALLEGIANCE_ANCHOR_X = 154 + W_GAP / 2
local SKILL_FIRST_ROW_Y = 176

local ORDERS = {
  {"metapimancer", {METAPISMANCER_ANCHOR_X, SKILL_FIRST_ROW_Y + 30}},
  {"metapis", {METAPIS_ANCHOR_X, SKILL_FIRST_ROW_Y + 30}},
  {"honeysmith", {HONEYSMITH_ANCHOR_X, SKILL_FIRST_ROW_Y + 30}},
  {"allegiance", {154 + W_GAP / 2, SKILL_FIRST_ROW_Y + 30}}
}

local MAX_METAPIS_SKILLS = 4

local function BuildSkillsData(SkillTreeFns)
  local function MakeMetapisLock(pos, connects, opentag)
    return {
      desc = string.format("Cannot activate more than %d Metapis skilltrees.", MAX_METAPIS_SKILLS),
      pos = pos,
      group = "metapis",
      tags = {"metapis_minion", "lock"},
      root = true,
      lock_open = function(prefabname, activatedskills, readonly)
        return SkillTreeFns.CountTags(prefabname, "metapis_minion_root", activatedskills) < MAX_METAPIS_SKILLS or
          SkillTreeFns.CountTags(prefabname, opentag, activatedskills) > 0
      end,
      connects = connects
    }
  end

  local skills = {
    -- metapimancer
    zeta_metapimancer_lock_1 = {
      desc = "Shepherd skills are not unlocked.",
      pos = {METAPISMANCER_ANCHOR_X - W_GAP, SKILL_FIRST_ROW_Y},
      group = "metapimancer",
      tags = {"metapimancer", "lock"},
      root = true,
      lock_open = function(prefabname, activatedskills, readonly)
        return SkillTreeFns.CountTags(prefabname, "metapimancer_shepherd", activatedskills) == 0
      end,
      connects = {
        "zeta_metapimancer_tyrant_1"
      }
    },
    zeta_metapimancer_tyrant_1 = {
      title = "Tyrant I",
      desc = "Halve all Metapises' health and damage. Boost Wuzzy’s stats and set damage multiplier to 1.05x - 1.5x based on Mother Hive upgrades.",
      icon = "zeta_metapimancer_tyrant_1",
      pos = {METAPISMANCER_ANCHOR_X, SKILL_FIRST_ROW_Y},
      group = "metapimancer",
      tags = {"metapimancer", "metapimancer_tyrant"},
      connects = {
        "zeta_metapimancer_tyrant_2"
      }
    },
    zeta_metapimancer_tyrant_2 = {
      title = "Tyrant II",
      desc = string.format(
        "When attacked, Wuzzy may redirect 10x damage to %d nearby Metapises, guaranteed at 30%% HP. If too few Metapises are nearby, Wuzzy takes the hit.",
        TUNING.ZETA_TYRANT_REDIRECT_DAMAGE_MINIONS
      ),
      icon = "zeta_metapimancer_tyrant_2",
      pos = {-214 + 18 + W_GAP, SKILL_FIRST_ROW_Y},
      group = "metapimancer",
      tags = {"metapimancer", "metapimancer_tyrant"}
    },
    zeta_metapimancer_lock_2 = {
      desc = "Tyrant skills are not unlocked.",
      pos = {METAPISMANCER_ANCHOR_X - W_GAP, SKILL_FIRST_ROW_Y - H_GAP},
      group = "metapimancer",
      tags = {"metapimancer", "lock"},
      root = true,
      lock_open = function(prefabname, activatedskills, readonly)
        return SkillTreeFns.CountTags(prefabname, "metapimancer_tyrant", activatedskills) == 0
      end,
      connects = {
        "zeta_metapimancer_shepherd_1"
      }
    },
    zeta_metapimancer_shepherd_1 = {
      title = "Shepherd I",
      desc = "Reduce Wuzzy's stats, set damage multipler to 0.6x. Boost all Metapises' health and damage by 25%. Metapises are able to attack shadow creatures.",
      icon = "zeta_metapimancer_shepherd_1",
      pos = {METAPISMANCER_ANCHOR_X, SKILL_FIRST_ROW_Y - H_GAP},
      group = "metapimancer",
      tags = {"metapimancer", "metapimancer_shepherd"},
      connects = {
        "zeta_metapimancer_shepherd_2"
      }
    },
    zeta_metapimancer_shepherd_2 = {
      title = "Shepherd II",
      desc = "Attacking or being attacked may enrage nearby Metapises, boosting their damage and speed. Chance and number affected scale with Wuzzy’s missing health.",
      icon = "zeta_metapimancer_shepherd_2",
      pos = {METAPISMANCER_ANCHOR_X + W_GAP, SKILL_FIRST_ROW_Y - H_GAP},
      group = "metapimancer",
      tags = {"metapimancer", "metapimancer_shepherd"}
    },
    -- metapis
    zeta_metapis_lock_1 = MakeMetapisLock(
      {METAPIS_ANCHOR_X - W_GAP, SKILL_FIRST_ROW_Y},
      {"zeta_metapis_assassin_1"},
      "metapis_assassin"
    ),
    zeta_metapis_assassin_1 = {
      title = "Metapis Mutant I",
      desc = "Less poison base damage but it becomes stackable. Maximum 20 stacks.",
      icon = "zeta_metapis_assassin_1",
      pos = {METAPIS_ANCHOR_X, SKILL_FIRST_ROW_Y},
      group = "metapis",
      tags = {"metapis_minion_root", "metapis_minion", "metapis_assassin"},
      connects = {
        "zeta_metapis_assassin_2"
      }
    },
    zeta_metapis_assassin_2 = {
      title = "Metapis Mutant II",
      desc = "Directly summoned Metapis Mutants have a chance to coat Wuzzy’s attacks in poison for 10 seconds. This coating also gives poison ticks on the target a chance to deal increased damage.",
      icon = "zeta_metapis_assassin_2",
      pos = {METAPIS_ANCHOR_X + W_GAP, SKILL_FIRST_ROW_Y},
      group = "metapis",
      tags = {"metapis_minion", "metapis_assassin"}
    },
    zeta_metapis_lock_2 = MakeMetapisLock(
      {METAPIS_ANCHOR_X - W_GAP, SKILL_FIRST_ROW_Y - H_GAP},
      {"zeta_metapis_shadow_1"},
      "metapis_shadow"
    ),
    zeta_metapis_shadow_1 = {
      title = "Metapis Shadow I",
      desc = "Metapis Shadows can summon Shadowlings to attack enemies. These melee minions have health decay over time and any damage received is capped at 15% max health.",
      icon = "zeta_metapis_shadow_1",
      pos = {METAPIS_ANCHOR_X, SKILL_FIRST_ROW_Y - H_GAP},
      group = "metapis",
      tags = {"metapis_minion_root", "metapis_minion", "metapis_shadow"},
      connects = {
        "zeta_metapis_shadow_2"
      }
    },
    zeta_metapis_shadow_2 = {
      title = "Metapis Shadow II",
      desc = "When a Metapis dies, it has a chance to spawn Shadowlings. On death, Shadowlings may release damaging spikes at nearby enemies. If Metapis Alchemist II is activated and the dying Metapis is frenzied, it will always spawn frenzied Shadowlings instead.",
      icon = "zeta_metapis_shadow_2",
      pos = {METAPIS_ANCHOR_X + W_GAP, SKILL_FIRST_ROW_Y - H_GAP},
      group = "metapis",
      tags = {"metapis_minion", "metapis_shadow"}
    },
    zeta_metapis_lock_3 = MakeMetapisLock(
      {METAPIS_ANCHOR_X - W_GAP, SKILL_FIRST_ROW_Y - 2 * H_GAP},
      {"zeta_metapis_defender_1"},
      "metapis_defender"
    ),
    zeta_metapis_defender_1 = {
      title = "Metapis Moonguard I",
      desc = "Metapis Moonguards now reduce incoming damage by 30% to 80%, depending on their missing health, reaching maximum reduction at 30% health. Additionally, they possess a chance to shield nearby ally Metapises from any incoming damage. Activates only at Mother Hive level 2.",
      icon = "zeta_metapis_defender_1",
      pos = {METAPIS_ANCHOR_X, SKILL_FIRST_ROW_Y - H_GAP - H_GAP},
      group = "metapis",
      tags = {"metapis_minion_root", "metapis_minion", "metapis_defender"},
      connects = {
        "zeta_metapis_defender_2"
      }
    },
    zeta_metapis_defender_2 = {
      title = "Metapis Moonguard II",
      desc = "Metapis Moonguards have a chance to retaliate with an ice nova upon receiving any damage. This also applies to damage received from shielding allies. Activates only at Mother Hive level 3.",
      icon = "zeta_metapis_defender_2",
      pos = {METAPIS_ANCHOR_X + W_GAP, SKILL_FIRST_ROW_Y - H_GAP - H_GAP},
      group = "metapis",
      tags = {"metapis_minion", "metapis_defender"}
    },
    zeta_metapis_lock_4 = MakeMetapisLock(
      {METAPIS_ANCHOR_X - W_GAP, SKILL_FIRST_ROW_Y - 3 * H_GAP},
      {"zeta_metapis_ranger_1"},
      "metapis_ranger"
    ),
    zeta_metapis_ranger_1 = {
      title = "Metapis Voltwing I",
      desc = "Metapis Voltwings orbit around their target, periodically firing electric orbs. Each attack builds up their charge, and at full power, they unleash an electric wisp that accelerates toward the target, dealing damage on impact.",
      icon = "zeta_metapis_ranger_1",
      pos = {METAPIS_ANCHOR_X, SKILL_FIRST_ROW_Y - H_GAP - H_GAP - H_GAP},
      group = "metapis",
      tags = {"metapis_minion_root", "metapis_minion", "metapis_ranger"},
      connects = {
        "zeta_metapis_ranger_2"
      }
    },
    zeta_metapis_ranger_2 = {
      title = "Metapis Voltwing II",
      desc = "Metapis Voltwings' attacks apply a debuff to their target. When the target thaws, electric wisps erupts from them and circles back to strike again. Additionally, Wuzzy's attacks have a chance to charge some nearby Voltwings.",
      icon = "zeta_metapis_ranger_2",
      pos = {METAPIS_ANCHOR_X + W_GAP, SKILL_FIRST_ROW_Y - H_GAP - H_GAP - H_GAP},
      group = "metapis",
      tags = {"metapis_minion", "metapis_ranger"}
    },
    zeta_metapis_lock_5 = MakeMetapisLock(
      {METAPIS_ANCHOR_X - W_GAP, SKILL_FIRST_ROW_Y - 4 * H_GAP},
      {"zeta_metapis_mimic_1"},
      "metapis_mimic"
    ),
    zeta_metapis_mimic_1 = {
      title = "Metapis Mimic I",
      desc = "Evolve Metapis Soldiers into Metapis Mimics, which periodically adapt their abilities based on nearby Metapises. Each adaptation grants 1 ability, retaining only 1 total 75% of the time, and up to 2 abilities 25% of the time.",
      icon = "zeta_metapis_mimic_1",
      pos = {METAPIS_ANCHOR_X, SKILL_FIRST_ROW_Y - 4 * H_GAP},
      group = "metapis",
      tags = {"metapis_minion_root", "metapis_minion", "metapis_mimic"},
      connects = {
        "zeta_metapis_mimic_2"
      }
    },
    zeta_metapis_mimic_2 = {
      title = "Metapis Mimic II",
      desc = "Metapis Mimics can now retain up to 2 abilities, with a 25% chance to hold up to 3.",
      icon = "zeta_metapis_mimic_2",
      pos = {METAPIS_ANCHOR_X + W_GAP, SKILL_FIRST_ROW_Y - 4 * H_GAP},
      group = "metapis",
      tags = {"metapis_minion", "metapis_mimic"}
    },
    zeta_metapis_lock_6 = MakeMetapisLock(
      {METAPIS_ANCHOR_X - W_GAP, SKILL_FIRST_ROW_Y - 5 * H_GAP},
      {"zeta_metapis_healer_1"},
      "metapis_healer"
    ),
    zeta_metapis_healer_1 = {
      title = "Metapis Alchemist I",
      desc = "Metapis Alchemists periodically release pheromones, briefly frenzying nearby allies to boost attack speed but increase damage taken. Their heal orbs also gain Wuzzy’s bonus movement speed for a short time, stacking up to 3 times.",
      icon = "zeta_metapis_healer_1",
      pos = {METAPIS_ANCHOR_X, SKILL_FIRST_ROW_Y - 5 * H_GAP},
      group = "metapis",
      tags = {"metapis_minion_root", "metapis_minion", "metapis_healer"},
      connects = {
        "zeta_metapis_healer_2"
      }
    },
    zeta_metapis_healer_2 = {
      title = "Metapis Alchemist II",
      desc = "When a Metapis dies while frenzied, it explodes, dealing double damage in a small area. If Metapis Shadow II is active, it always spawns Shadowlings on death and sends them into a frenzy.",
      icon = "zeta_metapis_healer_2",
      pos = {METAPIS_ANCHOR_X + W_GAP, SKILL_FIRST_ROW_Y - 5 * H_GAP},
      group = "metapis",
      tags = {"metapis_minion", "metapis_healer"}
    },
    -- honeysmith
    zeta_honeysmith_melissa_1 = {
      title = "Melissa I",
      desc = string.format(
        "Every 4th attack with Melissa, Wuzzy slams the target for %dx damage. Also increase Melissa's max uses.",
        TUNING.MELISSA_SLAM_DAMAGE_MULT
      ),
      icon = "zeta_honeysmith_melissa_1",
      root = true,
      pos = {HONEYSMITH_ANCHOR_X - W_GAP, SKILL_FIRST_ROW_Y},
      group = "honeysmith",
      tags = {"honeysmith", "melissa"},
      connects = {
        "zeta_honeysmith_melissa_2"
      }
    },
    zeta_honeysmith_melissa_2 = {
      title = "Melissa II",
      desc = string.format(
        "Wuzzy uses Melissa to swap with another Metapis, consuming durability. The swapped Metapis becomes frenzied and enraged. Melissa now deals %d damage.",
        TUNING.MELISSA_DAMAGE_2
      ),
      icon = "zeta_honeysmith_melissa_2",
      pos = {HONEYSMITH_ANCHOR_X, SKILL_FIRST_ROW_Y},
      group = "honeysmith",
      tags = {"honeysmith", "melissa"}
    },
    zeta_honeysmith_armor_honey_1 = {
      title = "Honey Suit I",
      desc = string.format(
        "Honey Suit increases healing and stores absorbed damage. Exceeding %d releases stingers that strike nearby enemies, scaling with the number of summoned Metapises. Stored damage resets when unequipped and rapidly decays after not taking hits.",
        TUNING.ARMORHONEY_RETALIATE_ACC_DAMAGE_THRESHOLD
      ),
      icon = "zeta_honeysmith_armor_honey_1",
      root = true,
      pos = {HONEYSMITH_ANCHOR_X - W_GAP, SKILL_FIRST_ROW_Y - H_GAP},
      group = "honeysmith",
      tags = {"honeysmith", "armor_honey"},
      connects = {
        "zeta_honeysmith_armor_honey_2"
      }
    },
    zeta_honeysmith_armor_honey_2 = {
      title = "Honey Suit II",
      desc = "When Wuzzy is attacked while wearing the Honey Suit, there is a chance to summon a Metapis. Releasing stingers always summons 1 Metapis. These summons are tracked separately and have the same cap.",
      icon = "zeta_honeysmith_armor_honey_2",
      pos = {HONEYSMITH_ANCHOR_X, SKILL_FIRST_ROW_Y - H_GAP},
      group = "honeysmith",
      tags = {"honeysmith", "armor_honey"}
    },
    -- allegiance
    zeta_allegiance_lock_1 = {
      group = "allegiance",
      tags = {"allegiance", "lock"},
      root = true,
      desc = "Learned at least 12 skills, including Shepherd or Tyrant.",
      lock_open = function(prefabname, activatedskills, readonly)
        return SkillTreeFns.CountSkills(prefabname, activatedskills) >= 12 and
          (SkillTreeFns.CountTags(prefabname, "metapimancer_shepherd", activatedskills) > 0 or
            SkillTreeFns.CountTags(prefabname, "metapimancer_tyrant", activatedskills) > 0)
      end,
      pos = {ALLEGIANCE_ANCHOR_X, SKILL_FIRST_ROW_Y}
    },
    zeta_allegiance_shadow_lock_1 = SkillTreeFns.MakeFuelWeaverLock(
      {pos = {ALLEGIANCE_ANCHOR_X - W_GAP / 2, SKILL_FIRST_ROW_Y - H_GAP}}
    ),
    zeta_allegiance_shadow_lock_2 = SkillTreeFns.MakeNoLunarLock(
      {pos = {ALLEGIANCE_ANCHOR_X - W_GAP / 2, SKILL_FIRST_ROW_Y - 2 * H_GAP}}
    ),
    zeta_allegiance_lunar_lock_1 = SkillTreeFns.MakeCelestialChampionLock(
      {pos = {ALLEGIANCE_ANCHOR_X + W_GAP / 2, SKILL_FIRST_ROW_Y - H_GAP}}
    ),
    zeta_allegiance_lunar_lock_2 = SkillTreeFns.MakeNoShadowLock(
      {pos = {ALLEGIANCE_ANCHOR_X + W_GAP / 2, SKILL_FIRST_ROW_Y - 2 * H_GAP}}
    ),
    zeta_allegiance_shadow_1 = {
      title = "Shadow Melissomancy I",
      desc = "The Queen will reward your loyalty with combat bonuses. You and your swarm take less damage from Shadow Aligned enemies and deal bonus damage to Lunar Aligned enemies. Being a Shepherd grants you lesser bonuses, but empowers your minions more. Being a Tyrant grants you greater bonuses, but empowers your minions less.",
      icon = "zeta_allegiance_shadow_1",
      pos = {ALLEGIANCE_ANCHOR_X - W_GAP / 2, SKILL_FIRST_ROW_Y - 3 * H_GAP},
      group = "allegiance",
      tags = {"allegiance", "shadow", "shadow_favor"},
      locks = {"zeta_allegiance_lock_1", "zeta_allegiance_shadow_lock_1", "zeta_allegiance_shadow_lock_2"},
      connects = {"zeta_allegiance_shadow_2"}
    },
    zeta_allegiance_shadow_2 = {
      title = "Shadow Melissomancy II",
      desc = "The Queen will grant you the secrets of Shadow Nectar.",
      icon = "zeta_allegiance_shadow_2",
      pos = {ALLEGIANCE_ANCHOR_X - W_GAP / 2, SKILL_FIRST_ROW_Y - 4 * H_GAP},
      group = "allegiance",
      tags = {"allegiance", "shadow", "shadow_favor"}
    },
    zeta_allegiance_lunar_1 = {
      title = "Lunar Melissomancy I",
      desc = "The Cryptic Founder will reward your curiosity with combat bonuses. You and your swarm take less damage from Lunar Aligned enemies and deal bonus damage to Shadow Aligned enemies. Being a Shepherd grants you lesser bonuses, but empowers your minions more. Being a Tyrant grants you greater bonuses, but empowers your minions less.",
      icon = "zeta_allegiance_lunar_1",
      pos = {ALLEGIANCE_ANCHOR_X + W_GAP / 2, SKILL_FIRST_ROW_Y - 3 * H_GAP},
      group = "allegiance",
      tags = {"allegiance", "lunar", "lunar_favor"},
      locks = {"zeta_allegiance_lock_1", "zeta_allegiance_lunar_lock_1", "zeta_allegiance_lunar_lock_2"}
    }
    -- zeta_allegiance_lunar_2 = {
    --   title = "Lunar II",
    --   desc = "",
    --   icon = "zeta_honeysmith_armor_honey_2",
    --   pos = {ALLEGIANCE_ANCHOR_X + W_GAP/2, SKILL_FIRST_ROW_Y - 4*H_GAP},
    --   group = "allegiance",
    --   tags = {"allegiance", "lunar", "lunar_favor"},
    --   locks = {"zeta_allegiance_lunar_1"}
    -- }
  }

  return {
    SKILLS = skills,
    ORDERS = ORDERS
  }
end

return BuildSkillsData
