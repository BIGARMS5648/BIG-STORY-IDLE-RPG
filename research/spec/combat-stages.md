# 메이플 키우기 — combat, stats, leveling & stage data (spec)

Data source: mirror of https://mapleidleindex.com (client tables 1.18.0; some rule code cites 1.15.0).
Machine-readable output: `combat-stages.json` (same folder). Scripts (in `scripts/`, helper `combat_lib_jsdata.py`):
`combat_01_extract_inline_scripts.py <web> <work/inline>` → `combat_02_build_combat_stages.py <scratchpad>` →
`combat_03_verify_and_summarize.py <scratchpad>` (run each with `python3 -I`).
Numbers are copied as-is. Big integers (HP, EXP) stay as strings in the JSON. Anything marked *derived* uses the
site's own formula. Paths below are relative to `scratchpad/web/`.

## 1. Stat system (JSON: `statSystem`)

**Units.** The client stores percent stats as raw integers: displayed % = raw / 10 (AttackSpeed raw 1500 = 150 %).
Skill ratios use "M" units, where 1000 = 100 %. Sources: `js/calculator/battle-stat-math.js`, `js/calculator/data/skill-data.js` (`scale`).

**How sources of the same stat combine** (`battle-stat-math.js` STAT_RULES):

| Rule | Formula | Stats |
|---|---|---|
| additive | total = Σ sources | everything not listed below |
| chained (ratio R) | new = cur + (R − cur) × add / R | AttackSpeed(11) R=150 · PiercePower(42) R=100 · Toughness(16) R=100 · CoolTimeReduceRatio(103) R=100 |
| multiplicative | new = (100+cur)(100+add)/100 − 100 | FinalDamage(80) and hidden lanes FinalDamage2-5 (105-108); each lane is kept separate |

Removing a chained source: cur' = R − (R − cur)/(1 + removed/R). Starting from B and adding n identical sources p:
R − (R − B)(1 − p/R)^n. Sources: `speedpierce.html` inline script, `js/assets/pierce-baseline.mjs`.

**Caps and limits** (DISPLAY_LIMITS):
- attackSpeed ≤ 150
- damageReduction ≤ 95
- defPen 0-99.9
- cooldownPct ≤ 99.9
- Most other displayed stats have a floor of 0.
- finalDamage2-5 are also floored at 0 at runtime.

**Rounding.** All sources are composed first. The result is then truncated in the raw unit: percent stats to 0.1,
integer stats to 1, cooldownSec to 0.001 s. The clamp is applied last.

**Primary stats** (calcv4 inline module `calcv4.html` → `work/inline/calcv4_19.js`; `js/calcv4/captured-observations.js`):
- Attack gained from stats = trunc(main) + trunc(sub / 4).
- MainDamagePower(68) "스탯 비례 데미지" % = (trunc(main/10) + trunc(sub/40)) / 10. It is applied as a ×(1 + %/100) factor.
- For MaxHp(5), MaxMp(6), Attack(7) and Defence(8): Final = trunc(plus × (1000 + multRaw) / 1000). The "+" value includes Base for these four.
- Main stat = trunc((hiddenBase + mainFlat) × (1 + mainPct/100)). *hiddenBase is not in the data.*
- MainStatPerLevel1/5/10 add delta × L, delta × trunc(L/5) and delta × trunc(L/10) to the base.
- MainStatRPerLevelN adds % × trunc(L/N), for N = 1, 2, 3, 4, 5, 10.
- Main/sub stat per job (JOB_STAT_TYPES):

| Main / sub | Jobs |
|---|---|
| STR/DEX | 히어로, 팔라딘, 다크나이트, 바이퍼, 소울마스터 |
| INT/LUK | 아크메이지(썬·콜), 아크메이지(불·독), 비숍, 플레임위자드 |
| DEX/STR | 보우마스터, 신궁, 윈드브레이커, 캡틴 |
| LUK/DEX | 나이트로드, 섀도어, 나이트워커 |

The JSON also contains:
- the StatType id list (`statTypeIds`, 52 ids found)
- the display type of 88 stats (`statDisplayTypes`, from `js/data/enhancement-client-raw.json`)
- the client StatType → stat-key map
- the Korean label and description of 65 stats (calcv4 `META`)
- for every stat, whether it affects the one-hit formula and/or the simulated DPS (`EFFICIENCY_COVERAGE`)

## 2. Damage formula (JSON: `damageFormula`)

Client order: **공격·방어 → 치명타 → 최소·최대 배율 → 상태이상 → 최종 데미지**. Source: `text/calcv4.txt`.
Code: calcv4 `commonDamage` / `fixedBaseDamage` / `scenarioDamage` / `skillLineDamage`.

```
pf(v) = max(0, 1 + v/100)
common   = max(0, displayAttack) · pf(damage) · pf(amp) · pf(statScaling) · critAvg
           · pf(finalDamage) · pf(FD2) · pf(FD3) · pf(FD4) · pf(FD5)
base     = common · rangeAvg · defMult
hit      = base · pf(target==boss ? bossDamage : normalDamage)
                · pf(attack==basic ? basicDamage : skillDamage) · pf(enemyWeakness)
skillHit = Σ_lines hit(profile with targetDmg += line.localBonus) · line.totalPercent / 100

critAvg  = 1 + clamp((critRate − targetCritResist)/100, 0, 1) · max(0, critDamage/100)
rangeAvg : minRaw = trunc(minDamage·10), maxRaw = trunc(maxDamage·10); if minRaw>maxRaw: minRaw=maxRaw
           rangeAvg = (minRaw + maxRaw) / 2000
defMult  : P‰ = clamp(round(defPen·10), 0, 999); raw = trunc(DEF)·(1000 − P‰)/1000
           eff = (0<raw<1) ? 1 : trunc(raw);  defMult = eff ≤ 0 ? 1 : 5000 / (eff + 6000)
```
- **Defense constants** 5000 and 6000. Penetration n × 20 % lines from base B: P = 1 − (1 − B/100)·0.8ⁿ.
  The site's efficiency table uses DEF values 1 000-500 000. calcv4 presets: 3000/5000/10000/50000/100000, default 10000.
- **Enemy debuffs.** Defence ModStatR on an enemy: DEF' = max(0, trunc(DEF·(1+pct/100) + flat)).
  Boss "down" states set targetDefenseRatio: 발록 = 0 (DEF −100 %); 월드보스 = 0.3 (DEF −70 %) and weakness +15.
- **damage (AttackPower 9).** A ModStatR on AttackPower scales the current damage% (damage += damage·raw/1000).
  The universal +100 % is added later by the consumer.
- **statusDamage (AttackPowerInCc 57)** applies only while the target is in a CC state (step 4). Its factor form is not given.
- **Worked checks** (asserted in `combat_03_verify_and_summarize.py`):
  - AS 90 % + 20 % → 98 %.
  - Pen 63.8 % + 20 % → 71.04 %.
  - Pen 50 % + 1 line → 60 %; + 2 lines → 68 %.
  - DEF 10000 at 0 % pen → ×0.3125.

**Hit / evasion** (`js/calculator/data/content-simulator-data.js` `combatRules.hitAvoid`; client
BattleCreature.EvaluateStatGapValueChance + StatGapValueTable::AvoidChance):
- gap = max(0, target AvoidChance − attacker HitChance), capped at 100.
- Miss chance is in permille (‰), read from a 100-entry table. Some points: gap 1 → 10, 5 → 50, 10 → 100, 20 → 225,
  30 → 318, 50 → 479, 75 → 620, 100 → 700 (entry *i* is assumed to be gap *i*+1).
- Hit ≥ avoid → no miss. The stage page says "회피 (캐릭터 필요 명중)".
- Expected DPS is multiplied by (1 − miss‰/1000).

## 3. Attack speed & skill coefficients (JSON: `attackSpeed`, `skillCoefficients`)

**Attack speed.** Chained accumulation with ratio 150, display cap 150 %, **no breakpoints** (it is continuous).
- The skill-use clock advances by dt·(1000 + ASraw)/1000.
- Basic-attack rate (attacks/s) = (1 + min(150, AS)/100) · 1000 / DurationTimeMs.
- Every job's 1st-4th job basic attack has DurationTimeMs = 1000. So 1.0/s at 0 % and 2.5/s at 150 %.
- Sources: `js/assets/basic-attack-throughput.js`, `skill-data.js`.
- The standard basic/skill damage share per job (Lv130, 60 s reference) is in `js/assets/standard-damage-weights.js`.
  In that model only the basic share scales with AS.

**Skill level.** Source: `js/calculator/skill-engine.js`.
- level = max(1, 1 + enh[step] + AllSkillLevel + JobStepNSkillLevel).
- enh[step] = clamp(trunc((charLv − off)·3), 0, cap). Offsets 10/30/60/100, caps 60/90/120/120.
- Job advancement levels: 1 / 30 / 60 / 100. These are the RequireLevel of each job's base attacks.

**Coefficient scaling.**
- value = trunc(base · factorCurve[c][level] / 1000). Five curves (12, 20-23), each with 1001 levels.
- Curve values at levels 1, 30, 60, 120 and 1000:

| Curve | Lv 1 | Lv 30 | Lv 60 | Lv 120 | Lv 1000 |
|---|---|---|---|---|---|
| 12 | 1000 | 1150 | 1300 | 1600 | 6000 |
| 20 | 1000 | 1299 | 1654 | 2546 | 276906 |
| 21 | 1000 | 1120 | 1240 | 1480 | 5000 |
| 22 | 1000 | 1090 | 1180 | 1360 | 4000 |
| 23 | 1000 | 2500 | 4000 | 7000 | 15800 |

- Mastery modifiers: trunc(set · (1000 + Σratio) / 1000) + Σadd.
- GetDamageR Values = [ratioM, flag, hitCount]. oneHit% = ratioM/10 · (1 + P1/1000)(1 + P2/1000)(1 + P3/1000) · Π(1 + FD_M/1000).
  total% = oneHit% · hitCount. Max targets = MaxHitCount.
- Example: hero basic attack 11010 has ratioM 260 (26 %) × 2 hits, 3 targets, curve 21.

## 4. Combat timing (JSON: `combatTiming`, `growthDungeons.*.simulator`)

**Companion (동료) summon:**
- First summon at 60000 ms × SupporterSpawnInitialCoolTimeRatio / 1000.
  - Ratio 100 (6 s): growth dungeons.
  - Ratio 200 (12 s): world boss and guild contents.
- Re-summon every 90000 ms. Each summon lasts 30000 ms.
- SupporterCoolTimeReduceRatio only shortens re-summons.

**Cooldowns:**
- CoolTimeSpeed scales the 100 ms cooldown progress step of the hero and companions.
- CoolTimeReduceRatio (chained, ratio 100, cap 99.9 %) and CoolTimeReduce (ms) affect the starting cooldown of learned actives only.

**Content time limits:**

| Content | Time limit |
|---|---|
| 무기 던전 | 22 s |
| 강화 던전 | 25 s |
| 경험치 던전 | 22 s base, +4 s per 시간연장몹 |
| 장비 던전 | 30-40 s |
| 용사의 수련장 | 30 s mobs + up to 20 s boss |
| 월드보스 | 37-75 s |
| 길드토벌전 | 50 s |
| 길드대항전 | 35 s |

**Boss patterns:**
- 발록 다운: starts at 20.6 s, lasts 4 s, repeats every 22 s. DEF −100 %, player AS +100 %.
- 월드보스 Untargetable: 3.5 s, starts at 19.3-20.7 s, repeats every 35 s. Only basic attacks hit during it.
- 월드보스 다운: 10 s. Weakness +15 %, DEF ×0.3.

Start distances: 4951 mm (무기 던전) and 4572 mm (월드보스).

## 5. Leveling (JSON: `leveling`)

Max character level **140**. The full table holds 139 `requiredExp` values (EXP needed for L → L+1) plus a derived
cumulative column. Source: `js/data/level-experience-117.json`. EXP carries over across level-ups.

| Lv | requiredExp | Lv | requiredExp |
|---|---|---|---|
| 1 | 25 | 60 | 54362868145 |
| 2 | 100 | 70 | 607552395890 |
| 5 | 1800 | 80 | 6110934424793 |
| 10 | 13396 | 90 | 61465512763493 |
| 20 | 398544 | 100 | 915907513551302 |
| 30 | 8951974 | 110 | 10236064123563100 |
| 40 | 285880904 | 120 | 114396931121831000 |
| 50 | 4242128285 | 130 | 1278485333045920000 |
| 139 | 9525458015843620000 | 140 | — (max); cumulative ≈ 4.669e19 |

**EXP sources:**
- **Hunting:** expPerKill × (1 + EXP%/100).
- **Offline (방치) reward:** 0.9 kills/s × the current stage's expPerKill × (1 + EXP%). The reward window is clamped to 300 s-86 400 s.
  The site notes this is "constant-condition-estimate"; the server formula is unverified.
- **Burning-field booster:** 600 s, about 400 burning kills, each worth `burningExpPerKill`.
  `burningExpPerKill` is stored per stage; it is ×7.0 the normal EXP in ch 1 and ×19.55 in ch 47.
- **EXP dungeon sweep:** a fixed reward per dungeon level (150 rows, from 50000 to 21690469919004900).
  EXP% does not apply. 0-3 keys per day.
- **Party quests:** 4 quests × 4 difficulties, base clear EXP (`party-experience-118.json`).
- **Journey-treasure constants:** offline premium ×1.7 and others (`journey-treasure.json`).

**Stat growth:**
- No gold/meso stat-upgrade table exists in the source.
- The token-based 용사의 힘 (Hero Power, 9 stages) is included under `statGrowth.heroPower_용사의힘`.
  - Its stats are Attack, MaxHp, Defence, MainStat, 데미지 and 명중, each with per-level token costs.
  - Stage-up timers run up to 641 520 s.

## 6. Chapters & stages (JSON: `chapterStages`)

Sources: `stage.html` inline (`HUNT_ROWS`, `TRIAL_ROWS`, `EARLY_HUNT_EXP`), plus `level-experience-117.json`
(`chapters[]`: expPerKill, burningExpPerKill, theoreticalSpawn). Stage EXP is cross-checked against `journey-treasure.json` and matches.

**Structure:**
- There are 47 chapters with 4 / 8 / 10 (ch 3-28) / 15 (ch 29-38) / 20 (ch 39-47) stages.
- In a chapter with N stages, stages 1..N−1 are hunting fields (555 in total). Each has monster ATK/HP/DEF/HIT/AVO,
  EXP per kill and a variant count.
- Stages 2..N−1 also have a 도전 (challenge) entry (508 in total): normal-mob HP range, the HP of the boss that spawns last,
  the max cumulative monster count, DEF/HIT/AVO.
- Stage N is the chapter 보스 (47 in total).
- Kills/min (*derived*) = monstersPerCycle · 60 / cycleSeconds. This is the "젠컷" steady state; it excludes first-spawn wait,
  movement, and burning/elite extras.
- Monster stats are base × stage multiplier, published pre-multiplied.

Overview (s1 = stage 1, last = stage N−1; boss = stage N; large numbers in e-notation, exact values are in the JSON):

| Ch | N | hunt s1 ATK / HP / DEF / AVO | hunt last ATK / HP / DEF / AVO | EXP/kill s1→last | spawn s1 n/s | boss HP / DEF / HIT / AVO |
|---|---|---|---|---|---|---|
| 1 | 4 | 10 / 21 / 1 / 1 | 19 / 31 / 10 / 1 | 2 → 14 | 12/10 | 3,400 / 1000 / 3 / 3 |
| 2 | 8 | 27 / 38 / 20 / 1 | 81 / 915 / 140 / 7 | 24 → 136 | 49/20 | 26,350 / 1000 / 11 / 11 |
| 3 | 10 | 133 / 1,395 / 200 / 10 | 354 / 9,835 / 360 / 18 | 159 → 558 | 46/25 | 419,068 / 1000 / 20 / 20 |
| 5 | 10 | 1,139 / 74,596 / 560 / 28 | 1,957 / 193,046 / 720 / 36 | 2,053 → 5,459 | 50/30 | 1.155e7 / 2050 / 38 / 38 |
| 10 | 10 | 21,579 / 1.020e7 / 1460 / 73 | 31,882 / 2.244e7 / 1620 / 81 | 273,100 → 505,490 | 60/35 | 1.693e9 / 2300 / 83 / 83 |
| 15 | 10 | 146,893 / 6.344e8 / 2360 / 118 | 193,430 / 1.218e9 / 2520 / 126 | 5.10e6 → 7.54e6 | 68/34 | 1.179e11 / 2550 / 128 / 128 |
| 20 | 10 | 658,091 / 2.109e10 / 3260 / 163 | 833,650 / 4.049e10 / 3420 / 171 | 4.52e7 → 5.95e7 | 64/34 | 3.369e12 / 2800 / 173 / 173 |
| 25 | 10 | 2.37e6 / 7.290e11 / 4160 / 208 | 2.89e6 / 1.453e12 / 4320 / 216 | 2.12e8 → 2.75e8 | 67/34 | 2.084e14 / 3050 / 218 / 218 |
| 30 | 15 | 7.25e6 / 3.567e13 / 5160 / 258 | 9.37e6 / 7.607e13 / 5420 / 271 | 8.64e8 → 1.09e9 | 62/34 | 1.186e16 / 3300 / 263 / 263 |
| 35 | 15 | 2.90e7 / 2.107e15 / 6560 / 307 | 3.75e7 / 4.494e15 / 6820 / 320 | 3.01e9 → 3.80e9 | 62/34 | 7.305e17 / 3550 / 340 / 320 |
| 40 | 20 | 1.21e8 / 1.378e17 / 8060 / 382 | 1.63e8 / 3.316e17 / 8420 / 400 | 1.08e10 → 1.41e10 | 61/34 | 5.630e19 / 3800 / 515 / 403 |
| 45 | 20 | 5.98e8 / 1.420e19 / 9960 / 477 | 8.11e8 / 3.417e19 / 10320 / 495 | 4.45e10 → 5.82e10 | 60/34 | 6.070e21 / 4050 / 690 / 498 |
| 47 | 20 | 1.135e9 / 9.067e19 / 10720 / 515 | 1.538e9 / 2.182e20 / 11080 / 533 | 7.84e10 → 1.03e11 | 60/34 | 3.947e22 / 4150 / 760 / 536 |

Hunt-field patterns:
- DEF rises by +20 per stage within a chapter (ch 3+); hunt HIT = AVO.
- Chapter-boss DEF is 1000 (ch 1-3), then 2000 + 50·(ch − 4).
- Boss HIT exceeds AVO from ch 35 on.
- The full 47-row overview is printed by `combat_03_verify_and_summarize.py`. Chapter names: the data has `CHAPTER1`…,
  and the site shows real names only for ch 45-47 (골드비치 해변가 풀숲 / 얕은 바다 / 거친 파도).

## 7. Growth dungeons & world boss (JSON: `growthDungeons`)

Each dungeon has 150 stages (source: `growth.html` inline rows). Every 10th stage is IsHard. The simulator copy adds creature,
tier, HitChance and timeLimitMs (`content-simulator-data.js`); the two copies were cross-checked and are identical.

| Dungeon | Monster(s) | HP (s1 → s150) | ATK (s1 → s150) | DEF (s1 → s150) | Clear condition |
|---|---|---|---|---|---|
| 무기 던전 | 머쉬맘 | 2,000 → 3.08e21 | 320 → 6.16e9 | 50 → 7500 | 1 kill in 22 s |
| 강화 던전 | 발록 | 1.8e6 → 5.27e22 | 4,800 → 1.43e10 | 1000 → 8450 | 1 kill in 25 s |
| 경험치 던전 | 3 normal types + timer mob | from 800 | 20 → 1.82e9 | normal DEF 300 → 7750 | 20-35 kills |
| 장비 던전 | normal, bomb, speed | from 1,440 | — | — | 75-120 kills in 30-40 s |
| 용사의 수련장 | flying / normal / large / buff / boss | boss 7e4 → 6.49e21 | — | — | — |
| 월드보스 (20 levels) | 킹 캐슬 골렘 | 2e5 → 3.28e17 | — | 1500 → 62100 | HIT 99999 at Lv 20; infinite HP at Lv 20 |

## 8. Missing / unknown

1. **Character base stats per level.** The hidden base main stat and base HP/MP/ATK/DEF per level are not in the data.
2. **Gold/meso stat-growth system.** Not present; only 용사의 힘 was found.
3. **Damage taken by the player.** There is no formula for monster ATK vs player DEF/HP, for applying Toughness (cap 95 %),
   or for CriticalResist against monster crits. Monster crit stats are also absent.
4. **Damage rolls.** The min/max roll distribution is not given (the site uses the average only).
   Base crit damage and the base min/max ratio of a new character are unknown.
5. **statusDamage and amp.** The statusDamage factor form and the client stat name of amp (데미지 증폭) are not given.
6. **Cooldown rules.** How % and flat cooldown reduction combine is not given; there are no GCD or queue rules.
7. **Chapter monsters.** Missing: monster names per stage, monster attack cadence, ATK of challenge/boss monsters,
   time limits for challenge/boss fights, base stats and tier multipliers, spawn positions and wave composition
   beyond n/cycle, and elite/burning spawn rules.
8. **Stage progression.** Rules for auto-advance and fail/retry are not given.
9. **Idle rewards.** Server online/offline reward formulas are unverified. Meso and item idle rates are absent.
10. **Combat simulator.** It is server-side (`/api/v4/simulate`); only its input tables are public.
11. **StatGapValueTable indexing.** The mapping from array index to gap is inferred.
12. **Out of scope here.** Per-skill data (`skill-data.js`), companions/artifacts (`loadout-peak-data.js`), and
    boss raids (`boss.html`) are present in the mirror but were not extracted. Only the rules that apply to every skill are taken from them.
