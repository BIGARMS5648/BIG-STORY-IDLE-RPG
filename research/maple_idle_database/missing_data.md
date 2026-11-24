# Missing data: what is still unknown, where we looked, why it failed

Retrieved 2026-11-24. "Not found" means no reachable source publishes the value. Missing values are `null` in the datasets, never `0`. Estimates are kept only in `json/estimates.json`.

## Hosts to request (or content to supply by hand)

| Host / URL | Status on 2026-11-24 | What it would unlock |
|---|---|---|
| `https://maplestoryidle.nexon.com/ko/guide` (official 전투 가이드) | HTTP 403 bot wall (`<title>NEXON</title>`). One attempt only; not circumvented. | The official PvE damage formula, minimum damage, rounding, and possibly base stats. The 6/22 KR notice promised "별도의 공간에 해당 로직에 대한 설명". MSI summarises this guide (reviewed 2026-08-06). A PDF or screenshot export from a human browser would close most of §3.3. |
| `https://namu.wiki/w/메이플%20키우기/시스템` | Cloudflare challenge; fetch denied. Seen only as web-search snippets. | It is the only lead for "능력치 포인트 / 메이플 등급 / 특수 능력치 포인트" (5 points per level; 25 points raise the grade). It also says weapon-dungeon tickets are "최대 50개씩". |
| `https://www.bluestacks.com/blog/game-guides/maplestory-idle-rpg/mpsir-beginners-guide-en.html` | Not on the allowlist. | Its "Maple Rank" description (raises Main Stat/DEF/Max HP, gated by level). |
| `https://mapleidle.gg/` | Vercel Security Checkpoint; not circumvented. | Unknown. Possibly a growth-dungeon or stat database. |
| maplestoryidle.info maintainers (`https://maplestoryidle.info/contact.html`) | Reachable, but data is unpublished. | Their local "patch vault" has every decoded client table: 1858 dungeons, 5691 reward rows, HeroTable. Only curated subsets are public. A request for the DungeonTable→RewardTable join for weapon/exp/gear/enhance (they publish it for Hero Training) and for the hero level/stat tables would close §3.1 and §3.4. |

## §3.1 Character base stats

| Missing item | Expected | Obtained |
|---|---|---|
| Base max HP, max MP, ATK, DEF, main stat and sub stat per level, Lv1-140 | 840 values | 0 |
| Per-level growth and the rounding rule | formula | none |
| Stat points (AP) per level, if they exist | 140 | 0 |
| Job differences in base stats | 14 jobs × 6 | 0 (the stat→ATK conversion is known, see `character_base_stats.json`) |

**Paths tried**
- **mapleidleindex.com:**
  - `/data/level-experience-117.json` has `requiredExp` only.
  - The `/leveling/` and `/calcv4/` inputs take only "현재 캐릭터 레벨".
  - All `/data/*.json` files in the sitemap were scanned (summon-levels, hero-ability, companion, enhancement, market, journey-treasure, weapon-comparison): none has hero level stats.
- **maplestoryidle.info:**
  - `game-data-library.json`: jobs only, with statConversion.
  - `game-stat-rules.json`: 81 StatTypeTable rows with no level table.
  - `target-context-model.json`: pvp and job-step targets have empty stats.
  - `job-behavior-model.json`, `job-skill-impact.json`, `gear-roll-ranges.json` and `equipment-compare-catalog.json`: nothing on base stats.
- **Global wiki:**
  - All 337 pages (MediaWiki API `allpages`); the search API returns nothing.
  - Character Stats has conversions only.
  - The Bowmaster page mentions "level-up stat points" with no numbers.
- **KR official forum:**
  - All 20 patch notes (2025-11-13 to 2026-11-05).
  - Notices 6633, events 6697/7418 and FAQ 6730. 207 threads decoded; none mentions base stats.
- **Others:**
  - GitHub `yanivgoft/MapleStoryIdleOptimizer`: outgoing DPS only.
  - slippa.dev case study: the model and data are private ("isn't mine to publish").

**Why it failed:** no public site exports HeroLevel or base-stat tables. The official guide is behind a bot wall.

## §3.2 능력치 강화 (meso) and 메이플 랭크

- **Meso-based stat upgrade:**
  - Missing: per-stat levels, gain, meso cost, cumulative cost, caps and unlocks.
  - Result: **0 records. The system itself was not found.**
- **Maple Rank:**
  - Missing: rank conditions, effects, caps and special stats.
  - Result: **0 records.**

**Paths tried**
- KR keyword search over 207 decoded forum threads ("능력치 강화", "메이플 랭크", "랭크", "메이플 등급", "능력치 포인트"): 0 hits.
- Inven board search (`/board/mapleidle/6554?name=subjcont&keyword=…`) for "메이플 등급" and "능력치 포인트": only the five sticky posts come back, so there are no matching posts.
- dcinside search: no relevant results.
- Global wiki: no "Maple Rank" page or mention.
- MSI and mapleidleindex data: no matching tables.

**Leads that remain unverified**
- BlueStacks: "Maple Rank … permanently increase Main Stat, Defense, Max HP …, gated behind level requirements".
- namu.wiki snippet: "레벨 1당 능력치 포인트 5개 … 25개 사용 시 메이플 등급 상승 … 특수 능력치 포인트".
- Wiki Bowmaster page: "level-up stat points".

**Assessment:**
- The leads may describe an older build, the global client or another title.
- The KR community and every official KR notice are silent, so the system may not exist in 메이플 키우기 1.18.
- The verified stat-upgrade system with caps and tiers is 용사의 힘 (Hero Power). It is delivered in `stat_upgrade_costs.json` (2 475 rows) and `maple_ranks.json` (stages 1-9).

## §3.3 Incoming damage

Obtained: 42 sourced terms and rules (`incoming_damage_formula.json`). Missing:

| Missing item | Notes |
|---|---|
| Minimum damage | No floor published. |
| Rounding and truncation points | Not in the official notice. |
| Skill coefficients for chapter and growth-dungeon monster attacks | Only Pink Bean raid statues have per-pattern A%/H% inputs (`monster_attack_patterns.json`). |
| Monster critical rate and damage | Absent from all monster exports (MSI 1.14, mapleidleindex 1.18). |
| PvE level-difference modifier | Only PvP level bands are documented. |
| Measured monster→player hits | None published, so the 5000/(6000+DEF) chain is not validated for PvE. |
| Max-HP percentages of 마왕 발록's fixed-damage attacks | The 11/5 notice gives no numbers. |

Paths tried: the official guide (403), the MSI battle-system guides (they summarise it), the KR PvP formula notices (6/22, 6/25, 7/2), the mapleidleindex boss page, the global wiki Character Stats page, and the KR patch notes.

## §3.4 Growth dungeon rewards (750 live stages, plus 151-160 announced for 11/26)

| Dungeon | Missing | Obtained |
|---|---|---|
| 무기 던전 | 무기 소환권 and 무기 강화석 for first clear, repeat and sweep, all 150 stages | 0/150. Monster data 150/150. |
| 장비 던전 | 엘리트 몬스터 소환 포인트, all phases | 0/150. Monster data 150/150. |
| 강화 던전 | 주문의 흔적 amounts; scroll quantity per drop | Scroll odds 150/150; spell traces 0/150 |
| 경험치 던전 | A separate first-clear reward (if any) | Sweep and repeat EXP 150/150 |
| 용사의 수련장 | KR values for stages 141-150; contents of first-clear rows other than tokens | 140/150 (global 1.14 table) |
| All five | Stages 151-160 (11/26 update) | Not live yet |

**Paths tried**
- **mapleidleindex.com:**
  - `/growth/` has inline monster rows and the enhancement scroll odds, but no reward fields. It was confirmed by searching for 보상, 소환권, 강화석, 증표 and 흔적.
  - `/droptable/` (PQ, raid and scroll odds) and `/data/*`: nothing more.
- **maplestoryidle.info:**
  - `game-data-library.json` and `target-context-model.json` have growth-dungeon rows with `rewardIndex: null` and `rewards: []`.
  - `hero-token-calculator.json` is the only DungeonTable→RewardTable join published, and only for the `UPGRADE_HEROPOWER` reward.
- **Global wiki:** the Weapon, Equipment, Enhancement, EXP and Growth Dungeon pages are prose only, and their stage caps are outdated (70/90).
- **KR patch notes and notices:** no reward tables.
- **Community searches:**
  - Inven "무기던전 보상" and "강화던전": no posts.
  - Web search: nothing beyond the namu snippet.

**Why it failed:** per-stage rewards exist only in client tables that no reachable site publishes (except the Hero Training join).

## Added scope: missions, tickets and summon levels

| Missing item | Paths tried | Status |
|---|---|---|
| Permanent individual 일일 미션 (8+): conditions, counts, rewards | KR boards 6633, 6697, 7418, 6698 and 6730; Inven search "일일 미션" (46 results, all event guides); mekifun; the wiki | Only the 8-mission header (무기 소환권 100 + 레드 다이아 5 000) and one added mission (길드 건물 업그레이드, 11/5) are known. The rest appears only in the game UI. |
| 주간 미션 stage count, thresholds and per-stage rewards | Same, plus community totals | Totals only: 레드 다이아 15 500 per week, and one stage gives 무기 소환권 500 (community). |
| Permanent 업적 list | Same | Not found. 62 event-scoped [업적] rows are delivered. |
| 가이드 퀘스트 rewards | Wiki Guide Quest, IV398, hotdeal unlock texts | Unlock numbers only (24 rows). |
| 소환 레벨 보상 (free level-up rewards) | mapleidleindex `summon-levels.json` and `companion-summon-rewards.json` (GachaLevelTable, Supporter/WeaponLevelGachaRewardTable = probabilities), wiki Summon pages | The wiki confirms tickets are granted on level-up, but no amounts are published. The requirements (49 steps) and the paid level hotdeals are delivered. |
| 3차/4차 전직 동료 소환권, free sources | Hotdeal catalog, wiki, events | None free: only paid hotdeals or passes. Exceptions: the 1st-anniversary special-shop 레전드리 동료 소환권 (event coin, once), and the 14-day mission's 79-completion 유니크 동료 reward. |
