# 메이플 키우기 (MapleStory: Idle RPG): data research report

Retrieved on 2026-11-24. The live KR client is 1.18.0, and the KR 11/26 update has been previewed but is not yet live.

This report builds on `research/spec/*.md` (combat-stages, content, items-gacha, research-progression) and on the scratchpad `research-income.md`. Its gaps are listed in `missing_data.md`.

## 1. Coverage summary

| Section | Item | Obtained / expected | % |
|---|---|---|---|
| 3.1 | EXP required per level, Lv1-140 | 140 / 140 | 100 |
| 3.1 | Pure base stats per level (HP, MP, ATK, DEF, main, sub) | 0 / 840 | 0 |
| 3.1 | Job main/sub stat and stat→ATK conversion | 14 / 14 jobs | 100 |
| 3.2 | Meso-based 능력치 강화 (levels, cost, cap) | 0. System not found | – |
| 3.2 | 메이플 랭크 | 0. System not found | – |
| 3.2 | Substitute: 용사의 힘 slot-levels (gain and token cost) | 2 475 / 2 475 | 100 |
| 3.2 | Substitute: 용사의 힘 stages (cap, slots, timer, bonus) | 9 / 9 | 100 |
| 3.3 | Incoming-damage terms and rules (48 enumerated items) | 42 sourced, 6 unknown | 87.5 |
| 3.3 | 5000/(DEF+6000) for monster→player hits | Partially verified (see §4) | – |
| 3.4 | Stages with the main reward fully known (5 dungeons × 150 live) | 290 / 750 (EXP 150, Hero Training 140) | 38.7 |
| 3.4 | Stages with at least partial reward data (plus enhancement scroll odds) | 440 / 750 | 58.7 |
| 3.4 | Monster HP, ATK, DEF and evasion per stage (KR 1.18.0) | 750 / 750 | 100 |
| 3.4 | Announced stages 151-160 (11/26) | 0 / 50 | not live |
| Added | Free companion-ticket sources | 56 sources (53 with amounts) | – |
| Added | Missions, attendance and battle pass rows | 315 | – |
| Added | Permanent daily missions (individual) and weekly stages | 0 known | – |
| Added | Achievements: event [업적] / permanent | 62 / 0 | – |
| Added | Guide quests: unlock numbers / rewards | 24 / 0 | – |
| Added | Summon levels: requirements / free level rewards | 49 / 0 of 49 | – |

Datasets: 22 JSON files, with matching CSVs and SQLite tables. That is 5 127 records in total, and 101 registered sources.

## 2. Source hierarchy and versions

1. **Official Nexon KR forum** (forum.nexon.com JSON API): patch notes, notices and events. This is the only official source reached. The official battle guide at maplestoryidle.nexon.com returned 403.
2. **Decoded client tables** published by third parties:
   - **mapleidleindex.com** (KR PC 1.18.0, verified 2026-11-05): EXP curve, EXP dungeon, growth-dungeon monsters, enhancement scroll odds, 용사의 힘, summon levels, hotdeals and the boss page.
   - **maplestoryidle.info** (global client 1.14.0, snapshot 2026-08-13): Hero Token / Hero Training rewards, the game-data library, game-stat-rules (StatTypeTable, StatGapValueTable, IL2CPP calculators) and the target model.
3. **Community wiki** (idle.maplestorywiki.net, global): rules, special requests and guide-quest unlocks. Several of its pages are outdated (dungeon caps 70/90).
4. **Community posts** (Inven, dcinside, mekifun): totals and the 14-day mission list.
5. **Not usable:**
   - slippa.dev: its model is private.
   - GitHub MapleStoryIdleOptimizer: outgoing DPS only.
   - namu.wiki, mapleidle.gg and bluestacks: blocked or not on the allowlist.

Every record carries `source_id`, `source_url`, `game_version`, `region`, `retrieved_at`, `verification_status` and `notes`.

**Calculator execution:** Playwright ran `mapleidleindex.com/growth/#exp` (stages 1, 50, 100, 140 and 150) and `maplestoryidle.info/hero-token-calculator.html` (stages 1, 10, 100 and 140). Their outputs equal the JSON tables (`mdb/raw/playwright_calculator_outputs.json`). Both calculators are thin views over those JSON files, so no hidden data exists behind them.

## 3. Findings

### 3.1 Character base stats and EXP
- **EXP to the next level:**
  - Lv1 25, Lv60 54 362 868 145, Lv100 915 907 513 551 302, Lv139 9 525 458 015 843 620 000.
  - Cumulative EXP to reach Lv140 (the cap) is 46 690 483 507 302 947 000.
  - The KR 1.18 table equals the global wiki `Module:Experience/data.json` for all 139 shared levels.
- **Stat conversion** (client HeroTable, per mille):
  - Main stat 1000 (1 main = 1 ATK); sub stat 250 (4 sub = 1 ATK).
  - Main/sub pairs: Warrior STR/DEX, Bowman DEX/STR, Magician INT/LUK, Thief LUK/DEX.
  - Stat Prop. Damage = main × 1% + sub × 0.25%, rounded down to 0.1%.
- **Job advancement levels:** 1st Lv5 (Guide Quest 7), 2nd Lv30, 3rd Lv60, 4th Lv100.
- **Pure base HP, MP, ATK, DEF and main/sub stat per level: not published anywhere reachable.** All 140 level rows are `null`.
  - Level-scaled effects that are not base stats, and so are excluded: item options "1/4/5/10레벨당 주 스탯(%)", medals (+30 main stat each), costume collection, and the PvP level adjustment.

### 3.2 Stat upgrades and rank
- **Not found:** no meso-based "능력치 강화" or "메이플 랭크" appears in any KR notice, patch note, client-table export or the global wiki. Leads and paths tried are in `missing_data.md`.
- **The verified system is 용사의 힘 (Hero Power).** It is paid in 용사의 증표 and unlocks at Guide Quest 79.

| Stage | Slots (max level) | Stage cost (tokens) | Cumulative (tokens) | Wait to reach (s) | Stage bonus |
|---|---|---|---|---|---|
| 1 | ATK / HP / DEF (10) | 1 698 | 1 698 | 0 | – |
| 2 | +주스탯 (15) | 10 212 | 11 910 | 300 | 주스탯 +100, HP +10% |
| 3 | +데미지% (20) | 27 310 | 39 220 | 7 200 | +200, +20% |
| 4 | +명중 (30; 명중 10) | 68 825 | 108 045 | 43 200 | +300, +30% |
| 5 | 6 slots (40; 명중 15) | 130 232 | 238 277 | 86 400 | +500, +40% |
| 6 | (60; 명중 20) | 285 705 | 523 982 | 259 200 | +700, +50% |
| 7 | (80; 명중 25) | 538 216 | 1 062 198 | 388 800 | +1 000, +60% |
| 8 | (100; 명중 30) | 924 404 | 1 986 602 | 583 200 | +1 500, +70% |
| 9 | (120; 명중 35) | 1 490 806 | 3 477 408 | 641 520 | +2 000, +80% |

- **Cost rule:** level cost = floor(base cost × level factor ÷ 1000). For example, stage 1 ATK costs 50, 51, 53 … (566 tokens for 10 levels). Stage 8 runs 560 → 3 376 per level.
- **Stat rule:** stat = slot start value + per-level gain × level.
- **Per-level gains:**
  - ATK and DEF: +10 at stage 1, +70 at stage 8.
  - HP: +200 at stage 1, +1 400 at stage 8.
  - Main stat: +10.
- **Cross-check:** global 1.14 (8 stages) has identical costs for all 1 840 shared slot-levels. KR 1.18 adds stage 9.

### 3.3 Incoming damage (official KR formula plus client rules)

The official notices are 2026-06-25 and the 7/2 patch note. Both state: "기본 피해량 산정 시 공격적인 능력치는 공격자, 방어적인 능력치는 피격자 기준".

```
damage = ATK[attacker] × 5000 ÷ (6000 + DEF[target] × (1 − Pierce[attacker]))
       × DamageTakenIncrease[target] × (1 − Toughness[target]) × (1 − DungeonToughness[target])
       × Damage% × DamageAmp% × (BasicAttack% | Skill%) × StatProp% × Mastery% × DungeonDamage%
       × (on crit) CritDamage% × [Min%..Max%] × (vs CC'd) StatusDamage% × FinalDamage%
       × SkillCoefficient
       × content adjustment (PvP: √ of the whole bracket, level adjustment ×2, PvP defence term)
internal units: % stored ×10; multiplier = (1000 + value) / 1000
```

- **Toughness (받는 피해 감소):**
  - Applied after DEF.
  - Chained stacking: gain = (100% − current) × added. Cap 95%.
- **Defense penetration:** chained stacking, capped at 100% (displayed up to 99.9%).
- **Evasion:**
  - gap = target evasion − attacker accuracy, which feeds `stat_gap_table.json`.
  - 1→1%, 10→10%, 25→27.5%, 50→47.9%, 75→62%, ≥100→70% cap.
  - Monster HitChance per growth-dungeon stage is in `growth_dungeon_monsters.json` (1.14 values).
- **Critical resistance** subtracts from the attacker's crit rate (clamped 0-100%).
- **PvP (from 7/2):**
  - Formula: × C ÷ ((offense+1e9)^0.23 × (MaxHP×1e8)^0.12 × ((DEF+6000)×1e12)^0.14 × ((1000+Toughness)×1e6)^0.5 ÷ 1e7) ÷ 1e6.
  - C: Arena 7 206 000 000; Colosseum 4 323 600 000; World Arena 5 764 800 000.
  - All inputs of this term are the target's pre-battle stats.
  - Before 7/2: × 10 000 (Arena) or 6 000 (Colosseum) × MaxHP ÷ √(offense) ÷ 1e6. That version was a bug where more HP meant more damage taken.
- **PvP level adjustment** (damage taken per defender level):

  | Mode | Lv31-60 | Lv61-70 | Lv71-100 | Lv101+ |
  |---|---|---|---|---|
  | Arena / World Arena | −0.5% | −1.3% | −1.3% | −1.5% |
  | Colosseum | −0.5% | −1.3% | −1.5% | −2.5% |

- **Square-root adjustment:**
  - Also used in 보스 레이드, 파티 퀘스트 and 길드 수련장 (6/22 notice).
  - Conflict: MSI's reading of the official Guide (8/6) gives 길드 수련장 a cube-root adjustment.
  - The direction of these PvE adjustments (whose damage they apply to) is not stated.
- **Max-HP exceptions:**
  - In 길드 토벌전, 길드 보스 대전, 길드 대항전, 보스 레이드, 길드 레이드 and 파티 퀘스트, monster hits = ATK part + target-Max-HP part. They then go through the normal chain; this is not fixed damage (official 6/25).
  - Pink Bean statues (client 1.18; A = 45 000 000):
    - Ariel: 40% A + 35% H.
    - Solomon and Rex: 12% A + 12% H, and 25% A + 18% H.
    - Hugin and Munin: 35% A + 20% H, and 15% A + 8% H (16 patterns).
  - 마왕 발록 (challenge boss, 11/5): fixed damage proportional to max HP. The percentages are not published.
- **Verdict on 5000/(DEF+6000) for monster→player hits:**
  - Officially confirmed when the defender is a player in PvP.
  - In PvE it is consistent with the official attacker/target rule. MSI's reading of the official guide gives the same chain.
  - No PvE measurement or official PvE example exists. The record is therefore marked `partially_verified`.
- **Unknown:** minimum damage, rounding, monster skill coefficients for chapter and dungeon monsters, monster crit, and any PvE level modifier.

### 3.4 Growth dungeons
- **Stage-cap history (official KR):**
  - 70 at launch (11/6), 90 (11/14), 100 (12/5), 110 (1/8), 120 (4/9), 130 (6/11), 140 (7/2), 150 (9/3).
  - **160 is announced for 11/26** (`growth_dungeon_stage_caps.json`). There are still 5 dungeon types.
  - The global wiki still shows 70/90/100.
- **Rules:**
  - 3 free keys per day per dungeon. Hero Training: daily +3, max carry 10.
  - Sweep (일괄 소탕) unlocks after clearing stage 50 of all growth dungeons. It uses the same keys and gives the same rewards (official 8/13).
  - Every 10th stage is a hard stage (IsHard).
  - Key refund (global wiki): weapon, EXP and equipment return the key on a successful clear; enhancement returns it on failure.
  - Medals (main stat +30): clear all growth dungeons to stage 50, 70 or 100 (wiki), or 125 or 150 (KR 9/22).
- **경험치 던전** (KR 1.18, fixed per stage, EXP% bonuses do not apply):
  - Stage 1: 50 000. Stage 50: 49 605 049 765. Stage 100: 82 875 345 318 979. Stage 150: 21 690 469 919 004 900.
  - The stage-to-stage ratio falls from ×1.7 (early) to ×1.1 (late).
  - Sweep reward = clear reward. A separate first-clear reward is unknown.
- **용사의 수련장** (global 1.14 table):
  - Repeat and sweep: 240 + 10 × stage (250 … 1 640).
  - First clear: only on stages divisible by 10, 1 200 + 50 × stage (1 700 … 8 200). Other first-clear rows hold 0 tokens.
  - KR stages 141-150 are `null`. Their extrapolation exists only in `estimates.json`.
- **강화 던전 scroll odds** (per clear, KR 1.18). Together the six random scrolls total 10% at every stage.

| Stages | 노말 40% | 레어 40% | 레어 25% | 에픽 70% / 30% / 15% (each) |
|---|---|---|---|---|
| 1-29 | 10% | – | – | – |
| 30-39 | 9% | 0.5% | 0.5% | – |
| 60-69 | 6% | 1.75% | 1.75% | 0.1667% |
| 110-119 | 1% | 3% | 3% | 1% |
| 150 | 1% | 2.5% | 2.5% | 1.3333% |

  - Spell-trace amounts are not published.
- **무기 던전 and 장비 던전 rewards: not published** (0/150 each). Monster stats are complete.
- **Monster stats:**
  - Stages 1-150 come from KR 1.18.0.
  - On the 700 shared rows, KR 1.18 equals global 1.14 for ATK in every row. HP differs only by float serialisation in the 1.14 JSON.
  - Range examples:
    - Weapon: Mushmom HP 2 000 → 3.08e21, ATK 320 → 6.16e9, DEF 50 → 7 500.
    - Enhancement: Balrog HP 1.8e6 → 5.27e22.
  - Official monster-ATK cuts: 4/9 (stage 91+ growth), 6/11 (stage 101+), 8/13 (all growth dungeons) and 9/3 (chapter 24+, up to about −54%). The 1.18 values already include them.

### Added scope
- **Free companion-ticket sources** (`companion_ticket_sources.json`, 56 rows):
  - Permanent:
    - Monthly attendance 40/60/80/120 (300 a month).
    - Red-diamond shop: 30 for 750 red, once a week.
    - Ad: 10 free summons a day.
    - Special request (Ming Ming): 30.
    - Guide quests and summon-level rewards: amounts unknown.
  - Events:
    - New-character growth: Lv38 100 / Lv58 200 / Lv76 300.
    - Challenge boss: 100-200 per stage.
    - Daily-mission boosts: 100 at 10 missions.
    - Anniversary point choice: 120/300/400/600.
    - Coupons: 200-500 each.
    - 한가위 day 2: 1 000.
  - No free source exists for 3차/4차 전직 동료 소환권 (the anniversary legendary ticket is an event exchange).
- **Missions** (`missions.json`, 315 rows):
  - Daily-mission header (8 missions): 무기 소환권 100 + 레드 다이아 5 000.
  - Monthly attendance: 28 days.
  - Daily battle pass: 1 500 red a day.
  - 14-day newcomer mission: 84 missions.
  - Event daily, weekly and achievement tables: anniversary, ring workshop, relic dig, festivals and challenge.
  - The individual permanent daily missions and the weekly stage list are missing.
- **Achievements:** 62 event [업적] rows. **Guide quests:** 24 unlock numbers. **Special requests:** 25 (global wiki). **Summon levels:** weapon 1→19, companion 1→13 and ability 1→20 requirements, plus the paid level hotdeals (flagged `is_paid`).

## 4. Conflicts and version notes
- **Hero Training:** the 1.14 global table has 140 stages; KR has 150 (soon 160). The KR rewards for 141-150 are unpublished.
- **Hero Power:** global 1.14 has 8 stages; KR 1.18 has 9. Costs for the shared slot-levels are identical.
- **Guild Training Ground:** square root (KR notice 6/22) versus cube root (official Guide per MSI, 8/6). The later statement is recorded as current.
- **Growth dungeon caps:** the wiki shows 70/90/100; the KR notices show 150.
- **Currency naming:** MSI labels `FreeDia` as "Blue Diamond", but it is 레드 다이아 (earlier repo research).
