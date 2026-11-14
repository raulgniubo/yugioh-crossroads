#!/usr/bin/env python3
"""Pad the color textures of the people models.

The models' pictures are an atlas of many small islands on black. Wherever the picture is drawn
smaller than it is (a face a few steps away), the black between the islands bleeds into their
edges and shows as dark marks along the seams: lines on a nose, a cheek, a hand. This spreads
every island's own edge colors out into the black around it, so the seams have nothing dark
to pick up. The islands themselves are not touched.

  python3 tools/pad_textures.py [--out DIR] [names...]     (no names: every model in the folder)
"""
import glob
import json
import os
import struct
import sys

import numpy as np
from PIL import Image, ImageDraw

PEOPLE = os.environ.get("HERO_PEOPLE", os.path.join(os.path.dirname(__file__), "..", "assets", "models", "people"))
CT = {5120: "i1", 5121: "u1", 5122: "<i2", 5123: "<u2", 5125: "<u4", 5126: "<f4"}
NC = {"SCALAR": 1, "VEC2": 2, "VEC3": 3, "VEC4": 4, "MAT4": 16}
REACH = 24


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


def coverage(glb, size):
    """Which pixels of the picture some triangle of the model uses."""
    j, b = load(glb)
    w, h = size
    cov = Image.new("L", size, 0)
    draw = ImageDraw.Draw(cov)
    for mesh in j["meshes"]:
        for prim in mesh["primitives"]:
            if "TEXCOORD_0" not in prim["attributes"]:
                continue
            uv = acc(j, b, prim["attributes"]["TEXCOORD_0"]).astype(np.float64)
            uv = uv - np.floor(uv.min(0)) if uv.min() < 0 or uv.max() > 1 else uv
            idx = acc(j, b, prim["indices"]).reshape(-1, 3) if "indices" in prim else np.arange(len(uv)).reshape(-1, 3)
            px = np.stack([uv[:, 0] * w, uv[:, 1] * h], 1)
            for t in idx:
                draw.polygon([tuple(px[t[0]]), tuple(px[t[1]]), tuple(px[t[2]])], fill=255)
    return np.asarray(cov) > 0


def pad(img, cov, reach=REACH):
    out = img.astype(np.float32)
    have = cov.copy()
    for _ in range(reach):
        if have.all():
            break
        total = np.zeros_like(out)
        count = np.zeros(have.shape, np.float32)
        for dy in (-1, 0, 1):
            for dx in (-1, 0, 1):
                if dy == 0 and dx == 0:
                    continue
                h2 = np.roll(np.roll(have, dy, 0), dx, 1)
                total += np.roll(np.roll(out, dy, 0), dx, 1) * h2[:, :, None]
                count += h2
        new = (~have) & (count > 0)
        out[new] = total[new] / count[new][:, None]
        have |= new
    return np.clip(out + 0.5, 0, 255).astype(np.uint8)


def texture_of(name):
    for f in sorted(glob.glob(os.path.join(PEOPLE, name + "_*.png"))):
        return f
    return ""


def main():
    args = [a for a in sys.argv[1:] if not a.startswith("--")]
    out_dir = ""
    for a in sys.argv[1:]:
        if a.startswith("--out="):
            out_dir = a[6:]
    names = args or sorted(os.path.basename(f)[:-4] for f in glob.glob(os.path.join(PEOPLE, "*.glb")))
    for name in names:
        tex = texture_of(name)
        glb = os.path.join(PEOPLE, name + ".glb")
        if tex == "" or not os.path.exists(glb):
            continue
        im = Image.open(tex).convert("RGB")
        a = np.asarray(im)
        cov = coverage(glb, im.size)
        # One pixel in from every island's edge: those edge pixels were already mixed with black.
        inner = cov.copy()
        for dy, dx in ((-1, 0), (1, 0), (0, -1), (0, 1)):
            inner &= np.roll(np.roll(cov, dy, 0), dx, 1)
        res = pad(a, inner)
        dark_before = float((a.max(2) <= 4).mean())
        dark_after = float((res.max(2) <= 4).mean())
        Image.fromarray(res).save(os.path.join(out_dir, os.path.basename(tex)) if out_dir else tex, optimize=True)
        print("%-28s used %4.1f%%  black %4.1f%% -> %4.1f%%" % (name, cov.mean() * 100, dark_before * 100, dark_after * 100))


if __name__ == "__main__":
    main()
