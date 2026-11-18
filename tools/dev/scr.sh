#!/bin/bash
# /tmp/scr.sh NAME args...   -> /tmp/scr_NAME.log (+ "done" line)
n=$1; shift
cd /home/claude/yugioh-crossroads
(timeout 400 godot --headless --rendering-driver opengl3 --path . -- --assets=/tmp/testassets2 --duel "$@" > /tmp/scr_$n.log 2>&1; echo "done $?" >> /tmp/scr_$n.log) &
