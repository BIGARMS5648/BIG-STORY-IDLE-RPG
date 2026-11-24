#!/usr/bin/env python3
"""Generate BigStoryIdleRPG/Data/GrowthRewards.lua: per-stage clear rewards of the growth dungeons.

Rules (KR in-game, provided by the user 2026-11-24; 용사의 수련장 also matches the global 1.14 table):
  무기 던전      stage s: 무기 소환권 10 + s, 무기 강화석 1700 + 300 s   (s1: 11 / 2,000; s10: 20 / 4,700)
  장비 던전      stage s: 엘리트 몬스터 소환 포인트 190 + 10 s          (s1: 200)
  용사의 수련장  stage s: 용사의 증표 240 + 10 s                        (s1: 250)
  강화 던전      stage s: 주문의 흔적 150 + 5 s (s1: 155) + 의문의 주문서 (low chance, independent)
  경험치 던전    client sweep table (already exact; matches the in-game % of the Lv72 requirement)
  All dungeons: each first clear gives 1 entry ticket of that dungeon; every 10th stage's first
  clear also pays 5x that stage's reward (e.g. 무기 던전 40: 250 / 68,500).

Usage: python3 -I tools/gen_growth_rewards.py
"""
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
from luagen import write_lua  # noqa: E402

ROOT = os.path.dirname(HERE)
OUT = os.path.join(ROOT, "BigStoryIdleRPG", "Data", "GrowthRewards.lua")
STAGES = 160   # cap raised to 160 on 2026-11-26 (research/maple_idle_database)


def main():
    r = {"weapon": {}, "gear": {}, "training": {}, "enhance": {}}
    for s in range(1, STAGES + 1):
        r["weapon"][s] = {"weaponTicket": 10 + s, "weaponStone": 1700 + 300 * s}
        r["gear"][s] = {"eliteSummonPoint": 190 + 10 * s}
        r["training"][s] = {"heroToken": 240 + 10 * s}
        r["enhance"][s] = {"spellTrace": 150 + 5 * s}
    assert r["weapon"][10] == {"weaponTicket": 20, "weaponStone": 4700}
    assert r["weapon"][40]["weaponTicket"] * 5 == 250 and r["weapon"][40]["weaponStone"] * 5 == 68500
    write_lua(OUT, [
        ("D.ContentGrowthRewards", r, None),
        ("D.ContentGrowthFirstClear", {"keys": 1, "every": 10, "multiplier": 5}, None),
    ], note="Growth-dungeon clear rewards (KR in-game rules, see tools/gen_growth_rewards.py).")
    print("ok: %d stages x 4 dungeons" % STAGES)


if __name__ == "__main__":
    main()
