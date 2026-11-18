#!/bin/sh
cd /home/claude/yugioh-crossroads
timeout 200 godot --headless --import >/dev/null 2>&1
timeout 120 godot --headless --rendering-driver opengl3 -- --parse-all 2>&1 | grep -E "Parse Error|PARSE|Compile Error" -A1 | grep -v "^--" | head -12
