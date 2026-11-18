#!/bin/sh
# /tmp/scan.sh key codes regex [-t]
cd /home/claude/yugioh-crossroads
python3 tools/family_scan.py /home/claude/probe /tmp/testassets2/cards.json /tmp/ocg_ids.txt "$1" "$2" "$3" /tmp/fam_extra_$1.json $4
