#!/usr/bin/env python3
"""Release order for the era packs' volumes (0.53.0).

Konami's card database numbers each card when it first comes out, so sorting by that number
puts cards in release order. Reads yaml-yugi's aggregate cards.json (github.com/DawnbrandBots/
yaml-yugi, branch aggregate) and the game's card ids, and writes data/release_order.json:
{"<card id>": <konami id>}. Cards with no number (alternate arts are matched by name, the
game's own cards have none) are left out and go to the end of the last volume.
  python3 -I tools/dev/release/make_release_order.py <cards.json> <ids.txt> <cards.cdb> <out.json>
"""
import json, sys, sqlite3
src, ids_path, cdb, out = sys.argv[1:5]
cards = json.load(open(src))
by_pw, by_name = {}, {}
for c in cards:
    k = c.get("konami_id")
    if not k:
        continue
    k = int(k)
    if c.get("password"):
        by_pw[int(c["password"])] = k
    n = (c.get("name") or {}).get("en")
    if n:
        by_name[n.lower()] = min(k, by_name.get(n.lower(), k))
db = sqlite3.connect(cdb)
names = {r[0]: r[1] for r in db.execute("select id, name from texts")}
alias = {r[0]: r[1] for r in db.execute("select id, alias from datas")}
res, miss = {}, []
for line in open(ids_path):
    line = line.strip()
    if not line:
        continue
    i = int(line)
    k = by_pw.get(i) or by_pw.get(alias.get(i, 0) or -1) or by_name.get(str(names.get(i, "")).lower())
    if k:
        res[str(i)] = k
    elif i < 99000000:
        miss.append((i, names.get(i, "?")))
json.dump(res, open(out, "w"), separators=(",", ":"), sort_keys=True)
print("release order: %d cards numbered, %d official cards without a number" % (len(res), len(miss)))
for m in miss[:20]:
    print("  missing", m)
