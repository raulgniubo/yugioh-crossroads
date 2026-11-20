# A stand-in body re-shaped to the proportions of a real model: the stand-in's own mesh, moved bone by
# bone onto the real model's skeleton (longer arms, bigger head and hands). Needs only numbers from
# the real model (real.json). usage: refit.py standin.glb real.json key out.glb
import json, struct, sys, numpy as np
sys.argv_keep = sys.argv; 
exec(open(__file__.replace('refit.py', 'skel.py')).read().split("res = []")[0])
src, realp, key, outp = sys.argv[1:5]
real = [r for r in json.load(open(realp)) if r["file"] == key + ".glb"][0]
RB = {b["n"]: b for b in real["bones"]}
js, bn = load(src); bn = bytearray(bn)
nodes = js["nodes"]; par = {}
for i, nd in enumerate(nodes):
    for c in nd.get("children", []): par[c] = i
G = {}
def glob_(i):
    if i in G: return G[i]
    m = local(nodes[i])
    if i in par: m = glob_(par[i]) @ m
    G[i] = m; return m
for i in range(len(nodes)): glob_(i)
sk = js["skins"][0]; joints = sk["joints"]; names = [nodes[j]["name"] for j in joints]
def unit(m):
    r = m[:3, :3]; s = np.linalg.norm(r, axis=0); return r / s, m[:3, 3].copy()
OLD = [unit(G[j]) for j in joints]
NEW = [unit(np.vstack([np.array(RB[n]["g"]).reshape(3, 4), [0, 0, 0, 1]])) for n in names]
kids = {k: [c for c in range(len(joints)) if joints[c] in nodes[joints[k]].get("children", [])] for k in range(len(joints))}
# what the stand-in measures (its own vertex boxes), for the head and the hands
P = []; DOM = []; prims = []
ibm = acc(js, bn, sk["inverseBindMatrices"]).reshape(-1, 4, 4).transpose(0, 2, 1)
for nd in nodes:
    if "mesh" not in nd or "skin" not in nd: continue
    for pr in js["meshes"][nd["mesh"]]["primitives"]:
        at = pr["attributes"]
        v = acc(js, bn, at["POSITION"]); jn = acc(js, bn, at["JOINTS_0"]).astype(int); w = acc(js, bn, at["WEIGHTS_0"]).astype(np.float64)
        w = w / np.maximum(w.sum(1, keepdims=True), 1e-9)
        vh = np.concatenate([v, np.ones((len(v), 1))], 1); wp = np.zeros((len(v), 3))
        for c in range(4):
            Ms = np.stack([G[joints[j]] @ ibm[j] for j in range(len(joints))])[jn[:, c]]
            wp += w[:, c:c+1] * np.einsum("nij,nj->ni", Ms, vh)[:, :3]
        prims.append((at["POSITION"], wp, jn, w)); P.append(wp); DOM.append(jn[np.arange(len(v)), w.argmax(1)])
Pall = np.concatenate(P); Dall = np.concatenate(DOM)
def span(k, axis_world, origin):
    sel = Pall[Dall == k]
    return float(((sel - origin) @ axis_world).max()) if len(sel) else 0.0
A = []
for k, n in enumerate(names):
    Ro, oo = OLD[k]; Rn, on = NEW[k]
    ch = kids[k]
    t = 1.0; kk = 1.0; a = np.array([0.0, 1.0, 0.0])
    if ch and n not in ("Head", "Hips"):
        c = ch[0]
        co = Ro.T @ (OLD[c][1] - oo); cn = Rn.T @ (NEW[c][1] - on)
        if np.linalg.norm(co) > 1e-4:
            a = co / np.linalg.norm(co); kk = np.linalg.norm(cn) / np.linalg.norm(co)
            t = min(max(kk ** 0.35, 0.9), 1.2) if "Arm" in n or "Leg" in n else 1.0
    elif n == "Head":
        b = RB["Head"]; old_h = Pall[Dall == k][:, 1].max() - Pall[Dall == k][:, 1].min()
        kk = t = (b["whi"][1] - b["wlo"][1]) / max(old_h, 1e-4)
    elif n in ("LeftHand", "RightHand"):
        fo = OLD[names.index(n.replace("Hand", "ForeArm"))][1]; d = (oo - fo) / np.linalg.norm(oo - fo)
        old_len = span(k, d, oo); b = RB[n]
        new_len = max(abs(b["whi"][0] - np.array(b["g"]).reshape(3, 4)[0, 3]), abs(b["wlo"][0] - np.array(b["g"]).reshape(3, 4)[0, 3]))
        kk = t = new_len / max(old_len, 1e-4)
    S = t * np.eye(3) + (kk - t) * np.outer(a, a)
    M = np.eye(4); M[:3, :3] = Rn @ S @ Ro.T; M[:3, 3] = on - M[:3, :3] @ oo
    A.append(M)
A = np.stack(A)
# the new vertices, written back in place; the skeleton and its bind matrices become the real ones
def put(ai, arr):
    a = js["accessors"][ai]; bv = js["bufferViews"][a["bufferView"]]
    start = bv.get("byteOffset", 0) + a.get("byteOffset", 0); stride = bv.get("byteStride", 0)
    arr = arr.astype(np.float32); n = arr.shape[1]
    if stride and stride != 4 * n:
        for i in range(len(arr)): bn[start + i * stride:start + i * stride + 4 * n] = arr[i].tobytes()
    else:
        bn[start:start + arr.nbytes] = arr.tobytes()
    if "min" in a: a["min"] = arr.min(0).tolist(); a["max"] = arr.max(0).tolist()
for ai, wp, jn, w in prims:
    vh = np.concatenate([wp, np.ones((len(wp), 1))], 1); out = np.zeros((len(wp), 3))
    for c in range(4):
        out += w[:, c:c+1] * np.einsum("nij,nj->ni", A[jn[:, c]], vh)[:, :3]
    put(ai, out)
Gn = [np.vstack([np.array(RB[n]["g"]).reshape(3, 4), [0, 0, 0, 1]]) for n in names]
put(sk["inverseBindMatrices"], np.stack([np.linalg.inv(g).T for g in Gn]).reshape(-1, 16))
def quat(m):
    t = np.trace(m)
    if t > 0:
        s = np.sqrt(t + 1.0) * 2; q = [(m[2,1]-m[1,2])/s, (m[0,2]-m[2,0])/s, (m[1,0]-m[0,1])/s, 0.25*s]
    elif m[0,0] > m[1,1] and m[0,0] > m[2,2]:
        s = np.sqrt(1.0 + m[0,0] - m[1,1] - m[2,2]) * 2; q = [0.25*s, (m[0,1]+m[1,0])/s, (m[0,2]+m[2,0])/s, (m[2,1]-m[1,2])/s]
    elif m[1,1] > m[2,2]:
        s = np.sqrt(1.0 + m[1,1] - m[0,0] - m[2,2]) * 2; q = [(m[0,1]+m[1,0])/s, 0.25*s, (m[1,2]+m[2,1])/s, (m[0,2]-m[2,0])/s]
    else:
        s = np.sqrt(1.0 + m[2,2] - m[0,0] - m[1,1]) * 2; q = [(m[0,2]+m[2,0])/s, (m[1,2]+m[2,1])/s, 0.25*s, (m[1,0]-m[0,1])/s]
    q = np.array(q); return (q / np.linalg.norm(q)).tolist()
ji = {j: k for k, j in enumerate(joints)}
for k, j in enumerate(joints):
    pg = Gn[ji[par[j]]] if j in par and par[j] in ji else G[par[j]] if j in par else np.eye(4)
    L = np.linalg.inv(pg) @ Gn[k]; r = L[:3, :3]; s = np.linalg.norm(r, axis=0)
    nd = nodes[j]; nd.pop("matrix", None)
    nd["translation"] = L[:3, 3].tolist(); nd["rotation"] = quat(r / s); nd["scale"] = [float(x) for x in np.round(s, 6)]
js.pop("animations", None)
jb = json.dumps(js).encode(); jb += b" " * ((4 - len(jb) % 4) % 4)
while len(bn) % 4: bn.extend(b"\x00")
open(outp, "wb").write(struct.pack("<III", 0x46546C67, 2, 28 + len(jb) + len(bn)) + struct.pack("<II", len(jb), 0x4E4F534A) + jb + struct.pack("<II", len(bn), 0x004E4942) + bytes(bn))
print("refit", key, "->", outp)
