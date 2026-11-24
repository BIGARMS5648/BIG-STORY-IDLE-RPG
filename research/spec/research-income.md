# 메이플 키우기: free income and missions (research-income.md)

Researched 2026-11-24. The machine-readable version is `spec/research-income.json`. It has the same data, a `sources` map (URL, region, date, raw file) and a per-chapter kill-drop table. Raw pages are saved under `web/research/income/`:
- `nexon/t/*.json|txt`: official KR forum threads, fetched through the forum JSON API `https://forum.nexon.com/api/v1/thread/<id>?alias=maplestoryidle-kr`.
- `nexon/list_*.json`: board indexes.
- `inven/*.html|txt`, `dc/*`, `mekifun/*`, `msi/*`, `wiki_*.html`.

Builder: `scripts_income/build_income_json.py`.

**Conventions**
- KR = Korean server or Korean source. global = MapleStory Idle RPG (EN).
- Every number has a citation key; §11 maps each key to its URL and date.
- "?" means no source gives the number. Nothing is estimated unless it is marked **(산식)**.
- 레드 다이아 is the free in-game currency (client code `FreeDia`). 블루 다이아 is paid only.
- Paid tracks are listed only so they can be marked for removal.

## 0. Reset times (KR, server time = KST)

| Reset | Time | What resets | Cite |
|---|---|---|---|
| 일간 | 매일 오전 0시 | Purchase limits, daily attendance, 일일 미션, dungeon tickets (+3 per dungeon), 데일리 배틀 패스, arena tickets (+5), world boss and arena daily settlement | NX_FAQ_RESET, NX_FAQ_RANK, NX_BP_0722, WIKI_ARENA |
| 주간 | 매주 월요일 오전 0시 | 주간 미션, weekly shop limits, boss raid tickets (2 base entries per boss + 2 shared tickets), 여정의 상자 열쇠 (5), 여정의 보물 weekly boost, 몬스터파크 tickets (2), arena and world boss weekly settlement, weekly 300h offline cap | NX_FAQ_RESET, NX_FAQ_RAID, NX_PN_0611, NX_PN_0813, NX_PN_1105 |
| 월간 | 매월 1일 오전 0시 | 월간 출석 (unclaimed rewards are lost), monthly purchase limits | NX_FAQ_RESET, NX_MONTHLY_ATT |
| 기타 | 길드 현상수배 정산: 일요일 0시. 길드 대항전 buff: until the following Monday 21:59. Guild contribution: Monday 0시 (global) | | NX_PN_1105, NX_PN_1127, WIKI_GUILDB |
| global | Server-local midnight: Scania UTC+9, Luna UTC+1, Bera UTC-8, Aria and Aquila UTC+8 | | WIKI_WORLDS |

## 1. Daily and weekly free loop at a glance (KR)

| Source | Free amount | Frequency | Cite |
|---|---|---|---|
| 일일 미션: '일일 미션 클리어 (0/8)' final reward | 무기 소환권 100 + 레드 다이아 5,000 | daily | NX_DMB_1119, NX_DMB_0722, NX_DMB_SUGAR |
| 일일 미션: individual missions (sum) | 레드 다이아 2,400 **(산식: community total 7,400 − 5,000)**. The list of individual missions is unknown | daily | MEKI_RD, IV731 |
| 데일리 배틀 패스 (free track) | 레드 다이아 1,500 (8 steps, 500 to 5,000 kills) | daily | NX_BP_1014 |
| 일반 상점 ad | 레드 다이아 1,000 | daily (→ convert to a free claim) | IV121, IV774, WIKI_ADREM |
| Weapon and companion summon ads | 무기 소환 10회, 동료 소환 10회 | daily each | WIKI_ADREM, DC435362 |
| 빠른 사냥 | 1 free + 1 ad per day (+3 for 500, 750 and 1,000 레드 다이아) | daily | IV119, IV305 |
| Ad booster | EXP +100% and 메소 +150% for 20 minutes | daily | WIKI_BOOST |
| Chapter hunting (24h auto) | ≈1,200 레드 다이아 a day (community estimate; the drop is 1% × 1 per kill) | continuous | MEKI_RD, MSI_LIB |
| Growth dungeons | 3 keys per dungeon per day (cap 10). There are 5 dungeons | daily | IV130, WIKI_GD |
| Arena | 5 tickets per day (cap 20), plus daily tier coin | daily | WIKI_ARENA, NX_PN_0922 |
| World boss | Daily tier coin | daily | NX_PN_0922 |
| 월간 출석 | 1 calendar reward per day after 8 daily missions (28 rewards) | daily | NX_MONTHLY_ATT |
| Friends | 엘리트 소환 포인트: send 10 / receive 20 per friend, max 500 a day | daily | WIKI_FRIENDS (global) |
| 여정의 상자 | Blessing reset: 1 free per day | daily | NX_PN_0611 |
| 주간 미션 (stage rewards) | 레드 다이아 15,500 + 무기 소환권 500 (only the totals are known) | weekly | MEKI_RD, IV731, DC435362 |
| Boss raid | 2 entries per boss + 2 shared tickets | weekly | NX_FAQ_RAID |
| 여정의 상자 열쇠 | 5 (cap 5) | weekly | NX_PN_0611 |
| 여정의 보물 ad boost | +20/25/30% gauge (60/30/10%) | weekly | NX_PN_0813 |
| Arena and world boss weekly tier rewards | See §6 | weekly | NX_PN_0922 |
| Guild warehouse supplies | 길드 코인 3,000 to 8,000 (+ 시간 단축 티켓) | weekly | NX_PN_1105 |
| 몬스터파크 익스트림 tickets | 2 (cap 2) | weekly | NX_PN_1105 |

**Community totals for 레드 다이아 (KR):**
- Daily: 24h hunt 1,200 + ads 1,000 + daily missions 7,400 + free battle pass 1,500 = **11,100/day**. With the paid membership pass it is 12,600.
- Weekly: quest bonus 15,500, so **93,200/week** (103,700 with membership). Source: MEKI_RD.
- Inven's 10-day count (10/26 to 11/4) is daily missions 74,000 + battle pass 15,000 + ads 10,000 + one week of weekly missions 15,500 + event 10,000. Source: IV731.

## 2. Per-currency free sources

### 2.1 레드 다이아 (free)

| Source | Amount | Frequency | Cite |
|---|---|---|---|
| Chapter-hunt kill drop | 1 per kill, 1% chance (all chapters 1-44) | per kill | MSI_LIB, WIKI_HUNT |
| 일일 미션 클리어 (8개) | 5,000 (x1.5 = 7,500 or x2 = 10,000 during boost events) | daily | NX_DMB_1119, NX_DMB_SUGAR |
| Individual daily missions | Sum 2,400 **(산식)**. Each mission's value is ? | daily | MEKI_RD, IV731 |
| 데일리 배틀 패스, free | 100 at each of 500/1,000/1,500/2,200/2,900/3,600/4,300 kills, 800 at 5,000 kills = 1,500 | daily | NX_BP_1014 |
| 데일리 배틀 패스, premium (paid membership) | Same again (+1,500). **Remove** | daily | NX_BP_1014 |
| 일반 상점 ad | 1,000 | daily | IV121 |
| 주간 미션 | 15,500 total. The stages are ? | weekly | MEKI_RD, IV731 |
| 빠른 사냥 | Included in its rewards (amount ?) | per use | IV114, IV774 |
| Special requests (global) | World Boss Stage 1 clear: 1,000. Elite summon ×5: 600. Reach Lv60: 10,000 | once | WIKI_QUESTS |
| 7일 특별 미션 (2026-01) | 6,300 total | once (event) | NX_7DAY |
| Event attendance examples | 한가위 day 5: 50,000. 1주년 전야제: day 2 5,000 and day 7 10,000 | event | NX_HANGAWI, NX_EVE |
| Guild raid first clear (server ranking) | 1st 300,000 … 10th 120,000 (top 30) | once (top guilds) | NX_PN_0611, NX_PN_1015 |
| Duplicate event costume | 3,000 | event | NX_PN_0922 |
| Sinks (context, not income) | Weapon summon 20 each. Companion summon 50 each. 빠른 사냥 500/750/1,000. Arena refresh 150. Star force restore 5,000. Skill mastery 4,500 to 10,500. Guild member skills 1,000 to 9,000 per level. Weekly shop, see §5 | | items-gacha.md, DC39138, WIKI_GUILDSKILL |

### 2.2 무기 소환권

| Source | Amount | Frequency | Cite |
|---|---|---|---|
| Chapter-hunt drop | 1 at 0.15% per kill (chapter 2+) | per kill | MSI_LIB, WIKI_HUNT |
| 무기 던전 | Amount per stage is ? | daily (3 keys) | IV130, WIKI_GD |
| 일일 미션 클리어 | 100 (150 or 200 during boosts) | daily | NX_DMB_1119 |
| 주간 미션 | 500 (one stage reward) | weekly | DC435362 |
| Weapon summon ad | 10 summons (summons, not tickets) | daily | WIKI_ADREM |
| 월간 출석 | days 1/8/15/22 = 100/150/200/300 (750 a month) | monthly | NX_MONTHLY_ATT |
| 무기 소환 패스7, free track | 10 per step, 50 every 5th step, 100 every 10th step (and step 95), 500 at step 100 = 2,750 over 100 steps (259,000 to 394,000 cumulative summons) | once | SPEC_WPASS |
| 길드 수련장 (event season) | Rank 1 to 7: 750/500/350/250/200/150/100 | per season | IV377 |
| Special requests (global) | 50 + 30 + 20 + 30 + 10 (펫 산책로) | once | WIKI_QUESTS |
| 14일 특별 미션 | 10 per mission (84 missions = 840) + day 1 150 + day 8 250 | once | DC48415 |
| 7일 특별 미션 | 600 + final 2,000 | once (event) | NX_7DAY |
| 신규 캐릭터 성장 1/2 (free) | Lv34 200, Lv54 300, Lv70 600 | once per new character | IV770, IV771 |
| 신규 용사 성장 챌린지 | Lv75 1,000, Lv91 1,000. Boss stages 1/7/13: 100/250/500 | once | IV769 |
| Daily mission boost (cumulative) | 30 missions: 250 | event | NX_DMB_1119 |
| Red-diamond weekly shop | 100 for 1,000 레드 다이아 (×1) | weekly | SPEC_SHOP, IV121 |
| Guide quests / Battle pass (global wiki) | "rewarded when completing Guide Quests". Amount ? | once | WIKI_SUMMON |
| Summon-level rewards | "Tickets are rewarded once a level is reached". Amount ? | once | WIKI_SUMMON |

### 2.3 동료 소환권 (and 3차 전직 동료 소환권)

| Source | Amount | Frequency | Cite |
|---|---|---|---|
| 월간 출석 | days 2/9/16/23 = 40/60/80/120 (300 a month) | monthly | NX_MONTHLY_ATT |
| Companion summon ad | 10 summons | daily | WIKI_ADREM |
| Red-diamond weekly shop | 30 for 750 레드 다이아 (×1) | weekly | SPEC_SHOP |
| 14일 특별 미션 | day 2: 60, day 9: 80 | once | DC48415 |
| 신규 캐릭터 성장 1/2 (free) | Lv38 100, Lv58 200, Lv76 300 | once | IV770, IV771 |
| 신규 용사 성장 챌린지 boss stages | 3/6/9: 100 each. 12/15/17: 200 each | once | IV769 |
| Daily mission boost (cumulative) | 10 missions: 100 | event | NX_DMB_1119 |
| Special request (global) | Mrs. Ming Ming (companion summon Lv3): 30 | once | WIKI_QUESTS |
| Event attendance | 한가위 day 2: 1,000 | event | NX_HANGAWI |
| Coupons | 200 / 300 / 500 per code | event | §8 |
| 3차 전직 동료 소환권 | **No free source found.** Only the paid hotdeal at companion Lv6 (15,000 블루) and the paid companion pass track. The 14-day mission day 13 needs "3차 전직 동료 획득" and 79 completions give "유니크 동료" (= a 3rd-job companion, since unique = 3rd job) | once | WIKI_3RDTICKET, IV146, DC48415 |

### 2.4 무기 강화석

| Source | Amount | Frequency | Cite |
|---|---|---|---|
| Chapter-hunt drop | 0.5% per kill. Amount 100 (ch2) to 265 (ch44), formula ≈ (94..96 + 3×chapter) | per kill | MSI_LIB, WIKI_HUNT |
| 무기 던전 | Amount ? | daily | IV130 |
| Boss raid, no-equipment fallback | 20,000 (10,000 before 9/3), drawn as one of five fallback rewards | weekly entries | NX_PN_0903 |
| Guild shop | 60,000 per purchase (30,000 before 11/5). Price ? | weekly | NX_PN_1105 |
| Special request (global) | World Boss Stage 1: 50,000 | once | WIKI_QUESTS |
| 성장 챌린지 boss stages | 5: 100,000. 11: 200,000 | once | IV769 |

### 2.5 미라클 큐브 / 에디셔널 큐브

| Source | Amount | Frequency | Cite |
|---|---|---|---|
| World boss weekly tier | 미라클 큐브 5 (플래티넘1) to 30 (챔피언1). Gold and below: 0 | weekly | NX_PN_0922 |
| World boss shop | 미라클 큐브 1, limit 10 a week. 에디셔널 큐브 also sold. Prices ? | weekly | NX_PN_1127, IV263, IV121 |
| 여정의 보물 card | 미라클 큐브 10/12/14/16/20 (card stages 1-5) | per gauge fill | NX_PN_0813 |
| 여정의 발자취 one-off (ch20-41) | 미라클 큐브 10 or 에디셔널 5 per chapter (see §3.11) | once per chapter | WIKI_HJ |
| 월간 출석 | day 14: 30, day 26: 5 | monthly | NX_MONTHLY_ATT |
| 길드 대항전 | Rank 1-5: 15/10/7/5/3 미라클 큐브 | per round (weekly) | NX_PN_1127, IV377 |
| 길드 보스 대전 | Win: 에디셔널 10. Lose: 에디셔널 3 | per round | IV377 |
| Guild shop | 미라클 큐브 3 (warehouse Lv10). Price ? | weekly | NX_PN_1105 |
| Red-diamond shop | 미라클 1 = 1,000 (×5/wk). 에디셔널 1 = 1,500 (×3/wk) | weekly | SPEC_SHOP |
| 14일 특별 미션 | day 7: "큐브" 3. day 14: "큐브" 5 | once | DC48415 |
| Special request (global) | Chief Stan 2: 미라클 3 | once | WIKI_QUESTS |
| New character / challenge | Lv70: 40. Lv100: 50 미라클. Challenge Lv89: 10, Lv100: 15 에디셔널. Boss stage 18: 10 미라클 | once | IV770, IV771, IV769 |
| Event attendance | 전야제 day 5: 40 미라클, day 10: 30 에디셔널 | event | NX_EVE |
| Coupons | 30/50/55/100/111 미라클 | event | §8 |

### 2.6 스타포스 강화 주문서

| Source | Amount | Frequency | Cite |
|---|---|---|---|
| Arena weekly tier | 4 (브론즈1) to 60 (챔피언1) | weekly | NX_PN_0922 |
| Arena shop | 1 per 150 arena coins, limit 25 a week (KR limit; price is global msi) | weekly | NX_PN_1127, MSI_ARENA |
| 여정의 보물 card | 20/24/28/32/40 | per gauge fill | NX_PN_0813 |
| 여정의 발자취 one-off | 20 on selected chapters (20, 23, 26, 29, 30, 32, 35, 38, 41) | once | WIKI_HJ |
| 월간 출석 | day 21: 60, day 25: 10 | monthly | NX_MONTHLY_ATT |
| 콜로세움 (season) | Participation 12 … 1st place 80. Bingos 1-4: +5 each | per season | WIKI_COLO (global) |
| Guild shop | 5 (warehouse Lv9). Price ? | weekly | NX_PN_1105 |
| Red-diamond shop | 5 for 1,500 (×3). There is also an unlimited "12개" row | weekly | SPEC_SHOP, NX_PN_0212 |
| Special requests (global) | 2 + 2 + 3 + 2 | once | WIKI_QUESTS |
| 14일 특별 미션 | day 4: 6, day 11: 10 | once | DC48415 |
| New character / challenge | Lv62: 30, Lv82: 30. Challenge Lv80: 40, Lv95: 60. Boss stages 4/10/16: 10/20/20 | once | IV770, IV771, IV769 |
| Daily mission boost (cumulative) | 70 missions: 20 | event | NX_DMB_1119 |

### 2.7 주문의 흔적

| Source | Amount | Frequency | Cite |
|---|---|---|---|
| 강화 던전 | Amount ? (plus a 10% enhancement-scroll drop, see items-gacha) | daily | IV130 |
| 여정의 보물 card | 15,000/18,000/21,000/24,000/30,000 | per fill | NX_PN_0813 |
| 월간 출석 | days 4/11/18 = 2,000/3,000/4,000 | monthly | NX_MONTHLY_ATT |
| Boss raid fallback | 400 (200 before 9/3) | per entry | NX_PN_0903 |
| Guild shop | 1,000 per purchase, ×2 a week (warehouse Lv6). Price ? | weekly | NX_PN_1105 |
| Red-diamond shop | 1,000 for 1,000 (×1). There is also an unlimited "2000개" row | weekly | SPEC_SHOP, NX_PN_0108 |
| Special requests (global) | 750 / 300 / 300 / 300 / 300 / 500 / 500 | once | WIKI_QUESTS |
| 14일 특별 미션 | day 3: 1,500, day 10: 2,500 | once | DC48415 |
| New character / challenge | Lv42: 5,000, Lv88: 15,000. Challenge Lv85: 10,000 | once | IV770, IV771, IV769 |

### 2.8 명예의 훈장

| Source | Amount | Frequency | Cite |
|---|---|---|---|
| Chapter-hunt drop | 0.15% per kill (from 3-7). Amount 10 (ch3) to 50 (ch44) ≈ 6 + chapter | per kill | MSI_LIB, WIKI_HUNT |
| 월간 출석 | day 7: 20,000 | monthly | NX_MONTHLY_ATT |
| Guild shop | 4,000 (warehouse Lv7). Price ? | weekly | NX_PN_1105 |
| Red-diamond shop | 1,000 for 1,500 (×5). The "2000개" row is unlimited | weekly | SPEC_SHOP, NX_PN_1114 |
| 길드 수련장 rewards | "무기 소환권·훈장" | season | IV377 |
| 14일 특별 미션 | day 6: 2,500, day 13: 3,000 | once | DC48415 |
| New character 2 | Lv94: 20,000 | once | IV771 |
| Coupon | 60LVCOUPON 20,000 | once | NX_CPN_LV |

### 2.9 용사의 증표 (Hero Token)

| Source | Amount | Frequency | Cite |
|---|---|---|---|
| 용사의 수련장 (growth dungeon) | Amount ? This is the only regular source (global wiki: "obtained only through the Hero Training Ground") | daily (3 keys) | IV130, WIKI_HEROPOWER |
| 신규 캐릭터 성장 1 | Lv46: 5,000 | once | IV770 |
| 7일 특별 미션 | 2,000 total | once | NX_7DAY |
| Extra 용사의 수련장 tickets (free) | 전야제 days 3/8: 3/6. 성장 던전 15일 출석 days 4/9/14: 3/4/5 | event | NX_EVE, NX_GD15 |

### 2.10 유물 상자 / 레전드리 유물 소환 / 유물 강화석

| Source | Amount | Frequency | Cite |
|---|---|---|---|
| Arena shop | 유물 상자 for 500 coins, limit 10 a week | weekly | IV314, MSI_ARENA |
| Red-diamond shop | 유물 상자 for 1,500, limit 5 a week. The once-only "유물 성장 지원" is 5 boxes + 유물 강화석 15,000 for 7,500 | weekly | SPEC_SHOP, IV314 |
| 월간 출석 | day 27: 4 boxes. day 28: 레전드리 유물 소환 1 | monthly | NX_MONTHLY_ATT, IV314 |
| Personal 유물 발굴 대회 (after total awakening 20, 35 days) | Weekly missions (3 completions): 3 boxes. Cumulative 6/12/18: 5/10/20 boxes. Cumulative 21: legendary artifact 1 | once (35-day personal event) | IV314 |
| 성장 챌린지 | Lv93: 20, Lv99: 20, boss stage 19: 30 | once | IV769 |
| Coupon | 100LVCOUPON: 레전드리 유물 소환권 1 | once | NX_CPN_LV |
| 유물 강화석 drop | 20 per drop, 0.6% per kill (chapter 11+) | per kill | MSI_LIB |
| 유물 강화석 in the arena shop | Amount and price ? | weekly | IV136, IV285 |
| Community weekly f2p total | 15 boxes a week (5 + 10). 4 weeks + attendance = 64 boxes + 1 legendary | | IV314 |

### 2.11 엘리트 몬스터 소환 포인트

| Source | Amount | Frequency | Cite |
|---|---|---|---|
| Chapter-hunt drop | 0.25% per kill. Amount 10 (ch1-2) to 52 (ch44) ≈ 8 + chapter | per kill | MSI_LIB, WIKI_HUNT |
| 장비 던전 | Amount ? This is the main source | daily | IV130, WIKI_GD |
| Friends | Send 10 / receive 20 per friend, max 500 a day, up to 30 friends (x3 during 우정 포인트 부스트) | daily | WIKI_FRIENDS (global), NX_PN_1105 |
| 월간 출석 | days 6/13/20 = 1,000/1,500/2,000 | monthly | NX_MONTHLY_ATT |
| Boss raid fallback | 400 | per entry | NX_PN_0903 |
| Guild shop | 500 per purchase, ×2 a week (warehouse Lv4). Price ? | weekly | NX_PN_1105 |
| Special request (global) | Cloy's Costume Proposal: 100 | once | WIKI_QUESTS |
| 14일 특별 미션 | day 5: 2,000, day 12: 2,500 | once | DC48415 |
| New character 1 / challenge rank | Lv30: 1,000. Weekly boss rank 1,500 to 15,000 | once / weekly (event) | IV770, IV769 |
| Cap | The base cap is unknown. 스페셜 회원권 adds +200% (paid), 챌린지 골드 adds +100%. Summon cost is 60 (Lv1) to 185 (Lv30) points (global) | | NX_PN_0813, IV769, WIKI_ELITEPT |

### 2.12 장비 부 옵션 변환석

| Source | Amount | Frequency | Cite |
|---|---|---|---|
| Guild shop | 200 for 길드 코인 2,000 (warehouse Lv12) | weekly ×1 | NX_PN_1105, IV791 |
| 현상수배 shop | 200 for 불꽃 늑대 코인 2,000 | weekly ×1 | NX_PN_1105 |
| 현상수배 shop (limited) | 200 for 불꽃 늑대 코인 4,000 (stage 20 cleared) | 10 per character | NX_PN_1105 |
| 현상수배 weekly guild rank | 1st 300 / 2nd 200 / 3rd 100 | weekly | NX_PN_1105 |
| 1주년 상점 (event) | 2,500 for 회중시계 25,000. 1,000 for 10,000 | once (event) | IV791 |

### 2.13 마법 부여 주머니 (하급/중급/상급/최상급)

| Source | Amount | Frequency | Cite |
|---|---|---|---|
| 현상수배 shop | 하급 200 / 중급 400 / 상급 600 / 최상급 1,000 불꽃 늑대 코인. Unlocked by clearing bounty stage 10/20/30/40 | 5 per grade per week | NX_PN_1105, IV791 |
| 현상수배 first-clear rewards | 마법 부여 주머니 교환권 (amounts per stage ?) | once per stage | NX_PN_1105 |
| 현상수배 weekly guild rank | 1st: 최상급 10. 2nd: 상급 10 … 201-300th: 하급 2. 301-400th: 하급 1 (see §6.3) | weekly | NX_PN_1105 |
| Pouch rule | Opens instantly into 1 enchant scroll. Grade odds are in items-gacha §8 | | NX_PN_1105 |

### 2.14 보스 레이드 입장권

| Source | Amount | Frequency | Cite |
|---|---|---|---|
| Base entries | 2 per boss (자쿰/혼테일/핑크빈), refilled Monday 0시, no overflow | weekly | NX_PN_0903, NX_FAQ_RAID |
| 공용 보스 레이드 입장권 | 2, refilled Monday 0시, capped at max | weekly | NX_PN_0903 |
| 월간 출석 | day 17: 3 | monthly | NX_MONTHLY_ATT |
| History | Before 4/30: 3 shared per week. 4/30: 4. Since 9/3: 2 per boss + 2 shared | | NX_PN_0430, NX_PN_0903 |
| Rule | Using 2 tickets at once gives 2 rewards. 도전 모드 uses none and gives no reward | | NX_PN_0430, NX_PN_0922 |

### 2.15 탐험 티켓 (party-quest exploration)

| Source | Amount | Frequency | Cite |
|---|---|---|---|
| Weekly recharge | 1, every Monday 0시 (5/21 launch notes) | weekly | NX_PN_0521 |
| 월간 출석 | day 10: 3 | monthly | NX_MONTHLY_ATT |
| Conflict | A hotdeal description mentions "일간 / 주간 충전 시 최대 보유량" (content.md). No daily amount was found | | content.md |

### 2.16 빠른 사냥 / 빠른 사냥 티켓 / 시간 단축 티켓(1분)

| Source | Amount | Frequency | Cite |
|---|---|---|---|
| Free 빠른 사냥 | 1 | daily | IV119 |
| Ad 빠른 사냥 | 1 (mobile only) | daily | IV119 |
| Paid with 레드 다이아 | 3 more for 500 / 750 / 1,000 | daily | IV305, WIKI_QH |
| Kill count per use | +5 each use, up to 3,000 (3,150 with guild skill Lv5) | | IV119 |
| 빠른 사냥 티켓 | From world boss rewards and event missions/exchanges. Amount ? | | IV625, IV114 |
| 시간 단축 티켓(1분) | 펫 산책로 jump quests 100 + 1,000 (once). Boss-raid fallback 200. Guild warehouse Lv8-12: 300-500 a week. Bounty shop: 100 for 1,000 coin. Challenge boss stages 8/14: 1,000/2,000. Coupon COOLSUMMER 1,000 | various | WIKI_QUESTS, MEKI_PET, NX_PN_0903, NX_PN_1105, IV769 |

### 2.17 메소

| Source | Amount | Frequency | Cite |
|---|---|---|---|
| Chapter-hunt drop | 7% per kill. Amount 40 (ch1-2) to 82 (ch44) = 38 + chapter, multiplied by meso% | per kill | MSI_LIB, WIKI_HUNT |
| Offline reward | Up to 24h stored (8h → 24h on 2/12). 0.9 kills/s. Weekly account cap 300h (since 11/5) | per login | NX_PN_0212, NX_PN_1105, IV127 |
| 여정의 보물 card | 4,000,000 / 4,800,000 / 5,600,000 / 6,400,000 / 8,000,000 | per fill | NX_PN_0813 |
| Boss raid fallback | 100,000 (50,000 before 9/3) | per entry | NX_PN_0903 |
| 콜로세움 bingo 5-8 | 350,000 / 400,000 / 450,000 / 500,000 | season | WIKI_COLO |
| Chapter-challenge first clears, world boss damage milestones, party quests | Exists. Amount ? | once / repeat | IV625 |
| Arena coin / red-diamond shop | 300,000 메소 for 1,500 레드 다이아 (unlimited). The arena coin price is ? | | SPEC_SHOP, IV625 |
| Meso buffs | World boss and arena tier buffs +8 … +25% meso (weekly). 길드 토벌전 tier up to +10%. 길드 대항전 +13%. Ad booster +150% for 20 minutes | weekly / daily | WIKI_BOOST, NX_PN_1105, NX_PN_1127 |

### 2.18 월드보스 코인 / 2.19 아레나 코인 / 2.20 길드 코인 · 불꽃 늑대 코인
See §6 (exact tier tables). Summary:
- 월드보스 코인: daily 500 to 2,000 and weekly 1,000 to 4,000 by tier.
- 아레나 코인: same scale; losing also pays coins.
- 길드 코인: guild warehouse weekly supplies, 3,000 (Lv1) to 8,000 (Lv12).
- 불꽃 늑대 코인: weekly bounty rank, 6,600 to 14,000, plus first clears.

Cite: NX_PN_0922, NX_PN_1105.

### 2.21 성장던전 입장권 (keys)

| Source | Amount | Frequency | Cite |
|---|---|---|---|
| Daily recharge | 3 per dungeon (무기/경험치/장비/용사의 힘/강화). Cap 10. Not used up on failure | daily | IV130, WIKI_GD |
| New-stage first clears | Give keys. Each 10th stage gives a large first-clear bundle (amounts ?) | once per stage | IV130 |
| 월간 출석 | day 3: 경험치 열쇠 3 | monthly | NX_MONTHLY_ATT |
| Events | 성장 던전 15일 출석: 3/4/5 of each type. 성장 던전으로 출석 체크 (20 days, amounts ?). 전야제: 용사의 힘 3/6 | event | NX_GD15, NX_PN_1114, NX_EVE |
| Challenge grade buffs | +1 free recharge for 무기/경험치/장비/강화/용사의 힘 | event | IV769 |

### 2.22 여정의 증표 / 여정의 기운 / 여정의 상자 열쇠

| Source | Amount | Frequency | Cite |
|---|---|---|---|
| 여정의 증표, chapter-hunt drop | 0.1% per kill from ch21. 300 (21-1) to 1,577 (44-19). Not from 빠른 사냥 | per kill | MSI_LIB, IV596 |
| 여정의 상자 | Base 10,280 (ch20) to 45,300 (ch41) per chest + blessing bonus (gray 0 / yellow +5% / red +10%) | 5 keys a week | WIKI_HJ, IV596 |
| 여정의 상자 열쇠 | 5 a week (cap 5) | weekly | NX_PN_0611 |
| 여정의 발자취 first open | 12,000 (ch20) to 446,000 (ch41) 여정의 증표 | once | WIKI_HJ |
| 여정의 기운 | Only from shops: red shop 1,000 each ×5 a week, arena shop ×5 a week (price ?). Coupon 80LVCOUPON 50 | weekly | NX_PN_0903, IV586 |

### 2.23 Other free consumables
- 메모리얼 스크롤: 월간 출석 day 24 gives 20. Also sold in the world boss shop and guild shop (6, warehouse Lv11).
  Cite: NX_MONTHLY_ATT, IV114, NX_PN_1105.
- 버닝 필드 부스터: 월간 출석 days 5/12/19 give 2/3/4. 한가위 day 1 gives 10. 현상수배 shop sells 1 for 2,000 coins.
  Cite: NX_MONTHLY_ATT, NX_HANGAWI, NX_PN_1105.
- EXP boosters:
  - Guild warehouse weekly EXP Booster (30%): 3 to 14 (global wiki).
  - Guild shop: 경험치 부스터(50%) 10.
  - Coupon 98LVCOUPON: 100% booster 20.
  - Cite: WIKI_GUILDB, NX_PN_1105, NX_CPN_LV.

## 3. Missions

### 3.1 일일 미션 (permanent, KR)
What is known:
- The "일일 미션 클리어 (0/8)" header mission completes when 8 daily missions are done.
  - Normal reward: **무기 소환권 100 + 레드 다이아 5,000**.
  - The same values appear in Jan, May, Jul and Nov 2026. Cite: NX_DMB_SUGAR, NX_DMB_HALF, NX_DMB_0722, NX_DMB_1119.
- Path: 메뉴 → 미션 → 최상단 '일일 미션 클리어'. Resets daily at 0시.
- It is also the trigger for 월간 출석. Cite: NX_MONTHLY_ATT, NX_PN_0723.
- 11/5 added the mission "길드 건물 업그레이드 하기" (for guild members). Cite: NX_PN_1105.
- Community checklists name these condition types:
  - 성장 던전 클리어
  - 몬스터 처치
  - 엘리트 몬스터 소환
  - 무기 소환 "등"
  - Rewards: 무기 소환권 / 레드 다이아.
  - Cite: IV114, IV774.
- Total 레드 다이아 from daily missions: 7,400 a day (MEKI_RD; IV731 "7,400개 × 10일"). So the non-header missions pay 2,400 in total **(산식)**.
- **Confirmed (in-game 미션 window, KR screenshots from the user, 2026-11-24).** 10 missions; the header counts *claimed* missions:

| Daily mission | Goal | Reward |
|---|---|---|
| 몬스터 처치하기 | 2,000 | 레드 다이아 300 |
| 엘리트 몬스터 소환하기 | 15 | 엘리트 몬스터 소환 포인트 300 |
| 무기 소환하기 | 30 | 무기 소환권 20 + 시간 단축 티켓(1분) 20 |
| 무기 던전 클리어하기 | 3 | 레드 다이아 300 |
| 경험치 던전 클리어하기 | 3 | 레드 다이아 300 |
| 장비 던전 클리어하기 | 3 | 레드 다이아 300 |
| 강화 던전 클리어하기 | 3 | 레드 다이아 300 |
| 용사의 수련장 클리어하기 | 3 | 레드 다이아 300 |
| 광고 시청하기 | 1 | 레드 다이아 300 + 시간 단축 티켓(1분) 20 |
| 부스터 사용하기 | 1 | 레드 다이아 300 |

  Red diamonds: 8 × 300 = 2,400, which matches the derived total above.
- Templates from KR event daily missions (exact):
  - 핑크빈 일일 미션: 몬스터 2,000 처치 · 엘리트 몬스터 10회 소환 · 무기 던전 1회 클리어. Cite: IV296.
  - 도깨비 일일 미션: 몬스터 처치 · 엘리트 소환 · 아레나 플레이. Cite: NX_PN_0922.
  - 1주년 특별 미션: 접속 10분 · 엘리트 소환 10회 · 무기 소환 10회 · 무기 던전 1회 · 부스터 사용 1회 · 빠른 사냥 1회. Cite: IV774.
  - 반지 공방: 몬스터 1,000 · 경험치 던전 1회 · 빠른 사냥 1회. Cite: NX_PN_1105.
- Daily-mission boost events (personal 10 days). The 'clear' header does not count toward these totals:

| Cumulative daily missions | 2026-05 / 07 / 11 boost | 2026-01 슈가 boost |
|---|---|---|
| 10 | 동료 소환권 100 | 엘리트 소환 포인트 1,500 |
| 30 | 무기 소환권 250 | 무기 소환권 200 |
| 50 | 주문의 흔적 3,000 | 주문의 흔적 3,000 |
| 70 | 스타포스 강화 주문서 20 | 무기 소환권 500 |
| Final reward multiplier | x2 (200 tickets + 10,000) | x1.5 (150 + 7,500) |

Cite: NX_DMB_1119, NX_DMB_0722, NX_DMB_HALF, NX_DMB_SUGAR.

### 3.2 주간 미션 (permanent, KR)
- Stage rewards add up to **레드 다이아 15,500 a week**. Cite: MEKI_RD, IV731.
- There is a **무기 소환권 500** stage reward. Cite: DC435362.
- Progress fills a weekly gauge as daily missions are done; each stage is claimed. Resets Monday 0시. Cite: IV114, NX_FAQ_RESET.
- **Confirmed (in-game screenshots, 2026-11-24):** not a gauge. It has 9 missions, and the header "주간 미션 클리어 (0/8)" pays **무기 소환권 300 + 레드 다이아 12,000**:

| Weekly mission | Goal | Reward |
|---|---|---|
| 몬스터 처치하기 | 15,000 | 레드 다이아 500 |
| 엘리트 몬스터 소환하기 | 200 | 엘리트 몬스터 소환 포인트 500 |
| 무기 소환하기 | 1,000 | 무기 소환권 100 + 시간 단축 티켓(1분) 50 |
| 무기 던전 클리어하기 | 15 (hidden by the cursor; assumed) | 레드 다이아 500 |
| 경험치 던전 클리어하기 | 15 | 레드 다이아 500 + 경험치 부스터(50%) 3 |
| 용사의 수련장 클리어하기 | 15 | 레드 다이아 500 |
| 장비 던전 클리어하기 | 15 | 레드 다이아 500 |
| 강화 던전 클리어하기 | 10 | 레드 다이아 500 |
| 월드보스 플레이하기 | 1 | 레드 다이아 500 |

  Red diamonds: 7 × 500 + 12,000 = 15,500, which matches the community total. 경험치 부스터(50%) item info: "10분간 경험치 보너스 50% 효과를 얻습니다."

### 3.3 데일리 배틀 패스 (exact, KR)

| Monsters killed today | Free 레드 다이아 | Premium 레드 다이아 (paid membership; remove) |
|---|---|---|
| 500 | 100 | 100 |
| 1,000 | 100 | 100 |
| 1,500 | 100 | 100 |
| 2,200 | 100 | 100 |
| 2,900 | 100 | 100 |
| 3,600 | 100 | 100 |
| 4,300 | 100 | 100 |
| 5,000 | 800 | 800 |
| **Total** | **1,500/day** | +1,500 |

- Resets at 0시. Rewards are claimed by hand; unclaimed ones are lost.
- Boost events double the rewards.
- Global: the Special membership claims instantly.
- Cite: NX_BP_1014, NX_BP_0722, NX_BP_FIX, WIKI_MEMBER.

### 3.4 월간 출석 (28-day calendar, KR = global)
- Unlocks at chapter 3-2.
- Claim after "일일 미션 클리어 0/8".
- Resets on the 1st at 0시; unclaimed rewards are lost.
- Missed days can be bought back for 3,000 블루 (**paid; remove**).
- Special membership: 2 attendances a day (**paid**).
- Cite: NX_MONTHLY_ATT, IV85, MSI_ATT, NX_PN_0813.

| 일차 | 보상 | 일차 | 보상 | 일차 | 보상 | 일차 | 보상 |
|---|---|---|---|---|---|---|---|
| 1 | 무기 소환권 100 | 8 | 무기 소환권 150 | 15 | 무기 소환권 200 | 22 | 무기 소환권 300 |
| 2 | 동료 소환권 40 | 9 | 동료 소환권 60 | 16 | 동료 소환권 80 | 23 | 동료 소환권 120 |
| 3 | 성장던전 입장권: 경험치 (경험치 던전 열쇠) 3 | 10 | 탐험 티켓 3 | 17 | 보스 레이드 입장권 3 | 24 | 메모리얼 스크롤 20 |
| 4 | 주문의 흔적 2,000 | 11 | 주문의 흔적 3,000 | 18 | 주문의 흔적 4,000 | 25 | 스타포스 강화 주문서 10 |
| 5 | 버닝 필드 부스터 2 | 12 | 버닝 필드 부스터 3 | 19 | 버닝 필드 부스터 4 | 26 | 미라클 큐브 5 |
| 6 | 엘리트 몬스터 소환 포인트 1,000 | 13 | 엘리트 몬스터 소환 포인트 1,500 | 20 | 엘리트 몬스터 소환 포인트 2,000 | 27 | 유물 상자 4 |
| 7 | 명예의 훈장 20,000 | 14 | 미라클 큐브 30 | 21 | 스타포스 강화 주문서 60 | 28 | 레전드리 유물 소환 1 |


### 3.5 14일 특별 미션 (newcomer, KR 2025-11; DC48415, MEKI_14D)
- Each mission gives **무기 소환권 10**.
- Each day has 5 missions plus a "5개 완료" bonus mission: 6 × 14 = 84 missions.
- Completing **79** missions gives a **유니크 동료**. One day opens per day.

| Day | Missions (5) | 5-mission bonus |
|---|---|---|
| 1 | 몬스터 4,000 처치 · 캐릭터 Lv30 · 엘리트 소환 Lv7 · 무기 소환 Lv4 · 펫 산책로 방문 | 무기 소환권 150 |
| 2 | 몬스터 10,000 · 무기 던전 15단계 · 동료 소환 Lv3 · 어빌리티 변환 Lv2 · 월드보스 4단계 | 동료 소환권 60 |
| 3 | 몬스터 10,000 · 장비 던전 15단계 · 주문서 부여 5회 · 무기 소환 Lv8 · 6챕터 보스 | 주문의 흔적 1,500 |
| 4 | 파티퀘스트 반지 획득·장착 · 스타포스 3단계 · 무기 던전 22단계 · 경험치 던전 20단계 · 월드보스 5단계 | 스타포스 강화 주문서 6 |
| 5 | 길드원에게 도움 요청 · 아레나 5회 · 무기 소환 Lv9 · 동료 소환 Lv4 · 8챕터 보스 | 엘리트 소환 포인트 2,000 |
| 6 | 몬스터 10,000 · 장비 던전 20단계 · 강화 던전 18단계 · 엘리트 소환 Lv15 · 용사의 힘 3단계 | 명예의 훈장 2,500 |
| 7 | 몬스터 10,000 · 월드보스 6단계 · 길드 토벌전 플레이 · 잠재옵션 변환 3회 · 9챕터 보스 | 큐브 3 |
| 8 | 몬스터 10,000 · 캐릭터 Lv60 · 엘리트 소환 Lv16 · 무기 소환 Lv10 · 동료 소환 Lv5 | 무기 소환권 250 |
| 9 | 무기 던전 30단계 · 경험치 던전 25단계 · 어빌리티 변환 Lv3 · 주문서 부여 10회 · 월드보스 7단계 | 동료 소환권 80 |
| 10 | 몬스터 20,000 · 장비 던전 30단계 · 강화 던전 25단계 · 스타포스 7단계 · 아레나 플래티넘 | 주문의 흔적 2,500 |
| 11 | 몬스터 10,000 · 일반 잠재 레어 · 무기 던전 35단계 · 경험치 던전 30단계 · MP 물약 6단계 | 스타포스 강화 주문서 10 |
| 12 | 길드 토벌전 1,000만점 · 아레나 다이아몬드 · 무기 소환 Lv12 · 어빌리티 변환 Lv4 · 동료 소환 Lv6 | 엘리트 소환 포인트 2,500 |
| 13 | 길드 토벌전 1,500만점 · 일반 잠재 에픽 · 3차 전직 동료 획득 · 용사의 힘 4단계 · 엘리트 소환 Lv20 | 명예의 훈장 3,000 |
| 14 | 몬스터 20,000 · 장비 던전 33단계 · 아레나 마스터 · 월드보스 8단계 · 스타포스 10단계 | 큐브 5 |

Conflict: for day 7 and day 12-13, DC says "길드 토벌전"; mekifun EN says "Guild Raid". "큐브" is not specified (미라클 is likely, but not confirmed).

### 3.6 7일 특별 미션 (KR, 2026-01-08 onward, 20 days after it opens; NX_7DAY)
- Only the totals are published:
  - 레드 다이아 6,300
  - 무기 소환권 600
  - 엘리트 소환 포인트 2,000
  - 용사의 증표 2,000
  - 명예의 훈장 2,500
  - 주문의 흔적 2,500
  - 미라클 큐브 5
- Final reward: **무기 소환권 2,000**.
- Per-mission details exist only in game.

### 3.7 신규 캐릭터 성장 이벤트 (level rewards, free track only; KR 2026-07-23 and 2026-11-05 versions are identical; IV770, IV771)

| Level | 1: free reward | | Level | 2: free reward |
|---|---|---|---|---|
| 30 | 엘리트 소환 포인트 1,000 | | 70 | 무기 소환권 600 |
| 34 | 무기 소환권 200 | | 73 | 성장의 비약 Lv.73 |
| 38 | 동료 소환권 100 | | 76 | 동료 소환권 300 |
| 42 | 주문의 흔적 5,000 | | 79 | 성장의 비약 Lv.79 |
| 46 | 용사의 증표 5,000 | | 82 | 스타포스 강화 주문서 30 |
| 50 | 성장의 비약 Lv.50 | | 85 | 성장의 비약 Lv.85 |
| 54 | 무기 소환권 300 | | 88 | 주문의 흔적 15,000 |
| 58 | 동료 소환권 200 | | 91 | 성장의 비약 Lv.91 |
| 62 | 스타포스 강화 주문서 30 | | 94 | 명예의 훈장 20,000 |
| 66 | 성장의 비약 Lv.66 | | 97 | 성장의 비약 Lv.97 |
| 70 | 미라클 큐브 40 | | 100 | 미라클 큐브 50 |

- Event 1 runs 30 days and event 2 runs 60 days. Only characters created after the event start can join.
- 성장의 비약 = instant EXP (amount ?).
- The premium tracks (15,000원 / 45,000원) are paid; **remove them**.

### 3.8 신규 용사 성장 챌린지 (KR, 2026-11-05 to 12-16, personal 60 days; IV769)
- Points raise a group grade with buffs: 브론즈 1,000 → 챔피언1 100,000. All 23 grades are in the JSON.
- The buffs include extra free growth-dungeon recharges, +1 free 빠른 사냥, EXP%, and +5 여정의 상자 열쇠.
- **Challenge missions ([업적], once, value = challenge points):** 엘리트 몬스터 소환 6레벨 달성하기: 250; 용사의 힘 2단계 달성하기: 250; 성장던전: 무기 10단계 클리어: 250; 5챕터 보스 클리어: 250; 길드 가입하기: 1,000; 친구 20명 달성하기: 250; 첫 번째 동행 쉬움 1회 클리어: 250; 파티퀘스트 탐험 보내기 3회: 250; 장비 부위 1개의 잠재능력 레어 이상 달성하기: 500; 성장던전: 무기 25단계 클리어: 500; 장비 1개 스타포스 5성 달성하기: 500; 장비 부위 1개의 잠재능력 에픽 이상 달성하기: 1,000; 장비 1개 스타포스 8성 달성하기: 1,000; 첫 번째 동행 보통 1회 클리어: 1,500; 장비 1개 스타포스 10성 달성: 1,500; 어빌리티 변환 레벨 5 달성: 1,500; 레전드리 유물 획득: 2,000; 자쿰 쉬움 클리어 3회: 2,000; 장비 1개 스타포스 12성 달성: 2,000; 차원의 균열 쉬움 1회 클리어: 2,000; 장비 부위 1개의 에디셔널 잠재능력 레어 이상 달성: 2,000; 자쿰 쉬움 싱글 모드 1회 클리어: 4,000; 장비 부위 1개의 잠재능력 레전드리 이상 달성: 2,000; 여신의 흔적 쉬움 1회 클리어: 2,000; 레전드리 동료 획득: 2,500; 자쿰 보통 클리어 3회: 2,500; 첫 번째 동행 어려움 1회 클리어: 2,500; 차원의 균열 보통 1회 클리어: 2,500; 자쿰 보통 싱글 모드 1회 클리어: 5,000; 장비 1개 스타포스 15성 달성: 2,500; 로미오와 줄리엣 쉬움 1회 클리어: 2,500; 여신의 흔적 보통 1회 클리어: 3,000; 차원의 균열 어려움 1회 클리어: 3,000; 여정의 발자취 1개 개방: 3,000; 자쿰 어려움 클리어 3회: 3,000; 첫 번째 동행 카오스 1회 클리어: 4,000; 혼테일 쉬움 1회 클리어: 4,000; 자쿰 어려움 싱글 모드 1회 클리어: 8,000; 장비 1개 스타포스 17성 이상 달성: 4,000; [반복] 스타포스 강화 주문서 사용 2회: 1; [반복] 미라클 큐브 사용: 1; [반복] 에디셔널 큐브 사용: 2; [반복] 동료 소환하기 20회: 1; [반복] 무기 소환하기 50회: 1; [반복] 유물 획득: 2
- **Level missions:**
  - Lv30-70: 500 to 1,000 points.
  - Lv75: 무기 소환권 1,000
  - Lv80: 스타포스 40
  - Lv85: 주문의 흔적 10,000
  - Lv89: 에디셔널 큐브 10
  - Lv91: 무기 소환권 1,000
  - Lv93: 유물 상자 20
  - Lv95: 스타포스 60
  - Lv99: 유물 상자 20
  - Lv100: 에디셔널 큐브 15
- **Challenge boss 마왕 발록:**
  - Entry ticket: 1 a day at 0시, cap 3. The ticket is refunded on a kill.
  - Stage-clear rewards:
    - 1 무기 소환권 100
    - 2 의상 교환권
    - 3 동료 100
    - 4 스타포스 10
    - 5 무기 강화석 100,000
    - 6 동료 100
    - 7 무기 250
    - 8 시간 단축 1,000
    - 9 동료 100
    - 10 스타포스 20
    - 11 무기 강화석 200,000
    - 12 동료 200
    - 13 무기 500
    - 14 시간 단축 2,000
    - 15 동료 200
    - 16 스타포스 20
    - 17 동료 200
    - 18 미라클 큐브 10
    - 19 유물 상자 30
  - Max-damage milestones (400만 → 5조 3,200억): 500 to 1,500 points each.
  - Weekly rank rewards:
    - 1st: 3,000 points + 엘리트 15,000
    - Top 30: 600 points + 1,500

### 3.9 특별 의뢰 / town quests (one-time; global numbers; WIKI_QUESTS, MEKI_PET)

| Quest | Condition | Unlock | Reward |
|---|---|---|---|
| 2. Henesys - Boss | Henesys boss | GQ 56 | 400,000 EXP, 무기 소환권 50 |
| Clear World Boss Stage 1 | world boss 1 | GQ 59 | 1,000,000 EXP, 무기 강화석 50,000, **레드 다이아 1,000** |
| Summon an Elite Monster 5 times | elite ×5 | GQ 48 | Lv15 벨트, 130,000 EXP, **레드 다이아 600** |
| Reach Lv. 60 | Lv60 | Lv58 | **레드 다이아 10,000** |
| Use a scroll | scroll | GQ 147 | 노말 강화 주문서(40%) 2 |
| Chief Stan's Request | 1,000 kills | 3-3 | 무기 소환권 30 |
| Cassandra's Crystal Ball 1/2 | weapon summon ×10 / ×100 | 3-3 / ch6 | 무기 소환권 20 / 30 |
| Mrs. Ming Ming's Request | companion summon Lv3 | ch4 | 동료 소환권 30 |
| Cloy's Costume Proposal | check costumes | 4-7 | 엘리트 소환 포인트 100 |
| Bruce's Scroll Research 1/2/3 | scroll ×3/×5/×7 | ch5/ch7/ch8 | 주문의 흔적 750 / 300 / 300 |
| Camila's Birthday Party | companion summon ×30 | ch6 | 주문의 흔적 300 |
| Camila's Sparkling Star 1/2 | star force ×3 | ch7 / 9-5 | 스타포스 강화 주문서 2 / 2 |
| Mrs. Ming Ming's Request 2 | check Royal Style | ch7 | 스타포스 강화 주문서 2 |
| Cloy's Research Materials | 첫 번째 동행 PQ | 7-5 | 주문의 흔적 300 |
| Cassandra's Crystal Ball 3 | companion summon ×100 | ch8 | 스타포스 강화 주문서 3 |
| Bruce's Ability Research | ability ×100 | ch8 | 주문의 흔적 500 |
| Chief Stan's Request 2 | potential ×3 | 9-5 | 미라클 큐브 3 |
| Casey's Proposal | weapon summon ×1 | ch10 | 주문의 흔적 500 |
| 펫 산책로: Doofus / Bartos / Frod (jump quest) | checkpoints / top | 3-4 / 2-1 / 2-1 | 무기 소환권 10 / 시간 단축 티켓 100 / 1,000 |
| KR 9/22 커닝시티 NPC 카이지 | weapon summon ×1 → 1,000 kills | ch10 | 같은그림찾기 세트 (minigame) (NX_PN_0922) |
| KR 9/22 커닝시티 NPCs (알렉스, 제이엠, …) | "조건 달성 시 퀘스트" | | rewards ? (NX_PN_0922) |

### 3.10 가이드 퀘스트 (IV398, WIKI_GQ)
- Main progression chain. It cycles through repeating types: map breakthrough, kill N, elite summon, weapon/companion summon, world boss, quick hunt, each dungeon, arena, summon levels.
- Unlocks by number:
  - 8 스킬
  - 13 무기
  - 25 스킬 강화
  - 33 스킬 마스터리
  - 34 무기 던전 / 성장 던전
  - 45 경험치 던전
  - 58 월드 보스
  - 67 장비 던전
  - 75 빠른 사냥
  - 79 용사의 힘
  - 89 부스터
  - 96 동료
  - 113 어빌리티
  - 131 강화 던전 / 장비 슬롯 강화
  - 140 길드
  - 239 스타포스
  - 247 아레나
  - 347 유물
- Chapter unlocks: 3-2 월간 출석, 15 boss 자동 분해, 16 boss 월드 아레나, 20-10 용사의 여정 (full list in IV398).
- **Rewards per guide quest: not published** (the global wiki only says they include weapon and companion tickets).

### 3.11 여정의 발자취: one-time chapter rewards (global module data; WIKI_HJ)
"Bonus Glowing Cube" in the global data = 에디셔널 큐브 (assumed from the name).


| 챕터 | 1회 개방 보상 | 개방 비용 | 개방 시간 | 옵션 변환 비용 |
|---|---|---|---|---|
| 20 | 여정의 증표 12,000, 스타포스 강화 주문서 20, 미라클 큐브 10 | 메소 674,400, 여정의 증표 60,300 | 1d 2h 40m | 메소 5,000, 여정의 증표 1,900 |
| 21 | 여정의 증표 15,000, 미라클 큐브 10 | 메소 752,900, 여정의 증표 78,500 | 1d 7h 40m | 메소 5,300, 여정의 증표 2,120 |
| 22 | 여정의 증표 19,000, 에디셔널 큐브 5 | 메소 836,300, 여정의 증표 99,600 | 1d 12h 56m | 메소 5,600, 여정의 증표 2,360 |
| 23 | 여정의 증표 24,000, 스타포스 강화 주문서 20 | 메소 924,700, 여정의 증표 124,600 | 1d 18h 46m | 메소 5,900, 여정의 증표 2,620 |
| 24 | 여정의 증표 30,000, 미라클 큐브 10 | 메소 1,018,100, 여정의 증표 153,800 | 2d 1h 10m | 메소 6,200, 여정의 증표 2,910 |
| 25 | 여정의 증표 37,000, 에디셔널 큐브 5, 미라클 큐브 10 | 메소 1,116,600, 여정의 증표 186,700 | 2d 7h 50m | 메소 6,500, 여정의 증표 3,220 |
| 26 | 여정의 증표 44,000, 스타포스 강화 주문서 20 | 메소 1,220,200, 여정의 증표 224,500 | 2d 15h 3m | 메소 6,800, 여정의 증표 3,560 |
| 27 | 여정의 증표 53,000, 미라클 큐브 10 | 메소 1,329,100, 여정의 증표 267,500 | 2d 22h 50m | 메소 7,100, 여정의 증표 3,920 |
| 28 | 여정의 증표 63,000, 에디셔널 큐브 5 | 메소 1,443,200, 여정의 증표 315,000 | 3d 6h 53m | 메소 7,400, 여정의 증표 4,310 |
| 29 | 여정의 증표 74,000, 스타포스 강화 주문서 20 | 메소 1,562,700, 여정의 증표 372,600 | 3d 15h 30m | 메소 7,700, 여정의 증표 4,730 |
| 30 | 여정의 증표 88,000, 미라클 큐브 10, 스타포스 강화 주문서 20 | 메소 1,687,500, 여정의 증표 442,900 | 4d 23m | 메소 8,000, 여정의 증표 5,180 |
| 31 | 여정의 증표 105,000, 에디셔널 큐브 5 | 메소 1,817,800, 여정의 증표 527,200 | 4d 9h 50m | 메소 8,300, 여정의 증표 5,660 |
| 32 | 여정의 증표 125,000, 스타포스 강화 주문서 20 | 메소 1,953,600, 여정의 증표 629,000 | 4d 19h 50m | 메소 8,600, 여정의 증표 6,170 |
| 33 | 여정의 증표 148,000, 미라클 큐브 10 | 메소 2,094,900, 여정의 증표 741,300 | 5d 6h 6m | 메소 8,900, 여정의 증표 6,710 |
| 34 | 여정의 증표 173,000, 에디셔널 큐브 5 | 메소 2,241,800, 여정의 증표 866,400 | 5d 16h 56m | 메소 9,200, 여정의 증표 7,290 |
| 35 | 여정의 증표 200,000, 스타포스 강화 주문서 20, 미라클 큐브 10 | 메소 2,394,300, 여정의 증표 1,003,200 | 6d 4h 3m | 메소 9,500, 여정의 증표 7,900 |
| 36 | 여정의 증표 231,000, 미라클 큐브 10 | 메소 2,552,500, 여정의 증표 1,155,700 | 6d 16h | 메소 9,800, 여정의 증표 8,550 |
| 37 | 여정의 증표 264,000, 에디셔널 큐브 5 | 메소 2,716,400, 여정의 증표 1,319,200 | 7d 3h 56m | 메소 10,100, 여정의 증표 9,230 |
| 38 | 여정의 증표 300,000, 스타포스 강화 주문서 20 | 메소 2,886,100, 여정의 증표 1,499,900 | 7d 16h 43m | 메소 10,400, 여정의 증표 9,950 |
| 39 | 여정의 증표 341,000, 미라클 큐브 10 | 메소 3,061,600, 여정의 증표 1,707,700 | 8d 5h 46m | 메소 10,700, 여정의 증표 10,710 |
| 40 | 여정의 증표 390,000, 에디셔널 큐브 5, 미라클 큐브 10 | 메소 3,242,900, 여정의 증표 1,951,300 | 8d 19h 6m | 메소 11,000, 여정의 증표 11,510 |
| 41 | 여정의 증표 446,000, 스타포스 강화 주문서 20 | 메소 3,432,900, 여정의 증표 2,228,900 | 9d 8h 43m | 메소 11,300, 여정의 증표 12,350 |


### 3.12 업적 / 훈장
- No list of permanent **업적 (achievement) missions with currency rewards** was found. The "[업적]" items seen so far are event-scoped:
  - Challenge missions (§3.8)
  - 1주년 메키 살롱 업적 (one-time; 몬스터파크 2회 → 1주년 포인트 1,500)
  - "[업적] 동료 소환하기 / 아레나 플레이하기" hotdeal triggers (content.md)
  - Cite: IV774, NX_PN_1105.
- The permanent achievement-like system is **훈장 (medals)**: each gives +30 main stat (cap 1,500), not currency. Lists are on the global wiki "Medals" page and in the KR 9/22 patch (20 new medals). Cite: NX_PN_0922.

### 3.13 Event attendance calendars (templates; KR)

| Event | Day rewards (in order) | Cite |
|---|---|---|
| 성장 던전 15일 출석 (2026-08-13, GQ34, open 20 days) | 성장던전 입장권: 무기3 · 경험치3 · 장비3 · 용사의 힘3 · 강화3 · (same ×4) · (same ×5) | NX_GD15 |
| 한가위 풍성한 출석 (5 days) | 버닝 필드 부스터 10 · 동료 소환권 1,000 · 도깨비 복주머니 20 · 스타포스 30 · 레드 다이아 50,000 | NX_HANGAWI |
| 1주년 전야제 (10 days) | 엘리트 3,000 · 레드 5,000 · 용사의 힘 입장권 3 · 명예의 훈장 5,000 · 미라클 40 · 엘리트 6,000 · 레드 10,000 · 용사의 힘 입장권 6 · 명예의 훈장 12,000 · 에디셔널 30 | NX_EVE |
| 시그너스 15일 출석 | Event currencies only (시험의 증표 / 페리도트) | NX_CYGNUS15 |
| 성장 던전으로 출석 체크 (server day 9+, 20 days) | 성장 던전 입장권 (amounts ?) | NX_PN_1114 |

## 4. Ad rewards → convert to free daily claims

| Ad | Reward | Frequency | Cite |
|---|---|---|---|
| 일반 상점 ad | 레드 다이아 1,000 | 1/day | IV121, WIKI_ADREM |
| Weapon summon ad | 10 weapon summons | 1/day | WIKI_ADREM, DC435362 |
| Companion summon ad | 10 companion summons | 1/day | WIKI_ADREM |
| 빠른 사냥 ad | 1 quick hunt | 1/day | IV119 |
| Daily Ad Booster | EXP +100%, 메소 +150% for 20 minutes | 1/day | WIKI_BOOST |
| Skill-mastery / elite-summon upgrade acceleration | 30-minute acceleration ×3 | 1/day | WIKI_ADREM |
| 용사의 힘 level-up acceleration | "광고 가속" (amount ?) | ? | NX_PN_0903 |
| 여정의 보물 weekly boost | +20% (60%) / +25% (30%) / +30% (10%) gauge | 1/week | NX_PN_0813 |
| Event shop ads (e.g. 1주년 상점 ×2, 도깨비 장터 ×2) | Event currency (회중시계 500 each) | event | IV774 |

The paid 광고 제거 패키지 (365 days) only skips these ads. In the addon, every ad becomes a free button.

## 5. Shops bought with free currencies
**5.1 Red-diamond weekly shop (KR client 1.18.0; SPEC_SHOP, IV121, MEKI_RD, DC39138)**

| Item | Price (레드 다이아) | Limit | Unlock |
|---|---|---|---|
| 명예의 훈장 1,000 | 1,500 | 5/week | GQ 용사의 힘 2단계 |
| 미라클 큐브 1 | 1,000 | 5/week | max star force ≥3 |
| 에디셔널 큐브 1 | 1,500 | 3/week | max star force ≥12 |
| 스타포스 강화 주문서 5 | 1,500 | 3/week | GQ 슬리피우드-10 |
| 유물 상자 1 | 1,500 | 5/week | GQ 오르비스-10 |
| 무기 소환권 100 | 1,000 | 1/week | 5-10 |
| 동료 소환권 30 | 750 | 1/week | 6-10 |
| 주문의 흔적 1,000 | 1,000 | 1/week | 7-10 |
| 여정의 기운 1 | 1,000 | 5/week | 20-10 |
| 300,000 메소 | 1,500 | unlimited | 8-10 |
| 챕터 돌파 선물 (메소 50,000 + 흔적 1,500 + 레드 1,000) | 100 | once | 4-10 |
| 유물 성장 지원 (유물 상자 5 + 유물 강화석 15,000) | 7,500 | once | 오르비스-10 |

- Buying every weekly-limited row costs 36,750 a week.
  - Inven's "필수 6종" total: 19,750.
  - mekifun "weekly shop essentials": 24,250 (artifact 7,500 + miracle 5,000 + additional 4,500 + star force 4,500 + spell trace 1,000 + weapon/companion 1,750).
- Unlimited rows with unknown prices: 명예의 훈장 2000, 유물 강화석 10000, 스타포스 강화 주문서 12, 주문의 흔적 2000, 무기 강화석 60000 (NX_PN_1114, NX_PN_0108, NX_PN_0212).

**5.2 Arena shop (KR limits; global prices)**
- 유물 상자: 500 coins, 10/week (MSI_ARENA, IV314).
- 스타포스 강화 주문서 1: 150 coins, 25/week (15 → 25 on 11/27) (NX_PN_1127, MSI_ARENA). Community "core weekly" cost: 8,750 coins (MSI_ARENA).
- 여정의 기운: 5/week (NX_PN_0903).
- Also sold, prices ?: 유물 강화석, 주문의 흔적, 메소, 특별 의상 (IV114, IV285).

**5.3 World boss shop**
- 미라클 큐브 1: 10/week (5 → 10 on 11/27).
- Also sold: 에디셔널 큐브, 메모리얼 스크롤, 경험치 쿠폰.
- Prices ? Cite: NX_PN_1127, IV114, IV263, DC439725.

**5.4 Guild shop / 현상수배 상점**: see §2.12-2.13 and the JSON `guild.shop` / `guild.bountyShop`. Most guild-coin prices are ?.

## 6. Ranking / content rewards
### 6.1 World boss (KR, after 9/22; NX_PN_0922 / IV604)
Settlement: daily 0시 and Monday 0시 (KST).

| 티어 | 일일 월드보스 코인 | 주간 월드보스 코인 | 주간 미라클 큐브 |
|---|---|---|---|
| 챔피언1 | 2,000 | 4,000 | 30 |
| 챔피언2 | 1,900 | 3,800 | 28 |
| 챔피언3 | 1,800 | 3,600 | 26 |
| 챌린저1 | 1,700 | 3,400 | 24 |
| 챌린저2 | 1,600 | 3,200 | 22 |
| 챌린저3 | 1,500 | 3,000 | 20 |
| 챌린저4 | 1,400 | 2,800 | 18 |
| 챌린저5 | 1,300 | 2,600 | 17 |
| 그랜드마스터1 | 1,250 | 2,500 | 16 |
| 그랜드마스터2 | 1,200 | 2,400 | 15 |
| 그랜드마스터3 | 1,150 | 2,300 | 14 |
| 그랜드마스터4 | 1,100 | 2,200 | 13 |
| 그랜드마스터5 | 1,050 | 2,100 | 12 |
| 마스터1 | 1,000 | 2,000 | 11 |
| 마스터2 | 970 | 1,940 | 10 |
| 마스터3 | 940 | 1,880 | 9 |
| 마스터4 | 910 | 1,820 | 8 |
| 마스터5 | 880 | 1,760 | 7 |
| 다이아몬드1 | 850 | 1,700 | 6 |
| 플래티넘1 | 800 | 1,600 | 5 |
| 골드1 | 700 | 1,400 | - |
| 실버1 | 600 | 1,200 | - |
| 브론즈1 | 500 | 1,000 | - |

Before 9/22 the values were lower:
- Daily coin: 100 (브론즈1) … 1,500 (챔피언1).
- Weekly coin: 200 … 3,000.
- Weekly cubes: 1 (플래티넘1) … 25.

Other world boss rewards:
- Weekly benefit buffs (global): 전문가 메소 +8%, 장인 +16%, 달인 +19% & item +5%, 명인 +22% & +10%, 패왕 +25% & +15% (WIKI_BOOST).
- One-time damage-milestone rewards exist (amounts ?) (NX_FAQ_WB).
- Event: rewards ×3 (2026-09-22 to 10-05).

### 6.2 Arena (KR, after 9/22)
- Tickets: 5 a day, cap 20.
- Free list refresh: 3, recovering 1 per 10 minutes. After that a refresh costs 150 레드 다이아 (WIKI_ARENA).

| 티어 | 일일 아레나 코인 | 주간 아레나 코인 | 주간 스타포스 강화 주문서 |
|---|---|---|---|
| 챔피언1 | 2,000 | 4,000 | 60 |
| 챔피언2 | 1,900 | 3,800 | 56 |
| 챔피언3 | 1,800 | 3,600 | 52 |
| 챌린저1 | 1,700 | 3,400 | 48 |
| 챌린저2 | 1,600 | 3,200 | 44 |
| 챌린저3 | 1,500 | 3,000 | 40 |
| 챌린저4 | 1,400 | 2,800 | 36 |
| 챌린저5 | 1,300 | 2,600 | 34 |
| 그랜드마스터1 | 1,250 | 2,500 | 32 |
| 그랜드마스터2 | 1,200 | 2,400 | 30 |
| 그랜드마스터3 | 1,150 | 2,300 | 28 |
| 그랜드마스터4 | 1,100 | 2,200 | 26 |
| 그랜드마스터5 | 1,050 | 2,100 | 24 |
| 마스터1 | 1,000 | 2,000 | 22 |
| 마스터2 | 970 | 1,940 | 20 |
| 마스터3 | 940 | 1,880 | 18 |
| 마스터4 | 910 | 1,820 | 16 |
| 마스터5 | 880 | 1,760 | 14 |
| 다이아몬드1 | 850 | 1,700 | 12 |
| 플래티넘1 | 800 | 1,600 | 10 |
| 골드1 | 700 | 1,400 | 8 |
| 실버1 | 600 | 1,200 | 6 |
| 브론즈1 | 500 | 1,000 | 4 |

Before 9/22 the values were:
- Daily coin: 100 … 1,500.
- Weekly coin: 200 … 3,000.
- Weekly star force: 2 … 50.

Other PvP:
- 월드 아레나: 10 tickets a day during 5-day rounds (NX_PN_0702).
- 콜로세움 (global): rank rewards 12 … 80 star force; bingo 1-4: +5 star force each; bingo 5-8: 메소 350k-500k (WIKI_COLO).

### 6.3 Guild (KR)
- **Warehouse weekly supplies (11/5):**
  - 길드 코인: Lv1 3,000 · 2 3,400 · 3 3,800 · 4 4,200 · 5 4,600 · 6 5,000 · 7 5,500 · 8 6,000 · 9 6,500 · 10 7,000 · 11 7,500 · 12 8,000.
  - 시간 단축 티켓(1분): Lv8-12 300/350/400/450/500.
  - Global wiki also lists weekly EXP Booster(30%) ×3..14.
  - Cite: NX_PN_1105, WIKI_GUILDB.
- **Building upgrades:** 100 길드 건설 재료 = 50 building EXP, max 10 a day. The 300-블루 option is paid. 길드 건설 재료 sources ?
- **길드 대항전** (weekly rounds): rank 1-5 get buffs + 미라클 큐브 15/10/7/5/3 (NX_PN_1127, IV377).
- **길드 수련장** (event seasons): rank 1-7 get 무기 소환권 750/500/350/250/200/150/100 + EXP/메소 buffs + medals (IV377).
- **길드 보스 대전**: win = EXP/메소 +16% + 에디셔널 10; lose = EXP +7% + 에디셔널 3 (IV377).
- **길드 현상수배** (weekly, Sunday 0시; NX_PN_1105):

| Server rank | Min guild score | Weekly reward |
|---|---|---|
| 1 | 20,000 | 불꽃 늑대 코인 14,000 + 최상급 주머니 10 + 변환석 300 |
| 2 | 15,000 | 13,000 + 상급 10 + 변환석 200 |
| 3 | 10,000 | 12,000 + 상급 9 + 변환석 100 |
| 4-5 | 5,000 | 11,000 + 상급 8 |
| 6-10 | 4,000 | 10,000 + 상급 7 |
| 11-20 | 3,000 | 9,500 + 상급 6 |
| 21-30 | 2,000 | 9,000 + 상급 5 |
| 31-50 | 1,500 | 8,500 + 중급 5 |
| 51-70 | 1,000 | 8,000 + 중급 4 |
| 71-100 | 800 | 7,800 + 중급 3 |
| 101-200 | 600 | 7,600 + 중급 2 |
| 201-300 | 500 | 7,400 + 하급 2 |
| 301-400 | 500 | 7,200 + 하급 1 |
| 401-500 | 300 | 7,000 |
| 501-1,000 | 100 | 6,800 |
| 1,001+ | 1 | 6,600 |

### 6.4 Boss raid fallback (no-equipment clear; KR 9/3; NX_PN_0903)
- One of these is given:
  - 주문의 흔적 400
  - 메소 100,000
  - 엘리트 소환 포인트 400
  - 무기 강화석 20,000
  - 시간 단축 티켓(1분) 200
- The 9/3 values are double the old ones.
- Weights from global Zakum Normal/Hard (old amounts; WIKI_ZAKUM, MSI_ZAKUM):
  - 메소 35%
  - 엘리트 16%
  - 무기 강화석 10%
  - 주문의 흔적 7%
  - 시간 단축 3%
  - The rest is equipment and scroll drops.

### 6.5 여정의 보물 cards (KR 8/13 = global 1.14.0; NX_PN_0813, MSI_JT)

| Card | Stage 1 | 2 | 3 | 4 | 5 |
|---|---|---|---|---|---|
| 스타포스 강화 주문서 | 20 | 24 | 28 | 32 | 40 |
| 미라클 큐브 | 10 | 12 | 14 | 16 | 20 |
| 주문의 흔적 | 15,000 | 18,000 | 21,000 | 24,000 | 30,000 |
| 메소 | 4,000,000 | 4,800,000 | 5,600,000 | 6,400,000 | 8,000,000 |

- Pick 1 card of 4. The picked card goes back to stage 1; the other three go up one stage (max 5).
- The gauge fills from chapter hunting (ch20+) and offline time, up to 200%. The gauge EXP table is in items-gacha §10.

## 7. Chapter-hunt kill drops (free, per normal-monster kill; MSI_LIB client 1.14.0, matches WIKI_HUNT formulas)
Cells show `amount (chance % per kill)`. Boss stages (x-10/x-15/x-20) have no kill drops. 레드 다이아 is stored as `FreeDia` (named "Blue Diamond" in that file).

| ch | stages | 메소 (%) | 레드 다이아 (%) | 엘리트 몬스터 소환 포인트 (%) | 무기 소환권 (%) | 무기 강화석 (%) | 명예의 훈장 (%) | 유물 강화석 (%) | 여정의 증표 (%) |
|---|---|---|---|---|---|---|---|---|---|
| 1 | 1-1~1-3 | 40 (7) | 1 (1) | 10 (0.25) | - | - | - | - | - |
| 2 | 2-1~2-7 | 40 (7) | 1 (1) | 10 (0.25) | 1 (0.15) | 100-102 (0.5) | - | - | - |
| 3 | 3-1~3-9 | 41 (7) | 1 (1) | 11 (0.25) | 1 (0.15) | 103-105 (0.5) | 10 (0.15) | - | - |
| 4 | 4-1~4-9 | 42 (7) | 1 (1) | 12 (0.25) | 1 (0.15) | 106-108 (0.5) | 10 (0.15) | - | - |
| 5 | 5-1~5-9 | 43 (7) | 1 (1) | 13 (0.25) | 1 (0.15) | 109-111 (0.5) | 11 (0.15) | - | - |
| 6 | 6-1~6-9 | 44 (7) | 1 (1) | 14 (0.25) | 1 (0.15) | 112-114 (0.5) | 12 (0.15) | - | - |
| 7 | 7-1~7-9 | 45 (7) | 1 (1) | 15 (0.25) | 1 (0.15) | 115-117 (0.5) | 13 (0.15) | - | - |
| 8 | 8-1~8-9 | 46 (7) | 1 (1) | 16 (0.25) | 1 (0.15) | 118-120 (0.5) | 14 (0.15) | - | - |
| 9 | 9-1~9-9 | 47 (7) | 1 (1) | 17 (0.25) | 1 (0.15) | 121-123 (0.5) | 15 (0.15) | - | - |
| 10 | 10-1~10-9 | 48 (7) | 1 (1) | 18 (0.25) | 1 (0.15) | 124-126 (0.5) | 16 (0.15) | - | - |
| 11 | 11-1~11-9 | 49 (7) | 1 (1) | 19 (0.25) | 1 (0.15) | 127-129 (0.5) | 17 (0.15) | 20 (0.6) | - |
| 12 | 12-1~12-9 | 50 (7) | 1 (1) | 20 (0.25) | 1 (0.15) | 130-132 (0.5) | 18 (0.15) | 20 (0.6) | - |
| 13 | 13-1~13-9 | 51 (7) | 1 (1) | 21 (0.25) | 1 (0.15) | 133-135 (0.5) | 19 (0.15) | 20 (0.6) | - |
| 14 | 14-1~14-9 | 52 (7) | 1 (1) | 22 (0.25) | 1 (0.15) | 136-138 (0.5) | 20 (0.15) | 20 (0.6) | - |
| 15 | 15-1~15-9 | 53 (7) | 1 (1) | 23 (0.25) | 1 (0.15) | 139-141 (0.5) | 21 (0.15) | 20 (0.6) | - |
| 16 | 16-1~16-9 | 54 (7) | 1 (1) | 24 (0.25) | 1 (0.15) | 142-144 (0.5) | 22 (0.15) | 20 (0.6) | - |
| 17 | 17-1~17-9 | 55 (7) | 1 (1) | 25 (0.25) | 1 (0.15) | 145-147 (0.5) | 23 (0.15) | 20 (0.6) | - |
| 18 | 18-1~18-9 | 56 (7) | 1 (1) | 26 (0.25) | 1 (0.15) | 148-150 (0.5) | 24 (0.15) | 20 (0.6) | - |
| 19 | 19-1~19-9 | 57 (7) | 1 (1) | 27 (0.25) | 1 (0.15) | 151-153 (0.5) | 25 (0.15) | 20 (0.6) | - |
| 20 | 20-1~20-9 | 58 (7) | 1 (1) | 28 (0.25) | 1 (0.15) | 154-156 (0.5) | 26 (0.15) | 20 (0.6) | - |
| 21 | 21-1~21-9 | 59 (7) | 1 (1) | 29 (0.25) | 1 (0.15) | 157-159 (0.5) | 27 (0.15) | 20 (0.6) | 300-324 (0.1) |
| 22 | 22-1~22-9 | 60 (7) | 1 (1) | 30 (0.25) | 1 (0.15) | 160-162 (0.5) | 28 (0.15) | 20 (0.6) | 327-351 (0.1) |
| 23 | 23-1~23-9 | 61 (7) | 1 (1) | 31 (0.25) | 1 (0.15) | 163-165 (0.5) | 29 (0.15) | 20 (0.6) | 354-378 (0.1) |
| 24 | 24-1~24-9 | 62 (7) | 1 (1) | 32 (0.25) | 1 (0.15) | 166-168 (0.5) | 30 (0.15) | 20 (0.6) | 381-405 (0.1) |
| 25 | 25-1~25-9 | 63 (7) | 1 (1) | 33 (0.25) | 1 (0.15) | 169-171 (0.5) | 31 (0.15) | 20 (0.6) | 408-432 (0.1) |
| 26 | 26-1~26-9 | 64 (7) | 1 (1) | 34 (0.25) | 1 (0.15) | 172-174 (0.5) | 32 (0.15) | 20 (0.6) | 435-459 (0.1) |
| 27 | 27-1~27-9 | 65 (7) | 1 (1) | 35 (0.25) | 1 (0.15) | 175-177 (0.5) | 33 (0.15) | 20 (0.6) | 462-486 (0.1) |
| 28 | 28-1~28-9 | 66 (7) | 1 (1) | 36 (0.25) | 1 (0.15) | 178-180 (0.5) | 34 (0.15) | 20 (0.6) | 489-513 (0.1) |
| 29 | 29-1~29-14 | 67 (7) | 1 (1) | 37 (0.25) | 1 (0.15) | 181-185 (0.5) | 35 (0.15) | 20 (0.6) | 516-555 (0.1) |
| 30 | 30-1~30-14 | 68 (7) | 1 (1) | 38 (0.25) | 1 (0.15) | 185-190 (0.5) | 36 (0.15) | 20 (0.6) | 558-597 (0.1) |
| 31 | 31-1~31-14 | 69 (7) | 1 (1) | 39 (0.25) | 1 (0.15) | 190-194 (0.5) | 37 (0.15) | 20 (0.6) | 601-653 (0.1) |
| 32 | 32-1~32-14 | 70 (7) | 1 (1) | 40 (0.25) | 1 (0.15) | 195-199 (0.5) | 38 (0.15) | 20 (0.6) | 657-709 (0.1) |
| 33 | 33-1~33-14 | 71 (7) | 1 (1) | 41 (0.25) | 1 (0.15) | 199-204 (0.5) | 39 (0.15) | 20 (0.6) | 713-765 (0.1) |
| 34 | 34-1~34-14 | 72 (7) | 1 (1) | 42 (0.25) | 1 (0.15) | 204-208 (0.5) | 40 (0.15) | 20 (0.6) | 769-821 (0.1) |
| 35 | 35-1~35-14 | 73 (7) | 1 (1) | 43 (0.25) | 1 (0.15) | 209-213 (0.5) | 41 (0.15) | 20 (0.6) | 825-877 (0.1) |
| 36 | 36-1~36-14 | 74 (7) | 1 (1) | 44 (0.25) | 1 (0.15) | 213-218 (0.5) | 42 (0.15) | 20 (0.6) | 881-933 (0.1) |
| 37 | 37-1~37-14 | 75 (7) | 1 (1) | 45 (0.25) | 1 (0.15) | 218-222 (0.5) | 43 (0.15) | 20 (0.6) | 937-989 (0.1) |
| 38 | 38-1~38-14 | 76 (7) | 1 (1) | 46 (0.25) | 1 (0.15) | 223-227 (0.5) | 44 (0.15) | 20 (0.6) | 993-1045 (0.1) |
| 39 | 39-1~39-19 | 77 (7) | 1 (1) | 47 (0.25) | 1 (0.15) | 227-233 (0.5) | 45 (0.15) | 20 (0.6) | 1049-1121 (0.1) |
| 40 | 40-1~40-19 | 78 (7) | 1 (1) | 48 (0.25) | 1 (0.15) | 234-240 (0.5) | 46 (0.15) | 20 (0.6) | 1125-1197 (0.1) |
| 41 | 41-1~41-19 | 79 (7) | 1 (1) | 49 (0.25) | 1 (0.15) | 240-246 (0.5) | 47 (0.15) | 20 (0.6) | 1202-1292 (0.1) |
| 42 | 42-1~42-19 | 80 (7) | 1 (1) | 50 (0.25) | 1 (0.15) | 246-252 (0.5) | 48 (0.15) | 20 (0.6) | 1297-1387 (0.1) |
| 43 | 43-1~43-19 | 81 (7) | 1 (1) | 51 (0.25) | 1 (0.15) | 253-259 (0.5) | 49 (0.15) | 20 (0.6) | 1392-1482 (0.1) |
| 44 | 44-1~44-19 | 82 (7) | 1 (1) | 52 (0.25) | 1 (0.15) | 259-265 (0.5) | 50 (0.15) | 20 (0.6) | 1487-1577 (0.1) |

Global-wiki formulas (WIKI_HUNT):
- 메소 = 38 + chapter (ch1 = 40).
- 무기 강화석 = 94/95/96 + 3×chapter (stages x-1..3 / 4..6 / 7..9).
- 엘리트 포인트 = 8 + chapter.
- 명예의 훈장 = 6 + chapter (from 3-7).

Offline:
- 0.9 kills/s, base cap 24h.
- Since 11/5 there is a weekly account cap of 300h (Premium is exempt).
- Cite: NX_PN_0212, NX_PN_1105, IV127.

## 8. Coupon codes (pattern only)
- Each code works once per account and is delivered to the **account mailbox**.
- Entry: 메뉴 → 환경 설정 → 기타 → 쿠폰입력, or mcoupon.nexon.com with the UID.
- Lifetime: time-limited, usually 2-6 weeks. Level coupons have no expiry and are claimable after reaching the level.
- Typical payloads (NX_CPN_*, IV152, WIKI_COUPONS):
  - 동료 소환권: 200 / 300 / 500.
  - 미라클 큐브: 30 / 50 / 55 / 100 / 111.
  - 명예의 훈장: 7,000 / 20,000.
  - 스타포스: 100 / 111, + 1,000,000 / 11,111,111 메소.
  - 여정의 기운: 50.
  - Boosters: 20 + 20.
  - Legendary artifact: 1.
- Level coupons (KR 1주년):
  - Lv30: 동료 300
  - Lv60: 훈장 20,000
  - Lv80: 여정의 기운 50
  - Lv98: 버닝 부스터 20 + EXP 부스터(100%) 20
  - Lv100: 레전드리 유물 소환권 1
- The full code list is in the JSON.

## 9. Paid elements seen in this research (remove or convert)
- 데일리 배틀 패스 premium track (+1,500 a day; Premium membership).
- Membership:
  - Special: +12h offline, +1 빠른 사냥, 2× attendance per day, elite cap +200%, instant pass.
  - Premium: offline ×1.7, +1 여정의 보물 boost, -15% upgrade time, no 300h cap.
  - Ad-removal package.
- Attendance makeup (3,000 블루).
- New-character event premium tracks (15,000원 / 45,000원).
- Companion pickup pass and weapon pass paid tracks.
- Hotdeals: job advancement (2차 무기 300 / 3차 동료 250 / 4차 cube), summon levels, 월간 출석 completion hotdeal (54,000 블루 + legendary), legendary artifact awakening hotdeal.
- Boss-raid / arena refills with 레드 다이아 (keep these: they are free currency).
- Cite: NX_BP_1014, NX_PN_0813, WIKI_MEMBER, IV146, IV453.

## 10. Conflicts and what is still missing
**Conflicts**
- 탐험 티켓: +1 every Monday (KR 5/21 notes) vs. a hotdeal text mentioning "일간 / 주간 충전". No daily amount was found.
- World boss weekly rewards. IV114 (2026-09-02) lists 엘리트 포인트, 무기/동료 소환권, 빠른 사냥 티켓, 레드 다이아, 메소. The 9/22 official table lists only coin + 미라클 큐브. The IV114 list probably mixes in damage-milestone rewards. Both are recorded.
- Overlord buff: the global wiki description says +15% item, but its effect column says +10%.
- 14-day mission day 7: the KR source says "길드 토벌전 플레이"; mekifun EN says "Guild Raid".
- Growth-dungeon keys: IV130 says "3 a day, cap 10". content.md says "경험치던전 하루 열쇠 최대 3개". These are probably the daily recharge vs. the hold cap.

**Still missing (no text source found)**
1. The permanent **일일 미션** list (conditions and per-mission rewards). Only the total (7,400 레드/day) and the clear reward (100 무기 소환권 + 5,000) are known.
2. The **주간 미션** stages (only the totals 15,500 레드 + a 500 무기 소환권 stage are known).
3. **업적** with currency rewards (only event-scoped ones were found).
4. **가이드 퀘스트** rewards per quest.
5. **소환 레벨 보상** (weapon/companion summon-level rewards).
6. Job-advancement free rewards.
7. **Growth dungeon** clear/sweep amounts per stage (무기 소환권, 강화석, 엘리트 포인트, 용사의 증표, 주문의 흔적). Also the first-clear key bundles.
8. World boss damage-milestone rewards.
9. Prices in the world boss shop and guild shop, plus most arena shop prices.
10. 길드 건설 재료 sources.
11. Bounty first-clear rewards.
12. Companion pickup pass free track.
13. The 3차 동료 소환권 free source (none exists).
14. Base 엘리트 포인트 cap.
15. Chapter-challenge first-clear meso.
16. 빠른 사냥 reward formula.

Blocked sources:
- maplestoryidle.nexon.com/ko/guide: 403 bot wall, abandoned as instructed.
- mapleidle.gg: HTTP 429 Vercel checkpoint.
- media.maplestorywiki.net images: host not allowed.
- mekifun info-* pages: client-rendered.

## 11. Sources (citation keys)

| Key | Region | Date | Title | URL | Raw file (under web/research/income/) |
|---|---|---|---|---|---|
| NX_DMB_1119 | KR | 2026-11-06 | 일일 미션 부스트 (~11/19) | https://forum.nexon.com/maplestoryidle-kr/board_view?board=7418&thread=3575660 | nexon/t/3575660.json |
| NX_DMB_0722 | KR | 2026-07-09 | 일일 미션 부스트 (~7/22) | https://forum.nexon.com/maplestoryidle-kr/board_view?board=7418&thread=3490081 | nexon/t/3490081.json |
| NX_DMB_SUGAR | KR | 2026-01-12 | 슈가의 일일 미션 부스트 (1/12~1/29) | https://forum.nexon.com/maplestoryidle-kr/board_view?board=7418&thread=3339452 | nexon/t/3339452.json |
| NX_DMB_HALF | KR | 2026-05-07 | 반주년 메키 페스티벌 일일 미션 부스트 | https://forum.nexon.com/maplestoryidle-kr/board_view?board=7418&thread=3436536 | nexon/t/3436536.json |
| NX_BP_1014 | KR | 2026-10-01 | 배틀 패스 부스트 (~10/14) | https://forum.nexon.com/maplestoryidle-kr/board_view?board=7418&thread=3549931 | nexon/t/3549931.json |
| NX_BP_0722 | KR | 2026-07-09 | 배틀 패스 부스트 (~7/22) | https://forum.nexon.com/maplestoryidle-kr/board_view?board=7418&thread=3490082 | nexon/t/3490082.json |
| NX_BP_FIX | KR | 2026-03-05 | (추가) 배틀 패스 부스트 이벤트 관련 처리 방향 안내 | https://forum.nexon.com/maplestoryidle-kr/board_view?board=6633&thread=3394412 | nexon/t/3394412.json |
| NX_MONTHLY_ATT | KR | 2026-07-23 (event from 2026-08-01) | 월간 출석 이벤트 | https://forum.nexon.com/maplestoryidle-kr/board_view?board=6697&thread=3505299 | nexon/t/3505299.json; inven/85.html |
| NX_7DAY | KR | 2026-01-08 | 7일 특별 미션 이벤트! | https://forum.nexon.com/maplestoryidle-kr/board_view?board=6697&thread=3339445 | nexon/t/3339445.json |
| NX_FAQ_RESET | KR | 2025-11-06 | FAQ 콘텐츠별 보상 초기화 주기 | https://forum.nexon.com/maplestoryidle-kr/board_view?board=6730&thread=3210559 | nexon/t/3210559.json |
| NX_FAQ_RAID | KR | 2026-11-03 | FAQ 보스 레이드 입장권은 어떻게 지급되나요? | https://forum.nexon.com/maplestoryidle-kr/board_view?board=6730&thread=3574931 | nexon/t/3574931.json |
| NX_FAQ_RANK | KR | 2025-11-06 | FAQ 랭킹 정산 보상이 도착하지 않았어요 | https://forum.nexon.com/maplestoryidle-kr/board_view?board=6730&thread=3210575 | nexon/t/3210575.json |
| NX_FAQ_OFFLINE | KR | 2025-11-06 | FAQ 오프라인 보상 | https://forum.nexon.com/maplestoryidle-kr/board_view?board=6730&thread=3210548 | nexon/t/3210548.json |
| NX_PN_1105 | KR | 2026-11-05 | 11/5(목) 패치노트 | https://forum.nexon.com/maplestoryidle-kr/board_view?board=6698&thread=3574353 | nexon/t/3574353.json; inven/772.html |
| NX_PN_1015 | KR | 2026-10-15 | 10/15(목) 패치노트 | https://forum.nexon.com/maplestoryidle-kr/board_view?board=6698&thread=3563013 | nexon/t/3563013.json |
| NX_PN_0922 | KR | 2026-09-22 | 9/22(화) 패치노트 | https://forum.nexon.com/maplestoryidle-kr/board_view?board=6698&thread=3550026 | nexon/t/3550026.json; inven_6554_604.html |
| NX_PN_0903 | KR | 2026-09-03 | 9/3(목) 패치노트 | https://forum.nexon.com/maplestoryidle-kr/board_view?board=6698&thread=3535860 | nexon/t/3535860.json |
| NX_PN_0813 | KR | 2026-08-13 | (추가) 8/13(목) 패치노트 | https://forum.nexon.com/maplestoryidle-kr/board_view?board=6698&thread=3521991 | nexon/t/3521991.json |
| NX_PN_0723 | KR | 2026-07-23 | 7/23(목) 패치노트 | https://forum.nexon.com/maplestoryidle-kr/board_view?board=6698&thread=3506485 | nexon/t/3506485.json |
| NX_PN_0702 | KR | 2026-07-02 | (추가) 7/2(목) 패치노트 | https://forum.nexon.com/maplestoryidle-kr/board_view?board=6698&thread=3490212 | nexon/t/3490212.json |
| NX_PN_0611 | KR | 2026-06-11 | (추가) 6/11(목) 패치노트 | https://forum.nexon.com/maplestoryidle-kr/board_view?board=6698&thread=3473998 | nexon/t/3473998.json |
| NX_PN_0521 | KR | 2026-05-21 | 5/21(목) 패치노트 | https://forum.nexon.com/maplestoryidle-kr/board_view?board=6698&thread=3448688 | nexon/t/3448688.json |
| NX_PN_0430 | KR | 2026-04-30 | (추가) 4/30(목) 패치노트 | https://forum.nexon.com/maplestoryidle-kr/board_view?board=6698&thread=3435722 | nexon/t/3435722.json |
| NX_PN_0212 | KR | 2026-02-12 | 2/12(목) 패치노트 | https://forum.nexon.com/maplestoryidle-kr/board_view?board=6698&thread=3374751 | nexon/t/3374751.json |
| NX_PN_0108 | KR | 2026-01-08 | 1/8(목) 패치노트 | https://forum.nexon.com/maplestoryidle-kr/board_view?board=6698&thread=3339428 | nexon/t/3339428.json |
| NX_PN_1127 | KR | 2025-11-27 | 11/27(목) 패치노트 | https://forum.nexon.com/maplestoryidle-kr/board_view?board=6698&thread=3274197 | nexon/t/3274197.json |
| NX_PN_1114 | KR | 2025-11-14 | 11/14(금) 패치노트 | https://forum.nexon.com/maplestoryidle-kr/board_view?board=6698&thread=3224718 | nexon/t/3224718.json |
| NX_GD15 | KR | 2026-08-13 | 성장 던전 15일 출석 이벤트 (~9/2) | https://forum.nexon.com/maplestoryidle-kr/board_view?board=7418&thread=3521783 | nexon/t/3521783.json |
| NX_HANGAWI | KR | 2026-09-23 | 한가위 풍성한 출석 (~9/29) | https://forum.nexon.com/maplestoryidle-kr/board_view?board=7418&thread=3549924 | nexon/t/3549924.json |
| NX_EVE | KR | 2026-10-22 | 1주년 전야제 (~11/4) | https://forum.nexon.com/maplestoryidle-kr/board_view?board=7418&thread=3563145 | nexon/t/3563145.json |
| NX_CYGNUS15 | KR | 2026-07-23 | 시그너스 15일 출석 이벤트 | https://forum.nexon.com/maplestoryidle-kr/board_view?board=7418&thread=3505289 | nexon/t/3505289.json |
| NX_CPN_LV | KR | 2026-11-05 | (2탄) 1주년 기념 레벨별 쿠폰 선물 | https://forum.nexon.com/maplestoryidle-kr/board_view?board=6697&thread=3575645 | nexon/t/3575645.json |
| NX_CPN_1ST | KR | 2026-11-05 | (1탄) 1주년 기념 쿠폰 선물 | https://forum.nexon.com/maplestoryidle-kr/board_view?board=6697&thread=3574354 | nexon/t/3574354.json |
| NX_CPN_AWARD | KR | 2026-11-18 | 구글 플레이 올해의 베스트 게임 수상 기념 쿠폰 | https://forum.nexon.com/maplestoryidle-kr/board_view?board=6697&thread=3582693 | nexon/t/3582693.json |
| NX_CPN_THANKS | KR | 2025-11-18 | 1일차 감사 쿠폰 공개 | https://forum.nexon.com/maplestoryidle-kr/board_view?board=7418&thread=3252827 | nexon/t/3252827.json |
| NX_CPN_100D | KR | 2026-02-13 | 정식 오픈 100일 기념 감사 쿠폰 | https://forum.nexon.com/maplestoryidle-kr/board_view?board=7418&thread=3372425 | nexon/t/3372425.json, 3372426.json, 3372427.json |
| NX_DEVNOTE_0806 | KR | 2026-08-06 | [개발자 노트] '메키에 바란다' 답변 및 '추가 정보' 공개 | https://forum.nexon.com/maplestoryidle-kr/board_view?board=6633&thread=3517922 | nexon/t/3517922.json |
| IV85 | KR | 2026-09-02 (repost of official 월간 출석 이벤트) | 월간 출석 이벤트 | https://www.inven.co.kr/board/mapleidle/6554/85 | inven/85.html |
| IV114 | KR | 2026-09-02 | 일일·주간 숙제 체크 리스트 | https://www.inven.co.kr/board/mapleidle/6554/114 | inven/114.html |
| IV116 | KR | 2026-09-02 | 초보자를 위한 스펙업 종합 가이드 | https://www.inven.co.kr/board/mapleidle/6554/116 | inven/116.html |
| IV119 | KR | 2026-09-02 | 빠른 사냥 활용법 정리 | https://www.inven.co.kr/board/mapleidle/6554/119 | inven/119.html |
| IV121 | KR | 2026-09-02 | 레드 다이아 사용 우선순위 (주간 상점 표) | https://www.inven.co.kr/board/mapleidle/6554/121 | inven/121.html |
| IV127 | KR | 2026-09-02 | 오프라인 보상 구조 | https://www.inven.co.kr/board/mapleidle/6554/127 | inven/127.html |
| IV130 | KR | 2026-09-02 | 성장 던전 열쇠 관리법 | https://www.inven.co.kr/board/mapleidle/6554/130 | inven/130.html |
| IV136 | KR | 2026-09-02 | 스타포스 주문서는 아레나에서 | https://www.inven.co.kr/board/mapleidle/6554/136 | inven/136.html |
| IV146 | KR | 2026-09-02 | 초보·초반 단계 핫딜 추천과 발동 조건 | https://www.inven.co.kr/board/mapleidle/6554/146 | inven/146.html |
| IV152 | KR | 2026-11-18 (updated) | 메이플 키우기 사용 가능한 쿠폰 모음 | https://www.inven.co.kr/board/mapleidle/6554/152 | inven/152.html |
| IV285 | KR | 2026-09-04 | 아레나 코인 사용처와 구매 우선순위 | https://www.inven.co.kr/board/mapleidle/6554/285 | inven/285.html |
| IV305 | KR | 2026-09-06 | 빠른 사냥 레드 다이아 효율 | https://www.inven.co.kr/board/mapleidle/6554/305 | inven_6554_305.html |
| IV314 | KR | 2026-09-07 | 무과금 유물 획득량/루트 정리 | https://www.inven.co.kr/board/mapleidle/6554/314 | inven/314.html |
| IV317 | KR | 2026-09-07 | 핑크빈 일일 미션 부스트 (~9/20) | https://www.inven.co.kr/board/mapleidle/6554/317 | inven/317.html |
| IV377 | KR | 2026-09-09 | 길드 콘텐츠 가이드 + 보상 정리 | https://www.inven.co.kr/board/mapleidle/6554/377 | inven/377.html |
| IV398 | KR | 2026-09-10 | 콘텐츠/장비 슬롯 해금 순서 정리 | https://www.inven.co.kr/board/mapleidle/6554/398 | inven/398.html |
| IV586 | KR | 2026-09-18 | 여정의 기운은 풀매수 해야할까? | https://www.inven.co.kr/board/mapleidle/6554/586 | inven/586.html |
| IV596 | KR | 2026-09-21 | 초보를 위한 효율적인 용사의 여정 공략 | https://www.inven.co.kr/board/mapleidle/6554/596 | inven/596.html |
| IV604 | KR | 2026-09-22 | [업데이트] 9/22(화) 패치노트 (repost) | https://www.inven.co.kr/board/mapleidle/6554/604 | inven_6554_604.html |
| IV625 | KR | 2026-09-29 | 초보 유저를 위한 메소 수급 방법 정리 | https://www.inven.co.kr/board/mapleidle/6554/625 | inven/625.html |
| IV731 | KR | 2026-10-26 | 1주년 전까지 동료뽑기 얼마나 모을 수 있을까? (레드 다이아 총량) | https://www.inven.co.kr/board/mapleidle/6554/731 | inven/731.html |
| IV735 | KR | 2026-10-27 | 빠른 사냥, 레드 다이아 몇 회까지? | https://www.inven.co.kr/board/mapleidle/6554/735 | inven/735.html |
| IV769 | KR | 2026-11-05 (repost of official 신규 용사 성장 챌린지, thread 3574351) | 신규 용사 성장 챌린지 (~12/16) | https://www.inven.co.kr/board/mapleidle/6554/769 | inven/769.html |
| IV263 | KR | 2026-09-03 | 월요일 콘텐츠 (월드보스 코인으로 미라클/에디셔널 큐브) | https://www.inven.co.kr/board/mapleidle/6554/263 | inven/263.html |
| WIKI_3RDTICKET | global | wiki dump 2026-11-24 | 3rd Job Companion Summoning Ticket | https://idle.maplestorywiki.net/w/3rd_Job_Companion_Summoning_Ticket | ../../idlewiki/wikitext.json |
| WIKI_HEROPOWER | global | wiki dump 2026-11-24 | Hero Power | https://idle.maplestorywiki.net/w/Hero_Power | ../../idlewiki/wikitext.json |
| WIKI_GUILDSKILL | global | wiki dump 2026-11-24 | Guild Member Skills (red diamond costs) | https://idle.maplestorywiki.net/w/Guild_Member_Skills | ../../idlewiki/wikitext.json |
| IV296 | KR | 2026-09-05 | 핑크빈 이벤트 획득 재화 총량 (핑크빈 일일 미션 3종) | https://www.inven.co.kr/board/mapleidle/6554/296 | inven/296.html |
| WIKI_ELITEPT | global | wiki dump 2026-11-24 | Elite Monster Summoning Point (summon cost per level) | https://idle.maplestorywiki.net/w/Elite_Monster_Summoning_Point | ../../idlewiki/wikitext.json |
| IV453 | KR | 2026-09-14 | 월간 출석 완료 핫딜/유물 각성 핫딜 (paid) | https://www.inven.co.kr/board/mapleidle/6554/453 | inven/453.html |
| NX_FAQ_WB | KR | 2025-11-06 | FAQ 월드보스 입장 제한과 규칙 (누적 피해 일회성 보상) | https://forum.nexon.com/maplestoryidle-kr/board_view?board=6730&thread=3210564 | nexon/t/3210564.json |
| DC439725 | KR | 2026-11-15 | 월보코인 → 경쿠/메모리얼 (월드보스 상점 품목) | https://gall.dcinside.com/mgallery/board/view/?id=maplerpg&no=439725 | dc/439725.html |
| IV770 | KR | 2026-11-05 (repost of official, thread 3575656) | 신규 캐릭터 성장 이벤트 1 (~1/6) | https://www.inven.co.kr/board/mapleidle/6554/770 | inven/770.html |
| IV771 | KR | 2026-11-05 (repost of official, thread 3575657) | 신규 캐릭터 성장 이벤트 2 (~1/6) | https://www.inven.co.kr/board/mapleidle/6554/771 | inven/771.html |
| IV774 | KR | 2026-11-05 | 매일 뭘 하면 될까? 1주년 일일 퀘스트 가이드 | https://www.inven.co.kr/board/mapleidle/6554/774 | inven/774.html |
| IV791 | KR | 2026-11 (after 11/5) | 장비 인챈트 추천 옵션·투자 순서·재화 수급 총정리 | https://www.inven.co.kr/board/mapleidle/6554/791 | inven/791.html |
| DC48415 | KR | 2025-11-22 | [정보] 14일 특별 미션 정리 | https://gall.dcinside.com/mgallery/board/view/?id=maplerpg&no=48415 | dc_48415.html |
| DC39138 | KR | 2025-11-18 | 레드다이아 수급이 부족한 이유 (주간상점 합계) | https://gall.dcinside.com/mgallery/board/view/?id=maplerpg&no=39138 | dc/39138.html |
| DC435362 | KR | 2026-11-06 | 지금 무뽑 찐빠 난거아님? (광고 10 / 주간미션 500) | https://gall.dcinside.com/mgallery/board/view/?id=maplerpg&no=435362 | dc/435362.html |
| MEKI_RD | KR site (English page) | not shown | Red Diamond Priority & Sources | https://www.mekifun.com/en/info/red-diamond-priority | mekifun_red_diamond_priority.html |
| MEKI_14D | KR site (English page) | not shown | 14-day special mission | https://www.mekifun.com/en/info/14-day-special-mission | mekifun/14-day-special-mission.html |
| MEKI_PET | KR site (English page) | not shown | Pet Walkway rewards | https://www.mekifun.com/en/info/pet-promenade-guide | mekifun/pet-promenade-guide.html |
| WIKI_QUESTS | global | wiki dump 2026-11-24 | Quests (Special Requests) | https://idle.maplestorywiki.net/w/Quests | ../../idlewiki/wikitext.json["Quests"]; wiki_Quests.html |
| WIKI_GQ | global | wiki dump 2026-11-24 | Guide Quest | https://idle.maplestorywiki.net/w/Guide_Quest | ../../idlewiki/wikitext.json["Guide Quest"] |
| WIKI_PASS | global | last edited 2025-11-25 | Pass | https://idle.maplestorywiki.net/w/Pass | wiki_Pass.html |
| WIKI_HUNT | global | wiki dump 2026-11-24 | Hunting and Offline Rewards | https://idle.maplestorywiki.net/w/Hunting_and_Offline_Rewards | ../../idlewiki/wikitext.json |
| WIKI_MEMBER | global | wiki dump 2026-11-24 | Membership | https://idle.maplestorywiki.net/w/Membership | ../../idlewiki/wikitext.json |
| WIKI_ADREM | global | wiki dump 2026-11-24 | Ad Removal Package (list of ad rewards) | https://idle.maplestorywiki.net/w/Ad_Removal_Package | ../../idlewiki/wikitext.json |
| WIKI_FRIENDS | global | wiki dump 2026-11-24 | Friends | https://idle.maplestorywiki.net/w/Friends | ../../idlewiki/wikitext.json |
| WIKI_ARENA | global | wiki dump 2026-11-24 | Arena | https://idle.maplestorywiki.net/w/Arena | ../../idlewiki/wikitext.json |
| WIKI_GUILDB | global | wiki dump 2026-11-24 | Guild Buildings | https://idle.maplestorywiki.net/w/Guild_Buildings | ../../idlewiki/wikitext.json |
| WIKI_GUILDWAR | global | wiki dump 2026-11-24 | Guild War | https://idle.maplestorywiki.net/w/Guild_War | ../../idlewiki/wikitext.json |
| WIKI_ZAKUM | global | wiki dump 2026-11-24 | Zakum | https://idle.maplestorywiki.net/w/Zakum | ../../idlewiki/wikitext.json |
| WIKI_HJ | global | wiki dump 2026-11-24 | Hero's Journey + Module:HeroJourney/data.json | https://idle.maplestorywiki.net/w/Hero%27s_Journey | ../../idlewiki/wikitext.json; ../../idlewiki/wikitext-other-ns.json |
| WIKI_COUPONS | global | wiki dump 2026-11-24 | Coupons | https://idle.maplestorywiki.net/w/Coupons | ../../idlewiki/wikitext.json |
| WIKI_COLO | global | wiki dump 2026-11-24 | Colosseum | https://idle.maplestorywiki.net/w/Colosseum | ../../idlewiki/wikitext.json |
| WIKI_QH | global | wiki dump 2026-11-24 | Quick Hunt | https://idle.maplestorywiki.net/w/Quick_Hunt | ../../idlewiki/wikitext.json |
| WIKI_GD | global | wiki dump 2026-11-24 | Growth Dungeon | https://idle.maplestorywiki.net/w/Growth_Dungeon | ../../idlewiki/wikitext.json |
| WIKI_BOOST | global | wiki dump 2026-11-24 | Boosters | https://idle.maplestorywiki.net/w/Boosters | ../../idlewiki/wikitext.json |
| WIKI_SUMMON | global | wiki dump 2026-11-24 | Summon / Summon Weapons / Summon Companions | https://idle.maplestorywiki.net/w/Summon | ../../idlewiki/wikitext.json |
| WIKI_WORLDS | global | wiki dump 2026-11-24 | Worlds (server time zones) | https://idle.maplestorywiki.net/w/Worlds | ../../idlewiki/wikitext.json |
| MSI_ATT | global | 2026-07-23 | Monthly Attendance Rewards | https://maplestoryidle.info/guides/monthly-attendance-rewards/ | msi/g_monthly-attendance-rewards.html |
| MSI_JT | global (1.14.0 client) | 2026-08-13 | Journey's Treasure | https://maplestoryidle.info/guides/journey-treasure/ | msi/g_journey-treasure.html |
| MSI_ARENA | global | n/a | Arena and Colosseum Guide (coin shop) | https://maplestoryidle.info/guides/arena-colosseum/ | msi/guides_arena-colosseum_.html |
| MSI_ZAKUM | global | 2026-05-27 table | Boss Raid Zakum reward table | https://maplestoryidle.info/guides/boss-raid-zakum/ | msi/g_boss-raid-zakum.html |
| MSI_LIB | global client 1.14.0 | snapshot 2026-08-13 | Game Data Library (stage kill rewards) | https://maplestoryidle.info/assets/data/game-data-library.json | msi/game-data-library.json |
| SPEC_SHOP | KR client 1.18.0 | 2026-11-05 | regular shop rows (spec/content.json shopAndPaid.regularShop_baselines) | mapleidleindex.com /hotdeal/ hotdeal-catalog.json baselines | ../../../spec/content.json |
| SPEC_WPASS | KR client 1.18.0 | 2026-11-05 | 무기 소환 패스7 steps | mapleidleindex.com js/data/market-information-117.json | ../../js/data/market-information-117.json |

Other local references: `spec/items-gacha.md` (summon/cube/star force/shop data), `spec/content.md` (content inventory; hotdeal text on 탐험 티켓).
