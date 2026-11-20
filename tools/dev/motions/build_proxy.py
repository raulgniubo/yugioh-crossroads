# Mannequins with the exact skeleton and proportions of Raul's real models, made from numbers only
# (real.json: joint rest matrices + the box of each joint's own vertices). One box per joint.
import json, struct, sys, os, numpy as np
R = json.load(open(sys.argv[1])); OUT = sys.argv[2]; os.makedirs(OUT, exist_ok=True)
def quat(m):
    t = np.trace(m)
    if t > 0:
        s = np.sqrt(t + 1.0) * 2; w = 0.25 * s; x = (m[2,1]-m[1,2])/s; y = (m[0,2]-m[2,0])/s; z = (m[1,0]-m[0,1])/s
    elif m[0,0] > m[1,1] and m[0,0] > m[2,2]:
        s = np.sqrt(1.0 + m[0,0] - m[1,1] - m[2,2]) * 2; w = (m[2,1]-m[1,2])/s; x = 0.25*s; y = (m[0,1]+m[1,0])/s; z = (m[0,2]+m[2,0])/s
    elif m[1,1] > m[2,2]:
        s = np.sqrt(1.0 + m[1,1] - m[0,0] - m[2,2]) * 2; w = (m[0,2]-m[2,0])/s; x = (m[0,1]+m[1,0])/s; y = 0.25*s; z = (m[1,2]+m[2,1])/s
    else:
        s = np.sqrt(1.0 + m[2,2] - m[0,0] - m[1,1]) * 2; w = (m[1,0]-m[0,1])/s; x = (m[0,2]+m[2,0])/s; y = (m[1,2]+m[2,1])/s; z = 0.25*s
    q = np.array([x, y, z, w]); return (q / np.linalg.norm(q)).tolist()
FACES = [([0,1,3,2],(-1,0,0)), ([4,6,7,5],(1,0,0)), ([0,4,5,1],(0,-1,0)), ([2,3,7,6],(0,1,0)), ([0,2,6,4],(0,0,-1)), ([1,5,7,3],(0,0,1))]
def box(corners):   # 8 world corners indexed by bits x(4) y(2) z(1) -> verts, normals, indices
    v = []; n = []; ix = []
    for quad, _ in FACES:
        p = [corners[i] for i in quad]; nn = np.cross(p[1]-p[0], p[2]-p[0]); nn = nn / max(np.linalg.norm(nn), 1e-9)
        b = len(v); v += p; n += [nn]*4; ix += [b, b+1, b+2, b, b+2, b+3]
    return v, n, ix
MATS = {"body": [0.36,0.42,0.55,1], "arm": [0.56,0.64,0.79,1], "head": [0.91,0.79,0.63,1], "face": [1.0,0.83,0.0,1], "hand": [1.0,0.31,0.19,1], "leg": [0.25,0.28,0.38,1]}
def kind(n):
    if n in ("LeftHand","RightHand"): return "hand"
    if "Arm" in n or "Shoulder" in n: return "arm"
    if n in ("Head","head_end","headfront","neck"): return "head"
    if "Leg" in n or "Foot" in n or "Toe" in n: return "leg"
    return "body"
for r in R:
    if "bones" not in r: continue
    bones = r["bones"]; idx = {b["n"]: i for i, b in enumerate(bones)}
    G = [np.vstack([np.array(b["g"]).reshape(3,4), [0,0,0,1]]) for b in bones]
    A = np.diag([0.01,0.01,0.01,1.0])
    nodes = []
    for i, b in enumerate(bones):
        pg = G[idx[b["p"]]] if b["p"] in idx else A
        L = np.linalg.inv(pg) @ G[i]
        rot = L[:3,:3]; sc = np.linalg.norm(rot, axis=0); rot = rot / sc
        nodes.append({"name": b["n"], "translation": L[:3,3].tolist(), "rotation": quat(rot), "scale": [1,1,1], "children": [j for j, c in enumerate(bones) if c["p"] == b["n"]]})
        if not nodes[-1]["children"]: del nodes[-1]["children"]
    prims = {k: ([], [], [], []) for k in MATS}   # verts, normals, joints, indices
    def add(kd, corners, j):
        v, n, ix = box(corners); P = prims[kd]; base = len(P[0])
        P[0].extend(v); P[1].extend(n); P[2].extend([j]*len(v)); P[3].extend([base + i for i in ix])
    for i, b in enumerate(bones):
        if "lo" not in b: continue
        lo = np.array(b["lo"]); hi = np.array(b["hi"])
        cs = [(G[i] @ np.array([hi[0] if k & 4 else lo[0], hi[1] if k & 2 else lo[1], hi[2] if k & 1 else lo[2], 1.0]))[:3] for k in range(8)]
        add(kind(b["n"]), cs, i)
    hb = bones[idx["Head"]]; hx = G[idx["Head"]][0,3]
    chin = hb["wlo"][1]; zf = hb["whi"][2]
    lo = np.array([hx - 0.11, chin + 0.02, zf - 0.005]); hi = np.array([hx + 0.11, chin + 0.26, zf + 0.012])
    add("face", [np.array([hi[0] if k & 4 else lo[0], hi[1] if k & 2 else lo[1], hi[2] if k & 1 else lo[2]]) for k in range(8)], idx["Head"])
    buf = bytearray(); views = []; accs = []
    def push(arr, target=None):
        while len(buf) % 4: buf.extend(b"\x00")
        views.append({"buffer": 0, "byteOffset": len(buf), "byteLength": arr.nbytes, **({"target": target} if target else {})})
        buf.extend(arr.tobytes()); return len(views) - 1
    def accessor(arr, typ, ct, target=None, mm=False):
        a = {"bufferView": push(arr, target), "componentType": ct, "count": len(arr), "type": typ}
        if mm: a["min"] = arr.min(0).tolist(); a["max"] = arr.max(0).tolist()
        accs.append(a); return len(accs) - 1
    gprims = []; mats = []
    for kd, (v, n, j, ix) in prims.items():
        if not v: continue
        va = np.array(v, dtype=np.float32); na = np.array(n, dtype=np.float32)
        ja = np.zeros((len(v), 4), dtype=np.uint16); ja[:,0] = j
        wa = np.zeros((len(v), 4), dtype=np.float32); wa[:,0] = 1
        mats.append({"name": kd, "doubleSided": True, "pbrMetallicRoughness": {"baseColorFactor": MATS[kd], "metallicFactor": 0, "roughnessFactor": 0.8}})
        gprims.append({"attributes": {"POSITION": accessor(va, "VEC3", 5126, 34962, True), "NORMAL": accessor(na, "VEC3", 5126, 34962), "JOINTS_0": accessor(ja, "VEC4", 5123, 34962), "WEIGHTS_0": accessor(wa, "VEC4", 5126, 34962)},
                       "indices": accessor(np.array(ix, dtype=np.uint32), "SCALAR", 5125, 34963), "material": len(mats) - 1})
    ibm = np.stack([np.linalg.inv(g).T for g in G]).astype(np.float32).reshape(-1, 16)
    ia = accessor(ibm, "MAT4", 5126)
    nb = len(bones)
    nodes.append({"name": "char1", "mesh": 0, "skin": 0})
    nodes.append({"name": "Armature", "scale": [0.01,0.01,0.01], "children": [idx["Hips"], nb]})
    js = {"asset": {"version": "2.0", "generator": "crossroads proxy"}, "scene": 0, "scenes": [{"name": "Scene", "nodes": [nb + 1]}], "nodes": nodes,
          "meshes": [{"name": "char1", "primitives": gprims}], "materials": mats, "skins": [{"name": "Armature", "inverseBindMatrices": ia, "joints": list(range(nb))}],
          "accessors": accs, "bufferViews": views, "buffers": [{"byteLength": len(buf)}]}
    jb = json.dumps(js).encode(); jb += b" " * ((4 - len(jb) % 4) % 4)
    while len(buf) % 4: buf.extend(b"\x00")
    out = struct.pack("<III", 0x46546C67, 2, 12 + 8 + len(jb) + 8 + len(buf)) + struct.pack("<II", len(jb), 0x4E4F534A) + jb + struct.pack("<II", len(buf), 0x004E4942) + bytes(buf)
    open(os.path.join(OUT, r["file"]), "wb").write(out)
print("made", len([r for r in R if "bones" in r]))
