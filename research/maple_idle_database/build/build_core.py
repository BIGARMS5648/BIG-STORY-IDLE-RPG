import json, sys
sys.path.insert(0, "/tmp/claude-0/-home-user-BIG-STORY-IDLE-RPG/f4db4718-c3e8-5335-9264-6dbe1627a364/scratchpad/mdb/scripts")
from common import *
import sources_reg  # noqa: F401  (registers SOURCES)

COV = {}

# ------------------------------------------------------------------ 3.1 EXP per level
lv = json.load(open(RAW + "/level-experience-117.json"))
wiki_exp = json.loads(json.load(open(OLDWEB + "/idlewiki/wikitext-other-ns.json"))["Module:Experience/data.json"])
recs, cum, mism = [], 0, 0
for row in lv["levels"]:
    L = row["level"]
    req = int(row["requiredExp"]) if row["requiredExp"] is not None else None
    w = int(wiki_exp[L - 1]) if L - 1 < len(wiki_exp) else None
    match = None if (req is None or w is None) else (req == w)
    if match is False:
        mism += 1
    r = dict(level=L, required_exp_to_next=bigint(req), cumulative_exp_at_level_start=bigint(cum),
             is_max_level=(L == lv["maxCharacterLevel"]), global_wiki_required_exp=bigint(w), kr_vs_global_wiki_match=match)
    r.update(meta("MII_LEVEL_EXP", "verified_client_table" if req is not None else "verified_client_table_max_level",
                  "requiredExp = EXP needed to go from this level to the next (level 140 = cap, no requirement). Cumulative = sum of previous levels. "
                  "EXP%/booster bonuses do not apply to EXP-dungeon sweep rewards (rules.dungeonBonusApplies=false)."))
    recs.append(r)
    if req:
        cum += req
COV["character_experience"] = (len(recs), 140)
write_dataset("character_experience", "Character EXP required per level (KR client 1.18.0, Lv1-140; 140 is the cap)", recs, 140,
              f"140/140 levels. Global wiki Module:Experience (139 values) cross-checked: {139 - mism} equal, {mism} differ.",
              dict(max_character_level=lv["maxCharacterLevel"], client_version=lv["clientVersion"], verified_at=lv["verifiedAt"]))

# ------------------------------------------------------------------ 3.1 base stats
gd = json.load(open(RAW + "/msi-game-data-library.json"))
SUB = {"Str": "Dex", "Dex": "Str", "Int": "Luk", "Luk": "Dex"}
recs = []
for j in gd["jobSkillSummary"]:
    conv = j.get("statConversion", {})
    main, sub = j["mainStat"], [k for k in conv if k != j["mainStat"]]
    sub = sub[0] if sub else SUB.get(main)
    r = dict(record_type="job_stat_mapping", job=j["job"], family=j["family"], level=None, main_stat=main.upper(),
             sub_stat=sub.upper() if sub else None,
             main_stat_to_attack=conv.get(main, None) and conv[main] / 1000, sub_stat_to_attack=conv.get(sub) and conv[sub] / 1000,
             base_max_hp=None, base_max_mp=None, base_attack=None, base_defense=None, base_main_stat=None, base_sub_stat=None)
    r.update(meta("MSI_GAMEDATA", "verified_client_table",
                  "statConversion from client HeroTable (per-mille): 1 main stat = 1 Attack, 1 sub stat = 0.25 Attack (4 sub = 1 ATK). "
                  "Stat Prop. Damage = 1% per main stat + 0.25% per sub stat, floored to 0.1% (wiki Character Stats; MSI game-stat-rules MainDamagePower)."))
    recs.append(r)
ADV = {5: "1차 전직 (Guide Quest 7)", 30: "2차 전직 시험", 60: "3차 전직 시험", 100: "4차 전직 시험"}
for L in range(1, 141):
    r = dict(record_type="level_base_stats", job=None, family=None, level=L, main_stat=None, sub_stat=None,
             main_stat_to_attack=None, sub_stat_to_attack=None,
             base_max_hp=None, base_max_mp=None, base_attack=None, base_defense=None, base_main_stat=None, base_sub_stat=None,
             job_advancement_available=ADV.get(L))
    r.update(meta("WIKI_CLASSES" if L in ADV else "MII_LEVEL_EXP", "not_found",
                  "Pure per-level base HP/MP/ATK/DEF/STR-DEX-INT-LUK not published in any reachable source (mapleidleindex level table has only requiredExp; "
                  "MSI 1.14 public exports contain no HeroLevel/stat-per-level table; wiki/KR notices silent). null = unknown, NOT zero."
                  + (" Job advancement level from wiki Classes/Bowmaster pages." if L in ADV else "")))
    recs.append(r)
COV["character_base_stats"] = (0, 140 * 6, len(gd["jobSkillSummary"]))
write_dataset("character_base_stats", "Pure character base stats per level and per job (external growth excluded)", recs, 140 + len(gd["jobSkillSummary"]),
              "Job stat mapping: 14/14 jobs (client 1.14). Per-level base values: 0/840 (140 levels × HP, MP, ATK, DEF, main, sub) - all null.",
              dict(level_independent_rules=[
                  "1 main stat = 1 Attack; 4 sub stat = 1 Attack (Warrior STR/DEX, Bowman DEX/STR, Magician INT/LUK, Thief LUK/DEX).",
                  "Stat Prop. Damage = main×1% + sub×0.25%, rounded down to 0.1%.",
                  "Known level-scaled effects that are NOT base stats: item options '1/4/5/10레벨당 주 스탯(%)', PvP level adjustment (see incoming_damage_formula)."]))

# ------------------------------------------------------------------ 3.2 stat upgrades = 용사의 힘 (Hero Power) slots
ha = json.load(open(RAW + "/mii/hero-ability-information-117.json"))
ht = json.load(open(RAW + "/msi-hero-token-calculator.json"))
msi_cost = {}
for st in ht["stages"]:
    for sl in st["slots"]:
        for i, c in enumerate(sl["tokensPerLevel"], 1):
            msi_cost[(st["stage"], sl["slotIndex"], i)] = c
recs, cmp_eq, cmp_n = [], 0, 0
for st in ha["hero"]["stages"]:
    for sl in st["slots"]:
        for lvrow in sl["levels"]:
            m = msi_cost.get((st["stage"], sl["slot"], lvrow["level"]))
            if m is not None:
                cmp_n += 1
                cmp_eq += (m == lvrow["cost"])
            r = dict(system="용사의 힘 (Hero Power) slot upgrade", stage=st["stage"], slot=sl["slot"], stat_type=sl["type"], stat_label_ko=sl["label"],
                     level=lvrow["level"], max_level_in_stage=sl["maxLevel"],
                     stat_value_after=lvrow["statValue"], display_divisor=sl["displayDivisor"], display_unit=sl["displayUnit"],
                     slot_start_value=sl["baseValue"],
                     stat_increase_per_level=(lvrow["statValue"] - sl["baseValue"]) if lvrow["level"] == 1 else None,
                     cost_currency="용사의 증표 (Hero Token)", cost=lvrow["cost"], cumulative_cost_in_slot=lvrow["cumulativeCost"],
                     global_1_14_cost=m, global_1_14_match=(None if m is None else m == lvrow["cost"]))
            r.update(meta("MII_HERO_ABILITY", "verified_client_table",
                          "Cost = floor(base cost × level factor / 1000); stat = slot start value + per-level gain × level (growthContract). "
                          "Currency is 용사의 증표, NOT meso: no meso-based '능력치 강화' table was found in any source."))
            recs.append(r)
# fill per-level increase for every level
for i, r in enumerate(recs):
    if r["level"] > 1:
        r["stat_increase_per_level"] = r["stat_value_after"] - recs[i - 1]["stat_value_after"]
COV["stat_upgrade_costs"] = (len(recs), len(recs))
write_dataset("stat_upgrade_costs", "Stat upgrade levels, gain and cost - 용사의 힘 (Hero Power) slots, the only verified stat-upgrade system (token-based, KR 1.18.0)",
              recs, len(recs),
              f"All {len(recs)} slot-levels of stages 1-9 (KR 1.18.0). Cross-check vs global 1.14 (stages 1-8): {cmp_eq}/{cmp_n} costs identical. "
              "Meso-based 능력치 강화: 0 records - system not found in any source (see missing_data.md).",
              dict(meso_stat_upgrade_found=False))

# ------------------------------------------------------------------ 3.2 rank-like tiers = Hero Power stages; Maple Rank placeholder
recs = []
r = dict(record_type="maple_rank", rank=None, name="메이플 랭크 / 메이플 등급 (Maple Rank)", requirement=None, stat_effects=None,
         upgrade_cap=None, special_stat_rules=None, slot_count=None, entry_cost_tokens=None, stage_cost_tokens=None,
         stage_up_wait_seconds=None, stage_bonus=None)
r.update(meta("REPO_PROGRESSION", "not_found",
              "No Maple Rank table/notice in: 20 KR patch notes (2025-11-13..2026-11-05), KR notices/FAQ/event boards, global wiki (337 pages), "
              "MSI 1.14 data exports, mapleidleindex 1.18 data. Only unverified leads: BlueStacks guide (Maple Rank raises Main Stat/DEF/Max HP), "
              "namu.wiki search snippet ('레벨당 5 능력치 포인트, 25포인트 사용 시 메이플 등급 상승, 특수 능력치 포인트'), wiki Bowmaster page "
              "('level-up stat points'). Inven board search for '메이플 등급'/'능력치 포인트' returns no posts.", game_version="n/a", region="KR/global"))
recs.append(r)
for st in ha["hero"]["stages"]:
    bonus = [{"type": b["type"], "label": b["label"], "value": b["value"], "display": f'{b["value"] / b["displayDivisor"]:g}{b["displayUnit"]}'} for b in st["stageBonus"]]
    r = dict(record_type="hero_power_stage", rank=st["stage"], name=f"용사의 힘 {st['stage']}단계",
             requirement=("start" if st["stage"] == 1 else f"stage {st['stage'] - 1} fully trained + wait {st['baseUpgradeSecondsToReach']} s"),
             stat_effects=[{"slot": s["slot"], "stat": s["type"], "label": s["label"], "start": s["baseValue"], "max": s["maxValue"], "max_level": s["maxLevel"]} for s in st["slots"]],
             upgrade_cap=max(s["maxLevel"] for s in st["slots"]), special_stat_rules="stage bonus granted on reaching the stage (main stat flat + Max HP %)",
             slot_count=len(st["slots"]), entry_cost_tokens=st["entryCost"], stage_cost_tokens=st["stageCost"],
             stage_up_wait_seconds=st["baseUpgradeSecondsToReach"], cumulative_wait_seconds=st["cumulativeBaseUpgradeSecondsToReach"],
             fully_trained_cumulative_tokens=st["fullyTrainedCumulativeCost"], stage_bonus=bonus)
    r.update(meta("MII_HERO_ABILITY", "verified_client_table",
                  "Closest verified analogue of a rank system: each 용사의 힘 stage raises slot caps, adds slots and a stage bonus. Unlock: Guide Quest 79 (wiki/IV398). "
                  "Global 1.14 (MSI) lists stages 1-8 with identical slot counts/caps."))
    recs.append(r)
COV["maple_ranks"] = (len(recs) - 1, None)
write_dataset("maple_ranks", "Maple Rank (not found) and the verified rank-like progression 용사의 힘 stages 1-9 (KR 1.18.0)", recs, None,
              "Maple Rank: 0 verified records (placeholder with nulls). Hero Power stages: 9/9.")

json.dump(COV, open(SCRATCH + "/mdb/cov_core.json", "w"))
print("core ok", {k: v for k, v in COV.items()})

# SOURCES_DUMP
from common import SOURCES as _S
json.dump(_S, open(SCRATCH + "/mdb/sources_build_core.json", "w"), ensure_ascii=False)
