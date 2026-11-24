# Arena, World Arena, Colosseum and other PvP: research spec

Compiled 2026-11-24. Research only. No addon code.

Machine-readable twin: `research-arena.json` (same folder). Raw pages: `../web/research/arena/` (KR official threads in `nexon-kr/`, global in `nexon-global/`, DC Inside in `dc/`, Inven in `inven/`, player posts from the official forum in `nexon-kr-free/`).

**Reuse note.** `research-income.md` §5.2 and §6.2 already hold the arena shop limits and the tier coin tables. §6 below repeats the tier table only so this file stands alone.

## Reading guide

**Confidence labels**
- **[OFF]**: official Nexon text (KR or global forum).
- **[COM]**: community source (wiki, maplestoryidle.info, Inven, DC Inside, or a player post on the official board).
- **[INF]**: my inference. Never treat it as data.

**Source keys** are listed in §10. Every key has a URL, a region and a date.

**Region.** KR (메이플 키우기) and global (MapleStory : Idle RPG) use the same patch dates and the same numbers since the November 2025 launch. Example: the 9/22 arena table is identical in NXKR_PN_0922 and NXGL_PN_0922.

**Percent stats** are stored per-mille inside the game (1000 = 100%). A multiplier is `(1000 + stat) / 1000`. [OFF NXKR_PN_0702]

---

## 1. Modes at a glance

| Mode (KR / EN) | Real PvP? | Opponent | When | Main reward | Source |
|---|---|---|---|---|---|
| 아레나 / Arena | Yes. You attack another player's AI-controlled defense snapshot | Server ranking list | Always on. Points reset weekly | 아레나 코인 (daily and weekly), 스타포스 강화 주문서 (weekly), meso/EXP buff (weekly) | NXKR_PN_0922, NXKR_PN_0430 |
| 결투장 친선전 / Friendly duel | Yes. Unranked | Any player, from their profile | Always on | None | NXKR_PN_1127 |
| 월드 아레나 / World Arena | Yes. Arena rules plus extras | Same region, all servers | 5-day rounds. 3 rounds ran in July 2026 | 미라클 큐브 (individual), 에디셔널 큐브 and EXP booster (guild), chairs | NXKR_PN_0702 |
| 콜로세움 / Colosseum | Yes. Bingo board | 25-player group, same region, all servers | Event rounds (Tue 12:00 to Sat 21:59) | 스타포스 강화 주문서, 메소 | NXKR_PN_0129 |
| 길드 대항전 / Guild War | **No.** Members fight a boss for score | 5 guilds per group | Weekly | Guild buff, 미라클 큐브 | NXKR_PN_1127 |
| 길드 보스 대전 | **No.** Guild vs guild, compared by boss damage | 1 matched guild | Seasons | (not researched) | NXKR_PN_0521 |

---

## 2. Arena battle rules

### 2.1 Format
1. **Snapshot fight.** The attacker plays live. The defender is an AI-controlled snapshot of the opponent's arena-defense setup.
   - Since 2025-11-27 the attack and the defense each use their own preset number. [OFF NXKR_PN_1127]
   - On 12/18 the per-content "던전 프리셋" replaced this. It sets skill, companion, ability, artifact and equipment presets for each content. [OFF NXKR_PN_1218]
   - Defense logs sometimes show an older setup than the player's current one. [COM DC327440]
2. **Control.** The attacker can play manually (move, jump, time skills and buffs) or use Full Auto. [COM MSI_ARENA, IV723]
3. **Quick battle (빠른 전투)**, added 9/3. [OFF NXKR_PN_0903]
   - Available when your CP is at least **5×** the opponent's.
   - It runs the same auto-battle logic on the current attack and defense presets, so a win is not guaranteed.
   - Ticket cost, rewards, ranking, record and replay are the same as a normal fight.
4. **Battle speed** ×1, ×1.5 or ×2. Arena, guild war and guild training only. The setting is remembered between fights. [OFF NXKR_PN_0903, NXKR_FAQ_SPEED]
5. **Win and loss conditions**
   - Win by bringing the opponent to 0 HP.
   - Leaving right after the start counts as a normal loss. [COM DC40865]
   - A disconnect while entering also counts as a loss. [COM NXKR_FREE_1005 (KR free board thread 3558555)]
   - In Colosseum, time-over was reported as a loss for the attacker. [COM DC286679]
6. **Time limit: NOT FOUND.**
   - A community model used about **15 s** per Arena fight and about **30 s** per Colosseum fight. These are typical lengths, not caps. [COM DC276959, 2026-03-25]
   - On 4/30 Nexon lowered Arena damage at high CP (longer fights) and raised it at low CP. It raised Colosseum damage at high CP (shorter fights). [OFF NXKR_PN_0430]
7. **Companions take part.**
   - The main companion is summoned in battle. Since 7/2 its auto-summon On/Off is saved per dungeon preset. [OFF NXKR_PN_0702]
   - Defender companions act too. Dark Knight gives basic-attack-damage immunity and healing. Hero gives a shield and a stun. [COM IV723, IV809]
8. **Potions** work, but their effect is reduced in Arena and Colosseum. [COM WIKI_ARENA, WIKI_COLO]
9. **Stats that do not apply in PvP**
   - Boss Monster Damage and Normal Monster Damage do nothing, because players are neither. [COM WIKI_CHARSTATS, MSI_COMP, IV809]
   - Since 10/15 the PvP CP formula also excludes them, plus "basic attack target count". [OFF NXKR_PN_1015]
10. **Stats that matter more in PvP**
    - The 10/15 PvP CP formula weights these higher than the PvE one: Accuracy, Evasion, Damage Taken Decrease, Critical Resistance and Debuff Tolerance. [OFF NXKR_PN_1015]
    - Critical Resistance lowers the attacker's crit rate. Accuracy against Evasion decides MISS. [COM IV809]
11. **Arena-only effects**
    - Artifact 영혼의 주머니 (Soul Pouch): "[Arena] Final Damage +20/24/28/32/36/40%". [COM WIKI_ARTIFACTS] It also works in World Arena. [OFF NXKR_PN_0702]
    - Client data condition: `$CheckDungeonType(Arena) > 0 || $CheckDungeonType(WorldArena) > 0`, with FinalDamage 200…400‰. [COM IDX_DATA]
    - Two OnStart passives (ids 808360 and 808470, names not identified) give Final Damage +20% outside Arena and +40% inside Arena. [COM IDX_DATA]
12. **Friendly duel (결투장 친선전)**
    - Start it from the other player's profile.
    - It is unranked. Players can refuse duels in Settings. [OFF NXKR_PN_1127]
    - Since 12/18 the records appear in Arena battle records and can be shared. [OFF NXKR_PN_1218]
13. **Separate preset types** exist in the client for Arena (9), Colosseum (18) and World Arena (25). [COM IDX_DATA artifact-preset-data.js]

### 2.2 PvP damage formula (Arena, Colosseum and World Arena since 2026-07-02) [OFF NXKR_NT_0625, NXKR_PN_0702]
```
피해 = √( 공격력
 × 5,000 ÷ ( 6,000 + 방어력 × (100% − 방어 관통력%) )
 × 받는 피해 증가% × (100% − 받는 피해 감소%)
 × (100% − 던전용 받는 피해 감소%)
 × 데미지% × 데미지 증폭%
 × (기본 공격 데미지% 또는 스킬 데미지%) × 스탯 비례 데미지%
 × 마스터리 피해량 증가%
 × 던전용 피해량 증가%
 × 크리티컬 발생 시 크리티컬 데미지% × (최소 데미지 배율% ~ 최대 데미지 배율%)
 × 상태이상의 적에게 상태이상 데미지% × 최종 데미지% )
 × 스킬 계수%
 × 결투장 보정으로 레벨에 의한 피해량 감소% x 2
 × [콘텐츠 전용 상수 : 아레나 7,206,000,000 / 콜로세움 4,323,600,000 / 월드 아레나 5,764,800,000]
 ÷ ((( 공격력 × 방어 관통력% × 데미지% × 데미지 증폭%
      × ( [기본 공격 데미지 + 스킬 데미지] ÷ 2 )%
      × 스탯 비례 데미지% × ( 크리티컬 데미지 × 크리티컬 확률의 비중(최대 100%) )%
      × ( 최소 데미지 배율 + 최대 데미지 배율 ) ÷ 2
      × 최종 데미지% + 1,000,000,000)^0.23
    × (최대 HP * 100,000,000) ^0.12
    × (( 방어력 + 6,000 ) * 1,000,000,000,000)^0.14
    × ( ( 100% + 받는 피해 감소% ) x 1,000,000 )^0.5)
   ÷ 10,000,000)
 ÷ 1,000,000
```
- **Whose stats count** [OFF]
  - In the √ base part, offensive stats are the attacker's and defensive stats are the target's.
  - In the divisor (the PvP reduction), both the offensive and the defensive stats are the **target's**.
  - Those divisor stats are taken **before the fight**. Active skills, buffs and on-start effects do not change them.
- **Content constant.** World Arena = 0.8 × Arena, so World Arena deals and receives 80% of Arena damage. Colosseum = 0.6 × Arena. [OFF + arithmetic]
- **Level correction (결투장 보정)** [OFF NXKR_NT_0625, NXKR_PN_0702]. Each extra character level changes final damage relative to the previous level:

| Level band | Arena / World Arena | Colosseum |
|---|---|---|
| 31-60 | −0.5% per level | −0.5% per level |
| 61-70 | −1.3% per level | −1.3% per level |
| 71-100 | −1.3% per level | −1.5% per level |
| 101+ | −1.5% per level | −2.5% per level |

  - Open question: whose level counts, and how the "× 2" combines.
  - The global wiki says damage *taken* drops with the character's level. [COM WIKI_ARENA]
- **History**
  - Before 1/29 (Colosseum) and 4/30 (Arena), the base damage was simply square-rooted. The same sqrt is still used in Boss Raid, Party Quest and Guild Training. [OFF NXKR_NT_0622]
  - From 1/29 (Colosseum) and 4/30 (Arena) to 7/2, the tail was `× 상수(아레나 10,000 / 콜로세움 6,000) × 최대 HP ÷ √(offense product) ÷ 1,000,000`.
    - Bug: Max HP raised damage taken, so HP gave no survival, and offensive stats lowered incoming damage.
    - Compensation: 2× the arena coins and star force scrolls earned 5/1-6/22, 2× the Colosseum scrolls, plus 100 miracle cubes, 100k 명예의 훈장 and 10M meso for everyone. [OFF NXKR_NT_0622, NXKR_NT_0623, NXKR_NT_0625]

---

## 3. Unlock, tickets and opponent list (Arena)

| Item | Value | Conf. | Source |
|---|---|---|---|
| Unlock | Guide Quest 247 | OFF event text / COM | IV610 (official event text), IV161, IV398, WIKI_UNLOCKS |
| Unlock (older wiki row) | Chapter 8-3 | COM | WIKI_UNLOCKS |
| Daily free tickets | 5 at 00:00 server time | COM | WIKI_ARENA, IV114 |
| Ticket cap | 20. Natural refill stops at 20, and the UI does not show the cap | COM | WIKI_ARENA, IV114, DC210296, DC328970 |
| Cost per attack | 1 ticket, win or lose (quick battle too) | COM / OFF | WIKI_ARENA, NXKR_PN_0903 |
| Extra tickets | Buy with 레드 다이아 when you have 0 tickets. "15 tickets for 1,000 RD" per day, which is 7,000 RD a week. Posts mention up to 5 refills a day | COM | DC35341 (2025-11-17), DC142351, DC262988, DC373144, DC421871 |
| Extra-charge daily cap | Exists ("아레나 추가 충전 최대 횟수" bug fix). The number is not published | OFF | NXKR_PN_0922 |
| Per-refill price | **NOT FOUND**. A 5 × 3-ticket ladder adding up to 1,000 fits [INF] | — | — |
| Opponent list refresh | 3 free; 1 free refresh regenerates every 10 min; then 150 레드 다이아 each | COM (global) | WIKI_ARENA |
| Who appears | "Recommended opponents" near your ranking score. Losing defenses (lower score) makes weaker opponents show up | COM | NXKR_NT_1112, DC150494 |
| List size | **NOT FOUND** | — | — |
| Daily-reward condition | Play at least one battle that day to get the next daily settlement | COM | IV263 |

## 4. Score, tiers and seasons (Arena)

| Item | Value | Conf. | Source |
|---|---|---|---|
| Attack win | About **+20** base, scaled by CP. +31 and +42 were seen against the same opponent. Doubling your own arena CP halved the gain | COM | DC402379 (2026-08-28), DC331367, DC351074, DC111613 |
| Attack loss | **NOT FOUND** | — | — |
| Defense win | **+5** | COM (player post on official board, 2026-11-13) | NXKR_FREE_1113 |
| Defense loss | **−9** | COM (same post) | NXKR_FREE_1113 |
| Weekly reset | Ranking points reset at the weekly settlement, Monday 00:00 | OFF | NXKR_PN_0430 / NXGL_PN_0430 (bug fix "ranking points failed to reset at weekly settlement"), NXKR_NT_0430, DC111613 |
| Start score | **NOT FOUND** for Arena. World Arena and Colosseum both start at 1,000 | — | NXKR_PN_0702, DC425800 |
| Observed top scores | Server #1 at about 5,870-6,000 at week end. On one server, #2 was 80 points behind #1 | COM | DC295702, DC146987 |
| [INF] check | A 1,000 start, about +20 per win and about 245 wins a week (35 tickets × 7) give about 5,900, which matches | INF | — |
| Daily settlement | 00:00 daily; weekly Monday 00:00 (KR: KST). Rewards arrive by mail | OFF | NXKR_FAQ_RANK, NXGL_FAQ |
| Per-battle coins | Win **30**, loss **20** 아레나 코인 (seen before the 9/22 increase; not re-checked after) | COM | DC35341, DC150494 |

**Tier ladder (high → low), from the 9/22 tables** [OFF NXKR_PN_0922 / NXGL_PN_0922]

챔피언 1-3, 챌린저 1-5, 그랜드마스터 1-5, 마스터 1-5, 다이아몬드1, 플래티넘1, 골드1, 실버1, 브론즈1.

English names: Champion, Challenger, Grand Master, Master, Diamond, Platinum, Gold, Silver, Bronze.

- **How a tier is assigned.** It comes from your *rank position* on the server at settlement.
  - A player who was ranking #1 was shown as 챔피언1. [COM DC111613]
  - Players talk of cut-offs at rank 1,000 and 2,000. [COM DC150494]
  - World Arena publishes rank ranges for the same tier names (§7.4). Arena's own ranges are **NOT FOUND**. Copying the World Arena ranges would be [INF].
- **Divisions.** Below Master only "…1" appears. Whether Diamond 2-5 and the lower divisions exist is **NOT FOUND**.
- **"Highest tier reached" is tracked**
  - The 아레나 랭커 유물 핫딜 (a paid offer, ignore it) unlocks at "아레나 최고 티어 그랜드마스터5 이상". [COM content.md / hotdeal data]
  - Newbie missions ask you to reach 아레나 플래티넘, 다이아몬드 and 마스터. [COM research-income §3.5]
- **Promotion reward (승급보상).** It is paid in arena coins: one player lost two of them, worth "4,000 coins". Amounts are **NOT FOUND**. [COM DC148153, DC151167]

## 5. Rewards (Arena)

### 5.1 Tier rewards, daily and weekly (9/22 change) [OFF NXKR_PN_0922; identical in NXGL_PN_0922]
| 티어 | Daily 아레나 코인 (before → after) | Weekly 아레나 코인 (before → after) | Weekly 스타포스 강화 주문서 (before → after) |
|---|---|---|---|
| 챔피언1 | 1,500 → 2,000 | 3,000 → 4,000 | 50 → 60 |
| 챔피언2 | 1,400 → 1,900 | 2,800 → 3,800 | 46 → 56 |
| 챔피언3 | 1,300 → 1,800 | 2,600 → 3,600 | 42 → 52 |
| 챌린저1 | 1,200 → 1,700 | 2,400 → 3,400 | 38 → 48 |
| 챌린저2 | 1,100 → 1,600 | 2,200 → 3,200 | 34 → 44 |
| 챌린저3 | 1,000 → 1,500 | 2,000 → 3,000 | 30 → 40 |
| 챌린저4 | 950 → 1,400 | 1,900 → 2,800 | 26 → 36 |
| 챌린저5 | 900 → 1,300 | 1,800 → 2,600 | 24 → 34 |
| 그랜드마스터1 | 850 → 1,250 | 1,700 → 2,500 | 22 → 32 |
| 그랜드마스터2 | 800 → 1,200 | 1,600 → 2,400 | 20 → 30 |
| 그랜드마스터3 | 760 → 1,150 | 1,520 → 2,300 | 18 → 28 |
| 그랜드마스터4 | 720 → 1,100 | 1,440 → 2,200 | 16 → 26 |
| 그랜드마스터5 | 680 → 1,050 | 1,360 → 2,100 | 14 → 24 |
| 마스터1 | 650 → 1,000 | 1,300 → 2,000 | 12 → 22 |
| 마스터2 | 620 → 970 | 1,240 → 1,940 | 10 → 20 |
| 마스터3 | 590 → 940 | 1,180 → 1,880 | 8 → 18 |
| 마스터4 | 560 → 910 | 1,120 → 1,820 | 6 → 16 |
| 마스터5 | 530 → 880 | 1,060 → 1,760 | 6 → 14 |
| 다이아몬드1 | 500 → 850 | 1,000 → 1,700 | 4 → 12 |
| 플래티넘1 | 400 → 800 | 800 → 1,600 | 4 → 10 |
| 골드1 | 300 → 700 | 600 → 1,400 | 2 → 8 |
| 실버1 | 200 → 600 | 400 → 1,200 | 2 → 6 |
| 브론즈1 | 100 → 500 | 200 → 1,000 | 2 → 4 |

### 5.2 Weekly benefit buff
- The tier buffs (전문가·장인·달인·명인·패왕 혜택) are **unchanged** by 9/22. [OFF NXKR_PN_0922]
- Global wiki names and values [COM WIKI_BOOSTERS]. Each lasts until the next weekly settlement.

| Buff | Meso drop | EXP |
|---|---|---|
| Arena Expert Benefit (전문가) | +8% | — |
| Arena Professional Benefit (장인) | +16% | — |
| Arena Ace Benefit (달인) | +19% | +5% |
| Arena Lord Benefit (명인) | +22% | +10% |
| Arena Overlord Benefit (패왕) | +25% | +15% |

- **Conflict.** The wiki's "Effect" column lists +50%, +100% and +150% EXP for Ace, Lord and Overlord.
- Which tier gives which buff: **NOT FOUND**.

### 5.3 Reward events (paid in coins and scrolls, not shop items)
| Event | Period | Effect | Source |
|---|---|---|---|
| 아레나 부스트 | 6/22 settlement to 7/5 settlement | Daily and weekly currency increased (multiplier not stated) | OFF NXKR_PN_0611 |
| 아레나 보상 부스트 | 8/31 settlement to 9/13 settlement | Daily and weekly ×2; the benefit buff is excluded | OFF IV161 (copy of the official event), NXKR_PN_0813 |
| 아레나 보상 3배 | 9/22 settlement to 10/5 settlement | Daily and weekly ×3; the benefit buff is excluded | OFF NXKR_PN_0922, IV610 |

### 5.4 Medals for arena wins (each gives Main Stat +30)
| Medal | Requirement | Source |
|---|---|---|
| Still Cute | 100 arena wins | COM WIKI_MEDALS |
| Powered Up | 500 arena wins | COM WIKI_MEDALS |
| Overwhelming Presence | 1,000 arena wins | COM WIKI_MEDALS |
| 무적의 나 (Invincible) | 2,000 cumulative attack wins | OFF NXKR_PN_0922 |
| 전설의 나 (Legendary) | 3,000 cumulative attack wins | OFF NXKR_PN_0922 |

### 5.5 Arena coin shop (summary; details in research-income §5.2)
| Item | Price (아레나 코인) | Limit | Source |
|---|---|---|---|
| 스타포스 강화 주문서 ×1 (weekly discount) | 150 | 25 a week (15 → 25 on 2025-11-27) | OFF NXKR_PN_1127; COM MSI_ARENA, DC35341 |
| 스타포스 강화 주문서 (regular, after the weekly 25) | "500?". Asked in a question post, unconfirmed | ? | COM DC373144 |
| 유물 상자 | 500 | 10 a week | COM MSI_ARENA, IV114, IV314 |
| 여정의 기운 | ? | 5 a week | OFF NXKR_PN_0903 |
| 유물 강화석, 주문의 흔적, 메소 | ? | ? | COM IV114, IV136, IV285 |
| 특별 의상 (Special Outfit (Arena), e.g. weapon costume "Longsword of Valor") | One outfit costs 100,000 (from a post title) | One-time | COM IV257, WIKI "Weapon (costume)" |

- Community "core weekly" spend: 8,750 coins (10 × 500 + 25 × 150). [COM MSI_ARENA]
- Typical weekly income: about 6,300-10,500 coins. [COM MSI_ARENA]
- Weekly limits reset Monday 00:00. [OFF NXGL_FAQ]

---

## 6. Arena timeline (KR, all official unless marked)
| Date | Change | Source |
|---|---|---|
| 2025-11-06 | Launch with Arena, daily and weekly settlement | NXKR_FAQ_RANK |
| 2025-11-12 | Fixes: "recommended opponent not found"; win/loss judgement | NXKR_NT_1112 |
| 2025-11-27 | Arena attack/defense preset numbers; friendly duel; SF scroll limit 15 → 25; 3 tickets as compensation | NXKR_PN_1127, NXKR_NT_1127B |
| 2025-12-18 | Dungeon presets replace the arena preset; friendly-duel records | NXKR_PN_1218 |
| 2026-01-29 | Colosseum launched (first formula change) | NXKR_PN_0129 |
| 2026-04-30 | Arena damage rebalanced (new formula with the HP bug); weekly point-reset bug fixed | NXKR_PN_0430 |
| 2026-05-21 | Matching uses an "appropriate value" even if you keep a low ranking CP on purpose | NXKR_PN_0521 |
| 2026-06-22/25 | HP bug admitted; formulas published; compensation | NXKR_NT_0622/0623/0625 |
| 2026-07-02 | New PvP formula; World Arena; fix for "win shown as loss" | NXKR_PN_0702, NXKR_NT_0702B |
| 2026-08-13 | Idle hunting keeps running during non-Arena PvP | NXKR_PN_0813 |
| 2026-09-03 | Battle speed ×2; quick battle at 5× CP; 여정의 기운 in the arena shop | NXKR_PN_0903 |
| 2026-09-22 | Reward tables raised; medals for 2,000 and 3,000 wins; 3× event; fixes for the extra-charge cap popup and quick-battle score refresh | NXKR_PN_0922 |
| 2026-10-15 | PvP CP formula (Arena, Colosseum, World Arena) | NXKR_PN_1015 |

---

## 7. World Arena (월드 아레나) [OFF NXKR_PN_0702 unless marked]

### 7.1 Basics
- **Unlock.** Clear the Chapter 16 boss. You can join a running round. No guild is needed.
- **Scope.** All servers of the same region.
- **Rounds** (5 days each):
  - R1: 2026-07-07 12:00 to 07-11 22:00
  - R2: 07-14 12:00 to 07-18 22:00
  - R3: 07-21 12:00 to 07-25 22:00
- **Later rounds:** none found up to 2026-11-24. A DC post on 11-22 asks when it returns.
- **Tickets**
  - 10 tickets at 00:00. The daily refill never goes above 10.
  - When you run out, buy **3 tickets** with 레드 다이아. The price rises with each purchase that day, from **100 to 500**, then stays at 500.
  - The exact steps are **NOT FOUND**.
  - Players report no daily purchase limit. [COM DC374766, DC375080]
- **Matching.** Opponents with a similar ranking score. The list can be refreshed (cost NOT FOUND). Pick 1 opponent.
- **Artifact block.** Before the fight, choose 1 of the defender's equipped artifacts. Its special effect is disabled.
- **Soul Pouch** works here.

### 7.2 Combat modifiers
- Same formula as Arena, with constant 5,764,800,000. That is **80%** of Arena damage, dealt and received.
- Healing and shields ×0.5.
- Damage immunity and basic-attack immunity last half as long.
- Potions, verbatim: "물약의 효과가 감소되어 적용됩니다. 회복 효과 감소의 결과로 아레나/콜로세움과 최종 회복량은 동일합니다."

### 7.3 Score
- Start at **1,000**.
- Gains and losses scale with the **defender's** World Arena preset CP at match time. A stronger defender means bigger swings, on attack and on defense.
- A loss that would take you to 1,000 or below costs a fixed **10** points.
- Max **5** defense-success scores from the same opponent per round.
- **Daily TOP5.** Each day the 5 highest-CP opponents you beat are recorded.
  - Beating one again at a higher CP updates the record.
  - The list is locked at 00:00.
  - Points from those wins are multiplied:

| Day | TOP1 | TOP2 | TOP3 | TOP4 | TOP5 |
|---|---|---|---|---|---|
| 1-2 | ×100 | ×80 | ×60 | ×50 | ×40 |
| 3 | ×150 | ×120 | ×100 | ×75 | ×50 |
| 4 | ×250 | ×200 | ×120 | ×100 | ×75 |
| 5 | ×600 | ×450 | ×300 | ×225 | ×150 |

- Base points per win: **NOT FOUND**.
- **Abuse rule.** Feeding TOP5 wins to guildmates (fighting with no attack skills or artifacts) led to bans. 24 accounts got a 3-day ban and their cubes were taken back. [OFF NXKR_NT_0804]

### 7.4 Rewards
- Paid only if you made at least 1 attack or defense.
- Guild score = the sum of members' scores.
  - Joining a guild mid-round: you play, but your score is not added and you get no guild reward.
  - Leaving mid-round removes you from the guild score and the guild reward.

| 티어 | Individual rank | 미라클 큐브 | Guild rank | 에디셔널 큐브 | Guild EXP booster (7 d) |
|---|---|---|---|---|---|
| 챔피언1 | 1 | 300 + Gold chair | 1 | 100 | +25% |
| 챔피언2 | 2 | 270 + Silver chair | 2 | 90 | +20% |
| 챔피언3 | 3 | 250 + Bronze chair | 3 | 80 | +15% |
| 그랜드마스터1 | 4-10 | 230 | 4-10 | 75 | +12% |
| 그랜드마스터2 | 11-30 | 215 | 11-30 | 70 | +10% |
| 그랜드마스터3 | 31-100 | 200 | 31-50 | 60 | +10% |
| 그랜드마스터4 | 101-500 | 180 | 51-100 | 50 | +10% |
| 그랜드마스터5 | 501-1,000 | 160 | 101-300 | 40 | +8% |
| 마스터1 | 1,001-2,000 | 140 | 301-500 | 35 | +8% |
| 마스터2 | 2,001-3,000 | 120 | 501-750 | 30 | +6% |
| 마스터3 | 3,001-4,000 | 110 | 751-1,000 | 27 | +6% |
| 마스터4 | 4,001-5,000 | 100 | 1,001-2,000 | 24 | +4% |
| 마스터5 | 5,001-10,000 | 80 | 2,001-3,000 | 21 | +4% |
| 다이아몬드1 | 10,001-30,000 | 65 | 3,001-4,000 | 18 | +4% |
| 플래티넘1 | 30,001-50,000 | 50 | 4,001-5,000 | 15 | +4% |
| 골드1 | 50,001-75,000 | 40 | 5,001-7,500 | 12 | +4% |
| 실버1 | 75,001-100,000 | 30 | 7,501-10,000 | 10 | +4% |
| 브론즈1 | 100,001+ | 10 | 10,001+ | 5 | — |

- Note: World Arena has no Challenger tier.
- **Chairs** (ranks 1-3)
  - 7-day item. Owning one gives EXP +10%.
  - Giving fame to a seated player gives the giver EXP +10% for 30 minutes, once a day.

---

## 8. Colosseum (콜로세움)
- **Format** [OFF NXKR_PN_0129, NXKR_PV_0120, NXGL_PN_0129]
  - An event in batches of 3 rounds.
  - **25 players** of similar strength are drawn from all servers of the region. Everyone fights the others 1v1.
  - Arena must be unlocked when matching runs. If Arena unlocks mid-round, you join from the next round.
  - Rewards need a participation record.
- **Matching** is by personal **highest CP across presets**. The devs said they have no plan to change it. [COM IV644, NXKR_FREE_0806, NXKR_FREE_0803]
- **Skill ban.** Before attacking, ban 1 skill from a fixed list of the opponent's skills. The list can include passives. [OFF NXKR_PN_0129; COM IV655]
- **Bingo** [OFF NXKR_PN_0129]
  - A win activates the opponent's cell.
  - A lost defense deactivates it. The first lost defense on a neutral cell costs no points.
  - Line rewards are paid at once, only once per line, and you keep them even if cells are lost later.
- **Score**, community breakdown from October 2026 [COM DC425800, DC200278]:
  - Start at 1,000.
  - **+100** for each currently active cell. A full board is 1,000 + 24 × 100 = 3,400.
  - Daily 00:00 bonus for each active cell:
    - +3 from the 3/24 round [OFF NXKR_PN_0319]
    - **+10** from the 5/26 round [OFF NXKR_PN_0521]
    - No bonus on the last day [OFF NXKR_PN_0723 / 0922]
  - Attack loss **−1**, defense win **+1**.
- **Damage.** Constant 4,323,600,000 (0.6 × Arena). Stronger per-level penalty above level 70 (§2.2). On 4/30 damage at high CP went up. [OFF]
- **Rounds** (Tue 12:00 to Sat 21:59) [OFF]:
  - 1/30-2/7 (the first round ran to Sat 2/7), 2/10-2/14, 2/17-2/21
  - 3/24-3/28, 3/31-4/4, 4/7-4/11
  - 5/26-5/30, 6/2-6/6, 6/9-6/13
  - 7/28-8/1, 8/4-8/8, 8/11-8/15
  - 9/29-10/3, 10/6-10/10, 10/13-10/17
- **Rank rewards** in 스타포스 강화 주문서 [COM WIKI_COLO (global)]:

| Rank | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 | 10 | 11 | 12 | 13 | "15" | "17" | "19" | "21" | "23" | Participation |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| SF | 80 | 70 | 60 | 56 | 52 | 48 | 44 | 40 | 38 | 36 | 34 | 32 | 30 | 27 | 24 | 21 | 18 | 15 | 12 |

  - The wiki lists "Top 15/17/…", which I read as ranks 14-15, 16-17 and so on.
  - KR check: a player got 80 for a round. [COM DC230233]
  - One DC post guesses rewards differ by league. [COM DC199808, unverified]
- **Bingo line rewards** [COM WIKI_COLO]
  - Lines 1-4: +5 SF each.
  - Lines 5-8: 350,000 / 400,000 / 450,000 / 500,000 메소.
  - Community says line rewards were cut on the 3/24 round ("7개 아니었나"). "All bingo = 20 SF" in September 2026. [COM DC276285, DC419871]
- **Medals**: "Let's Go Bingo" for 8 lines; "Conqueror" for a full board. [COM WIKI_MEDALS]
- **Board shape and attack limits: NOT FOUND.** There are 25 players and 8 rewarded lines.

## 9. Guild contests (not PvP)
- **길드 대항전 / Guild War** [OFF NXKR_PN_1127; COM WIKI_GUILDWAR]
  - 5 guilds per group. Members score against a **boss**.
  - Runs Thu 12:00 to the next Mon 22:00.
  - Rewards (KR 11/27):

| Rank | Guild buff | 미라클 큐브 |
|---|---|---|
| 1 | EXP +16%, 메소 +13% | 15 |
| 2 | EXP +13%, 메소 +13% | 10 |
| 3 | EXP +10%, 메소 +10% | 7 |
| 4 | EXP +7% | 5 |
| 5 | EXP +5% | 3 |

  - The buff lasts until the next Monday 21:59.
  - Conflict: the global wiki says rank 1 gets +16% EXP **and +16% meso**, for 7 days.
  - 9/3: point values for ranks 1-29 in the group were raised (e.g. 1st: 1,000,000 → 1,500,000). [OFF NXKR_PN_0903]
- **길드 보스 대전** [OFF NXKR_PN_0521, NXKR_PN_0813]
  - Guild vs guild, matched 1:1. From 5/21 the guild with the higher total boss score wins.
  - Rounds run Fri 12:00 to Wed 21:59.
- The client also has a "길드 대항전 (대전)" preset type (GuildLeagueVersus). Its rules were not found. [COM IDX_DATA]

---

## 10. Sources
All forum links use the official JSON API `https://forum.nexon.com/api/v1/thread/<id>?alias=maplestoryidle-kr` (KR) or `alias=maplestoryidle` (global). Raw files are under `../web/research/arena/`.

| Key | Region | Date | Title | URL | Raw |
|---|---|---|---|---|---|
| NXKR_PN_1114 | KR | 2025-11-14 | 11/14 패치노트 | https://forum.nexon.com/maplestoryidle-kr/board_view?board=6698&thread=3224718 | nexon-kr/t3224718.* |
| NXKR_PN_1127 | KR | 2025-11-27 | 11/27 패치노트 | …board=6698&thread=3274197 | nexon-kr/t3274197.* |
| NXKR_PN_1218 | KR | 2025-12-18 | 12/18 패치노트 | …board=6698&thread=3309519 | nexon-kr/t3309519.* |
| NXKR_PN_0129 | KR | 2026-01-29 | 1/29 패치노트 | …board=6698&thread=3360461 | nexon-kr/t3360461.* |
| NXKR_PN_0319 | KR | 2026-03-19 | 3/19 패치노트 | …board=6698&thread=3403618 | nexon-kr/t3403618.* |
| NXKR_PN_0409 | KR | 2026-04-09 | 4/9 패치노트 | …board=6698&thread=3419376 | nexon-kr/t3419376.* |
| NXKR_PN_0430 | KR | 2026-04-30 | 4/30 패치노트 | …board=6698&thread=3435722 | nexon-kr/t3435722.* |
| NXKR_PN_0521 | KR | 2026-05-21 | 5/21 패치노트 | …board=6698&thread=3448688 | nexon-kr/t3448688.* |
| NXKR_PN_0611 | KR | 2026-06-11 | 6/11 패치노트 | …board=6698&thread=3473998 | nexon-kr/t3473998.* |
| NXKR_PN_0702 | KR | 2026-07-02 | 7/2 패치노트 (World Arena, formula) | …board=6698&thread=3490212 | nexon-kr/t3490212.* |
| NXKR_PN_0723 | KR | 2026-07-23 | 7/23 패치노트 | …board=6698&thread=3506485 | nexon-kr/t3506485.* |
| NXKR_PN_0813 | KR | 2026-08-13 | 8/13 패치노트 | …board=6698&thread=3521991 | nexon-kr/t3521991.* |
| NXKR_PN_0903 | KR | 2026-09-03 | 9/3 패치노트 | …board=6698&thread=3535860 | nexon-kr/t3535860.* |
| NXKR_PN_0922 | KR | 2026-09-22 | 9/22 패치노트 (reward increase) | https://forum.nexon.com/maplestoryidle-kr/board_view?board=6698&thread=3550026 | nexon-kr/t3550026.*, nexon-api-3550026.json, nexon-3550026.txt |
| NXKR_PN_1015 | KR | 2026-10-15 | 10/15 패치노트 (PvP CP) | …board=6698&thread=3563013 | nexon-kr/t3563013.* |
| NXKR_PV_0120 | KR | 2026-01-20 | 1/29 업데이트 미리보기 | …board=6633&thread=3352910 | nexon-kr/t3352910.* |
| NXKR_PV_0625 | KR | 2026-06-25 | 7/2 업데이트 미리보기 | …board=6633&thread=3484302 | nexon-kr/t3484302.* |
| NXKR_PV_0827 | KR | 2026-08-27 | 9/3 업데이트 미리보기 | …board=6633&thread=3533653 | nexon-kr/t3533653.* |
| NXKR_NT_1112 | KR | 2025-11-12 | 11/12 무중단 패치 | …board=6633&thread=3221083 | nexon-kr/t3221083.* |
| NXKR_NT_1127B | KR | 2025-11-27 | 11/27 무중단 패치 (ticket compensation) | …board=6633&thread=3275274 | nexon-kr/t3275274.* |
| NXKR_NT_0430 | KR | 2026-04-30 | 아레나 기록 초기화 오류 | …board=6633&thread=3436063 | nexon-kr/t3436063.* |
| NXKR_NT_0622 | KR | 2026-06-22 | 아레나/콜로세움 수치 적용 오류 및 사과 보상 | …board=6633&thread=3480968 | nexon-kr/t3480968.* |
| NXKR_NT_0623 | KR | 2026-06-23 | 개별 보상 지급 안내 | …board=6633&thread=3481663 | nexon-kr/t3481663.* |
| NXKR_NT_0625 | KR | 2026-06-25 | 수치 적용 오류 수정 및 계산식 변경 안내 (formulas) | …board=6633&thread=3483504 | nexon-kr/t3483504.* |
| NXKR_NT_0702B | KR | 2026-07-02 | 7/2 무중단 패치 (win→loss bug) | …board=6633&thread=3490934 | nexon-kr/t3490934.* |
| NXKR_NT_0804 | KR | 2026-08-04 | 월드 아레나 비정상 플레이 조치 | …board=6633&thread=3516303 | nexon-kr/t3516303.* |
| NXKR_NT_0916 | KR | 2026-09-16 | 서버 통합 규모 조정 및 보상 개선 | …board=6633&thread=3546003 | nexon-kr/t3546003.* |
| NXKR_FAQ_RANK | KR | 2025-11-06 | 랭킹 정산 보상 FAQ | …board=6730&thread=3210575 | nexon-kr/t3210575.* |
| NXKR_FAQ_SPEED | KR | 2026-11-03 | 전투 배속 FAQ | …board=6730&thread=3574941 | nexon-kr/t3574941.* |
| NXKR_FREE_1113 | KR (player) | 2026-11-13 | 아레나 점수는 언제 개편할까 (+5 / −9) | …board=7612&thread=3581109 | nexon-kr-free/t3581109.* |
| NXKR_FREE_0806 / _0803 | KR (player) | 2026-08-06 / 08-03 | Colosseum matching complaints | …thread=3518120 / 3515753 | nexon-kr-free/ |
| NXGL_PN_0922 | global | 2026-09-22 | September 22 Patch Notes | https://forum.nexon.com/maplestoryidle/board_view?board=6675&thread=3550175 | nexon-global/t3550175.* |
| NXGL_PN_0430 | global | 2026-04-30 | 4/30 Patch Note | …board=6675&thread=3435578 | nexon-global/t3435578.* |
| NXGL_PN_0129 | global | 2026-01-29 | January 29 Patch Notes | …board=6675&thread=3360937 | nexon-global/t3360937.* |
| NXGL_NT_0430 | global | 2026-04-30 | Arena Record Reset Error | …board=6653&thread=3435648 | nexon-global/t3435648.* |
| NXGL_NT_1110 | global | 2025-11-10 | Bera & Luna WB/Arena settlement error (comp: Arena Coin ×2,000, SF ×6) | …board=6653&thread=3218711 | nexon-global/t3218711.* |
| NXGL_FAQ | global | FAQ ver. 2026-07-23 | FAQ (reset times, server time zones) | …board=6679&thread=3209008 | nexon-global/t3209008.* |
| WIKI_ARENA | global | rev 2026-07-02 | Arena | https://idle.maplestorywiki.net/w/Arena | ../idlewiki/wikitext.json; wiki-arena-colosseum-live.json |
| WIKI_COLO | global | rev 2026-08-11 | Colosseum | https://idle.maplestorywiki.net/w/Colosseum | same |
| WIKI_GUILDWAR, WIKI_BOOSTERS, WIKI_ARTIFACTS, WIKI_MEDALS, WIKI_UNLOCKS, WIKI_CHARSTATS | global | dump 2026-11-24 | Guild War, Boosters, Artifacts, Medals, Guide Quest/Chapter Unlocks/Systems, Character Stats | https://idle.maplestorywiki.net/w/<page> | ../idlewiki/wikitext.json |
| MSI_ARENA | global | checked 2026-07-02 | Arena and Colosseum Guide | https://maplestoryidle.info/guides/arena-colosseum/ | info-arena-colosseum.html |
| MSI_WA | global | 2026-07-02 | World Arena Info | https://maplestoryidle.info/guides/world-arena-info/ | info-world-arena-info.html |
| MSI_COMP | global | n/a | Companion Setup and Priority | https://maplestoryidle.info/guides/companion-setup-priority/ | info-companion-setup-priority.html |
| IDX_DATA | KR client 1.18.0 extract | n/a | mapleidleindex calculator data | https://mapleidleindex.com/calculator/data/loadout-peak-data.js, /calcv4/artifact-preset-data.js | ../web/js/calculator/data/, ../web/js/calcv4/ |
| IV114, IV136, IV161, IV257, IV263, IV285, IV314, IV398, IV586, IV610, IV644, IV647, IV655, IV723, IV809 | KR | 2026-09-02 … 11-20 | Inven guides and posts (titles in JSON) | https://www.inven.co.kr/board/mapleidle/6554/<n> | inven/inven-<n>.html |
| DC35341 … DC425800 (≈30 posts) | KR | 2025-11-17 … 2026-10-13 | DC Inside 메이플 키우기 gallery (titles in JSON) | https://gall.dcinside.com/mgallery/board/view/?id=maplerpg&no=<n> | dc/dc-<n>.html |

---

## 11. Not found / still missing
1. Arena **time limit** and arena map size. Only "about 15 s typical" exists, from a community model.
2. Arena **start score**, **attack-loss** points and the exact CP-scaling formula for points. Known so far: about +20 per win, +5 defense win, −9 defense loss, all community.
3. Arena **tier rank ranges**. The World Arena ranges are known; Arena's may be the same, but that is unconfirmed. Whether Diamond and lower tiers have divisions 2-5.
4. Which tier gets which weekly benefit buff (전문가…패왕), and the EXP conflict on the wiki.
5. **Promotion (승급) reward** amounts.
6. Arena **ticket refill price ladder**. Known so far: 15 tickets for 1,000 RD a day, community.
7. Arena shop **prices** for 여정의 기운, 유물 강화석, 주문의 흔적, 메소, regular SF scrolls and outfits (only the 100k outfit is known).
8. World Arena base points per win and refresh cost.
9. Colosseum board layout, attack limits, list-refresh rules, and whether rank rewards differ by group strength.
10. The official in-game guide page (`maplestoryidle.nexon.com/ko/guide`) was not fetched; it blocks automated access. It likely holds the formulas already captured from the notices, and possibly the missing time limit.
11. Image-only data: the arena shop and score screenshots on Inven and DC are on hosts that cannot be reached.
