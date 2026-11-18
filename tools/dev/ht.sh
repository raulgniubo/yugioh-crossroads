#!/bin/bash
# ht.sh name deck oppdeck [level]  -> /tmp/ht_<name>.log ; a headless duel where every pick (boxes, table, zones) is made at random
n=$1; cd /home/claude/yugioh-crossroads; rm -f ~/.local/share/Crossroads/running.txt
timeout 420 godot --headless --rendering-driver opengl3 --path . -- --assets=/tmp/testassets2 --duel --human-test --human-board --ocg-log --deck=$2 --oppdeck=$3 --ocg-level=${4:-0} > /tmp/ht_$n.log 2>&1
echo "$n: errors $(grep -c 'SCRIPT ERROR' /tmp/ht_$n.log) asked $(grep -c ' asked ' /tmp/ht_$n.log) $(grep 'OCG END' /tmp/ht_$n.log | cut -c1-90)"
