"""make(spec, strings): write the family spec, add it to the game, add its Spanish interface strings."""
import json, subprocess, sys
def make(spec, strings):
    f = '/home/claude/work/families/%s.json' % spec['key']
    names = json.load(open('/tmp/fam_%s.json' % spec.get('scan', spec['key'])))
    spec['cards'] = [n for n in names if n not in spec.get('drop', [])]
    n_main = sum(spec['deck']['cards'].values()); n_ex = sum(spec['deck'].get('extra', {}).values())
    assert n_main == 40, 'deck has %d' % n_main
    missing = [n for n in list(spec['deck']['cards']) + list(spec['deck'].get('extra', {})) if n not in spec['cards']]
    print(spec['key'], len(spec['cards']), 'cards; deck', n_main, '+', n_ex, '; deck cards from outside the family:', len(missing))
    json.dump(spec, open(f, 'w'), indent=1, ensure_ascii=False)
    r = subprocess.run(['python3', '/home/claude/yugioh-crossroads/tools/add_family.py', f], capture_output=True, text=True)
    print(r.stdout.strip(), r.stderr.strip()[-300:])
    if r.returncode != 0: sys.exit(1)
    with open('/home/claude/work/i18n/es/extras.tsv', 'a', encoding='utf-8') as t:
        for a, b in strings: t.write(a + '\t' + b + '\n')
    r = subprocess.run(['python3', 'build.py'], cwd='/home/claude/work/i18n', capture_output=True, text=True)
    print(r.stdout.strip().split('\n')[-1])
