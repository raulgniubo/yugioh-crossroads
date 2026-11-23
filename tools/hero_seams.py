#!/usr/bin/env python3
"""Clean the seams of the built-in hero models, so the face (and everything else) reads clean.

The hero models are auto-unwrapped: their pictures are hundreds of small islands on a black
background. Wherever the game's texture filtering reaches past the edge of an island (any pixel
near a seam, and more of them the farther away the hero stands, as smaller mipmaps are used)
it mixed that black in, which drew thin dark lines across the face. Their masks had a few stray
pixels of hair, clothes or the signature color in the middle of the face too, which the recolor
then painted as specks.

For every model this
  * fills every pixel of the picture that no triangle covers with the nearest covered one,
  * does the same for the mask (both what each pixel is and which part is the head),
  * makes every pixel of the head and neck that is painted in the skin's color skin, and small
    stray patches ringed by the face's skin skin too, so the face takes one even skin color.

  python3 tools/hero_seams.py [--src DIR] [model names...]

--src reads the untouched pictures from another copy of assets/models/people (the result is
always written here). Running it twice changes nothing more. tools/hero_masks.py runs it on the
models it has just made masks for.
"""
import os
import sys

import numpy as np
from PIL import Image

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import hero_masks as hm  # noqa: E402

SKIN = hm.IDS["skin"]
STRAY = 400          # a patch smaller than this (in 2048² pixels) inside the face's skin is a stray


def coverage(name):
    """Which picture pixels a triangle covers (pixel centre inside), and the picture's size."""
    j, b = hm.load(os.path.join(hm.PEOPLE, name + ".glb"))
    prim = j["meshes"][0]["primitives"][0]
    UV = hm.acc(j, b, prim["attributes"]["TEXCOORD_0"]).astype(np.float64)
    I = hm.acc(j, b, prim["indices"]).reshape(-1, 3).astype(np.int64)
    return UV, I


def raster(UV, I, H, W):
    cov = np.zeros((H, W), bool)
    px = np.stack([UV[:, 0] * W - 0.5, UV[:, 1] * H - 0.5], 1)
    for a, bb, c in px[I]:
        x0 = int(max(0, np.ceil(min(a[0], bb[0], c[0]))))
        x1 = int(min(W - 1, np.floor(max(a[0], bb[0], c[0]))))
        y0 = int(max(0, np.ceil(min(a[1], bb[1], c[1]))))
        y1 = int(min(H - 1, np.floor(max(a[1], bb[1], c[1]))))
        if x1 < x0 or y1 < y0:
            continue
        den = (bb[1] - c[1]) * (a[0] - c[0]) + (c[0] - bb[0]) * (a[1] - c[1])
        if abs(den) < 1e-12:
            continue
        xs, ys = np.meshgrid(np.arange(x0, x1 + 1), np.arange(y0, y1 + 1))
        l1 = ((bb[1] - c[1]) * (xs - c[0]) + (c[0] - bb[0]) * (ys - c[1])) / den
        l2 = ((c[1] - a[1]) * (xs - c[0]) + (a[0] - c[0]) * (ys - c[1])) / den
        l3 = 1 - l1 - l2
        e = -1e-6
        cov[y0:y1 + 1, x0:x1 + 1] |= (l1 >= e) & (l2 >= e) & (l3 >= e)
    return cov


def nearest(cov):
    """For every pixel, the row and column of the nearest covered pixel."""
    try:
        from scipy import ndimage
        return ndimage.distance_transform_edt(~cov, return_distances=False, return_indices=True)
    except ImportError:
        H, W = cov.shape
        iy, ix = np.indices((H, W))
        done = cov.copy()
        while not done.all():
            for dy, dx in ((0, 1), (0, -1), (1, 0), (-1, 0)):
                take = ~done & np.roll(done, (dy, dx), (0, 1))
                iy[take] = np.roll(iy, (dy, dx), (0, 1))[take]
                ix[take] = np.roll(ix, (dy, dx), (0, 1))[take]
                done |= take
        return np.stack([iy, ix])


def skin_like(ids, part, cov, T):
    """On the head and neck, a pixel painted in the skin's own color is skin, whatever the first
    guess said (shaded skin read as nothing, a pale forehead read as silver hair, an eyelid read
    as the eye). Left as it was, it kept its old color when the skin was recolored, or took the
    hair's or the eyes' color: blotches and pale streaks across the face."""
    zone = (part >= 128) & cov
    sk = zone & (ids == SKIN)
    if sk.sum() < 500:
        return 0
    lab = hm.srgb_to_lab(T)
    c = np.median(lab[sk], 0)
    d = np.hypot(lab[..., 1] - c[1], lab[..., 2] - c[2])
    hr = zone & (ids == hm.IDS["hair"])
    dh = np.full(d.shape, 1e9)
    if hr.sum() > 500:
        h = np.median(lab[hr], 0)
        dh = np.hypot(lab[..., 1] - h[1], lab[..., 2] - h[2]) + 0.5 * np.abs(lab[..., 0] - h[0])
    take = zone & (ids != SKIN) & (d < 9.0) & (lab[..., 0] > 30) & (dh > 2.0 * d + 6.0)
    ids[take] = SKIN
    return int(take.sum())


def strays(ids, head, cov):
    """Small patches of anything but skin, mostly ringed by skin, inside the head: they are skin."""
    try:
        from scipy import ndimage
    except ImportError:
        return 0
    skin = (ids == SKIN) & head
    fixed = 0
    for v in np.unique(ids[head & cov]):
        if v in (SKIN, 0, hm.IDS["eyes"]):
            continue
        lab, n = ndimage.label((ids == v) & head & cov)
        if n == 0:
            continue
        sizes = ndimage.sum(np.ones_like(lab), lab, range(1, n + 1))
        ring = ndimage.binary_dilation(lab > 0) & ~(lab > 0) & cov
        for k, sl in enumerate(ndimage.find_objects(lab)):
            if sizes[k] >= STRAY:
                continue
            ys = slice(max(0, sl[0].start - 2), sl[0].stop + 2)
            xs = slice(max(0, sl[1].start - 2), sl[1].stop + 2)
            me = lab[ys, xs] == k + 1
            edge = ndimage.binary_dilation(me) & ~me & ring[ys, xs]
            if edge.sum() and skin[ys, xs][edge].mean() > 0.75:
                ids[ys, xs][me] = SKIN
                fixed += int(sizes[k])
    return fixed


def textures(name):
    return [f for f in sorted(os.listdir(hm.PEOPLE)) if f.startswith(name + "_") and f.endswith(".png")
            and (f[len(name) + 1:].startswith("Material_") or f[len(name) + 1:].startswith("Image_"))]


def save(img, path):
    tmp = path + ".tmp.png"
    img.save(tmp, optimize=True)
    os.replace(tmp, path)       # a new file, never written through a link to another copy


def fix(name, src=None):
    src = src or hm.PEOPLE
    UV, I = coverage(name)
    mpath = os.path.join(hm.PEOPLE, "masks", name + ".png")
    mask = np.array(Image.open(os.path.join(src, "masks", name + ".png")).convert("RGB"))
    H, W = mask.shape[:2]
    cov = raster(UV, I, H, W)
    iy, ix = nearest(cov)
    ids = mask[..., 0].copy()
    part = mask[..., 1].copy()
    tx = textures(name)
    T0 = np.array(Image.open(os.path.join(src, tx[0])).convert("RGB")) if tx else None
    n_like = skin_like(ids, part, cov, T0) if T0 is not None and T0.shape[:2] == (H, W) else 0
    n_stray = strays(ids, part == 255, cov)
    ids = ids[iy, ix]
    part = part[iy, ix]
    out = np.dstack([ids, part, np.zeros_like(ids)])
    save(Image.fromarray(out), mpath)
    done = []
    for f in tx:
        img = Image.open(os.path.join(src, f))
        mode = img.mode
        t = np.array(img.convert("RGBA" if "A" in mode else "RGB"))
        if t.shape[:2] != (H, W):
            c2 = raster(UV, I, *t.shape[:2])
            jy, jx = nearest(c2)
            t = t[jy, jx]
        else:
            t = t[iy, ix]
        save(Image.fromarray(t), os.path.join(hm.PEOPLE, f))
        done.append(f)
    print("%s: %d of %d px filled; head px made skin: %d skin-colored, %d strays; %s" % (
        name, int((~cov).sum()), H * W, n_like, n_stray, ", ".join(done)))


def main():
    args = sys.argv[1:]
    src = None
    if "--src" in args:
        k = args.index("--src")
        src = args[k + 1]
        del args[k:k + 2]
    names = args or sorted(f[:-4] for f in os.listdir(hm.PEOPLE) if f.startswith("hero_") and f.endswith(".glb"))
    for n in names:
        fix(n, src)


if __name__ == "__main__":
    main()
