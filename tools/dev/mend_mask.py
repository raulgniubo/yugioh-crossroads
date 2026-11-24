#!/usr/bin/env python3
"""Mend the mask of a hero head where tools/hero_masks.py left parts unmarked (0.73.2).

  godot --headless --path . res://tests/tri_dump.tscn -- --model=<m> --out=/tmp/masktool/tris/<m>.json
  python3 tools/dev/mend_mask.py <m> [--face] [--dry]

Every texel is given the place on the body of the triangle it belongs to (from tri_dump), then:
  - irises: unmarked texels (id 0) next to an eye, with a clear color (not the white of the eye,
    not a lash) become eyes (220), so the picked eye color takes all of the iris;
  - hair: unmarked texels on the head (mask G = 255) above the eyes or behind them, away from the
    eyes, become hair (80): stray strands and eyebrows that kept the model's own grey;
  - --face (generated heads whose face texture is a patchwork, like Pixie Cut): the front of the
    face below the brows is all skin, and its texels far from a skin color are painted the face's
    own skin color in the texture (the shading comes from the light, the features from the eyes).
Then: godot --headless --path . --import (in the repo).
"""
import json
import os
import sys

import numpy as np
from PIL import Image, ImageDraw

PEOPLE = "assets/models/people/"
m = sys.argv[1]
face = "--face" in sys.argv
flat = "--flat" in sys.argv
only_mouth = "--only-mouth" in sys.argv
dry = "--dry" in sys.argv

mask_img = Image.open(PEOPLE + "masks/%s.png" % m).convert("RGB")
mk = np.array(mask_img)
ids = mk[..., 0].astype(int)
G = mk[..., 1].astype(int)
H, W = ids.shape
import glob
_tp = PEOPLE + "%s_Image_0.png" % m
if not os.path.exists(_tp):
    _c = [f for f in glob.glob(PEOPLE + m + "_*.png")]
    _tp = _c[0] if _c else _tp
tex_img = Image.open(_tp).convert("RGB")
if tex_img.size != (W, H):
    tex_img = tex_img.resize((W, H), Image.LANCZOS)
tex = np.asarray(tex_img).astype(float) / 255.0

tris = json.load(open("/tmp/masktool/tris/%s.json" % m))
tri_img = Image.new("I", (W, H), 0)
d = ImageDraw.Draw(tri_img)
for n, t in enumerate(tris):
    d.polygon([(t[0] * W, t[1] * H), (t[2] * W, t[3] * H), (t[4] * W, t[5] * H)], fill=n + 1)
tri = np.asarray(tri_img)
pos = np.array([[0, 0, 0]] + [t[6:9] for t in tris], float)
P = pos[tri]
has = tri > 0

mx = tex.max(-1)
mn = tex.min(-1)
sat = np.where(mx > 1e-4, (mx - mn) / np.maximum(mx, 1e-4), 0)

head = has & (G > 200)
hp = P[head]
hc = hp.mean(0)
eye = has & (np.abs(ids - 220) < 9) & (G > 200)
ep = P[eye]
if len(ep) < 50:
    sys.exit("%s: no eyes marked, nothing to go by" % m)
# (the middle line of the face is between the eyes: a head mask that takes in a long ponytail
# has its own middle somewhere else)
hc = hc.copy()
# The two eyes: the densest place of eye texels is one; the other is its mirror across the head.
# (Pieces of hair marked as eye, often several, must not pull either one away.)
eye_idx = np.argwhere(eye)
rng = np.random.default_rng(1)
smp = ep[rng.choice(len(ep), min(len(ep), 2500), replace=False)]
# (a pair: two dense places at the same height and depth, an eye's width apart; pieces of hair
# marked as eye have no such partner)
dens = np.array([(np.linalg.norm(smp - q, axis=1) < 0.018).sum() for q in smp])
best = (-1, None, None)
order = np.argsort(-dens)
for i in order:
    q = smp[i]
    ok = (np.abs(smp[:, 1] - q[1]) < 0.008) & (np.abs(smp[:, 2] - q[2]) < 0.012) & (np.abs(smp[:, 0] - q[0]) > 0.05) & (np.abs(smp[:, 0] - q[0]) < 0.13)
    if not ok.any():
        continue
    j = np.flatnonzero(ok)[dens[ok].argmax()]
    sc = min(dens[i], dens[j])
    if sc > best[0]:
        best = (sc, q, smp[j])
a = best[1]
b_guess = best[2]
if a is None:
    a = smp[dens.argmax()]
    b_guess = np.array([2 * np.median(ep[:, 0]) - a[0], a[1], a[2]])
centers = []
for guess in (a, b_guess):
    c = guess
    for _ in range(3):
        near = np.linalg.norm(ep - c, axis=1) < 0.015
        if near.sum() < 30:
            break
        c = np.median(ep[near], 0)
    centers.append(c)
eyes = []
boxes = []
for c in centers:
    dist = np.linalg.norm(ep - c, axis=1)
    core = dist < 0.03
    r = (np.percentile(dist[core], 90) * 1.1) if core.sum() > 30 else 0.02
    eyes.append((c, r))
    yx = eye_idx[dist < r]
    if len(yx) == 0:
        continue
    y0, x0 = yx.min(0)
    y1, x1 = yx.max(0)
    py, px = int((y1 - y0) * 0.2) + 4, int((x1 - x0) * 0.2) + 4
    boxes.append((max(0, y0 - py), min(H, y1 + py + 1), max(0, x0 - px), min(W, x1 + px + 1)))
hc[0] = (centers[0][0] + centers[1][0]) / 2.0
print("  eyes at %s and %s" % (centers[0].round(3), centers[1].round(3)))
eye_y = np.mean([e[0][1] for e in eyes])
eye_r = np.mean([e[1] for e in eyes])
front = np.sign(np.mean([e[0][2] for e in eyes]) - hc[2]) or 1.0
print("%s: head center %s, eyes at y %.3f r %.3f, front %+d" % (m, hc.round(3), eye_y, eye_r, front))


def near_eye(k):
    out = np.zeros(ids.shape, bool)
    for c, r in eyes:
        out |= np.linalg.norm(P - c, axis=-1) < r * k
    return out


new = ids.copy()
# the mouth and what is drawn around it, left unmarked: its own paint showed (a blue mouth on
# Ponytail from a few steps away). On the face, it is skin: its lines stay (HeroLook keeps what is
# drawn darker than the skin), its stray color goes.
eye_dx0 = max(abs(e[0][0] - hc[0]) for e in eyes)
r_eff = max(np.mean([e[1] for e in eyes]), 0.012)
fz = np.mean([e[0][2] for e in eyes])
# (also lips marked as the jacket: a blue mouth on the Track Jacket)
mouth = has & ((ids < 20) | (np.abs(ids - 220) < 9) | (np.abs(ids - 120) < 12) | (np.abs(ids - 160) < 12) | (np.abs(ids - 200) < 9) | (ids > 231)) \
    & (P[..., 1] < eye_y - r_eff * 1.3) & (P[..., 1] > eye_y - 0.095) \
    & (np.abs(P[..., 0] - hc[0]) < eye_dx0) & ((P[..., 2] - fz) * front > -0.03)
# (teeth stay as they are: white is no stray color)
new[mouth] = 40
print("  mouth and around it made skin: %d texels" % mouth.sum())
if only_mouth:
    if not dry:
        mk[..., 0] = new.astype(np.uint8)
        Image.fromarray(mk).save(PEOPLE + "masks/%s.png" % m)
        print("  saved")
    sys.exit(0)
# bits marked as eye far from both eyes (strands of hair, painted like an iris): the hair's streak
stray = eye & ~near_eye(1.8)
new[stray] = 240
print("  stray eye bits made the hair streak: %d texels" % stray.sum())
none = has & (new < 20)
# irises
inbox = np.zeros(ids.shape, bool)
for y0, y1, x0, x1 in boxes:
    inbox[y0:y1, x0:x1] = True
iris = none & near_eye(1.6) & inbox & (sat > 0.18) & (mx > 0.12) & (mx < 0.97)
new[iris] = 220
# stray hair and brows
up = P[..., 1] > eye_y + eye_r * 0.35
behind = (P[..., 2] - hc[2]) * front < 0
hair = none & (G > 200) & ~near_eye(1.7) & (up | behind) & ~iris
new[hair] = 80
# pieces anywhere on the head that are painted just like its hair (a strand by a temple, a lock
# over a cheek): hair too
hsel = head & (np.abs(ids - 80) < 9)
if hsel.sum() > 500:
    hcol = np.median(tex[hsel], 0)
    like = none & (G > 200) & ~(inbox & near_eye(1.25)) & ~iris & (np.linalg.norm(tex - hcol, axis=-1) < 0.13) & (sat < 0.25) & (mx < 0.92)
    new[like] = 80
    print("  hair by color %s: +%d texels" % ((hcol * 255).round(), like.sum()))
# whatever unmarked hangs in front of the face (a lock over an eye) or out at the sides (a lock by
# the cheek) is hair as well
eye_z = np.mean([e[0][2] for e in eyes])
eye_dx = max(abs(e[0][0] - hc[0]) for e in eyes)
lum = tex @ np.array([0.2126, 0.7152, 0.0722])
hangs = none & (G > 200) & ~(inbox & near_eye(1.25)) & ~iris & (mx < 0.92) & (
    (((P[..., 2] - eye_z) * front > 0.02) & (np.abs(P[..., 0] - hc[0]) > 0.015) & (P[..., 1] > eye_y - 0.02)) | ((np.abs(P[..., 0] - hc[0]) > eye_dx + 0.03) & (P[..., 1] > eye_y - 0.1)))
new[hangs] = 80
# eyebrows painted on the skin (marked skin): the dark strokes just above each eye take the hair color
skin_sel = head & (np.abs(ids - 40) < 12)
skin_lum = np.median(lum[skin_sel]) if skin_sel.sum() > 500 else 0.7
brow = np.zeros(ids.shape, bool)
for c, r in eyes:
    rr = max(r, 0.012)
    brow |= (P[..., 1] > c[1] + rr * 0.7) & (P[..., 1] < c[1] + rr * 4.5) & (np.abs(P[..., 0] - c[0]) < rr * 2.6)
skin_sat = np.median(sat[skin_sel]) if skin_sel.sum() > 500 else 0.3
brow &= skin_sel & (((lum < skin_lum * 0.72)) | ((lum < skin_lum * 0.82) & (sat < skin_sat * 0.7))) & ~near_eye(1.0)
new[brow] = 80
print("  hanging locks +%d, brows +%d texels" % (hangs.sum(), brow.sum()))
print("  irises +%d texels, hair +%d texels" % (iris.sum(), hair.sum()))

if face:
    half = np.percentile(np.abs(hp[:, 0] - hc[0]), 90)
    fr = ((P[..., 2] - hc[2]) * front) > 0.25 * half
    zone = head & fr & (P[..., 1] < eye_y + eye_r * 0.6) & (np.abs(P[..., 0] - hc[0]) < 0.62 * half) & ~near_eye(1.25)
    zone &= (np.abs(new - 220) >= 9) & (new < 232)
    skin = zone & (np.abs(ids - 40) < 12)
    ref = np.median(tex[skin & (sat > 0.15) & (mx > 0.55)], 0) if (skin & (sat > 0.15) & (mx > 0.55)).sum() > 200 else np.array([0.96, 0.8, 0.7])
    far = zone & (np.linalg.norm(tex - ref, axis=-1) > 0.22)
    new[zone] = 40
    t8 = np.asarray(Image.open(PEOPLE + "%s_Image_0.png" % m).convert("RGB")).copy()
    if t8.shape[:2] == (H, W) and "--repaint" in sys.argv:
        t8[far] = (ref * 255).round().astype(np.uint8)
        if not dry:
            Image.fromarray(t8).save(PEOPLE + "%s_Image_0.png" % m)
    print("  face: %d texels made skin, %d repainted to %s" % (zone.sum(), far.sum(), (ref * 255).round()))

if flat:
    # A generated head painted as a patchwork (Pixie Cut): every island of its picture has its own
    # tone, so whatever color is picked, the face and hair come out in patches. On the head, skin
    # is painted one skin tone and hair one hair tone (the light shades them; the eyes keep theirs).
    t8 = np.asarray(Image.open(PEOPLE + "%s_Image_0.png" % m).convert("RGB")).copy()
    keep = near_eye(1.2) | (np.abs(new - 220) < 9) | (new > 231)
    sk = head & (np.abs(new - 40) < 12) & ~keep
    hr = head & (np.abs(new - 80) < 12) & ~keep
    t8[sk] = (243, 204, 180)
    t8[hr] = (58, 52, 60)
    if not dry:
        Image.fromarray(t8).save(PEOPLE + "%s_Image_0.png" % m)
    print("  flat: %d skin texels, %d hair texels" % (sk.sum(), hr.sum()))

if not dry:
    mk[..., 0] = new.astype(np.uint8)
    Image.fromarray(mk).save(PEOPLE + "masks/%s.png" % m)
    print("  saved")
