#!/usr/bin/env python3
"""Soften the shading of a low-polygon head in a rigged GLB (in place, same file size).

A model with a few thousand triangles for the whole body has a face made of large, slightly
uneven facets: lit from the side, every facet catches the light at its own angle and the face
looks broken. This evens it out without touching the shape much:
  1. the normals of everything on the head are averaged with their neighbours, several times;
  2. the points of the face are relaxed a little (Taubin smoothing: no shrinking).
Only vertices that follow the head bone are touched. UVs, weights and triangles stay as they are.

  python3 tools/models/smooth_head.py in.glb out.glb [normal_rounds=12] [shape_rounds=6]
"""
import json, struct, sys
import numpy as np

CT = {5120: np.int8, 5121: np.uint8, 5122: np.int16, 5123: np.uint16, 5125: np.uint32, 5126: np.float32}
NC = {'SCALAR': 1, 'VEC2': 2, 'VEC3': 3, 'VEC4': 4, 'MAT4': 16}


def load(path):
    b = open(path, 'rb').read()
    jl, _ = struct.unpack('<I4s', b[12:20])
    j = json.loads(b[20:20 + jl])
    off = 20 + jl
    bl, _ = struct.unpack('<I4s', b[off:off + 8])
    return j, bytearray(b[off + 8:off + 8 + bl]), b[off + 8 + bl:]


def save(path, j, bin_, rest):
    js = json.dumps(j, separators=(',', ':')).encode()
    js += b' ' * ((4 - len(js) % 4) % 4)
    body = struct.pack('<I4s', len(js), b'JSON') + js + struct.pack('<I4s', len(bin_), b'BIN\0') + bytes(bin_) + rest
    open(path, 'wb').write(struct.pack('<4sII', b'glTF', 2, 12 + len(body)) + body)


def view(j, bin_, i):
    a = j['accessors'][i]
    bv = j['bufferViews'][a['bufferView']]
    dt = np.dtype(CT[a['componentType']])
    n = NC[a['type']]
    start = bv.get('byteOffset', 0) + a.get('byteOffset', 0)
    stride = bv.get('byteStride', 0) or dt.itemsize * n
    assert stride == dt.itemsize * n, 'interleaved buffers are not handled'
    return np.frombuffer(bin_, dtype=dt, count=a['count'] * n, offset=start).reshape(a['count'], n), start


def main():
    src, dst = sys.argv[1], sys.argv[2]
    n_rounds = int(sys.argv[3]) if len(sys.argv) > 3 else 12
    p_rounds = int(sys.argv[4]) if len(sys.argv) > 4 else 6
    j, bin_, rest = load(src)
    skin = j['skins'][0]
    names = [j['nodes'][n].get('name', '') for n in skin['joints']]
    head_set = set()
    # the head bone and everything under it (eyes, jaw, head end)
    kids = {i: j['nodes'][i].get('children', []) for i in range(len(j['nodes']))}
    for k, nm in zip(skin['joints'], names):
        if nm.lower() in ('head',):
            stack = [k]
            while stack:
                x = stack.pop()
                head_set.add(x)
                stack += kids[x]
    head_idx = [i for i, k in enumerate(skin['joints']) if k in head_set]
    assert head_idx, 'no bone called Head: %s' % names
    for m in j['meshes']:
        for prim in m['primitives']:
            at = prim['attributes']
            P, p_at = view(j, bin_, at['POSITION'])
            N, n_at = view(j, bin_, at['NORMAL'])
            J, _ = view(j, bin_, at['JOINTS_0'])
            W, _ = view(j, bin_, at['WEIGHTS_0'])
            I, _ = view(j, bin_, prim['indices'])
            P = P.astype(np.float64).copy()
            N = N.astype(np.float64).copy()
            Wf = W.astype(np.float64)
            if W.dtype != np.float32:
                Wf = Wf / np.iinfo(W.dtype).max
            hw = np.zeros(len(P))
            for h in head_idx:
                hw += (Wf * (J == h)).sum(1)
            # one point per place in space (a seam in the texture splits a point into several)
            key = np.round(P / 1e-5).astype(np.int64)
            _, first, inv = np.unique(key, axis=0, return_index=True, return_inverse=True)
            inv = inv.ravel()
            U = len(first)
            tri = inv[I.ravel().astype(np.int64)].reshape(-1, 3)
            e = np.concatenate([tri[:, [0, 1]], tri[:, [1, 2]], tri[:, [2, 0]]])
            e = np.unique(np.concatenate([e, e[:, ::-1]]), axis=0)
            e = e[e[:, 0] != e[:, 1]]
            deg = np.bincount(e[:, 0], minlength=U).astype(np.float64)
            deg[deg == 0] = 1
            uw = np.zeros(U)
            np.maximum.at(uw, inv, hw)
            # fade in over the neck so there is no line where the smoothing starts
            wgt = np.clip((uw - 0.35) / 0.4, 0, 1)
            # --- the shape of the face, a little
            UP = np.zeros((U, 3))
            UP[inv] = P
            if p_rounds > 0:
                top = UP[wgt > 0.99][:, 1].max()
                low = UP[wgt > 0.99][:, 1].min()
                # the face: the front half of the head, below the hairline (the hair keeps its strands)
                cz = np.median(UP[wgt > 0.99][:, 2])
                face = wgt * np.clip((UP[:, 2] - cz) / 0.02, 0, 1) * np.clip((low + (top - low) * 0.72 - UP[:, 1]) / 0.02, 0, 1)
                Q = UP.copy()
                for r in range(p_rounds):
                    for lam in (0.5, -0.53):
                        avg = np.zeros((U, 3))
                        np.add.at(avg, e[:, 0], Q[e[:, 1]])
                        avg /= deg[:, None]
                        Q += (avg - Q) * lam * face[:, None]
                moved = np.linalg.norm(Q - UP, axis=1)
                print('  shape: %d points on the face, moved %.2f mm on average, %.2f mm at most' % ((face > 0.5).sum(), moved[face > 0.5].mean() * 1000, moved.max() * 1000))
                UP = Q
                P = UP[inv]
            # --- normals: from the (new) shape, then averaged with the neighbours
            t = UP[tri]
            fn = np.cross(t[:, 1] - t[:, 0], t[:, 2] - t[:, 0])
            UN = np.zeros((U, 3))
            for c in range(3):
                np.add.at(UN, tri[:, c], fn)
            UN /= np.maximum(np.linalg.norm(UN, axis=1, keepdims=True), 1e-12)
            old = np.zeros((U, 3))
            np.add.at(old, inv, N)
            old /= np.maximum(np.linalg.norm(old, axis=1, keepdims=True), 1e-12)
            S = UN.copy()
            for r in range(n_rounds):
                acc = S.copy()
                np.add.at(acc, e[:, 0], S[e[:, 1]])
                acc /= np.maximum(np.linalg.norm(acc, axis=1, keepdims=True), 1e-12)
                S = acc
            out = old * (1 - wgt[:, None]) + S * wgt[:, None]
            out /= np.maximum(np.linalg.norm(out, axis=1, keepdims=True), 1e-12)
            turn = np.degrees(np.arccos(np.clip((out * old).sum(1), -1, 1)))
            print('  normals: %d points on the head, turned %.1f degrees on average, %.1f at most' % ((wgt > 0.5).sum(), turn[wgt > 0.5].mean(), turn.max()))
            newN = out[inv].astype(np.float32)
            newP = P.astype(np.float32)
            bin_[n_at:n_at + newN.nbytes] = newN.tobytes()
            bin_[p_at:p_at + newP.nbytes] = newP.tobytes()
            a = j['accessors'][at['POSITION']]
            a['min'] = [float(x) for x in newP.min(0)]
            a['max'] = [float(x) for x in newP.max(0)]
    save(dst, j, bin_, rest)
    print('wrote', dst)


if __name__ == '__main__':
    main()
