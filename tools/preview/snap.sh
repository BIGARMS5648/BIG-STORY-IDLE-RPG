#!/bin/sh
# Render a screen of the addon to PNG: sh tools/preview/snap.sh <panel|main> <out.png> [jobKey]
set -e
tmp="${3:-hero}"
txt="${2%.png}.txt"
out=$(lua5.1 tools/preview/shot.lua "$1" "$txt" "$tmp" | tail -1)
crop=$(echo "$out" | sed -n 's/.*crop \([-0-9,]*\).*/\1/p')
python3 tools/preview/render.py "$txt" "$2" --crop "$crop" | tail -1
