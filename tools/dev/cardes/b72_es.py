"""0.72.0: official Spanish text for every card added in 0.72.0 (all cards with engine data that are not Links or
Pendulums). Sources: yaml-yugi aggregate (/tmp/dl_ygo/yy/cards.json) and, for cards newer than it, the per-card
files of yaml-yugi master (/tmp/yym/data/cards/<password>.json). Quoted names go back to English as in official_es.py.
  python3 tools/dev/cardes/b72_es.py names.json [--write]"""
import json, re, sys, glob
ROOT = __file__.rsplit('/tools/', 1)[0]
y = json.load(open('/tmp/dl_ygo/yy/cards.json'))
new = [json.load(open(f)) for f in glob.glob('/tmp/yym/data/cards/*.json')]
mine = {c['name']: c for c in json.load(open('/tmp/testassets3/cards.json'))}
by_pw = {}
for c in y + new:
    if c.get('password'): by_pw[c['password']] = c
es2en = {}
for c in y + new:
    es = (c.get('name') or {}).get('es')
    if es: es2en.setdefault(es, c['name']['en'])
Q = re.compile(r'"([^"]+)"')
out, missing = {}, []
for n in json.load(open(sys.argv[1])):
    m = mine.get(n); c = by_pw.get(m['id']) if m else None
    es = ((c or {}).get('text') or {}).get('es')
    if not es:
        missing.append(n); continue
    en = m.get('desc', '')
    qe, qn = Q.findall(es), Q.findall(en)
    if len(qe) == len(qn):
        it = iter(qn); es = Q.sub(lambda x: '"%s"' % next(it), es)
    else:
        es = Q.sub(lambda x: '"%s"' % es2en.get(x.group(1), x.group(1)), es)
    out[n] = es
print(len(out), 'texts;', len(missing), 'missing:', missing)
if '--write' in sys.argv:
    p = ROOT + '/data/card_text_es.json'
    d = json.load(open(p, encoding='utf-8'))
    k0 = len(d)
    for k, v in out.items(): d.setdefault(k, v)
    open(p, 'w', encoding='utf-8').write("{\n" + ",\n".join(json.dumps(k, ensure_ascii=False) + ": " + json.dumps(d[k], ensure_ascii=False) for k in sorted(d)) + "\n}\n")
    json.dump(out, open(ROOT + '/tools/dev/cardes/b72_official_es.json', 'w', encoding='utf-8'), ensure_ascii=False, indent=0)
    print('merged', len(d) - k0, 'new; total', len(d))
