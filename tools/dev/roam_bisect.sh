#!/bin/bash
# tools/dev/roam_bisect.sh <district> [ROAM_SKIP list]   -> how much main-thread time the first seconds in a world cost
# Headless (nothing is drawn): every slow frame is the game's own work. Prints: frames over 60 ms and the time over
# 16 ms per frame, summed, for the first 8 s after the world is built.
d=${1:-domino}; skip=$2; tag=${skip:-all}; tag=${tag//,/_}
cd /home/claude/yc_test
H=/tmp/pB_$tag; if [ -z "$KEEP" ] && [ "$tag" != "all" ]; then rm -rf $H; cp -r /tmp/pB_all $H; fi; mkdir -p $H
FRAME_LOG_MS=1 ROAM_SKIP=$skip HOME=$H XDG_DATA_HOME=$H/.local/share timeout ${T:-75} godot --headless --path . -- --assets=/tmp/realfit --lang=es --skip-opening --roam --district=$d --frame-log $EXTRA > /tmp/bis_$tag.txt 2>&1
python3 - "$tag" <<'P'
import re,sys
tag=sys.argv[1]; rows=[]
for l in open('/tmp/bis_%s.txt'%tag):
    m=re.match(r'SLOWFRAME (\d+) ms  t=([\d.]+)  n=(\d+) busy=(\w+) .*nodes (\d+)',l)
    if m: rows.append((int(m[1]),float(m[2]),int(m[3]),m[4],int(m[5])))
start=next((i for i,r in enumerate(rows) if r[3]=='false' and r[4]>2000),None)
if start is None: print(tag,'never got there'); sys.exit()
t0=rows[start][1]; w=[r for r in rows[start:] if r[1]-t0<=8.0]
over=sum(max(0,r[0]-16) for r in w); big=[r[0] for r in w if r[0]>60]
print('%-28s build %5.1fs  frames %4d  over-16ms total %5d ms  >60ms: %2d  worst %s' % (tag, rows[start-1][0]/1000 if start else 0, len(w), over, len(big), sorted(big,reverse=True)[:8]))
P
