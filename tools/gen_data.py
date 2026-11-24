#!/usr/bin/env python3
"""Generate BigStoryIdleRPG/Data/*.lua from research/spec/*.json.

Usage: python3 -I tools/gen_data.py  (run from the repository root)
"""
import json
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
from luagen import write_lua  # noqa: E402

ROOT = os.path.dirname(HERE)
SPEC = os.path.join(ROOT, "research", "spec")
OUT = os.path.join(ROOT, "BigStoryIdleRPG", "Data")

CURVE_MAX_LEVEL = 300


def load(name):
    with open(os.path.join(SPEC, name), encoding="utf-8") as f:
        return json.load(f)


def big(v):
    """Spec big integers are strings -> float/int."""
    if v is None:
        return None
    if isinstance(v, (int, float)):
        return v
    s = str(v).replace(",", "")
    try:
        return int(s)
    except ValueError:
        return float(s)


# ---------------------------------------------------------------------------
# Jobs & skills
# ---------------------------------------------------------------------------
SKILL_DROP_KEYS = {"heroOwners", "masteryOwners", "refs", "effects", "SkillIconPath"}


def clean_skill(raw):
    out = {k: v for k, v in raw.items() if k not in SKILL_DROP_KEYS}
    ops = out.get("Operations") or []
    if ops and ops[0] is None:
        ops = ops[1:]
    out["Operations"] = ops
    return out


def gen_skills():
    d = load("jobs-skills.json")
    cs = load("combat-stages.json")
    job_stats = cs["statSystem"]["primaryStatConversions"]["jobStatTypes"]

    skills = {}
    for sid, s in d["skills"].items():
        rec = clean_skill(s["raw"])
        rec["nameKo"] = s.get("nameKo")
        if s.get("tags"):
            rec["tags"] = s["tags"]
        skills[int(sid)] = rec

    curves = {}
    for cid, arr in d["factorCurves"].items():
        curves[int(cid)] = [arr[i] for i in range(1, min(len(arr), CURVE_MAX_LEVEL + 1))]

    projectiles = {int(k): v for k, v in d["projectiles"].items()}

    jobs = []
    for j in d["jobs"]:
        rows = []
        for r in j["skillRows"]:
            row = {k: r.get(k) for k in (
                "SkillIndex", "JobStep", "DisableSkillLevel", "HeroSkillType", "RequireLevel",
                "RequireMissionIndex", "nameKo", "nameEn", "category", "isBasicAttack")}
            rows.append(row)
        masteries = []
        for m in j["masteries"]:
            masteries.append({k: m.get(k) for k in (
                "MasteryIndex", "ParentSkillIndex", "programSkillId", "TierIndex", "RequireCreatureLevel",
                "IsMainNode", "RequireMasteryIndex", "StatData", "CostData", "LearnedDelaySeconds", "nameKo")})
        main, sub = job_stats.get(j["nameKo"], ["STR", "DEX"])
        tiers = {}
        for step, t in j["tiers"].items():
            tiers[int(step)] = t
        jobs.append({
            "index": j["creatureIndex"],
            "key": j["key"],
            "codeName": j["codeName"],
            "mapleNameKo": j["nameKo"],
            "mapleNameEn": j["nameEn"],
            "attackType": j["attackType"],
            "mainStat": main,
            "subStat": sub,
            "initialBaseAttack": j["initialBaseAttackSkillIndex"],
            "baseAttacks": {int(k): v for k, v in j["baseAttackSkillIndices"].items()},
            "tiers": tiers,
            "rows": rows,
            "masteries": masteries,
        })

    rules = d["rules"]
    write_lua(os.path.join(OUT, "Skills.lua"), [
        ("D.Skills", skills, None),
        ("D.Projectiles", projectiles, None),
    ], note="Skill records (client 1.18.0 SkillTable/SkillProjectileTable) - Operations are 1-based.")
    write_lua(os.path.join(OUT, "Jobs.lua"), [
        ("D.Jobs", jobs, {"indent": " "}),
        ("D.SkillCurves", curves, None),
        ("D.ExpressionMacros", d["expressionMacros"], {"indent": " "}),
        ("D.StateMaxStacks", d["stateMaxStacks"], None),
        ("D.SkillRules", {
            "stepUnlockLevel": {1: 1, 2: 30, 3: 60, 4: 100},
            "enhance": {int(k): v for k, v in rules["skillLevel"]["enhance"]["assumedFullySpentFormula"].items()},
        }, {"indent": " "}),
    ])
    return jobs


# ---------------------------------------------------------------------------
# Leveling, chapters, dungeons, combat constants
# ---------------------------------------------------------------------------
def gen_world():
    cs = load("combat-stages.json")
    lv = cs["leveling"]
    exp = [big(x["requiredExp"]) for x in lv["levels"]]

    chapters = []
    for c in cs["chapterStages"]["chapters"]:
        stages = []
        for st in c["stages"]:
            e = {
                "stage": st["stage"],
                "boss": st.get("isChapterBoss") or False,
            }
            h = st.get("hunt")
            if h:
                e["hunt"] = {
                    "atk": big(h.get("attack")), "hp": big(h.get("maxHp")), "def": big(h.get("defense")),
                    "hit": big(h.get("hitChance")), "avoid": big(h.get("avoidChance")),
                    "variants": h.get("variantCount"),
                }
            if st.get("expPerKill") is not None:
                e["exp"] = big(st["expPerKill"])
            if st.get("burningExpPerKill") is not None:
                e["burnExp"] = big(st["burningExpPerKill"])
            sp = st.get("spawn")
            if sp:
                e["spawn"] = {"n": sp.get("monstersPerCycle"), "cycle": sp.get("cycleSeconds")}
            ch = st.get("challenge")
            if ch:
                e["challenge"] = {k: big(v) if isinstance(v, str) and v.replace(",", "").isdigit() else v
                                  for k, v in ch.items()}
            bs = st.get("boss")
            if bs:
                e["bossFight"] = {k: big(v) if isinstance(v, str) and v.replace(",", "").isdigit() else v
                                  for k, v in bs.items()}
            stages.append(e)
        chapters.append({"chapter": c["chapter"], "nameKo": c.get("nameKo"), "stages": stages})

    df = cs["damageFormula"]
    combat = {
        "missPermilleByGap": df["hitAndAvoid"]["avoidPermilleByGap"],
        "defNumerator": df["defense"]["constants"]["numerator"],
        "defOffset": df["defense"]["constants"]["offset"],
        "maxPierce": 999,
        "attackSpeedCap": 1500,
        "toughnessCap": 950,
        "coolTimeReduceCap": 999,
        "jobAdvancementLevels": lv.get("jobAdvancementLevels"),
        "offline": lv["expRules"]["offline"],
        "burning": lv["expRules"]["burningField"],
        "supporter": {
            "initialCoolTimeMs": cs["combatTiming"]["supporterSpawn"]["initialMinCoolTimeMs"],
            "coolTimeMs": cs["combatTiming"]["supporterSpawn"]["coolTimeMs"],
            "durationMs": cs["combatTiming"]["supporterSpawn"]["spawnDurationMsValues"][0],
            "ratiosByContent": cs["combatTiming"]["supporterSpawn"]["ratiosByContent"],
            "guild": cs["combatTiming"]["supporterSpawn"]["guildContents"],
        },
        "initialDistanceMm": cs["combatTiming"]["contentInitialDistanceMm"],
    }
    write_lua(os.path.join(OUT, "World.lua"), [
        ("D.ExpTable", exp, None),
        ("D.MaxLevel", lv["maxCharacterLevel"], None),
        ("D.Chapters", chapters, {"bignum": True}),
        ("D.Combat", combat, {"indent": " "}),
        ("D.GrowthDungeonsRaw", cs["growthDungeons"], {"bignum": True}),
        ("D.ExpDungeonSweep", lv.get("experienceDungeonSweep"), {"bignum": True}),
        ("D.PartyQuestExp", lv.get("partyQuestExp"), {"bignum": True}),
        ("D.HeroPowerRaw", cs["statGrowth"].get("heroPower_용사의힘"), {"bignum": True}),
    ])


def main():
    os.makedirs(OUT, exist_ok=True)
    gen_skills()
    gen_world()
    print("ok")


if __name__ == "__main__":
    main()
