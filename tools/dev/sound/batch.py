# python3 batch.py N -> /tmp/sb_N.json: the updates for creative_update_flow_nodes (batch N = sounds 20N .. 20N+19)
import json, sys
n = int(sys.argv[1]); kind = sys.argv[2] if len(sys.argv) > 2 else "sounds"
spec = json.load(open("sounds.json"))[kind]; fl = json.load(open("flow.json"))
part = spec[20 * n: 20 * n + 20]
ups = [{"node_id": fl["nodes"][i], "label": s[0], "prompt": s[2], "model_parameters": {"duration_seconds": s[1], "prompt_influence": 0.5, "loop": kind == "ambience"}} for i, s in enumerate(part)]
print(json.dumps({"updates": ups, "run": fl["nodes"][:len(part)], "names": [s[0] for s in part]}))
