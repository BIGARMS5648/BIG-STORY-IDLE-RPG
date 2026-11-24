# 메이플 키우기 — Jobs & Skills spec (client 1.18.0, via mapleidleindex.com)

Machine-readable data: `jobs-skills.json` (same folder). Regenerate: `node scripts/extract-jobs-skills.js <web> jobs-skills.json`;
per-job overview below: `node scripts/make-overview.js jobs-skills.json`. Numbers are copied from the tables; anything
marked **derived** was computed by the formula below or by the site's own `skill-engine.js` (run in a sandbox).

## 1. Sources (all under `scratchpad/web/`)
| file (site path) | used for |
|---|---|
| `js/calculator/data/skill-data.js` (`/calculator/data/skill-data.js`) | `MAPLE_SKILL_DATA`: 16 jobs, 496 hero skill rows, 928 mastery rows, 1475 skill records, 88 projectiles, 5 factor curves, enhance rule, 87 expression macros, 748 state max stacks. Built from HeroSkillTable, SkillTable, SkillLevelFactorTable, HeroSkillEnhanceTable, HeroSkillMasteryTable, SkillProjectileTable, ExpressionMacroTable, StateTable (.bytes) |
| `js/calculator/data/skill-names-ko.js` | `MAPLE_SKILL_NAMES` (482 skills), `MAPLE_JOB_NAMES` (16), `MAPLE_MASTERY_NAMES` (928 nodes) |
| `js/calculator/data/skill-descriptions.js` | in-game Korean description templates + parameter scaling (`format(id, level)`) |
| `js/calculator/skill-engine.js` | skill level, level scaling, mastery merge, damage-graph resolver, buffs (logic summarized in §5–§7) |
| `js/skills/skills-page.js`, `js/skills/skills-explorer.js`, `js/skills/skills-cooldown.js` | site categories (active/buff/passive), unlock labels, static cooldown display |
| `js/assets/basic-attack-throughput.js` | basic-attack cadence (uses/s) formula |
| `js/data/skill-hitboxes.json` (+ `js/assets/skill-hitbox-model.mjs`) — fetched | hitbox stages per skill, English job/skill names |
| `calcv4.html` inline script | how a coefficient becomes damage (`scenarioDamage`, `skillLineDamage`) |
| `js/calculator/battle-stat-math.js` | stat accumulators (AttackSpeed cap 150, FinalDamage multiplicative) |

## 2. JSON layout (`jobs-skills.json`)
- `meta` (sources, conventions), `rules` (all formulas below as text + constants), `factorCurves` ("12","20","21","22","23": index = skill level 1..1000, `[0]` = null),
  `expressionMacros`, `stateMaxStacks`, `projectiles` (verbatim SkillProjectileTable rows).
- `jobs[16]`: `creatureIndex, key, codeName, nameKo, nameEn, attackType, initialBaseAttackSkillIndex, baseAttackSkillIndices{1..4}`,
  `tiers{0..4}` (unlockLevel, enhanceCap, basicAttackSkillId, skillIds), `skillRows[31]` (verbatim HeroSkill row + nameKo/nameEn,
  category, unlock, skillLevelRule), `masteries[58]` (verbatim mastery row + nameKo, programSkillId),
  `derivedEngineSnapshotLv140` (site-engine output at Lv140, no bonuses: skill levels, base attack, attacks, triggered attacks,
  buffs/passives with scaled values, static cooldown/trigger-ratio after masteries).
- `skills{id}` (1475): `nameKo/nameEn`, `trigger{type, ratioM, flags, timeMs, condition}`, `mp`, `cooldownMs`, `castDurationMs`,
  `tickTimeMs`, `targeting{skillTargetType, targetCount, rangeType, maxRangeMm}`, `damageOperations[]` (ratioM, hitCount,
  maxTargets, levelCurve, area, condition, modStats, derived % at Lv1 and at the tier's cap level), `modifierOperations[]`
  (structured restatement of ModSkill*/ModStat*/ChangeSkill ops), `description{template, params}`, `hitbox[]`, `referencedBy`, `raw` (verbatim record).
- Conventions: Operations are 1-based (`Operations[0]` = null). "M" units: 1000 = 100 %, displayed % = value/10. ms / mm.
  Rects (`RectAreaMm`, `MaxRangeMm`) = `[front, back, up, down]` from the caster (skill-hitbox-model.mjs `shapeBounds`).

## 3. Jobs (16) and advancement
| # | key | 한국어 (engine) | EN (hitbox json) | attack | initial BA id | 1차/2차/3차/4차 basic-attack skill |
|---|---|---|---|---|---|---|
| 1 | hero | 히어로 | Hero | Physical | 10000 | 11010 / 12010 / 13010 / 14010 |
| 2 | paladin | 팔라딘 | Paladin | Physical | 10000 | 21010 / 22010 / 23010 / 24010 |
| 3 | darkKnight | 다크나이트 | Dark Knight | Physical | 10000 | 31010 / 32010 / 33010 / 34010 |
| 4 | archMageIL | 아크메이지(썬·콜) | Arch Mage (Ice/Lightning) | Magical | 10000 | 41010 / 42010 / 43010 / 44010 |
| 5 | archMageFP | 아크메이지(불·독) | Arch Mage (Fire/Poison) | Magical | 10000 | 51010 / 52010 / 53010 / 54010 |
| 6 | bishop | 비숍 | Bishop | Magical | 10000 | 61010 / 62010 / 63010 / 64010 |
| 7 | bowMaster | 보우마스터 | Bowmaster | Physical | 10001 | 71010 / 72010 / 73010 / 74010 |
| 8 | marksman | 신궁 | Marksman | Physical | 10001 | 81010 / 82010 / 83010 / 84010 |
| 9 | nightLord | 나이트로드 | Night Lord | Physical | 10002 | 91010 / 92010 / 93010 / 94010 |
| 10 | shadower | 섀도어 | Shadower | Physical | 10000 | 101010 / 102010 / 103010 / 104010 |
| 11 | viper | 바이퍼 | Buccaneer | Physical | 10000 | 111010 / 112010 / 113010 / 114010 |
| 12 | captain | 캡틴 | Corsair | Physical | 10003 | 121010 / 122010 / 123010 / 124010 |
| 13 | nightWalker | 나이트워커 | Night Walker | Physical | 10002 | 131010 / 132010 / 133010 / 134010 |
| 14 | windBreaker | 윈드브레이커 | Wind Archer | Physical | 10001 | 141010 / 142010 / 143010 / 144010 |
| 15 | flameWizard | 플레임위자드 | Blaze Wizard | Magical | 10000 | 151010 / 152010 / 153010 / 154010 |
| 16 | soulMaster | 소울마스터 | Dawn Warrior | Physical | 10000 | 161010 / 162010 / 163010 / 164010 |

- Each job is one creature (final 4th-job class) with 31 hero skill rows: JobStep 0 ×1 (9000 민첩한 몸놀림 for jobs 1–12,
  9001 엘리멘탈 하모니 for 13–16), 1차 ×4, 2차 ×8, 3차 ×8, 4차 ×10. Skill ids are per job (e.g. 11010 and 21010 are both 슬래시 블러스트).
- Tier unlock levels (site constant `STEP_UNLOCK_LEVELS`): 1차 Lv1, 2차 Lv30, 3차 Lv60, 4차 Lv100. Every non-first row also carries
  its own `RequireLevel` (range 10–125; the 2/3/4차 basic attacks have 30/60/100). Rows without RequireLevel: the 1차 basic
  attack, 9000/9001, and one 1차 mobility passive per job (워리어 리프, 마나 웨이브, 더블 점프, 플래시 점프, 파이렛 리프, 쉐도우 점프,
  거스트 쉬프트, 파이어워크, 소울 리프) which has `RequireMissionIndex: 518` instead.
- Basic attack: rows whose skill has `TriggerFlag ReplaceBaseAttack`; the highest unlocked tier's one is used
  (`buildState` sorts unlocked base rows by JobStep desc). Shared numbers for every job (Lv1, curve 21, cast `DurationTimeMs` 1000):
  1차 26%×2 hits (3 targets, MP15) · 2차 40%×3 (5, MP25) · 3차 80%×5 (6, MP50) · 4차 290%×5 (6, MP130).
  Exceptions: 41010/51010/61010 ops have no MaxHitCount; 92010 too; captain 124010 has a second op 580%×5/6t;
  나이트워커 131010–134010 deal damage through projectiles (131010/131011 …). Ranges/hit timings differ per job (see JSON `skills[id]`).
- Mastery-stat node `BaseAttackMaxHitCount +1` (Lv64, every job) adds 1 target to the basic attack.

## 4. Skill level
```
enhance[step] = max(0, min(cap[step], trunc((charLevel - offset[step]) * 3)))
  offset/cap: 1차 10/60, 2차 30/90, 3차 60/120, 4차 100/120   (skill-data.js enhance.assumedFullySpentFormula;
  startLevel 11, pointsPerLevel 3 => each char level from 11 gives 3 points to the current tier; caps reached at Lv30/60/100/140)
skillLevel = DisableSkillLevel ? 1 : max(1, 1 + enhance[JobStep] + allSkill + stepBonus[JobStep])   (JobStep 0 => 1)
```
- `allSkill` = 모든 스킬 레벨 ("모스렙"), `stepBonus` = 1차/2차/3차/4차 스킬 레벨 (site inputs; they come from equipment etc., not from skill data).
  Without bonuses the max is 61 / 91 / 121 / 121. Site allows overrides 1..1000; curves hold levels 1..1000.
- Fixed-level rows (`DisableSkillLevel`): 9000/9001, each job's mission leap passive, plus e.g. 14060, 41040/51040/61040, 92030,
  112020, 134020 (다크니스 오멘), 142030.
- Linked sub-skills with `FollowLevelIndex` use the owner row's level; other sub-skills and mastery programs are Lv1
  (engine `effectiveLevel`). Mastery nodes do not have levels.

## 5. Per-level scaling (exact)
```
for each (valueIndex, curveId) pair in op.ValueLevelFactors:  Values[valueIndex] = trunc(Values[valueIndex] * curve[curveId][skillLevel] / 1000)
```
| curve | L1 | L2 | L61 | L91 | L121 | L1000 | shape (verified over the array) | used by |
|---|---|---|---|---|---|---|---|---|
| 12 | 1000 | 1010 | 1305 | 1455 | 1605 | 6000 | +5/level from L2 | active (non-basic) attack GetDamageR (113), GetDotR (10) |
| 21 | 1000 | 1008 | 1244 | 1364 | 1484 | 5000 | +4/level | basic attacks + triggered passive hits (e.g. 파이널 어택) GetDamageR (114), active-buff ModStat/ModStatR (70), heals |
| 22 | 1000 | 1006 | 1183 | 1273 | 1363 | 4000 | +3/level | passive ModStat/ModStatR values (293), shields, MP |
| 23 | 1000 | 1100 | 4050 | 5550 | 7010 | 15800 | +50/level to L120, then +10 | ModSkillStat FinalDamage (55 ops) of 4차 passive 메이플 용사 (jobs 1–12) / 시그너스 나이츠 (13–16) |
| 20 | 1000 | 1010 | 1667 | 2082 | 2563 | 276906 | non-linear | not referenced by any op |
Example: 14010 레이징 블로우 ratioM 2900, curve 21 → Lv121: trunc(2900*1484/1000)=4303 → 430.3 % × 5 hits, 6 targets.
Expression values (`$...`, `#Macro(...)`) are evaluated at runtime, then the pending curve is applied. Descriptions use the
same curves (`value + trunc(value*(f-1000)/1000)`, then `Div n` → 1 decimal).

## 6. Skill record fields (SkillTable)
- `TriggerType`: None (active skill), OnStart (applied at battle start: passives, mastery programs), OnAttack, OnTimer, OnState(End),
  OnActiveSkill, OnDamage, OnHit, OnTryAttack, OnWaveStart, OnEnemyDie. `TriggerRatio` M (1000 = 100 % chance), `TriggerTimeMs`
  (OnTimer interval array), `TriggerCondition` (expression, e.g. 14020 needs `ComboAttack >= 5`). TriggerRatio may itself be an
  expression (73020 `#MultByAttackSpeed(200)` = AttackSpeed_M×200/1000+200; 131033 `#Element_Darkness_Ratio(200)`); AttackSpeed in expressions is M (1000 = 100 %).
- `CoolTimeMs`, `CoolTimeGroupIndex`, `InitialMin/MaxCoolTimeMs`, `Mp` (cost), `DurationTimeMs` (site: 시전 시간 / cast time),
  `TickTimeMs` (array; semantics not stated by the site; bishop 64010 uses strings like `"100[2:5:6]"`), `ActionName`.
- Targeting: `SkillTargetType` (Enemy, Myself, TriggerTarget, RandomEnemy, Ally, Friend, MinStatEnemy), `TargetCount`,
  `SkillRangeType` Rect + `MaxRangeMm` (acquisition range), `MaxFireRangeMm`, `RetargetOnFire/Dead`. `AttrFlag` Ice/Lightning/Fire/Poison.
- Operation types (count): ModSkillStat 506, ModStat 329, ModSkill 260, GetDamageR 227, ModStatR 125, ModSkillEnabled 102,
  CreateProjectile 80, ModSkillR 71, State 51, UseSkill 41, … GetDotR 14, ChangeSkill 9, SetSkill 11 (full list in JSON `raw`).
- **GetDamageR**: `Values=[ratioM, damageFlag, hitCount]`, `MaxHitCount` = max targets, `RectAreaMm`/`RadiusMm` = damage area,
  `ModStats` = hit-local stats (`AttackPowerToBoss`, `AttackPowerExcludeBoss`, M units), `EnableCondition`, `FireRatio` (weighted branch),
  `QueueDelayMs`/`DelayMs`/`DistanceDelayMs` timing. **GetDotR**: per tick (site excludes DoT from per-use totals).
- Damage also flows through `UseSkill`/`UseSkillToTarget` (Values[1] = repeat count), `CreateProjectile`/`FireProjectile`
  (projectile `SkillIndex[]`, `TickTimeMs`, `DurationTimeMs`, `MaxTargetCount`, `MaxFireCount`), `NextSkillIndex`.
- Site category: PassiveSkill → passive; ActiveSkill + tag `attack` → active (A); other ActiveSkill → buff (B).
  Tags in data: baseAttack, attack, activeBuff, staticPassive, conditionalPassive, skillModifier.

## 7. Damage per use (site engine `resolveDamage`) and DPS
1. Walk the skill graph from the root (after `ChangeSkill` replacements): direct GetDamageR ops, UseSkill links (×repeat),
   projectiles (and their linked skills/children), NextSkillIndex. Conditions resolved per mode: boss/normal target,
   `unbuffed` (state count 0) vs `peak` (state present; static peak stacks ComboAttack 5, Ice 5, ArchMagePoison/Burn 5).
2. Per line: `oneHit% = scaledRatioM/10 × (1+ΣGiveDamagePower1_M/1000) × (1+Power2_M/1000) × (1+Power3_M/1000) × Π(1+pipelineFD_M/1000)`;
   `total% = oneHit% × hitCount × repeat`; then × Π(1 + FinalDamage_M/1000) of every `ModSkillStat FinalDamage` passive targeting the line
   (each owner multiplies separately). FireRatio branches: expected value (unbuffed) or best branch (peak). `#FlashSlash(x)` → x or 1.5x (peak).
3. Mastery numeric merge: `trunc(set × (1000 + Σ ModSkillR) / 1000) + Σ ModSkill`. Applies to `GiveDamagePower1, Value, MaxHit(Count),
   ModStatAddValue, DurationMs, FireRatio, SkillCoolTimeMs, SkillTriggerRatio, SkillTargetCount, SkillTriggerTimeMs`, projectile fields.
4. Damage of a hit (calcv4): `scenarioDamage(profile,target,route) × total%/100`; route `basic` uses BaseAttackPower (기본 공격 데미지),
   otherwise SkillPower (스킬 데미지); `scenarioDamage = attack × (1+dmg%) × (1+amp%) × (1+statScaling%) × critAvg × Π(1+FD_k%) ×
   avg(min,max range) × 5000/(effDef+6000) × (1+boss|normal%) × (1+basic|skill%) × (1+enemyWeakness%)`; hit-local ModStats add to boss/normal %.
5. DPS: the client-side site does **not** sum a job DPS ("사용 횟수와 쿨타임이 필요"); its battle simulator is a server API (`/api/v4/*`).
   Only basic-attack cadence is given: `uses/s = max(0, 1 + min(150, attackSpeed%)/100) × 1000 / DurationTimeMs`
   (requires ReplaceBaseAttack, no IgnoreSkillSpeed, no cooldown, one-shot projectiles only). Cooldowns: `CoolTimeMs` after mastery
   `SkillCoolTimeMs` modifiers (static view; external 쿨감 `CoolTimeReduceRatio` is a chained stat, max 99.9 %, see battle-stat-math).
6. Buffs: ModStat/ModStatR/ModStatOnTick values scaled by level; ModStatR on `Attack` → 공격력 %; other stat keys map to site stats
   (AttackPower→데미지, FinalDamage (multiplicative), CriticalChance, CriticalPower, PiercePower, AttackSpeed, SkillPower, BaseAttackPower, …).
   Permanent = OnStart + DurationMs ≥ 99999999 or `IsSticky`.

## 8. Masteries (HeroSkillMasteryTable) — identical schedule for all 16 jobs
- 58 nodes per job: 29 **main** nodes `TierIndex 1..29` (linear chain via `RequireMasteryIndex`) and 29 **side** nodes
  `TierIndex 1001..1029`, side N requires main N. Unlock = `RequireCreatureLevel` (12 … 138) + previous node + cost
  `FreeDia` + learn time `LearnedDelaySeconds`. Site assumption: every node whose level is reached is learned.
- Main levels: 12,15,19,22,26 | 32,37,42,47,52,56 | 62,66,71,76,80,84,88,92,96 | 102,106,111,116,120,124,128,132,136; main nodes buff the
  basic attack of their band (피해 / 대상 / 보스 몬스터 피해 / 타격). Cost 200→11000 FreeDia; delay 5 s → 251200 s.
- Side levels: 14,17,21,24,28,34,39,44,49,54,58,64,68,73,78,82,86,90,94,98,104,108,113,118,122,126,130,134,138; cost 300→16500.
  7 side nodes are plain stats (`StatData`, no program): Lv14 MainStat +30, Lv17 CriticalChance +50 (5 %), Lv28 BaseAttackPower +150 (15 %),
  Lv34 HitChance +5, Lv58 MaxDamageRatio +100 (10 %), Lv64 BaseAttackMaxHitCount +1, Lv86 SkillPower +150 (15 %); the rest run a program skill.
  Main-node bands: T1–5 → 1차 basic attack, T6–11 → 2차, T12–20 → 3차, T21–29 → 4차 (ParentSkillIndex, all jobs).
- Program op mix (all jobs): ModSkillStat GiveDamagePower1 435, ModSkill Value 91 (hitCount when valueIndex 2), ModSkill ModStatAddValue 89
  (boss dmg on the hit), ModSkillEnabled 78, ModSkill MaxHitCount 54, ModSkillR SkillCoolTimeMs 31, ModSkillProjectile(R) 42, ModSkillR
  DurationMs 21, ModStat/ModStatR 28, ChangeSkill 3, … Trigger: OnStart 811, OnAttack 3, OnWaveStart 1, OnActiveSkill 1.
- Program skill ids normally equal the MasteryIndex, but not always (hero 10225→10255, 10255→10225, 10285→10295, 10295→10285);
  JSON `masteries[].programSkillId` holds the real link.

## 9. Per-job skill overview
Legend: BA basic attack, A active attack, B buff/utility, P passive; `LvN` = RequireLevel; `base` = Lv1 table coefficient per op
(%×hits/targets); `Lv140` = **derived** site-engine total % at char Lv140 (masteries+passives, normal target, unbuffed);
`CD` = table cooldown; `OnAttack 25%` = trigger type and chance.

### 1. 히어로 — hero / Hero.Hero / Physical / EN "Hero"
- 공통: 민첩한 몸놀림 9000 [B, 고정Lv1, CD60s]
- 1차 (Lv1, 강화cap 60): 슬래시 블러스트 11010 [BA, base 26%×2/3t] · 워리어 리프 11020 [P, 미션518, 고정Lv1] · 아이언 바디 11030 [P, Lv10] · 워리어 마스터리 11040 [P, Lv15]
- 2차 (Lv30, 강화cap 90): 브랜디쉬 12010 [BA, Lv30, base 40%×3/5t] · 웨폰 액셀레이션 12060 [P, Lv33] · 플래시 슬래시 12020 [A, Lv35, ratio expr #FlashSlash(3500)×1/7t, Lv140 5047.2%, CD16s] · 피지컬 트레이닝 12080 [P, Lv38] · 스피릿 블레이드 12040 [B, Lv40, CD45s] · 웨폰 마스터리 12050 [P, Lv43] · 콤보 어택 12030 [P, Lv45, OnAttack 40%] · 파이널 어택 12070 [P, Lv50, OnAttack 25%, base 35%×1, Lv140 602.5%]
- 3차 (Lv60, 강화cap 120): 브레이브 슬래시 13010 [BA, Lv60, base 80%×5/6t] · 셀프 리커버리 13060 [P, Lv60] · 돌진 13030 [A, Lv63, base 600%×1/12t, Lv140 5378.7%, CD22s] · 스카링 소드 13040 [B, Lv66, CD30s] · 오라 블레이드 13020 [A, Lv69, base 250%×4/8t, Lv140 7227.6%, CD16s] · 찬스 어택 13070 [P, Lv72] · 인듀어 13080 [P, Lv74] · 콤보 시너지 13050 [P, Lv75]
- 4차 (Lv100, 강화cap 120): 레이징 블로우 14010 [BA, Lv100, base 290%×5/6t, Lv140 4518.2%] · 메이플 용사 14100 [P, Lv100] · 인사이징 14030 [A, Lv103, base 900%×3/10t, Lv140 6500.3%, CD17s] · 어드밴스드 파이널 어택 14080 [P, Lv105] · 인핸스 레이징 블로우 14020 [A, Lv107, base 610%×6/12t, Lv140 8811%, CD17s] · 어드밴스드 콤보 14060 [P, Lv110, 고정Lv1] · 인레이지 14050 [P, Lv115, OnTimer] · 매직 크래쉬 14040 [A, Lv117, base 4800%×1/9t, Lv140 7704%, CD28s] · 컴뱃 마스터리 14090 [P, Lv120] · 스탠스 14070 [P, Lv125]
### 2. 팔라딘 — paladin / Hero.Paladin / Physical / EN "Paladin"
- 공통: 민첩한 몸놀림 9000 [B, 고정Lv1, CD60s]
- 1차 (Lv1, 강화cap 60): 슬래시 블러스트 21010 [BA, base 26%×2/3t] · 워리어 리프 21020 [P, 미션518, 고정Lv1] · 아이언 바디 21030 [P, Lv10] · 워리어 마스터리 21040 [P, Lv15]
- 2차 (Lv30, 강화cap 90): 디바인 스윙 22010 [BA, Lv30, base 40%×3/5t] · 웨폰 액셀레이션 22060 [P, Lv33] · 페이지 오더 22020 [A, Lv35, base 460%×1/7t, Lv140 6634.1%, CD18s] · 피지컬 트레이닝 22080 [P, Lv38] · 스탠스 22040 [P, Lv40] · 웨폰 마스터리 22050 [P, Lv43] · 홀리 차지 22030 [P, Lv45, OnAttack 15%] · 파이널 어택 22070 [P, Lv50, OnAttack 25%, base 35%×1, Lv140 823.9%]
- 3차 (Lv60, 강화cap 120): 디바인 차지 23010 [BA, Lv60, base 80%×5/6t] · 아킬레스 23070 [P, Lv60] · 돌진 23020 [A, Lv63, base 600%×1/12t, Lv140 5378.7%, CD22s] · 노블 디맨드 23040 [A, Lv66, dmg via linked/projectile, Lv140 9252.5%, CD30s] · 컴뱃 오더스 23050 [B, Lv69, CD35s] · 파라쇼크 가드 23060 [P, Lv72] · 리스토네이션 23030 [B, Lv74, CD25s] · 블레싱 아머 23080 [P, Lv75, OnTimer]
- 4차 (Lv100, 강화cap 120): 블래스트 24010 [BA, Lv100, base 290%×5/6t, Lv140 4518.2%] · 메이플 용사 24100 [P, Lv100] · 생츄어리 24030 [A, Lv103, base 780%×5/7t, Lv140 9389.3%, CD18s] · 가디언 스피릿 24060 [B, Lv105, CD24s] · 디바인 스티그마 24020 [A, Lv107, base 460%×6/8t+400%×4/8t, Lv140 10496.7%, CD16s] · 어드밴스드 홀리 차지 24090 [P, Lv110, OnState] · 디바인 블레싱 24050 [B, Lv115, CD30s] · 매직 크래쉬 24040 [A, Lv117, base 4800%×1/9t, Lv140 7704%, CD28s] · 팔라딘 엑스퍼트 24080 [P, Lv120] · 디바인 저지먼트 24070 [P, Lv125, OnActiveSkill]
### 3. 다크나이트 — darkKnight / Hero.DarkKnight / Physical / EN "Dark Knight"
- 공통: 민첩한 몸놀림 9000 [B, 고정Lv1, CD60s]
- 1차 (Lv1, 강화cap 60): 슬래시 블러스트 31010 [BA, base 26%×2/3t] · 워리어 리프 31020 [P, 미션518, 고정Lv1] · 아이언 바디 31030 [P, Lv10] · 워리어 마스터리 31040 [P, Lv15]
- 2차 (Lv30, 강화cap 90): 스피어 풀링 32010 [BA, Lv30, base 40%×3/5t] · 웨폰 액셀레이션 32070 [P, Lv33] · 비홀더 32020 [A, Lv35, dmg via linked/projectile, Lv140 7225.8%, CD30s] · 아이언 월 32050 [P, Lv38] · 비홀더 쇼크 32030 [A, Lv40, dmg via linked/projectile, Lv140 6717.9%, CD18s] · 웨폰 마스터리 32060 [P, Lv43] · 하이퍼 바디 32040 [B, Lv45, CD30s] · 파이널 어택 32080 [P, Lv50, OnAttack 25%, base 35%×1, Lv140 602.5%]
- 3차 (Lv60, 강화cap 120): 라만차 스피어 33010 [BA, Lv60, base 80%×5/6t] · 비홀더 도미넌트 33040 [P, Lv60] · 돌진 33020 [A, Lv63, base 600%×1/12t, Lv140 5378.7%, CD22s] · 크로스 오버 체인 33030 [B, Lv66, CD30s] · 비홀더스 버프 33060 [P, Lv69] · 로드 오브 다크니스 33070 [P, Lv72, OnAttack 30%, CD3s] · 인듀어 33080 [P, Lv74] · 비홀더 쇼크 강화 33050 [P, Lv75]
- 4차 (Lv100, 강화cap 120): 다크 임페일 34010 [BA, Lv100, base 290%×5/6t, Lv140 4518.2%] · 메이플 용사 34100 [P, Lv100] · 궁니르 디센트 34020 [A, Lv103, base 1800%×2, Lv140 13000.5%, CD13s] · 어드밴스드 파이널 어택 34080 [P, Lv105] · 리인카네이션 34050 [P, Lv107] · 비홀더스 리벤지 34060 [P, Lv110, CD5s] · 다크 레조넌스 34030 [B, Lv115, CD32s] · 매직 크래쉬 34040 [A, Lv117, base 4800%×1/9t, Lv140 7704%, CD28s] · 어드밴스드 웨폰 마스터리 34090 [P, Lv120] · 스탠스 34070 [P, Lv125]
### 4. 아크메이지(썬·콜) — archMageIL / Hero.ArchMageIL / Magical / EN "Arch Mage (Ice/Lightning)"
- 공통: 민첩한 몸놀림 9000 [B, 고정Lv1, CD60s]
- 1차 (Lv1, 강화cap 60): 에너지 볼트 41010 [BA, base 26%×2] · 마나 웨이브 41020 [P, 미션518, 고정Lv1] · 텔레포트 41040 [B, Lv10, 고정Lv1, CD10s] · 매직 가드 41030 [B, Lv15, CD30s]
- 2차 (Lv30, 강화cap 90): 콜드 빔 42010 [BA, Lv30, base 40%×3/5t] · 매직 액셀레이션 42050 [P, Lv33] · 프리징 이펙트 42020 [P, Lv35, OnAttack 40%] · 썬더 볼트 42030 [A, Lv38, base 180%×3/8t, Lv140 10698.9%, CD18s] · 메디테이션 42040 [B, Lv40, CD30s] · 스펠 마스터리 42060 [P, Lv43] · MP 이터 42080 [P, Lv45, OnAttack 50%, CD1s] · 하이 위즈덤 42070 [P, Lv50]
- 3차 (Lv60, 강화cap 120): 아이스 스트라이크 43010 [BA, Lv60, base 80%×5/6t] · 엘리멘탈 어댑팅 43040 [P, Lv60, OnTimer] · 글레이셜 월 43020 [A, Lv63, base 290%×3/8t, Lv140 7798.3%, CD22s] · 프로즌 브레이크 43050 [P, Lv66] · 썬더 스피어 43030 [A, Lv69, dmg via linked/projectile, Lv140 1734.8%, CD30s] · 엘리멘탈 리셋 43060 [P, Lv72, OnAttack 25%] · 매직 크리티컬 43070 [P, Lv74] · 엘리먼트 앰플리피케이션 43080 [P, Lv75]
- 4차 (Lv100, 강화cap 120): 체인 라이트닝 44010 [BA, Lv100, base 290%×5/6t, Lv140 4518.2%] · 메이플 용사 44100 [P, Lv100] · 프리징 브레스 44020 [A, Lv103, dmg via linked/projectile, Lv140 1926%, CD40s] · 블리자드 44030 [A, Lv105, base 600%×3/7t, Lv140 4333.5%, CD33s] · 프로즌 오브 44040 [A, Lv107, dmg via linked/projectile, Lv140 1083.3%, CD23s] · 인피니티 44050 [B, Lv110, CD30s] · 엘퀴네스 44060 [A, Lv115, dmg via linked/projectile, Lv140 8426.3%, CD80s] · 마스터 매직 44070 [P, Lv117] · 아케인 에임 44080 [P, Lv120, OnAttack 25%] · 프로스트 이펙트 44090 [P, Lv125]
### 5. 아크메이지(불·독) — archMageFP / Hero.ArchMageFP / Magical / EN "Arch Mage (Fire/Poison)"
- 공통: 민첩한 몸놀림 9000 [B, 고정Lv1, CD60s]
- 1차 (Lv1, 강화cap 60): 에너지 볼트 51010 [BA, base 26%×2] · 마나 웨이브 51020 [P, 미션518, 고정Lv1] · 텔레포트 51040 [B, Lv10, 고정Lv1, CD10s] · 매직 가드 51030 [B, Lv15, CD30s]
- 2차 (Lv30, 강화cap 90): 플레임 오브 52010 [BA, Lv30, base 40%×3/5t] · 매직 액셀레이션 52050 [P, Lv33] · 이그나이트 52060 [P, Lv35, OnAttack 50%, dmg via linked/projectile, Lv140 159.5%, CD2.5s] · 포이즌 브레스 52030 [A, Lv38, base 200%×3/6t, Lv140 9806.9%, CD18s] · 메디테이션 52040 [B, Lv40, CD30s] · 스펠 마스터리 52070 [P, Lv43] · MP 이터 52080 [P, Lv45, OnAttack 50%, CD0.5s] · 엘리멘탈 드레인 52020 [P, Lv50, OnHit 50%]
- 3차 (Lv60, 강화cap 120): 익스플로젼 53010 [BA, Lv60, base 80%×5/6t] · 엘리멘탈 어댑팅 53040 [P, Lv60, OnTimer] · 포이즌 미스트 53020 [A, Lv63, base 160%×3/10t, Lv140 2252.2%, CD35s] · 익스트림 매직 53050 [P, Lv66] · 포이즌 리젼 53030 [A, Lv69, dmg via linked/projectile, CD27s] · 엘리멘탈 리셋 53060 [P, Lv72, OnAttack 25%] · 매직 크리티컬 53070 [P, Lv74] · 엘리먼트 앰플리피케이션 53080 [P, Lv75]
- 4차 (Lv100, 강화cap 120): 플레임 스윕 54010 [BA, Lv100, base 290%×5/6t, Lv140 4518.2%] · 메이플 용사 54100 [P, Lv100] · 미스트 이럽션 54020 [P, Lv103, OnEnemyDie, CD4s] · 메테오 54030 [A, Lv105, base 600%×3/7t, Lv140 4333.5%, CD33s] · 플레임 헤이즈 54040 [A, Lv107, dmg via linked/projectile, Lv140 6064.5%, CD25s] · 인피니티 54050 [B, Lv110, CD30s] · 이프리트 54060 [A, Lv115, dmg via linked/projectile, Lv140 5617.5%, CD80s] · 마스터 매직 54070 [P, Lv117] · 아케인 에임 54080 [P, Lv120, OnAttack 25%] · 퍼번트 드레인 54090 [P, Lv125]
### 6. 비숍 — bishop / Hero.Bishop / Magical / EN "Bishop"
- 공통: 민첩한 몸놀림 9000 [B, 고정Lv1, CD60s]
- 1차 (Lv1, 강화cap 60): 에너지 볼트 61010 [BA, base 26%×2] · 마나 웨이브 61020 [P, 미션518, 고정Lv1] · 텔레포트 61040 [B, Lv10, 고정Lv1, CD10s] · 매직 가드 61030 [B, Lv15, CD30s]
- 2차 (Lv30, 강화cap 90): 홀리 애로우 62010 [BA, Lv30, base 40%×3/5t] · 매직 액셀레이션 62040 [P, Lv33] · 힐 62020 [B, Lv35, CD18s] · 인빈서블 62060 [P, Lv38] · 블레스 62030 [B, Lv40, CD24s] · 스펠 마스터리 62070 [P, Lv43] · MP이터 62080 [P, Lv45, OnAttack 50%, CD0.8s] · 하이 위즈덤 62050 [P, Lv50]
- 3차 (Lv60, 강화cap 120): 샤이닝 레이 63010 [BA, Lv60, base 80%×5/6t] · 디바인 프로텍션 63040 [P, Lv60, OnTimer] · 트라이엄프 페더 63050 [P, Lv63, OnAttack 15%, dmg via linked/projectile, Lv140 4512.7%, CD18s] · 홀리 파운틴 63020 [B, Lv66, CD30s] · 홀리 매직 쉘 63030 [B, Lv69, CD27s] · 홀리 심볼 63060 [P, Lv72, OnTimer] · 매직 크리티컬 63070 [P, Lv74] · 엘리먼트 앰플리피케이션 63080 [P, Lv75]
- 4차 (Lv100, 강화cap 120): 빅뱅 64010 [BA, Lv100, base 290%×5/6t, Lv140 4518.2%] · 메이플 용사 64100 [P, Lv100] · 엔젤레이 64020 [A, Lv103, base 680%×2, Lv140 3274.2%, CD17s] · 제네시스 64030 [A, Lv105, dmg via linked/projectile, Lv140 10111.5%, CD23s] · 어드밴스드 블레스 64040 [B, Lv107, CD26s] · 인피니티 64050 [B, Lv110, CD30s] · 바하뮤트 64060 [A, Lv115, dmg via linked/projectile, Lv140 8426.3%, CD80s] · 마스터 매직 64070 [P, Lv117] · 아케인 에임 64080 [P, Lv120, OnAttack 25%] · 홀리 블러드 64090 [P, Lv125]
### 7. 보우마스터 — bowMaster / Hero.BowMaster / Physical / EN "Bowmaster"
- 공통: 민첩한 몸놀림 9000 [B, 고정Lv1, CD60s]
- 1차 (Lv1, 강화cap 60): 애로우 블로우 71010 [BA, base 26%×2/3t] · 더블 점프 71020 [P, 미션518, 고정Lv1] · 아처 마스터리 71040 [P, Lv10] · 크리티컬 샷 71030 [P, Lv15]
- 2차 (Lv30, 강화cap 90): 바람의 시 72010 [BA, Lv30, base 40%×3/5t] · 보우 액셀레이션 72040 [P, Lv33] · 리트리트 샷 72020 [A, Lv35, base 250%×1, Lv140 4369.9%, CD19s] · 피지컬 트레이닝 72080 [P, Lv38] · 퀴버 카트리지 72030 [P, Lv40, OnTimer, base 50%×1, Lv140 557.7%] · 보우 마스터리 72060 [P, Lv43] · 소울 애로우 : 활 72050 [P, Lv45] · 파이널 어택 : 활 72070 [P, Lv50, OnAttack 25%, base 35%×1, Lv140 602.5%]
- 3차 (Lv60, 강화cap 120): 바람의 시 II 73010 [BA, Lv60, base 80%×5/6t] · 플레시 미라주 73020 [P, Lv60, OnAttack #MultByAttackSpeed(200), base 550%×1+550%×1/6t, Lv140 8491.7%, CD5s] · 애로우 플래터 73040 [A, Lv63, dmg via linked/projectile, Lv140 331.1%, CD40s] · 컨센트레이션 73070 [P, Lv66, OnActiveSkill] · 피닉스 73030 [A, Lv69, dmg via linked/projectile, Lv140 2988.2%, CD60s] · 모탈 블로우 73060 [P, Lv72, OnHit] · 마크맨쉽 73080 [P, Lv74] · 익스트림 아쳐리 : 활 73050 [P, Lv75]
- 4차 (Lv100, 강화cap 120): 언카운터블 애로우 74010 [BA, Lv100, base 290%×5/6t, Lv140 4518.2%] · 메이플 용사 74100 [P, Lv100] · 폭풍의 시 74020 [A, Lv103, base 800%×1/11t, Lv140 1926%, CD40s] · 어드밴스드 파이널 어택 74080 [P, Lv105] · 어드밴스드 퀴버 74050 [P, Lv107] · 플레시 미라주 II 74040 [P, Lv110] · 샤프 아이즈 74030 [B, Lv115, CD35s] · 일루전 스탭 74070 [P, Lv117, OnTimer] · 보우 엑스퍼트 74060 [P, Lv120] · 아머 피어싱 74090 [P, Lv125]
### 8. 신궁 — marksman / Hero.Marksman / Physical / EN "Marksman"
- 공통: 민첩한 몸놀림 9000 [B, 고정Lv1, CD60s]
- 1차 (Lv1, 강화cap 60): 애로우 블로우 81010 [BA, base 26%×2/3t] · 더블 점프 81020 [P, 미션518, 고정Lv1] · 아처 마스터리 81040 [P, Lv10] · 크리티컬 샷 81030 [P, Lv15]
- 2차 (Lv30, 강화cap 90): 피어싱 82010 [BA, Lv30, base 40%×3/5t] · 크로스보우 액셀레이션 82030 [P, Lv33] · 리트리트 샷 82020 [A, Lv35, base 250%×1, Lv140 4369.9%, CD19s] · 피지컬 트레이닝 82070 [P, Lv38] · 데미지 리버싱 82080 [P, Lv40, OnAttack 25%, CD10s] · 크로스보우 마스터리 82050 [P, Lv43] · 소울 애로우 : 석궁 82040 [P, Lv45] · 파이널 어택 : 석궁 82060 [P, Lv50, OnAttack 25%, base 35%×1, Lv140 602.5%]
- 3차 (Lv60, 강화cap 120): 피어싱 II 83010 [BA, Lv60, base 80%×5/6t] · 볼트 플로우 83040 [B, Lv60, CD10s] · 볼트 스위프트 83030 [A, Lv63, base 450%×3/10t, Lv140 8943.7%, CD21s] · 페인 킬러 83050 [B, Lv66, CD25s] · 프리져 83020 [A, Lv69, dmg via linked/projectile, Lv140 2241.1%, CD60s] · 모탈 블로우 83070 [P, Lv72, OnHit] · 마크맨쉽 83080 [P, Lv74] · 익스트림 아쳐리 : 석궁 83060 [P, Lv75]
- 4차 (Lv100, 강화cap 120): 인핸스 피어싱 84010 [BA, Lv100, base 290%×5/6t, Lv140 4518.2%] · 메이플 용사 84100 [P, Lv100] · 스나이핑 84020 [A, Lv103, base 3800%×1, Lv140 9148.5%, CD12s] · 어드밴스드 파이널 어택 84080 [P, Lv105] · 어디셔널 볼트 84050 [P, Lv107, OnAttack 15%, base 650%×2/3t, Lv140 4340.7%, CD0.1s] · 애로우 일루전 84040 [A, Lv110, dmg via linked/projectile, Lv140 2889%, CD45s] · 샤프 아이즈 84030 [B, Lv115, CD35s] · 일루전 스탭 84070 [P, Lv117, OnTimer] · 크로스보우 엑스퍼트 84060 [P, Lv120] · 라스트맨 스탠딩 84090 [P, Lv125]
### 9. 나이트로드 — nightLord / Hero.NightLord / Physical / EN "Night Lord"
- 공통: 민첩한 몸놀림 9000 [B, 고정Lv1, CD60s]
- 1차 (Lv1, 강화cap 60): 럭키 세븐 91010 [BA, base 26%×2/3t] · 플래시 점프 91040 [P, 미션518, 고정Lv1] · 헤이스트 91020 [P, Lv10] · 다크 사이트 91030 [B, Lv15, CD25s]
- 2차 (Lv30, 강화cap 90): 슈리켄 버스트 92010 [BA, Lv30, base 40%×3] · 자벨린 액셀레이션 92060 [P, Lv33] · 윈드 탈리스만 92020 [A, Lv35, base 400%×1/8t, Lv140 10594.4%, CD24s] · 피지컬 트레이닝 92080 [P, Lv38] · 자벨린 마스터리 92050 [P, Lv40] · 마크 오브 어쌔신 92040 [P, Lv43, OnTimer] · 크리티컬 스로우 92070 [P, Lv45] · 쉐도우 러쉬 92030 [B, Lv50, 고정Lv1, CD6s]
- 3차 (Lv60, 강화cap 120): 슈리켄 챌린지 93010 [BA, Lv60, base 80%×5/6t] · 쉐도우 파트너 93030 [P, Lv60, OnTimer] · 트리플 스로우 93020 [A, Lv63, base 360%×3, Lv140 3466.8%, CD13s] · 아드레날린 93080 [P, Lv66, OnActiveSkill] · 다크 플레어 93040 [A, Lv69, dmg via linked/projectile, Lv140 3258.6%, CD45s] · 래디컬 다크니스 93050 [P, Lv72] · 베놈 93060 [P, Lv74, OnAttack 50%] · 숙련된 표창술 93070 [P, Lv75]
- 4차 (Lv100, 강화cap 120): 쇼다운 챌린지 94010 [BA, Lv100, base 290%×5/6t, Lv140 4518.2%] · 메이플 용사 94100 [P, Lv100] · 쿼드러플 스로우 94020 [A, Lv103, base 1150%×4, Lv140 11074.2%, CD10s] · 써든레이드 94030 [A, Lv105, base 1400%×3/8t, Lv140 10111.5%, CD19s] · 마크 오브 나이트로드 94050 [P, Lv107] · 퍼지 에어리어 94040 [B, Lv110, CD45s] · 페이크 94070 [P, Lv115, OnDamage 20%, base 2500%×1, Lv140 3710%, CD12s] · 페이탈 베놈 94080 [P, Lv117, OnAttack 20%, base 600%×1, Lv140 1780.8%] · 자벨린 엑스퍼트 94090 [P, Lv120] · 다크 세레니티 94060 [P, Lv125]
### 10. 섀도어 — shadower / Hero.Shadower / Physical / EN "Shadower"
- 공통: 민첩한 몸놀림 9000 [B, 고정Lv1, CD60s]
- 1차 (Lv1, 강화cap 60): 더블 스탭 101010 [BA, base 26%×2/3t] · 플래시 점프 101040 [P, 미션518, 고정Lv1] · 헤이스트 101020 [P, Lv10] · 다크 사이트 101030 [B, Lv15, CD25s]
- 2차 (Lv30, 강화cap 90): 새비지 블로우 102010 [BA, Lv30, base 40%×3/5t] · 대거 액셀레이션 102040 [P, Lv33] · 스틸 102020 [P, Lv35, OnHit 10%] · 피지컬 트레이닝 102070 [P, Lv38] · 카르마 102050 [P, Lv40] · 대거 마스터리 102060 [P, Lv43] · 실드 마스터리 102080 [P, Lv45] · 크리티컬 엣지 102030 [P, Lv50]
- 3차 (Lv60, 강화cap 120): 엣지 카니발 103010 [BA, Lv60, base 80%×5/6t] · 쉐도우 파트너 103050 [P, Lv60, OnTimer] · 무스펠 하임 103020 [A, Lv63, base 450%×2/9t, Lv140 9890.1%, CD23s] · 메소 익스플로젼 103030 [A, Lv66, base 270%×3, Lv140 2599.8%, CD11s] · 다크 플레어 103040 [A, Lv69, dmg via linked/projectile, Lv140 3258.6%, CD45s] · 베놈 103060 [P, Lv72, OnAttack 50%] · 인투 다크니스 103070 [B, Lv74, CD40s] · 그리드 103080 [P, Lv75]
- 4차 (Lv100, 강화cap 120): 크루얼 스탭 104010 [BA, Lv100, base 290%×5/6t, Lv140 4518.2%] · 메이플 용사 104100 [P, Lv100] · 암살 104020 [A, Lv103, base 1400%×2, Lv140 13963.5%, CD13s] · 써든레이드 104030 [A, Lv105, base 1400%×3/8t, Lv140 10111.5%, CD19s] · 블러디 파킷 104050 [P, Lv107] · 연막탄 104040 [B, Lv110, CD45s] · 페이크 104070 [P, Lv115, OnDamage 20%, base 2500%×1, Lv140 3710%, CD12s] · 페이탈 베놈 104080 [P, Lv117, OnAttack 20%, base 600%×1, Lv140 1780.8%] · 대거 엑스퍼트 104090 [P, Lv120] · 섀도어 인스팅트 104060 [P, Lv125]
### 11. 바이퍼 — viper / Hero.Viper / Physical / EN "Buccaneer"
- 공통: 민첩한 몸놀림 9000 [B, 고정Lv1, CD60s]
- 1차 (Lv1, 강화cap 60): 써머솔트 킥 111010 [BA, base 26%×2/3t] · 파이렛 리프 111040 [P, 미션518, 고정Lv1] · 크리티컬 로어 111020 [P, Lv10] · 퀵모션 111030 [P, Lv15]
- 2차 (Lv30, 강화cap 90): 쇼크 웨이브 112010 [BA, Lv30, base 40%×3/5t] · 너클 액셀레이션 112040 [P, Lv33] · 씨 서펜트 버스트 112030 [P, Lv35, OnAttack, dmg via linked/projectile, Lv140 6785.2%, CD7s] · 피지컬 트레이닝 112070 [P, Lv38] · 멘탈 클리어리티 112050 [P, Lv40] · 너클 마스터리 112060 [P, Lv43] · 인듀어런스 112080 [P, Lv45, OnTimer] · 어드밴스드 대쉬 112020 [B, Lv50, 고정Lv1, CD6s]
- 3차 (Lv60, 강화cap 120): 터닝 킥 113010 [BA, Lv60, base 80%×5/6t] · 윌로우 디펜시브 113070 [P, Lv60] · 스크류 펀치 113020 [A, Lv63, base 340%×2/7t, Lv140 7473%, CD21s] · 서펜트 스톤 113030 [B, Lv66] · 서펜트 어썰트 113050 [P, Lv69] · 씨 서펜트 강화 I 113040 [P, Lv72] · 럭키 다이스 113060 [P, Lv74, OnTimer] · 그로기 마스터리 113080 [P, Lv75]
- 4차 (Lv100, 강화cap 120): 훅 봄버 114010 [BA, Lv100, base 290%×5/6t, Lv140 4518.2%] · 메이플 용사 114100 [P, Lv100] · 피스트 인레이지 114020 [A, Lv103, base 900%×3/4t+900%×2, Lv140 6500.3%, CD16s] · 전함 노틸러스 114030 [A, Lv105, base 1950%×5/15t, Lv140 23472.7%, CD33s] · 윈드 부스터 114050 [B, Lv107, CD35s] · 씨 서펜트 강화 II 114070 [P, Lv110] · 바이퍼지션 114040 [B, Lv115, CD28s] · 씨 서펜트 인레이지 114080 [P, Lv117, OnActiveSkill, base 1700%×2/8t, Lv140 10091.2%] · 서펜트 어썰트 인레이지 114090 [P, Lv120, OnAttack, dmg via linked/projectile, Lv140 5787.6%] · 타임 리프 114060 [B, Lv125, CD65s]
### 12. 캡틴 — captain / Hero.Captain / Physical / EN "Corsair"
- 공통: 민첩한 몸놀림 9000 [B, 고정Lv1, CD60s]
- 1차 (Lv1, 강화cap 60): 더블 파이어 121010 [BA, base 26%×2/3t] · 파이렛 리프 121040 [P, 미션518, 고정Lv1] · 크리티컬 로어 121020 [P, Lv10] · 퀵모션 121030 [P, Lv15]
- 2차 (Lv30, 강화cap 90): 매그넘 샷 122010 [BA, Lv30, base 40%×3/5t] · 스위프트 파이어 122020 [A, Lv33, base 180%×1/8t, Lv140 2596%, CD17s] · 서먼 크루 122030 [A, Lv35, dmg via linked/projectile, Lv140 3925.7%, CD35s] · 피지컬 트레이닝 122070 [P, Lv38] · 건 액셀레이션 122050 [P, Lv40] · 건 마스터리 122060 [P, Lv43] · 인피닛 불릿 122080 [P, Lv45] · 백스텝샷 122040 [A, Lv50, base 60%×1/1t, Lv140 87.3%, CD3s]
- 3차 (Lv60, 강화cap 120): 더블 배럴 샷 123010 [BA, Lv60, base 80%×5/6t] · 발키리 페이션트 123070 [P, Lv60] · 시즈 봄버 123030 [A, Lv63, dmg via linked/projectile, Lv140 1098.6%, CD22s] · 불릿 스매시 123020 [A, Lv66, base 170%×4/9t, Lv140 6226.4%, CD23s] · 어셈블 크루 123040 [P, Lv69] · 풀메탈 자켓 123050 [P, Lv72] · 럭키 다이스 123060 [P, Lv74, OnTimer] · 할로포인트 불릿 123080 [P, Lv75]
- 4차 (Lv100, 강화cap 120): 퍼실레이드 124010 [BA, Lv100, base 290%×5/6t+580%×5/6t, Lv140 4518.2%] · 메이플 용사 124100 [P, Lv100] · 헤드 샷 124020 [A, Lv103, base 2900%×2, Lv140 18618%, CD18s] · 전함 노틸러스 124030 [A, Lv105, base 1950%×5/15t, Lv140 23472.7%, CD33s] · 크루 커맨더십 124080 [P, Lv107] · 배틀쉽 봄버 124050 [A, Lv110, dmg via linked/projectile, Lv140 25198.5%, CD20s] · 파이렛 스타일 124060 [B, Lv115, CD42s] · 래피드 파이어 124040 [A, Lv117, base 1800%×1/9t, Lv140 4911.3%, CD17s] · 캡틴 디그니티 124090 [P, Lv120, OnAttack 25%, base 1800%×1/6t, Lv140 4006.8%, CD0.5s] · 퀵 드로우 124070 [P, Lv125]
### 13. 나이트워커 — nightWalker / Hero.NightWalker / Physical / EN "Night Walker"
- 공통: 엘리멘탈 하모니 9001 [B, 고정Lv1, CD60s]
- 1차 (Lv1, 강화cap 60): 럭키 세븐 131010 [BA, dmg via linked/projectile] · 쉐도우 점프 131020 [P, 미션518, 고정Lv1] · 엘리멘트 : 다크니스 131030 [B, Lv10, CD28s] · 쉐도우 배트 131040 [P, Lv15, OnAttack 20%, dmg via linked/projectile, Lv140 2154.3%, CD1s]
- 2차 (Lv30, 강화cap 90): 트리플 스로우 132010 [BA, Lv30, dmg via linked/projectile] · 스로잉 액셀레이션 132040 [P, Lv33] · 스타더스트 132020 [A, Lv35, base 220%×1/7t, Lv140 16585.7%, CD19s] · 피지컬 트레이닝 132080 [P, Lv38] · 배트 커뮤니온 132030 [P, Lv40] · 스로잉 마스터리 132060 [P, Lv43] · 크리티컬 스로우 132070 [P, Lv45] · 다크니스 어뎁팅 132050 [P, Lv50]
- 3차 (Lv60, 강화cap 120): 쿼드러플 스로우 133010 [BA, Lv60, dmg via linked/projectile] · 래디컬 다크니스 133080 [P, Lv60] · 쉐도우 서번트 133020 [A, Lv63, dmg via linked/projectile, CD30s] · 배트 커뮤니온 II 133050 [P, Lv66] · 다크니스 어센션 133030 [B, Lv69, CD36s] · 다크니스 어뎁팅 II 133060 [P, Lv72] · 쉐도우 모멘텀 133040 [P, Lv74, OnActiveSkill] · 스피릿 스로잉 133070 [P, Lv75]
- 4차 (Lv100, 강화cap 120): 퀸터플 스로우 134010 [BA, Lv100, dmg via linked/projectile, Lv140 4518.2%] · 시그너스 나이츠 134100 [P, Lv100] · 다크니스 오멘 134020 [A, Lv103, 고정Lv1, dmg via linked/projectile, Lv140 10771.6%, CD38s] · 쉐도우 스티치 134040 [A, Lv105, base 2850%×4/15t, Lv140 27445.2%, CD27s] · 배트 커뮤니온 III 134050 [P, Lv107] · 다크니스 어뎁팅 III 134060 [P, Lv110] · 다크니스 이베이젼 134030 [B, Lv115, CD40s] · 사이펀 바이탈리티 134080 [P, Lv117] · 스로잉 엑스퍼트 134070 [P, Lv120] · 다크니스 블레싱 134090 [P, Lv125]
### 14. 윈드브레이커 — windBreaker / Hero.WindBreaker / Physical / EN "Wind Archer"
- 공통: 엘리멘탈 하모니 9001 [B, 고정Lv1, CD60s]
- 1차 (Lv1, 강화cap 60): 브리즈 애로우 141010 [BA, base 26%×2/3t] · 거스트 쉬프트 141020 [P, 미션518, 고정Lv1] · 위스퍼 오브 더 윈드 141040 [P, Lv10] · 엘리멘트 : 스톰 141030 [B, Lv15, CD28s]
- 2차 (Lv30, 강화cap 90): 거스트 샷 142010 [BA, Lv30, base 40%×3/5t] · 보우 액셀레이션 142040 [P, Lv33] · 스파이럴 볼텍스 142020 [A, Lv35, base 250%×2/9t, Lv140 8739.7%, CD19s] · 피지컬 트레이닝 142080 [P, Lv38] · 트라이플링 윔 I 142050 [P, Lv40, OnActiveSkill, CD2s] · 보우 마스터리 142060 [P, Lv43] · 실프스 에이드 142070 [P, Lv45] · 윈드워크 142030 [B, Lv50, 고정Lv1, CD6s]
- 3차 (Lv60, 강화cap 120): 서리바람의 군무 143010 [BA, Lv60, base 80%×5/6t] · 닷지 143080 [P, Lv60] · 핀포인트 피어스 143020 [A, Lv63, base 330%×1+740%×1, Lv140 9798.9%, CD20s] · 트라이플링 윔 II 143040 [P, Lv66] · 에메랄드 플라워 143030 [B, Lv69, CD38s] · 세컨드 윈드 143070 [P, Lv72] · 페더리니스 143060 [P, Lv74] · 알바트로스 143050 [P, Lv75]
- 4차 (Lv100, 강화cap 120): 페어리 턴 144010 [BA, Lv100, base 290%×5/6t, Lv140 4518.2%] · 시그너스 나이츠 144100 [P, Lv100] · 천공의 노래 144020 [A, Lv103, base 780%×1/9t, Lv140 1877.9%, CD40s] · 트라이플링 윔 III 144050 [P, Lv105] · 에메랄드 더스트 144080 [P, Lv107] · 스톰 브링어 144040 [P, Lv110, OnActiveSkill 50%, CD25s] · 샤프 아이즈 144030 [B, Lv115, CD35s] · 윈드 블레싱 144060 [P, Lv117] · 보우 엑스퍼트 144070 [P, Lv120] · 알바트로스 맥시멈 144090 [P, Lv125]
### 15. 플레임위자드 — flameWizard / Hero.FlameWizard / Magical / EN "Blaze Wizard"
- 공통: 엘리멘탈 하모니 9001 [B, 고정Lv1, CD60s]
- 1차 (Lv1, 강화cap 60): 오비탈 플레임 151010 [BA, base 26%×2/3t] · 파이어워크 151030 [P, 미션518, 고정Lv1] · 불의 반발력 151040 [P, Lv10] · 엘리멘트 : 플레임 151020 [B, Lv15, CD28s]
- 2차 (Lv30, 강화cap 90): 오비탈 플레임 II 152010 [BA, Lv30, base 40%×3/5t] · 북 오브 파이어 152040 [P, Lv33] · 플레임 볼텍스 152020 [A, Lv35, base 260%×2/7t, Lv140 6696.1%, CD18s] · 번 앤 레스트 152050 [P, Lv38, OnAttack 50%, CD1s] · 엘리멘트 : 플레임 II 152060 [P, Lv40] · 주문 연마 152070 [P, Lv43] · 오비탈 익스플로젼 152080 [P, Lv45, OnTimer] · 파이어 블링크 152030 [B, Lv50, CD10s]
- 3차 (Lv60, 강화cap 120): 오비탈 플레임 III 153010 [BA, Lv60, base 80%×5/6t] · 스피릿 오브 플레임 153040 [B, Lv60, CD3s] · 플레임 템페스타 153020 [A, Lv63, base 300%×2/8t, Lv140 5985.4%, CD20s] · 번뜩이는 깨달음 153050 [P, Lv66] · 마엘스트롬 153030 [A, Lv69, base 270%×3/6t, Lv140 6050.4%, CD23s] · 약점 분석 153060 [P, Lv72] · 엘리멘트 : 플레임 III 153070 [P, Lv74] · 해방된 마력 153080 [P, Lv75]
- 4차 (Lv100, 강화cap 120): 오비탈 플레임 IV 154010 [BA, Lv100, base 290%×5/6t, Lv140 4518.2%] · 시그너스 나이츠 154100 [P, Lv100] · 블레이징 익스팅션 154020 [A, Lv103, dmg via linked/projectile, Lv140 2889%, CD32s] · 엘리멘트 : 플레임 IV 154030 [P, Lv105] · 본 피닉스 154060 [P, Lv107] · 인페르노라이즈 154070 [A, Lv110, dmg via linked/projectile, Lv140 16250.2%, CD21s] · 버닝 리젼 154040 [B, Lv115, CD40s] · 플레임 배리어 154080 [P, Lv117, OnState, CD30s] · 마법의 진리 154090 [P, Lv120] · 꺼지지 않는 화염 154050 [P, Lv125]
### 16. 소울마스터 — soulMaster / Hero.SoulMaster / Physical / EN "Dawn Warrior"
- 공통: 엘리멘탈 하모니 9001 [B, 고정Lv1, CD60s]
- 1차 (Lv1, 강화cap 60): 솔라 슬래시 161010 [BA, base 26%×2/3t] · 소울 리프 161030 [P, 미션518, 고정Lv1] · 소울 가디언 161040 [P, Lv10] · 엘리멘트 : 소울 161020 [B, Lv15, CD28s]
- 2차 (Lv30, 강화cap 90): 셀레스티얼 비전 162010 [BA, Lv30, base 40%×3/5t] · 님블 핑거 162040 [P, Lv33] · 코스믹 매터 162030 [A, Lv35, dmg via linked/projectile, Lv140 8507.5%, CD14s] · 피지컬 트레이닝 162050 [P, Lv38] · 소울 블레싱 162070 [P, Lv40] · 소드 마스터리 162060 [P, Lv43] · 솔루나 타임 162020 [B, Lv45, CD30s] · 이너 트러스트 162080 [P, Lv50]
- 3차 (Lv60, 강화cap 120): 셀레스티얼 비전 II 163010 [BA, Lv60, base 80%×5/6t] · 윌 오브 스틸 163050 [P, Lv60, OnTimer] · 라우드 러쉬 163030 [A, Lv63, base 300%×2/7t, Lv140 4482.3%, CD26s] · 트루 사이트 163040 [A, Lv66, base 780%×1, Lv140 2503.8%, CD27s] · 코스믹 샤워 163020 [A, Lv69, dmg via linked/projectile, Lv140 1855.1%, CD22s] · 솔루나 마스터리 163070 [P, Lv72] · 소울 블레싱 II 163060 [P, Lv74] · 이너 샤우트 163080 [P, Lv75]
- 4차 (Lv100, 강화cap 120): 셀레스티얼 비전 III 164010 [BA, Lv100, base 290%×5/6t, Lv140 4518.2%] · 시그너스 나이츠 164100 [P, Lv100] · 솔루나 슬래시 164030 [A, Lv103, base 2200%×2/7t, Lv140 10593%, CD11s] · 소울 페네트레이션 164040 [A, Lv105, base 1600%×3/14t+1300%×3, Lv140 15408%, CD24s] · 소울 플레지 164020 [P, Lv107] · 마스터 오브 더 소드 164050 [P, Lv110] · 코스믹 버스트 164070 [A, Lv115, base 1500%×4/12t, Lv140 14445%, CD19s] · 언포시어블 164080 [P, Lv117] · 소드 엑스퍼트 164090 [P, Lv120] · 소울 블레싱 III 164060 [P, Lv125]

## 10. Missing / unknown (not in the downloaded sources — do not invent)
- **Intermediate job names** (1차/2차/3차 class titles such as the per-tier job names) are absent: data only has the 16 final jobs with JobStep 1–4.
- **Pre-1차 basic attack**: `initialBaseAttackSkillIndex` 10000/10001/10002/10003 has no SkillTable record in skill-data.js.
- **Animation / cast timing semantics**: only `DurationTimeMs` (site: 시전 시간), skill `TickTimeMs` (meaning not stated), op `QueueDelayMs`/`DelayMs`/
  `DistanceDelayMs` and projectile ticks exist. Whether attack speed shortens active-skill casts is not stated (site applies it to basic attacks only).
- **Rotation / DPS**: auto-cast priority, MP economy, buff uptime and the combat timeline live in the server-side simulator (`/api/v4/*`), not downloaded.
- **Runtime expression semantics**: the 87 `#Macro` bodies are given (`expressionMacros`, readable formulas), but the primitives they call
  (`$CreatureStateCount`, `$CreatureFinalStat`, `$CreatureIsBoss`, `#if` …) are not defined in the sources; the engine evaluates only
  FlashSlash, CosmicShower, BowMaster_SoulArrow, EnhanceRagingBlow_Mastery and simple `$CreatureFinalStat(Defence|HpRatio)` forms.
  StateTable is reduced to `stateMaxStacks` (state durations come from the creating operation's `DurationMs`).
- **Engine snapshot caveats** (derived values only): static view; GetDotR excluded; ModSkillR edits of another passive's ModSkillStat value are not
  folded in (e.g. hero mastery 10235 +50 % on 14080 is not reflected in 12070's Lv140 coefficient); 53030 포이즌 리젼 and 133020 쉐도우 서번트 have no
  resolvable 1-target coefficient; servant clones (`CreateServantProjectile`) are not traversed; peak mode uses fixed stack maxima.
- 177 linked sub-skill records have no Korean name (site shows "<owner> 추가 발동/연계 효과"); JSON `referencedBy` links them to their owner.
- Hitbox JSON omits the 1차–3차 basic attacks (raw `RectAreaMm`/`MaxRangeMm` remain) and marks 16 stages `unresolved` (12 of them 다크나이트).
- Sources of `allSkill`/step bonuses (equipment options, etc.) are outside the skill data (see the items area).
- Undocumented raw fields kept verbatim: `LinkIndexByHeroJobChange`, `CanDisableSkillEffect`, damage flag (`"None"`, `"Dot"`), `IsTouchType`,
  `TargetSortType`, `Flag` values like `WatchCondition`, `RecalculateValueOnTick`.
- Skill-point allocation UI rules beyond `enhance` (startLevel 11, 3 pts/level, caps 60/90/120/120) are not included; the site assumes all points spent.
