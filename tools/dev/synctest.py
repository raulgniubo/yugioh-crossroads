#!/usr/bin/env python3
"""Bring the test copy (/home/claude/yc_test) up to date with the repo.
Big files (assets, voices, the import cache) are hard links: the copy costs almost no disk.
Scripts, tests, tools, scenes and the project files are real copies, so the repo can be edited
while tests run on the copy."""
import os, shutil, sys, time
S = "/home/claude/yugioh-crossroads"; D = "/home/claude/yc_test"
REAL = ("scripts", "tests", "tools", "scenes")
REAL_FILES = ("project.godot", "export_presets.cfg", ".godot/global_script_class_cache.cfg", ".godot/uid_cache.bin", ".godot/extension_list.cfg")
SKIP = (".git", "build", ".godot/editor", ".godot/shader_cache")
t0 = time.time(); linked = copied = removed = 0
seen = set()
for root, dirs, files in os.walk(S):
    rel = os.path.relpath(root, S)
    rel = "" if rel == "." else rel
    dirs[:] = [d for d in dirs if os.path.join(rel, d) not in SKIP]
    os.makedirs(os.path.join(D, rel), exist_ok=True)
    for f in files:
        r = os.path.join(rel, f); seen.add(r)
        s = os.path.join(S, r); d = os.path.join(D, r)
        real = r in REAL_FILES or r.split(os.sep)[0] in REAL
        try:
            ss = os.stat(s)
        except FileNotFoundError:
            continue
        ds = os.stat(d) if os.path.exists(d) else None
        if real:
            if ds is None or ds.st_ino == ss.st_ino or ds.st_size != ss.st_size or int(ds.st_mtime) != int(ss.st_mtime):
                tmp = d + ".tmp~"; shutil.copy2(s, tmp); os.replace(tmp, d); copied += 1
        elif ds is None or ds.st_ino != ss.st_ino:
            if ds is not None: os.remove(d)
            os.link(s, d); linked += 1
for root, dirs, files in os.walk(D):
    rel = os.path.relpath(root, D); rel = "" if rel == "." else rel
    if rel.split(os.sep)[0] == "build":
        continue      # what the exports made stays
    if rel.split(os.sep)[0] in (".godot",) and rel not in ("", ".godot"):
        if rel.startswith(".godot/editor") or rel.startswith(".godot/shader_cache"): continue
    for f in files:
        r = os.path.join(rel, f)
        if r not in seen and not r.startswith(".godot/editor") and not r.startswith(".godot/shader_cache") and not r.endswith(".tmp~"):
            os.remove(os.path.join(D, r)); removed += 1
print("synced: %d linked, %d copied, %d removed, %.1f s" % (linked, copied, removed, time.time() - t0))
