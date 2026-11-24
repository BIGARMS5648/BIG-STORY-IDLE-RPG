# Appearance map: addon gear to vanilla item IDs

Data file: `appearance-map.json` (same folder). It drives `DressUpModel`: `SetUnit("player")`, `Undress()`, then `TryOn(id)` for each visible slot. When an ID fails, the addon falls back to the default look.

**Counts:** 504 armor (9 classes x 7 slots x 8 grades), 8 capes (shared), 176 weapon entries (16 jobs, main and off hand x 8 grades). Total 688. Confidence: **688 high, 0 medium, 0 low**.

## How IDs were checked

No ID was written from memory alone. Each one was looked up by its exact English name and then checked against two sources:

- QuestieDB `data/Forever/foreverItemDB.lua`, the WoW: Forever item list (seeded from Classic Era 1.15.x data). The ID must exist and its name must match.
- nexus-devs `wow-classic-items` (Era). The item must have the expected slot and armor type (Plate/Mail/Leather/Cloth) or weapon type, and set pieces come from their tooltip set membership.
- Korean names come from QuestieDB `l10n/Forever/lookupItems/koKR.lua`.

This check caught several IDs that memory got wrong. For example, Shadowfang is 1482, Soulforge Breastplate is 22089 and Larvae of the Great Worm is 23557. One thing could not be checked offline: whether the Forever client has a model for each item. The addon's fallback covers that case.

## Armor grade themes (`armor.<CLASS>.<Slot>.<Grade>`)

Slots: Cap, Shoulder, Clothes, Pants, Glove, Belt, Shoes. Cape is in the separate top-level `cape` map, shared by all classes.

| Grade | Theme |
|---|---|
| Grade1 | 노말 - lv40-55 leveling look (crafted greens / early dungeon blues) |
| Grade2 | 레어 - Rank 7-10 PvP rare set (Knight-Lieutenant/Lt. Commander; Shaman uses Horde Blood Guard/Champion) + Arathi Basin belt |
| Grade3 | 에픽 - Tier 0 (Dungeon Set 1) |
| Grade4 | 유니크 - Tier 0.5 (Dungeon Set 2) |
| Grade5 | 레전드리 - Tier 1 (Molten Core) |
| Grade5_1 | 레전드리+ - Tier 2 (Blackwing Lair) |
| Grade6 | 미스틱 - Tier 2.5 (AQ40; Glove/Belt filled from AQ40 boss loot, set has no hands/waist) |
| Grade6_1 | 미스틱+ - Tier 3 (Naxxramas) |

| Class | G1 | G2 | G3 | G4 | G5 | G5_1 | G6 | G6_1 |
|---|---|---|---|---|---|---|---|---|
| WARRIOR | Imperial Plate + Ornate Mithril Gloves | Lieutenant Commander's Battlegear | Battlegear of Valor | Battlegear of Heroism | Battlegear of Might | Battlegear of Wrath | Conqueror's Battlegear | Dreadnaught's Battlegear |
| PALADIN | Ornate Mithril + Thorium Belt | Lieutenant Commander's Aegis | Lightforge Armor | Soulforge Armor | Lawbringer Armor | Judgement Armor | Avenger's Battlegear | Redemption Armor |
| HUNTER | Tough Scorpid + Boar Champion's Belt | Lieutenant Commander's Pursuit | Beaststalker Armor | Beastmaster Armor | Giantstalker Armor | Dragonstalker Armor | Striker's Garb | Cryptstalker Armor |
| SHAMAN | Scarlet Crusade chain + Turtle Scale Helm + Herod's Shoulder | Champion's Earthshaker | The Elements | The Five Thunders | The Earthfury | The Ten Storms | Stormcaller's Garb | The Earthshatterer |
| ROGUE | Blackened Defias + Nightscape head/shoulder | Lieutenant Commander's Vestments | Shadowcraft Armor | Darkmantle Armor | Nightslayer Armor | Bloodfang Armor | Deathdealer's Embrace | Bonescythe Armor |
| DRUID | Embrace of the Viper + Wolfshead Helm | Lieutenant Commander's Sanctuary | Wildheart Raiment | Feralheart Raiment | Cenarion Raiment | Stormrage Raiment | Genesis Raiment | Dreamwalker Raiment |
| PRIEST | Runecloth | Lieutenant Commander's Raiment | Vestments of the Devout | Vestments of the Virtuous | Vestments of Prophecy | Vestments of Transcendence | Garments of the Oracle | Vestments of Faith |
| MAGE | Black Mageweave + Star Belt | Lieutenant Commander's Regalia | Magister's Regalia | Sorcerer's Regalia | Arcanist Regalia | Netherwind Regalia | Enigma Vestments | Frostfire Regalia |
| WARLOCK | Shadoweave + Deathmage Sash | Lieutenant Commander's Threads | Dreadmist Raiment | Deathmist Raiment | Felheart Raiment | Nemesis Raiment | Doomcaller's Attire | Plagueheart Raiment |

Capes: Grade1 Cape of the Brotherhood (5193), Grade2 Cape of the Black Baron (13340), Grade3 Onyxia Scale Cloak (15138), Grade4 Dragon's Blood Cape (17107), Grade5 Cloak of the Shrouded Mists (17102), Grade5_1 Cloak of the Brood Lord (19378), Grade6 Cloak of the Devoured (22731), Grade6_1 Cloak of the Necropolis (23050).

## Weapons (`weapons.<jobKey>`, grades Grade1-Grade8)

| Job | Spec | Type | Grade8 (top) |
|---|---|---|---|
| hero | 무기 전사 (Arms Warrior) | Two-Hand Sword/Axe | Corrupted Ashbringer (22691) |
| darkKnight | 분노 전사 (Fury Warrior) | Dual-wield One-Hand Sword/Axe | Thunderfury, Blessed Blade of the Windseeker (19019) + Gressil, Dawn of Ruin (23054) |
| paladin | 보호 성기사 (Protection Paladin) | One-Hand Mace/Sword + Shield | Hammer of the Twisting Nether (23056) + Shield of Condemnation (22819) |
| archMageFP | 파괴 흑마법사 (Destruction Warlock) | Staff | Atiesh, Greatstaff of the Guardian (22630) |
| archMageIL | 정기 주술사 (Elemental Shaman) | One-Hand Mace + Shield | Thunderfury, Blessed Blade of the Windseeker (19019) + Death's Bargain (23075) |
| bishop | 신성 사제 (Holy Priest) | Staff | Benediction (18608) |
| bowMaster | 냉기 마법사 (Frost Mage) | Staff | Atiesh, Greatstaff of the Guardian (22589) |
| marksman | 사격 사냥꾼 (Marksmanship Hunter) | Ranged Crossbow/Bow | Rhok'delar, Longbow of the Ancient Keepers (18713) |
| nightLord | 암살 도적 (Assassination Rogue) | Dual Daggers | Kingsfall (22802) + Death's Sting (21126) |
| shadower | 악마 흑마법사 (Demonology Warlock) | Dagger + Held Off-hand | Midnight Haze (22803) + Sapphiron's Left Eye (23049) |
| viper | 야성 드루이드 (Feral Druid, Cat) | Two-Hand Mace/Staff | Might of Menethil (22798) |
| captain | 야수 사냥꾼 (Beast Mastery Hunter) | Ranged Gun | Toxin Injector (22810) |
| windBreaker | 조화 드루이드 (Balance Druid) | Staff | Atiesh, Greatstaff of the Guardian (22632) |
| nightWalker | 암흑 사제 (Shadow Priest) | Staff | Anathema (18609) |
| soulMaster | 징벌 성기사 (Retribution Paladin) | Two-Hand Mace/Sword | Sulfuras, Hand of Ragnaros (17182) |
| flameWizard | 화염 마법사 (Fire Mage) | One-Hand Sword + Held Off-hand | Wraith Blade (22807) + Sapphiron's Right Eye (23048) |

An empty `offHand` means a two-hand or ranged weapon. Atiesh comes in a separate ID per class (mage 22589, warlock 22630, priest 22631, druid 22632), and all four share one model.

## Notes for the addon

- **Off hand:** for the dual-wield jobs (darkKnight, nightLord), try on the off-hand weapon with `TryOn(id, "SECONDARYHANDSLOT")` if the client's `TryOn` takes a hand-slot argument. Otherwise the second one-hand weapon may replace the main hand. Shields and held-in-off-hand items go to the off hand on their own.
- **Ranged:** marksman and captain have only ranged weapons. If the Forever `DressUpModel` does not show ranged weapons in the hand, they will not appear. In that case, add a melee look or accept no weapon.
- **Robes:** Clothes entries that are robes cover the Pants entry. This is normal.
- **Faction and class flavor:** the G2 PvP sets are Alliance pieces, except the Shaman set, which is Horde. Appearance does not depend on the player's faction or class.
- **Repeats:** some mid-grade staves are used by more than one job, and Thunderfury is the top weapon for both darkKnight and archMageIL. Within a single job, no item repeats across its 8 grades.
