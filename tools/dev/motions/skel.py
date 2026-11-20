
import json, struct, sys, os, glob
import numpy as np
CT = {5120: np.int8, 5121: np.uint8, 5122: np.int16, 5123: np.uint16, 5125: np.uint32, 5126: np.float32}
NC = {"SCALAR": 1, "VEC2": 2, "VEC3": 3, "VEC4": 4, "MAT4": 16}
def load(path):
    b = open(path, "rb").read()
    magic, ver, ln = struct.unpack_from("<III", b, 0)
    off = 12; js = None; bn = None
    while off < ln:
        cl, ct = struct.unpack_from("<II", b, off); off += 8
        if ct == 0x4E4F534A: js = json.loads(b[off:off + cl])
        elif ct == 0x004E4942: bn = b[off:off + cl]
        off += cl
    return js, bn
def acc(js, bn, i):
    a = js["accessors"][i]; bv = js["bufferViews"][a["bufferView"]]
    dt = np.dtype(CT[a["componentType"]]); n = NC[a["type"]]
    start = bv.get("byteOffset", 0) + a.get("byteOffset", 0)
    stride = bv.get("byteStride", 0)
    if stride and stride != dt.itemsize * n:
        out = np.zeros((a["count"], n), dtype=dt)
        for k in range(a["count"]):
            out[k] = np.frombuffer(bn, dtype=dt, count=n, offset=start + k * stride)
    else:
        out = np.frombuffer(bn, dtype=dt, count=a["count"] * n, offset=start).reshape(a["count"], n)
    out = out.astype(np.float64) if dt == np.float32 else out
    if a.get("normalized") and dt != np.float32:
        out = out.astype(np.float64) / np.iinfo(dt).max
    return out
def local(nd):
    if "matrix" in nd: return np.array(nd["matrix"], dtype=np.float64).reshape(4, 4).T
    t = nd.get("translation", [0, 0, 0]); r = nd.get("rotation", [0, 0, 0, 1]); s = nd.get("scale", [1, 1, 1])
    x, y, z, w = r
    R = np.array([[1-2*(y*y+z*z), 2*(x*y-z*w), 2*(x*z+y*w)], [2*(x*y+z*w), 1-2*(x*x+z*z), 2*(y*z-x*w)], [2*(x*z-y*w), 2*(y*z+x*w), 1-2*(x*x+y*y)]])
    M = np.eye(4); M[:3, :3] = R * np.array(s); M[:3, 3] = t
    return M
def one(path):
    js, bn = load(path)
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
    out = {"file": os.path.basename(path), "ext": js.get("extensionsUsed", []), "skins": len(js.get("skins", [])), "anims": [a.get("name", "") for a in js.get("animations", [])]}
    if not js.get("skins"): return out
    sk = js["skins"][0]; joints = sk["joints"]
    ibm = acc(js, bn, sk["inverseBindMatrices"]).reshape(-1, 4, 4).transpose(0, 2, 1)
    jidx = {j: k for k, j in enumerate(joints)}
    P = []; DOM = []
    for mi, nd in enumerate(nodes):
        if "mesh" not in nd or "skin" not in nd: continue
        for pr in js["meshes"][nd["mesh"]]["primitives"]:
            at = pr["attributes"]
            if "JOINTS_0" not in at: continue
            v = acc(js, bn, at["POSITION"]); jn = acc(js, bn, at["JOINTS_0"]).astype(int); w = acc(js, bn, at["WEIGHTS_0"]).astype(np.float64)
            w = w / np.maximum(w.sum(1, keepdims=True), 1e-9)
            vh = np.concatenate([v, np.ones((len(v), 1))], 1)
            acc_p = np.zeros((len(v), 3))
            for c in range(4):
                Ms = np.stack([G[joints[j]] @ ibm[j] for j in range(len(joints))])[jn[:, c]]
                acc_p += w[:, c:c+1] * np.einsum("nij,nj->ni", Ms, vh)[:, :3]
            P.append(acc_p); DOM.append(jn[np.arange(len(v)), w.argmax(1)])
    P = np.concatenate(P); DOM = np.concatenate(DOM)
    out["verts"] = int(len(P)); out["bbox"] = [np.round(P.min(0), 4).tolist(), np.round(P.max(0), 4).tolist()]
    bones = []
    for k, j in enumerate(joints):
        nd = nodes[j]; g = G[j]
        e = {"n": nd.get("name", str(j)), "p": nodes[par[j]].get("name", "") if j in par and par[j] in jidx else "", "g": np.round(g[:3, :], 5).reshape(-1).tolist()}
        sel = P[DOM == k]
        if len(sel) > 0:
            loc = (np.linalg.inv(g) @ np.concatenate([sel, np.ones((len(sel), 1))], 1).T).T[:, :3]
            e["c"] = int(len(sel)); e["lo"] = np.round(loc.min(0), 4).tolist(); e["hi"] = np.round(loc.max(0), 4).tolist()
            e["wlo"] = np.round(sel.min(0), 4).tolist(); e["whi"] = np.round(sel.max(0), 4).tolist()
        bones.append(e)
    out["bones"] = bones
    return out
res = []
for f in sorted(glob.glob(sys.argv[1] + "/*.glb")):
    try: res.append(one(f))
    except Exception as ex: res.append({"file": os.path.basename(f), "error": repr(ex)})
json.dump(res, open(sys.argv[2], "w"))
