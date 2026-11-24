# 메이플 키우기 — Content Map (client 1.18.0)

Source: mapleidleindex.com mirror under `scratchpad/web` (client 1.18.0 tables, snapshot 2026-11-05). Full machine-readable data: `spec/content.json`.
Conventions: numbers are copied as given (big HP values stay strings in JSON). Korean names are kept as found. All dates are KST.
"NOT IN DATA" means the site has no table for it. Guide posts from /doongni/ are player opinions, so they only serve as evidence that a system exists.

## 1. Content inventory

| # | Content (Korean) | Type | Size / tiers | Entry / limit | Multiplayer | Rewards in data | Source |
|---|---|---|---|---|---|---|---|
| 1 | 챕터 사냥 | idle campaign hunt | 47 chapters, 555 hunt stages (ch1=4, ch2=8, ch3-28=10, ch29-38=15, ch39-47=20 stages; last stage of each chapter = boss) | unlimited; offline accrual 300~86400 s at 0.9 kills/s | solo | EXP per kill + burning EXP per stage | stage.html HUNT_ROWS; level-experience-117.json |
| 2 | 챕터 도전·보스 | campaign progression fights | 508 도전 + 47 보스 rows | sequential | solo | NOT IN DATA | stage.html TRIAL_ROWS |
| 3 | 무기던전 | growth dungeon | 150 stages, 머쉬맘 ×1, 22 s, every 10th stage 어려움 | NOT IN DATA | solo | NOT IN DATA | growth.html WEAPON_ROWS; content-simulator-data.js |
| 4 | 경험치던전 | growth dungeon | 150 stages, 20→35 kills, base 22 s (+4 s per 시간연장몹) | **하루 열쇠 최대 3개** (1 key = 1 sweep) | solo | expPerSweep 50000 (st.1) … 21690469919004900 (st.150); EXP% bonus not applied | growth.html EXP_ROWS; level-experience-117.json; leveling-ui.mjs |
| 5 | 장비던전 | growth dungeon | 150 stages, 75→120 kills, 30→40 s; pool 44 normal / 4 bomb / 2 speed | NOT IN DATA | solo | NOT IN DATA | growth.html GEAR_ROWS |
| 6 | 용사의 수련장 | growth dungeon | 150 stages; 30 s mobs + ≤20 s boss (clear in 50 s) | ticket "성장던전 입장권: 용사의 힘" (name-based link) | solo | NOT IN DATA | growth.html TRAINING_ROWS |
| 7 | 강화던전 | growth dungeon | 150 stages, 발록 ×1, 25 s | reward ticket (보상권), count NOT IN DATA | solo | scroll drop table (10% total per clear/sweep) | growth.html ENHANCE_ROWS + enhanceBody; scroll.html |
| 8 | 월드보스 | solo boss | 20 levels, 킹 캐슬 골렘; Lv20 unlimited HP; time 37 s (Lv1-2) / 75 s (Lv3-20) | NOT IN DATA | solo | NOT IN DATA | boss.html WORLD; content-simulator-data.js |
| 9 | 자쿰 보스레이드 | raid | 쉬움/보통/어려움/카오스 × party/single; body + 8 arms | 보스 레이드 입장권 (daily/weekly recharge, cap; values NOT IN DATA) | party ≤4 or single | equipment drops, scroll drops, sub-option odds | boss.html RAID + cards; scroll.html; itemlibrary.html |
| 10 | 혼테일 보스레이드 | raid | 4 difficulties × party/single; body + 8 spike parts | same ticket | party ≤4 or single | same | same |
| 11 | 핑크빈 보스레이드 | raid | 쉬움/보통/어려움 × party/single; body + 5 statues | same ticket; 480 s; deaths: team 15 (party) / personal 8 (single); companions disabled | party ≤4 or single | equipment + scroll drops | boss.html PINKBEAN_RAID |
| 12 | 자쿰 길드레이드 | guild raid | 1 tier | 480 s, team 5 deaths, 2 per user | guild ≤8 | cumulative-damage scrolls | boss.html GUILD_RAID; scroll.html |
| 13 | 혼테일 길드레이드 | guild raid | 1 tier | 480 s, team 10 deaths, 3 per user | guild ≤8 | cumulative-damage scrolls | same |
| 14 | 핑크빈 길드레이드 | guild raid | body 120조 + 5 statues (7조 2,000억 base) | opened 2026-10-16 20:00; needs 일반 핑크빈 보통+ clear; 480 s; revives 5 + 3/member (29 at 8) | guild ≤8 | NOT IN DATA | boss.html pinkbean-* tables |
| 15 | 신규 용사 성장 챌린지 · 마왕 발록 | event boss | 20 stages, 40→70 s; stage 20 unkillable | chars created after 2026-11-05 08:00, Lv30 | group shares boss HP | NOT IN DATA | boss.html GROUP_CHALLENGE |
| 16 | 파티 퀘스트 ×4 (첫 번째 동행, 차원의 균열, 여신의 흔적, 로미오와 줄리엣) | party dungeon | 4 difficulties each, dungeon Lv 45~125 | 탐험 티켓 (daily/weekly recharge, cap; values NOT IN DATA); 로미오 needs 22-10, 로미오 카오스 needs 37-15 | party (size NOT IN DATA) | EXP per run + accessory drop | droptable.html; party-experience-118.json |
| 17 | 몬스터파크 익스트림 | limited party event | 10 stages (unlock 17-10 … 44-20) | ticket: +2 every Mon 00:00, cap 2, 1 used only when the reward is claimed; 30 min | party ≤4, no companions | fixed EXP, +30% if preset Star Force ≥ threshold | droptable.html |
| 18 | 길드 토벌전 | guild score attack | 51 boss tiers | 50 s, +5 s for the first 10 kills (max 100 s) | guild (individual score) | NOT IN DATA | guild.html GUILD_BOSS |
| 19 | 길드 대항전 | guild vs guild (score) | 81 waves (6 minions + boss) | 35 s, +≤20 s per boss kill | guild | NOT IN DATA | guild.html GUILD_LEAGUE |
| 20 | 길드 보스 대전 | damage race | unlimited HP, 100 s | — | guild | NOT IN DATA | guild.html MATCH_STATES |
| 21 | 길드 수련장 | score hunt | 84 normal + 3 special spawn points, respawn table 1~50 | 90 s (+2 s per 30 kills) | guild | NOT IN DATA | guild.html TRAINING_* |
| 22 | 길드 현상수배 · 불꽃늑대의 소굴 | guild bounty | 100 stages, 120 s | ranking settled every Sunday | guild | clear score 100→7700 only | guild.html INFERNO_WOLF |
| 23 | 여정의 보물 | idle gauge reward | internal Lv 1~1000; gauge cap 200% | weekly acceleration (ad 1 + premium 1), Mon 00:00 reset | solo | reward contents NOT IN DATA | journey-treasure.json; event.html |
| 24 | 여정의 발자취 / 여정의 상자 | journey stages / boxes | stages 20,25,…45 seen | — | solo | NOT IN DATA | hotdeal unlocks; guide post 015 |
| 25 | 엘리트 몬스터 소환 | elite-mob farming | 엘리트 등급 13/21/28/29 seen | points (shop) | solo | NOT IN DATA | itemlibrary guide; shop |
| 26 | 빠른 사냥 | instant hunt | — | 빠른 사냥 티켓 | solo | NOT IN DATA | shop; event.html |
| 27 | 아레나 | **PVP** | tiers incl. 그랜드마스터5 | NOT IN DATA | PvP | NOT IN DATA (아레나 코인 mentioned) | hotdeal deal-015/054; guide posts |
| 28 | 미니게임 (오목, 카드게임) / 인내의 숲 | social | — | 오목 세트, 미니게임 전적 초기화권 | multi | NOT IN DATA | shop; guide post 027 |
| 29 | 무기·동료 소환 | gacha | weapon Lv1-19, companion Lv1-13 | 1 ticket or 20 / 50 레드 다이아 per summon | — | (summon spec) | summon-levels.json; companion-summon-rewards.json |

## 2. Key stats (first → last tier; full rows are in content.json)

- 무기던전 HP 2000 → 3081876196773700000000; ATK 320 → 6157592529; DEF 50 → 7500; avoid 7 → 565.
- 경험치던전 normal1 HP 800 → 923075583937946000000; ATK 20 → 1816210468. The 시간연장몹 gives +4 s and a 10 s move-speed and attack-speed buff.
- 장비던전 normal HP 1440 → 625855840905470000000; ATK 16 → 290439724. The bomb mob explodes about 0.3 s after death (radius 3,300). The yellow speed mob gives 5 s of move speed.
- 용사의 수련장 boss HP 70000 → 6489749281163300000000. Each kill gives +2% ATK and +1% move speed for 60 s (max 100 stacks). Buff mobs give 5 ATK stacks plus 5 attack-speed or move-speed stacks.
- 강화던전 발록 HP 1800000 → 52724517857947400000000; ATK 4800 → 14292724054. BossDown starts at 20.6 s and lasts 4 s (DEF −100%, ATK speed +100%), repeating every 22 s.
- 월드보스 HP 200000 → 328239843750000000 (Lv20 unlimited); ATK 415 → 68309435; DEF 1500 → 62100. Untargetable for 3.5 s every 35 s.
- 자쿰 raid body HP (party): 쉬움 26102400 / 보통 153674600 / 어려움 4640041400 / 카오스 37189874440. Each arm has the same HP as the body. DEF 60000. Single mode HP is lower; ATK/DEF/avoid are the same as party.
- 혼테일 raid "보스 판정 HP" (party): 13000000000 / 104000000000 / 832000000000 / 6656000000000. Each spike part: 9100000000 / 72800000000 / 582400000000 / 4659200000000. DEF 100000.
- 핑크빈 raid body (party): 160000000000 / 2080000000000 / 22880000000000. Each statue: 8800000000 / 114400000000 / 1258400000000. DEF 20000. ATK 6000000 / 16800000 / 67200000.
- 길드레이드: 자쿰 body 19528353600 (DEF 100000). 혼테일 4160000000000 + 8 × 2912000000000.
- 핑크빈 길드레이드 statues start at 2조 8,800억 (−60%). After that their max HP is 7.2조 × 1.25^(n−1) by shared seal count. A seal heals the other statues by 58~62% of their max HP.
  - Seal buffs: 아리엘 최종뎀 +40% 45 s · 솔로몬 공속 +60% (MP +3%) 45 s · 렉스 버프지속 +50% 80 s · 휘긴 쿨감 +40% (MP +3%) 70 s · 무닌 디버프·행동불가 차단 30 s.
  - The body's damage reduction is 0% at 100% HP, rising to 95% at 5% HP. Groggy adds −100%p for 10 s. Player damage goes through an integer square root.
- 마왕 발록 challenge HP 54933200 → 3282398437500000000; ATK 415 → 68309435; DEF 1500.
- 길드 토벌전 HP 600000 → 64112690160012000000000000000000; DEF 100000 → 600000; time 50 → 100 s.
- 길드 대항전 boss HP 36000000 → 149632918428401000000000000. The boss has a 60% shield and minions a 30% shield.
- 불꽃늑대 HP 4940000000 → 1064400000000000000000000000000; clear score 100 → 7700.
- Guild score: 19 brackets of nested roots (n = 1.10 … 2.00). 토벌전 cap T starts at 100만; 대항전 starts at 100 점.
- 길드 수련장 normal-mob score = 3 × [100 × 순번 + 3 × (순번 − 1)³].
- Party quests (EXP per run, base clear, EXP% not applied):

| PQ | 쉬움 | 보통 | 어려움 | 카오스 | slot |
|---|---|---|---|---|---|
| 첫 번째 동행 (Lv 45/65/85/95) | 4037821 | 326329838 | 10780277700 | 74952031500 | 반지1 |
| 차원의 균열 (75/90/100/110) | 1861294800 | 25317570500 | 114888981600 | 190571149800 | 목걸이 |
| 여신의 흔적 (80/95/105/115) | 5444772900 | 37977575400 | 143615842800 | 413324691000 | 얼굴장식 |
| 로미오와 줄리엣 (95/105/115/125) | 29979849000 | 113371672200 | 335557352100 | 1169798925760 | 반지2 |

- 몬스터파크 익스트림 EXP: st1 (17-10) 4,400,000,000,000 at SF 110 … st10 (44-20) 15,408,325,195,312,500 at SF 355; ×1.3 with the Star Force bonus. Mechanics: 4 missions × 15 kills. 빅풋 flees after 20/40/60/80 s on appearances 1-4. 재카로프 adds +10 to all missions.

## 3. Rewards and currencies found per content

| Content | Reward (exact) | Source |
|---|---|---|
| 강화던전 | Random enhancement scroll on 10% of clears/sweeps. Per stage band: 노말40% 10% (st1-29) falling to 1% (110+); 레어40%/25% each 0.5% (30-39) up to 3% (110-119), then 2.5% at 150; 에픽70/30/15% each 0.1667% (60-69) up to 1.3333% (150). First-clear bundle separate (NOT IN DATA). | growth.html enhanceBody; scroll.html |
| 자쿰 raid | 자쿰의 투구 (쉬움 유니크 상급 9% / 보통 유니크 최상급 9% / 어려움 레전더리 하급 9%), 아쿠아틱 레터 눈장식 15% (카오스 20%), 카오스 자쿰의 투구 (어려움 1%, 카오스 5%). 버닝UP doubles each rate. Scroll 자쿰의 주문서(하급) 쉬움 4% / 보통+ 3%; (중급) 보통+ 1%. | boss.html; scroll.html |
| 혼테일 raid | 데아 시두스 이어링 23% (쉬움/보통), 15% (어려움), 20% (카오스); 혼테일의 목걸이 어려움 9%; 카오스 혼테일의 목걸이 1% (어려움) / 5% (카오스); 혼테일의 주문서 as for 자쿰. | same |
| 핑크빈 raid | 핑크빛 성배 23%/2% (쉬움, 보통), 15% (어려움); 블랙빈 마크 9% (어려움); 카오스 핑크빈 마크 1% (어려움); 핑크빈의 주문서 쉬움 4% / 보통+ 3% (하급), 보통+ 1% (중급). | same |
| 자쿰/혼테일 길드레이드 | Cumulative damage 10%·40%·80% → 하급 scroll ×3 each; 50%·90% → 중급 scroll ×2 each (guaranteed). | scroll.html |
| Party quests | Accessory drop 쉬움 25% (버닝UP 35%), others 20% (30%). Sub-option lines 1/2/3 = 40/40/20% (min 1). Item level ranges per difficulty in json. | droptable.html; itemlibrary PARTY_META |
| 경험치던전 / 몬스터파크 / PQ / 사냥 | EXP tables (json) | level-experience-117.json; party-experience-118.json |
| Raid sub-options | e.g. 자쿰의 투구 유니크 0/1/2 lines 30/40/30%; 레전더리 30/35/25/10% (4-player 901 set; single-mode gear uses different odds, NOT IN DATA). | itemlibrary.html |

Currencies and items seen (97 in hotdeal data plus shop): 블루 다이아 (paid; 1 = 1원), 레드 다이아, 메소, 무기/동료 소환권, 3차/4차 전직 동료 소환권, 미스터리 무기/동료 소환권 상자, 무기 강화석, 명예의 훈장, 용사의 증표, 주문의 흔적, 스타포스 강화 주문서, 미라클 큐브, 에디셔널 큐브, 메모리얼 스크롤, 유물상자, 픽업 유물상자, 레전드리 유물 소환, 유물 강화석, 엘리트 몬스터 소환 포인트, 여정의 증표, 여정의 기운, 여정의 상자 열쇠, 보스 레이드 입장권, 탐험 티켓, 성장던전 입장권: 용사의 힘, 빠른 사냥 티켓, 시간 단축 티켓(1분), 경험치 부스터(100%), 버닝 필드 부스터, 1000% 스페셜 핫타임 부스터 티켓, 장비 부 옵션 변환석, 최상급 마법 부여 주머니, 카오스 링 강화석, 부티크 기프트, event tokens (단풍잎, 한과, 솜사탕, 도깨비 복주머니, 여름 보물 열쇠, 시험의 증표 …), 25 artifact items (성배, 낡은 오르골 …). Full list: `itemsAndCurrencies_glossary`.

## 4. Resets and limits (all that exist in data)

- 경험치던전: max 3 keys per day.
- 몬스터파크 입장권: +2 every Monday 00:00, auto-recharge cap 2, starts with 2. A ticket is used only when the reward is claimed; a failed run costs nothing. Practice 도전 모드 is free and gives no reward.
- 여정의 보물: the weekly acceleration count resets Monday 00:00; the gauge and internal level persist. Each use gives +20% (60%), +25% (30%) or +30% (10%).
- 불꽃늑대의 소굴: ranking settles every Sunday.
- 돌아온 브루스 weekly scroll mission: resets Monday.
- 보스 레이드 입장권 / 탐험 티켓: "일간 / 주간 충전 시 최대 보유량" exists, but the amounts are NOT IN DATA. Raids also have a "보상 횟수" (reward count) and 소탕 (sweep).
- Shop: per-row weekly / monthly / once limits (json `regularShop_baselines`).
- Offline reward: 300 s min, 86400 s max, 0.9 kills/s. Premium ×1.7 applies to journey treasure.
- Burning field booster: 600 s, about 400 burning kills.

## 5. Paid-only reward sources (remove or replace)

- **Hotdeals: 250 deals, all paid.** 141 cash (KRW, price "check in game"), 108 blue diamond, 1 red diamond (deal-005 웰컴 에픽 무기, 100 red). 27 were added in 1.18 (hotdeal-release.json). They are unlocked by progress or events and delivered by mail.
  - Summon tickets come from: job-advance deals (무기 소환권 300; 동료 소환권 250), summon-level deals (무기 1000→8000; 동료 140→2100), blue-spend deals, and event deals (e.g. 성장 던전 15일 출석 응원 동료 소환권 3000).
- **Regular shop: 76 rows.** 61 blue diamond (weekly 23, monthly 14, ordinary 24), 14 red diamond, 1 cash (월간 PC버전 패키지: 블루 30000 + 미라클 큐브 15). Blue-priced summon rows:
  - Weekly: 무기 소환권 420 (6000, 5/wk), 무기 2000 (30000, 5/wk), 동료 170 (6000, 5/wk), 동료 820 (30000, 5/wk).
  - Monthly: 무기 250 / 동료 100 (3000, 10/mo).
  - Red-diamond rows: 무기 소환권 100 = 1000 red (1/wk), 동료 소환권 30 = 750 red (1/wk). Red diamond can also be bought 1:1 with blue ("레드 다이아 1,500개" = 1500 blue). Free sources for red diamond are NOT IN DATA.
- **Limited products (blue):**
  - 특별 무기 소환권 패키지: 820 tickets for 9000, 5/month.
  - 특별 무기 소환권 패키지 2: 4200 for 45000, 10/month.
  - 특별 용사의 힘 패키지: 11 성장던전 입장권 for 6000, 10/month.
  - All three ended 2026-11-05.
- **신비한 10월 출석 패키지** (30000 blue, 14 days, chapter gate 3-4): pays back 블루 다이아(무료) 30000 + 용사의 힘 입장권 4 + 미라클 큐브 30 + 알쏭달쏭 주문서 9.
- **무기 소환 패스7** (100 steps; requiredSummons 259000→394000):
  - Free track: 2,750 무기 소환권 in total. This counts as a free source.
  - Paid track: 8,460 tickets + 에인션트 최상급 공용 무기 ×1.
- **신규 동료 픽업 소환 패스 1/2/3** (30/50/50 steps; final step at 6,500/20,000/35,000 summons): rewards NOT IN DATA.
- **명예의 훈장 bundles:** 3,500 for 3,000원 (10/month); 10,000 for 10,500원 (15/week); 2,000 for 3,000원 (unlimited).
- **Enhancement store:** cube, star and meso packages in enhancement-store-rules.json.
- **Royal cosmetics:**
  - 로얄스타일 costumes: 32 editions (2025-11 → 2026-11-26). The gacha price is NOT IN DATA.
  - 로얄 성형: 3,500 blue; 로얄 헤어: 5,500 blue (19 editions each).
  - 부티크: priced in 부티크 기프트 tickets (75/40/20 per piece, 750 per package, 400 per hair). The tickets come from cash deal-218.
- **Membership** (guide post): 광고제거 (1년), 스페셜 (월 3,000원: elite storage 200%, +1 fast hunt/day), 프리미엄 (월 12,000원: elite +3 levels, double pass red diamonds, offline ×1.7, +1 weekly acceleration). 회원권 EXP +10%/+5%.
- **Ads** grant the journey weekly acceleration and booster time. These are not paid, but need a replacement trigger.

## 6. Events, missions, attendance, achievements (names only; rewards NOT IN DATA)

44 events are referenced by hotdeal unlocks (json `events_fromHotdealUnlocks`, with unlock windows):

- **Seasonal:** 설맞이, 새해에도 메키와 함께!, 발렌타인, 봄맞이 성장 미션, 15일간 쑥쑥! 봄날의 성장, 여름맞이 10일 출석/보물 찾기!, 무더운 여름, 한가위 풍성한 출석, 신비한 10월, 마녀의 캔디 선물.
- **Anniversary:** 반주년 메키 페스티벌 (포인트/특별 미션/스탬프), 1주년 전야제, 1주년 메키 살롱 (포인트/특별 미션/반지 공방 → 1주년 이벤트 반지).
- **Growth festivals:** 미라클 Power UP, 미라클 부스팅, 여정의 증표 Power UP, 엘리트 몬스터 소환 Power Up, 유물 발굴 대작전!, 주간 유물 발굴 대회!, 카산드라의 큐브 점성술, 달콤한 큐브 축제, 기사단의 펜던트 강화.
- **Scroll events:** (돌아온) 브루스의 주문서 특강, 도깨비 복주머니 교환소 (rates in json), 알쏭달쏭 도깨비 복주머니.
- **Boss challenge events:** 도전! 자쿰/혼테일/핑크빈 레이드.
- **Attendance:** 월간 출석 이벤트 (days 5, 28 referenced), 시그너스 15일, 성장 던전 15일, 여름맞이 10일, 한가위, 1주년 전야제.
- **Daily missions:** 일일 미션 부스트, 핑크빈 일일 미션 (+부스트), 도깨비 일일 미션, 팡팡! 물풍선 모으기, 마녀의 캔디 선물 [일일] 몬스터 1,000마리. Also 돌발 미션 (scroll: 노말 주문서 2장).
- **Weekly:** 돌아온 브루스 (강화 100/120/150회 → 하급 3 / 중급 3 / 확신 1).
- **Achievements:** only "[업적] 동료 소환하기" and "[업적] 아레나 플레이하기" are seen.
- **Guide quests (11 seen):** 동료 소환하기, 페리온-10, 엘리니아-4/6, 슬리피우드-10, 오르비스-10 돌파, 용사의 힘 2단계, 첫 번째 스킬 마스터리, 스타포스 3단계, 어빌리티 변환, 유물 공명 증폭.

## 7. PVP findings

- **아레나 (Arena)** is the PVP mode, but the site has no data for it. Evidence:
  - deal-015 "아레나 랭커 유물 핫딜" is unlocked by "아레나 최고 티어 그랜드마스터5 이상", so arena has ranked tiers.
  - deal-054 is unlocked by "[업적] 아레나 플레이하기".
  - Guide posts mention 아레나 코인, "pvp" balance, and "아레나용" gear sets.
  - Unknown: format, unlock, entry count, season, tier list, rewards, 아레나 코인 shop.
- **길드 대항전** is guild-vs-guild only through PvE score (full wave and score data exists). 길드 토벌전, 불꽃늑대 and 길드 보스 대전 are ranked score attacks.

## 8. Systems mentioned but lacking data (ask the user)

1. Rewards for 월드보스, 무기/장비던전, 용사의 수련장, 길드 토벌전/대항전/보스 대전/수련장/현상수배 (guide post: "코인 + 장비옵션변환"), 핑크빈 길드레이드, 마왕 발록 challenge, chapter clears.
2. Entry counts: daily/weekly free ticket recharge for 보스 레이드 입장권 and 탐험 티켓, growth-dungeon keys (only the EXP dungeon's 3/day is known), world boss attempts.
3. Unlock conditions for most content. Known: 몬스터파크 17-10+, 로미오 22-10, 로미오 카오스 37-15, 핑크빈 길드레이드 = 일반 핑크빈 보통 clear. Shop gates hint at 보스 레이드 입장권 13-10, 탐험 티켓 7-5, 도전 events 13-10 / 26-10 / 32-15.
4. Party quest party size, time limits, and death limits for party-mode 자쿰/혼테일.
5. Arena (all of it), 아레나 코인.
6. Rewards for journey treasure claims; the 여정의 발자취 stage list, option pool and 여정의 상자 contents.
7. Elite monster summon: point income, 엘리트 등급 table, drop table. Also the 빠른 사냥 formula and free count.
8. Lists and rewards for daily/weekly missions, achievements, attendance calendars, guide quests and event rewards.
9. Rewards of passes 1-6 and of the companion/ability passes; the royal style gacha price; membership details (beyond the player post).
10. Guild system: levels, guild mastery (마스터리), 시간단축, donations, ranking rewards, server merge.
11. Minigames (오목, 카드게임), 인내의 숲, 메키 살롱 event shop, 스타포스 필드 event.
12. Unpublished map files AntCave_Exp.json and GearDungeon_2.json (spawn layouts). Korean names for chapters 1-44 (only 45-47 are named: 골드비치).
13. Meso income anywhere (hunting, dungeons); meso is only seen as a shop item.

## 9. Source files

| File (under scratchpad/web) | Used for |
|---|---|
| boss.html (+ text/boss.txt) | world boss, raids, guild raids, Pink Bean guild raid, 발록 challenge, raid drops |
| growth.html | 5 growth dungeons, 강화던전 scroll table |
| guild.html | 토벌전, 대항전, 보스 대전, 수련장, 현상수배 |
| stage.html | chapter hunt / challenge / boss monster stats |
| droptable.html, js/assets/partyquest-tabs.js | party quests, monster park |
| js/calculator/data/content-simulator-data.js | dungeon/world-boss creatures, time limits, patterns, supporter spawn |
| js/data/level-experience-117.json, party-experience-118.json | EXP, offline and burning rules, EXP dungeon sweep, PQ EXP |
| js/data/journey-treasure.json, event.html, js/assets/journey-treasure.js | 여정의 보물 |
| js/assets/hotdeal-catalog.json (+ hotdeal-release.json, hotdeal-discovery.js) | 250 hotdeals, 76 shop rows, events, guide quests, item glossary |
| js/data/market-information-117.json | limited products, attendance package, weapon pass 7 |
| js/royalstyle/editions.json, js/api/royalstyle-*.json, royalstyle.html | royal cosmetics |
| scroll.html, itemlibrary.html, companion.html, heroability.html | scroll rewards, raid sub-options, PQ item levels, pickup passes, medal bundles |
| js/data/summon-levels.json, companion-summon-rewards.json, enhancement-store-rules.json | summon costs, store packages |
| js/api/my-guide/post-*.json (doongni) | evidence that systems exist (player opinion) |
| chahuji.html | community "보스버스" carry queue (not game content) |

Scripts in `spec/scripts/`. Run `sh content_run_all.sh <scratchpad>` to rebuild everything; it runs these in order:
- `content_01_dump_inline_scripts.py` → work/content_inline
- `content_02_extract_const_json.py` → work/content_consts
- `content_03_extract_static_tables.py` → work/content_tables
- `content_04_build_content_json.py` → spec/content.json
