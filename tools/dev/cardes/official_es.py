"""Spanish card text for new cards from the official Spanish text in yaml-yugi (/tmp/dl_ygo/yy/cards.json).
Quoted card and archetype names go back to English (the game shows English card names): the i-th quote of
the Spanish text takes the i-th quote of the English text when both have as many; otherwise each quote goes
through the es->en name map. Merges into data/card_text_es.json (sorted, one entry per line).

  python3 tools/dev/cardes/official_es.py names.json [--write]
"""
import json, re, sys
ROOT = __file__.rsplit('/tools/', 1)[0]
y = json.load(open('/tmp/dl_ygo/yy/cards.json'))
by_en = {c['name']['en']: c for c in y if c.get('password')}
es2en = {}
for c in y:
    es = (c.get('name') or {}).get('es')
    if es: es2en.setdefault(es, c['name']['en'])
Q = re.compile(r'"([^"]+)"')
names = json.load(open(sys.argv[1]))
out, missing, odd = {}, [], []
for n in names:
    c = by_en.get(n)
    es = ((c or {}).get('text') or {}).get('es')
    en = ((c or {}).get('text') or {}).get('en', '')
    if not es:
        missing.append(n); continue
    qe, qn = Q.findall(es), Q.findall(en)
    if len(qe) == len(qn):
        it = iter(qn)
        es = Q.sub(lambda m: '"%s"' % next(it), es)
    else:
        es = Q.sub(lambda m: '"%s"' % es2en.get(m.group(1), m.group(1)), es)
        odd.append(n)
    out[n] = es
print(len(out), 'texts;', len(missing), 'with no official Spanish:', missing, '; quote counts differ (mapped by name):', len(odd))
if '--write' in sys.argv:
    p = ROOT + '/data/card_text_es.json'
    d = json.load(open(p, encoding='utf-8'))
    new = sum(1 for k in out if k not in d)
    for k, v in out.items():
        d.setdefault(k, v)
    ks = sorted(d)
    open(p, 'w', encoding='utf-8').write("{\n" + ",\n".join(json.dumps(k, ensure_ascii=False) + ": " + json.dumps(d[k], ensure_ascii=False) for k in ks) + "\n}\n")
    json.dump(out, open(ROOT + '/tools/dev/cardes/b56_official_es.json', 'w', encoding='utf-8'), ensure_ascii=False, indent=0)
    print('merged', new, 'new; total', len(d))
