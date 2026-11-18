#!/bin/bash
# The one command after adding cards (a family in Collection.FAMILIES, a single card in
# CardPool.ADDED, a deck in CardData.NAMED_DECKS): repack the rules engine's data for every card
# the game names now, then check every card and every family (tests/card_check.gd), then play the
# hand-made positions (tests/card_positions.gd).
#   tools/cards.sh <BabelCDB folder> <CardScripts folder> <Distribution folder>
# Prints the problems, if any. Exit code 0 means there are none.
set -e
cd "$(dirname "$0")/.."
DB=${1:-/home/claude/probe/BabelCDB}; SC=${2:-/home/claude/probe/CardScripts}; DI=${3:-/home/claude/probe/Distribution}
godot --headless --import > /dev/null 2>&1 || true
godot --headless res://tests/ocg_sim.tscn -- ids /tmp/ocg_ids.txt 2>&1 | grep "^ids" 
python3 tools/make_ocg_data.py "$DB" "$SC" "$DI" /tmp/ocg_ids.txt | tail -1
python3 tools/script_refs.py "$SC" /tmp/ocg_ids.txt /tmp/refs.json
godot --headless res://tests/card_check.tscn -- /tmp/card_check.txt 2>&1 | grep "CARD CHECK\|PROBLEM\|note:"
# Hand-made positions for the cards random duels never get to play (tests/card_positions.json).
godot --headless res://tests/card_positions.tscn 2>&1 | grep "CARD POSITIONS\|NOT OK\|??\|^open\|^never"
