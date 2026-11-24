import json, sys, re
sys.path.insert(0, "/tmp/claude-0/-home-user-BIG-STORY-IDLE-RPG/f4db4718-c3e8-5335-9264-6dbe1627a364/scratchpad/mdb/scripts")
from common import *
import sources_reg  # noqa

COV = {}
OFF = "official_kr_notice"

# ======================================================================= companion ticket sources (free only)
ct = []


def tk(name, category, amount, frequency, condition, sid, status, period=None, choice=False, unit="동료 소환권", notes=""):
    r = dict(source_name=name, category=category, companion_tickets=amount, ticket_type=unit, frequency=frequency, condition=condition,
             event_period=period, mutually_exclusive_choice=choice, is_paid=False)
    r.update(meta(sid, status, notes))
    ct.append(r)


for day, amt in [(2, 40), (9, 60), (16, 80), (23, 120)]:
    tk(f"월간 출석 {day}일차", "permanent_monthly", amt, "monthly (28-day calendar)", "일일 미션 8개 클리어 후 출석 수령; 챕터 3-2 해금", "NX_MONTHLY_ATT", OFF,
       notes="300 per month total. Missed-day buy-back (블루 다이아) and membership double attendance are paid and excluded.")
tk("상점: 동료 소환권 30개 (레드 다이아 750)", "permanent_weekly_shop", 30, "weekly ×1", "챕터 6-10 클리어; costs 750 레드 다이아 (free-earnable currency)", "MII_HOTDEAL",
   "verified_client_table", notes="Red diamonds are earned free (missions, battle pass, hunting) but can also be bought 1:1 with blue diamonds.")
tk("광고 시청 동료 소환 10회", "permanent_daily_ad", 10, "daily ×1", "watch 1 ad (Ad Removal membership skips the ad)", "WIKI_ADREM", "wiki_global",
   unit="free companion summons (not tickets)")
tk("특별 의뢰: Mrs. Ming Ming's Request (동료 소환 Lv3)", "one_time_quest", 30, "once", "Clear Chapter 4", "WIKI_QUESTS", "wiki_global")
tk("가이드 퀘스트 보상", "one_time_quest", None, "once per quest", "various guide quests", "WIKI_COMP_TICKET", "wiki_global",
   notes="Wiki: tickets are 'rewarded when completing Guide Quests and in the Battle Pass'; amounts not published.")
tk("동료 소환 레벨 달성 보상", "one_time_level_reward", None, "once per summon level", "reach companion summon Lv2..13", "WIKI_SUMMON_COMP", "wiki_global",
   notes="Wiki Summon: 'Tickets are rewarded once a level is reached' (tap item next to Summoning Level UI). Amounts not published.")
tk("14일 특별 미션 2일차 5개 완료 보너스", "newcomer_once", 60, "once", "신규 캐릭터 14일 미션 (2025-11 launch event)", "DC48415", "community_reported")
tk("14일 특별 미션 9일차 5개 완료 보너스", "newcomer_once", 80, "once", "신규 캐릭터 14일 미션", "DC48415", "community_reported")
for lvl, amt, sid, per in [(38, 100, "NX_NEWCHAR1_1105", "2026-11-05~2027-01-06"), (58, 200, "NX_NEWCHAR1_1105", "2026-11-05~2027-01-06"),
                           (76, 300, "NX_NEWCHAR2_1105", "2026-11-05~2027-01-06"), (36, 50, "NX_NEWCHAR_0129", "2026-01-29~"), (51, 100, "NX_NEWCHAR_0129", "2026-01-29~"),
                           (38, 50, "NX_NEWCHAR_0430", "2026-04-30~07-01"), (58, 100, "NX_NEWCHAR_0430", "2026-04-30~07-01")]:
    tk(f"신규 캐릭터 성장 이벤트 Lv{lvl} (무료 보상)", "event_new_character", amt, "once", f"reach Lv{lvl}; characters created during the event", sid, OFF, per,
       notes="Free track only; paid tracks excluded.")
for stg, amt in [(3, 100), (6, 100), (9, 100), (12, 200), (15, 200), (17, 200)]:
    tk(f"신규 용사 성장 챌린지 보스 {stg}단계 클리어", "event", amt, "once", "마왕 발록 challenge boss stage clear", "NX_CHALLENGE_1105", OFF, "2026-11-05~12-16")
for sid, per in [("NX_DMB_1119", "2026-11-05~11-19"), ("NX_DMB_0722", "2026-07-08~07-22"), ("NX_DMB_HALF", "2026-05-06~05-20")]:
    tk("일일 미션 부스트: 일일 미션 누적 10회", "event_daily_mission_boost", 100, "once per event", "complete 10 daily missions during the event", sid, OFF, per)
for stg, amt in [(1, 120), (7, 300), (16, 400), (19, 600)]:
    tk(f"1주년 메키 살롱 포인트 보상 {stg}단계 (보상 2)", "event_choice", amt, "once", "1주년 포인트 달성; choose reward 1 (무기 소환권) OR reward 2 (동료 소환권)",
       "NX_ANNIV_POINTS", OFF, "2026-11-05~12-16", True)
tk("1주년 상점: 동료 소환권 200개", "event_shop", 200, "11/19~11/25 rotation", "1주년 회중시계 5,000개 (earned from event missions)", "NX_ANNIV_SHOP", OFF, "2026-11-19~11-25")
tk("1주년 메키 살롱 스페셜 상점: 레전드리 동료 소환권", "event_shop", 1, "once per character", "1주년 스페셜 코인 1개; 동료 소환 10레벨 달성", "NX_ANNIV_SPECIAL_SHOP", OFF,
   "2026-11-05~12-18", unit="레전드리 동료 소환권")
for code, amt, sid, per in [("THANKU", 200, "NX_COUPON_1D", "2025-11-18~12-17"), ("WINTERGIFT", 300, "NX_XMAS_COUPON", "2025-12-24~2026-01-14"),
                            ("MI100DAYS", 500, "NX_100DAYS", "2026-02-13~03-01"), ("HALFANNIV", 500, "NX_HALF_COUPON", "2026-04-30~05-20"),
                            ("MAPLEFESTA", 300, "NX_HALF_COUPON2", "2026-05-07~05-27"), ("GIFT300", 300, "NX_GIFT300", "2026-07-23~09-02"),
                            ("PINKBEANATTACK", 300, "NX_PINKBEAN_COUPON", "2026-09-03~10-14"), ("30LVCOUPON", 300, "NX_ANNIV_COUPON2", "2026-11-06~ (until notice)")]:
    tk(f"쿠폰 {code}", "coupon", amt, "once per account/character", "coupon redemption" + (" (Lv30+)" if code == "30LVCOUPON" else ""), sid, OFF, per)
tk("한가위 풍성한 출석 누적 2일", "event_attendance", 1000, "once", "event attendance day 2", "NX_HANGAWI", OFF, "2026-09-22~09-29")
for d_, amt in [(5, 150), (10, 200), (15, 250)]:
    tk(f"15일간 쑥쑥! 봄날의 성장 {d_}일차", "event_attendance", amt, "once", f"attendance day {d_}", "NX_SPRING", OFF, "2026-02-26~03-18")
tk("신비한 10월: 일일 접속 보상 24회 수령", "event_attendance", 200, "once", "claim daily login reward 24 times", "NX_OCT", OFF, "2026-10-15~11-04")
tk("슈가의 단풍잎 상점: 동료 소환권 300개", "event_shop", 300, "weekly ×2", "단풍잎 1,200개", "NX_LEAF_SHOP", OFF, "2025-11-26~")
tk("크리스마스 상점: 동료 소환권 300개", "event_shop", 300, "per listing", "크리스마스 양말 9,000개", "NX_XMAS_SHOP", OFF, "2025-12-18~12-31")
tk("설맞이 이벤트 광고 보상", "event_ad", 50, "daily ×2", "watch ad in event", "NX_SEOL", OFF, "2026-01-29~")
tk("유물 발굴 대작전 교환: 동료 소환권 300개", "event_shop", 300, "per exchange limit", "유물 발굴 증서 6,000개", "NX_RELIC_DIG", OFF, "2026-08-13~09-02")
tk("유물 발굴 대작전 교환: 동료 소환권 2개", "event_shop", 2, "per exchange limit", "유물 발굴 증서 100개", "NX_RELIC_DIG", OFF, "2026-08-13~09-02")
tk("반주년 메키 페스티벌 포인트 보상 (24,500 포인트)", "event", 200, "once", "festival points threshold (table layout: threshold precedes item)", "NX_HALF_POINTS", OFF, "2026-04-30~05-20")
tk("반주년 메키 페스티벌 포인트 보상 (39,000 포인트)", "event", 200, "once", "festival points threshold", "NX_HALF_POINTS", OFF, "2026-04-30~05-20")
tk("반주년 스탬프 미션 스탬프 보상", "event_random", 100, "1 obtainable", "stamp reward pool (probabilistic draw)", "NX_HALF_STAMP", OFF, "2026-05-21~06-10")
tk("핑크빈 교환소", "event_shop", None, "unknown", "핑크빈 코인 exchange (amount not stated in patch note)", "NX_PN_0903", OFF, "2026-09-03~10-14")
tk("배틀 패스 부스트 오류 사과 보상", "compensation", 1000, "once", "affected accounts", "NX_BP_APOLOGY", OFF, "2026-03")
COV["companion_ticket_sources"] = (sum(1 for r in ct if r["companion_tickets"] is not None), len(ct))
write_dataset("companion_ticket_sources", "Free (non-paid) sources of 동료 소환권 / free companion summons (KR unless noted)", ct, None,
              f"{len(ct)} sources, {COV['companion_ticket_sources'][0]} with amounts. Permanent free: monthly attendance 300/mo, red-diamond shop 30/wk, ad 10 summons/day. "
              "3차/4차 전직 동료 소환권: no free source found (paid hotdeals/pass only).")

# ======================================================================= missions
ms = []


def mi(group, mtype, name, condition, count, reward, sid, status, period=None, notes="", **kw):
    r = dict(mission_group=group, mission_type=mtype, mission=name, condition=condition, required_count=count, reward=reward, event_period=period)
    r.update(kw)
    r.update(meta(sid, status, notes))
    ms.append(r)


mi("일일 미션 (permanent)", "daily_header", "일일 미션 클리어 (0/8)", "complete 8 daily missions", 8, "무기 소환권 100 + 레드 다이아 5,000",
   "NX_DMB_1119", OFF, notes="Same values in Jan/May/Jul/Nov 2026 boost notices (normal value shown as '기존'). Also triggers 월간 출석.")
mi("일일 미션 (permanent)", "daily_individual", "individual permanent daily missions (8+)", None, None, None, "REPO_INCOME", "not_found",
   notes="Conditions/counts/rewards not published in any text source (only in-game). Community: condition types 성장 던전 클리어, 몬스터 처치, 엘리트 몬스터 소환, 무기 소환 등 "
         "(IV114); rewards 무기 소환권/레드 다이아; red-diamond total 7,400/day (MEKI_RD, IV731) ⇒ individual missions ≈ 2,400 red/day (derived).")
mi("일일 미션 (permanent)", "daily_individual", "길드 건물 업그레이드 하기", "guild members; added 2026-11-05", 1, None, "NX_PN_1105", OFF, notes="Reward not stated.")
mi("주간 미션 (permanent)", "weekly_stages", "weekly mission stages", "progress from daily missions; reset Monday 0시", None,
   "total 레드 다이아 15,500/week; one stage gives 무기 소환권 500", "REPO_INCOME", "community_reported",
   notes="Stage count/thresholds unknown. Sources: MEKI_RD, IV731 (15,500), DC435362 (500 tickets).")
# daily mission boost cumulative tables
for sid, per, rows, mult in [
        ("NX_DMB_1119", "2026-11-05~11-19", [(10, "동료 소환권 100"), (30, "무기 소환권 250"), (50, "주문의 흔적 3,000"), (70, "스타포스 강화 주문서 20")], "×2 (무기 소환권 200 + 레드 다이아 10,000)"),
        ("NX_DMB_0722", "2026-07-08~07-22", [(10, "동료 소환권 100"), (30, "무기 소환권 250"), (50, "주문의 흔적 3,000"), (70, "스타포스 강화 주문서 20")], "×2")]:
    for n, rw in rows:
        mi("일일 미션 부스트 (event)", "cumulative", f"일일 미션 누적 {n}회 달성", "cumulative daily missions during event (header mission excluded)", n, rw, sid, OFF, per)
    mi("일일 미션 부스트 (event)", "header_multiplier", "일일 미션 클리어 보상 배수", None, None, mult, sid, OFF, per)

# generic parser for event mission tables
EVENTS = [("NX_ANNIV_MISSION", 6697, 3575652, "2026-11-05~12-16"), ("NX_CHALLENGE_1105", 6697, 3574351, "2026-11-05~12-16"),
          ("NX_RING_WORKSHOP", 6697, 3574350, "2026-11-05~12-16"), ("NX_RELIC_DIG", 7418, 3521780, "2026-08-13~09-02")]
extra = [(6697, 3339448), (6697, 3403558), (6697, 3448873), (6697, 3505292), (7418, 3549925)]
for b, t in extra:
    txt = forum_text(b, t)
    title = txt.split("\n")[0].replace("TITLE: ", "")
    date = txt.split("\n")[1].replace("DATE: ", "")
    sid = f"NX_EVT_{t}"
    from common import fkr
    fkr(sid, b, t, title, date)
    EVENTS.append((sid, b, t, date + "~"))
ach = []
for sid, b, t, per in EVENTS:
    txt = forum_text(b, t)
    title = txt.split("\n")[0].replace("TITLE: ", "")
    section = ""
    lines = txt.split("\n")
    for li, line in enumerate(lines):
        s = line.strip()
        if s.startswith("📌") or s.startswith("▪️"):
            section = s.strip("📌▪️ ").strip()
            continue
        if not s.startswith("|"):
            continue
        cells = [c.strip() for c in s.split("|") if c.strip()]
        if len(cells) == 1 and re.search(r"\[(일일|업적|반복|주간)\]", s) and li + 1 < len(lines) and lines[li + 1].strip().startswith("|"):
            cells += [c.strip() for c in lines[li + 1].split("|") if c.strip()][:1]
        if len(cells) < 2 or cells[-1] in ("보상", "보상 2") or cells[0] in ("미션", "구분", "누적 조건", "조건", "단계", "달성 단계", "누적 달성 횟수"):
            continue
        if not any(k in section for k in ("미션", "클리어 보상", "누적 보상", "달성 보상")) and not re.search(r"\[(일일|업적|반복|주간)\]", s):
            continue
        name = next((c for c in cells if re.search(r"\[(일일|업적|반복|주간)\]", c)), cells[-2] if len(cells) >= 2 else cells[0])
        tag = re.search(r"\[(일일|업적|반복|주간)\]", name)
        mtype = {"일일": "event_daily", "업적": "achievement", "반복": "repeatable", "주간": "event_weekly"}[tag.group(1)] if tag else \
            ("achievement" if "업적" in section else "cumulative" if "누적" in section else "stage_or_threshold")
        cnt = None
        if len(cells) == 3 and re.fullmatch(r"[\d,]+", cells[1]):
            cnt = int(cells[1].replace(",", ""))
        rec = dict(group=title, mtype=mtype, name=name, reward=cells[-1], count=cnt, section=section)
        if mtype == "achievement":
            r = dict(achievement=name, reward=cells[-1], scope=f"event: {title}", permanent=False, event_period=per, section=section)
            r.update(meta(sid, OFF, "Event-scoped achievement ([업적]) - one claim per character unless [반복]."))
            ach.append(r)
        mi(title, mtype, name, section, cnt, cells[-1], sid, OFF, per)
# 14-day special mission (newcomer, 2025-11) from earlier repo research table
inc = open(SCRATCH + "/spec/research-income.md", encoding="utf-8").read()
blk = inc[inc.find("### 3.5 14일 특별 미션"):inc.find("### 3.6")]
for line in blk.split("\n"):
    m = re.match(r"^\| (\d+) \| (.+?) \| (.+?) \|$", line)
    if m:
        day = int(m.group(1))
        for x in [s.strip() for s in m.group(2).replace("획득·장착", "획득+장착").split("·")]:
            mi("14일 특별 미션 (newcomer, KR 2025-11)", "newcomer_daily", x, f"day {day}", None, "무기 소환권 10", "DC48415", "community_reported", "2025-11~",
               day=day, notes="Each mission gives 무기 소환권 10 (DC48415/MEKI_14D). 79 completions -> 유니크 동료.")
        mi("14일 특별 미션 (newcomer, KR 2025-11)", "newcomer_daily_bonus", f"day {day}: 5개 완료", f"day {day}", 5, m.group(3).strip(), "DC48415", "community_reported", "2025-11~", day=day)
mi("7일 특별 미션 (KR 2026-01-08~)", "newcomer_totals", "all missions (totals only)", "20 days after open", None,
   "레드 다이아 6,300 · 무기 소환권 600 · 엘리트 소환 포인트 2,000 · 용사의 증표 2,000 · 명예의 훈장 2,500 · 주문의 흔적 2,500 · 미라클 큐브 5; final 무기 소환권 2,000",
   "NX_7DAY", OFF, notes="Per-mission rows not published.")
# monthly attendance
att = {1: "무기 소환권 100", 2: "동료 소환권 40", 3: "성장던전 입장권: 경험치 3", 4: "주문의 흔적 2,000", 5: "버닝 필드 부스터 2", 6: "엘리트 몬스터 소환 포인트 1,000",
       7: "명예의 훈장 20,000", 8: "무기 소환권 150", 9: "동료 소환권 60", 10: "탐험 티켓 3", 11: "주문의 흔적 3,000", 12: "버닝 필드 부스터 3",
       13: "엘리트 몬스터 소환 포인트 1,500", 14: "미라클 큐브 30", 15: "무기 소환권 200", 16: "동료 소환권 80", 17: "보스 레이드 입장권 3", 18: "주문의 흔적 4,000",
       19: "버닝 필드 부스터 4", 20: "엘리트 몬스터 소환 포인트 2,000", 21: "스타포스 강화 주문서 60", 22: "무기 소환권 300", 23: "동료 소환권 120",
       24: "메모리얼 스크롤 20", 25: "스타포스 강화 주문서 10", 26: "미라클 큐브 5", 27: "유물 상자 4", 28: "레전드리 유물 소환 1"}
for d_, rw in att.items():
    mi("월간 출석 (permanent)", "attendance", f"{d_}일차", "after 일일 미션 클리어 (0/8)", d_, rw, "NX_MONTHLY_ATT", OFF, day=d_,
       notes="Values from earlier repo research of this notice (research-income.md §3.4).")
# daily battle pass
for kills, amt in [(500, 100), (1000, 100), (1500, 100), (2200, 100), (2900, 100), (3600, 100), (4300, 100), (5000, 800)]:
    mi("데일리 배틀 패스 (permanent, free track)", "daily_kill_track", f"몬스터 {kills:,} 처치", "monsters killed today", kills, f"레드 다이아 {amt}",
       "REPO_INCOME", "official_kr_notice_via_repo", notes="From research-income.md §3.3 (NX_BP_1014/NX_BP_0722). Premium track (paid) excluded.")
COV["missions"] = (sum(1 for r in ms if r["verification_status"] != "not_found"), len(ms))
write_dataset("missions", "Daily/weekly/event missions, attendance and battle pass with rewards", ms, None,
              f"{len(ms)} mission rows. Permanent daily missions: only the 8-mission header + 1 added mission known; weekly stages unknown.")

# achievements
r = dict(achievement="permanent achievement list ([업적] menu)", reward=None, scope="permanent", permanent=True, event_period=None, section=None)
r.update(meta("REPO_INCOME", "not_found", "No permanent achievement list in any text source; only event-scoped [업적] missions are published (below). "
              "Hotdeals reference '[업적] 동료 소환하기' / '[업적] 아레나 플레이하기' inside events."))
ach.insert(0, r)
write_dataset("achievements", "Achievements ([업적]): event-scoped lists with rewards; permanent list not found", ach, None, f"{len(ach) - 1} event achievements.")
COV["achievements"] = (len(ach) - 1, None)

# ======================================================================= guide quests
gq = []
for n, content in [(7, "1차 전직 (Lv5)"), (8, "스킬"), (13, "무기"), (25, "스킬 강화"), (33, "스킬 마스터리"), (34, "무기 던전 / 성장 던전"), (45, "경험치 던전"),
                   (48, "특별 의뢰: 엘리트 몬스터 5회 소환 (global)"), (56, "특별 의뢰: 헤네시스 보스 (global)"), (58, "월드 보스"), (59, "특별 의뢰: 월드 보스 1단계 (global)"),
                   (67, "장비 던전"), (71, "닉네임 변경"), (75, "빠른 사냥"), (79, "용사의 힘"), (89, "부스터"), (96, "동료"), (113, "어빌리티"),
                   (131, "강화 던전 / 장비 슬롯 강화"), (140, "길드"), (147, "특별 의뢰: 주문서 사용 (global)"), (239, "스타포스"), (247, "아레나"), (347, "유물")]:
    r = dict(guide_quest_no=n, unlocks=content, condition=None, reward=None)
    r.update(meta("WIKI_GQ", "wiki_global", "Unlock number from global wiki Guide Quest table (KR order reproduced by IV398). Reward per quest NOT published "
                  "(wiki: rewards include weapon/companion tickets)."))
    gq.append(r)
write_dataset("guide_quests", "Guide quest numbers that unlock content; per-quest rewards not published", gq, None,
              f"{len(gq)} unlock rows; rewards 0/{len(gq)}. Quest cycle types: map breakthrough, kill N, elite summon, weapon/companion summon, world boss, quick hunt, dungeons, arena, summon levels.")
COV["guide_quests"] = (0, len(gq))

# ======================================================================= summon level rewards
sl = json.load(open(RAW + "/mii/summon-levels.json"))
hd = json.load(open(RAW + "/mii/hotdeal-catalog.json"))
slr = []
for typ in ["weapon", "companion", "ability"]:
    t = sl["types"][typ]
    cum = 0
    for s in t["steps"]:
        cum += s["requiredCount"]
        r = dict(summon_type=typ, from_level=s["fromLevel"], to_level=s["toLevel"], required_count=s["requiredCount"], cumulative_required=cum,
                 count_unit=t["metricLabel"], level_up_free_reward=None, is_paid=False)
        r.update(meta("MII_SUMMON_LEVELS", "verified_client_table",
                      "Requirement verified (GachaLevelTable). Free level-up reward exists per wiki ('Tickets are rewarded once a level is reached') but amounts are "
                      "not in any reachable source -> null."))
        slr.append(r)
for d in hd["deals"]:
    nm = d["name"]["ko"]
    if "소환 레벨 핫딜" in nm:
        p = d.get("payment", {})
        r = dict(summon_type="companion" if "동료" in nm else "weapon", from_level=None, to_level=None, required_count=None, cumulative_required=None,
                 count_unit=None, level_up_free_reward=None, is_paid=True, deal=nm, unlock=d.get("unlock", {}).get("ko"),
                 price=f'{p.get("currency")} {p.get("amount")}', items=[(i["name"]["ko"], i["quantity"]) for i in d["items"]])
        r.update(meta("MII_HOTDEAL", "verified_client_table", "PAID hot deal unlocked by summon level (listed for completeness, not a free reward)."))
        slr.append(r)
write_dataset("summon_level_rewards", "Summon levels (weapon 1-19, companion 1-13, ability 1-20): requirements, free level rewards (unknown), paid level hotdeals",
              slr, None, "Requirements 49/49 steps; free level-up reward amounts 0/49 (null).")
COV["summon_level_rewards"] = (0, sum(1 for r in slr if not r["is_paid"]))

# ======================================================================= special requests (global wiki table)
q = open(RAW + "/wiki/Quests.wiki", encoding="utf-8").read()
sr = []
for blk in q.split("|-")[1:]:
    cells = [c.strip() for c in re.split(r"\n\|\s*", "\n" + blk.strip()) if c.strip()]
    cells = [re.sub(r"<!--.*?-->", "", c).strip() for c in cells]
    cells = [c for c in cells if c and not c.startswith("|}")]
    if len(cells) >= 4:
        clean = [re.sub(r"\[\[(?:[^|\]]*\|)?([^\]]*)\]\]", r"\1", c).replace("|}", "").strip() for c in cells[:4]]
        r = dict(quest=clean[0], description=clean[1], unlock=clean[2], reward=clean[3])
        r.update(meta("WIKI_QUESTS", "wiki_global", "Global wiki (rev 2025-11-23); KR values may differ."))
        sr.append(r)
write_dataset("special_requests", "특별 의뢰 (Special Requests / town quests) with rewards (global wiki)", sr, None, f"{len(sr)} quests.")
COV["special_requests"] = (len(sr), None)
json.dump(COV, open(SCRATCH + "/mdb/cov_missions.json", "w"))
print("missions ok", COV)

# SOURCES_DUMP
from common import SOURCES as _S
json.dump(_S, open(SCRATCH + "/mdb/sources_build_missions.json", "w"), ensure_ascii=False)
