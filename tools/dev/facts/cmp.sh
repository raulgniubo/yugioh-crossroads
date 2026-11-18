#!/bin/bash
cd /home/claude/yugioh-crossroads && timeout 300 godot --headless res://tests/facts_check.tscn 2>&1 | grep "FACTS\|SCRIPT ERROR" | head -5
python3 - <<'P'
import json
a=json.load(open('/tmp/facts/base.json')); b=json.load(open('/tmp/facts/now.json'))
bad=[k for k in a if a[k]!=b.get(k)]
print('FACTS SAME' if not bad else 'FACTS DIFFER in %s'%bad)
for k in bad[:3]:
    if isinstance(a[k],dict):
        d=[x for x in a[k] if a[k][x]!=b[k].get(x)][:5]; print(k,d,[ (a[k][x], b[k].get(x)) for x in d][:3])
    else:
        print(k, len(a[k]), len(b[k]), list(set(map(str,a[k]))^set(map(str,b[k])))[:8])
P
