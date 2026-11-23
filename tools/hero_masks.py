#!/usr/bin/env python3
"""Work out, for every built-in hero model, which part of its picture is skin, hair, top, bottom
and shoes, and which triangles belong to the head. The game reads the result
(assets/models/people/masks/<model>.png and scripts/core/hero_masks.gd) to recolor the hero and
to put any hairstyle on any outfit.

  python3 tools/hero_masks.py [--preview /tmp/out] [model names...]

Mask picture: R = what the pixel is (see IDS), G = 255 on the head (hair, face), 128 on the
neck's skin, 0 on the body.
"""
import io
import json
import os
import struct
import sys

import numpy as np
from PIL import Image

HERE = os.path.dirname(os.path.abspath(__file__))
PEOPLE = os.environ.get("HERO_PEOPLE", os.path.join(HERE, "..", "assets", "models", "people"))
IDS = {"none": 0, "skin": 40, "hair": 80, "top": 120, "bottom": 160, "shoes": 200, "eyes": 220, "accent": 240}
CT = {5120: np.int8, 5121: np.uint8, 5122: np.int16, 5123: np.uint16, 5125: np.uint32, 5126: np.float32}
NC = {"SCALAR": 1, "VEC2": 2, "VEC3": 3, "VEC4": 4, "MAT4": 16}
GROUPS = {
    "head": ["Head", "head_end", "headfront"],
    "neck": ["neck"],
    "top": ["Spine01", "Spine02", "LeftShoulder", "RightShoulder", "LeftArm", "RightArm", "LeftForeArm", "RightForeArm"],
    "waist": ["Spine", "Hips"],
    "legs": ["LeftUpLeg", "RightUpLeg", "LeftLeg", "RightLeg"],
    "feet": ["LeftFoot", "RightFoot", "LeftToeBase", "RightToeBase"],
    "hands": ["LeftHand", "RightHand"],
}
GN = list(GROUPS.keys())
# Outfits whose models carry their own hairstyle's head (HeroLook.OWN_HEAD); every later outfit
# is a body that always takes a borrowed head.
OWN_HEAD = ("street", "academy", "rider", "satellite", "heartland")


def load(path):
    d = open(path, "rb").read()
    jl = struct.unpack("<I", d[12:16])[0]
    j = json.loads(d[20:20 + jl])
    off = 20 + jl
    bl = struct.unpack("<I", d[off:off + 4])[0]
    return j, d[off + 8:off + 8 + bl]


def acc(j, b, i):
    a = j["accessors"][i]
    bv = j["bufferViews"][a["bufferView"]]
    n = NC[a["type"]]
    dt = np.dtype(CT[a["componentType"]])
    start = bv.get("byteOffset", 0) + a.get("byteOffset", 0)
    stride = bv.get("byteStride", 0)
    if stride and stride != dt.itemsize * n:
        out = np.zeros((a["count"], n), dt)
        for k in range(a["count"]):
            out[k] = np.frombuffer(b, dt, n, start + k * stride)
        return out
    return np.frombuffer(b, dt, a["count"] * n, start).reshape(a["count"], n).copy()


def srgb_to_lab(rgb):
    c = rgb.astype(np.float64) / 255.0
    c = np.where(c <= 0.04045, c / 12.92, ((c + 0.055) / 1.055) ** 2.4)
    m = np.array([[0.4124564, 0.3575761, 0.1804375], [0.2126729, 0.7151522, 0.0721750], [0.0193339, 0.1191920, 0.9503041]])
    xyz = c @ m.T / np.array([0.95047, 1.0, 1.08883])
    f = np.where(xyz > 0.008856, np.cbrt(xyz), 7.787 * xyz + 16.0 / 116.0)
    return np.stack([116 * f[..., 1] - 16, 500 * (f[..., 0] - f[..., 1]), 200 * (f[..., 1] - f[..., 2])], -1)


def hsv(rgb):
    c = rgb.astype(np.float64) / 255.0
    mx = c.max(-1)
    mn = c.min(-1)
    d = mx - mn
    h = np.zeros_like(mx)
    r, g, bl = c[..., 0], c[..., 1], c[..., 2]
    m = d > 1e-6
    hr = ((g - bl) / np.where(m, d, 1)) % 6
    hg = (bl - r) / np.where(m, d, 1) + 2
    hb = (r - g) / np.where(m, d, 1) + 4
    h = np.where(mx == r, hr, np.where(mx == g, hg, hb)) / 6.0
    h = np.where(m, h % 1.0, 0)
    s = np.where(mx > 1e-6, d / np.where(mx > 1e-6, mx, 1), 0)
    return h, s, mx


def main_cluster(lab, k=5, it=12, seed=1):
    """The biggest group of similar colors: returns (center, spread per channel, member mask)."""
    rng = np.random.default_rng(seed)
    if len(lab) < 50:
        return None
    pts = lab if len(lab) < 40000 else lab[rng.choice(len(lab), 40000, False)]
    cen = pts[rng.choice(len(pts), k, False)].copy()
    for _ in range(it):
        d = ((pts[:, None, :] - cen[None]) ** 2 * np.array([0.35, 1, 1])).sum(-1)
        lab_i = d.argmin(1)
        for c in range(k):
            if (lab_i == c).any():
                cen[c] = pts[lab_i == c].mean(0)
    counts = np.bincount(lab_i, minlength=k)
    # groups that are the same color in a lighter or darker shade count as one; the biggest
    # such family wins (a navy blazer in three shades beats one flat white shirt)
    best, same, most = 0, [0], -1
    for c0 in range(k):
        fam = [c for c in range(k) if counts[c] > 0 and np.hypot(*(cen[c, 1:] - cen[c0, 1:])) < 9 and abs(cen[c, 0] - cen[c0, 0]) < 28]
        n = sum(counts[c] for c in fam)
        if counts[c0] > 0 and n > most:
            best, same, most = c0, fam, n
    sel = pts[np.isin(lab_i, same)]
    return sel.mean(0), sel.std(0) + 1e-3, (sel[:, 0].min(), sel[:, 0].max())


def close_to(lab, cl, chroma=11.0, pad=9.0):
    cen, _sd, (lo, hi) = cl
    return (np.hypot(lab[..., 1] - cen[1], lab[..., 2] - cen[2]) < chroma) & (lab[..., 0] > lo - pad) & (lab[..., 0] < hi + pad)


def build(name, preview=None, collars=False, tails=False):
    j, b = load(os.path.join(PEOPLE, name + ".glb"))
    prim = j["meshes"][0]["primitives"][0]
    P = acc(j, b, prim["attributes"]["POSITION"]).astype(np.float64)
    UV = acc(j, b, prim["attributes"]["TEXCOORD_0"]).astype(np.float64)
    J = acc(j, b, prim["attributes"]["JOINTS_0"]).astype(np.int64)
    W = acc(j, b, prim["attributes"]["WEIGHTS_0"]).astype(np.float64)
    I = acc(j, b, prim["indices"]).reshape(-1, 3).astype(np.int64)
    skin = j["skins"][0]
    jn = [j["nodes"][n]["name"] for n in skin["joints"]]
    ibm = acc(j, b, skin["inverseBindMatrices"]).reshape(-1, 4, 4)
    bone_pos = {}
    for k, nm in enumerate(jn):
        bone_pos[nm] = np.linalg.inv(ibm[k].T)[:3, 3]
    img_bv = j["bufferViews"][j["images"][0]["bufferView"]]
    tex = Image.open(io.BytesIO(b[img_bv.get("byteOffset", 0):img_bv.get("byteOffset", 0) + img_bv["byteLength"]])).convert("RGB")
    T = np.asarray(tex)
    H, Wd = T.shape[:2]

    # which body part every vertex follows
    gw = np.zeros((len(P), len(GN)))
    for gi, g in enumerate(GN):
        for nm in GROUPS[g]:
            if nm in jn:
                gw[:, gi] += (W * (J == jn.index(nm))).sum(1)
    tri_g = gw[I].sum(1).argmax(1)
    tri_c = P[I].mean(1)

    # picture pixel -> triangle
    tri_of = np.full((H, Wd), -1, np.int32)
    px = np.stack([UV[:, 0] * Wd - 0.5, UV[:, 1] * H - 0.5], 1)
    for t in range(len(I)):
        a, bb, c = px[I[t]]
        x0 = int(max(0, np.floor(min(a[0], bb[0], c[0])) - 1))
        x1 = int(min(Wd - 1, np.ceil(max(a[0], bb[0], c[0])) + 1))
        y0 = int(max(0, np.floor(min(a[1], bb[1], c[1])) - 1))
        y1 = int(min(H - 1, np.ceil(max(a[1], bb[1], c[1])) + 1))
        if x1 < x0 or y1 < y0:
            continue
        den = (bb[1] - c[1]) * (a[0] - c[0]) + (c[0] - bb[0]) * (a[1] - c[1])
        if abs(den) < 1e-12:
            continue
        xs, ys = np.meshgrid(np.arange(x0, x1 + 1), np.arange(y0, y1 + 1))
        l1 = ((bb[1] - c[1]) * (xs - c[0]) + (c[0] - bb[0]) * (ys - c[1])) / den
        l2 = ((c[1] - a[1]) * (xs - c[0]) + (a[0] - c[0]) * (ys - c[1])) / den
        l3 = 1 - l1 - l2
        e = -0.6 / max(1.0, np.sqrt(abs(den)))   # a little past the edge, so seams are covered
        m = (l1 >= e) & (l2 >= e) & (l3 >= e)
        sub = tri_of[y0:y1 + 1, x0:x1 + 1]
        sub[m & (sub < 0)] = t
        inside = (l1 >= 0) & (l2 >= 0) & (l3 >= 0)
        sub[inside] = t
    used = tri_of >= 0
    tg = np.where(used, tri_g[np.maximum(tri_of, 0)], -1)
    pos = tri_c[np.maximum(tri_of, 0)]
    lab = srgb_to_lab(T)
    hh, ss, vv = hsv(T)
    gi = {g: i for i, g in enumerate(GN)}

    front = bone_pos.get("headfront", bone_pos["Head"] + np.array([0, 0, 0.1])) - bone_pos["Head"]
    fz = 1.0 if front[2] >= 0 else -1.0
    head_y = bone_pos["Head"][1]
    top_y = P[:, 1].max()
    if collars:
        # --collars: leave a finished mask as it is, but give the body back the collar pieces that
        # are bound to the head bone (so a borrowed head brings no collar of its own along).
        mpath = os.path.join(PEOPLE, "masks", name + ".png")
        M = np.array(Image.open(mpath).convert("RGB"))
        cut = used & (tg == gi["head"]) & (pos[..., 1] < head_y - 0.005) & ~np.isin(M[..., 0], [40, 80, 220]) & (M[..., 1] > 0)
        M[..., 1][cut] = 0
        Image.fromarray(M).save(mpath, optimize=True)
        print(name, "collar pixels given back to the body:", int(cut.sum()))
        return None

    # skin: the peach on the face, neck and hands
    cand = used & np.isin(tg, [gi["head"], gi["neck"], gi["hands"]]) & (hh > 0.01) & (hh < 0.12) & (ss > 0.12) & (ss < 0.62) & (vv > 0.55)
    skin_ref = np.median(lab[cand], 0)
    skin = used & (np.hypot(lab[..., 1] - skin_ref[1], lab[..., 2] - skin_ref[2]) < 9.5) & (lab[..., 0] > skin_ref[0] - 26) & (lab[..., 0] < skin_ref[0] + 14) & (ss < 0.66)

    # accent: the signature color (teal; orange on the rider suit)
    rider = name.endswith("_rider")
    if rider:
        accent = used & (np.abs(hh - 0.065) < 0.045) & (ss > 0.66) & ~skin
    else:
        accent = used & (np.abs(hh - 0.49) < 0.07) & (ss > 0.32) & (vv > 0.24)

    # hair: whatever the crown of the head is, wherever it shows on the head and neck
    crown = used & (tg == gi["head"]) & (pos[..., 1] > top_y - 0.075) & ~skin
    hair_cl = main_cluster(lab[crown], k=4)
    # Hair: start at the crown and follow the mesh through every triangle that has the hair's
    # color, however far down the back it hangs. Going by the mesh (and not by "anything of this
    # color near the head") keeps a white collar or a navy blazer out of it.
    loose = used & close_to(lab, hair_cl, 12.0, 14.0) & ~skin
    hairlike = used & close_to(lab, hair_cl, 8.5, 7.0) & ~skin & ~accent
    nt = len(I)
    tot = np.bincount(tri_of[used], minlength=nt).astype(np.float64)
    hl = np.bincount(tri_of[hairlike], minlength=nt) / np.maximum(tot, 1)
    ll = np.bincount(tri_of[loose], minlength=nt) / np.maximum(tot, 1)
    key = np.round(P * 4000).astype(np.int64)
    _u, weld = np.unique(key, axis=0, return_inverse=True)
    weld = weld.reshape(-1)
    WI = weld[I]
    on_head = tri_g == gi["head"]
    brow_y = head_y + 0.5 * (top_y - head_y)
    is_hair = on_head & (tri_c[:, 1] > brow_y) & (ll > 0.5)
    # A head-only model ("<stem>_hair") wears plain clothes picked to look nothing like its hair.
    donor = name.endswith("_hair")
    ok = (np.where(on_head, ll > 0.45, hl > 0.6) | (tot == 0)) & (tri_c[:, 1] > 0.25)
    if donor:
        # Head-only models are drawn with light silver hair and dark plain clothes: off the head,
        # only what is as light as the crown is hair.
        crown_l = float(np.median(lab[crown][:, 0]))
        tri_l = np.bincount(tri_of[used], weights=lab[used][:, 0], minlength=nt) / np.maximum(tot, 1)
        teal = used & (np.abs(hh - 0.49) < 0.09) & (ss > 0.18)       # the streak, shadows and all
        acc_f = np.bincount(tri_of[teal | (used & accent)], minlength=nt) / np.maximum(tot, 1)
        ok = (ok & (on_head | (tri_l > crown_l - 22))) | (~on_head & (acc_f > 0.5) & (tri_c[:, 1] > 0.25))
    if donor:
        # Meshy makes a braid or a tail its own piece, not joined to the head: start there too.
        is_hair |= ((hl > 0.7) | (acc_f > 0.5)) & ok & ~on_head & (tri_c[:, 1] > bone_pos["Hips"][1] + 0.1)
    vert_hair = np.zeros(weld.max() + 1, bool)
    for _ in range(600):
        vert_hair[:] = False
        vert_hair[WI[is_hair].reshape(-1)] = True
        grow = ok & ~is_hair & vert_hair[WI].any(1)
        if not grow.any():
            break
        is_hair |= grow
    in_flood = used & is_hair[np.maximum(tri_of, 0)]
    if tails:
        # --tails: leave a finished mask as it is, but hand the head the colored tips of a tail or
        # a braid that hang off the hair below the head (so a borrowed head leaves none behind).
        teal_t = used & (np.abs(hh - 0.49) < 0.09) & (ss > 0.18)
        acc_t = np.bincount(tri_of[teal_t], minlength=nt) / np.maximum(tot, 1)
        tip = np.zeros(nt, bool)
        grown = is_hair.copy()
        for _ in range(60):
            vert_hair[:] = False
            vert_hair[WI[grown].reshape(-1)] = True
            g2 = ~grown & ~on_head & (acc_t > 0.5) & vert_hair[WI].any(1)
            if not g2.any():
                break
            tip |= g2
            grown |= g2
        mpath = os.path.join(PEOPLE, "masks", name + ".png")
        M = np.array(Image.open(mpath).convert("RGB"))
        cut = used & tip[np.maximum(tri_of, 0)] & (M[..., 1] < 128)
        M[..., 1][cut] = 255
        Image.fromarray(M).save(mpath, optimize=True)
        print(name, "tail tip pixels handed to the head:", int(cut.sum()), "triangles:", int(tip.sum()))
        return None
    hair = in_flood & ~skin & ~accent
    back = hair & (tg != gi["head"])
    # eyes: keep the whites and the irises out of the hair
    face = used & (tg == gi["head"]) & (pos[..., 2] * fz > bone_pos["Head"][2] * fz + 0.045)
    band = face & (pos[..., 1] > head_y + 0.04) & (pos[..., 1] < head_y + 0.16)
    feat = band & ~skin & ~loose
    eyes = []
    for sgn in (-1, 1):
        m = feat & (pos[..., 0] * sgn > 0.008) & (np.abs(pos[..., 0]) < 0.075)
        if m.sum() > 40:
            eyes.append(np.median(pos[m], 0))
    eye_zone = np.zeros_like(used)
    for e in eyes:
        eye_zone |= face & (np.hypot(pos[..., 0] - e[0], pos[..., 1] - e[1]) < 0.024)
    hair &= ~eye_zone
    # eyebrows go with the hair
    for e in eyes:
        hair |= face & loose & (pos[..., 1] > e[1] + 0.012) & (pos[..., 1] < e[1] + 0.05) & (np.abs(pos[..., 0] - e[0]) < 0.04)
    iris = eye_zone & ~close_to(lab, hair_cl, 6.0, 6.0) & (((ss > 0.3) & (vv > 0.22) & ~skin) | (ss > 0.5))

    def region(mask, k=5):
        m = used & mask & ~skin & ~accent & ~hair & ~back
        if m.sum() < 400:
            return None, np.zeros_like(used)
        cl = main_cluster(lab[m], k=k)
        return cl, m & close_to(lab, cl, 10.0, 8.0)

    # The sleeves say what the jacket is (a white shirt under a blazer must not win), and the
    # upper legs say what the trousers or skirt are (not the socks).
    arm_tri = np.zeros(len(I), bool)
    thigh_tri = np.zeros(len(I), bool)
    aw = np.zeros(len(P))
    tw_ = np.zeros(len(P))
    for nm in ("LeftArm", "RightArm"):
        if nm in jn:
            aw += (W * (J == jn.index(nm))).sum(1)
    for nm in ("LeftUpLeg", "RightUpLeg"):
        if nm in jn:
            tw_ += (W * (J == jn.index(nm))).sum(1)
    arm_tri = aw[I].mean(1) > 0.5
    thigh_tri = tw_[I].mean(1) > 0.5
    arms = arm_tri[np.maximum(tri_of, 0)] & (tg == gi["top"])
    thighs = thigh_tri[np.maximum(tri_of, 0)] & (tg == gi["legs"])
    top_cl, top = region(arms)
    if top_cl is None or top.sum() < 0.3 * max(1, (used & arms & ~skin & ~hair).sum()):
        top_cl, top = region(np.isin(tg, [gi["top"]]))
    else:
        top = used & (tg == gi["top"]) & ~skin & ~accent & ~hair & close_to(lab, top_cl, 10.0, 8.0)
    # (A long coat covers the thighs: what is not the top's color there is the trousers or skirt.)
    bot_cl, bottom = region((thighs | (tg == gi["waist"])) & ~close_to(lab, top_cl, 10.0, 8.0) if top_cl is not None else thighs)
    if bot_cl is None:
        bot_cl, bottom = region(np.isin(tg, [gi["legs"]]))
    else:
        bottom = used & np.isin(tg, [gi["legs"]]) & ~skin & ~accent & ~hair & close_to(lab, bot_cl, 10.0, 8.0)
    shoe_cl, shoes = region(np.isin(tg, [gi["feet"]]), k=3)
    # the waist goes with whichever of the two it looks like
    waist = used & np.isin(tg, [gi["waist"]]) & ~skin & ~accent & ~hair
    if top_cl is not None and bot_cl is not None:
        dt = np.sqrt((((lab - top_cl[0]) * np.array([0.5, 1, 1])) ** 2).sum(-1))
        db = np.sqrt((((lab - bot_cl[0]) * np.array([0.5, 1, 1])) ** 2).sum(-1))
        same = np.sqrt((((top_cl[0] - bot_cl[0]) * np.array([0.5, 1, 1])) ** 2).sum()) < 9
        if same:
            upper = pos[..., 1] > bone_pos["Hips"][1] + 0.03
            top |= waist & close_to(lab, top_cl, 10.0, 8.0) & upper
            bottom |= waist & close_to(lab, bot_cl, 10.0, 8.0) & ~upper
        else:
            top |= waist & close_to(lab, top_cl, 10.0, 8.0) & (dt <= db)
            bottom |= waist & close_to(lab, bot_cl, 10.0, 8.0) & (db < dt)
        # the top's color on the upper legs is the hem of a long coat or blazer
        knee = bone_pos["LeftLeg"][1] - 0.06 if "LeftLeg" in bone_pos else bone_pos["Hips"][1] - 0.2
        hem = used & (tg == gi["legs"]) & (pos[..., 1] > min(knee, bone_pos["Hips"][1] - 0.2)) & ~skin & ~accent & ~hair & close_to(lab, top_cl, 10.0, 8.0) & (dt < db) & ~same
        top |= hem
        bottom &= ~top
    # An outfit made after the first five only ever lends its body: its own head is always
    # replaced, so nothing below the head counts as hair (a white collar touching short silver
    # hair would otherwise be cut away with the head).
    body_only = (not donor) and name.rsplit("_", 1)[-1] not in OWN_HEAD
    if body_only:
        back[:] = False
        hair &= tg == gi["head"]
    hair |= back
    top &= ~hair
    bottom &= ~hair
    shoes &= ~hair
    iris |= (eye_zone | band) & accent & ~hair     # teal eyes are eyes, not the signature color
    accent &= ~iris

    ids = np.zeros((H, Wd), np.uint8)
    ids[top] = IDS["top"]
    ids[bottom] = IDS["bottom"]
    ids[shoes] = IDS["shoes"]
    ids[accent] = IDS["accent"]
    ids[skin] = IDS["skin"]
    ids[hair] = IDS["hair"]
    ids[iris] = IDS["eyes"]
    # G: 255 = the head (face and all the hair), 128 = the skin of the neck. When a hairstyle
    # from one model goes on another, the body gives up its 255 and the head brings 128 and up,
    # so the two necks overlap in the same skin tone instead of leaving a gap.
    part = np.where(used & ((tg == gi["head"]) | hair | (in_flood & donor)), 255, 0).astype(np.uint8)
    # A collar bound to the head bone stays with the body; the face and hair go. (On a body-only
    # outfit only what is clearly cloth: its own chin must never peek out under a borrowed head.)
    low = used & (tg == gi["head"]) & (pos[..., 1] < head_y - 0.005) & ~hair & ~skin
    if donor:
        low[:] = False        # a head-only model wears a plain t-shirt: everything on its head stays
    if body_only:
        # (a tan collar can pass for skin: anything well under the jaw goes back to the body)
        low = (low & np.isin(ids, [IDS["top"], IDS["bottom"], IDS["accent"]])) | \
            (used & (tg == gi["head"]) & (pos[..., 1] < head_y - 0.025) & ~hair)
    part[low] = 0
    part[used & (tg == gi["neck"]) & skin & (part == 0)] = 128
    if False and donor and eyes:      # off: it cut eyelashes on clean faces; kept for reference
        # Stray strands Meshy leaves floating in front of the face (by the eyes, on the cheeks):
        # small pieces of hair not joined to the rest of it, below the brows. A head-only model
        # never shows them (G 0 is never drawn on a borrowed head). Bangs are joined to the hair.
        ey = max(float(e[1]) for e in eyes)
        frontz = tri_c[:, 2] * fz - bone_pos["Head"][2] * fz
        skin_t = (np.bincount(tri_of[used & skin], minlength=len(I)) / np.maximum(tot, 1) > 0.5) & on_head
        hair_t = (np.bincount(tri_of[used & (hair | (loose & eye_zone & ~iris))], minlength=len(I)) / np.maximum(tot, 1) > 0.5) & on_head
        ht = np.where(hair_t)[0]
        parent = np.arange(weld.max() + 1)

        def find(x):
            while parent[x] != x:
                parent[x] = parent[parent[x]]
                x = parent[x]
            return x
        for t in ht:
            a0, a1, a2 = (find(v) for v in WI[t])
            parent[a1] = a0
            parent[find(a2)] = a0
        comp = np.array([find(WI[t][0]) for t in ht])
        shard = np.zeros(len(I), bool)
        for c in np.unique(comp):
            ts = ht[comp == c]
            cc = tri_c[ts].mean(0)
            if len(ts) > 40 or not (head_y - 0.06 < cc[1] < ey + 0.015) or abs(cc[0] - bone_pos["Head"][0]) > 0.095:
                continue
            # it must stand out at or in front of the face's skin around it (an eye white is set in)
            lo, hi = tri_c[ts, :2].min(0) - 0.01, tri_c[ts, :2].max(0) + 0.01
            sk = skin_t & np.all(tri_c[:, :2] > lo, 1) & np.all(tri_c[:, :2] < hi, 1)
            if sk.any() and frontz[ts].max() >= frontz[sk].max() - 0.003:
                shard[ts] = True
        part[used & shard[np.maximum(tri_of, 0)]] = 0
        print(name, "strands under the eyes hidden:", int(shard.sum()))

    # spread into the empty gaps between the pieces, so filtering at the seams picks nothing wrong
    for _ in range(3):
        empty = ~used
        for dy, dx in ((0, 1), (0, -1), (1, 0), (-1, 0)):
            sh_u = np.roll(used, (dy, dx), (0, 1))
            take = empty & sh_u
            ids[take] = np.roll(ids, (dy, dx), (0, 1))[take]
            part[take] = np.roll(part, (dy, dx), (0, 1))[take]
            used = used | take
            empty = ~used

    def ref(mask):
        if mask.sum() < 50:
            return [0.5, 0.5, 0.5]
        c = np.median(T[mask].astype(np.float64) / 255.0, 0)
        lin = np.where(c <= 0.04045, c / 12.92, ((c + 0.055) / 1.055) ** 2.4)      # the real sRGB curve
        return [round(float(x), 4) for x in lin]

    out = {"skin": ref(skin), "hair": ref(hair), "top": ref(top), "bottom": ref(bottom), "shoes": ref(shoes),
           "share": {k: round(float((ids == v).sum()) / max(1, (tri_of >= 0).sum()), 3) for k, v in IDS.items() if k != "none"},
           "eyes": len(eyes)}
    os.makedirs(os.path.join(PEOPLE, "masks"), exist_ok=True)
    Image.merge("RGB", [Image.fromarray(ids), Image.fromarray(part), Image.fromarray(np.zeros_like(ids))]).save(
        os.path.join(PEOPLE, "masks", name + ".png"), optimize=True)

    if preview:
        os.makedirs(preview, exist_ok=True)
        paint = {"skin": (0.36, 0.2, 0.12), "hair": (0.75, 0.1, 0.1), "top": (0.9, 0.75, 0.1), "bottom": (0.15, 0.5, 0.2), "shoes": (0.8, 0.2, 0.8), "accent": (1.0, 0.45, 0.0), "eyes": (0.1, 0.9, 0.2)}
        lin = (T.astype(np.float64) / 255.0) ** 2.2
        luma = lin @ np.array([0.2126, 0.7152, 0.0722])
        R = lin.copy()
        for k, col in paint.items():
            m = ids == IDS[k]
            if k in ("accent", "eyes"):
                R[m] = np.array(col) * np.clip(luma[m] / 0.2, 0.3, 1.6)[:, None]
                continue
            rl = max(1e-3, float(np.array(out[k]) @ np.array([0.2126, 0.7152, 0.0722])))
            R[m] = np.array(col) * np.clip(luma[m] / rl, 0.35, 1.7)[:, None]
        R = (np.clip(R, 0, 1) ** (1 / 2.2) * 255).astype(np.uint8)
        views = [render(P, UV, I, T, fz, 420), render(P, UV, I, R, fz, 420), render(P, UV, I, R, -fz, 420)]
        hv = render(P, UV, I, np.dstack([part, part, part]), fz, 420)
        sheet = Image.new("RGB", (sum(v.width for v in views) + hv.width, views[0].height), (40, 40, 48))
        x = 0
        for v in views + [hv]:
            sheet.paste(v, (x, 0))
            x += v.width
        sheet.save(os.path.join(preview, name + ".jpg"), quality=85)
    return out


def render(P, UV, I, tex, sgn, size=640):
    """A plain front (or back) picture of the model, to check the masks by eye."""
    h = size
    w = int(size * 0.62)
    s = (h - 20) / 1.75
    X = (P[:, 0] * sgn) * s + w / 2
    Y = h - 10 - P[:, 1] * s
    Z = P[:, 2] * sgn
    img = np.full((h, w, 3), 40, np.uint8)
    zb = np.full((h, w), -1e9)
    th, tw = tex.shape[:2]
    for t in range(len(I)):
        i0, i1, i2 = I[t]
        xs0, xs1 = int(np.floor(min(X[i0], X[i1], X[i2]))), int(np.ceil(max(X[i0], X[i1], X[i2])))
        ys0, ys1 = int(np.floor(min(Y[i0], Y[i1], Y[i2]))), int(np.ceil(max(Y[i0], Y[i1], Y[i2])))
        xs0, ys0 = max(xs0, 0), max(ys0, 0)
        xs1, ys1 = min(xs1, w - 1), min(ys1, h - 1)
        if xs1 < xs0 or ys1 < ys0:
            continue
        den = (Y[i1] - Y[i2]) * (X[i0] - X[i2]) + (X[i2] - X[i1]) * (Y[i0] - Y[i2])
        if abs(den) < 1e-9:
            continue
        gx, gy = np.meshgrid(np.arange(xs0, xs1 + 1), np.arange(ys0, ys1 + 1))
        l1 = ((Y[i1] - Y[i2]) * (gx - X[i2]) + (X[i2] - X[i1]) * (gy - Y[i2])) / den
        l2 = ((Y[i2] - Y[i0]) * (gx - X[i2]) + (X[i0] - X[i2]) * (gy - Y[i2])) / den
        l3 = 1 - l1 - l2
        m = (l1 >= 0) & (l2 >= 0) & (l3 >= 0)
        if not m.any():
            continue
        z = l1 * Z[i0] + l2 * Z[i1] + l3 * Z[i2]
        sub = zb[ys0:ys1 + 1, xs0:xs1 + 1]
        m &= z > sub
        if not m.any():
            continue
        u = l1 * UV[i0, 0] + l2 * UV[i1, 0] + l3 * UV[i2, 0]
        v = l1 * UV[i0, 1] + l2 * UV[i1, 1] + l3 * UV[i2, 1]
        tx = np.clip((u * tw).astype(int), 0, tw - 1)
        ty = np.clip((v * th).astype(int), 0, th - 1)
        sub[m] = z[m]
        img[ys0:ys1 + 1, xs0:xs1 + 1][m] = tex[ty[m], tx[m]]
    return Image.fromarray(img)


def trim(name, neck=False):
    """--trim: a short hairstyle's head-only model keeps nothing of its own below the shoulders
    (light clothes there can pass for silver hair and would show on every outfit it goes on)."""
    from PIL import ImageDraw
    j, b = load(os.path.join(PEOPLE, name + ".glb"))
    prim = j["meshes"][0]["primitives"][0]
    P = acc(j, b, prim["attributes"]["POSITION"]).astype(np.float64)
    UV = acc(j, b, prim["attributes"]["TEXCOORD_0"]).astype(np.float64)
    I = acc(j, b, prim["indices"]).reshape(-1, 3).astype(np.int64)
    skin = j["skins"][0]
    jn = [j["nodes"][n]["name"] for n in skin["joints"]]
    ibm = acc(j, b, skin["inverseBindMatrices"]).reshape(-1, 4, 4)
    bp = {nm: np.linalg.inv(ibm[k].T)[:3, 3] for k, nm in enumerate(jn)}
    sh = max(bp["LeftShoulder"][1], bp["RightShoulder"][1])
    mpath = os.path.join(PEOPLE, "masks", name + ".png")
    M = np.array(Image.open(mpath).convert("RGB"))
    H, W = M.shape[:2]
    tc = P[I].mean(1)
    low = tc[:, 1] < (bp["neck"][1] if neck else sh - 0.08)
    if neck:
        # and anything out on the shoulders below the head (a donor's shoulder pads read as hair)
        low |= (tc[:, 1] < bp["Head"][1]) & (np.abs(tc[:, 0] - bp["Head"][0]) > 0.12)
    canvas = Image.new("L", (W, H), 0)
    d = ImageDraw.Draw(canvas)
    for t in np.where(low)[0]:
        d.polygon([(UV[v, 0] * W - 0.5, UV[v, 1] * H - 0.5) for v in I[t]], fill=255, outline=255)
    cut = (np.asarray(canvas) > 0) & (M[..., 1] > 0)
    if neck:
        cut &= M[..., 0] != IDS["skin"]       # (--neck: from the neck bone down; its skin stays)
    M[..., 1][cut] = 0
    Image.fromarray(M).save(mpath, optimize=True)
    print(name, "pixels below the shoulders taken off the head:", int(cut.sum()))


def floating(name):
    """--float: bits of a body's own hair left hanging in the air beside the head once the head
    is borrowed (tips Meshy cut off the tail): high up and off to the side, they go with the head."""
    from PIL import ImageDraw
    j, b = load(os.path.join(PEOPLE, name + ".glb"))
    prim = j["meshes"][0]["primitives"][0]
    P = acc(j, b, prim["attributes"]["POSITION"]).astype(np.float64)
    UV = acc(j, b, prim["attributes"]["TEXCOORD_0"]).astype(np.float64)
    I = acc(j, b, prim["indices"]).reshape(-1, 3).astype(np.int64)
    skin = j["skins"][0]
    jn = [j["nodes"][n]["name"] for n in skin["joints"]]
    ibm = acc(j, b, skin["inverseBindMatrices"]).reshape(-1, 4, 4)
    bp = {nm: np.linalg.inv(ibm[k].T)[:3, 3] for k, nm in enumerate(jn)}
    tc = P[I].mean(1)
    dx = np.abs(tc[:, 0] - bp["Head"][0])
    up = (tc[:, 1] > bp["neck"][1] + 0.05) & (dx > 0.11) & (dx < 0.3)
    mpath = os.path.join(PEOPLE, "masks", name + ".png")
    M = np.array(Image.open(mpath).convert("RGB"))
    H, W = M.shape[:2]
    canvas = Image.new("L", (W, H), 0)
    d = ImageDraw.Draw(canvas)
    for t in np.where(up)[0]:
        d.polygon([(UV[v, 0] * W - 0.5, UV[v, 1] * H - 0.5) for v in I[t]], fill=255, outline=255)
    cut = (np.asarray(canvas) > 0) & (M[..., 1] < 128)
    M[..., 1][cut] = 255
    Image.fromarray(M).save(mpath, optimize=True)
    print(name, "floating bits handed to the head:", int(up.sum()), "triangles,", int(cut.sum()), "pixels")


def main():
    args = sys.argv[1:]
    preview = None
    if "--preview" in args:
        k = args.index("--preview")
        preview = args[k + 1]
        del args[k:k + 2]
    if "--float" in args:
        args.remove("--float")
        for n in args:
            floating(n)
        return
    if "--trim" in args:
        args.remove("--trim")
        neck = "--neck" in args
        if neck:
            args.remove("--neck")
        for n in args:
            trim(n, neck)
        return
    if "--tails" in args:
        args.remove("--tails")
        for n in args:
            build(n, tails=True)
        return
    if "--collars" in args:
        args.remove("--collars")
        for n in args:
            build(n, collars=True)
        return
    names = args or sorted(f[:-4] for f in os.listdir(PEOPLE) if f.startswith("hero_") and f.endswith(".glb"))
    table = {}
    path = os.path.join(PEOPLE, "masks", "refs.json")
    if os.path.exists(path):
        table = json.load(open(path))
    for n in names:
        table[n] = build(n, preview)
        print(n, json.dumps(table[n]))
    json.dump(table, open(path, "w"), indent=1, sort_keys=True)
    # fill the seams of the new masks and the pictures, and make the face one even skin
    import hero_seams
    for n in names:
        hero_seams.fix(n)
    if os.environ.get("HERO_NO_GD"):
        return
    lines = ["class_name HeroMasks", "## Made by tools/hero_masks.py. The usual color of each part of every built-in hero model,",
             "## so the game can repaint it. Do not edit by hand.", "", "const REFS := {"]
    for n in sorted(table):
        t = table[n]
        lines.append('\t"%s": {%s},' % (n, ", ".join('"%s": Color(%s, %s, %s)' % (k, *t[k]) for k in ("skin", "hair", "top", "bottom", "shoes"))))
    lines += ["}", ""]
    open(os.path.join(HERE, "..", "scripts", "core", "hero_masks.gd"), "w").write("\n".join(lines))


if __name__ == "__main__":
    main()
