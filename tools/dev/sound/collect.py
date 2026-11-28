# python3 collect.py N [kind] -> the sandbox command that files batch N's generations under their sound names
import json, sys
n = int(sys.argv[1]); kind = sys.argv[2] if len(sys.argv) > 2 else "sounds"
spec = json.load(open("sounds.json"))[kind]; fl = json.load(open("flow.json"))
part = spec[20 * n: 20 * n + 20]
lines = ["mkdir -p /workspace/all/%s" % kind]
for i, s in enumerate(part):
    lines.append('f=$(ls /workspace/in/%s.* 2>/dev/null | head -1); [ -n "$f" ] && cp "$f" "/workspace/all/%s/%s.${f##*.}" || echo MISSING %s' % (fl["nodes"][i], kind, s[0], s[0]))
lines.append('for f in /workspace/all/%s/*; do echo "$(basename $f) $(ffprobe -v error -show_entries format=duration -of csv=p=0 $f)"; done | tail -%d' % (kind, len(part)))
lines.append("ls /workspace/all/%s | wc -l" % kind)
lines.append("echo DUPES; md5sum /workspace/all/*/* | sort | uniq -w32 -D")
print(json.dumps({"inputs": [{"node_id": x} for x in fl["nodes"][:len(part)]], "command": "\n".join(lines)}))
