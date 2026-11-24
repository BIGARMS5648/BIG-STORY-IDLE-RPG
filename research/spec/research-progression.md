# 메이플 키우기: progression numbers (research)

Compiled 2026-11-24. This file fills the gaps listed in `combat-stages.md` §8, `items-gacha.md` §13 and `content.md` §8. It does not repeat data those files already hold. The machine-readable copy is `research-progression.json` in the same folder. It holds every table below in full, plus per-stage data. Raw pages are saved under `scratchpad/web/research/progression/`, and the build scripts under `scratchpad/scripts_research/`.

## Sources and how they are cited

| Key | URL | Region | What it is |
|---|---|---|---|
| MK-elite | https://www.mekipick.com/info/elite-monster | KR | Client elite table, 40 levels, embedded in a JS chunk. Fetched 2026-11-24. |
| MK-map | https://www.mekipick.com/info/map | KR | Client stage tables for 47 chapters: KR names, monsters, drops, first-clear rewards |
| MK-comp | https://www.mekipick.com/calculator/companion | KR | SupporterTable extract, "2026-11-15 제공" |
| MK-relic | https://www.mekipick.com/simulator/relic | KR | Artifact chest rates |
| INV-n | https://www.inven.co.kr/board/mapleidle/6554/n | KR | Reposts of official KR patch notes and guides. The posts are marked "출처: 메이플 키우기 공식 커뮤니티". Patch dates are given per row. |
| NV | https://data.novasmc.com/games/maple-idle/system-catalog | KR | System catalog that quotes official patch notes |
| WIKI | https://idle.maplestorywiki.net/w/<page> | global | Wikitext dump plus Module:* JSON |
| MSI | https://maplestoryidle.info/assets/data/game-data-library.json | global | Decoded client v1.14.0, snapshot 2026-08-13 |

The official forum JSON API (`forum.nexon.com/api/v1/board/6698/threads?alias=maplestoryidle`) lists the 20 KR patch notes. However, `/api/v1/thread/<id>` returns `{"errorCode":8,"error":"no contents"}` to anonymous clients, so the patch-note text was taken from the inven reposts instead. mapleidle.gg returned HTTP 429 and was skipped. dcinside searches turned up nothing usable.

## 1. Elite monster summoning (엘리트 몬스터 소환)

**Max level (KR):** 30 → 35 on 2026-02-12 [INV-76], then 35 → 40 on 2026-08-13 [NV elite-summon: "8/13 패치문은 최대35→40을 명시한다"]. The 9/22 medal 「소환의 명장」 requires elite level 40 [INV-604]. The KR client table has exactly 40 levels [MK-elite]. The global wiki shows only 30 levels for costs and 35 levels for rates.

**Grade unlocks:**
- Epic: Lv5
- Unique: Lv13
- Legendary: Lv21
- Legendary+: Lv29 [WIKI Elite_Monsters]
- Mystic: Lv37 (KR data) [MK-elite]

**Rates:** per 10 000, and identical in KR and global for Lv1-35 (checked row by row).

**Field meanings** (KR client field names):
- `Gacha_Cost_Point`: points spent per summon.
- `Drop_Count_Per_Kill`: equipment items dropped per elite kill.
- `Max_Gacha_Gauge`: the cap on stored elite points.
- `Lucky_Spawn_Count`: 1 at every level.
- `Level_Up_Gold_Cost` (meso) and `Level_Up_Delay_Seconds`: shown on the same row as the step costs, exactly as the data gives them. At Lv1 the meso is 0 and the delay is 5 s. The data does not say whether a row is the cost to reach that level or to leave it.

**Level-up flow:** pay `steps × gear stones` (장비 강화석, `GEAR_STONE`), then the meso, then wait out the delay.

**Rules and modifiers:**
- **Simultaneous elites:** the base count is not published. The Special Membership (paid) gives +1 [WIKI Membership]. The KR 성장 챌린지 grade 마스터3 also gives "엘리트 몬스터 동시 소환 마릿수 +1" [INV-772, 2026-11-05].
- **Item level of elite gear:** the base rule is not published. The Premium Membership (paid) gives "+3 level of equipment from Elite Monster summoning" [WIKI Membership]. The KR 챌린저2 grade gives "엘리트 소환 시 획득하는 장비의 레벨 +1" [INV-772].
- **Point cap:** this is `Max_Gacha_Gauge`. The Special Membership adds +100% (global), raised to +200% in KR on 8/13 [INV-88]. The KR challenge grade 골드 adds +100% [INV-772].
- **Refund:** if you move to another dungeon while an elite is alive, the points are refunded [INV-78, 2026-03-19].
- **Drop pool:** no rings or necklaces from elites. Shoulders (어깨) drop only at Epic+ [NV elite-summon, citing the FAQ]. Elites drop only the 8 armor parts (see `items-gacha.md` §2).

**Elite point sources:**

| Source | Amount | Ref |
|---|---|---|
| Chapter hunt drop | 0.25% per kill. 10 pts in ch1, 8 + chapter in ch2 and later (ch47 = 55) | MK-map. WIKI Hunting_and_Offline_Rewards gives the same formula. |
| Chapter trial (도전) first clear | 102 (1-2) … 1 214 (47-19) | MK-map |
| Chapter boss first clear | 300 (ch1), 400 (ch2), then +100 per chapter up to 4 900 (ch47) | MK-map |
| Equipment dungeon | "main F2P source". Amounts per stage are not published. | WIKI Equipment_Dungeon |
| Friends (send/receive) | Amount not published. Events triple it. | WIKI, INV-772 |
| Boss raid with no gear drop | 400 (KR from 9/3, was 200). Global Zakum: 200 at 16% | INV-158, WIKI Zakum |
| Guild shop | 500, twice a week (KR 11/5, was 300 once a week). Needs warehouse Lv4 (global). | INV-772, WIKI Guild_Buildings |
| 성장 챌린지 boss weekly rank | 15 000 (1st) … 1 500 (26-30th) | INV-772 |

**Elite level table** (KR, MK-elite). The per-tier split follows in the second table.

| Lv | pts/summon | drops/kill | max stored pts | level-up meso | level-up time (s) | steps × gear stones | grade split % (KR) |
|---|---|---|---|---|---|---|---|
| 1 | 60 | 2 | 1,500 | 0 | 5 | 2 × 70 | Normal 99.7, Rare 0.3 |
| 2 | 63 | 2 | 1,638 | 1,500 | 5 | 2 × 119 | Normal 99.2, Rare 0.8 |
| 3 | 66 | 3 | 1,782 | 7,800 | 15 | 2 × 202 | Normal 98.2, Rare 1.8 |
| 4 | 69 | 3 | 1,932 | 16,900 | 60 | 2 × 303 | Normal 93.2, Rare 6.8 |
| 5 | 72 | 3 | 2,088 | 29,100 | 600 | 2 × 455 | Normal 89.8, Rare 10.0, Epic 0.2 |
| 6 | 75 | 3 | 2,250 | 44,500 | 1,200 | 3 × 500 | Normal 87.15, Rare 12.5, Epic 0.35 |
| 7 | 79 | 3 | 2,449 | 63,300 | 1,800 | 3 × 625 | Normal 80.8, Rare 18.5, Epic 0.7 |
| 8 | 83 | 3 | 2,656 | 85,700 | 3,600 | 3 × 781 | Normal 73.4, Rare 25.5, Epic 1.1 |
| 9 | 87 | 3 | 2,871 | 111,800 | 5,400 | 3 × 976 | Normal 65.8, Rare 32.5, Epic 1.7 |
| 10 | 91 | 3 | 3,094 | 141,700 | 7,200 | 3 × 1,220 | Normal 53.9, Rare 43.5, Epic 2.6 |
| 11 | 95 | 3 | 3,325 | 175,600 | 9,000 | 4 × 1,300 | Normal 43.3, Rare 52.5, Epic 4.2 |
| 12 | 99 | 3 | 3,564 | 213,500 | 12,600 | 4 × 1,560 | Normal 35.9, Rare 58.5, Epic 5.6 |
| 13 | 103 | 3 | 3,811 | 255,600 | 18,000 | 4 × 1,872 | Normal 26.95, Rare 65.0, Epic 7.9, Unique 0.15 |
| 14 | 107 | 3 | 4,066 | 302,000 | 25,200 | 4 × 2,246 | Normal 19.75, Rare 69.0, Epic 10.95, Unique 0.3 |
| 15 | 111 | 3 | 4,329 | 352,700 | 34,200 | 4 × 2,695 | Normal 10.95, Rare 73.0, Epic 15.5, Unique 0.55 |
| 16 | 115 | 3 | 4,600 | 407,800 | 45,000 | 4 × 3,234 | Normal 8.4, Rare 70.8, Epic 19.95, Unique 0.85 |
| 17 | 119 | 3 | 4,760 | 467,500 | 57,600 | 4 × 3,881 | Normal 4.95, Rare 68.7, Epic 25.0, Unique 1.35 |
| 18 | 123 | 3 | 4,920 | 531,800 | 72,000 | 4 × 4,657 | Normal 2.4, Rare 65.0, Epic 30.75, Unique 1.85 |
| 19 | 128 | 3 | 5,120 | 600,700 | 80,000 | 4 × 5,588 | Rare 59.05, Epic 38.5, Unique 2.45 |
| 20 | 133 | 3 | 5,320 | 674,400 | 96,000 | 4 × 6,706 | Rare 50.85, Epic 46.0, Unique 3.15 |
| 21 | 138 | 3 | 5,520 | 752,900 | 114,000 | 5 × 7,500 | Rare 40.8, Epic 53.0, Unique 6.1, Legendary 0.1 |
| 22 | 143 | 3 | 5,720 | 836,300 | 133,000 | 5 × 9,000 | Rare 33.4, Epic 58.95, Unique 7.4, Legendary 0.25 |
| 23 | 148 | 3 | 5,920 | 924,700 | 154,000 | 5 × 10,800 | Rare 24.0, Epic 65.0, Unique 10.55, Legendary 0.45 |
| 24 | 153 | 3 | 6,120 | 1,018,100 | 177,000 | 5 × 12,960 | Rare 19.1, Epic 66.5, Unique 13.75, Legendary 0.65 |
| 25 | 158 | 3 | 6,320 | 1,116,600 | 201,000 | 5 × 15,552 | Rare 14.0, Epic 66.75, Unique 18.25, Legendary 1.0 |
| 26 | 163 | 3 | 6,520 | 1,220,200 | 227,000 | 5 × 18,662 | Rare 9.1, Epic 64.25, Unique 25.25, Legendary 1.4 |
| 27 | 168 | 3 | 6,720 | 1,329,100 | 255,000 | 5 × 22,394 | Rare 3.8, Epic 61.95, Unique 32.0, Legendary 2.25 |
| 28 | 173 | 3 | 6,920 | 1,443,200 | 284,000 | 5 × 26,873 | Rare 1.75, Epic 51.5, Unique 44.0, Legendary 2.75 |
| 29 | 179 | 3 | 7,160 | 1,562,700 | 315,000 | 5 × 32,248 | Epic 41.15, Unique 53.0, Legendary 5.75, Legendary+ 0.1 |
| 30 | 185 | 3 | 7,400 | 1,687,500 | 347,000 | 6 × 38,698 | Epic 33.4, Unique 58.95, Legendary 7.4, Legendary+ 0.25 |
| 31 | 191 | 3 | 7,640 | 1,817,800 | 381,000 | 6 × 46,438 | Epic 24.0, Unique 65.0, Legendary 10.55, Legendary+ 0.45 |
| 32 | 197 | 3 | 7,880 | 1,953,600 | 417,000 | 6 × 55,726 | Epic 19.1, Unique 66.5, Legendary 13.75, Legendary+ 0.65 |
| 33 | 203 | 3 | 8,120 | 2,094,900 | 454,000 | 6 × 66,871 | Epic 14.0, Unique 66.75, Legendary 18.25, Legendary+ 1.0 |
| 34 | 209 | 3 | 8,360 | 2,241,800 | 493,000 | 6 × 80,245 | Epic 9.1, Unique 64.25, Legendary 25.25, Legendary+ 1.4 |
| 35 | 215 | 3 | 8,600 | 2,394,300 | 533,000 | 6 × 96,294 | Epic 3.8, Unique 61.95, Legendary 32.0, Legendary+ 2.25 |
| 36 | 221 | 3 | 8,840 | 2,552,500 | 561,800 | 6 × 115,553 | Epic 1.75, Unique 51.5, Legendary 44.0, Legendary+ 2.75 |
| 37 | 227 | 3 | 9,080 | 2,716,500 | 590,600 | 6 × 138,664 | Unique 41.15, Legendary 53.0, Legendary+ 5.75, Mystic 0.1 |
| 38 | 234 | 3 | 9,360 | 2,886,300 | 619,400 | 6 × 166,397 | Unique 33.4, Legendary 58.95, Legendary+ 7.4, Mystic 0.25 |
| 39 | 241 | 3 | 9,640 | 3,061,900 | 648,200 | 6 × 199,676 | Unique 24.0, Legendary 65.0, Legendary+ 10.55, Mystic 0.45 |
| 40 | 248 | 3 | 9,920 | 3,243,400 | 677,000 | 7 × 239,611 | Unique 19.1, Legendary 66.5, Legendary+ 13.75, Mystic 0.65 |

**Per-tier rates per level** (KR = global wiki for Lv1-35).

| Lv | tier rates (per 10000; T4 = 하급 lowest … T1 = 최상급) |
|---|---|
| 1 | Normal T4 8985, Normal T3 835, Normal T2 100, Normal T1 50, Rare T4 30 |
| 2 | Normal T4 6350, Normal T3 2570, Normal T2 750, Normal T1 250, Rare T4 50, Rare T3 30 |
| 3 | Normal T4 4120, Normal T3 3700, Normal T2 1500, Normal T1 500, Rare T4 100, Rare T3 50, Rare T2 30 |
| 4 | Normal T4 3070, Normal T3 3500, Normal T2 1750, Normal T1 1000, Rare T4 500, Rare T3 100, Rare T2 50, Rare T1 30 |
| 5 | Normal T4 2530, Normal T3 3250, Normal T2 2000, Normal T1 1200, Rare T4 600, Rare T3 250, Rare T2 100, Rare T1 50, Epic T4 20 |
| 6 | Normal T4 2165, Normal T3 2800, Normal T2 2400, Normal T1 1350, Rare T4 700, Rare T3 325, Rare T2 150, Rare T1 75, Epic T4 35 |
| 7 | Normal T4 1390, Normal T3 2090, Normal T2 3000, Normal T1 1600, Rare T4 1000, Rare T3 500, Rare T2 250, Rare T1 100, Epic T4 50, Epic T3 20 |
| 8 | Normal T4 995, Normal T3 1800, Normal T2 2000, Normal T1 2545, Rare T4 1350, Rare T3 750, Rare T2 300, Rare T1 150, Epic T4 75, Epic T3 35 |
| 9 | Normal T4 690, Normal T3 1500, Normal T2 1890, Normal T1 2500, Rare T4 1500, Rare T3 1000, Rare T2 500, Rare T1 250, Epic T4 100, Epic T3 50, Epic T2 20 |
| 10 | Normal T4 345, Normal T3 1070, Normal T2 1725, Normal T1 2250, Rare T4 2000, Rare T3 1350, Rare T2 700, Rare T1 300, Epic T4 150, Epic T3 75, Epic T2 35 |
| 11 | Normal T4 240, Normal T3 500, Normal T2 1500, Normal T1 2090, Rare T4 2250, Rare T3 1600, Rare T2 1000, Rare T1 400, Epic T4 250, Epic T3 100, Epic T2 50, Epic T1 20 |
| 12 | Normal T4 95, Normal T3 350, Normal T2 1345, Normal T1 1800, Rare T4 2100, Rare T3 2000, Rare T2 1100, Rare T1 650, Epic T4 300, Epic T3 150, Epic T2 75, Epic T1 35 |
| 13 | Normal T3 195, Normal T2 1000, Normal T1 1500, Rare T4 2000, Rare T3 2500, Rare T2 1200, Rare T1 800, Epic T4 400, Epic T3 250, Epic T2 100, Epic T1 40, Unique T4 15 |
| 14 | Normal T3 100, Normal T2 625, Normal T1 1250, Rare T4 1750, Rare T3 2225, Rare T2 1925, Rare T1 1000, Epic T4 550, Epic T3 325, Epic T2 150, Epic T1 70, Unique T4 30 |
| 15 | Normal T2 195, Normal T1 900, Rare T4 1600, Rare T3 2000, Rare T2 2500, Rare T1 1200, Epic T4 800, Epic T3 400, Epic T2 250, Epic T1 100, Unique T4 40, Unique T3 15 |
| 16 | Normal T2 90, Normal T1 750, Rare T4 1555, Rare T3 1900, Rare T2 2275, Rare T1 1350, Epic T4 1000, Epic T3 575, Epic T2 300, Epic T1 120, Unique T4 55, Unique T3 30 |
| 17 | Normal T1 495, Rare T4 1500, Rare T3 1870, Rare T2 2000, Rare T1 1500, Epic T4 1200, Epic T3 800, Epic T2 350, Epic T1 150, Unique T4 80, Unique T3 40, Unique T2 15 |
| 18 | Normal T1 240, Rare T4 1150, Rare T3 1650, Rare T2 1950, Rare T1 1750, Epic T4 1350, Epic T3 1000, Epic T2 500, Epic T1 225, Unique T4 100, Unique T3 55, Unique T2 30 |
| 19 | Rare T4 535, Rare T3 1570, Rare T2 1800, Rare T1 2000, Epic T4 1500, Epic T3 1200, Epic T2 800, Epic T1 350, Unique T4 125, Unique T3 65, Unique T2 40, Unique T1 15 |
| 20 | Rare T4 325, Rare T3 1260, Rare T2 1600, Rare T1 1900, Epic T4 1850, Epic T3 1375, Epic T2 875, Epic T1 500, Unique T4 150, Unique T3 80, Unique T2 55, Unique T1 30 |
| 21 | Rare T4 160, Rare T3 870, Rare T2 1250, Rare T1 1800, Epic T4 2100, Epic T3 1600, Epic T2 1000, Epic T1 600, Unique T4 350, Unique T3 150, Unique T2 75, Unique T1 35, Legendary T4 10 |
| 22 | Rare T4 90, Rare T3 650, Rare T2 1000, Rare T1 1600, Epic T4 1950, Epic T3 1900, Epic T2 1270, Epic T1 775, Unique T4 400, Unique T3 200, Unique T2 100, Unique T1 40, Legendary T4 25 |
| 23 | Rare T3 185, Rare T2 815, Rare T1 1400, Epic T4 1800, Epic T3 2100, Epic T2 1600, Epic T1 1000, Unique T4 500, Unique T3 350, Unique T2 150, Unique T1 55, Legendary T4 35, Legendary T3 10 |
| 24 | Rare T3 90, Rare T2 650, Rare T1 1170, Epic T4 1500, Epic T3 2200, Epic T2 1675, Epic T1 1275, Unique T4 700, Unique T3 425, Unique T2 175, Unique T1 75, Legendary T4 40, Legendary T3 25 |
| 25 | Rare T2 450, Rare T1 950, Epic T4 1325, Epic T3 2000, Epic T2 1750, Epic T1 1600, Unique T4 1000, Unique T3 500, Unique T2 200, Unique T1 125, Legendary T4 55, Legendary T3 35, Legendary T2 10 |
| 26 | Rare T2 230, Rare T1 680, Epic T4 1225, Epic T3 1525, Epic T2 2000, Epic T1 1675, Unique T4 1275, Unique T3 750, Unique T2 350, Unique T1 150, Legendary T4 75, Legendary T3 40, Legendary T2 25 |
| 27 | Rare T1 380, Epic T4 800, Epic T3 1340, Epic T2 2255, Epic T1 1800, Unique T4 1500, Unique T3 1000, Unique T2 500, Unique T1 200, Legendary T4 125, Legendary T3 55, Legendary T2 35, Legendary T1 10 |
| 28 | Rare T1 175, Epic T4 550, Epic T3 825, Epic T2 1775, Epic T1 2000, Unique T4 1950, Unique T3 1550, Unique T2 650, Unique T1 250, Legendary T4 150, Legendary T3 60, Legendary T2 40, Legendary T1 25 |
| 29 | Epic T4 195, Epic T3 870, Epic T2 1250, Epic T1 1800, Unique T4 2100, Unique T3 1600, Unique T2 1000, Unique T1 600, Legendary T4 350, Legendary T3 150, Legendary T2 50, Legendary T1 25, Legendary+ T4 10 |
| 30 | Epic T4 90, Epic T3 650, Epic T2 1000, Epic T1 1600, Unique T4 1950, Unique T3 1900, Unique T2 1270, Unique T1 775, Legendary T4 400, Legendary T3 200, Legendary T2 100, Legendary T1 40, Legendary+ T4 25 |
| 31 | Epic T3 185, Epic T2 815, Epic T1 1400, Unique T4 1800, Unique T3 2100, Unique T2 1600, Unique T1 1000, Legendary T4 500, Legendary T3 350, Legendary T2 150, Legendary T1 55, Legendary+ T4 35, Legendary+ T3 10 |
| 32 | Epic T3 90, Epic T2 650, Epic T1 1170, Unique T4 1500, Unique T3 2200, Unique T2 1675, Unique T1 1275, Legendary T4 700, Legendary T3 425, Legendary T2 175, Legendary T1 75, Legendary+ T4 40, Legendary+ T3 25 |
| 33 | Epic T2 450, Epic T1 950, Unique T4 1325, Unique T3 2000, Unique T2 1750, Unique T1 1600, Legendary T4 1000, Legendary T3 500, Legendary T2 200, Legendary T1 125, Legendary+ T4 55, Legendary+ T3 35, Legendary+ T2 10 |
| 34 | Epic T2 230, Epic T1 680, Unique T4 1225, Unique T3 1525, Unique T2 2000, Unique T1 1675, Legendary T4 1275, Legendary T3 750, Legendary T2 350, Legendary T1 150, Legendary+ T4 75, Legendary+ T3 40, Legendary+ T2 25 |
| 35 | Epic T1 380, Unique T4 800, Unique T3 1340, Unique T2 2255, Unique T1 1800, Legendary T4 1500, Legendary T3 1000, Legendary T2 500, Legendary T1 200, Legendary+ T4 125, Legendary+ T3 55, Legendary+ T2 35, Legendary+ T1 10 |
| 36 | Epic T1 175, Unique T4 550, Unique T3 825, Unique T2 1775, Unique T1 2000, Legendary T4 1950, Legendary T3 1550, Legendary T2 650, Legendary T1 250, Legendary+ T4 150, Legendary+ T3 60, Legendary+ T2 40, Legendary+ T1 25 |
| 37 | Unique T4 195, Unique T3 770, Unique T2 1350, Unique T1 1800, Legendary T4 2100, Legendary T3 1600, Legendary T2 1000, Legendary T1 600, Legendary+ T4 350, Legendary+ T3 140, Legendary+ T2 50, Legendary+ T1 35, Mystic T4 10 |
| 38 | Unique T4 90, Unique T3 650, Unique T2 1000, Unique T1 1600, Legendary T4 1950, Legendary T3 1900, Legendary T2 1270, Legendary T1 775, Legendary+ T4 400, Legendary+ T3 200, Legendary+ T2 100, Legendary+ T1 40, Mystic T4 25 |
| 39 | Unique T3 185, Unique T2 815, Unique T1 1400, Legendary T4 1800, Legendary T3 2100, Legendary T2 1600, Legendary T1 1000, Legendary+ T4 500, Legendary+ T3 350, Legendary+ T2 150, Legendary+ T1 55, Mystic T4 35, Mystic T3 10 |
| 40 | Unique T3 90, Unique T2 650, Unique T1 1170, Legendary T4 1500, Legendary T3 2200, Legendary T2 1675, Legendary T1 1275, Legendary+ T4 700, Legendary+ T3 425, Legendary+ T2 175, Legendary+ T1 75, Mystic T4 40, Mystic T3 25 |

**Conflict: global wiki vs KR.** The level-up meso and time differ for levels 11-27. The wiki also has no steps at L30, because L30 was the maximum level when it was written. Both versions are in the JSON (`levels[].globalWiki`).

| Lv | global wiki meso | global wiki time | KR meso | KR time (s) |
|---|---|---|---|---|
| 11 | 175,800 | 04:00:00 | 175,600 | 9,000 |
| 12 | 214,800 | 06:00:00 | 213,500 | 12,600 |
| 13 | 259,500 | 08:00:00 | 255,600 | 18,000 |
| 14 | 310,700 | 12:00:00 | 302,000 | 25,200 |
| 15 | 369,200 | 18:00:00 | 352,700 | 34,200 |
| 16 | 435,800 | 24:00:00 | 407,800 | 45,000 |
| 17 | 511,600 | 30:00:00 | 467,500 | 57,600 |
| 18 | 597,700 | 36:00:00 | 531,800 | 72,000 |
| 19 | 695,500 | 42:00:00 | 600,700 | 80,000 |
| 20 | 806,700 | 48:00:00 | 674,400 | 96,000 |
| 21 | 933,200 | 54:00:00 | 752,900 | 114,000 |
| 22 | 1,076,900 | 60:00:00 | 836,300 | 133,000 |
| 23 | 1,240,300 | 66:00:00 | 924,700 | 154,000 |
| 24 | 1,426,100 | 72:00:00 | 1,018,100 | 177,000 |
| 25 | 1,637,300 | 78:00:00 | 1,116,600 | 201,000 |
| 26 | 1,876,900 | 84:00:00 | 1,220,200 | 227,000 |
| 27 | 2,147,900 | 90:00:00 | 1,329,100 | 255,000 |

## 2. Equipment acquisition, dismantle, gear stones

- **Where equipment comes from:**
  - Elite summon: 8 armor parts.
  - Party quests: 반지1, 목걸이, 얼굴장식, 반지2.
  - Boss raids: the accessories listed in `items-gacha.md` §11.
  - Paid hot deals.
  - Chapter hunting never drops equipment. Its whole drop table is listed in §6 [MK-map, WIKI maps.json].
- **Dismantle (분해):**
  - Bulk dismantle with a filter unlocks after the chapter 15 boss (KR 7/2) [INV-83].
  - There is also an auto-dismantle option, whose grade filter was made easier to unlock on 2/12 [INV-76].
  - Gear with option conversion or an enchant is excluded from bulk and auto dismantle (11/5) [INV-772].
  - Dismantled gear cannot be restored [NV, FAQ].
  - **Dismantle yield: NOT FOUND.** No source lists what dismantling returns.
- **Gear stones (장비 강화석, `GEAR_STONE`):**
  - Used only for elite summon level steps (§1).
  - **Income: NOT FOUND.** Dismantling is the likely source, but this is unconfirmed.
  - The global wiki calls them "Armor Stones" / "Gear Stones".
- **Armor materials:** besides gear stones, the remaining armor materials are already covered in `items-gacha.md`: star force scrolls, cubes, spell traces, sub-option conversion stones and enchant pouches.

## 3. Companions (동료): level-up and promotion

Source: MK-comp (KR SupporterTable extract, 2026-11-15). The formula is the site's own code.
`copies(L→L+1) = min(beginCost + floor((L−1)/costGap) × costAdd, maxCost)` for 1 ≤ L < maxLevel. The first copy, which unlocks the companion, is separate.

| Grade | Max Lv | beginCost | costGap | costAdd | maxCost | Copies Lv1→max | Promotion (승급) copies → next grade |
|---|---|---|---|---|---|---|---|
| 노말 Normal | 100 | 5 | 1 | 3 | 500 | 15 048 (5, 8, 11 … 299) | 300 → 레어 |
| 레어 Rare | 50 | 1 | 1 | 2 | 300 | 2 401 (1, 3, 5 … 97) | 100 → 에픽 |
| 에픽 Epic | 30 | 1 | 1 | 1 | 100 | 435 (1 … 29) | 30 → 유니크 |
| 유니크 Unique | 10 | 1 | 2 | 1 | 100 | 25 (1, 1, 2, 2 … 5) | 20 → 레전드리 |
| 레전드리 Legendary | 18 | 1 | 3 | 1 | 100 | 57 (1, 1, 1, 2 … 6) | — |

- **Legendary max level history (KR):**
  - 10 → 12 on 2026-01-29. Unique stays at 10, and its equip effect gets ×1.1 instead [INV-75].
  - 12 → 14 on 2026-04-30 [INV-80].
  - 14 → 16 on 2026-07-23 [INV-84].
  - 16 → 18 on 2026-11-05 [INV-772].
- **Promotion:** it consumes owned companions of the same grade evenly (12/18 change; a bug was fixed on 9/22) [INV-604].
- **Slots:** 1 main companion and 6 subs [WIKI Companions].
  - The subs unlock at companion summon levels 3, 4, 5, 6, 7 and 8 [MK-comp `subSlots`].
  - Sub companions apply 100% of their equip effect.
  - The main companion is summoned for 30 s with a 90 s cooldown.
- **Per-level stat factors:** the factor table (1000-based, 14 curves) and all 69 companion definitions are in the JSON (`companions.perLevelStatFactors`, `companionDefs`).
  - Each definition has its collection (보유), equip, link (계승 공격력) and skills.
  - Stat value = trunc(base × factor[level−1][curve] / 1000).

## 4. Weapons: level cost, awakening, promotion, mastery

- **Level cost (global wiki, Weapons):** base cost by tier, in weapon enhancers:
  - Normal T4: 10
  - Rare T4: 40
  - Epic T4: 140
  - Unique T4: 490
  - Legendary T4: 1 470
  - Mystic T4: 5 880
  - Ancient T4: 23 520
  - Within a grade, each tier is ×1.2 (T3, T2, T1).
  - Multipliers by level band:
    - Lv1-50: ×1.01^(L−1)
    - Lv51-100: then ×1.015 per level
    - Lv101-150: then ×1.02 per level
    - Lv151-200: then ×1.025 per level
  - The cost is rounded up.
  - The full per-level stone totals are already in `items-gacha.md` §4. They come from the KR client and match this formula.
- **Attack scaling (wiki):**
  - Lv1-100: base × (0.997 + 0.003·L)
  - Lv101-130: base × (0.596 + 0.007·L)
  - Lv131-155: base × (0.466 + 0.008·L)
  - Lv156-175: base × (0.311 + 0.009·L)
  - Lv176-200: base × (0.136 + 0.01·L)
  - Inventory effect = equip ÷ 3.5 (Normal T4 to Unique T1), or ÷ 4 (Legendary T4 and up).
- **Awakening:**
  - Duplicates raise the awakening stage, up to 5. Each stage adds +20 to the max level (100 → 200) [WIKI Weapons].
  - **Duplicates per stage: NOT FOUND** on any allowed host. One web-search snippet (roonby.com, not an allowed host, not fetched) says "5 copies per star". It is unverified.
- **Promotion:**
  - 5 copies of a stage-5-awakened weapon become 1 weapon of the next tier [WIKI Weapons].
  - KR 10/15: Ancient 최상급 ×5 → Eternity 하급 ×1 [INV-679].
- **Weapon mastery (무기 마스터리):** it exists. A KR notice from 3/5, quoted by NV, mentions "무기 마스터리 습득 상태". **No values were found.** The wiki page "Weapon Mastery" is a different thing: a Hero/Dark Knight skill (+0.3% min damage per level).
- **Merge (합성):** no weapon merge exists apart from promotion. The 9/3 "유물 합성" is an artifact system [NV relic-synthesis].


## 5. Meso (메소): income, multipliers, sinks

**Income**

| Source | Amount | Ref |
|---|---|---|
| Chapter hunt | 7% per kill. 40 meso in ch1-2, then 38 + chapter (ch47 = 85, KR) | MK-map. WIKI Hunting_and_Offline_Rewards gives the same formula. |
| Chapter trial first clear | 4 000 (1-2), 8 000-13 000 (ch2) … 759 300-784 800 (ch47) | MK-map (all 508 rows in the JSON) |
| 여정의 보물 meso card | 4 000 000-8 000 000, depending on the card step (1-5) | INV-625 (2026-09-29 guide) |
| Boss raid with no gear drop | 100 000 (KR from 9/3, was 50 000). Global Zakum: 50 000 at 35% | INV-158, WIKI Zakum |
| Red-diamond shop | 1 500 red → 300 000 meso | INV-625 |
| Quick hunt, offline, PQ, world boss rewards, arena coin shop, colosseum, events | Amounts not published | INV-625 |

**Meso rate modifiers**
- **Rounding:** online, meso% is applied and floored per drop. Offline, it is floored once at the end, before premium [WIKI Hunting_and_Offline_Rewards].
- **Boosters (global):**
  - Daily Ad Booster: +100% EXP and +150% meso for 20 min.
  - Meso boosters: +100/150/200% for 10 min [WIKI Boosters].
- **World Boss weekly benefit (global):**
  - Expert: +8%
  - Professional: +16%
  - Ace: +19% meso, +5% item
  - Lord: +22% meso, +10% item
  - Overlord: +25% meso, +15% (or +10%) item [WIKI Boosters]
- **Costume collection cap (KR 3/19):** meso 20% → 40%, EXP 10% → 20%, main stat 1 500 → 3 000 [INV-78].
- **Guild 토벌전 noblesse (KR 11/5):**
  - 골드: +2% meso
  - 플래티넘: +6%
  - 다이아몬드 and up: +10% [INV-772]
- **Guild War rank (global):**
  - 1st: +16% EXP and meso for 7 days
  - 2nd: +13%
  - 3rd: +10% [WIKI Guild_War]

**Meso sinks**
- **Elite summon level-ups (§1):** the sum of every KR row is 41 338 200 meso. Gear stones across all rows total 8 634 154.
- **Star force, cubes, sub-option conversion:** see `items-gacha.md`.
- **Enchant scrolls (KR 11/5):** meso per try [INV-772]:
  - 레어: 20 000
  - 에픽: 50 000
  - 유니크: 70 000
  - 레전드리: 100 000
  - 미스틱: 150 000
- **Hero's Journey trail:** opening costs meso plus tokens, e.g. ch20 = 674 400 meso + 60 300 tokens; option change = 5 000 meso + 1 900 tokens (§7).
- **Scroll enhancement:** "+메소" per try, but the amounts are not published.

## 6. Character base stats, damage taken, death

- **Base HP/ATK/DEF per level: NOT FOUND.**
  - No source (MK, MSI, mapleidleindex, wiki) publishes the per-level base stats.
  - No AP / stat-point system exists in any source.
  - Character level only feeds: skill levels (`combat-stages.md`), the item options "1레벨당 주 스탯" and "4레벨당 주 스탯%", and companion `link` scaling.
  - Medals: +30 main stat each, capped at 1 500 main stat from medals (global) [WIKI Medals].
  - Costume collection: up to 3 000 main stat (KR).
- **Damage taken by the player: the formula is NOT FOUND.**
  - The wiki only says this: "damage taken after being reduced by your Defense is further reduced by" Damage Taken Decrease. That reduction is chained and capped at 95%. Critical Resistance lowers the attacker's crit rate [WIKI Character_Stats].
  - The monster-side DEF formula, 5000/(DEF+6000) in `combat-stages.md`, is **not** confirmed to apply to the player.
  - Known special cases:
    - 마왕 발록 deals fixed damage proportional to max HP [INV-772].
    - On 8/13, damage taken in raids, PQ and growth dungeons was lowered (no numbers given) [INV-88].
    - Monster ATK in chapters 24+ was lowered by up to about 54% [NV chapter].
- **Death and retry in chapter hunting (MSI, client v1.14.0):**
  - Stage 1-1 has `NoUserDie`. Every other hunt stage has `ExitToRetry`: on death you leave the fight and the stage restarts.
  - Players can die while idle: the 2/26 fix corrected how elapsed time is counted after a death [INV-77].
  - Trials (도전) use `RushMode`: the clear type is `RushDefence` with a 60 s limit, plus a `max_acc_monster_count` per stage (5 and 10 in ch1, 60 in ch47, all values in the JSON).
  - Chapter bosses use KillBoss or KillAllEnemies:
    - Time limits: 70 s, except ch1 30 s, ch2 25 s, ch3 40 s and ch4 55 s.
    - `CannotRepeat` applies after the first clear.
- **Revives:**
  - Zakum party: Easy 15, Normal 12, Hard 10, shared by the party [WIKI Zakum].
  - Every raid in single mode: 8 [INV-158].
  - Pink Bean party: 15 (`content.md`).


## 7. Chapters: KR names, monsters, first-clear rewards, hunt drops

Source: MK-map (KR client). The EN names for ch1-41 come from the global wiki `Module:Dungeons/maps.json`.
- **Chapter boss first-clear rewards:**
  - Red diamonds: 500 (ch1), 750 (ch2), then +250 per chapter up to 12 000 (ch47).
  - Elite points: 300 … 4 900.
  - Weapon summon tickets: 50 (ch2), then +25 per chapter up to 1 175 (ch47).
  - Time tickets (1 min): 20 … 470.
- **Currency naming:** `FreeDia` = 레드 다이아. MSI labels the same code "Blue Diamond", which conflicts with this.
- **Trial (도전) first-clear rewards:**
  - Red diamonds: 100-500.
  - Meso, elite points and EXP: these rise every stage.
  - From ch2 on, also 20 weapon summon tickets and 4 000-11 360 weapon stones.
- **Per-stage data:** monster names for every stage and all 508 trial rows are in the JSON (`chapters.chapters[].huntStageMonsters` and `trialFirstClearRewards`). So are the field stats of the elite boss and minion per stage (`eliteFieldStats`).

| Ch | 한국어 (KR) | global EN | hunt / trial | monsters (KR, first 6) | chapter boss (KR) | boss time | boss first-clear rewards |
|---|---|---|---|---|---|---|---|
| 1 | 메이플 아일랜드 | 1. Maple Island | 3 / 2 | 달팽이, 파란 달팽이, 빨간 달팽이, 스텀프 | 마노 | 30 s | red 500, elitePt 300 |
| 2 | 헤네시스 | 2. Henesys | 7 / 6 | 빨간 달팽이, 파란 달팽이, 스포아, 슬라임, 주황버섯, 돼지 | 블루 머쉬맘 | 25 s | red 750, elitePt 400, wpnTicket 50, timeTicket 20 |
| 3 | 엘리니아 | 3. Ellinia | 9 / 8 | 슬라임, 달팽이, 초록버섯, 버블링, 파란버섯, 페어리 | 파우스트 | 40 s | red 1,000, elitePt 500, wpnTicket 75, timeTicket 30 |
| 4 | 페리온 | 4. Perion | 9 / 8 | 스텀프, 초록버섯, 빨간 달팽이, 엑스텀프, 다크 스텀프, 다크 엑스텀프 | 스텀피 | 55 s | red 1,250, elitePt 600, wpnTicket 100, timeTicket 40 |
| 5 | 커닝시티 | 5. Kerning City | 9 / 8 | 주황버섯, 옥토퍼스, 스텀프, 파란버섯, 다크 스텀프, 엑스텀프 | 다일 | 70 s | red 1,500, elitePt 700, wpnTicket 125, timeTicket 50 |
| 6 | 플로리나비치 | 6. Florina Beach | 9 / 8 | 루팡, 로랑, 클랑, 엄티 | 킹크랑 | 70 s | red 1,750, elitePt 800, wpnTicket 150, timeTicket 60 |
| 7 | 슬리피우드 | 7. Sleepywood | 9 / 8 | 좀비버섯, 짜증내는 좀비버섯, 스티지, 주니어 부기, 레드 드레이크, 이블아이 | 좀비 머쉬맘 | 70 s | red 2,000, elitePt 900, wpnTicket 175, timeTicket 70 |
| 8 | 페리온 발굴지역 | 8. Perion Excavation Area | 9 / 8 | 스톤 마스크, 우드 마스크, 스켈독, 머미독, 스켈레톤 사병, 스켈레톤 지휘관 | 스켈레톤 총사령관 | 70 s | red 2,250, elitePt 1,000, wpnTicket 200, timeTicket 80 |
| 9 | 슬리피우드 던전 | 9. Sleepywood Dungeon | 9 / 8 | 와일드카고, 콜드아이, 아이스 드레이크, 다크 드레이크, 타우로마시스, 타우로스피어 | 주니어 발록 | 70 s | red 2,500, elitePt 1,100, wpnTicket 225, timeTicket 90 |
| 10 | 오르비스 | 10. Orbis | 9 / 8 | 주니어 샐리온, 스타픽시, 주니어 라이오너, 주니어 그류핀, 라이오너, 샐리온 | 엘리쟈 | 70 s | red 2,750, elitePt 1,200, wpnTicket 250, timeTicket 100 |
| 11 | 오르비스 탑 | 11. Orbis Tower | 9 / 8 | 스톤볼, 주니어 스톤볼, 파이어 스톤볼, 리티, 아이스 스톤볼 | 픽시맘 | 70 s | red 3,000, elitePt 1,300, wpnTicket 275, timeTicket 110 |
| 12 | 엘나스 | 12. El Nath | 9 / 8 | 다크 리티, 리티, 주니어 페페, 헥터, 페페, 화이트팽 | 스노우맨 | 70 s | red 3,250, elitePt 1,400, wpnTicket 300, timeTicket 120 |
| 13 | 엘나스 폐광 | 13. El Nath Abandoned Mine | 9 / 8 | 라이칸스로프, 웨어울프, 마이너 좀비, 쿨리 좀비, 플라이아이, 주니어 불독 | 리치 | 70 s | red 3,500, elitePt 1,500, wpnTicket 325, timeTicket 130 |
| 14 | 아쿠아리움 | 14. Aquarium | 9 / 8 | 크라피, 씨코, 씨클, 크립, 플라워 피쉬, 주니어 씰 | 세르프 | 70 s | red 3,750, elitePt 1,600, wpnTicket 350, timeTicket 140 |
| 15 | 루디브리엄 에오스탑 | 15. Ludibrium Eos Tower | 9 / 8 | 블랙 라츠, 라츠, 블록퍼스, 북치는 토끼, 킹 블록퍼스, 브라운테니 | 롬바드 | 70 s | red 4,000, elitePt 1,700, wpnTicket 375, timeTicket 150 |
| 16 | 루디브리엄 성 | 16. Ludibrium Castle | 9 / 8 | 북치는 토끼, 브라운테니, 팬더테니, 핑크테니, 장난감 목마, 더키 패밀리 | 타이머 | 70 s | red 4,250, elitePt 1,800, wpnTicket 400, timeTicket 160 |
| 17 | 루디브리엄 시계탑최하층 | 17. Ludibrium Clocktower Lower Floors | 9 / 8 | 티키, 크로노스, 틱톡, 마스터 크로노스, 플래툰 크로노스, 레이지 버피 | 타나토스 | 70 s | red 4,500, elitePt 1,900, wpnTicket 425, timeTicket 170 |
| 18 | 지구방위본부 | 18. Omega Sector | 9 / 8 | 플라티안, 마티안, 메카티안, 바나드 그레이, 울트라 그레이, 뉴그레이 블랙 | 제노 | 70 s | red 4,750, elitePt 2,000, wpnTicket 450, timeTicket 180 |
| 19 | 아쿠아리움 심해 | 19. Aquarium Deep Sea | 9 / 8 | 리셀스퀴드, 스퀴드, 샤크, 콜드샤크, 플라이아이 | 피아누스 | 70 s | red 5,000, elitePt 2,100, wpnTicket 475, timeTicket 190 |
| 20 | 아랫마을 입구 | 20. Korean Folk Town Entrance | 9 / 8 | 다크 엑스텀프, 월묘, 호돌이, 호걸, 삼미호, 깨비 | 요미 | 70 s | red 5,250, elitePt 2,200, wpnTicket 500, timeTicket 200 |
| 21 | 아랫마을 깊은산 | 21. Korean Folk Town Forest | 9 / 8 | 파란 왕도깨비, 깨비, 초록 왕도깨비, 노란 왕도깨비 | 선비귀신 | 70 s | red 5,500, elitePt 2,300, wpnTicket 525, timeTicket 210 |
| 22 | 아리안트 | 22. Ariant | 9 / 8 | 갈색 모래토끼, 흰 모래토끼, 주니어 카투스, 카투스, 로얄 카투스, 귀마개 프릴드 | 데우 | 70 s | red 5,750, elitePt 2,400, wpnTicket 550, timeTicket 220 |
| 23 | 마가티아 연구소 | 23. Magatia Research Center | 9 / 8 | 루모, 큐브슬라임, 트리플 루모, 아이언 뮤테, 강화된 아이언 뮤테, 강화된 미스릴 뮤테 | 루루모 | 70 s | red 6,000, elitePt 2,500, wpnTicket 575, timeTicket 230 |
| 24 | 마가티아 실험실 | 24. Magatia Lab | 9 / 8 | 호문쿨루, 호문, 호문스큘러, 사이티, 로이드, 네오 휴로이드 | 자동경비시스템 | 70 s | red 6,250, elitePt 2,600, wpnTicket 600, timeTicket 240 |
| 25 | 리프레 미나르숲 | 25. Leafre Minar Forest | 9 / 8 | 듀얼 비틀, 비틀, 헹키, 레쉬, 호브, 블러드 하프 | 그리프 | 70 s | red 6,500, elitePt 2,700, wpnTicket 625, timeTicket 250 |
| 26 | 리프레 용의둥지 | 26. Leafre Dragon Nest | 9 / 8 | 붉은 켄타우로스, 검은 켄타우로스, 푸른 켄타우로스, 버크, 듀얼 버크, 마스터 버크 | 레비아탄 | 70 s | red 6,750, elitePt 2,800, wpnTicket 650, timeTicket 260 |
| 27 | 무릉도원 | 27. Mu Lung Garden | 9 / 8 | 묘선, 비급, 흑저, 별다람쥐, 천록, 원공 | 태륜 | 70 s | red 7,000, elitePt 2,900, wpnTicket 675, timeTicket 270 |
| 28 | 백초마을 | 28. Herb Town | 9 / 8 | 삼단지, 단지, 도라지, 늙은 도라지, 게비알, 크루 | 거대 도라지 | 70 s | red 7,250, elitePt 3,000, wpnTicket 700, timeTicket 280 |
| 29 | 무릉도원 깊은 곳 | Deep in Mu Lung Garden | 14 / 13 | 청화사, 비급, 묘선, 선인인형, 별다람쥐, 호저 | 요괴선사 | 70 s | red 7,500, elitePt 3,100, wpnTicket 725, timeTicket 290 |
| 30 | 황금사원 수행자의 숲 | Golden Temple Forest of Training | 14 / 13 | 사나운 원숭이, 어미 원숭이, 흰털 아기원숭이, 흰털 어미원숭이 | 흰털 대장원숭이 | 70 s | red 7,750, elitePt 3,200, wpnTicket 750, timeTicket 300 |
| 31 | 황금사원 버려진 사원 | Golden Temple Abandoned Temple | 14 / 13 | 푸른 도깨비, 붉은 도깨비, 돌도깨비, 힘센 돌도깨비, 가네시 | 라바나 | 70 s | red 8,000, elitePt 3,300, wpnTicket 775, timeTicket 310 |
| 32 | 시간의 신전 추억 | Temple of Time Memory | 14 / 13 | 시간의 눈, 추억의 사제, 추억의 신관, 추억의 수호병, 추억의 수호대장 | 도도 | 70 s | red 8,250, elitePt 3,400, wpnTicket 800, timeTicket 320 |
| 33 | 시간의 신전 후회 | Temple of Time Qualm | 14 / 13 | 시간의 눈, 후회의 사제, 후회의 신관, 후회의 수호병, 후회의 수호대장 | 릴리노흐 | 70 s | red 8,500, elitePt 3,500, wpnTicket 825, timeTicket 330 |
| 34 | 시간의 신전 망각 | Temple of Time Oblivion | 14 / 13 | 시간의 눈, 망각의 사제, 망각의 신관, 망각의 수호병, 망각의 수호대장 | 라이카 | 70 s | red 8,750, elitePt 3,600, wpnTicket 850, timeTicket 340 |
| 35 | 크림슨우드 성채 | Crimsonheart Castle | 14 / 13 | 마족 환술사, 티폰, 마족 역사, 레프러콘 | 붉은 성채의 간수 | 70 s | red 9,000, elitePt 3,700, wpnTicket 875, timeTicket 350 |
| 36 | 크림슨우드 성채 꼭대기 | Top of Crimsonheart Castle | 14 / 13 | 푸른 성채의 간수, 마족 추격자, 레드 스티지, 마족 약탈자, 엘더레이스 | 마스터 레드너그 | 70 s | red 9,250, elitePt 3,800, wpnTicket 900, timeTicket 360 |
| 37 | 커닝타워 저층 | Kerning Tower Lower Floors | 14 / 13 | 소다맛 젤리주스, 흘러간 가요 CD, 최신곡 CD, 최신형 스피커, 포도맛 젤리주스, 증기뿜는 커피머신 | 락 스피릿 | 70 s | red 9,500, elitePt 3,900, wpnTicket 925, timeTicket 370 |
| 38 | 커닝타워 고층 | Kerning Tower Upper Floors | 14 / 13 | 난폭한 화장품, 파란색 노트, 노란색 헤드폰, 빨간색 헤드폰, 난폭한 화장대, 까칠한 헤어롤 | 분노한 락 스피릿 | 70 s | red 9,750, elitePt 4,000, wpnTicket 950, timeTicket 380 |
| 39 | 암벽 거인 탐사 현장 | Stone Colossus Exploration Site | 19 / 18 | 플로라, 맨티스, 블러드 맨티스, 포이즌 맨티스, 호넷, 포이즌 호넷 | 다크 플로라 | 70 s | red 10,000, elitePt 4,100, wpnTicket 975, timeTicket 390 |
| 40 | 암벽 거인에게 가는 길 | Colossus Road | 19 / 18 | 타락한 나무의 정령, 호넷, 플로라, 포이즌 호넷, 포이즌 맨티스, 맨티스 | 제너럴 호넷 | 70 s | red 10,250, elitePt 4,200, wpnTicket 1,000, timeTicket 400 |
| 41 | 암벽 거인의 몸 속 | Inside the Stone Colossus | 19 / 18 | 타락한 돌의 정령, 블러드 맨티스, 오염된 돌의 정령, 오염된 나무의 정령, 타락한 나무의 정령, 플로라 | 타란튤로스 | 70 s | red 10,500, elitePt 4,300, wpnTicket 1,025, timeTicket 410 |
| 42 | 에레브 | — | 19 / 18 | 티노, 티무, 티브, 티루, 티구르 | 흉터곰 | 70 s | red 10,750, elitePt 4,400, wpnTicket 1,050, timeTicket 420 |
| 43 | 리엔 | — | 19 / 18 | 무루, 무루파, 무루피아, 무루무루, 무루쿤, 부하 늑대 | 도둑까마귀 | 70 s | red 11,000, elitePt 4,500, wpnTicket 1,075, timeTicket 430 |
| 44 | 리에나 해협 | — | 19 / 18 | 암모나이트 화석, 물고기 화석, 찐득한 오염물, 찐득한 폐기물, 수상한 물개, 수상한 바다표범 | 게오르크 | 70 s | red 11,250, elitePt 4,600, wpnTicket 1,100, timeTicket 440 |
| 45 | 골드비치 해변가 풀숲 | — | 19 / 18 | 코코넛 슬라임, 야자수 슬라임, 초록조개 슬라임, 빨간 튜브 슬라임, 파란 튜브 슬라임, 새우 슬라임 | 보라조개 슬라임 | 70 s | red 11,500, elitePt 4,700, wpnTicket 1,125, timeTicket 450 |
| 46 | 골드비치 얕은 바다 | — | 19 / 18 | 빨간 튜브 슬라임, 파란 튜브 슬라임, 새우 슬라임, 날치 슬라임, 불가사리 문어 슬라임, 소라문어 슬라임 | 갈매기 슬라임 | 70 s | red 11,750, elitePt 4,800, wpnTicket 1,150, timeTicket 460 |
| 47 | 골드비치 거친 파도 | — | 19 / 18 | 날치 슬라임, 불가사리 문어 슬라임, 소라문어 슬라임, 초록조개 슬라임, 코코넛 슬라임, 야자수 슬라임 | 캡틴 블랙 슬라임 | 70 s | red 12,000, elitePt 4,900, wpnTicket 1,175, timeTicket 470 |

**Hunt drop table per kill (KR, MK-map).** Drop rates are the same in every chapter:
- Meso: 7%
- Elite points: 0.25%
- Red diamond: 1 at 1%
- Weapon summon ticket: 1 at 0.15% (ch2+)
- Weapon stones: 0.5% (ch2+)
- Medals of honor: 0.15% (from 3-7)
- Artifact enhance stones: 20 at 0.6% (ch11+)
- Journey tokens: 0.1% (ch21+; not given by quick hunt)

The global wiki states the same rates and formulas for ch1-41: probabilities per 1 000 000 in `maps.json`.

| Ch | meso (7%) | elite pts (0.25%) | wpn stones (0.5%) s1→last | medals (0.15%) | artifact stones (0.6%) | journey tokens (0.1%) s1→last | trial 1st-clear meso first→last | trial elite pts | trial EXP first→last |
|---|---|---|---|---|---|---|---|---|---|
| 1 | 40 | 10 | —→— | — | — | —→— | 4,000→5,000 | 102→104 | 291→578 |
| 2 | 40 | 10 | 100→102 | — | — | —→— | 8,000→13,000 | 110→120 | 1,752→6,529 |
| 3 | 41 | 11 | 103→105 | 10 | — | —→— | 17,000→24,000 | 128→142 | 17,420→83,068 |
| 4 | 42 | 12 | 106→108 | 10 | — | —→— | 26,000→33,000 | 146→160 | 125,674→535,279 |
| 5 | 43 | 13 | 109→111 | 11 | — | —→— | 35,000→42,000 | 164→178 | 770,802→2,761,921 |
| 6 | 44 | 14 | 112→114 | 12 | — | —→— | 44,000→51,000 | 182→196 | 3,977,166→14,250,905 |
| 7 | 45 | 15 | 115→117 | 13 | — | —→— | 53,000→60,000 | 200→214 | 19,508,064→58,548,424 |
| 8 | 46 | 16 | 118→120 | 14 | — | —→— | 62,000→69,000 | 218→232 | 77,430,291→205,966,113 |
| 9 | 47 | 17 | 121→123 | 15 | — | —→— | 71,000→78,000 | 236→250 | 258,363,893→571,160,253 |
| 10 | 48 | 18 | 124→126 | 16 | — | —→— | 80,400→88,800 | 254→268 | 691,103,906→1,346,766,001 |
| 11 | 49 | 19 | 127→129 | 17 | 20 | —→— | 91,200→99,600 | 272→286 | 1,541,912,394→2,475,974,361 |
| 12 | 50 | 20 | 130→132 | 18 | 20 | —→— | 102,000→110,400 | 290→304 | 2,729,761,733→3,841,048,889 |
| 13 | 51 | 21 | 133→135 | 19 | 20 | —→— | 112,800→121,200 | 308→322 | 4,234,756,400→5,958,727,522 |
| 14 | 52 | 22 | 136→138 | 20 | 20 | —→— | 123,600→132,000 | 326→340 | 6,569,497,093→9,243,942,137 |
| 15 | 53 | 23 | 139→141 | 21 | 20 | —→— | 134,400→142,800 | 344→358 | 9,806,898,213→12,061,247,812 |
| 16 | 54 | 24 | 142→144 | 22 | 20 | —→— | 145,800→156,300 | 362→376 | 12,795,777,803→15,737,192,707 |
| 17 | 55 | 25 | 145→147 | 23 | 20 | —→— | 159,300→169,800 | 380→394 | 16,695,587,743→20,533,467,033 |
| 18 | 56 | 26 | 148→150 | 24 | 20 | —→— | 172,800→183,300 | 398→412 | 21,363,019,101→24,539,393,858 |
| 19 | 57 | 27 | 151→153 | 25 | 20 | —→— | 186,300→196,800 | 416→430 | 25,530,785,370→29,326,847,238 |
| 20 | 58 | 28 | 154→156 | 26 | 20 | —→— | 199,800→210,300 | 434→448 | 30,511,651,867→35,048,297,196 |
| 21 | 59 | 29 | 157→159 | 27 | 20 | 300→324 | 213,300→223,800 | 452→466 | 36,464,248,403→41,885,959,521 |
| 22 | 60 | 30 | 160→162 | 28 | 20 | 327→351 | 226,800→237,300 | 470→484 | 43,578,152,285→50,057,598,954 |
| 23 | 61 | 31 | 163→165 | 29 | 20 | 354→378 | 240,300→250,800 | 488→502 | 52,079,925,952→59,823,464,513 |
| 24 | 62 | 32 | 166→168 | 30 | 20 | 381→405 | 253,800→264,300 | 506→520 | 62,240,332,479→71,494,577,870 |
| 25 | 63 | 33 | 169→171 | 31 | 20 | 408→432 | 267,300→277,800 | 524→538 | 74,382,958,816→85,442,638,709 |
| 26 | 64 | 34 | 172→174 | 32 | 20 | 435→459 | 280,800→291,300 | 542→556 | 88,894,521,313→102,111,862,564 |
| 27 | 65 | 35 | 175→177 | 33 | 20 | 462→486 | 294,300→304,800 | 560→574 | 106,237,181,811→122,033,128,118 |
| 28 | 66 | 36 | 178→180 | 34 | 20 | 489→513 | 307,800→318,300 | 578→592 | 126,963,266,494→145,840,884,539 |
| 29 | 67 | 37 | 181→185 | 35 | 20 | 516→555 | 321,300→339,300 | 596→620 | 151,732,856,275→192,433,949,937 |
| 30 | 68 | 38 | 185→190 | 36 | 20 | 558→597 | 342,300→360,300 | 624→648 | 200,208,281,515→253,912,510,233 |
| 31 | 69 | 39 | 190→194 | 37 | 20 | 601→653 | 363,300→381,300 | 652→676 | 264,170,575,647→335,032,164,929 |
| 32 | 70 | 40 | 195→199 | 38 | 20 | 657→709 | 384,300→402,300 | 680→704 | 348,567,464,393→442,067,826,568 |
| 33 | 71 | 41 | 199→204 | 39 | 20 | 713→765 | 405,300→423,300 | 708→732 | 459,927,366,761→583,299,108,990 |
| 34 | 72 | 42 | 204→208 | 40 | 20 | 769→821 | 426,300→444,300 | 736→760 | 606,864,392,993→769,650,786,827 |
| 35 | 73 | 43 | 209→213 | 41 | 20 | 825→877 | 447,300→465,300 | 764→788 | 800,744,678,615→1,015,537,868,193 |
| 36 | 74 | 44 | 213→218 | 42 | 20 | 881→933 | 468,300→486,300 | 792→816 | 1,056,565,598,068→1,339,980,650,167 |
| 37 | 75 | 45 | 218→222 | 43 | 20 | 937→989 | 489,300→507,300 | 820→844 | 1,394,115,868,433→1,768,076,010,809 |
| 38 | 76 | 46 | 223→227 | 44 | 20 | 993→1,045 | 510,300→528,300 | 848→872 | 1,839,506,281,646→2,332,938,747,748 |
| 39 | 77 | 47 | 227→233 | 45 | 20 | 1,049→1,121 | 531,300→556,800 | 876→910 | 2,427,189,473,157→3,398,651,232,543 |
| 40 | 78 | 48 | 234→240 | 46 | 20 | 1,125→1,197 | 559,800→585,300 | 914→948 | 3,535,956,742,338→4,951,193,087,096 |
| 41 | 79 | 49 | 240→246 | 47 | 20 | 1,202→1,292 | 588,300→613,800 | 952→986 | 5,151,221,287,815→7,212,953,406,622 |
| 42 | 80 | 50 | 246→252 | 48 | 20 | 1,297→1,387 | 616,800→642,300 | 990→1,024 | 7,504,356,724,249→10,507,911,109,689 |
| 43 | 81 | 51 | 253→259 | 49 | 20 | 1,392→1,482 | 645,300→670,800 | 1,028→1,062 | 10,932,430,718,521→15,308,042,304,526 |
| 44 | 82 | 52 | 259→265 | 50 | 20 | 1,487→1,577 | 673,800→699,300 | 1,066→1,100 | 15,926,487,213,629→22,300,927,058,764 |
| 45 | 83 | 53 | 265→271 | 51 | 20 | 1,582→1,672 | 702,300→727,800 | 1,104→1,138 | 23,201,884,511,938→32,488,239,696,935 |
| 46 | 84 | 54 | 272→278 | 52 | 20 | 1,677→1,767 | 730,800→756,300 | 1,142→1,176 | 33,800,764,580,692→47,329,230,566,258 |
| 47 | 85 | 55 | 278→284 | 53 | 20 | 1,772→1,862 | 759,300→784,800 | 1,180→1,214 | 49,241,331,481,135→68,949,751,876,072 |

## 8. Offline, idle and quick hunt

| Rule | Value | Region / date | Ref |
|---|---|---|---|
| Offline accrual cap | 24 h (was 8 h). Special Membership +12 h (was +4 h), for 36 h total | KR 2026-02-12 | INV-76, INV-697 |
| Offline efficiency | +5.9%. Premium multiplier 1.5 → 1.7 | KR 2026-08-13 | INV-88 |
| Weekly cap | 300 h per account per week, reset Monday 00:00. No carry-over, and nothing is paid if less than 5 min remains. Premium characters are exempt. | KR 2026-11-05 | INV-772 |
| Kill rate | 54 kills/min (0.9/s), fixed at the latest map reached, whatever the level | global | WIKI Hunting_and_Offline_Rewards |
| Minimum / rounding | 5 min minimum. Time is counted per second, then rounded down to whole minutes. | global | same |
| Offline drops | Deterministic: floor(kills × rate) per drop type × amount | global | same |
| Boosters | Apply to the offline reward for their remaining time | KR 7/23, global | INV-84, WIKI Boosters |
| Online spawn | First 40 s on a map: 28-35 monsters per interval. After that: 12 per 10 s (1-1), 64 per 20 s (ch1-3), 64 per 25 s (ch4-5), 64 per 30 s (ch6-10), 64 per 35 s (ch11+) | global | WIKI |
| Quick hunt | Grants 1 000 kills on first use, +5 per use, up to 3 000. The guild skill adds +50/100/150. EXP/meso/drop boosts do not apply. Uses the highest stage reached. Unlocks at Guide Quest 75. | global + KR | WIKI Quick_Hunt, INV-735 |
| Quick hunt price | 1 ad use/day. Red diamonds 500 / 750 / 1 000 (3 per day). Quick hunt tickets. Special Membership +1 free/day. KR challenge 마스터5 +1 free/day. | KR 10/27 guide | INV-735, INV-772 |

## 9. Growth dungeons (성장 던전)

- **Tickets:**
  - 3 free keys per day for each of the 5 dungeons [WIKI Growth_Dungeon].
  - Weapon, EXP and equipment dungeons: the entry ticket "is returned upon successfully clearing the dungeon".
  - Enhancement dungeon: the ticket is returned on failure (wiki wording).
- **Stages:**
  - KR has 150 stages per dungeon. There were 130 on 7/2, and stages 141-150 were added on 9/3 [NV growth-dungeons].
  - The global wiki pages still say 70/90/100.
- **Bulk sweep:** unlocks after stage 50 in every dungeon. It uses the same tickets and gives the same rewards (KR 8/13) [INV-88].
- **Reward types:**
  - 무기 던전: weapon summon tickets and weapon enhancers.
  - 장비 던전: elite points.
  - 용사의 수련장: 용사의 증표 (hero tokens).
  - 강화 던전: spell traces and enhancement scrolls.
  - 경험치 던전: EXP [WIKI].
- **Rewards per stage: NOT FOUND,** except the EXP dungeon table and the enhancement scroll odds, which are already in the spec.
- **Medals:** "Floor 50/70/100 Mapler" for clearing stage 50/70/100 of every growth dungeon, Main Stat +30 each [WIKI Medals].

## 10. World boss (월드보스)

Unlocks at Guide Quest 58. Daily and weekly rewards go by ranking tier. There are also one-time rewards for reaching X% of max HP; their amounts are **not published**. Reward events (×3) do not affect these one-time rewards [INV-611].

**KR tier rewards (2026-09-22 change, old → new)** [INV-604]

| Tier | Daily WB coins | Weekly WB coins | Weekly miracle cubes |
|---|---|---|---|
| 챔피언1 | 1 500→2 000 | 3 000→4 000 | 25→30 |
| 챔피언2 | 1 400→1 900 | 2 800→3 800 | 23→28 |
| 챔피언3 | 1 300→1 800 | 2 600→3 600 | 21→26 |
| 챌린저1 | 1 200→1 700 | 2 400→3 400 | 19→24 |
| 챌린저2 | 1 100→1 600 | 2 200→3 200 | 17→22 |
| 챌린저3 | 1 000→1 500 | 2 000→3 000 | 15→20 |
| 챌린저4 | 950→1 400 | 1 900→2 800 | 13→18 |
| 챌린저5 | 900→1 300 | 1 800→2 600 | 12→17 |
| 그랜드마스터1 | 850→1 250 | 1 700→2 500 | 11→16 |
| 그랜드마스터2 | 800→1 200 | 1 600→2 400 | 10→15 |
| 그랜드마스터3 | 760→1 150 | 1 520→2 300 | 9→14 |
| 그랜드마스터4 | 720→1 100 | 1 440→2 200 | 8→13 |
| 그랜드마스터5 | 680→1 050 | 1 360→2 100 | 7→12 |
| 마스터1 | 650→1 000 | 1 300→2 000 | 6→11 |
| 마스터2 | 620→970 | 1 240→1 940 | 5→10 |
| 마스터3 | 590→940 | 1 180→1 880 | 4→9 |
| 마스터4 | 560→910 | 1 120→1 820 | 3→8 |
| 마스터5 | 530→880 | 1 060→1 760 | 3→7 |
| 다이아몬드1 | 500→850 | 1 000→1 700 | 2→6 |
| 플래티넘1 | 400→800 | 800→1 600 | 1→5 |
| 골드1 | 300→700 | 600→1 400 | — |
| 실버1 | 200→600 | 400→1 200 | — |
| 브론즈1 | 100→500 | 200→1 000 | — |

- The weekly benefit buff is listed in §5.
- **World Boss shop contents: NOT FOUND.**
- **Guild member skill (global):** World Boss final damage +1/2/3% [WIKI].

## 11. Boss raids (자쿰 / 혼테일 / 핑크빈)

- **Ticket history:**
  - 2025-12-18 (Zakum launch): 3 weekly entries [WIKI Zakum].
  - 2026-04-30: weekly tickets 3 → 4 and red-diamond refills 3 → 4. A run may spend 2 tickets for a double main reward [INV-80].
  - 2026-09-03: each boss gets 2 base entries per week, plus 2 common 보스 레이드 입장권 per week. Both reset Monday 00:00 and cannot exceed their max holding.
- **Challenge mode:** no ticket and no reward.
- **Red-diamond refill price:** 2 000 / 3 000 / 5 000 / 5 000 [NV boss-raid].
- **Single mode (9/3):** 1 player, lower boss HP, 8 revives, and more sub-option lines on gear [INV-158].
- **Unlocks:** see `content.md` and the wiki Chapter_Unlocks page. KR changes on 4/30: Zakum Hard 26-10 → 25-10, Chaos 31-15 → 30-15 [INV-80]. Pink Bean 쉬움/보통/어려움 unlock at the ch32/37/42 boss [NV].
- **Reward when no gear drops** (KR 9/3, doubled; the old value is in brackets) [INV-158]:
  - Spell traces: 400 (200)
  - Meso: 100 000 (50 000)
  - Elite points: 400 (200)
  - Weapon enhancers: 20 000 (10 000)
  - Time tickets (1 min): 200 (100)
- **Zakum main reward odds (global wiki; one pick per run)** [WIKI Zakum]:
  - Normal:
    - 50 000 meso: 35%
    - 200 elite pts: 16%
    - Aquatic Letter (Unique): 15%
    - 10 000 weapon enhancers: 10%
    - Zakum Helmet (Unique): 9%
    - 200 spell traces: 7%
    - Zakum Scroll (Low): 4%
    - 100 time tickets: 3%
    - Zakum Helmet (Unique): 1%
  - Hard: the same, except Scroll (Low) 3%, Helmet (Legendary) 1% and Scroll (Mid) 1%.
  - Gear-drop % per KR difficulty is in `items-gacha.md` §11.
- **Medals:**
  - 자쿰 파괴자 (Very Hard ×5): boss damage +10%.
  - 혼테일 파괴자 (Hard ×5): boss damage +10% [INV-80].
  - Guild raid clear medals: final damage +3%.

## 12. Party quests, monster park, star force field

- **PQ expedition (탐험):** 탐험 티켓 +1 every Monday 00:00. The PQ runs in the background and gives equipment only [INV-81, 2026-05-21].
- **Party:** 1-4 players, matched across servers [WIKI Party_Quest].
- **Rewards:** equipment, EXP, meso and elite points (wiki stub). **The meso and elite amounts are not published.**
- **Medals:** 50 clears of each PQ give Main Stat +30 [WIKI Medals].
- **Monster park:** see `content.md` (EXP only). **No item rewards were found.**
- **Star force field (event, 2026-04-30 → 06-28):**
  - Weekly ticket, 1 per Monday.
  - Difficulties: 에픽 (no bonus), 유니크 (+50% final EXP) and 레전드리 (+90%).
  - EXP% applies in full [INV-80].

## 13. Hero's Journey (용사의 여정) and Journey Treasure (여정의 보물)

**Journey Treasure (여정의 보물)**
- **Cards:** 4 cards (star force scrolls, miracle cubes, spell traces, meso); pick 1.
  - Unpicked cards go up one step, to a maximum of 5. The picked card resets to step 1.
  - The meso card pays 4M-8M [INV-596, INV-625].
- **Gauge:** filled by kills in ch20+ (not by quick hunt or event monsters). Capped at 200%.
  - The required gauge grows after each claim.
  - The gauge also fills when you claim the offline reward, with premium ×1.7.
- **Weekly acceleration:** 1 by ad plus 1 for premium. It gives +20/25/30% at 60/30/10% odds.

**Journey Chest (여정의 상자)**
- **Keys:** 5 per week (Monday), with a cap of 5.
- **Blessings:** 7 blessings are given before opening. They add grey +0, yellow +5% or red +10% [INV-82, WIKI Hero's_Journey].
  - 1 free reset per day.
  - Up to 10 keys can be used at once.
- **Base journey tokens per chest (global wiki):**
  - ch20: 10 280
  - ch25: 15 380
  - ch30: 21 020
  - ch35: 31 100
  - ch40: 42 400
  - ch41: 45 300
  - The full list is in the JSON.

**Journey Trail (여정의 발자취)**
- **Option odds:**
  - Normal: 40%
  - Rare: 30%
  - Epic: 22%
  - Unique: 4%
  - Legendary: 2.5%
  - Mystic: 1.3%
  - Mystic+: 0.2%
- **Special option:** active only while all 3 slots are Unique or better.
- **Lock:** locking a slot costs 여정의 기운. It used miracle cubes until 9/3. 여정의 기운 can be bought 5 per week with red diamonds and 5 per week with arena coins [INV-158].
- **Per-chapter data (global wiki, ch20-41):** the table below is abridged. Slot values for every grade are in the JSON (`heroJourneyTrail`).

| Ch | one-off rewards | open delay | open cost | option change cost | slot4 special |
|---|---|---|---|---|---|
| 20 | Journey Token 12,000, Star Force Enhancement Scroll 20, Miracle Cube 10 | 1d 2h 40m | Meso 674,400, Journey Token 60,300 | Meso 5,000, Journey Token 1,900 | Main Stat +5% |
| 21 | Journey Token 15,000, Miracle Cube 10 | 1d 7h 40m | Meso 752,900, Journey Token 78,500 | Meso 5,300, Journey Token 2,120 | Boss Monster Damage +10% |
| 22 | Journey Token 19,000, Bonus Glowing Cube 5 | 1d 12h 56m | Meso 836,300, Journey Token 99,600 | Meso 5,600, Journey Token 2,360 | Normal Monster Damage +10% |
| 23 | Journey Token 24,000, Star Force Enhancement Scroll 20 | 1d 18h 46m | Meso 924,700, Journey Token 124,600 | Meso 5,900, Journey Token 2,620 | Damage +20% |
| 24 | Journey Token 30,000, Miracle Cube 10 | 2d 1h 10m | Meso 1,018,100, Journey Token 153,800 | Meso 6,200, Journey Token 2,910 | Max Damage Multiplier +10% |
| 25 | Journey Token 37,000, Bonus Glowing Cube 5, Miracle Cube 10 | 2d 7h 50m | Meso 1,116,600, Journey Token 186,700 | Meso 6,500, Journey Token 3,220 | EXP Gain +7% |
| 26 | Journey Token 44,000, Star Force Enhancement Scroll 20 | 2d 15h 3m | Meso 1,220,200, Journey Token 224,500 | Meso 6,800, Journey Token 3,560 | Normal Monster Damage +10% |
| 27 | Journey Token 53,000, Miracle Cube 10 | 2d 22h 50m | Meso 1,329,100, Journey Token 267,500 | Meso 7,100, Journey Token 3,920 | Main Stat +5% |
| 28 | Journey Token 63,000, Bonus Glowing Cube 5 | 3d 6h 53m | Meso 1,443,200, Journey Token 315,000 | Meso 7,400, Journey Token 4,310 | Max Damage Multiplier +10% |
| 29 | Journey Token 74,000, Star Force Enhancement Scroll 20 | 3d 15h 30m | Meso 1,562,700, Journey Token 372,600 | Meso 7,700, Journey Token 4,730 | Min Damage Multiplier +10% |
| 30 | Journey Token 88,000, Miracle Cube 10, Star Force Enhancement Scroll 20 | 4d 23m | Meso 1,687,500, Journey Token 442,900 | Meso 8,000, Journey Token 5,180 | Final Damage +2.5% |
| 31 | Journey Token 105,000, Bonus Glowing Cube 5 | 4d 9h 50m | Meso 1,817,800, Journey Token 527,200 | Meso 8,300, Journey Token 5,660 | Main Stat +5% |
| 32 | Journey Token 125,000, Star Force Enhancement Scroll 20 | 4d 19h 50m | Meso 1,953,600, Journey Token 629,000 | Meso 8,600, Journey Token 6,170 | Boss Monster Damage +10% |
| 33 | Journey Token 148,000, Miracle Cube 10 | 5d 6h 6m | Meso 2,094,900, Journey Token 741,300 | Meso 8,900, Journey Token 6,710 | Min Damage Multiplier +10% |
| 34 | Journey Token 173,000, Bonus Glowing Cube 5 | 5d 16h 56m | Meso 2,241,800, Journey Token 866,400 | Meso 9,200, Journey Token 7,290 | Max Damage Multiplier +10% |
| 35 | Journey Token 200,000, Star Force Enhancement Scroll 20, Miracle Cube 10 | 6d 4h 3m | Meso 2,394,300, Journey Token 1,003,200 | Meso 9,500, Journey Token 7,900 | Critical Damage +10% |
| 36 | Journey Token 231,000, Miracle Cube 10 | 6d 16h | Meso 2,552,500, Journey Token 1,155,700 | Meso 9,800, Journey Token 8,550 | Boss Monster Damage +10% |
| 37 | Journey Token 264,000, Bonus Glowing Cube 5 | 7d 3h 56m | Meso 2,716,400, Journey Token 1,319,200 | Meso 10,100, Journey Token 9,230 | Normal Monster Damage +10% |
| 38 | Journey Token 300,000, Star Force Enhancement Scroll 20 | 7d 16h 43m | Meso 2,886,100, Journey Token 1,499,900 | Meso 10,400, Journey Token 9,950 | Main Stat +5% |
| 39 | Journey Token 341,000, Miracle Cube 10 | 8d 5h 46m | Meso 3,061,600, Journey Token 1,707,700 | Meso 10,700, Journey Token 10,710 | Min Damage Multiplier +10% |
| 40 | Journey Token 390,000, Bonus Glowing Cube 5, Miracle Cube 10 | 8d 19h 6m | Meso 3,242,900, Journey Token 1,951,300 | Meso 11,000, Journey Token 11,510 | Final Damage +2.5% |
| 41 | Journey Token 446,000, Star Force Enhancement Scroll 20 | 9d 8h 43m | Meso 3,432,900, Journey Token 2,228,900 | Meso 11,300, Journey Token 12,350 | Boss Monster Damage +10% |

## 14. Artifacts (유물): chest rates and resonance

**Chest (유물상자), KR** [MK-relic]
- **Grade split:** 에픽 89.5% (4 items × 22.375%), 유니크 9.5% (9 items × 1.0556%), 레전드리 1% (23 items × 0.04348%).
- **Per-item list:** in the JSON.
- **Global wiki:** the same 89.5 / 9.5 / 1 split, but with fewer artifacts in each group [WIKI Artifact_Chest].
- **Pickup chest (KR 8/13):** when a Legendary is rolled, the new pickup artifacts take 60% and the existing ones 40% [INV-88].
- **Price:** the chest is a shop item (paid). mekipick's simulator assumes 10 000 blue diamonds per 10 draws.

**Awakening and slots (KR)**
- **Slots:** the 4th slot opens at total awakening 50 (3/19) [INV-78]. The 5th opens at 80 (11/26 preview) [INV-807].
- **Legendary awakening:** up to 7 (11/5). A 7-awakened legendary can be dismantled for a lock material [INV-745].
- **Duplicates per awakening: NOT FOUND.**

**Resonance amplification (공명 증폭)** [WIKI Resonance_Amplification]
- **Cost:** artifact enhancers (유물 강화석) per level.
- **Max level:** starts at 50 and gains +10 per artifact awakening stage. The awakening stage is the total number of stars across all artifacts.
- **Cost per level:** 1 500 at Lv1, then +18/+19/+20 … per level, up to 46 723 at Lv900. Every level is in the JSON. Sample:

| Lv | enhancers | Lv | enhancers | Lv | enhancers |
|---|---|---|---|---|---|
| 1 | 1,500 | 10 | 1,662 | 20 | 1,847 |
| 30 | 2,037 | 40 | 2,227 | 50 | 2,425 |
| 60 | 2,625 | 70 | 2,828 | 80 | 3,038 |
| 90 | 3,248 | 100 | 3,467 | 150 | 4,619 |
| 200 | 5,892 | 250 | 7,297 | 300 | 8,852 |
| 350 | 10,570 | 400 | 12,469 | 450 | 14,566 |
| 500 | 16,883 | 550 | 19,445 | 600 | 22,275 |
| 650 | 25,404 | 700 | 28,860 | 750 | 32,680 |
| 800 | 36,900 | 850 | 41,566 | 900 | 46,723 |

## 15. Guild (길드): buildings, skills, content rewards

**Buildings (global wiki)** [WIKI Guild_Buildings]
- **Upgrading:** an upgrade uses 100 Guild Construction Material for +50 EXP, or 300 blue diamonds (paid) for +200 EXP. At most 10 upgrades per day across all buildings.
- **Guild Base:** required EXP and member cap by level.

  | Lv | Required EXP | Member cap |
  |---|---|---|
  | 1 | 1 800 | 20 |
  | 2 | 5 400 | 22 |
  | 3 | 16 200 | 24 |
  | 4 | 32 400 | 26 |
  | 5 | 64 800 | 28 |
  | 6 | 113 400 | 30 |
  | 12 | 1 335 800 | 30 |

- **Warehouse:** required EXP is 900 at Lv1 … 667 400 at Lv12.
  - Weekly guild coins, global: 3 000 + 3 EXP boosters (30%) at Lv1, then +300 coins and +1 booster per level.
  - KR 11/5 coin values:
    - Lv2: 3 400
    - Lv3: 3 800
    - Lv4: 4 200
    - Lv5: 4 600
    - Lv6: 5 000
    - Lv7: 5 500
    - Lv8: 6 000 + 300 time tickets
    - Lv9: 6 500 + 350
    - Lv10: 7 000 + 400
    - Lv11: 7 500 + 450
    - Lv12: 8 000 + 500 [INV-772]
- **Lab:** cuts research time by 0% at Lv1 up to 300% at Lv12 (required EXP 1 200 … 890 000).
- **Guild help:** a request can be helped 10 times per day, each help cuts 10 min, and the request expires after 12 h. It also works on elite summon level-up timers [WIKI Guild].

**Guild member skills (global)** [WIKI Guild_Member_Skills]
- Each skill has 3 levels, paid in red diamonds. Research time is per level.

| Skill | Guild Lv | Effect Lv1/2/3 | Red diamonds Lv1/2/3 | Research |
|---|---|---|---|---|
| Damage | 1 | +3/6/10% | 1 000/2 000/3 000 | 24 h |
| Max HP | 1 | +5/10/20% | 1 000/2 000/3 000 | 24 h |
| Growth-dungeon damage | 3 | +6/12/20% | 3 000/6 000/9 000 | 40 h |
| Speed | 3 | +3/6/10% | 3 000/6 000/9 000 | 40 h |
| Chapter-hunt damage | 5 | +6/12/20% | 5 000/10 000/15 000 | 56 h |
| Quick-hunt kills | 5 | +50/100/150 | 5 000/10 000/15 000 | 56 h |
| Chapter-breakthrough damage | 7 | +6/12/20% | 7 000/14 000/21 000 | 72 h |
| Scroll success | 7 | +1/2/3%p | 7 000/14 000/21 000 | 72 h |
| World boss final damage | 10 | +1/2/3% | 10 000/20 000/30 000 | 96 h |
| Bonus EXP | 10 | +1/3/5% | 10 000/20 000/30 000 | 96 h |

**New KR skills (2026-11-05)** [INV-772]
- **Member skills:**
  - Normal-monster damage +5% (guild Lv2)
  - Boss damage +5% (Lv4)
  - Max damage ratio +10% (Lv6)
  - Min damage ratio +10% (Lv8)
  - Bounty (현상수배) damage +20% (bounty stage 5)
  - Bounty max/min damage ratio +10% each (stages 10/20)
  - Damage taken −5% (stage 30)
  - Max/min damage ratio +10% each (stages 50/70)
  - Crit damage +10% (stage 90)
  - Final damage +5% (stage 100)
  - 데미지 +50% (Lv100, +0.5% per level)
- **Guild mastery:**
  - Max HP +10% (guild Lv3)
  - Bounty damage +20% (Lv5)
  - Normal-monster damage +10% (Lv7)
  - Boss damage +10% (Lv9)
  - Defense +10% (guild hunt score 500)
  - Bounty speed +10% (3 750)
  - Damage +10% (5 500)
  - Bounty pierce +10% (7 500)
  - Normal-monster damage +10% (12 500)
  - Boss damage +10% (17 500)
  - Bounty companion duration +10% (22 500)
  - Damage amplification +5% (37 500)
  - Bounty final damage +100% (Lv100, +1% per level, Lv96-100 at score 1 650 000)
- **Mastery reset:** monthly at first (global). The monthly reset was removed in KR on 2/26 [NV guild-growth].
- **토벌전 noblesse by guild tier (11/5):**
  - 실버: damage +6%
  - 골드: damage +10%, meso +2%
  - 플래티넘: damage +10%, meso +6%
  - 다이아몬드: damage +10%, meso +10%
  - 마스터5 → 1: as 다이아몬드, plus normal-monster damage +2/4/6/8/10%
  - Higher tiers: also normal-monster damage +10%
  - None of these apply inside guild content.

**Guild shop (KR 11/5)** [INV-772]
- Weapon stones: 60 000
- Elite points: 500, twice a week
- Spell traces: 1 000, twice a week
- Medals of honor: 4 000 (warehouse Lv7)
- EXP booster (50%) ×10 (Lv8)
- Star force scroll ×5 (Lv9)
- Miracle cube ×3 (Lv10)
- Memorial scroll ×6 (Lv11)
- 200 sub-option stones for 2 000 guild coins, weekly (Lv12)

**Bounty shop (현상수배 상점), paid in 불꽃 늑대 coins**
- 200 sub-option stones for 4 000 coins (10 per character, stage 20) or 2 000 coins (weekly).
- 하급/중급/상급/최상급 enchant pouches for 200/400/600/1 000 coins, 5 per week each, needing stages 10/20/30/40.
- 100 time tickets for 1 000 coins.
- 1 burning-field booster for 2 000 coins.

**Content rewards**
- **길드 현상수배 (bounty, KR 11/5)** [INV-772]:
  - First clear of each stage: hunt score 100 … 7 700, plus first-clear rewards that include enchant-pouch vouchers.
  - Weekly server rank, settled Sunday 00:00. Each row gives the minimum guild score, then the reward:
    - 1st (20 000): 14 000 wolf coins + 10 최상급 pouches + 300 stones
    - 2nd (15 000): 13 000 + 10 상급 + 200
    - 3rd (10 000): 12 000 + 9 상급 + 100
    - 4-5 (5 000): 11 000 + 8 상급
    - 6-10 (4 000): 10 000 + 7 상급
    - 11-20 (3 000): 9 500 + 6 상급
    - 21-30 (2 000): 9 000 + 5 상급
    - 31-50 (1 500): 8 500 + 5 중급
    - 51-70 (1 000): 8 000 + 4 중급
    - 71-100 (800): 7 800 + 3 중급
    - 101-200 (600): 7 600 + 2 중급
    - 201-300 (500): 7 400 + 2 하급
    - 301-400 (500): 7 200 + 1 하급
    - 401-500 (300): 7 000
    - 501-1 000 (100): 6 800
    - 1 001+ (1): 6 600
  - All-server rank buff, until the next settlement: 1st EXP +25% plus a riding mount, 2nd +20%, 3rd +15%, 4-10 +12%, 11-50 +10%, 51-100 +8%, 101-500 +6%, 501-1 000 +4%, 1 001-10 000 +2%.
- **길드 보스 대전 (KR 3/19)** [INV-78]:
  - Win: EXP +16% and meso +16% for 7 days, plus 10 additional cubes.
  - Loss: EXP +7% for 7 days, plus 3 additional cubes.
  - Personal world-rank EXP buff for 7 days, by rank: 1st 25%, 2nd 20%, 3rd 15%, top 10 12%, top 100 10%, top 1 000 8%, top 10 000 6%, top 100 000 4%, everyone 2%.
- **Guild War: Dragon Warlord = 길드 대항전 (global, monthly guild rank)** [WIKI Guild_War]:
  - 1st: +16% EXP and meso for 7 days, plus 15 cubes
  - 2nd: +13%, 10 cubes
  - 3rd: +10%, 7 cubes
  - 4th: +7% EXP, 5 cubes
  - 5th: +5% EXP, 3 cubes
- **Guild raid:** cumulative-damage scrolls are in `content.md`. The Horntail clear medal gives final damage +3% [INV-82].
- **NOT FOUND:**
  - 토벌전 rank and score rewards
  - KR 대항전 rewards (only the point-table change is noted, at NV guild-contest)
  - 수련장 rewards
  - guild coin income per activity

## 16. Still missing (no source found on the allowed hosts)

1. **Elite summoning:** the base number of simultaneous elites; the item-level rule for elite gear; the income of gear stones (장비 강화석); dismantle (분해) yields.
2. **Weapons:** duplicates needed per awakening stage (only an unverified snippet says 5 per star); the values of 무기 마스터리.
3. **Character:** base HP/ATK/DEF/MP per level (and whether any exist); the player damage-taken formula (monster ATK vs player DEF).
4. **Growth dungeons:** reward amounts per stage for the weapon, equipment and hero-training dungeons (only the EXP dungeon and the enhancement scroll odds are known).
5. **World boss:** the one-time HP% reward amounts and the World Boss Coin shop.
6. **Guild:** KR reward tables for 토벌전, 대항전 and 수련장; guild coin income.
7. **Other rewards:** meso and elite amounts from PQs; monster park item rewards; Journey Treasure card amounts per step for the non-meso cards; artifact duplicates per awakening.
8. **Official KR patch-note text:** forum.nexon.com thread content is blocked for anonymous API calls ("no contents"). The KR 8/13 patch is known only through NV, as no inven repost of the full note exists.
