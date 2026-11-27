#!/bin/bash
# Makes what gets sent for a version (0.82.0 on): the small update, and a new base when asked.
#
#   tools/dev/make_release.sh <out dir>             the update: one small zip for Windows, one for Mac
#   tools/dev/make_release.sh <out dir> --base N    the same, plus Base N (the big download, in parts)
#
# How a build is laid out (see scripts/core/packs.gd and addons/crossroads_packs/export_split.gd):
#   Crossroads.exe + ocgbridge dll   the program (changes only with the engine or the rules bridge)
#   Crossroads.pck                   the game: code, cards, menus, and every voice or model that is
#                                    new or changed since the base. THIS is the update.
#   base.pck                         the voices and the 3D models as they were when the base was made
#
# The Windows update zip holds Crossroads.pck, and the program files only when they are not the ones
# Base N shipped with. It is unzipped into the game folder, replacing what is there, and works from
# any older version on the same base. The Mac zip is the whole app (small: the base stays outside it,
# beside the app or in Crossroads Data).
#
# Make a new base (--base N+1) when the update has grown heavy with voices and models (150 MB or so),
# or when the engine changes the way it imports them. The game then asks for the new base by number.
#
# PROJECT is the copy the export runs in (import cache in place), REPO the git checkout.
set -e
OUT=${1:?where to put the files}; shift
BASE_ID=""
[ "$1" = "--base" ] && BASE_ID=$2
PROJECT=${PROJECT:-/home/claude/yc_test}
REPO=${REPO:-/home/claude/yugioh-crossroads}
PART=${PART:-215m}
MAN=tools/dev/base_manifest.json
export HOME=${GODOT_HOME:-/root}
cd "$PROJECT"
V=$(grep -m1 '^config/version=' project.godot | cut -d'"' -f2)
mkdir -p "$OUT" build/base build/windows build/mac
rm -f build/windows/* build/mac/*

if [ -n "$BASE_ID" ]; then
  echo "== Base $BASE_ID"
  rm -f build/base/base.pck
  CR_PACK=base CR_BASE_ID=$BASE_ID godot --headless --export-pack "Base" build/base/base.pck > /tmp/rel_base.log 2>&1
  grep "CrossroadsPacks" /tmp/rel_base.log
  python3 - "$MAN" build/base/base.pck <<'PY'
import json, os, sys
m = json.load(open(sys.argv[1])); m["bytes"] = os.path.getsize(sys.argv[2]); m.pop("program", None)
json.dump(m, open(sys.argv[1], "w"), indent=0, sort_keys=True)
PY
fi
[ -f build/base/base.pck ] || echo "(no base.pck in build/base: fine for an update, the manifest is what counts)"

echo "== Windows $V"
CR_PACK=main godot --headless --export-release "Windows" build/windows/Crossroads.exe > /tmp/rel_win.log 2>&1
grep "CrossroadsPacks" /tmp/rel_win.log
echo "== Mac $V"
CR_PACK=main godot --headless --export-release "macOS" build/mac/Crossroads.zip > /tmp/rel_mac.log 2>&1
grep "CrossroadsPacks" /tmp/rel_mac.log | grep -v "in the update"
ls build/windows/Crossroads.exe build/windows/Crossroads.pck build/windows/ocgbridge.windows.x86_64.dll build/mac/Crossroads.zip > /dev/null

if [ -n "$BASE_ID" ]; then
  # The program files this base ships with: an update carries them again only when they change.
  python3 - "$MAN" build/windows/Crossroads.exe build/windows/ocgbridge.windows.x86_64.dll <<'PY'
import hashlib, json, os, sys
m = json.load(open(sys.argv[1]))
m["program"] = {os.path.basename(p): hashlib.md5(open(p, "rb").read()).hexdigest() for p in sys.argv[2:]}
json.dump(m, open(sys.argv[1], "w"), indent=0, sort_keys=True)
PY
  cp "$MAN" "$REPO/$MAN"
  echo "== Base $BASE_ID package (the whole game for Windows, with base.pck)"
  rm -f "$OUT/Crossroads-Base$BASE_ID.zip" "$OUT"/Crossroads-Base$BASE_ID.part*
  (cd build/base && zip -q -0 "$OUT/Crossroads-Base$BASE_ID.zip" base.pck)
  (cd build/windows && zip -q -9 "$OUT/Crossroads-Base$BASE_ID.zip" Crossroads.exe ocgbridge.windows.x86_64.dll Crossroads.pck)
  md5sum "$OUT/Crossroads-Base$BASE_ID.zip" | cut -d' ' -f1 > /tmp/rel_base.md5
  (cd "$OUT" && split -b $PART --numeric-suffixes=1 --suffix-length=1 "Crossroads-Base$BASE_ID.zip" "Crossroads-Base$BASE_ID.part")
  [ "$(cat "$OUT"/Crossroads-Base$BASE_ID.part* | md5sum | cut -d' ' -f1)" = "$(cat /tmp/rel_base.md5)" ] && echo "parts join back to the zip: ok"
  rm -f "$OUT/Crossroads-Base$BASE_ID.zip"
fi

echo "== Windows update zip"
WZ="$OUT/Crossroads-$V-windows-update.zip"; rm -f "$WZ"
EXTRA=$(python3 - "$MAN" build/windows/Crossroads.exe build/windows/ocgbridge.windows.x86_64.dll <<'PY'
import hashlib, json, os, sys
prog = json.load(open(sys.argv[1])).get("program", {})
print(" ".join(os.path.basename(p) for p in sys.argv[2:] if prog.get(os.path.basename(p)) != hashlib.md5(open(p, "rb").read()).hexdigest()))
PY
)
[ -n "$EXTRA" ] && echo "the program changed since the base, the update carries: $EXTRA"
(cd build/windows && zip -q -9 "$WZ" Crossroads.pck $EXTRA)
echo "== Mac zip"
cp build/mac/Crossroads.zip "$OUT/Crossroads-$V-mac.zip"
ls -la "$OUT" | awk 'NR>1 && $9 !~ /^\.+$/ {printf "%8.1f MB  %s\n", $5/1e6, $9}'
