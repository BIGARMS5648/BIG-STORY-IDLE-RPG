#!/usr/bin/env python3
"""Generate BigStoryIdleRPG/Data/Upgrades.lua (star force, potential, scrolls/enchant,
hero power, ability, artifacts, journey) from research/spec/items-gacha.json.

KR client 1.18.0 data comes from items-gacha.json. Where the KR extraction has gaps,
global-wiki / KR-community values are embedded below in GLOBAL (each with its source);
those are copied verbatim, never estimated. Remaining unknowns are PROVISIONAL in the
Systems/*.lua files, not here.

Usage: python3 -I tools/gen_upgrades.py  (run from the repository root)
"""
import json
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
from luagen import to_lua  # noqa: E402

ROOT = os.path.dirname(HERE)
SPEC = os.path.join(ROOT, "research", "spec")
OUT = os.path.join(ROOT, "BigStoryIdleRPG", "Data", "Upgrades.lua")

# ---------------------------------------------------------------------------
# Data missing from the KR extraction (items-gacha.json), copied from:
#  artifactInventory  : idle.maplestorywiki.net "Artifacts" (global) - 보유 효과 per awakening 0..5,
#                       raw units (percent x10); None = not published (legendary awakening 1+)
#  resonanceCost      : idle.maplestorywiki.net "Resonance Amplification/Costs" (global) - 유물 강화석 per level 1..900
#  journeyTrail       : idle.maplestorywiki.net "Module:HeroJourney/data.json" (global) - 여정의 발자취 ch20..41
#                       slots = [stat, raw value per grade Normal..Mystic+], special = 4th (special) option
#  journeyChestTokens : idle.maplestorywiki.net "Hero's Journey" (global) - 여정의 상자 base tokens per chapter
# (all collected in scratchpad research-progression.json, 2026-11-24)
# ---------------------------------------------------------------------------
GLOBAL = {'artifactInventory': {'ARTIFACT_3_1': [['Attack', [50, 100, 150, 200, 250, 300]],
                                        ['MaxHp', [500, 1000, 1500, 2000, 2500, 3000]]],
                       'ARTIFACT_3_2': [['Attack', [50, 100, 150, 200, 250, 300]],
                                        ['MaxHp', [500, 1000, 1500, 2000, 2500, 3000]]],
                       'ARTIFACT_3_3': [['Attack', [50, 100, 150, 200, 250, 300]],
                                        ['MaxHp', [500, 1000, 1500, 2000, 2500, 3000]]],
                       'ARTIFACT_3_4': [['Attack', [50, 100, 150, 200, 250, 300]],
                                        ['MaxHp', [500, 1000, 1500, 2000, 2500, 3000]]],
                       'ARTIFACT_4_1': [['Attack', [100, 200, 300, 400, 500, 600]],
                                        ['Defence', [70, 140, 210, 280, 350, 420]]],
                       'ARTIFACT_4_2': [['Attack', [100, 200, 300, 400, 500, 600]],
                                        ['Defence', [70, 140, 210, 280, 350, 420]]],
                       'ARTIFACT_4_3': [['Attack', [100, 200, 300, 400, 500, 600]],
                                        ['Defence', [70, 140, 210, 280, 350, 420]]],
                       'ARTIFACT_4_4': [['Attack', [100, 200, 300, 400, 500, 600]],
                                        ['Defence', [70, 140, 210, 280, 350, 420]]],
                       'ARTIFACT_4_5': [['Attack', [100, 200, 300, 400, 500, 600]],
                                        ['Defence', [70, 140, 210, 280, 350, 420]]],
                       'ARTIFACT_4_6': [['Attack', [100, 200, 300, 400, 500, 600]],
                                        ['Defence', [70, 140, 210, 280, 350, 420]]],
                       'ARTIFACT_4_7': [['FinalDamage', [10, 12, 14, 16, 18, 20]]],
                       'ARTIFACT_4_8': [['FinalDamage', [10, 12, 14, 16, 18, 20]]],
                       'ARTIFACT_4_9': [['FinalDamage', [10, 12, 14, 16, 18, 20]]],
                       'ARTIFACT_5_1': [['AttackPower', [300, None, None, None, None, None]]],
                       'ARTIFACT_5_10': [['AvoidChance', [20, None, None, None, None, None]]],
                       'ARTIFACT_5_11': [['MaxDamageRatio', [150, None, None, None, None, None]]],
                       'ARTIFACT_5_12': [['CriticalPower', [100, None, None, None, None, None]]],
                       'ARTIFACT_5_13': [['HitChance', [10, None, None, None, None, None]]],
                       'ARTIFACT_5_14': [['BaseAttackPower', [150, None, None, None, None, None]]],
                       'ARTIFACT_5_15': [['MinDamageRatio', [150, None, None, None, None, None]]],
                       'ARTIFACT_5_16': [['AttackSpeed', [50, None, None, None, None, None]]],
                       'ARTIFACT_5_17': [['AttackPower', [300, 360, None, None, None, None]]],
                       'ARTIFACT_5_18': [['MaxDamageRatio', [150, None, None, None, None, None]]],
                       'ARTIFACT_5_19': [['AttackPowerToBoss', [150, None, None, None, None, None]]],
                       'ARTIFACT_5_2': [['DebuffResist', [10, None, None, None, None, None]]],
                       'ARTIFACT_5_20': [['HitChance', [10, None, None, None, None, None]]],
                       'ARTIFACT_5_21': [['AttackPower', [300, None, None, None, None, None]]],
                       'ARTIFACT_5_22': [['FinalDamage', [20, None, None, None, None, None]]],
                       'ARTIFACT_5_23': [['CriticalPower', [100, None, None, None, None, None]]],
                       'ARTIFACT_5_3': [['PiercePower', [50, None, None, None, None, None]]],
                       'ARTIFACT_5_4': [['DefenceR', [100, None, None, None, None, None]]],
                       'ARTIFACT_5_5': [['CriticalChance', [50, None, None, None, None, None]]],
                       'ARTIFACT_5_6': [['Toughness', [50, None, None, None, None, None]]],
                       'ARTIFACT_5_7': [['AttackPowerExcludeBoss', [150, None, None, None, None, None]]],
                       'ARTIFACT_5_8': [['SkillPower', [150, None, None, None, None, None]]],
                       'ARTIFACT_5_9': [['AttackPowerToBoss', [150, None, None, None, None, None]]]},
 'journeyChestTokens': {20: 10280,
                        21: 11300,
                        22: 12320,
                        23: 13340,
                        24: 14360,
                        25: 15380,
                        26: 16380,
                        27: 17400,
                        28: 18420,
                        29: 19440,
                        30: 21020,
                        31: 22640,
                        32: 24760,
                        33: 26860,
                        34: 28980,
                        35: 31100,
                        36: 33200,
                        37: 35320,
                        38: 37420,
                        39: 39540,
                        40: 42400,
                        41: 45300},
 'journeyTrail': {20: {'change': {'journeyToken': 1900, 'meso': 5000},
                       'openCost': {'journeyToken': 60300, 'meso': 674400},
                       'openSec': 96000,
                       'rewards': {'cubeMiracle': 10, 'journeyToken': 12000, 'starforceScroll': 20},
                       'slots': [['Attack', [200, 400, 800, 1200, 3000, 9000, 18000]],
                                 ['MaxHp', [1000, 2000, 4000, 6000, 15000, 45000, 90000]],
                                 ['MainStat', [17, 34, 68, 100, 260, 510, 770]]],
                       'special': ['MainStatR', 50]},
                  21: {'change': {'journeyToken': 2120, 'meso': 5300},
                       'openCost': {'journeyToken': 78500, 'meso': 752900},
                       'openSec': 114000,
                       'rewards': {'cubeMiracle': 10, 'journeyToken': 15000},
                       'slots': [['Attack', [230, 460, 920, 1380, 3450, 10350, 20700]],
                                 ['MaxHp', [1150, 2300, 4600, 6900, 17250, 51750, 103500]],
                                 ['AttackPower', [8, 16, 32, 48, 120, 240, 300]]],
                       'special': ['AttackPowerToBoss', 100]},
                  22: {'change': {'journeyToken': 2360, 'meso': 5600},
                       'openCost': {'journeyToken': 99600, 'meso': 836300},
                       'openSec': 132960,
                       'rewards': {'cubeAdditional': 5, 'journeyToken': 19000},
                       'slots': [['Attack', [260, 520, 1040, 1560, 3900, 11700, 23400]],
                                 ['MaxHp', [1300, 2600, 5200, 7800, 19500, 58500, 117000]],
                                 ['MaxMp', [40, 80, 160, 240, 600, 1200, 1800]]],
                       'special': ['AttackPowerExcludeBoss', 100]},
                  23: {'change': {'journeyToken': 2620, 'meso': 5900},
                       'openCost': {'journeyToken': 124600, 'meso': 924700},
                       'openSec': 153960,
                       'rewards': {'journeyToken': 24000, 'starforceScroll': 20},
                       'slots': [['Attack', [290, 580, 1160, 1740, 4350, 13050, 26100]],
                                 ['MaxHp', [1450, 2900, 5800, 8700, 21750, 65250, 130500]],
                                 ['HitChance', [1, 2, 3, 5, 7, 10, 15]]],
                       'special': ['AttackPower', 200]},
                  24: {'change': {'journeyToken': 2910, 'meso': 6200},
                       'openCost': {'journeyToken': 153800, 'meso': 1018100},
                       'openSec': 177000,
                       'rewards': {'cubeMiracle': 10, 'journeyToken': 30000},
                       'slots': [['Attack', [320, 640, 1280, 1920, 4800, 14400, 28800]],
                                 ['MaxHp', [1600, 3200, 6400, 9600, 24000, 72000, 144000]],
                                 ['MainStat', [19, 38, 76, 110, 290, 570, 860]]],
                       'special': ['MaxDamageRatio', 100]},
                  25: {'change': {'journeyToken': 3220, 'meso': 6500},
                       'openCost': {'journeyToken': 186700, 'meso': 1116600},
                       'openSec': 201000,
                       'rewards': {'cubeAdditional': 5, 'cubeMiracle': 10, 'journeyToken': 37000},
                       'slots': [['Attack', [350, 700, 1400, 2100, 5250, 15750, 31500]],
                                 ['MaxHp', [1750, 3500, 7000, 10500, 26250, 78750, 157500]],
                                 ['AttackPowerToBoss', [4, 8, 16, 24, 60, 120, 180]]],
                       'special': ['BonusExpPercent', 70]},
                  26: {'change': {'journeyToken': 3560, 'meso': 6800},
                       'openCost': {'journeyToken': 224500, 'meso': 1220200},
                       'openSec': 226980,
                       'rewards': {'journeyToken': 44000, 'starforceScroll': 20},
                       'slots': [['Attack', [380, 760, 1520, 2280, 5700, 17100, 34200]],
                                 ['MaxHp', [1900, 3800, 7600, 11400, 28500, 85500, 171000]],
                                 ['Defence', [90, 180, 360, 540, 1350, 2700, 4050]]],
                       'special': ['AttackPowerExcludeBoss', 100]},
                  27: {'change': {'journeyToken': 3920, 'meso': 7100},
                       'openCost': {'journeyToken': 267500, 'meso': 1329100},
                       'openSec': 255000,
                       'rewards': {'cubeMiracle': 10, 'journeyToken': 53000},
                       'slots': [['Attack', [410, 820, 1640, 2460, 6150, 18450, 36900]],
                                 ['MaxHp', [2050, 4100, 8200, 12300, 30750, 92250, 184500]],
                                 ['MainStat', [22, 44, 88, 130, 330, 660, 990]]],
                       'special': ['MainStatR', 50]},
                  28: {'change': {'journeyToken': 4310, 'meso': 7400},
                       'openCost': {'journeyToken': 315000, 'meso': 1443200},
                       'openSec': 283980,
                       'rewards': {'cubeAdditional': 5, 'journeyToken': 63000},
                       'slots': [['Attack', [440, 880, 1760, 2640, 6600, 19800, 39600]],
                                 ['MaxHp', [2200, 4400, 8800, 13200, 33000, 99000, 198000]],
                                 ['HitChance', [1, 2, 3, 5, 7, 10, 15]]],
                       'special': ['MaxDamageRatio', 100]},
                  29: {'change': {'journeyToken': 4730, 'meso': 7700},
                       'openCost': {'journeyToken': 372600, 'meso': 1562700},
                       'openSec': 315000,
                       'rewards': {'journeyToken': 74000, 'starforceScroll': 20},
                       'slots': [['Attack', [470, 940, 1880, 2820, 7050, 21150, 42300]],
                                 ['MaxHp', [2350, 4700, 9400, 14100, 35250, 105750, 211500]],
                                 ['AttackPower', [8, 16, 32, 48, 120, 240, 360]]],
                       'special': ['MinDamageRatio', 100]},
                  30: {'change': {'journeyToken': 5180, 'meso': 8000},
                       'openCost': {'journeyToken': 442900, 'meso': 1687500},
                       'openSec': 346980,
                       'rewards': {'cubeMiracle': 10, 'journeyToken': 88000, 'starforceScroll': 20},
                       'slots': [['Attack', [500, 1000, 2000, 3000, 7500, 22500, 45000]],
                                 ['MaxHp', [2500, 5000, 10000, 15000, 37500, 112500, 225000]],
                                 ['AttackPowerExcludeBoss', [4, 8, 16, 24, 60, 120, 180]]],
                       'special': ['FinalDamage', 25]},
                  31: {'change': {'journeyToken': 5660, 'meso': 8300},
                       'openCost': {'journeyToken': 527200, 'meso': 1817800},
                       'openSec': 381000,
                       'rewards': {'cubeAdditional': 5, 'journeyToken': 105000},
                       'slots': [['Attack', [530, 1060, 2120, 3180, 7950, 23850, 47700]],
                                 ['MaxHp', [2650, 5300, 10600, 15900, 39750, 119250, 238500]],
                                 ['MainStat', [24, 48, 96, 140, 360, 720, 1100]]],
                       'special': ['MainStatR', 50]},
                  32: {'change': {'journeyToken': 6170, 'meso': 8600},
                       'openCost': {'journeyToken': 629000, 'meso': 1953600},
                       'openSec': 417000,
                       'rewards': {'journeyToken': 125000, 'starforceScroll': 20},
                       'slots': [['Attack', [560, 1120, 2240, 3360, 8400, 25200, 50400]],
                                 ['MaxHp', [2800, 5600, 11200, 16800, 42000, 126000, 252000]],
                                 ['BonusExpPercent', [10, 20, 30, 50, 70, 100, 120]]],
                       'special': ['AttackPowerToBoss', 100]},
                  33: {'change': {'journeyToken': 6710, 'meso': 8900},
                       'openCost': {'journeyToken': 741300, 'meso': 2094900},
                       'openSec': 453960,
                       'rewards': {'cubeMiracle': 10, 'journeyToken': 148000},
                       'slots': [['Attack', [590, 1180, 2360, 3540, 8850, 26550, 53100]],
                                 ['MaxHp', [2950, 5900, 11800, 17700, 44250, 132750, 265500]],
                                 ['AttackPower', [8, 16, 32, 48, 120, 240, 360]]],
                       'special': ['MinDamageRatio', 100]},
                  34: {'change': {'journeyToken': 7290, 'meso': 9200},
                       'openCost': {'journeyToken': 866400, 'meso': 2241800},
                       'openSec': 492960,
                       'rewards': {'cubeAdditional': 5, 'journeyToken': 173000},
                       'slots': [['Attack', [620, 1240, 2480, 3720, 9300, 27900, 55800]],
                                 ['MaxHp', [3100, 6200, 12400, 18600, 46500, 139500, 279000]],
                                 ['BonusGoldPercent', [10, 20, 30, 50, 70, 100, 120]]],
                       'special': ['MaxDamageRatio', 100]},
                  35: {'change': {'journeyToken': 7900, 'meso': 9500},
                       'openCost': {'journeyToken': 1003200, 'meso': 2394300},
                       'openSec': 532980,
                       'rewards': {'cubeMiracle': 10, 'journeyToken': 200000, 'starforceScroll': 20},
                       'slots': [['Attack', [650, 1300, 2600, 3900, 9750, 29250, 58500]],
                                 ['MaxHp', [3250, 6500, 13000, 19500, 48750, 146250, 292500]],
                                 ['FinalDamage', [1, 2, 4, 6, 15, 30, 45]]],
                       'special': ['CriticalPower', 100]},
                  36: {'change': {'journeyToken': 8550, 'meso': 9800},
                       'openCost': {'journeyToken': 1155700, 'meso': 2552500},
                       'openSec': 576000,
                       'rewards': {'cubeMiracle': 10, 'journeyToken': 231000},
                       'slots': [['Attack', [680, 1360, 2720, 4080, 10200, 30600, 61200]],
                                 ['MaxHp', [3400, 6800, 13600, 20400, 51000, 153000, 306000]],
                                 ['MainStat', [27, 54, 110, 160, 410, 810, 1200]]],
                       'special': ['AttackPowerToBoss', 100]},
                  37: {'change': {'journeyToken': 9230, 'meso': 10100},
                       'openCost': {'journeyToken': 1319200, 'meso': 2716400},
                       'openSec': 618960,
                       'rewards': {'cubeAdditional': 5, 'journeyToken': 264000},
                       'slots': [['Attack', [710, 1420, 2840, 4260, 10650, 31950, 63900]],
                                 ['MaxHp', [3550, 7100, 14200, 21300, 53250, 159750, 319500]],
                                 ['CriticalPower', [4, 8, 16, 24, 60, 120, 150]]],
                       'special': ['AttackPowerExcludeBoss', 100]},
                  38: {'change': {'journeyToken': 9950, 'meso': 10400},
                       'openCost': {'journeyToken': 1499900, 'meso': 2886100},
                       'openSec': 664980,
                       'rewards': {'journeyToken': 300000, 'starforceScroll': 20},
                       'slots': [['Attack', [740, 1480, 2960, 4440, 11100, 33300, 66600]],
                                 ['MaxHp', [3700, 7400, 14800, 22200, 55500, 166500, 333000]],
                                 ['BonusExpPercent', [10, 20, 30, 50, 70, 100, 120]]],
                       'special': ['MainStatR', 50]},
                  39: {'change': {'journeyToken': 10710, 'meso': 10700},
                       'openCost': {'journeyToken': 1707700, 'meso': 3061600},
                       'openSec': 711960,
                       'rewards': {'cubeMiracle': 10, 'journeyToken': 341000},
                       'slots': [['Attack', [770, 1540, 3080, 4620, 11550, 34650, 69300]],
                                 ['MaxHp', [3850, 7700, 15400, 23100, 57750, 173250, 346500]],
                                 ['BonusGoldPercent', [10, 20, 30, 50, 70, 100, 120]]],
                       'special': ['MinDamageRatio', 100]},
                  40: {'change': {'journeyToken': 11510, 'meso': 11000},
                       'openCost': {'journeyToken': 1951300, 'meso': 3242900},
                       'openSec': 759960,
                       'rewards': {'cubeAdditional': 5, 'cubeMiracle': 10, 'journeyToken': 390000},
                       'slots': [['Attack', [800, 1600, 3200, 4800, 12000, 36000, 72000]],
                                 ['MaxHp', [4000, 8000, 16000, 24000, 60000, 180000, 360000]],
                                 ['CriticalPower', [4, 8, 16, 24, 60, 120, 180]]],
                       'special': ['FinalDamage', 25]},
                  41: {'change': {'journeyToken': 12350, 'meso': 11300},
                       'openCost': {'journeyToken': 2228900, 'meso': 3432900},
                       'openSec': 808980,
                       'rewards': {'journeyToken': 446000, 'starforceScroll': 20},
                       'slots': [['Attack', [830, 1660, 3320, 4980, 12450, 37350, 74700]],
                                 ['MaxHp', [4150, 8300, 16600, 24900, 62250, 186750, 373500]],
                                 ['MainStat', [29, 58, 120, 170, 440, 870, 1300]]],
                       'special': ['AttackPowerToBoss', 100]}},
 'resonanceCost': [1500, 1518, 1536, 1554, 1572, 1590, 1608, 1626, 1644, 1662, 1680, 1698, 1716, 1734, 1752, 1771, 1790,
                   1809, 1828, 1847, 1866, 1885, 1904, 1923, 1942, 1961, 1980, 1999, 2018, 2037, 2056, 2075, 2094, 2113,
                   2132, 2151, 2170, 2189, 2208, 2227, 2246, 2265, 2285, 2305, 2325, 2345, 2365, 2385, 2405, 2425, 2445,
                   2465, 2485, 2505, 2525, 2545, 2565, 2585, 2605, 2625, 2645, 2665, 2685, 2705, 2725, 2745, 2765, 2786,
                   2807, 2828, 2849, 2870, 2891, 2912, 2933, 2954, 2975, 2996, 3017, 3038, 3059, 3080, 3101, 3122, 3143,
                   3164, 3185, 3206, 3227, 3248, 3269, 3291, 3313, 3335, 3357, 3379, 3401, 3423, 3445, 3467, 3489, 3511,
                   3533, 3555, 3577, 3599, 3621, 3643, 3665, 3687, 3709, 3731, 3753, 3776, 3799, 3822, 3845, 3868, 3891,
                   3914, 3937, 3960, 3983, 4006, 4029, 4052, 4075, 4098, 4121, 4144, 4167, 4190, 4213, 4236, 4259, 4283,
                   4307, 4331, 4355, 4379, 4403, 4427, 4451, 4475, 4499, 4523, 4547, 4571, 4595, 4619, 4643, 4667, 4691,
                   4715, 4739, 4763, 4788, 4813, 4838, 4863, 4888, 4913, 4938, 4963, 4988, 5013, 5038, 5063, 5088, 5113,
                   5138, 5163, 5188, 5213, 5238, 5263, 5289, 5315, 5341, 5367, 5393, 5419, 5445, 5471, 5497, 5523, 5549,
                   5575, 5601, 5627, 5653, 5679, 5705, 5731, 5757, 5784, 5811, 5838, 5865, 5892, 5919, 5946, 5973, 6000,
                   6027, 6054, 6081, 6108, 6135, 6162, 6189, 6216, 6243, 6270, 6298, 6326, 6354, 6382, 6410, 6438, 6466,
                   6494, 6522, 6550, 6578, 6606, 6634, 6662, 6690, 6718, 6746, 6774, 6803, 6832, 6861, 6890, 6919, 6948,
                   6977, 7006, 7035, 7064, 7093, 7122, 7151, 7180, 7209, 7238, 7267, 7297, 7327, 7357, 7387, 7417, 7447,
                   7477, 7507, 7537, 7567, 7597, 7627, 7657, 7687, 7717, 7747, 7777, 7808, 7839, 7870, 7901, 7932, 7963,
                   7994, 8025, 8056, 8087, 8118, 8149, 8180, 8211, 8242, 8273, 8305, 8337, 8369, 8401, 8433, 8465, 8497,
                   8529, 8561, 8593, 8625, 8657, 8689, 8721, 8753, 8786, 8819, 8852, 8885, 8918, 8951, 8984, 9017, 9050,
                   9083, 9116, 9149, 9182, 9215, 9248, 9281, 9315, 9349, 9383, 9417, 9451, 9485, 9519, 9553, 9587, 9621,
                   9655, 9689, 9723, 9757, 9792, 9827, 9862, 9897, 9932, 9967, 10002, 10037, 10072, 10107, 10142, 10177,
                   10212, 10247, 10282, 10318, 10354, 10390, 10426, 10462, 10498, 10534, 10570, 10606, 10642, 10678,
                   10714, 10750, 10787, 10824, 10861, 10898, 10935, 10972, 11009, 11046, 11083, 11120, 11157, 11194,
                   11231, 11268, 11306, 11344, 11382, 11420, 11458, 11496, 11534, 11572, 11610, 11648, 11686, 11724,
                   11762, 11801, 11840, 11879, 11918, 11957, 11996, 12035, 12074, 12113, 12152, 12191, 12230, 12269,
                   12309, 12349, 12389, 12429, 12469, 12509, 12549, 12589, 12629, 12669, 12709, 12749, 12789, 12830,
                   12871, 12912, 12953, 12994, 13035, 13076, 13117, 13158, 13199, 13240, 13281, 13323, 13365, 13407,
                   13449, 13491, 13533, 13575, 13617, 13659, 13701, 13743, 13785, 13828, 13871, 13914, 13957, 14000,
                   14043, 14086, 14129, 14172, 14215, 14258, 14302, 14346, 14390, 14434, 14478, 14522, 14566, 14610,
                   14654, 14698, 14742, 14786, 14831, 14876, 14921, 14966, 15011, 15056, 15101, 15146, 15191, 15236,
                   15281, 15327, 15373, 15419, 15465, 15511, 15557, 15603, 15649, 15695, 15741, 15787, 15834, 15881,
                   15928, 15975, 16022, 16069, 16116, 16163, 16210, 16257, 16305, 16353, 16401, 16449, 16497, 16545,
                   16593, 16641, 16689, 16737, 16785, 16834, 16883, 16932, 16981, 17030, 17079, 17128, 17177, 17226,
                   17275, 17325, 17375, 17425, 17475, 17525, 17575, 17625, 17675, 17725, 17775, 17826, 17877, 17928,
                   17979, 18030, 18081, 18132, 18183, 18234, 18285, 18337, 18389, 18441, 18493, 18545, 18597, 18649,
                   18701, 18753, 18806, 18859, 18912, 18965, 19018, 19071, 19124, 19177, 19230, 19283, 19337, 19391,
                   19445, 19499, 19553, 19607, 19661, 19715, 19769, 19824, 19879, 19934, 19989, 20044, 20099, 20154,
                   20209, 20264, 20320, 20376, 20432, 20488, 20544, 20600, 20656, 20712, 20768, 20825, 20882, 20939,
                   20996, 21053, 21110, 21167, 21224, 21281, 21339, 21397, 21455, 21513, 21571, 21629, 21687, 21745,
                   21803, 21862, 21921, 21980, 22039, 22098, 22157, 22216, 22275, 22335, 22395, 22455, 22515, 22575,
                   22635, 22695, 22755, 22816, 22877, 22938, 22999, 23060, 23121, 23182, 23243, 23304, 23366, 23428,
                   23490, 23552, 23614, 23676, 23738, 23800, 23863, 23926, 23989, 24052, 24115, 24178, 24241, 24304,
                   24368, 24432, 24496, 24560, 24624, 24688, 24752, 24817, 24882, 24947, 25012, 25077, 25142, 25207,
                   25272, 25338, 25404, 25470, 25536, 25602, 25668, 25734, 25800, 25867, 25934, 26001, 26068, 26135,
                   26202, 26269, 26337, 26405, 26473, 26541, 26609, 26677, 26745, 26813, 26882, 26951, 27020, 27089,
                   27158, 27227, 27296, 27366, 27436, 27506, 27576, 27646, 27716, 27786, 27857, 27928, 27999, 28070,
                   28141, 28212, 28283, 28355, 28427, 28499, 28571, 28643, 28715, 28787, 28860, 28933, 29006, 29079,
                   29152, 29225, 29298, 29372, 29446, 29520, 29594, 29668, 29742, 29816, 29891, 29966, 30041, 30116,
                   30191, 30266, 30342, 30418, 30494, 30570, 30646, 30722, 30798, 30875, 30952, 31029, 31106, 31183,
                   31260, 31338, 31416, 31494, 31572, 31650, 31728, 31806, 31885, 31964, 32043, 32122, 32201, 32280,
                   32360, 32440, 32520, 32600, 32680, 32760, 32841, 32922, 33003, 33084, 33165, 33246, 33327, 33409,
                   33491, 33573, 33655, 33737, 33819, 33902, 33985, 34068, 34151, 34234, 34317, 34401, 34485, 34569,
                   34653, 34737, 34821, 34906, 34991, 35076, 35161, 35246, 35331, 35417, 35503, 35589, 35675, 35761,
                   35848, 35935, 36022, 36109, 36196, 36283, 36371, 36459, 36547, 36635, 36723, 36811, 36900, 36989,
                   37078, 37167, 37256, 37346, 37436, 37526, 37616, 37706, 37796, 37887, 37978, 38069, 38160, 38251,
                   38343, 38435, 38527, 38619, 38711, 38803, 38896, 38989, 39082, 39175, 39268, 39362, 39456, 39550,
                   39644, 39738, 39832, 39927, 40022, 40117, 40212, 40307, 40403, 40499, 40595, 40691, 40787, 40884,
                   40981, 41078, 41175, 41272, 41370, 41468, 41566, 41664, 41762, 41861, 41960, 42059, 42158, 42257,
                   42357, 42457, 42557, 42657, 42757, 42858, 42959, 43060, 43161, 43262, 43364, 43466, 43568, 43670,
                   43772, 43875, 43978, 44081, 44184, 44287, 44391, 44495, 44599, 44703, 44807, 44912, 45017, 45122,
                   45227, 45332, 45438, 45544, 45650, 45756, 45863, 45970, 46077, 46184, 46291, 46399, 46507, 46615,
                   46723]}


def load(name):
    with open(os.path.join(SPEC, name), encoding="utf-8") as f:
        return json.load(f)


def big(v):
    if isinstance(v, (int, float)):
        return v
    s = str(v).replace(",", "")
    try:
        return int(s)
    except ValueError:
        return float(s)


def pct_raw(text):
    """'0.5%' / '+1.4%' -> raw 0.1% units (5 / 14)."""
    return int(round(float(text.replace("+", "").replace("%", "").replace(",", "").strip()) * 10))


def flat(text):
    return int(text.replace("+", "").replace(",", "").strip())


# ---------------------------------------------------------------------------
# Stat labels / display
# ---------------------------------------------------------------------------
EXTRA_LABELS = {
    "Str": "STR", "Dex": "DEX", "Int": "INT", "Luk": "LUK",
    "StrR": "STR%", "DexR": "DEX%", "IntR": "INT%", "LukR": "LUK%",
    "MainStat": "주 스탯", "MainStatR": "주 스탯%", "DefenceR": "방어력%", "MaxHpR": "최대 HP%", "MaxMpR": "최대 MP%",
    "AttackPower2": "데미지 증폭", "HitChance": "명중", "AvoidChance": "회피", "MpRegen": "초당 MP 회복",
    "DebuffResist": "디버프 내성", "CriticalResist": "크리티컬 저항", "Toughness": "받는 피해 감소",
    "BonusGoldPercent": "메소 획득량", "BonusExpPercent": "경험치 획득량", "AttackSpeed": "공격 속도",
    "AttackPower": "데미지", "BaseAttackPower": "기본 공격 데미지", "HpPotionCoolTimeReduceRatio": "HP 물약 재사용 대기시간 감소",
    "Weakness": "받는 피해 증가", "CoolTimeReduceRatio": "스킬 재사용 대기시간 감소",
    "CoolTimeReduce": "스킬 재사용 대기시간 감소", "SupporterDurationRatio": "동료 소환 지속시간 증가",
}


def stat_tables(d):
    labels = {}
    labels.update(d["equipment"]["statLabels"])
    labels.update(d["potential"]["optionLabels"])
    labels.update(EXTRA_LABELS)
    display = {k: v for k, v in d["potential"]["statDisplay"].items()}
    for k in ("StrR", "DexR", "IntR", "LukR", "MainStatR", "DefenceR", "MaxHpR", "MaxMpR"):
        display[k] = "Percent"
    return labels, display


# ---------------------------------------------------------------------------
# Star force
# ---------------------------------------------------------------------------
def gen_starforce(d):
    sf = d["starforce"]
    r = sf["rules"]
    rows = {}
    for row in sf["rows"]:
        rows[row["star"]] = {
            "success": row["success"], "fail": row["fail"], "down": row["down"], "destroy": row["destroy"],
            "preventDown": row["preventDown"], "preventDestroy": row["preventDestroy"],
            "scroll": row["scroll"], "meso": row["meso"],
            "pdScroll": row["preventDownScroll"], "pdMeso": row["preventDownMeso"],
            "pxScroll": row["preventDestroyScroll"], "pxMeso": row["preventDestroyMeso"],
            "maxPoint": row["maxEnhancePoint"],
        }
    amp = {}
    for k, v in sf["amplificationPerStar"].items():
        e = {"main": v["main"], "sub": v["sub"]}
        if v.get("stat"):
            assert v["stat"]["type"] == "FinalDamage"
            e["fd"] = v["stat"]["value"]
        amp[int(k)] = e
    restore = {x["restoreToStar"]: {"redDia": x["redDiamond_freeDia"], "meso": x["meso"], "scroll": x["scroll"]}
               for x in sf["destroyRestore"]}
    return {
        "scale": sf["probabilityScale"],
        "maxStar": sf["maxStar"],
        "rules": {
            "chanceTimeDownCount": r["chanceTimeDownCount"], "failPoint": r["failPoint"], "downPoint": r["downPoint"],
            "destroyPoint": r["destroyPoint"], "destroyResultStar": r["destroyResultStarForce"],
        },
        "rows": rows, "amp": amp, "restore": restore,
    }


# ---------------------------------------------------------------------------
# Potential
# ---------------------------------------------------------------------------
def gen_potential(d):
    p = d["potential"]
    grades = ["Grade1", "Grade2", "Grade3", "Grade4", "Grade5", "Grade6"]
    gradeup = {}
    for cube in ("miracle", "additional"):
        gradeup[cube] = [{"prob": x["gradeUpProb"], "pity": x["pityRolls"], "meso": x["mesoPerRoll"],
                          "cubes": x["cubesPerRoll"]} for x in p["gradeUp"][cube]]
        assert [x["grade"] for x in p["gradeUp"][cube]] == grades
    pools = {}
    for part, gs in p["optionPools"].items():
        pools[part] = []
        for g in grades:
            lines = []
            for ln in ("line1", "line2", "line3"):
                rows = gs[g][ln]
                assert sum(r[2] for r in rows) == p["probabilityScale"], (part, g, ln)
                lines.append([[r[0], r[1], r[2]] for r in rows])
            pools[part].append(lines)
    return {
        "scale": p["probabilityScale"],
        "gradeNames": [p["gradeLabels"][g] for g in grades],
        "partNames": p["partLabels"],
        "gradeUp": gradeup,
        "pools": pools,
    }


# ---------------------------------------------------------------------------
# Scrolls (주문서 강화) and enchant (마법 부여)
# ---------------------------------------------------------------------------
# row index in equipmentScrolls31 -> (key, cost item or None for spell-trace scrolls, slot restriction)
SCROLL_KEYS = [
    ("lv35_70", None), ("lv35_30", None), ("lv65_70", None), ("lv65_30", None),
    ("lv85_70", None), ("lv85_30", None), ("lv85_15", None),
    ("lv105_70", None), ("lv105_30", None), ("lv105_15", None),
    ("lv115_70", None), ("lv115_30", None), ("lv115_15", None),
    ("normal40", "scrollNormal"), ("rare40", "scrollRare"), ("rare25", "scrollRare25"),
    ("epic70", "scrollEpic"), ("epic30", "scrollEpic30"), ("epic15", "scrollEpic15"),
    ("zakum1", "scrollZakum1"), ("zakum2", "scrollZakum2"), ("horntail1", "scrollHorntail1"),
    ("horntail2", "scrollHorntail2"), ("pinkbean1", "scrollPinkBean1"), ("pinkbean2", "scrollPinkBean2"),
    ("bruce1", "scrollBruce1"), ("bruce2", "scrollBruce2"), ("bruce3", "scrollBruce3"),
    ("mystery", "scrollMystery"), ("certainty", "scrollCertainty"), ("innocent", None),
]
SCROLL_STAT_COLS = [(2, "Attack"), (3, "MainStat"), (4, "MaxHp"), (5, "AttackPower2")]  # 데미지 증폭 -> AttackPower2


def clean_name(n):
    n = n.replace("1번 슬롯 전용", "").replace("10번 슬롯 전용", "").replace("과거 이벤트", "")
    return n.strip()


ENCHANT_STATS = {
    "공격력": ("Attack", False), "최대 HP": ("MaxHp", False), "방어력": ("Defence", False),
    "최대 MP%": ("MaxMpR", True), "명중": ("HitChance", False), "회피": ("AvoidChance", False),
    "크리티컬 확률": ("CriticalChance", True), "크리티컬 데미지": ("CriticalPower", True),
    "보스 몬스터 데미지": ("AttackPowerToBoss", True), "일반 몬스터 데미지": ("AttackPowerExcludeBoss", True),
    "1차 스킬 레벨": ("JobStep1SkillLevel", False), "2차 스킬 레벨": ("JobStep2SkillLevel", False),
    "3차 스킬 레벨": ("JobStep3SkillLevel", False), "4차 스킬 레벨": ("JobStep4SkillLevel", False),
    "데미지": ("AttackPower", True), "최소 데미지 배율": ("MinDamageRatio", True),
    "최대 데미지 배율": ("MaxDamageRatio", True), "스킬 데미지": ("SkillPower", True),
    "방어 관통력": ("PiercePower", True), "기본 공격 데미지": ("BaseAttackPower", True),
    "최종 데미지": ("FinalDamage", True), "모든 스킬 레벨": ("AllSkillLevel", False), "주 스탯%": ("MainStatR", True),
}
ENCHANT_GRADES = ["레어", "에픽", "유니크", "레전드리", "레전드리+", "미스틱", "미스틱+"]
POUCH_KEYS = {"하급 마법 부여 주머니": "enchantPouch", "중급 마법 부여 주머니": "enchantPouchMid",
              "상급 마법 부여 주머니": "enchantPouchHigh", "최상급 마법 부여 주머니": "enchantPouchTop"}


def gen_scrolls(d):
    s = d["scrolls"]
    rows = s["equipmentScrolls31"]["rows"]
    assert len(rows) == len(SCROLL_KEYS) == 31
    lst = []
    for row, (key, item) in zip(rows, SCROLL_KEYS):
        e = {"key": key, "name": clean_name(row[0])}
        if key == "innocent":
            m = re.search(r"주문의 흔적 ([\d,]+)개", row[6])
            e["innocent"] = True
            e["cost"] = {"spellTrace": flat(m.group(1))}
            lst.append(e)
            continue
        e["rate"] = int(round(float(row[1].rstrip("%")) * 10))  # per mille
        stats = {}
        if key not in ("mystery", "certainty"):
            for col, stat in SCROLL_STAT_COLS:
                v = row[col]
                if v in ("—", "-", ""):
                    continue
                stats[stat] = pct_raw(v) if v.endswith("%") else flat(v)
        e["stats"] = stats
        if item:
            e["item"] = item
        else:
            m = re.search(r"주문의 흔적 ([\d,]+)개/시도", row[6])
            e["spellTrace"] = flat(m.group(1))
        lv = re.match(r"(\d+)레벨", row[0])
        if lv and int(lv.group(1)) != 35:     # 35레벨 has no character level requirement (rules.levelReq)
            e["levelReq"] = int(lv.group(1))
        if key == "mystery":
            e["onlySlot"] = 1
        if key == "certainty":
            e["onlySlot"] = 10
        lst.append(e)

    def rolls(tbl, cols):
        out = []
        for r in tbl["rows"]:
            st = {}
            for i, stat in cols:
                st[stat] = pct_raw(r[i]) if r[i].endswith("%") else flat(r[i])
            out.append({"prob": pct_raw(r[0]), "stats": st})  # prob per mille
        assert sum(x["prob"] for x in out) == 1000
        return out

    mystery = rolls(s["mysteryScrollValueRolls"], [(1, "Attack"), (2, "MaxHp"), (3, "AttackPower2")])
    certainty = rolls(s["certaintyScrollValueRolls"], [(1, "MainStat"), (2, "MaxHp"), (3, "AttackPower2")])

    # 강화 던전 drop: first 10% roll, then grade split; values are the final per-type percent
    drops = []
    for r in s["enhanceDungeonDropPercent"]["rows"]:
        band = r[0]
        lo, hi = (int(band), int(band)) if "~" not in band else map(int, band.split("~"))
        normal = float(r[1].rstrip("%"))
        rare = float(r[2].rstrip("%"))
        # epic column is rounded ("≈0.1667%"): exact value is the remainder of the 10% split into 3 types
        epic = round((10.0 - normal - 2 * rare) / 3, 10)
        drops.append({"from": lo, "to": hi, "pct": {"normal40": normal, "rare40": rare, "rare25": rare,
                                                    "epic70": epic, "epic30": epic, "epic15": epic}})

    ench = []
    for r in s["enchant"]["scrolls127"]["rows"]:
        cat, grade, rate, statname, rng, meso, req = r
        stat, ispct = ENCHANT_STATS[statname]
        lo, hi = [x.strip() for x in rng.split("–")]
        conv = pct_raw if ispct else flat
        e = {"cat": cat, "grade": ENCHANT_GRADES.index(grade) + 1, "rate": pct_raw(rate),
             "stat": stat, "min": conv(lo), "max": conv(hi), "meso": flat(meso)}
        if req != "별도 등급 조건 없음":
            assert req == "유니크 · 티어 1 이상", req
            e["minGearGrade"] = 4      # Grade4 (유니크) or better, any tier
        ench.append(e)
    assert len(ench) == 127
    pouches = []
    for r in s["enchant"]["pouchGradePercent"]["rows"]:
        odds = [pct_raw(x) for x in r[1:]]       # per mille: 레어, 에픽, 유니크, 레전드리, 미스틱
        assert sum(odds) == 1000
        pouches.append({"key": POUCH_KEYS[r[0]], "name": r[0], "odds": odds})
    return {
        "slots": 10,
        "slotBonus": {5: 100, 10: 200},   # per mille (+10%p / +20%p), final rate capped at 100%
        "list": lst,
        "mysteryRolls": mystery,
        "certaintyRolls": certainty,
        "dungeonDrop": {"chancePct": 10, "bands": drops},
        "enchant": {
            "unlockStage": "14-10",
            "gradeNames": ENCHANT_GRADES,
            "pouchGrades": [1, 2, 3, 4, 6],   # pouch columns 레어, 에픽, 유니크, 레전더리, 미스틱 -> grade index
            "scrolls": ench,
            "pouches": pouches,
        },
    }


# ---------------------------------------------------------------------------
# Hero power (용사의 힘) and ability (어빌리티)
# ---------------------------------------------------------------------------
def gen_heropower(d):
    h = d["heroPower"]
    stages = []
    for st in h["stages"]:
        slots = []
        for sl in st["slots"]:
            assert [x[0] for x in sl["levels"]] == list(range(1, sl["maxLevel"] + 1))
            slots.append({"type": sl["type"], "label": sl["label"], "base": sl["baseValue"], "maxLevel": sl["maxLevel"],
                          "values": [x[1] for x in sl["levels"]], "costs": [x[2] for x in sl["levels"]]})
        stages.append({
            "stage": st["stage"], "waitSec": st["baseUpgradeSecondsToReach"], "stageCost": st["stageCost"],
            "bonus": [[b["type"], b["value"]] for b in st["stageBonus"]],
            "slots": slots,
        })
    return {"stages": stages, "maxStage": len(stages)}


ABILITY_STATS = {
    "mainFlat": ("MainStat", False), "maxHp": ("MaxHp", False), "maxMp": ("MaxMp", False),
    "hit": ("HitChance", False), "evasion": ("AvoidChance", False), "mpRecovery": ("MpRegen", False),
    "damage": ("AttackPower", True), "debuffResist": ("DebuffResist", False),
    "minDamage": ("MinDamageRatio", True), "maxDamage": ("MaxDamageRatio", True),
    "critRate": ("CriticalChance", True), "criticalResist": ("CriticalResist", True),
    "attackSpeed": ("AttackSpeed", True), "damageReduction": ("Toughness", True),
    "mesoGain": ("BonusGoldPercent", True), "expGain": ("BonusExpPercent", True),
    "defPen": ("PiercePower", True), "bossDamage": ("AttackPowerToBoss", True),
    "normalDamage": ("AttackPowerExcludeBoss", True),
}


def gen_ability(d):
    a = d["ability"]
    levels = []
    for l in a["levels"]:
        levels.append({"exp": l["expToNext"], "cost": l["medalsPerConversionByLockedLines"],
                       "weights": [l["gradeWeightsPer10000"][g] for g in a["grades"]]})
        assert sum(levels[-1]["weights"]) == 10000
    opts = []
    for o in a["options"]:
        stat, pct = ABILITY_STATS[o["statKey"]]
        conv = (lambda v: int(round(v * 10))) if pct else int
        opts.append({"grade": o["grade"], "stat": stat, "name": o["name"], "min": conv(o["tableMin"]),
                     "max": conv(o["tableMax"])})
    for g, n in a["optionCountPerGrade"].items():
        assert sum(1 for o in opts if o["grade"] == int(g)) == n
    return {
        "maxLevel": len(levels), "maxSlots": a["maxSlots"], "gradeNames": a["grades"],
        "levels": levels, "options": opts,
        "slotUnlockStage": [s["heroPowerStage"] for s in a["slotUnlocks"]],
    }


# ---------------------------------------------------------------------------
# Artifacts (유물)
# ---------------------------------------------------------------------------
def gen_artifacts(d):
    a = d["artifacts"]
    skills = {}
    lst = []
    for x in a["artifacts"]:
        sk = {}
        for s in x["equipSkillsByAwakening"]:
            rec = {"SkillIndex": s["skillIndex"], "TriggerType": s["trigger"], "TriggerRatio": s["triggerRatio"],
                   "SkillTargetType": s["target"], "TargetCount": 1, "Operations": s["operations"],
                   "nameKo": x["nameKo"], "isArtifact": True}
            if s["triggerTimeMs"]:
                rec["TriggerTimeMs"] = s["triggerTimeMs"]
            if s["coolTimeMs"]:
                rec["CoolTimeMs"] = s["coolTimeMs"]
            skills[s["skillIndex"]] = rec
            sk[s["awakening"]] = s["skillIndex"]
        inv = GLOBAL["artifactInventory"][x["code"]]
        lst.append({"id": x["id"], "code": x["code"], "grade": int(x["gradeType"][-1]), "name": x["nameKo"],
                    "skills": sk, "inventory": inv})
    return {
        "list": lst,
        "skills": skills,
        "excluded": a["runtimeRules"]["excludedIds"],
        "presets": a["equipPresets"],
        "macros": a["macros"],
        # 유물상자 (KR, mekipick relic simulator): grade split per 1,000,000, equal share inside a grade
        "chestGradeOdds": {3: 895000, 4: 95000, 5: 10000},
        "resonanceCost": GLOBAL["resonanceCost"],
        "resonanceBaseMax": 50, "resonancePerAwakening": 10,
        # KR guide (inven 6554/462, 2026-09-15): slot 2 at total awakening 10, slot 3 at 30, slot 4 at 50
        "slotUnlockAwakening": [0, 10, 30, 50],
        "maxAwakening": 5,
    }


# ---------------------------------------------------------------------------
# Journey (여정의 보물 / 여정의 상자 / 여정의 발자취)
# ---------------------------------------------------------------------------
def gen_journey(d):
    j = d["journeyTreasure"]
    c = j["constants"]
    levels = [big(x[1]) for x in j["levelExpToNextReward"]]
    assert [x[0] for x in j["levelExpToNextReward"]] == list(range(1, 1001))
    stage_exp = {}
    for ch, st, e in j["stageKillExp"]:
        stage_exp.setdefault(ch, {})[st] = big(e)
    accel = [{"prob": o["probabilityPermille"], "gauge": int(round(o["gaugePercentPoints"] * 10))}
             for o in c["weeklyAcceleration"]["outcomes"]]   # gauge in per mille of one level
    return {
        "treasure": {
            "expRate": float(c["expRate"]),
            "maxStored": c["stackableRewardCount"],
            "levelExp": levels,
            "stageExp": stage_exp,
            "unlockChapter": min(stage_exp),
            "offlineKillsPerSecond": c["offlineKillsPerSecond"],
            "weeklyAccelUses": c["weeklyAcceleration"]["adUses"],   # premium extra use removed (paid)
            "weeklyAccel": accel,
            # reward cards (KR inven 6554/596·625 + maplestoryidle.info 1.14.0 tables): steps 1..5
            "cards": [
                {"key": "starforceScroll", "amounts": [20, 24, 28, 32, 40]},
                {"key": "cubeMiracle", "amounts": [10, 12, 14, 16, 20]},
                {"key": "spellTrace", "amounts": [15000, 18000, 21000, 24000, 30000]},
                {"key": "meso", "amounts": [4000000, 4800000, 5600000, 6400000, 8000000]},
            ],
            "maxCardStep": 5,
        },
        "chest": {
            "tokens": GLOBAL["journeyChestTokens"],
            "keysPerWeek": 5, "keyCap": 5, "maxKeysPerOpen": 10,
            "blessings": 7, "freeResetsPerDay": 1,
            "blessBonus": [0, 50, 100],          # per mille of the chest reward (회색 +0, 노랑 +5%, 빨강 +10%)
            # transition table (maplestoryidle.info, 1.14.0 tables): row = previous blessing (0 = first)
            "blessOdds": {0: [600, 300, 100], 1: [400, 500, 100], 2: [600, 300, 100], 3: [670, 300, 30]},
        },
        "trail": {
            "chapters": GLOBAL["journeyTrail"],
            "gradeNames": ["노말", "레어", "에픽", "유니크", "레전드리", "미스틱", "미스틱+"],
            "gradeOdds": [400, 300, 220, 40, 25, 13, 2],   # per mille
            "specialMinGrade": 4,
            "maxLocks": 1,
        },
    }


def main():
    d = load("items-gacha.json")
    labels, display = stat_tables(d)
    data = [
        ("D.StatLabelsKo", labels, None),
        ("D.StatDisplay", display, None),
        ("D.GearGradeLadder", d["equipment"]["gradeLadder"], None),
        ("D.StarForce", gen_starforce(d), {"indent": " "}),
        ("D.Potential", gen_potential(d), None),
        ("D.Scrolls", gen_scrolls(d), {"indent": " "}),
        ("D.HeroPower", gen_heropower(d), {"indent": " "}),
        ("D.Ability", gen_ability(d), {"indent": " "}),
        ("D.Artifacts", gen_artifacts(d), None),
        ("D.Journey", gen_journey(d), None),
    ]
    with open(OUT, "w", encoding="utf-8") as f:
        f.write("-- GENERATED by tools/gen_upgrades.py from research/spec/items-gacha.json. Do not edit by hand.\n")
        f.write("-- Probabilities: StarForce/Potential per 1,000,000; Scrolls/Ability/Journey per 1,000 (or 10,000 where noted).\n")
        f.write("-- Percent stats are raw 0.1% units (1000 = 100%).\n")
        f.write("local ADDON, ns = ...\nns.Data = ns.Data or {}\nlocal D = ns.Data\n")
        for lhs, value, opts in data:
            opts = opts or {}
            f.write("%s = %s\n" % (lhs, to_lua(value, opts.get("indent"), 0, opts.get("bignum", False))))
    print("ok", OUT, os.path.getsize(OUT))


if __name__ == "__main__":
    main()
