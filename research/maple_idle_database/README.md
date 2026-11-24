# maple_idle_database

This is a structured database of real 메이플 키우기 (MapleStory: Idle RPG) game numbers, built for game development. Data was retrieved on 2026-11-24, and covers KR live client 1.18.0 plus a global 1.14.0 client-table snapshot. Values are never invented: an unknown value is `null`, and estimates are kept only in `json/estimates.json`.

- `research_report.md`: findings, key formulas and numbers, coverage table, and version conflicts.
- `missing_data.md`: every missing item, the access paths tried, why they failed, and the hosts to request.
- `sources.csv`: 101 sources (URL, publisher, type, version, region, snapshot date, local copy, number of records citing each).
- `maple_idle.sqlite`: one table per dataset, plus `sources` and `datasets` (coverage notes). JSON lists and objects are stored as JSON text. Integers above int64 (monster HP up to 1e23) are stored as exact decimal strings.
- `json/*.json`: each file holds `dataset`, `description`, `record_count`, `expected_record_count`, `coverage_note` and `records[]`.
- `csv/*.csv`: the same records as the JSON, in UTF-8 with BOM. Nested values are JSON-encoded.
- `build/`: the scripts that produced everything. Their inputs are raw downloads in the session scratchpad (`mdb/raw`), which may be gone later.

## Datasets

| File | Section | Records | Content |
|---|---|---|---|
| character_experience | 3.1 | 140 | EXP to the next level for Lv1-140 (cap 140), cumulative EXP, and a cross-check against the global wiki |
| character_base_stats | 3.1 | 154 | 14 job stat mappings (main/sub stat, stat→ATK). Per-level base HP/MP/ATK/DEF/main/sub are all **null** (not published) |
| stat_upgrade_costs | 3.2 | 2 475 | 용사의 힘 (Hero Power) slot upgrades: stage × slot × level, stat value, gain, token cost and cumulative cost. **No meso-based 능력치 강화 exists in any source** |
| maple_ranks | 3.2 | 10 | Maple Rank placeholder (not found) plus 용사의 힘 stages 1-9 (slots, caps, costs, stage-up timer, stage bonus) |
| incoming_damage_formula | 3.3 | 48 | Ordered formula terms, stacking rules, PvP/content adjustments, level bands, max-HP exceptions, patch changes and explicit unknowns |
| stat_gap_table | 3.3 | 100 | StatGapValueTable: evasion % by (evasion − accuracy) gap, plus debuff columns |
| monster_attack_patterns | 3.3 | 16 | Pink Bean statue hit inputs (x% monster ATK + y% target Max HP) |
| weapon_dungeon_rewards | 3.4 | 160 | Stages 1-150 live plus 151-160 announced. Rewards **null**; monster/stage data filled |
| experience_dungeon_rewards | 3.4 | 160 | EXP per sweep/repeat for 150 stages; first-clear reward null |
| equipment_dungeon_rewards | 3.4 | 160 | Rewards **null**; monster/stage data filled |
| hero_training_rewards | 3.4 | 160 | First-clear, repeat and sweep 용사의 증표 for stages 1-140 (global 1.14); 141-160 null |
| enhancement_dungeon_rewards | 3.4 | 160 | Odds for six enhancement-scroll types per stage; 주문의 흔적 null |
| growth_dungeon_monsters | 3.4 | 800 | Every monster role per stage (KR 1.18.0), plus global 1.14 names and HitChance |
| growth_dungeon_rules | 3.4 | 9 | Keys, sweep, hard stages, clear conditions, unlocks, medals, event keys |
| growth_dungeon_stage_caps | 3.4 | 9 | Stage-cap history 70 → 160 (160 = 11/26 preview) |
| companion_ticket_sources | added | 56 | Free 동료 소환권 sources (permanent, event, coupon, shop), with periods |
| missions | added | 315 | Daily-mission header, event daily/weekly/cumulative missions, 14-day newcomer missions, monthly attendance, daily battle pass |
| achievements | added | 63 | Event-scoped [업적] rows (permanent list not found) |
| guide_quests | added | 24 | Guide-quest numbers that unlock content (rewards not published) |
| summon_level_rewards | added | 60 | Weapon, companion and ability summon-level requirements; free level reward = null; paid level hotdeals flagged |
| special_requests | added | 25 | 특별 의뢰 quests and rewards (global wiki) |
| estimates | – | 23 | **Estimates only:** Hero Training 141-160 extrapolation and the derived daily-mission red-diamond total |

## Record metadata

| Field | Meaning |
|---|---|
| `source_id` | Key into `sources.csv` |
| `source_url` | Where the value comes from |
| `game_version` | Client or patch version (e.g. "KR PC client 1.18.0", "client 1.14.0 …") |
| `region` | `KR` or `global` |
| `retrieved_at` | 2026-11-24 |
| `verification_status` | See the table below |
| `notes` | Interpretation, exceptions and conflicts |

| verification_status | Meaning |
|---|---|
| `verified_client_table` | Decoded client table published by mapleidleindex.com or maplestoryidle.info; cross-checked where possible |
| `official_kr_notice` | Nexon KR forum notice or patch note (quoted) |
| `official_kr_notice_via_repo` | Official values carried over from earlier repo research |
| `secondary_summary_of_official` | MSI's reading of the official guide (the guide itself returns 403) |
| `strong_client_helper_evidence` | Client helper code; strong but not final proof |
| `partially_verified` | Consistent with official statements, but not measured |
| `wiki_global` | Global community wiki |
| `community_reported` | Inven, dcinside or mekifun |
| `not_found` | No source; values are null |
| `announced_not_live` | Stages 151-160 from the 11/26 preview |
| `estimate` | Only in `estimates.json` |

## Quick queries

```sql
-- EXP dungeon reward and monster ATK per stage
SELECT stage, sweep_exp, monster_attack FROM experience_dungeon_rewards WHERE stage BETWEEN 140 AND 150;
-- Hero Power cost to max a stage-8 slot
SELECT stage, stat_type, MAX(cumulative_cost_in_slot) FROM stat_upgrade_costs WHERE stage = 8 GROUP BY stat_type;
-- Evasion chance for a gap of 40
SELECT evade_percent FROM stat_gap_table WHERE gap = 40;
```
