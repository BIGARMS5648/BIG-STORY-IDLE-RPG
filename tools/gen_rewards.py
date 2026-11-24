#!/usr/bin/env python3
"""Generate BigStoryIdleRPG/Data/Rewards.lua (hunt drops, trial / boss first-clear rewards,
content time limits) from research/spec/research-progression.json.

Usage: python3 -I tools/gen_rewards.py
"""
import json
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
from luagen import write_lua  # noqa: E402

ROOT = os.path.dirname(HERE)
SPEC = os.path.join(ROOT, "research", "spec")
OUT = os.path.join(ROOT, "BigStoryIdleRPG", "Data", "RewardTables.lua")

# research item names -> wallet keys (BigStoryIdleRPG/Data/Currencies.lua)
KEY = {
    "meso": "meso", "Meso": "meso",
    "eliteSummonPoint": "eliteSummonPoint", "Elite Monster Summoning Point": "eliteSummonPoint",
    "redDiamond(FreeDia)": "redDia", "Red Diamond": "redDia",
    "weaponSummonTicket": "weaponTicket", "Weapon Summoning Ticket": "weaponTicket",
    "weaponEnhanceStone": "weaponStone", "Weapon Enhancer": "weaponStone",
    "medalOfHonor": "honorMedal", "Medal of Honor": "honorMedal",
    "artifactEnhanceStone": "artifactStone", "Artifact Enhancer": "artifactStone",
    "journeyToken": "journeyToken", "JOURNEY_COIN": "journeyToken",
    "timeReductionTicket1min": "timeSkip1m",
    "exp": "exp",
}


def key(name):
    k = KEY.get(name)
    if not k:
        raise KeyError(name)
    return k


def main():
    with open(os.path.join(SPEC, "research-progression.json"), encoding="utf-8") as f:
        d = json.load(f)

    # per-stage hunt drops: {key, amount, ppm (per 1,000,000)}
    hunt = {}
    for sid, m in d["chapterHuntDropsGlobal"]["maps"].items():
        drops = [{"key": key(r["name"]), "n": r["amount"], "ppm": r["prob"]} for r in m["killReward"]]
        if drops:
            hunt[sid] = drops
    chapters = d["chapters"]["chapters"]
    for c in chapters:
        ch = c["chapter"]
        hd = c.get("huntDropsPerKill") or {}
        n_hunt = c.get("huntStages") or 0
        for st in range(1, n_hunt + 1):
            sid = "%d-%d" % (ch, st)
            if sid in hunt:
                continue  # global per-stage table agrees with KR stage1 rows (checked: 0 mismatches)
            src = hd.get("stage1") if st <= max(1, n_hunt // 2) else (hd.get("lastStage") or hd.get("stage1"))
            if src:
                hunt[sid] = [{"key": key(r["item"]), "n": r["min"], "ppm": round(r["probPct"] * 10000)} for r in src]

    trials, bosses, names = {}, {}, {}
    for c in chapters:
        ch = c["chapter"]
        names[ch] = {"maple": c.get("nameKo"), "mapleEn": c.get("nameEnGlobalWiki"),
                     "monsters": c.get("huntStageMonsters")}
        for sid, t in (c.get("trialFirstClearRewards") or {}).items():
            trials[sid] = {
                "time": t.get("timeLimitSec"), "maxAcc": t.get("maxAccMonsterCount"),
                "rewards": {key(r["item"]): r["min"] for r in t["rewards"]},
            }
        for b in c.get("chapterBoss") or []:
            st = b.get("stats") or {}
            bosses[ch] = {
                "stage": b["stageId"], "maple": (b.get("nameKo") or [None])[0], "time": b.get("timeLimitSec"),
                "rewards": {key(r["item"]): r["min"] for r in b.get("firstClearRewards") or []},
                "atk": st.get("attack_min"), "hp": st.get("hp_min"), "def": st.get("defence_min"),
                "hit": st.get("hit_chance_min"), "avoid": st.get("avoid_chance_min"),
                "count": st.get("total_spawn_count"),
            }

    elite_field = {}
    for c in chapters:
        for sid, e in (c.get("eliteFieldStats") or {}).items():
            row = {}
            for part in ("eliteBoss", "eliteMinion"):
                p = e.get(part)
                if p:
                    row[part] = {"hp": p.get("hp_min"), "atk": p.get("attack_min"), "def": p.get("defence_min"),
                                 "hit": p.get("hit_chance_min"), "avoid": p.get("avoid_chance_min"),
                                 "n": p.get("variant_count")}
            elite_field[sid] = row

    offline = d.get("offlineAndIdle", {})
    quick = d.get("quickHunt", {})
    write_lua(OUT, [
        ("D.HuntDrops", hunt, None),
        ("D.TrialRewards", trials, None),
        ("D.BossRewards", bosses, {"indent": " "}),
        ("D.EliteFieldStats", elite_field, None),
        ("D.MapleChapterNames", names, None),
        ("D.IdleRules", {"offline": offline.get("kr"), "quickHunt": {
            "killsGranted": quick.get("killsGranted"), "price": quick.get("price")}}, {"indent": " "}),
    ], note="Hunt drops: per kill, ppm = probability per 1,000,000 (global Module:Dungeons/maps.json,\n"
            "cross-checked against KR client rows). Trial / boss first-clear rewards: KR client (MK-map).")
    print("hunt stages %d, trials %d, bosses %d" % (len(hunt), len(trials), len(bosses)))


if __name__ == "__main__":
    main()
