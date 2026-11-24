# Items, grades & gacha/upgrade systems - extraction summary

Source: mapleidleindex.com mirror (PC client **1.18.0** tables) under `$W`. Machine-readable data: `items-gacha.json` (each section has a `source` with file + URL). Scripts: `scripts/items_01_extract.py` (build), `scripts/items_02_validate.py` (all checks PASS), `scripts/items_03_summary_md.py` (this file; helpers items_common.py, items_html_tables.py, items_kwic.py, items_kstrings.py). Korean names kept as found. Nothing estimated; gaps in section 13.

## 1. Grade ladders
- **Weapon / summon grades** (summon-levels.json): 1 노말(Normal), 2 레어(Rare), 3 에픽(Epic), 4 유니크(Unique), 5 레전드리(Legendary), 6 미스틱(Mystic), 7 에인션트(Ancient), 8 이터니티(Eternity); sub-qualities (tiers): 1 하급(T4), 2 중급(T3), 3 상급(T2), 4 최상급(T1). 29 weapon tiers = Grade1-7 x 4 tiers + 이터니티 하급.
- **Gear grades** (itemlibrary inline D): Grade1 노말 → Grade2 레어 → Grade3 에픽 → Grade4 유니크 → Grade5 레전더리 → Grade5_1 레전더리+ → Grade6 미스틱 → Grade6_1 미스틱+; tiers 1=하급, 2=중급, 3=상급, 4=최상급.
- **Potential (cube) grades**: Grade1 노말, Grade2 레어, Grade3 에픽, Grade4 유니크, Grade5 레전드리, Grade6 미스틱 (no + grades, no tiers).
- **Companion grades** (max level): 노말(Normal) Lv100, 레어(Rare) Lv50, 에픽(Epic) Lv30, 유니크(Unique) Lv10, 레전드리(Legendary) Lv18.
- **Ability option grades**: 노멀, 레어, 에픽, 유니크, 레전드리, 미스틱. **Artifacts**: Grade3 x4, Grade4 x9, Grade5 x23 (no grade names in data). **Enchant scrolls**: 레어, 에픽, 유니크, 레전드리, 레전드리+, 미스틱, 미스틱+.

## 2. Equipment (armor & accessories)
- 15 slots: Cap 투구, Clothes 상의, Pants 하의, Glove 장갑, Cape 망토, Shoulder 어깨, Belt 벨트, Shoes 신발, Ring 반지1, Ring2 반지2, Pendant 목걸이, EarAccessory 귀걸이, EyeAccessory 눈장식, BrowAccessory 얼굴장식, Pocket 포켓.
- 291 gear records: normal 256 (8 armor parts x 8 grades x 4 tiers - the "엘리트 몬스터 장비"), party-quest 16 (반지1/목걸이/얼굴장식/반지2), boss-raid 19 (자쿰 투구·눈장식, 혼테일 귀고리·목걸이, 핑크빈 눈장식·포켓).
- Main options (3 per item): Cap: Attack/Defence/MaxHp; Clothes: Attack/Defence/MaxHp; Pants: Attack/HitChance/MaxHp; Glove: Attack/HitChance/MaxHp; Cape: Attack/AvoidChance/MaxHp; Shoulder: Attack/AvoidChance/MaxHp; Belt: Attack/MaxHp/MaxMp; Shoes: Attack/MaxHp/MaxMp; Ring: Attack/MainStat/MaxHp; Ring2: Attack/MainStat/MaxHp; Pendant: Attack/MainStat/MaxHp; BrowAccessory: Attack/MainStat/MaxHp; EyeAccessory: Attack/MainStat/MaxHp; EarAccessory: Attack/MainStat/MaxHp; Pocket: Attack/HitChance/MaxHp.
- Sub-option pool: 14-17 types per slot (Attack, MaxHp, Defence, MaxMpR, Avoid, Hit, Crit%/CritDmg, Boss/Normal dmg, 1-4차 skill levels; slot-specific: Ring1 & 얼굴장식 Min/MaxDamageRatio, Ring1/Pendant/Eye/Brow/Pocket AttackPower, Ring2 SkillPower, Eye PiercePower, Ear BaseAttackPower). 8 raid items add 1 fixed sub (e.g. 카오스 자쿰의 투구 AllSkillLevel 15, 혼테일의 목걸이 MainStatR 80 = 8%).
- Value = `floor(min*levelFactor[itemLv][factorIdx]/1000) + floor((max-min)*step/steps)`; star force adds `floor(base*mult/1000)` (main vs sub multiplier). Normal gear item level 1-140 (UI); PQ/raid gear have drop-level ranges (e.g. PQ 1 쉬움 40-50 ... 로미오 카오스 120-130).
- Sub-line count (normal 8 parts, %, lines 0/1/2/3/4):

| 등급 | 품질 | 0 | 1 | 2 | 3 | 4 |
|---|---|---|---|---|---|---|
| 노말 · 레어 | 하급~최상급 | 100 | 0 | 0 | 0 | 0 |
| 에픽 | 하급 | 70 | 30 | 0 | 0 | 0 |
| 에픽 | 중급 | 65 | 35 | 0 | 0 | 0 |
| 에픽 | 상급 | 60 | 40 | 0 | 0 | 0 |
| 에픽 | 최상급 | 50 | 50 | 0 | 0 | 0 |
| 유니크 | 하급 | 30 | 50 | 20 | 0 | 0 |
| 유니크 | 중급 | 25 | 50 | 25 | 0 | 0 |
| 유니크 | 상급 | 20 | 50 | 30 | 0 | 0 |
| 유니크 | 최상급 | 25 | 40 | 35 | 0 | 0 |
| 레전더리 | 하급 | 20 | 30 | 35 | 15 | 0 |
| 레전더리 | 중급 | 25 | 20 | 35 | 20 | 0 |
| 레전더리 | 상급 | 20 | 20 | 35 | 25 | 0 |
| 레전더리 | 최상급 | 15 | 20 | 35 | 30 | 0 |
| 레전더리+ | 하급 | 0 | 20 | 35 | 35 | 10 |
| 레전더리+ | 중급 | 0 | 10 | 35 | 40 | 15 |
| 레전더리+ | 상급 | 0 | 0 | 35 | 45 | 20 |
| 레전더리+ | 최상급 | 0 | 0 | 35 | 40 | 25 |
| 미스틱 | 하급~최상급 | 0 | 0 | 35 | 40 | 25 |

- Raid gear (4-person/901 set) and PQ gear have their own line tables (PQ: 1줄 40/2줄 40/3줄 20, min 1 line). The inline per-code probs for raid gear differ from the static 4-person table -> both kept (`meta.checks`).
- **부옵션 변환** (1.18): cost per attempt = 변환석/메소, rising for 8 attempts then flat; e.g. 에픽 T1 30→150 stones, 미스틱+ T4 530→2650 stones (120,000→312,000 meso). First converted slot becomes locked target.
- Event ring (1주년): craft to 레전드리, 부가 옵션 1/2/3/4개 = 30/35/25/10%, max Lv100, 2 claims per account (event-only).

## 3. Weapon summon (무기 뽑기)
Cost per pull: 무기 소환권 x1 or 레드 다이아 x20. Summon EXP +1 per pull. Guarantees (pity, separate from base rates, reset when the item drops naturally): Lv18 -> grade 7 tier 4 every 312,500 pulls; Lv19 -> grade 8 tier 1 every 357,000 pulls.

| Lv | pulls to next | 노말 | 레어 | 에픽 | 유니크 | 레전드리 | 미스틱 | 에인션트 | 이터니티 | max draw |
|---|---|---|---|---|---|---|---|---|---|---|
| 1 | 100 | 92 | 8 | 0 | 0 | 0 | 0 | 0 | 0 | 1,000 |
| 2 | 250 | 88 | 12 | 0 | 0 | 0 | 0 | 0 | 0 | 1,000 |
| 3 | 500 | 84.2 | 15 | 0.8 | 0 | 0 | 0 | 0 | 0 | 1,000 |
| 4 | 800 | 80.6 | 17.6 | 1.8 | 0 | 0 | 0 | 0 | 0 | 1,000 |
| 5 | 1,300 | 77.35 | 20.15 | 2.3 | 0.2 | 0 | 0 | 0 | 0 | 1,000 |
| 6 | 1,800 | 74.1 | 22.7 | 2.6 | 0.6 | 0 | 0 | 0 | 0 | 1,000 |
| 7 | 2,400 | 70.27 | 25.7 | 3.1 | 0.9 | 0.03 | 0 | 0 | 0 | 1,500 |
| 8 | 3,200 | 66.42 | 28.7 | 3.6 | 1.2 | 0.08 | 0 | 0 | 0 | 1,500 |
| 9 | 4,100 | 62.54 | 31.7 | 4.1 | 1.5 | 0.16 | 0 | 0 | 0 | 1,500 |
| 10 | 5,400 | 58.66 | 34.7 | 4.6 | 1.8 | 0.24 | 0 | 0 | 0 | 2,000 |
| 11 | 7,000 | 54.77 | 37.7 | 5.1 | 2.1 | 0.32 | 0.01 | 0 | 0 | 2,000 |
| 12 | 9,300 | 50.92 | 40.7 | 5.6 | 2.4 | 0.36 | 0.02 | 0 | 0 | 2,000 |
| 13 | 12,100 | 47.05 | 43.7 | 6.1 | 2.7 | 0.4 | 0.05 | 0 | 0 | 3,000 |
| 14 | 15,600 | 43.23 | 46.7 | 6.6 | 3 | 0.4 | 0.07 | 0 | 0 | 3,000 |
| 15 | 31,200 | 39.387 | 49.7 | 7.1 | 3.3 | 0.4 | 0.11 | 0.003 | 0 | 3,000 |
| 16 | 46,800 | 39.342 | 49.7 | 7.1 | 3.3 | 0.4 | 0.15 | 0.008 | 0 | 5,000 |
| 17 | 70,200 | 39.297 | 49.7 | 7.1 | 3.3 | 0.4 | 0.19 | 0.013 | 0 | 5,000 |
| 18 | 137,500 | 39.264 | 49.7 | 7.1 | 3.3 | 0.4 | 0.22 | 0.016 | 0 | 5,000 |
| 19 | - | 38.7743 | 49.503 | 7.5 | 3.5 | 0.45 | 0.25 | 0.022 | 0.0007 | 5,000 |

Per grade x tier % are in `weaponSummon.ratesPercentByLevel[].gradeTierPercent`. Cosmetic 단풍 colour odds in `mapleLeafEffect`.

## 4. Weapons: equip / owned effects and enhancement
All 16 jobs share stats. Max enhance Lv100, awakening (각성) 1-5 raises cap +20 each to 200 (no extra multiplier; material counts unknown). Cost item 무기 강화석. Accuracy/attack speed are flat per tier.

| weapon | equip ATK% L1 / L200 | owned ATK% L1 / L200 | acc | AS% | stones L1→200 |
|---|---|---|---|---|---|
| 노말 하급 | 15 / 32 | 4.3 / 9.1 | 0 | 0 | 13,819 |
| 노말 중급 | 18 / 38.4 | 5.1 / 10.8 | 0 | 0 | 16,574 |
| 노말 상급 | 21 / 44.8 | 6 / 12.8 | 0 | 0 | 19,859 |
| 노말 최상급 | 25 / 53.4 | 7.1 / 15.1 | 0 | 0 | 23,813 |
| 레어 하급 | 31.3 / 66.8 | 8.9 / 19 | 2 | 0 | 54,986 |
| 레어 중급 | 39.1 / 83.5 | 11.2 / 23.9 | 2 | 0 | 65,969 |
| 레어 상급 | 48.9 / 104.4 | 14 / 29.9 | 3 | 0 | 79,139 |
| 레어 최상급 | 61.1 / 130.5 | 17.5 / 37.3 | 3 | 0 | 94,947 |
| 에픽 하급 | 76.4 / 163.2 | 21.8 / 46.5 | 4 | 2 | 192,211 |
| 에픽 중급 | 95.5 / 204 | 27.3 / 58.3 | 5 | 2 | 230,638 |
| 에픽 상급 | 119.4 / 255.1 | 34.1 / 72.8 | 6 | 2 | 276,746 |
| 에픽 최상급 | 149.3 / 319 | 42.7 / 91.2 | 7 | 2 | 332,075 |
| 유니크 하급 | 194.1 / 414.7 | 55.5 / 118.6 | 9 | 3 | 672,492 |
| 유니크 중급 | 252.3 / 539.1 | 72.1 / 154 | 11 | 3 | 806,978 |
| 유니크 상급 | 328 / 700.9 | 93.7 / 200.2 | 13 | 3 | 968,362 |
| 유니크 최상급 | 426.4 / 911.2 | 121.8 / 260.2 | 15 | 3 | 1,162,001 |
| 레전드리 하급 | 554.3 / 1,184.5 | 138.6 / 296.1 | 17 | 4 | 2,017,291 |
| 레전드리 중급 | 720.6 / 1,539.9 | 180.2 / 385 | 19 | 4 | 2,420,736 |
| 레전드리 상급 | 936.8 / 2,001.9 | 234.2 / 500.4 | 21 | 4 | 2,904,862 |
| 레전드리 최상급 | 1,217.8 / 2,602.4 | 304.5 / 650.7 | 23 | 4 | 3,485,814 |
| 미스틱 하급 | 1,619.7 / 3,461.2 | 404.9 / 865.2 | 25 | 6 | 8,068,887 |
| 미스틱 중급 | 2,154.2 / 4,603.5 | 538.6 / 1,150.9 | 27 | 6 | 9,682,643 |
| 미스틱 상급 | 2,865.1 / 6,122.7 | 716.3 / 1,530.7 | 30 | 6 | 11,619,155 |
| 미스틱 최상급 | 3,810.6 / 8,143.2 | 952.7 / 2,035.9 | 33 | 6 | 13,942,976 |
| 에인션트 하급 | 5,144.3 / 10,993.3 | 1,286.1 / 2,748.3 | 40 | 8 | 32,275,254 |
| 에인션트 중급 | 6,944.8 / 14,841 | 1,736.2 / 3,710.2 | 45 | 8 | 94,910,073 |
| 에인션트 상급 | 9,375.5 / 20,035.4 | 2,343.9 / 5,008.9 | 50 | 8 | 162,702,904 |
| 에인션트 최상급 | 12,656.9 / 27,047.7 | 3,164.2 / 6,761.8 | 55 | 8 | 230,498,580 |
| 이터니티 하급 | 17,086.8 / 36,514.4 | 4,271.7 / 9,128.6 | 60 | 10 | 338,967,029 |

## 5. Companion summon (동료 뽑기) and companions
Cost per pull: 동료 소환권 x1 or 레드 다이아 x50; batches [1, 10]. Pools: 노말 5종, 레어 16종, 에픽 16종, 유니크 16종, 레전드리 16종 (노말 = 5 지망생; 레어/에픽/유니크/레전드리 = 16 jobs 1/2/3/4차). Each companion = grade% / pool size. Pity: Lv13 -> grade 5 (레전드리) at 6,250 pulls (pickup pulls not counted; resets on natural legendary).

| Lv | pulls to next | 노말 | 레어 | 에픽 | 유니크 | 레전드리 |
|---|---|---|---|---|---|---|
| 1 | 100 | 97 | 3 | 0 | 0 | 0 |
| 2 | 300 | 95 | 5 | 0 | 0 | 0 |
| 3 | 700 | 92 | 7 | 1 | 0 | 0 |
| 4 | 1,300 | 88 | 10 | 2 | 0 | 0 |
| 5 | 2,200 | 84.9 | 13 | 2.09 | 0.01 | 0 |
| 6 | 2,700 | 81.86 | 16 | 2.1 | 0.04 | 0 |
| 7 | 3,400 | 78.72 | 19 | 2.2 | 0.08 | 0 |
| 8 | 4,100 | 78.05 | 19.5 | 2.3 | 0.15 | 0 |
| 9 | 6,000 | 77.425 | 20 | 2.4 | 0.17 | 0.005 |
| 10 | 7,100 | 76.8 | 20.5 | 2.5 | 0.19 | 0.01 |
| 11 | 8,300 | 76.27 | 21 | 2.5 | 0.21 | 0.02 |
| 12 | 9,600 | 75.74 | 21.5 | 2.5 | 0.23 | 0.03 |
| 13 | - | 75.21 | 22 | 2.5 | 0.25 | 0.04 |

- Pickup banner (time-limited): legendary result split 30% / 30% for the 2 new (플레임위자드, 소울마스터) and 40% across 14 others; pickup passes (30/50/50 steps, 6,500/20,000/35,000 pulls).
- Effects per level (display units, `companions.companions[]`), representative (hero line):
  - 전사 지망생 (Lv1→100): equip Attack 60→654 | owned Attack 25→1,703; MaxHp 250→17,034
  - 히어로(1차) (Lv1→50): equip Attack 200→1,180 | owned Attack 50→951; MaxHp 500→9,515
  - 히어로(2차) (Lv1→30): equip MaxDamageRatio 5→19.5 | owned MainStat 70→601; MaxHp 1,750→15,032
  - 히어로(3차) (Lv1→10): equip MaxDamageRatio 10→20 | owned AttackPower 5→14; MaxHpR 10→28.1
  - 히어로(4차) (Lv1→18): equip MaxDamageRatio 20→54 | owned AttackPower 10→48.4; MaxHpR 15→72.6
  - Epic+ equip stat depends on job (MaxDamageRatio, BaseAttackPower, HitChance, NormalDmg, Crit%, SkillPower, AttackSpeed, CC dmg, Boss dmg, MinDamageRatio, MainStat%, CritDmg); owned effects identical within a grade.

## 6. Potential / cubes (미라클 큐브 = 잠재, 에디셔널 큐브 = 에디셔널)
3 lines, each rolled from its own pool (line 1 = current-grade values only; lines 2-3 mix current-grade values with the previous grade line-1 values). Same option tables for both cubes. 1 cube + meso per roll; grade-up with pity (천장):

| grade | up % | pity (miracle) | meso (miracle) | pity (additional) | meso (additional) |
|---|---|---|---|---|---|
| Grade1 노말 | 6 | 33 | 7,000 | 42 | 10,000 |
| Grade2 레어 | 3.333 | 60 | 9,800 | 75 | 14,000 |
| Grade3 에픽 | 1.67 | 120 | 13,700 | 150 | 19,600 |
| Grade4 유니크 | 0.6 | 333 | 19,200 | 417 | 27,400 |
| Grade5 레전드리 | 0.21 | 714 | 26,900 | 714 | 38,400 |
| Grade6 미스틱 | 0 | 0 | 37,700 | 0 | 53,800 |

Option pools: 15 parts x 6 grades x 3 lines in `potential.optionPools` ([type, raw value, prob/1e6, id]); labels in `optionLabels`; Percent types raw/10.

## 7. Star Force (0→30)
Cost = 스타포스 강화 주문서 + 메소. Pity: fail +1 / down +2 / destroy +4 points, guaranteed success at `maxEnhancePoint`; chance time after 2 consecutive downs. Destroy → 12★, restore cost below. Protections: 하락 방지 (down→fail, +cost), 파괴 완화 (destroy halved from 20★, +cost). Amplification per star: main/sub option +x/1000 of base, plus FinalDamage from 20★.

| ★→ | success % | fail % | down % | destroy % | scroll | meso | max pts | amp main/sub (‰) | bonus |
|---|---|---|---|---|---|---|---|---|---|
| 0→1 | 100 | 0 | 0 | 0 | 1 | 20,000 | 0 | 100/0 |  |
| 1→2 | 100 | 0 | 0 | 0 | 1 | 30,000 | 0 | 200/0 |  |
| 2→3 | 90 | 10 | 0 | 0 | 2 | 40,000 | 0 | 300/0 |  |
| 3→4 | 85 | 15 | 0 | 0 | 3 | 50,000 | 0 | 400/0 |  |
| 4→5 | 80 | 20 | 0 | 0 | 4 | 60,000 | 0 | 600/100 |  |
| 5→6 | 70 | 30 | 0 | 0 | 5 | 70,000 | 0 | 750/100 |  |
| 6→7 | 65 | 35 | 0 | 0 | 6 | 90,000 | 0 | 900/100 |  |
| 7→8 | 60 | 40 | 0 | 0 | 7 | 110,000 | 0 | 1050/100 |  |
| 8→9 | 55 | 45 | 0 | 0 | 8 | 130,000 | 0 | 1200/100 |  |
| 9→10 | 50 | 50 | 0 | 0 | 9 | 150,000 | 0 | 1500/250 |  |
| 10→11 | 35 | 65 | 0 | 0 | 10 | 170,000 | 0 | 1750/250 |  |
| 11→12 | 34 | 66 | 0 | 0 | 11 | 190,000 | 0 | 2000/250 |  |
| 12→13 | 33 | 67 | 0 | 0 | 12 | 210,000 | 8 | 2250/250 |  |
| 13→14 | 32.5 | 67.5 | 0 | 0 | 18 | 325,000 | 8 | 2500/250 |  |
| 14→15 | 31.5 | 68.5 | 0 | 0 | 21 | 370,000 | 8 | 3000/500 |  |
| 15→16 | 31 | 69 | 0 | 0 | 18 | 320,000 | 9 | 3500/600 |  |
| 16→17 | 29 | 71 | 0 | 0 | 28 | 520,000 | 9 | 4000/700 |  |
| 17→18 | 26 | 74 | 0 | 0 | 37 | 700,000 | 10 | 4500/800 |  |
| 18→19 | 23 | 77 | 0 | 0 | 38 | 770,000 | 11 | 5000/900 |  |
| 19→20 | 21 | 79 | 0 | 0 | 42 | 850,000 | 12 | 6000/1000 | FinalDamage 0.2% |
| 20→21 | 12.8 | 76.2 | 0 | 11 | 21 | 420,000 | 20 | 7000/1100 | FinalDamage 0.4% |
| 21→22 | 11.5 | 70.5 | 8 | 10 | 38 | 750,000 | 22 | 9000/1300 | FinalDamage 0.7% |
| 22→23 | 11.3 | 77.7 | 4 | 7 | 40 | 790,000 | 23 | 10500/1450 | FinalDamage 1% |
| 23→24 | 9 | 82 | 4 | 5 | 44 | 820,000 | 28 | 12000/1600 | FinalDamage 1.4% |
| 24→25 | 7.5 | 81 | 4 | 7.5 | 50 | 950,000 | 34 | 13500/1800 | FinalDamage 2% |
| 25→26 | 7 | 81.5 | 4 | 7.5 | 54 | 1,000,000 | 36 | 15000/2000 | FinalDamage 2.8% |
| 26→27 | 4.5 | 85 | 3 | 7.5 | 68 | 1,300,000 | 56 | 17500/2250 | FinalDamage 4% |
| 27→28 | 4 | 86.5 | 3 | 6.5 | 71 | 1,400,000 | 63 | 20000/2500 | FinalDamage 6% |
| 28→29 | 2 | 92 | 4 | 2 | 75 | 1,750,000 | 125 | 22500/2750 | FinalDamage 10% |
| 29→30 | 2 | 92 | 4 | 2 | 80 | 1,800,000 | 125 | 25000/3000 | FinalDamage 15% |

Destroy restore (to ★): 12★ 5,000 레드다이아 + 1,000,000 메소 + 0 주문서; 16★ 5,000 레드다이아 + 4,960,000 메소 + 220 주문서; 20★ 5,000 레드다이아 + 18,810,000 메소 + 932 주문서 (all 9 rows in JSON). Each protection (하락 방지 / 파괴 완화) costs the base scroll+meso of that attempt again (rows 20-29); with 하락 방지 the down chance becomes 0% (2% at 28-29★).

## 8. Scrolls (주문서 강화) and enchant (마법 부여)
- 31 equipment scrolls (level scrolls 35-115 bought with 주문의 흔적 150-1,800/try + meso; 노말/레어/에픽 강화 주문서 from 강화 던전; 자쿰/혼테일/핑크빈 주문서 from raids; event 브루스/알쏭달쏭/확신; 이노센트 = reset for 50 흔적). Slot rules: slot 5 +10%p, slot 10 +20%p; 알쏭달쏭 slot 1 only (30%, ATK +1,000~5,000 at 25/30/20/15/10%), 확신 slot 10 only (100%).
- 강화 던전 drop: 10% per clear/sweep, then grade split by stage band (e.g. 1-29: 노말 10%; 150: 노말 1%, 레어 2.5% each, 에픽 ≈1.3333% each).
- Raid scrolls: 하급 쉬움 4% / 보통+ 3%, 중급 보통+ 1%; guild raid cumulative-damage rewards give 하급 x3 (10/40/80%) and 중급 x2 (50/90%).
- 마법 부여 (unlock 14-10): 127 scrolls replace the slot enchant; success 50% (레어-미스틱) or 100% (레전드리+/미스틱+), meso 20,000-150,000/try. Pouch grade odds 레어/에픽/유니크/레전더리/미스틱: 하급 87/10/3/0/0, 중급 78/15/5/2/0, 상급 65.5/20/10/4/0.5, 최상급 64/20/10/5/1.

## 9. 용사의 힘 (Hero Power) and 어빌리티 (Ability)
- Hero Power: 9 stages; each stage has 3-6 stat slots (Attack, MaxHp, Defence, MainStat, AttackPower%, Hit) with per-level cost in 용사의 증표; stage up when all maxed + base wait (S2 300s, S3 7,200s, S4 43,200s, S5 86,400s, S6 259,200s, S7 388,800s, S8 583,200s, S9 641,520s). Cumulative tokens to finish stage 9: 3,477,408. Stage bonus up to MainStat 2,000 / MaxHp 80%.
- Ability: 8 slots (unlocked at Hero Power stage 2-9). Conversion rolls all unlocked lines; cost in 명예의 훈장 grows with locked lines (Lv1: 20/30/40/50/60/70/80/90; Lv20: 99/149/198/248/297/347/396/446). 1 medal spent = 1 ability EXP; levels 1-20. Option = grade weight / #options in grade (노멀 6, 레어 8, 에픽 12, 유니크 14, 레전드리 19, 미스틱 19); identical re-roll rule.

| Ab Lv | EXP to next | 노멀 | 레어 | 에픽 | 유니크 | 레전드리 | 미스틱 (per 10000) |
|---|---|---|---|---|---|---|---|
| 1 | 5,000 | 6000 | 3500 | 470 | 30 | 0 | 0 |
| 3 | 18,000 | 5000 | 3500 | 1350 | 150 | 0 | 0 |
| 5 | 35,300 | 3000 | 3200 | 3430 | 350 | 20 | 0 |
| 7 | 69,200 | 2500 | 3200 | 3850 | 370 | 80 | 0 |
| 9 | 135,700 | 2500 | 3200 | 3828 | 360 | 109 | 3 |
| 11 | 229,300 | 2500 | 3200 | 3817 | 350 | 127 | 6 |
| 13 | 387,500 | 2500 | 3200 | 3805 | 340 | 145 | 10 |
| 15 | 604,600 | 2500 | 3200 | 3793 | 330 | 163 | 14 |
| 17 | 870,600 | 2500 | 3200 | 3781 | 320 | 181 | 18 |
| 19 | 1,253,600 | 2500 | 3200 | 3769 | 310 | 199 | 22 |
| 20 | 1,504,300 | 2500 | 3200 | 3763 | 305 | 208 | 24 |

## 10. 여정의 보물, artifacts
- Journey Treasure: hidden internal level 1-1000, EXP per reward from 3,456,000 (Lv1) to 742,199,800,791,750,000,000 (Lv1000); treasure EXP = monster base EXP x kills x 0.0000001; gauge stores up to 200% (2 rewards); offline 0.9 kills/s, premium x1.7; weekly acceleration (ad 1x, premium +1x) adds 20/25/30% of a level at 60/30/10%. Reward contents NOT published.
- Artifacts (유물): 36 items, up to 4 equipped, awakening 0-5 changes the equip skill (e.g. 죽은자의 부적 Attack +100→+200‰ for 5s every 10s; 성배 FinalDamage 150→300 on kill). Raw skill operations in `artifacts.artifacts[].equipSkillsByAwakening`. Chest rates/costs/potentials not published.

## 11. Drop tables
- Boss raid equipment (% / 버닝UP %), boss.html:
  - 자쿰: 쉬움 자쿰의 투구 유니크 상급(~80) 9/18; 쉬움 아쿠아틱 레터 눈장식 유니크 상급(~80) 15/30; 쉬움 자쿰의 투구 유니크 최상급(~95) 1/2; 보통 자쿰의 투구 유니크 최상급(~95) 9/18; 보통 아쿠아틱 레터 눈장식 유니크 최상급(~95) 15/30; 보통 자쿰의 투구 레전더리 하급(~110) 1/2; 어려움 자쿰의 투구 레전더리 하급(~110) 9/18; 어려움 아쿠아틱 레터 눈장식 레전더리 하급(~110) 15/30; 어려움 카오스 자쿰의 투구 레전더리 최상급(~110) 1/2; 카오스 카오스 자쿰의 투구 레전더리 최상급(~110) 5/10; 카오스 아쿠아틱 레터 눈장식 레전더리 중급(~110) 20/40
  - 혼테일: 쉬움 데아 시두스 이어링 레전더리 중급(~105) 23/46; 쉬움 데아 시두스 이어링 레전더리 상급(~115) 2/4; 보통 데아 시두스 이어링 레전더리 상급(~115) 23/46; 보통 데아 시두스 이어링 레전더리 최상급(~125) 2/4; 어려움 혼테일의 목걸이 레전더리+ 하급(~125) 9/18; 어려움 데아 시두스 이어링 레전더리 최상급(~125) 15/30; 어려움 카오스 혼테일의 목걸이 레전더리+ 중급(~125) 1/2; 카오스 카오스 혼테일의 목걸이 레전더리+ 중급(~125) 5/10; 카오스 데아 시두스 이어링 레전더리+ 하급(125) 20/40
  - 핑크빈: 쉬움 핑크빛 성배 레전더리 상급(~110) 23/46; 쉬움 핑크빛 성배 레전더리+ 하급(~120) 2/4; 보통 핑크빛 성배 레전더리+ 하급(~120) 23/46; 보통 핑크빛 성배 레전더리+ 중급(~130) 2/4; 어려움 핑크빛 성배 레전더리+ 중급(~130) 15/30; 어려움 블랙빈 마크 레전더리+ 상급(~130) 9/18; 어려움 카오스 핑크빈 마크 레전더리+ 최상급(~130) 1/2
- Party quests (첫 번째 동행→반지1, 차원의 균열→목걸이, 여신의 흔적→얼굴장식, 로미오와 줄리엣→반지2): drop 쉬움 25%/35%, 보통 20%/30%, 어려움 20%/30%, 카오스 20%/30% (normal/버닝UP).
- Scroll drops: see section 8. Elite monster, stage and growth-dungeon drop tables are not published.

## 12. Currencies & materials (status vs. payment)
Status legend: PAID_ONLY = cash currency/cash item; ONLY_PAID_SOURCES = data lists only shop/hot-deal/red-diamond-shop sources (we must invent a free source); EVENT_OR_PAID; HAS_FREE_SOURCE (cited); FREE_SOURCE_IMPLIED. 250 hot deals (KRW 141, 블루 다이아 108, 레드 다이아 1) + 76 shop rows.

| item | used for | free source in data | status |
|---|---|---|---|
| 블루 다이아 | shop packages / hot deals priced in blueDiamond (shopPaid) | - | PAID_ONLY |
| 레드 다이아 | 무기 소환 1회 = 레드 다이아 20 (summon-levels.json costs) | - | ONLY_PAID_SOURCES_DOCUMENTED |
| 메소 | 스타포스 시도 비용 (starforce.rows.meso) | 어빌리티 옵션 "메소 획득량" exists (hero-ability-information-117.json options) - implies me | FREE_SOURCE_IMPLIED |
| 무기 소환권 | 무기 소환 1회 = 1장 (summon-levels.json costs) | 무기 소환 패스7 free track: 2,750 tickets over 100 steps by cumulative weapon summons  | HAS_FREE_SOURCE |
| 동료 소환권 | 동료 소환 1회 = 1장 (companion-summon-rewards.json costs) | red-diamond shop: 동료 소환권 30개 = 레드 다이아 750 (weekly 1) | ONLY_PAID_SOURCES_DOCUMENTED |
| 3차 전직 동료 소환권 | companion summon (3rd-job/epic pool) - only name evidence | - | ONLY_PAID_SOURCES_DOCUMENTED |
| 4차 전직 동료 소환권 | companion summon (4th-job/legendary pool) - only name evidence | - | ONLY_PAID_SOURCES_DOCUMENTED |
| 미스터리 동료 소환권 상자 | contents not published | - | ONLY_PAID_SOURCES_DOCUMENTED |
| 미스터리 무기 소환권 상자 | contents not published | - | ONLY_PAID_SOURCES_DOCUMENTED |
| 무기 강화석 | 무기 강화 Lv.1->200 (weapons.tiers[].perLevel_1to200.enhanceStoneCostToReach) | - | ONLY_PAID_SOURCES_DOCUMENTED |
| 미라클 큐브 | 잠재능력 재설정 1회 = 큐브 1 + 메소 (potential.gradeUp.miracle) | red-diamond shop: 미라클 큐브 1개 = 레드 다이아 1,000 (weekly 5) | ONLY_PAID_SOURCES_DOCUMENTED |
| 에디셔널 큐브 | 에디셔널 잠재능력 재설정 1회 = 큐브 1 + 메소 (potential.gradeUp.additional) | red-diamond shop: 에디셔널 큐브 1개 = 레드 다이아 1,500 (weekly 3) | ONLY_PAID_SOURCES_DOCUMENTED |
| 스타포스 강화 주문서 | 스타포스 시도 비용 + 보호 비용 + 파괴 복구 (starforce.rows.scroll / destroyRestore.scroll) | red-diamond shop: 5개 = 레드 다이아 1,500 (weekly 3) | ONLY_PAID_SOURCES_DOCUMENTED |
| 메모리얼 스크롤 | UNKNOWN - function not described (packages gated by 장비 최대 스타포스 3 이상) | - | ONLY_PAID_SOURCES_DOCUMENTED |
| 주문의 흔적 | 주문서 강화 화면: 레벨 주문서 1회 시도 150~1,800개 + 메소; 이노센트 주문서 초기화 50개 (scroll.html) | red-diamond shop: 1,000개 = 레드 다이아 1,000 (weekly 1) | ONLY_PAID_SOURCES_DOCUMENTED |
| 장비 강화 주문서 (노말/레어/에픽 강화 주문서, 자쿰·혼테일·핑크빈의 주문서) | 장비 주문서 강화 (scrolls.equipmentScrolls31) | 강화 던전 1~150단계 clear/sweep drop: 10% total (scrolls.enhanceDungeonDropPercent) | HAS_FREE_SOURCE |
| 알쏭달쏭 주문서 | 주문서 강화 1번 슬롯 전용 | past event exchanges (도깨비 교환소) - event only | EVENT_OR_PAID_ONLY |
| 확신의 주문서 | 주문서 강화 10번 슬롯 전용 | past events (도깨비 교환소, 돌아온 브루스 150회) | EVENT_OR_PAID_ONLY |
| 브루스의 주문서(하급/중급/상급) | 주문서 강화 | 돌아온 브루스 event missions (event only); 상급 = 과거 이벤트 | EVENT_OR_PAID_ONLY |
| 명예의 훈장 | 어빌리티 변환: 1회 비용 = medalsPerConversionByLockedLines; 소모 1개 = 어빌리티 경험치 1 (ability) | red-diamond shop: 1,000개 = 레드 다이아 1,500 (weekly 5) | ONLY_PAID_SOURCES_DOCUMENTED |
| 용사의 증표 | 용사의 힘 능력치 레벨업 비용 (heroPower.stages[].slots[].levels cost) | - | ONLY_PAID_SOURCES_DOCUMENTED |
| 성장던전 입장권: 용사의 힘 | 용사의 힘 growth dungeon entry (name evidence) | - | ONLY_PAID_SOURCES_DOCUMENTED |
| 시간 단축 티켓(1분) | 용사의 힘 단계 승급 대기시간 단축 (hero-ability-ui.mjs mentions 시간 단축 티켓) | - | ONLY_PAID_SOURCES_DOCUMENTED |
| 유물상자 | 유물 획득 (rates not published) | red-diamond shop: 1개 = 레드 다이아 1,500 (weekly 5) | ONLY_PAID_SOURCES_DOCUMENTED |
| 픽업 유물상자 | 유물 획득 (pickup; rates not published) | - | ONLY_PAID_SOURCES_DOCUMENTED |
| 레전드리 유물 소환 | 레전드리 유물 획득 | - | ONLY_PAID_SOURCES_DOCUMENTED |
| 유물 강화석 | 유물 강화 (costs not published) | red-diamond shop: 유물 성장 지원 (7,500 red) contains 15,000 | ONLY_PAID_SOURCES_DOCUMENTED |
| 엘리트 몬스터 소환 포인트 | 엘리트 몬스터 소환 -> 엘리트(일반 8부위) 장비 획득 (itemlibrary guide; rates not published) | - | ONLY_PAID_SOURCES_DOCUMENTED |
| 빠른 사냥 티켓 | 빠른 사냥 (instant hunting rewards); itemlibrary guide pairs it with elite farming | - | ONLY_PAID_SOURCES_DOCUMENTED |
| 경험치 부스터(100%) | EXP buff | - | ONLY_PAID_SOURCES_DOCUMENTED |
| 보스 레이드 입장권 | 보스 레이드 보상 수령 ("보상권을 사용하여 보상을 받는 클리어", scroll.html) | - | ONLY_PAID_SOURCES_DOCUMENTED |
| 탐험 티켓 | party-quest related (sold in 파티 퀘스트 핫딜); exact use not described | 일간 / 주간 충전 (deal description: "일간 / 주간 충전 시 최대 보유량을 넘는 수량을 획득할 수 없습니다") | HAS_FREE_SOURCE |
| 몬스터파크 익스트림 입장권 | 보상 수령 시 1장 | 매주 월요일 00:00 2장 충전 (자동 충전 상한 2장), 최초 지급 2장 (droptable.html) | HAS_FREE_SOURCE |
| 여정의 상자 열쇠 | journey chest (not described) | - | ONLY_PAID_SOURCES_DOCUMENTED |
| 여정의 증표 | journey growth (not described) | - | ONLY_PAID_SOURCES_DOCUMENTED |
| 여정의 기운 | journey growth (not described) | red-diamond shop: 1개 = 레드 다이아 1,000 (weekly 5) | ONLY_PAID_SOURCES_DOCUMENTED |
| 장비 부 옵션 변환석 | 부옵션 변환 (equipment.subOptionConversion costTable) | - | ONLY_PAID_SOURCES_DOCUMENTED |
| 최상급 마법 부여 주머니 | 마법 부여 주문서 획득 (scrolls.enchant.pouchGradePercent) | - | ONLY_PAID_SOURCES_DOCUMENTED |
| 하급/중급/상급 마법 부여 주머니 | 마법 부여 주문서 획득 | - | UNKNOWN |
| 카오스 링 강화석 | UNKNOWN (no system data) | - | ONLY_PAID_SOURCES_DOCUMENTED |
| 버닝 필드 부스터 | booster | - | ONLY_PAID_SOURCES_DOCUMENTED |
| 1000% 스페셜 핫타임 부스터 티켓 | booster | - | ONLY_PAID_SOURCES_DOCUMENTED |
| 부티크 기프트 | cosmetic (royalstyle boutique) | - | PAID_ONLY |

- Paid-only gameplay hooks to remove/replace: 프리미엄 (membership): 여정의 보물 오프라인 적립 1.7배 + 주간 가속 1회 추가 (journey-treasure.json constants); 멤버십 성공률 보정 for scroll enhancement (scroll.html: "멤버십·캐릭터 보정은 별도"); 회원권 EXP +10%/+5% (event.html); 무기 소환 패스 / 신규 동료 픽업 소환 패스 paid tracks (market-information weaponPass.paidTotals; companion.html passes); 광고 (ad) uses: journey weekly acceleration 1/week for non-premium (free, ad-gated).
- Also sold directly for cash/blue diamonds: artifacts (성배 etc.), Lv40-70 유니크/레전드리 armor, 직업별 에픽/유니크 무기, 자쿰/혼테일 gear, legendary companions, event tokens (`currencies.otherItemsSoldInPaidDeals`).
- 레드 다이아 is spent on pulls (20/50), star-force restore (5,000) and a weekly red-diamond shop; the client calls the restore currency `freeDia`, but no free income table exists in the data.

## 13. Missing / unknown
- Weapon awakening (각성) material counts: "같은 무기와 합성 재료" are required but quantities are not in the data.
- Weapon synthesis/merge (합성) rules and weapon mastery (무기 숙련) values are not in the data.
- Weapon summon: batch sizes other than the per-level maximum draw count (summon-maple maxDrawCount) are not given.
- Companion level-up cost (SupporterLevelUpCostTable is named in companion-information.json sources but its rows are not published).
- Companion pickup summon: per-level grade rates of the pickup banner other than legendary shares (table only lists legendary at Lv.9-13); pickup pass rewards.
- "잠재능력 변환 레벨" / "에디셔널 잠재능력 변환 레벨" (potential conversion level, referenced by hot-deal unlocks up to 60) - no table of what it changes.
- Star Force: native success-rate modifiers (events/membership) are not in the data; star force event discounts unknown.
- Memorial Scroll (메모리얼 스크롤): sold in packages gated by "장비 최대 스타포스 3 이상" but its function is not described anywhere in the data.
- Scroll enhancement: meso cost per attempt ("+ 메소") amounts are not given; number of slots is implied as 10 by slot rules.
- Enchant pouch (하급/중급/상급 마법 부여 주머니) sources other than paid 최상급 packages are not documented; per-value roll distribution within enchant ranges not given.
- Ability: exact value distribution inside an option's [tableMin, tableMax] range is not given.
- Hero Power: free sources of 용사의 증표 (e.g. 용사의 수련장 dungeon rewards) are not stated in the data.
- Journey Treasure: contents/probabilities of the treasure reward itself (JourneyTreasureTable rewards) are not published; only the EXP gauge tables. Journey materials (여정의 증표/기운/상자 열쇠) uses are not described.
- Artifacts: 유물상자 / 픽업 유물상자 / 레전드리 유물 소환 drop rates, duplicate->awakening costs, 유물 강화석 usage/costs, artifact potential (잠재 옵션) pools, 유물 공명 (resonance) amplification table - none published.
- Elite monster equipment (엘리트 몬스터 소환 / 엘리트 등급 up to 29+): summon point costs, grade/tier drop tables, elite level table - not published.
- Normal stage/field drop tables (what armor/materials drop in hunting stages, rates) - not published; stage.html excludes elite and extra monsters.
- Growth dungeons (무기던전/경험치던전/장비던전/용사의 수련장): reward items and amounts are not in the data (only monster stats; 강화던전 scroll drops are).
- Dismantle (분해) and any "armor stone"/방어구 강화석: no data found in any downloaded file.
- Boss raid solo-mode (싱글) sub-line weights: "세부 가중치는 서버에서 결정되어 정확한 수치는 미확인" (boss.html).
- Armor (방어구) direct acquisition outside elite summon / PQ / raids, and 장비던전 rewards - not published.
- Item level of dropped normal gear (how 1..140 item level is assigned) - not published.
- Royal style / cosmetics stats (royalstyle page is a gallery only) - out of scope, not extracted.
- Arena / guild shop / mileage-type shops and their currencies - not in the downloaded data.

## 14. Source files
`$W/js/data/`: summon-levels.json, companion-summon-rewards.json, companion-information.json, weapon-comparison-117.json, weapon-enhancement-costs-117.json, summon-maple-probabilities-117.json, enhancement-client-raw.json, enhancement-client-labels.json, enhancement-store-rules.json, hero-ability-information-117.json, journey-treasure.json, market-information-117.json; `$W/js/assets/`: hotdeal-catalog.json, gear-option-values.mjs, enhancement-engine.mjs, enhancement-ui.mjs, hero-ability-math.mjs/-ui.mjs, journey-treasure.js, cube-efficiency.js, *-ui.mjs; `$W/js/calcv4/`: companion-equip-data.js, ability-options.js, artifact-preset-data.js; `$W/js/calculator/data/loadout-peak-data.js`; pages `$W/itemlibrary.html` (inline D), summon.html, companion.html, scroll.html, boss.html, droptable.html, growth.html, event.html, calcv4.html (ARTIFACTS). Fetched for this task: the `*-ui.mjs`/math modules, the `/data/*.json` above, `/calcv4/companion-templates.json` (OCR icon templates only - no game data), `/hotdeal/` page + catalog.
