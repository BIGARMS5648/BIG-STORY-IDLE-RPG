import json, sys, re
sys.path.insert(0, "/tmp/claude-0/-home-user-BIG-STORY-IDLE-RPG/f4db4718-c3e8-5335-9264-6dbe1627a364/scratchpad/mdb/scripts")
from common import *
import sources_reg  # noqa

COV = {}
recs = []


def add(rtype, order, name, expression, applies_to, sid, status, notes="", value=None, unit=None):
    r = dict(record_type=rtype, order=order, name=name, expression=expression, value=value, unit=unit, applies_to=applies_to)
    r.update(meta(sid, status, notes))
    recs.append(r)


OFF = "official_kr_notice"
# ---- base chain (identical in old and new PvP formulas; MSI summary of the official Guide gives the same order)
chain = [
    ("base_attack_vs_defense", "공격력[attacker] × 5,000 ÷ (6,000 + 방어력[target] × (100% − 방어 관통력%[attacker]))", "5000 / (6000 + effective DEF)"),
    ("damage_taken_increase", "× 받는 피해 증가%[target]", None),
    ("damage_taken_decrease", "× (100% − 받는 피해 감소%[target])", "Toughness; chained remaining-gap stacking; cap 95%"),
    ("dungeon_damage_taken_decrease", "× (100% − 던전용 받는 피해 감소%[target])", "content/boss implementation stat; negative on boss groggy"),
    ("damage_and_amplification", "× 데미지%[attacker] × 데미지 증폭%[attacker]", None),
    ("basic_or_skill_damage", "× (기본 공격 데미지% 또는 스킬 데미지%) × 스탯 비례 데미지%", None),
    ("mastery_damage", "× 마스터리 피해량 증가%", "skill-mastery implementation stat"),
    ("dungeon_damage_increase", "× 던전용 피해량 증가%", "dungeon condition bonus stat"),
    ("critical_and_range", "× (크리티컬 발생 시) 크리티컬 데미지% × (최소 데미지 배율% ~ 최대 데미지 배율%)", "crit rate = attacker crit − target 크리티컬 저항, clamp 0-100%"),
    ("status_and_final", "× (상태이상 대상에게) 상태이상 데미지% × 최종 데미지%", "Final Damage sources multiply per source"),
    ("skill_coefficient", "× 스킬 계수%", "applied after the general chain"),
]
for i, (n, e, v) in enumerate(chain, 1):
    add("formula_term", i, n, e, "all damage events (official text: offensive stats from attacker, defensive stats from target)", "NX_PVP_FORMULA", OFF,
        "Quoted from the official PvP formula notice (2026-06-25) and 7/2 patch note; the same order is given by MSI's reading of the official Guide "
        "(Attack × 5,000 ÷ (effective Defense + 6,000) × Damage Taken multipliers × ... × content adjustment × Skill coefficient).", value=v)

add("rule", 20, "stat_side_assignment", "기본 피해량: 공격적인 능력치 = 공격자 기준, 방어적인 능력치 = 피격자 기준", "all", "NX_PVP_FORMULA", OFF,
    "Official sentence. This is what makes the chain usable for monster→player hits: monster ATK/accuracy/crit vs player DEF/Toughness/evasion.")
add("rule", 21, "per_mille_internal_units", "%stats are stored ×10 (30% = 300); multiplier = (1000 + value) / 1000; '100% + 받는 피해 감소%' is computed as 1000 + 300",
    "all", "NX_PVP_FORMULA", OFF)
add("rule", 22, "toughness_stacking", "actualGain = (100% − current) × added / 100%; total capped at 95% (StatTypeTable maxValueE3 950)", "target = player or monster",
    "MSI_STATRULES", "verified_client_table", "IL2CPP ChainedPercentageAccumCalculator; tooltip: 'After Defense reduces incoming damage, Damage Taken Decrease reduces it further'. "
    "Order confirmed: DEF step first, then Toughness.", value=95, unit="% cap")
add("rule", 23, "defense_penetration_stacking", "actualGain = (100% − current) × added / 100%; cap 100% (display max 99.9%)", "attacker", "MSI_STATRULES", "verified_client_table")
add("rule", 24, "evasion", "gap = max(target Evasion − attacker Accuracy, 0); miss chance = StatGapValueTable[gap]; 70% at gap ≥ 100", "player evading monster hits and vice versa",
    "MSI_STATRULES", "verified_client_table", "Full 100-row table in stat_gap_table.json. Monster HitChance per growth-dungeon monster is in growth_dungeon_monsters.json.", value=70, unit="% max")
add("rule", 25, "critical_resistance", "effective crit rate = clamp(attacker crit − target 크리티컬 저항, 0, 100%); negative resist raises attacker crit", "all",
    "MSI_STATRULES", "strong_client_helper_evidence", "Same rule in wiki Character Stats. Monster crit stats are not published (unknown whether monsters crit).")
add("rule", 26, "final_damage_stacking", "combined = Π(1 + FD_i) − 1", "attacker", "MSI_STATRULES", "verified_client_table")
add("rule", 27, "min_max_clamp", "each strike rolls between Min and Max multiplier; if Min > Max, Max is used", "attacker", "MSI_STATRULES", "verified_client_table")
add("rule", 28, "guild_war_excess_accuracy", "Guild War only: FD += min(max(Acc − target Eva, 0), 30) × 0.5%  (max +15%)", "PvP guild war", "MSI_STATRULES",
    "verified_client_table", "Official 2/12 patch note: 내 명중이 상대 회피보다 높을수록 최종 데미지 소폭 증가, 최대 30 차이.")

# ---- verification of the 5000/6000 constants for monster→player hits
add("verification", 30, "constants_5000_6000_for_monster_to_player",
    "5,000 ÷ (6,000 + DEF×(1−pierce)) with DEF = defender's DEF", "PvE monster → player", "NX_PVP_FORMULA", "partially_verified",
    "Officially stated for PvP where the defender is a player (so player DEF does enter 5000/(6000+DEF)). For monster→player in PvE the official text only "
    "says the base chain uses attacker offense and target defense; no official PvE example and no published measurement exists. Monster attacks in "
    "co-op content add a target-Max-HP term (A×a% + H×h%) BEFORE the chain (see exceptions). Status: consistent but NOT measured; do not treat as proven.")

# ---- PvP / content adjustments
add("content_adjustment", 40, "pvp_sqrt", "피해 = √(base chain ... × 최종 데미지%) × 스킬 계수% × 레벨 보정×2 × [PvP adjustment]", "Arena, Colosseum, World Arena",
    "NX_PVP_FORMULA", OFF)
add("content_adjustment", 41, "pvp_adjustment_old", "× [아레나 10,000 / 콜로세움 6,000] × 최대 HP[target] ÷ √(공격력×관통×데미지×증폭×((기공+스뎀)/2)×스탯비례×(크뎀×크확 비중)×((최소+최대)/2)×최종뎀) ÷ 1,000,000",
    "Arena (4/30-7/1), Colosseum (1/29-7/1)", "NX_PVP_FORMULA", OFF, "Bug: damage rose with target Max HP; replaced 7/2.")
add("content_adjustment", 42, "pvp_adjustment_new",
    "× C ÷ (((ATK×pierce×dmg×amp×((basic+skill)/2)×statprop×(critdmg×critweight)×((min+max)/2)×FD + 1e9)^0.23 × (MaxHP×1e8)^0.12 × ((DEF+6000)×1e12)^0.14 × ((1000+Toughness)×1e6)^0.5) ÷ 1e7) ÷ 1e6",
    "Arena, Colosseum, World Arena from 2026-07-02", "NX_PN_0702", OFF,
    "C = Arena 7,206,000,000 / Colosseum 4,323,600,000 / World Arena 5,764,800,000. Both offensive and defensive inputs of this adjustment use the TARGET's pre-battle stats "
    "(no active skills/buffs).", value={"arena": 7206000000, "colosseum": 4323600000, "world_arena": 5764800000, "exponents": [0.23, 0.12, 0.14, 0.5]})
for i, (mode, bands) in enumerate([("Arena / World Arena", [("31-60", 0.5), ("61-100", 1.3), ("101+", 1.5)]),
                                   ("Colosseum", [("31-60", 0.5), ("61-70", 1.3), ("71-100", 1.5), ("101+", 2.5)])]):
    for lvband, pct in bands:
        add("level_adjustment", 50 + i, f"pvp_level_adjustment_{mode}_{lvband}", f"each +1 level of the defender: final damage taken −{pct}% vs previous level",
            mode, "NX_PN_0702", OFF, "Formula term '결투장 보정으로 레벨에 의한 피해량 감소% × 2'. Levels 1-30: no reduction listed.", value=pct, unit="% per level")
add("content_adjustment", 60, "coop_sqrt", "final damage (after all stats incl. 받는 피해 감소) → square root", "Arena/Colosseum + 보스 레이드, 파티 퀘스트, 길드 수련장",
    "NX_ARENA_0622", OFF, "Official 6/22 wording. MSI (official Guide, 8/6) lists Party Quest & Boss/Guild Raid = square-root, Guild Training Ground = CUBE-root: "
    "conflict on 길드 수련장 (cube root is the later statement). Direction (player→boss vs boss→player) is not stated for PvE.")
add("content_adjustment", 61, "guild_training_cube_root", "cube-root-based damage adjustment", "Guild Training Ground", "MSI_GUIDE_CONTENT", "secondary_summary_of_official")
add("content_adjustment", 62, "potion_rules", "Arena/Colosseum HP potion 10%, MP 80%; World Arena HP 20% ×50% = 10%; Boss/Guild Raid HP potion cooldown 30 s", "PvP / raids",
    "MSI_GUIDE_CONTENT", "secondary_summary_of_official")

# ---- exceptions
add("exception", 70, "max_hp_proportional_monster_attacks",
    "monster hit input = ATK-based part + target-Max-HP-based part; summed value then goes through the normal chain (NOT fixed damage)",
    "길드 토벌전, 길드 보스 대전, 길드 대항전, 보스 레이드, 길드 레이드, 파티 퀘스트", "NX_PVP_FORMULA", OFF,
    "Official 6/25: '특별히 의도한 경우를 제외한다면 ... 계산식을 무시하는 고정데미지가 아닙니다 (피해 감소, 증가 등의 영향을 받습니다)'. Per-pattern coefficients for "
    "Pink Bean statues in monster_attack_patterns.json.")
add("exception", 71, "balrog_fixed_max_hp_damage", "마왕 발록: 모든 공격 = 캐릭터 최대 HP에 비례하는 고정 피해", "신규 용사 성장 챌린지 boss (2026-11-05~)",
    "NX_PN_1105", OFF, "Percentages per attack not published.")
add("exception", 72, "special_patterns", "fixed amount / Max-HP-based / set HP to ratio / keep 1 HP / instant incapacitation; some monsters ignore Defense",
    "dungeon mechanics", "MSI_GUIDE_CONTENT", "secondary_summary_of_official")

# ---- patch history affecting incoming damage
for o, sid, txt in [(80, "NX_PN_0409", "성장던전 무기·경험치·강화 던전 91단계 이후 몬스터 공격력 단계별 상승량 감소"),
                    (81, "NX_PN_0611", "성장 던전 난이도별 공격력 증가량 감소 (무기/경험치/용사의 수련장 101단계 이후)"),
                    (82, "NX_PN_0813", "성장 던전 몬스터 공격력 하향; 자쿰 보스 공격력·체력·회피 하향"),
                    (83, "NX_PN_0903", "챕터 몬스터 공격력 하향: 24챕터부터 점진 적용, 상위 챕터 최대 약 54%"),
                    (84, "NX_PN_0702", "PvP 신규 수식 적용 (아레나/콜로세움/월드 아레나)")]:
    add("patch_change", o, sid, txt, "KR", sid, OFF, "Monster ATK values in growth_dungeon_monsters.json (client 1.18.0) already include these changes.")

# ---- unknowns
for o, n, why in [(90, "minimum_damage", "No floor (e.g. min 1) published for hits on the player."),
                  (91, "rounding", "Truncation/rounding point of the chain not published (official notice gives no rounding)."),
                  (92, "monster_skill_coefficients_chapters_dungeons", "Per-attack coefficients of chapter/growth-dungeon monsters not exported (only raid statues known)."),
                  (93, "monster_crit", "Monster Critical Rate/Damage absent from all monster stat exports."),
                  (94, "pve_level_difference_modifier", "No PvE level-difference modifier documented (PvP only)."),
                  (95, "pve_measurements", "No public measured monster→player hit values to validate the chain.")]:
    add("unknown", o, n, None, "PvE", "NX_GUIDE_OFFICIAL", "not_found", why + " The official battle guide (maplestoryidle.nexon.com) is behind a 403 bot wall.")

COV["incoming_damage_formula"] = (sum(1 for r in recs if r["verification_status"] != "not_found"), len(recs))
write_dataset("incoming_damage_formula", "Player incoming-damage formula: ordered terms, stacking rules, content/PvP adjustments, exceptions, unknowns",
              recs, len(recs), f"{COV['incoming_damage_formula'][0]} sourced terms/rules, {sum(1 for r in recs if r['verification_status']=='not_found')} explicit unknowns.")

# ---- StatGapValueTable
sr = json.load(open(RAW + "/msi/game-stat-rules.json"))
g = []
for row in sr["gapCurves"]["rows"]:
    r = dict(gap=row["gap"], evade_percent=row["evadePercent"], debuff_evade_percent=row["debuffEvadePercent"],
             debuff_duration_reduction_percent=row["debuffDurationReductionPercent"])
    r.update(meta("MSI_STATRULES", "verified_client_table", "gap = defender Evasion − attacker Accuracy (or Debuff Resistance − Effectiveness / Tolerance − Ignore)."))
    g.append(r)
write_dataset("stat_gap_table", "StatGapValueTable: evasion / debuff-evasion / debuff-duration-reduction by stat gap (1-100)", g, 100, "100/100 rows.")
COV["stat_gap_table"] = (len(g), 100)

# ---- Pink Bean statue attack inputs (mapleidleindex boss page, client 1.18)
t = open(OLDWEB + "/text/boss.txt", encoding="utf-8", errors="replace").read()
sec = t[t.find("A = 공격하는 석상의 현재 공격력"):t.find("예를 들어 아리엘의 지연 타격")]
pats, cur = [], None
for line in sec.split("\n"):
    line = line.strip()
    m = re.match(r"^(아리엘|솔로몬|렉스|휘긴|무닌)\b", line)
    if m:
        cur = m.group(1)
        continue
    cells = [c.strip() for c in line.split("|") if c.strip()]
    if cur and len(cells) == 4 and cells[0] != "패턴":
        cd = cells[1]
        a = re.search(r"(\d+)% A", cells[2]); h = re.search(r"(\d+)% H", cells[2])
        r = dict(boss="핑크빈 (석상)", statue=cur, pattern=cells[0], cooldown_and_first_delay=cd, hit_input=cells[2],
                 attack_coefficient_percent=int(a.group(1)) if a else (0 if "직접 피해 없음" in cells[2] else None),
                 target_max_hp_coefficient_percent=int(h.group(1)) if h else (0 if "직접 피해 없음" in cells[2] else None),
                 statue_base_attack=45000000, description=cells[3])
        r.update(meta("MII_BOSS", "verified_client_table",
                      "A = attacking statue's current ATK (base 45,000,000), H = struck player's Max HP. Input per hit BEFORE defense/toughness/evasion (site note)."))
        pats.append(r)
write_dataset("monster_attack_patterns", "Monster→player hit inputs (ATK% + target MaxHP%) for Pink Bean raid statues (KR client 1.18)", pats, None,
              f"{len(pats)} patterns; only raid statues have published per-pattern inputs.")
COV["monster_attack_patterns"] = (len(pats), None)
json.dump(COV, open(SCRATCH + "/mdb/cov_damage.json", "w"))
print("damage ok", COV)

# SOURCES_DUMP
from common import SOURCES as _S
json.dump(_S, open(SCRATCH + "/mdb/sources_build_damage.json", "w"), ensure_ascii=False)
