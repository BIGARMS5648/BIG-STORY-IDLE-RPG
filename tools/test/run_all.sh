#!/bin/sh
# Runs every headless test (from the repository root): sh tools/test/run_all.sh
set -e
for f in $(find BigStoryIdleRPG -name '*.lua'); do luac5.1 -p "$f"; done
echo "syntax ok"
lua5.1 tools/test/test_expr.lua | tail -1
lua5.1 tools/test/test_skills_lv140.lua | tail -1
lua5.1 tools/test/test_battle.lua | tail -1
lua5.1 tools/test/test_items.lua | tail -1
lua5.1 tools/test/test_upgrades.lua | tail -1
lua5.1 tools/test/test_comm.lua | tail -1
lua5.1 tools/test/test_game.lua hero | tail -2
lua5.1 tools/test/test_progression.lua nightLord | tail -1
lua5.1 tools/test/test_arena.lua | tail -1
lua5.1 tools/test/test_income.lua | tail -1
lua5.1 tools/test/test_ui.lua 4 | tail -1
