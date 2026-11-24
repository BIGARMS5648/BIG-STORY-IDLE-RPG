#!/usr/bin/env python3
"""Generate BigStoryIdleRPG/Data/GrowthRewards.lua from research/maple_idle_database/json.
Only stages with real (non-null) values are emitted; others fall back to the
PROVISIONAL formulas in Systems/ContentDungeons.lua.

Usage: python3 -I tools/gen_growth_rewards.py
"""
import json
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
from luagen import write_lua  # noqa: E402

ROOT = os.path.dirname(HERE)
DB = os.path.join(ROOT, "research", "maple_idle_database", "json")
OUT = os.path.join(ROOT, "BigStoryIdleRPG", "Data", "GrowthRewards.lua")

# (dataset file, dungeon key, wallet key, repeat field, first-clear field)
SETS = [
    ("hero_training_rewards.json", "training", "heroToken", "repeat_clear_hero_tokens", "first_clear_hero_tokens"),
    ("weapon_dungeon_rewards.json", "weapon", "weaponTicket", "repeat_clear_weapon_summon_tickets",
     "first_clear_weapon_summon_tickets"),
    ("equipment_dungeon_rewards.json", "gear", "eliteSummonPoint", "repeat_clear_elite_monster_summon_points",
     "first_clear_elite_monster_summon_points"),
    ("enhancement_dungeon_rewards.json", "enhance", "spellTrace", "repeat_clear_spell_traces", "first_clear_spell_traces"),
]


def main():
    rewards, first = {}, {}
    counts = {}
    for fname, key, wallet, rep, fc in SETS:
        with open(os.path.join(DB, fname), encoding="utf-8") as f:
            recs = json.load(f)["records"]
        for r in recs:
            st = r["stage"]
            if r.get(rep) is not None:
                rewards.setdefault(key, {})[st] = {wallet: r[rep]}
                counts[key] = counts.get(key, 0) + 1
            if r.get(fc):
                first.setdefault(key, {})[st] = {wallet: r[fc]}
    write_lua(OUT, [
        ("D.ContentGrowthRewards", rewards, None),
        ("D.ContentGrowthFirstClear", first, None),
    ], note="Growth-dungeon per-stage rewards with a published source (research/maple_idle_database).")
    print("stages with real rewards:", counts, "first-clear bonuses:", {k: len(v) for k, v in first.items()})


if __name__ == "__main__":
    main()
