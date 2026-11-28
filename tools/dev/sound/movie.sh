#!/bin/bash
# /tmp/movie.sh <tag> <frames> <game args...>: runs the game writing its mixed sound to /tmp/mv/<tag>.wav (and a small film)
cd /home/claude/yc_test
tag=$1; frames=$2; shift 2
rm -rf /tmp/pMv; cp -r /tmp/pDeck /tmp/pMv; rm -f /tmp/mv/$tag.*
HOME=/tmp/pMv XDG_DATA_HOME=/tmp/pMv/.local/share timeout ${TMO:-900} xvfb-run -a -s "-screen 0 480x270x24" godot --path . --rendering-driver opengl3 --resolution 480x270 --write-movie /tmp/mv/$tag.avi --fixed-fps 20 --quit-after $frames -- --assets=/tmp/realfit --skip-opening "$@" > /tmp/mv/$tag.txt 2>&1
ls -la /tmp/mv/$tag.* 2>/dev/null | awk '{print $5, $9}'
grep -a "SCRIPT ERROR" -A2 /tmp/mv/$tag.txt | head -6
