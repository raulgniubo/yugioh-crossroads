#!/bin/sh
# /tmp/ship.sh VERSION [BRANCH] : export both builds, package, verify, push
V=$1
B=${2:-$(cd /home/claude/yugioh-crossroads && git branch --show-current)}
cd /home/claude/yugioh-crossroads
rm -rf build/mac/* build/windows/* "/tmp/Yu-Gi-Oh! Crossroads"
godot --headless --export-release "macOS" build/mac/Crossroads.zip > /tmp/exp_mac.log 2>&1
godot --headless --export-release "Windows" build/windows/Crossroads.exe > /tmp/exp_win.log 2>&1
cp build/mac/Crossroads.zip /mnt/user-data/outputs/Crossroads-v$V.zip
(cd build/windows && rm -f /mnt/user-data/outputs/Crossroads-v$V-windows.zip && zip -q -1 /mnt/user-data/outputs/Crossroads-v$V-windows.zip Crossroads.exe *.dll)
unzip -tq /mnt/user-data/outputs/Crossroads-v$V.zip | tail -1 > /tmp/ship.log
unzip -tq /mnt/user-data/outputs/Crossroads-v$V-windows.zip | tail -1 >> /tmp/ship.log
echo "mac export errors: $(grep -c '^ERROR' /tmp/exp_mac.log)  windows export errors: $(grep -c '^ERROR' /tmp/exp_win.log)" >> /tmp/ship.log
git push -q origin $B >> /tmp/ship.log 2>&1
echo "remote $(git ls-remote origin $B | cut -c1-7) local $(git rev-parse --short HEAD)" >> /tmp/ship.log
ls -la /mnt/user-data/outputs/Crossroads-v$V*.zip >> /tmp/ship.log
echo done > /tmp/ship.done
