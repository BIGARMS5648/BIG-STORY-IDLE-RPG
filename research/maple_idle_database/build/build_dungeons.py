import json, sys, re, html
sys.path.insert(0, "/tmp/claude-0/-home-user-BIG-STORY-IDLE-RPG/f4db4718-c3e8-5335-9264-6dbe1627a364/scratchpad/mdb/scripts")
from common import *
import sources_reg  # noqa

COV = {}
LIVE_MAX, ANNOUNCED_MAX = 150, 160
js = open(RAW + "/growth_inline.js", encoding="utf-8").read()


def rows(var):
    m = re.search(r"const " + var + r"=(\[.*?\]);", js, re.S)
    return {r["stage"]: r for r in json.loads(m.group(1))}


KR = {k: rows(v) for k, v in [("weapon", "WEAPON_ROWS"), ("exp", "EXP_ROWS"), ("equipment", "GEAR_ROWS"),
                               ("hero_training", "TRAINING_ROWS"), ("enhancement", "ENHANCE_ROWS")]}
gd = json.load(open(RAW + "/msi-game-data-library.json"))
MSIMAP = {"weapon": "WeaponDungeon", "exp": "AntCave_Exp", "equipment": "GearDungeon", "enhancement": "EnhanceDungeon", "hero_training": "GuardianTower"}
MSI = {k: {s["dungeon"]: s for s in gd["stages"] if s["map"].startswith(v)} for k, v in MSIMAP.items()}
NAME_KO = {"weapon": "무기 던전", "exp": "경험치 던전", "equipment": "장비 던전", "hero_training": "용사의 수련장", "enhancement": "강화 던전"}
KEY_KO = {"weapon": "성장던전 입장권: 무기", "exp": "성장던전 입장권: 경험치", "equipment": "성장던전 입장권: 장비",
          "hero_training": "성장던전 입장권: 용사의 힘", "enhancement": "성장던전 입장권: 강화"}
REFUND = {"weapon": "wiki(global): key 'returned upon successfully clearing'", "exp": "wiki(global): key 'returned upon successfully clearing'",
          "equipment": "wiki(global): key 'returned upon successfully clearing'", "enhancement": "wiki(global): key returned if you FAIL (retry freely)",
          "hero_training": None}
UNLOCK_GQ = {"weapon": 34, "exp": 45, "equipment": 67, "hero_training": None, "enhancement": 131}

# ------------------------------------------------------------------ monsters (all dungeons)
mon = []
for d, tab in KR.items():
    for st in range(1, ANNOUNCED_MAX + 1):
        k = tab.get(st)
        m = MSI[d].get(st)
        r = dict(dungeon=d, dungeon_ko=NAME_KO[d], stage=st)
        if k:
            for kk, vv in k.items():
                if kk != "stage":
                    r[kk] = bigint(vv) if kk.endswith("hp") or kk == "attack" else vv
        msi_list = None
        if m:
            msi_list = [{"name": x["name"], "boss": x["boss"], "spawn": x["spawnCount"], "MaxHp": bigint(x["stats"]["MaxHp"]),
                         "Attack": bigint(x["stats"]["Attack"]), "Defence": x["stats"]["Defence"], "HitChance": x["stats"]["HitChance"],
                         "AvoidChance": x["stats"]["AvoidChance"]} for x in m["monsters"]]
            r["clear_condition_1_14"] = m["clearConditions"]
        r["monsters_global_1_14"] = msi_list
        if k:
            r.update(meta("MII_GROWTH", "verified_client_table",
                          "KR 1.18.0 values (base × stage multiplier). monsters_global_1_14 = MSI 1.14 snapshot (adds names and HitChance = monster accuracy vs player evasion)."))
        elif st <= ANNOUNCED_MAX:
            r.update(meta("NX_PREVIEW_1126", "announced_not_live", "Stage announced for the 11/26 update (growth dungeons to 160); no data yet."))
        mon.append(r)
write_dataset("growth_dungeon_monsters", "Growth dungeon monster stats per stage, 5 dungeons (KR 1.18.0 stages 1-150; global 1.14 cross-check 1-140; 151-160 announced)",
              mon, 5 * ANNOUNCED_MAX, "750/750 live stage rows with KR 1.18.0 monster stats; 700 also carry global 1.14 monster names/HitChance; 50 announced rows empty.")
COV["growth_dungeon_monsters"] = (750, 800)

# ------------------------------------------------------------------ enhancement scroll odds (KR 1.18.0)
gh = open(RAW + "/growth.html", encoding="utf-8").read()
txt = html.unescape(re.sub(r"\s+", " ", re.sub(r"<[^>]+>", " ", re.sub(r"<script.*?</script>|<style.*?</style>", "", gh, flags=re.S))))
seg = txt[txt.find("강화 주문서 드랍률"):txt.find("브루스 이벤트 주문서")]
SCROLLS = ["노말 강화 주문서 40%", "레어 강화 주문서 40%", "레어 강화 주문서 25%", "에픽 강화 주문서 70%", "에픽 강화 주문서 30%", "에픽 강화 주문서 15%"]
odds = []
for m in re.finditer(r"(\d+)(?:~(\d+))? ((?:(?:[\d.]+%|-) ){5}(?:[\d.]+%|-))", seg + " "):
    lo, hi = int(m.group(1)), int(m.group(2) or m.group(1))
    vals = [None if v == "-" else float(v.rstrip("%")) for v in m.group(3).split()]
    odds.append((lo, hi, vals))
assert len(odds) == 16, odds


def odds_for(st):
    for lo, hi, v in odds:
        if lo <= st <= hi:
            return v
    if st == 1:
        return odds[0][2]
    return None


# ------------------------------------------------------------------ reward datasets
lv = json.load(open(RAW + "/level-experience-117.json"))
expsweep = {r["level"]: int(r["expPerSweep"]) for r in lv["experienceDungeon"]}
ht = json.load(open(RAW + "/msi-hero-token-calculator.json"))
hero = {r["stage"]: r for r in ht["heroTrainingRewards"]["clearRewardByStage"]}
pw = json.load(open(RAW + "/playwright_calculator_outputs.json"))
pw_exp = {r["stage"]: int(r["exact"].split()[0].replace(",", "")) for r in pw["exp"]}
pw_hero = {int(r["stage"]): int(r["tokensPerRun"]) for r in pw["hero"] if "tokensPerRun" in r}


def base(d, st):
    k = KR[d].get(st)
    m = MSI[d].get(st)
    r = dict(dungeon=d, dungeon_ko=NAME_KO[d], stage=st, stage_status=("live" if st <= LIVE_MAX else "announced_11_26_preview"),
             is_hard_stage=(k["hard"] if k else (st % 10 == 0 if st <= LIVE_MAX else None)))
    return r, k, m


def monster_cols(d, k, m):
    if not k:
        return dict(monster_hp=None, monster_attack=None, monster_defense=None, monster_avoid=None, monster_hit_chance_1_14=None,
                    time_limit_sec=None, clear_kill_count=None)
    hp = k.get("hp") or k.get("boss_hp") or k.get("normal_hp") or k.get("normal1_hp")
    atk = k.get("attack") or k.get("boss_attack") or k.get("normal_attack")
    df = k.get("defence") or k.get("boss_defence") or k.get("normal_defence")
    av = k.get("avoid") or k.get("boss_avoid") or k.get("normal_avoid")
    hit = max((x["stats"]["HitChance"] for x in m["monsters"]), default=None) if m else None
    return dict(monster_hp=bigint(hp), monster_attack=bigint(atk), monster_defense=df, monster_avoid=av, monster_hit_chance_1_14=hit,
                time_limit_sec=k.get("time_sec") or k.get("base_time_sec") or k.get("total_time_sec"), clear_kill_count=k.get("kill_count"))


def common_cols(d):
    return dict(entry_key=KEY_KO[d], keys_per_entry=1, free_keys_per_day=3, key_refund_rule=REFUND[d],
                sweep_unlock="stage 50 cleared in all growth dungeons (KR 8/13); sweep uses the same keys and gives the same rewards",
                unlock_guide_quest=UNLOCK_GQ[d], event_only_rewards=None)


def finish(r, sid, status, notes, **kw):
    r.update(meta(sid, status, notes, **kw))
    return r


# weapon / equipment: rewards unknown
for d, fields, name, desc in [
    ("weapon", ["weapon_summon_tickets", "weapon_enhancers"], "weapon_dungeon_rewards", "무기 던전: 무기 소환권 / 무기 강화석 per stage"),
    ("equipment", ["elite_monster_summon_points"], "equipment_dungeon_rewards", "장비 던전: 엘리트 몬스터 소환 포인트 per stage")]:
    out = []
    for st in range(1, ANNOUNCED_MAX + 1):
        r, k, m = base(d, st)
        for phase in ["first_clear", "repeat_clear", "sweep"]:
            for f in fields:
                r[f"{phase}_{f}"] = None
        r.update(dict(reward_type="unknown (guaranteed vs probabilistic not published)", drop_rate_percent=None))
        r.update(common_cols(d))
        r.update(monster_cols(d, k, m))
        st_ = "not_found" if st <= LIVE_MAX else "announced_not_live"
        finish(r, "MII_GROWTH" if k else "NX_PREVIEW_1126", st_,
               "Reward amounts not published: MSI 1.14 exports have rewardIndex=null for this dungeon; mapleidleindex shows monsters only; no wiki/notice table. "
               "Monster columns are KR 1.18.0. Unverified lead (namu.wiki search snippet): weapon dungeon gives up to 50 weapon summon tickets per clear and slowly "
               "rising enhancers - NOT used as data." if d == "weapon" else
               "Reward amounts not published (same access paths as weapon dungeon). Monster columns are KR 1.18.0.")
        out.append(r)
    write_dataset(name, desc, out, ANNOUNCED_MAX, "Rewards 0/150 live stages (all null). Monster/stage data 150/150.")
    COV[name] = (0, 150)

# exp
out = []
for st in range(1, ANNOUNCED_MAX + 1):
    r, k, m = base("exp", st)
    v = expsweep.get(st)
    r.update(dict(first_clear_exp=None, repeat_clear_exp=bigint(v), sweep_exp=bigint(v), reward_type="guaranteed (fixed per stage)" if v else None,
                  exp_bonus_percent_applies=False if v else None, playwright_calculator_value=bigint(pw_exp.get(st))))
    r.update(common_cols("exp"))
    r.update(monster_cols("exp", k, m))
    if v:
        finish(r, "MII_LEVEL_EXP", "verified_client_table",
               "sweep_exp = client experienceDungeon row (fixed per stage; EXP% bonuses do not apply). repeat_clear_exp set equal because the official 8/13 KR patch note "
               "states sweeps give the same rewards as clears. first_clear_exp: unknown whether a separate first-clear reward exists.")
    else:
        finish(r, "NX_PREVIEW_1126", "announced_not_live", "Stage announced for 11/26; no data.")
    out.append(r)
write_dataset("experience_dungeon_rewards", "경험치 던전: character EXP per stage (KR 1.18.0)", out, ANNOUNCED_MAX,
              "Sweep/repeat EXP 150/150 live stages; first-clear 0/150 (unknown if it exists). Playwright check of stages 1,50,100,140,150 matched.")
COV["experience_dungeon_rewards"] = (150, 150)

# hero training
out = []
for st in range(1, ANNOUNCED_MAX + 1):
    r, k, m = base("hero_training", st)
    h = hero.get(st)
    r.update(dict(first_clear_hero_tokens=h["firstClearTokens"] if h else None, first_clear_reward_index=h["firstRewardIndex"] if h else None,
                  repeat_clear_hero_tokens=h["clearTokens"] if h else None, clear_reward_index=h["clearRewardIndex"] if h else None,
                  sweep_hero_tokens=h["clearTokens"] if h else None, reward_type="guaranteed (fixed per stage)" if h else None,
                  playwright_calculator_value=pw_hero.get(st)))
    r.update(common_cols("hero_training"))
    r["free_keys_per_day"] = 3
    r["key_max_carry"] = ht["dailyKeys"]["maxCarry"]
    r["key_add_reset_count"] = ht["dailyKeys"]["addResetCount"]
    r.update(monster_cols("hero_training", k, m))
    if h:
        finish(r, "MSI_HERO_TOKEN", "verified_client_table",
               "Global client 1.14.0: clear = 240 + 10 × stage (DungeonTable → RewardTable UPGRADE_HEROPOWER). First-clear tokens only on stages divisible by 10 "
               "(1200 + 50 × stage); other first-clear rows exist (reward index) but contain 0 Hero Tokens (other items not exported). Sweep = clear (KR 8/13 rule). "
               "KR values not separately published.", region="global")
    elif st <= LIVE_MAX:
        finish(r, "MII_GROWTH", "not_found", "KR stages 141-150 exist (monsters known) but the 1.14 reward table stops at 140; values not published "
               "(formula extrapolation in estimates.json only).")
    else:
        finish(r, "NX_PREVIEW_1126", "announced_not_live", "Announced for 11/26.")
    out.append(r)
write_dataset("hero_training_rewards", "용사의 수련장: 용사의 증표 per stage (first clear / repeat / sweep)", out, ANNOUNCED_MAX,
              "140/150 live stages (global 1.14 table); 141-150 null; 151-160 announced.")
COV["hero_training_rewards"] = (140, 150)

# enhancement
out = []
for st in range(1, ANNOUNCED_MAX + 1):
    r, k, m = base("enhancement", st)
    o = odds_for(st) if st <= LIVE_MAX else None
    r.update(dict(first_clear_spell_traces=None, repeat_clear_spell_traces=None, sweep_spell_traces=None))
    for i, s in enumerate(SCROLLS):
        key = "scroll_drop_pct_" + ["normal40", "rare40", "rare25", "epic70", "epic30", "epic15"][i]
        r[key] = (o[i] if o and o[i] is not None else (0.0 if o else None))
    r["scroll_drop_pct_total"] = round(sum(x for x in o if x), 4) if o else None
    r["scroll_quantity_per_drop"] = None
    r["reward_type"] = "spell traces: unknown; scrolls: probabilistic per clear (one random enhancement scroll in 10% of clears)" if o else None
    r.update(common_cols("enhancement"))
    r.update(monster_cols("enhancement", k, m))
    if o:
        finish(r, "MII_GROWTH", "verified_client_table",
               "Scroll odds per clear from mapleidleindex (client 1.18.0) by 10-stage bracket; '-' in source stored as 0.0 (= no chance). Excludes Bruce event scrolls and "
               "Zakum/Horntail scrolls. 주문의 흔적 amounts not published (null).")
    else:
        finish(r, "NX_PREVIEW_1126", "announced_not_live", "Announced for 11/26.")
    out.append(r)
write_dataset("enhancement_dungeon_rewards", "강화 던전: 주문의 흔적 + 강화 주문서 odds per stage", out, ANNOUNCED_MAX,
              "Scroll odds 150/150 live stages; spell-trace amounts 0/150.")
COV["enhancement_dungeon_rewards"] = (150, 300)

# ------------------------------------------------------------------ stage caps & rules
caps = [("2025-11-06", 70, "WIKI_WEAPON_DG", "launch cap (global wiki still shows 70/90)"), ("2025-11-14", 90, "NX_PN_1114", ""), ("2025-12-05", 100, "NX_PN_1205", ""),
        ("2026-01-08", 110, "NX_PN_0108", ""), ("2026-04-09", 120, "NX_PN_0409", ""), ("2026-06-11", 130, "NX_PN_0611", ""),
        ("2026-07-02", 140, "NX_PN_0702", ""), ("2026-09-03", 150, "NX_PN_0903", "141~150단계 추가"), ("2026-11-26", 160, "NX_PREVIEW_1126", "preview, not live on 2026-11-24")]
cap_recs = []
for date, cap, sid, n in caps:
    r = dict(effective_date=date, max_stage_all_growth_dungeons=cap, dungeon_types=5)
    r.update(meta(sid, "official_kr_notice" if sid.startswith("NX") else "wiki_global", n))
    cap_recs.append(r)
write_dataset("growth_dungeon_stage_caps", "Growth dungeon stage-cap history (KR)", cap_recs, None, "9 changes; dungeon types unchanged (5).")

rules = []
def rule(name, value, sid, status, notes=""):
    r = dict(rule=name, value=value); r.update(meta(sid, status, notes)); rules.append(r)
rule("free_keys_per_day", "3 per dungeon per day (reset 0시)", "WIKI_GROWTH", "wiki_global")
rule("hero_training_keys", ht["dailyKeys"], "MSI_HERO_TOKEN", "verified_client_table", "StaminaTable TICKET_DUNGEON_HEROPOWER: default 3, addResetCount 3, maxCarry 10, Daily.")
rule("sweep", "일괄 소탕: unlock after clearing stage 50 in all growth dungeons; consumes the same keys; rewards identical to a clear", "NX_PN_0813", "official_kr_notice")
rule("hard_stages", "every 10th stage is IsHard (특수 단계)", "MII_GROWTH", "verified_client_table")
rule("clear_conditions", {"weapon": "kill 머쉬맘 in 22 s", "exp": "20+ kills, 22 s base, +4 s per 시간연장몹", "equipment": "75-120 kills in 30-40 s",
                          "hero_training": "30 s hunt (+2% ATK/kill, max 100 stacks) then boss within 20 s (50 s total)", "enhancement": "kill 발록 in 25 s"},
     "MII_GROWTH", "verified_client_table")
rule("unlock_guide_quest", UNLOCK_GQ, "WIKI_GQ", "wiki_global", "Hero Training ties to 용사의 힘 (GQ 79).")
rule("stage_medals", "Main Stat +30 each: clear stage 50 / 70 / 100 of all growth dungeons (global wiki), 125 / 150 (KR 9/22 '125층 용사', '150층 용사')",
     "NX_PN_0922", "official_kr_notice", "50/70/100 from WIKI_MEDALS.")
rule("event_keys", "성장 던전 15일 출석 이벤트 gives keys for all 5 dungeons (8/13 and again with 11/26 update)", "NX_PN_0813", "official_kr_notice", "Event-only; not part of normal rewards.")
rule("challenge_grade_buffs", "신규 용사 성장 챌린지 grades add +1 free daily recharge per dungeon (브론즈: 무기, 마스터1: 경험치, 그랜드마스터4: 장비, 그랜드마스터2: 강화, 챌린저5: 용사의 힘)",
     "NX_PN_1105", "official_kr_notice", "Event-only (2026-11-05 ~ 12-16).")
write_dataset("growth_dungeon_rules", "Growth dungeon entry/key/sweep/medal rules", rules, None, f"{len(rules)} rules.")
json.dump(COV, open(SCRATCH + "/mdb/cov_dungeons.json", "w"))
print("dungeons ok", COV, len(odds))

# SOURCES_DUMP
from common import SOURCES as _S
json.dump(_S, open(SCRATCH + "/mdb/sources_build_dungeons.json", "w"), ensure_ascii=False)
