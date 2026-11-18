#!/bin/bash
# shot2.sh <name> <after seconds> args...  -> /tmp/sh_<name>.png   (software rendering runs about 4x slower than the clock: allow after*5+60 s)
n=$1; a=$2; shift; shift
cd /home/claude/yugioh-crossroads; rm -f ~/.local/share/Crossroads/running.txt
timeout $((a*5+60)) xvfb-run -a -s "-screen 0 1920x1080x24" godot --rendering-driver opengl3 --path . -- --assets=/tmp/testassets2 --duel --skip-opening --first=me --shot=/tmp/sh_$n.png --after=$a "$@" > /tmp/sh_$n.log 2>&1
echo "$n errors: $(grep -c 'SCRIPT ERROR' /tmp/sh_$n.log)"
