#!/usr/bin/env python3
"""Generate BigStoryIdleRPG/Data/Content.lua (growth dungeons, world boss, boss raids,
guild raids, 마왕 발록, party quests, monster park, guild content, quick hunt) from
research/spec/content.json, combat-stages.json, research-progression.json and items-gacha.json.

A few KR reward tables that only exist in the free-income research (research-income.md,
citation keys IV769 / IV377 / NX_PN_1127 / NX_PN_1105) are embedded below as literals
with their citation; when research-income.json is found (research/spec or argv[1]) they are
checked against it.

Usage: python3 -I tools/gen_content.py [path/to/research-income.json]
"""
import json
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
from luagen import write_lua  # noqa: E402

ROOT = os.path.dirname(HERE)
SPEC = os.path.join(ROOT, "research", "spec")
OUT = os.path.join(ROOT, "BigStoryIdleRPG", "Data", "Content.lua")


def load(name):
    with open(os.path.join(SPEC, name), encoding="utf-8") as f:
        return json.load(f)


def num(v):
    """Spec numbers: ints, floats or digit strings with commas -> int/float."""
    if v is None or v == "":
        return None
    if isinstance(v, bool):
        return v
    if isinstance(v, (int, float)):
        return v
    s = str(v).replace(",", "").strip()
    try:
        return int(s)
    except ValueError:
        return float(s)


KO_UNITS = {"만": 10 ** 4, "억": 10 ** 8, "조": 10 ** 12, "경": 10 ** 16, "해": 10 ** 20}


def ko_num(s):
    """'8억 8,749만' -> 887490000, '120조' -> 120e12, '4,500만' -> 45000000, '20,000' -> 20000."""
    s = str(s).replace("약", "").replace("점", "").strip()
    if not s:
        return None
    total = 0
    rest = 0
    for tok in s.split():
        m = re.match(r"^([\d,\.]+)([만억조경해]?)$", tok)
        if not m:
            raise ValueError("bad korean number %r" % s)
        v = float(m.group(1).replace(",", ""))
        if m.group(2):
            total += v * KO_UNITS[m.group(2)]
        else:
            rest += v
    v = total + rest
    return int(v) if v == int(v) and v < 2 ** 63 else v


def ko_range(s):
    """'4,325 ~ 6,850' -> (4325, 6850); '38,400,000' -> (38400000, 38400000)."""
    parts = [p.strip() for p in str(s).split("~")]
    lo = ko_num(parts[0])
    hi = ko_num(parts[1]) if len(parts) > 1 else lo
    return lo, hi


def trailing_int(s):
    """'4조 4,000억4,400,000,000,000' -> 4400000000000 (the exact figure after the Korean text)."""
    m = re.search(r"([\d,]+)$", str(s).strip())
    return int(m.group(1).replace(",", ""))


def pct_ppm(s):
    """'0.1667%' -> 1667 (per 1,000,000); '-' -> 0."""
    s = str(s).strip()
    if s in ("-", "", "0"):
        return 0
    return round(float(s.rstrip("%")) * 10000)


def content(d, cid):
    for c in d["contents"]:
        if c["id"] == cid:
            return c
    raise KeyError(cid)


GRADE_BY_KO = {"노말": "Grade1", "레어": "Grade2", "에픽": "Grade3", "유니크": "Grade4", "레전더리": "Grade5",
               "레전더리+": "Grade5_1", "미스틱": "Grade6", "미스틱+": "Grade6_1"}
TIER_BY_KO = {"하급": 1, "중급": 2, "상급": 3, "최상급": 4}
DIFF_ORDER = ["쉬움", "보통", "어려움", "카오스"]


# ---------------------------------------------------------------------------
# Growth dungeons
# ---------------------------------------------------------------------------
SCROLL_COLS = {"노말 40%": "scrollNormal", "레어 40%": "scrollRare", "레어 25%": "scrollRare25",
               "에픽 70%": "scrollEpic", "에픽 30%": "scrollEpic30", "에픽 15%": "scrollEpic15"}


def gen_growth(cd, cs):
    g = cs["growthDungeons"]

    def boss_rows(key):
        rows = []
        sim = g[key]["simulatorStages"]
        for r, s in zip(g[key]["rows"], sim):
            assert r["stage"] == s["stage"]
            st = s["stats"]
            assert num(st["maxHp"]) == num(r["hp"]) and num(st["attack"]) == num(r["attack"])
            rows.append({"hp": num(r["hp"]), "atk": num(r["attack"]), "def": r["defence"], "hit": st["hit"],
                         "avoid": r["avoid"], "time": r["time_sec"], "hard": r["hard"]})
        return rows

    exp_rows = []
    for r in g["experienceDungeon"]["rows"]:
        exp_rows.append({"kills": r["kill_count"], "time": r["base_time_sec"],
                         "hp": [num(r["normal1_hp"]), num(r["normal2_hp"]), num(r["normal3_hp"])],
                         "timerHp": num(r["timer_hp"]), "def": r["normal_defence"], "avoid": r["normal_avoid"],
                         "timerAvoid": r["timer_avoid"], "atk": num(r["attack"]), "hard": r["hard"]})
    sweep = [num(x["expPerSweep"]) for x in content(cd, "growth_exp_dungeon")["rewards"]["expPerSweep"]]
    assert len(sweep) == 150
    gear_rows = []
    for r in g["equipmentDungeon"]["rows"]:
        gear_rows.append({"kills": r["kill_count"], "time": r["time_sec"], "hp": num(r["normal_hp"]),
                          "bombHp": num(r["bomb_hp"]), "speedHp": num(r["speed_hp"]), "def": r["defence"],
                          "avoid": r["normal_avoid"], "bombAvoid": r["bomb_avoid"], "speedAvoid": r["speed_avoid"],
                          "atk": num(r["attack"]), "hard": r["hard"]})
    tr_rows = []
    for r in g["heroTrainingGround"]["rows"]:
        tr_rows.append({
            "hp": {"normal": num(r["normal_hp"]), "large": num(r["large_hp"]), "flying": num(r["flying_hp"]),
                   "buff": num(r["buff_hp"]), "boss": num(r["boss_hp"])},
            "atk": {"normal": num(r["normal_attack"]), "large": num(r["large_attack"]),
                    "flying": num(r["flying_attack"]), "buff": num(r["buff_attack"]), "boss": num(r["boss_attack"])},
            "def": r["normal_defence"], "buffDef": r["buff_defence"], "bossDef": r["boss_defence"],
            "avoid": r["normal_avoid"], "buffAvoid": r["buff_avoid"], "bossAvoid": r["boss_avoid"],
            "bossAt": r["boss_spawn_sec"], "time": r["total_time_sec"], "minMobs": r["min_monster_count"],
            "pool": {"normal": r["pool_normal"], "large": r["pool_large"], "flying": r["pool_flying"],
                     "atkSpeed": r["pool_attack_speed"], "moveSpeed": r["pool_move_speed"]},
            "hard": r["hard"]})
    # enhancement dungeon scroll table (per clear / sweep, ppm)
    table = content(cd, "growth_enhance_dungeon")["rewards"]["scrollDropTable"]
    head = table[0]
    bands = []
    for row in table[1:]:
        rng = row[0].split("~")
        lo = int(rng[0])
        hi = int(rng[1]) if len(rng) > 1 else lo
        drops = {}
        for col, cell in zip(head[1:], row[1:]):
            ppm = pct_ppm(cell)
            if ppm:
                drops[SCROLL_COLS[col]] = ppm
        bands.append({"from": lo, "to": hi, "drops": drops})
    enh_sim = g["enhancementDungeon"]["simulator"]["combatPatterns"][0]
    wb_sup = cs["growthDungeons"]
    return {
        "rules": {"dailyKeys": 3, "keyCap": 10, "bulkSweepStage": 50, "stages": 150,
                  "src": "research-progression §9 (3 keys/day, bulk sweep after 50), research-income §2.21 "
                         "(cap 10, not used on failure)"},
        "weapon": {"nameKo": "무기 던전", "monsterKo": "머쉬맘", "rows": boss_rows("weaponDungeon"),
                   "initialDistanceMm": 4951},
        "exp": {"nameKo": "경험치 던전", "rows": exp_rows, "sweepExp": sweep, "timerBonusSec": 4, "timerBuffSec": 10},
        "gear": {"nameKo": "장비 던전", "rows": gear_rows, "pool": {"normal": 44, "bomb": 4, "speed": 2},
                 "bombRadiusMm": 3300, "bombDelayMs": 300, "speedBuffSec": 5},
        "training": {"nameKo": "용사의 수련장", "rows": tr_rows, "killAtkPct": 2, "killMovePct": 1, "killBuffSec": 60,
                     "killBuffMax": 100, "buffMobStacks": 5},
        "enhance": {"nameKo": "강화 던전", "monsterKo": "발록", "rows": boss_rows("enhancementDungeon"),
                    "scrollBands": bands, "initialDistanceMm": 4740,
                    "bossDown": {"startMs": enh_sim["startMinMs"], "durationMs": enh_sim["durationMs"],
                                 "intervalMs": enh_sim["intervalMs"], "defenceRatio": 0, "atkSpeedPct": 100}},
    }


# ---------------------------------------------------------------------------
# World boss
# ---------------------------------------------------------------------------
def gen_world_boss(cd, prog):
    wb = content(cd, "world_boss")
    levels = []
    for r, s in zip(wb["levels"]["rows"], wb["simulatorStages_timeLimits"]):
        assert r["level"] == s["stage"]
        levels.append({"hp": num(r["hp"]), "atk": num(r["attack"]), "def": r["defence"], "hit": s["stats"]["hit"],
                       "avoid": r["avoid"], "time": s["timeLimitMs"] // 1000, "infinite": r["infinite"]})
    pats = {}
    for p in wb["simulator"]["combatPatterns"]:
        key = "untargetable" if p["state"] == "Untargetable" else "down"
        e = {"startMinMs": p["startMinMs"], "startMaxMs": p["startMaxMs"], "durationMs": p["durationMs"],
             "intervalMs": p["intervalMs"]}
        eff = p.get("effects") or {}
        if "targetWeaknessPct" in eff:
            e["weaknessPct"] = eff["targetWeaknessPct"]
            e["defenceRatio"] = eff["targetDefenseRatio"]
        pats[key] = e
    tiers = []
    for row in prog["worldBoss"]["tierRewardsKR_2026-09-22"]["rows"]:
        def new(cell):
            if cell.strip() in ("—", "-"):
                return 0
            return num(cell.split("→")[1])
        tiers.append({"name": row[0], "daily": new(row[1]), "weekly": new(row[2]), "cubes": new(row[3])})
    return {"nameKo": "월드보스", "monsterKo": "킹 캐슬 골렘", "levels": levels, "patterns": pats, "tiers": tiers,
            "initialDistanceMm": 4572, "dungeonType": "WorldBoss"}


# ---------------------------------------------------------------------------
# Boss raids
# ---------------------------------------------------------------------------
RAID_KEYS = {"raid_zakum": "zakum", "raid_horntail": "horntail", "raid_pinkbean": "pinkbean"}
RAID_SCROLLS = {"zakum": ("scrollZakum1", "scrollZakum2"), "horntail": ("scrollHorntail1", "scrollHorntail2"),
                "pinkbean": ("scrollPinkBean1", "scrollPinkBean2")}


def gear_index(items):
    idx = {}
    for g in items["equipment"]["gear"]:
        if g["sourceKind"] == "bossRaid":
            idx.setdefault((g["nameKo"], g["grade"], g["tier"]), g)
    return idx


def side(row):
    return {"primary": num(row["primary_hp"]), "part": num(row["part_hp"]), "atk": num(row["attack"]),
            "def": num(row["defence"]), "avoid": num(row["avoid"])}


def gen_raids(cd, items, prog):
    gidx = gear_index(items)
    drops_by = {}
    for r in items["dropTables"]["bossRaidEquipment"]["rows"]:
        g = gidx[(r["item"], GRADE_BY_KO[r["grade"]], TIER_BY_KO[r["tier"]])]
        drops_by.setdefault((r["boss"], r["difficulty"]), []).append({
            "code": g["code"], "item": r["item"], "grade": g["grade"], "tier": g["tier"], "part": g["part"],
            "permille": round(r["percent"] * 10), "burningPermille": round(r["burningUpPercent"] * 10)})
    out = {}
    for cid, key in RAID_KEYS.items():
        c = content(cd, cid)
        diffs = {}
        for row in c["difficulties"]["rows"]:
            dd = diffs.setdefault(row["difficulty"], {"nameKo": row["difficulty"]})
            dd[row["mode"]] = side(row)
            if row.get("time_sec"):
                dd["time"] = row["time_sec"]
                dd["teamDeaths"] = row["team_death_count"]
        dl = []
        low, mid = RAID_SCROLLS[key]
        for i, name in enumerate(DIFF_ORDER):
            if name not in diffs:
                continue
            dd = diffs[name]
            dd["index"] = i
            dd["drops"] = drops_by.get((c["difficulties"]["rows"][0]["boss"], name), [])
            # scroll.html: 하급 쉬움 4% / 보통 이상 3%, 중급 쉬움 없음 / 보통 이상 1%
            dd["scrolls"] = [{"key": low, "permille": 40}] if i == 0 else \
                [{"key": low, "permille": 30}, {"key": mid, "permille": 10}]
            dl.append(dd)
        row0 = c["difficulties"]["rows"][0]
        e = {"nameKo": row0["boss"], "primaryLabel": row0["primary_label"], "partLabel": row0["part_label"],
             "partCount": row0["part_count"], "difficulties": dl}
        if key == "pinkbean":
            e["noSupporter"] = True
            e["personalDeathsSingle"] = c["limits"]["personalDeathLimitSingle"]
            e["statues"] = ["아리엘", "솔로몬", "렉스", "휘긴", "무닌"]
            e["firstWakeHpRatio"] = 0.8   # facts_ko: 첫 기상 시 석상 최대 HP -20%
        out[key] = e
    nog = prog["bossRaids"]["noGearRewardsKR_2026-09-03"]
    out["rules"] = {
        "weeklyPerBoss": 2, "weeklyShared": 2, "singleRevives": 8, "doubleTickets": 2,
        "refillRedDia": [num(x) for x in prog["bossRaids"]["redDiamondRefillPrice"].split("red")[0].split("/")],
        # one pick per run: equipment 25% + scrolls 4% + fallback 71% (global Zakum odds, KR 9/3 amounts)
        "fallback": [
            {"key": "meso", "n": nog["meso"], "permille": 350},
            {"key": "eliteSummonPoint", "n": nog["eliteSummonPoint"], "permille": 160},
            {"key": "weaponStone", "n": nog["weaponEnhanceStone"], "permille": 100},
            {"key": "spellTrace", "n": nog["spellTrace"], "permille": 70},
            {"key": "timeSkip1m", "n": nog["timeReductionTicket1min"], "permille": 30},
        ],
        "unlocks": {
            # KR 4/30 (INV-80) / hotdeal gates / NV 9/3; {chapter, stage} where stage 0 = chapter boss
            "zakum": [[13, 10], [18, 10], [25, 10], [30, 15]],
            "horntail": [[26, 10]],
            "pinkbean": [[32, 0], [37, 0], [42, 0]],
        },
        "src": "research-progression §11, research-income §2.14/§6.4, items-gacha dropTables",
    }
    return out


def gen_guild_raids(cd):
    out = {}
    for cid, key, low, mid in (("guild_raid_zakum", "zakum", "scrollZakum1", "scrollZakum2"),
                               ("guild_raid_horntail", "horntail", "scrollHorntail1", "scrollHorntail2")):
        c = content(cd, cid)
        s = c["stats"]
        out[key] = {"nameKo": s["boss"], "primaryLabel": s["primary_label"], "partLabel": s["part_label"],
                    "primary": num(s["primary_hp"]), "part": num(s["part_hp"]), "partCount": s["part_count"],
                    "visibleTotal": num(s["visible_total"]), "atk": num(s["attack"]), "def": num(s["defence"]),
                    "avoid": num(s["avoid"]), "members": s["max_members"], "time": s["time_sec"],
                    "teamDeaths": s["team_death_count"], "perUserDeaths": s["per_user_death_count"],
                    # scroll.html: 누적 피해 10/40/80% -> 하급 3장, 50/90% -> 중급 2장 (확정)
                    "damageRewards": [{"pct": 10, "key": low, "n": 3}, {"pct": 40, "key": low, "n": 3},
                                      {"pct": 50, "key": mid, "n": 2}, {"pct": 80, "key": low, "n": 3},
                                      {"pct": 90, "key": mid, "n": 2}]}
    c = content(cd, "guild_raid_pinkbean")
    tbl = c["bodyAndStatues"]
    body = tbl[1]
    statues = [r[0] for r in tbl[2:]]
    buffs = {}
    for r in c["sealBuffs"][1:]:
        buffs[r[0]] = {"textKo": r[1], "sec": int(r[2].rstrip("초"))}
    # effects of the seal buffs as client stats (raw 0.1% units)
    eff = {"아리엘": [["FinalDamage", 400]], "솔로몬": [["AttackSpeed", 600], ["MpRegenRatio", 30]],
           "렉스": [["BuffDurationRatio", 500]], "휘긴": [["CoolTimeReduceRatio", 400], ["MpRegenRatio", 30]],
           "무닌": [["CcImmune", 1]]}
    for k, v in eff.items():
        buffs[k]["stats"] = v
    red = []
    for r in c["bodyDamageReductionByHp"][1:]:
        red.append({"hpPct": int(r[0].rstrip("%")), "reductionPct": int(r[2].rstrip("%"))})
    out["pinkbean"] = {
        "nameKo": "핑크빈", "unlockKo": c["unlock_ko"], "members": c["multiplayer"]["guildMembersMax"],
        "time": c["limits"]["timeSec"], "revivesBase": 5, "revivesPerMember": 3,
        "body": {"hp": ko_num(body[1]), "atk": ko_num(body[3]), "def": ko_num(body[4]), "hit": ko_num(body[5]),
                 "avoid": ko_num(body[6])},
        "statues": statues, "statueBaseHp": ko_num(tbl[2][1]), "firstWakeHpRatio": 0.4,
        "statueHpGrowth": 1.25, "healOnSealMin": 0.58, "healOnSealMax": 0.62,
        "sealSec": 85, "sealMotionSec": 2.7, "wakeSec": 5.5, "bodyAppearMs": 1500, "groggySec": 10,
        "sealBuffs": buffs, "bodyReduction": red, "bodyReductionMaxPct": 95, "bodyReductionCheckMs": 500,
    }
    assert out["pinkbean"]["statueBaseHp"] == 7.2e12
    return out


# ---------------------------------------------------------------------------
# 마왕 발록 (신규 용사 성장 챌린지 boss)
# ---------------------------------------------------------------------------
# research-income §3.8 (IV769): stage clear rewards; stage 2 (의상 교환권) has no wallet item here
BALROG_REWARDS = {
    1: {"weaponTicket": 100}, 3: {"companionTicket": 100}, 4: {"starforceScroll": 10},
    5: {"weaponStone": 100000}, 6: {"companionTicket": 100}, 7: {"weaponTicket": 250}, 8: {"timeSkip1m": 1000},
    9: {"companionTicket": 100}, 10: {"starforceScroll": 20}, 11: {"weaponStone": 200000},
    12: {"companionTicket": 200}, 13: {"weaponTicket": 500}, 14: {"timeSkip1m": 2000},
    15: {"companionTicket": 200}, 16: {"starforceScroll": 20}, 17: {"companionTicket": 200},
    18: {"cubeMiracle": 10}, 19: {"artifactChest": 30},
}


def gen_balrog(cd):
    c = content(cd, "challenge_balrog_new_hero")
    stages = []
    for r in c["stages"]["rows"]:
        stages.append({"hp": num(r["hp"]), "atk": num(r["attack"]), "def": r["defence"], "avoid": r["avoid"],
                       "time": r["time_sec"], "rewards": BALROG_REWARDS.get(r["stage"])})
    return {"nameKo": "마왕 발록", "stages": stages, "unkillableStage": 20, "unlockLevel": 30,
            "ticket": {"daily": 1, "cap": 3, "refundOnKill": True},
            "src": "content.json challenge_balrog_new_hero; research-income §3.8 (IV769)"}


# ---------------------------------------------------------------------------
# Party quests + monster park
# ---------------------------------------------------------------------------
def nearest_hunt_atk(cs, hp):
    """PROVISIONAL helper: chapter hunt attack of the stage whose monster HP is closest (log scale)."""
    import math
    best, bd = None, None
    for ch in cs["chapterStages"]["chapters"]:
        for st in ch["stages"]:
            h = st.get("hunt")
            if not h:
                continue
            mh = num(h["maxHp"])
            if not mh:
                continue
            dist = abs(math.log(mh) - math.log(hp))
            if bd is None or dist < bd:
                best, bd = num(h["attack"]), dist
    return best


def gen_party(cd, cs, items):
    c = content(cd, "party_quests")
    pq_codes = {}
    for g in items["equipment"]["gear"]:
        if g["sourceKind"] == "partyQuest":
            pq_codes[g["code"]] = g
    quests = []
    for qi, q in enumerate(c["quests"]):
        rows = {r[0]: r for r in q["monsterStatsTable"]["rows"]}
        three = len(q["monsterStatsTable"]["header"]) == 4   # 일반 / Wave2 중간보스 / Wave3 최종보스
        diffs = []
        for di, dd in enumerate(q["difficulties"]):
            r = rows[dd["difficulty"]]
            if three:
                nhp, ndef, navd = ko_range(r[1]), ko_range(r[2]), ko_range(r[3])
                mid = {"hp": ko_num(r[4]), "def": ko_num(r[5]), "avoid": ko_num(r[6])}
                boss = {"hp": ko_num(r[7]), "def": ko_num(r[8]), "avoid": ko_num(r[9])}
            else:
                nhp, ndef, navd = ko_range(r[1]), ko_range(r[3]), ko_range(r[5])
                mid = None
                boss = {"hp": ko_num(r[2]), "def": ko_num(r[4]), "avoid": ko_num(r[6])}
            code = "GEAR_PARTYDUNGEON_%d_%d" % (qi + 1, di + 1)
            lv = q["equipmentItemLevelRanges"][code]
            assert code in pq_codes
            e = {"nameKo": dd["difficulty"], "level": dd["dungeonLevel"], "exp": num(dd["expPerRun"]),
                 "gear": code, "itemLevel": [lv["min"], lv["max"]],
                 "normal": {"hpMin": nhp[0], "hpMax": nhp[1], "defMin": ndef[0], "defMax": ndef[1],
                            "avoidMin": navd[0], "avoidMax": navd[1]},
                 "boss": boss,
                 # PROVISIONAL: monster attack is not in the data -> chapter-hunt attack of the
                 # stage with the closest monster HP (normal) / closest boss HP (bosses)
                 "atkProvisional": {"normal": nearest_hunt_atk(cs, nhp[0]), "boss": nearest_hunt_atk(cs, boss["hp"])}}
            if mid:
                e["mid"] = mid
                e["atkProvisional"]["mid"] = nearest_hunt_atk(cs, mid["hp"])
            diffs.append(e)
        quests.append({"id": q["id"], "nameKo": q["name_ko"], "regionKo": q["region_ko"],
                       "slotKo": q["equipmentReward_ko"], "difficulties": diffs})
    drop = {}
    for r in items["dropTables"]["partyQuestEquipment"]["dropPercentByDifficulty"]:
        drop[r["difficulty"]] = {"permille": round(r["percent"] * 10), "burningPermille": round(r["burningUpPercent"] * 10)}
    pq = {"quests": quests, "drop": drop, "subLines": [0, 400, 400, 200],
          "unlocks": {"romeo": [22, 10], "romeoChaos": [37, 15]},
          "partyMax": 4, "restartSec": 15, "expeditionWeekly": 1,
          "src": "content.json party_quests; items-gacha dropTables; research-progression §12"}

    mp = content(cd, "monster_park_extreme")
    stats = mp["stages"]["monsterStats"][2:]
    exps = {r[0]: r for r in mp["stages"]["expRewards"][1:]}
    st_out = []
    for r in stats:
        ch, st = r[1].split("-")
        ex = exps[r[0]]
        base = trailing_int(ex[2])
        bonus = trailing_int(ex[4])
        st_out.append({"unlock": [int(ch), int(st)],
                       "normal": {"hp": num(r[2]), "def": num(r[3]), "avoid": num(r[4])},
                       "jackalope": {"hp": num(r[5]), "def": num(r[6]), "avoid": num(r[7])},
                       "bigfoot": {"hp": num(r[8]), "def": num(r[9]), "avoid": num(r[10])},
                       "exp": base, "starForce": int(ex[3]), "expBonus": bonus,
                       "atkProvisional": {"normal": nearest_hunt_atk(cs, num(r[2])),
                                          "bigfoot": nearest_hunt_atk(cs, num(r[8]))}})
    park = {"nameKo": "몬스터파크 익스트림", "stages": st_out, "missions": 4, "killsPerMission": 15,
            "fleeSec": [20, 40, 60, 80], "jackalopeMissionBonus": 10, "timeSec": 1800, "partyMax": 4,
            "noSupporter": True, "weeklyTickets": 2, "ticketCap": 2, "startTickets": 2, "bonusPct": 30,
            "src": "content.json monster_park_extreme"}
    return pq, park


# ---------------------------------------------------------------------------
# Guild content
# ---------------------------------------------------------------------------
def brackets(rows):
    out = []
    for r in rows[1:]:
        t = None if r[1].startswith("상한") else ko_num(r[1])
        out.append({"cap": t, "n": float(r[2])})
    return out


def gen_guild(cd):
    tb = content(cd, "guild_boss_raid_toubeol")
    boss = {"nameKo": "길드 토벌전", "dungeonType": "GuildBoss",
            "tiers": [{"hp": num(r["hp"]), "def": r["defence"], "avoid": r["avoid"], "time": r["available_time_sec"],
                       "atk": num(r["attack"])} for r in tb["tiers"]["rows"]],
            "brackets": brackets(tb["scoreConversion"]["brackets"]),
            "timeBase": 50, "timePerKill": 5, "timeKillsMax": 10, "timeMax": 100}
    lg = content(cd, "guild_league")
    league = {"nameKo": "길드 대항전", "dungeonType": "GuildLeague",
              "waves": [{"minionHp": num(r["minion_hp"]), "minionShield": num(r["minion_shield"]),
                         "bossHp": num(r["boss_hp"]), "bossShield": num(r["boss_shield"]),
                         "bossDef": r["boss_defence"], "minionDef": r["minion_defence"], "bossAvoid": r["boss_avoid"],
                         "minionAvoidStart": r["minion_avoid_start"], "minionAvoidEnd": r["minion_avoid_end"],
                         "bossAtk": num(r["boss_attack"]), "minionAtk": num(r["minion_attack"])}
                        for r in lg["waves"]["rows"]],
              "brackets": brackets(lg["scoreConversion"]["brackets"]),
              "minions": 6, "timeBase": 35, "bossKillBonusMax": 20, "minionAvoidDecaySec": 8}
    mb = content(cd, "guild_boss_battle")
    states = mb["states"]["rows"]
    match = {"nameKo": "길드 보스 대전", "dungeonType": "GuildLeagueVersus", "time": 100, "def": states[0]["raw_defence"],
             "avoid": 100, "atk": num(states[0]["attack"]), "stackToughness": states[1]["toughness"],
             "maxStacks": 2, "downSec": 11.7, "downDefencePower": states[3]["defence_power"]}
    gt = content(cd, "guild_training")
    training = {"nameKo": "길드 수련장", "dungeonType": "GuildTraining", "time": 90, "plusSec": 2, "plusPerKills": 30,
                "normalPoints": 84, "specialPoints": 3, "normalRespawnSec": 8, "specialRespawnSec": 20,
                "regular": [{"hp": num(r["hp"]), "score": r["score"], "def": r["defence"], "avoid": r["avoid"],
                             "atk": num(r["attack"])} for r in gt["regular"]["rows"]],
                "special": [{"hits": r["required_hits"], "score": r["score"], "def": r["defence"], "avoid": r["avoid"],
                             "atk": num(r["attack"])} for r in gt["special"]["rows"]]}
    # check the published normal score formula 3 x [100 n + 3 (n-1)^3]
    for i, r in enumerate(training["regular"]):
        n = i + 1
        assert r["score"] == 3 * (100 * n + 3 * (n - 1) ** 3), (n, r["score"])
    wolf = content(cd, "guild_bounty_inferno_wolf")
    bounty = {"nameKo": "불꽃늑대의 소굴", "dungeonType": "InfernoWolf",
              "stages": [{"hp": num(r["hp"]), "atk": num(r["attack"]), "def": r["defence"], "avoid": r["avoid"],
                          "time": r["time_sec"], "score": r["clear_score"]} for r in wolf["stages"]["rows"]],
              # research-progression §15 / research-income §6.3 (NX_PN_1105): min guild score -> weekly reward
              "weekly": [
                  {"rank": "1위", "min": 20000, "wolfCoin": 14000, "pouch": ["enchantPouchTop", 10], "stones": 300},
                  {"rank": "2위", "min": 15000, "wolfCoin": 13000, "pouch": ["enchantPouchHigh", 10], "stones": 200},
                  {"rank": "3위", "min": 10000, "wolfCoin": 12000, "pouch": ["enchantPouchHigh", 9], "stones": 100},
                  {"rank": "4~5위", "min": 5000, "wolfCoin": 11000, "pouch": ["enchantPouchHigh", 8]},
                  {"rank": "6~10위", "min": 4000, "wolfCoin": 10000, "pouch": ["enchantPouchHigh", 7]},
                  {"rank": "11~20위", "min": 3000, "wolfCoin": 9500, "pouch": ["enchantPouchHigh", 6]},
                  {"rank": "21~30위", "min": 2000, "wolfCoin": 9000, "pouch": ["enchantPouchHigh", 5]},
                  {"rank": "31~50위", "min": 1500, "wolfCoin": 8500, "pouch": ["enchantPouchMid", 5]},
                  {"rank": "51~70위", "min": 1000, "wolfCoin": 8000, "pouch": ["enchantPouchMid", 4]},
                  {"rank": "71~100위", "min": 800, "wolfCoin": 7800, "pouch": ["enchantPouchMid", 3]},
                  {"rank": "101~200위", "min": 600, "wolfCoin": 7600, "pouch": ["enchantPouchMid", 2]},
                  {"rank": "201~300위", "min": 500, "wolfCoin": 7400, "pouch": ["enchantPouch", 2]},
                  {"rank": "301~400위", "min": 500, "wolfCoin": 7200, "pouch": ["enchantPouch", 1]},
                  {"rank": "401~500위", "min": 300, "wolfCoin": 7000},
                  {"rank": "501~1,000위", "min": 100, "wolfCoin": 6800},
                  {"rank": "1,001위 이하", "min": 1, "wolfCoin": 6600},
              ]}
    # research-income §6.3 (NX_PN_1127, IV377): 대항전 rank 1-5 buff + 미라클 큐브; 수련장 rank 1-7 무기 소환권;
    # 보스 대전 win / lose
    rewards = {
        "league": [{"rank": 1, "expPct": 16, "mesoPct": 13, "cubeMiracle": 15},
                   {"rank": 2, "expPct": 13, "mesoPct": 13, "cubeMiracle": 10},
                   {"rank": 3, "expPct": 10, "mesoPct": 10, "cubeMiracle": 7},
                   {"rank": 4, "expPct": 7, "mesoPct": 0, "cubeMiracle": 5},
                   {"rank": 5, "expPct": 5, "mesoPct": 0, "cubeMiracle": 3}],
        "training": [{"rank": r, "weaponTicket": n} for r, n in
                     ((1, 750), (2, 500), (3, 350), (4, 250), (5, 200), (6, 150), (7, 100))],
        "match": {"win": {"expPct": 16, "mesoPct": 16, "cubeAdditional": 10, "days": 7},
                  "lose": {"expPct": 7, "mesoPct": 0, "cubeAdditional": 3, "days": 7}},
        "src": "research-income §6.3 (NX_PN_1127, IV377), research-progression §15",
    }
    return {"boss": boss, "league": league, "match": match, "training": training, "bounty": bounty,
            "rewards": rewards}


def check_income(path, balrog, guild):
    if not path or not os.path.exists(path):
        print("research-income.json not found - embedded KR tables not cross-checked")
        return
    with open(path, encoding="utf-8") as f:
        inc = json.load(f)
    clear = dict((r[0], r[1]) for r in inc["newcomerMissions"]["newHeroGrowthChallenge"]["bossStageClear"])
    for st, rw in BALROG_REWARDS.items():
        (k, n), = rw.items()
        txt = clear[st].replace(",", "")
        assert txt.endswith(" " + str(n)), (st, txt, n)
    for row, ref in zip(guild["rewards"]["training"], inc["guild"]["guildTraining"]):
        assert row["weaponTicket"] == ref[1]
    for row, ref in zip(guild["rewards"]["league"], inc["guild"]["guildWar"]):
        assert row["cubeMiracle"] == ref[2]
    for row, ref in zip(guild["bounty"]["weekly"], inc["guild"]["bountyWeekly"]):
        assert row["min"] == ref[1]
    print("research-income cross-check ok")


def main(argv):
    cd = load("content.json")
    cs = load("combat-stages.json")
    prog = load("research-progression.json")
    items = load("items-gacha.json")
    growth = gen_growth(cd, cs)
    wb = gen_world_boss(cd, prog)
    raids = gen_raids(cd, items, prog)
    graids = gen_guild_raids(cd)
    balrog = gen_balrog(cd)
    pq, park = gen_party(cd, cs, items)
    guild = gen_guild(cd)
    quick = {"firstKills": 1000, "perUse": 5, "maxKills": 3000, "freePerDay": 1, "adPerDay": 1,
             "redPrices": [500, 750, 1000], "src": "research-progression §8, research-income §2.16"}
    burning = {"durationSec": 600, "suggestedKills": 400, "src": "content.json chapter_hunt.burningField"}
    income = argv[1] if len(argv) > 1 else os.path.join(SPEC, "research-income.json")
    check_income(income, balrog, guild)
    # world boss tiers equal the research-income table when available
    if os.path.exists(income):
        with open(income, encoding="utf-8") as f:
            inc = json.load(f)
        for t, ref in zip(wb["tiers"], inc["worldBoss"]["tierRewards_after_0922"]):
            assert (t["name"], t["daily"], t["weekly"], t["cubes"]) == tuple(ref), (t, ref)
    write_lua(OUT, [
        ("D.ContentGrowth", growth, None),
        ("D.ContentWorldBoss", wb, None),
        ("D.ContentRaids", raids, None),
        # guild content was removed (user decision); only the Pink Bean seal mechanics remain,
        # shared by the normal Pink Bean boss raid
        ("D.ContentPinkBeanSeal", graids["pinkbean"], None),
        ("D.ContentBalrog", balrog, None),
        ("D.ContentPartyQuests", pq, None),
        ("D.ContentMonsterPark", park, None),
        ("D.ContentQuickHunt", quick, None),
        ("D.ContentBurning", burning, None),
    ], note="Content modes (tools/gen_content.py): growth dungeons, world boss, boss raids,\n"
            "마왕 발록, party quests, monster park, quick hunt (guild content removed). Client 1.18.0 numbers\n"
            "(content.json / combat-stages.json), KR rules (research-progression), drops (items-gacha).\n"
            "Fields named *Provisional are derived placeholders (see Systems/Content.lua).")
    print("ok: growth %d stages, world boss %d levels, raids %d, PQ %d" % (
        len(growth["weapon"]["rows"]), len(wb["levels"]), 3, len(pq["quests"])))


if __name__ == "__main__":
    main(sys.argv)
