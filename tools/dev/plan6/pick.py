import os
RELAX=os.environ.get('RELAX')=='1'
import json,collections,re,sys
d=json.load(open('/tmp/dl_ygo/yy/cards.json'))
game=set(int(x) for x in open('/tmp/game_ids.txt'))
LP=re.compile(r'Link Monster|Link Summon|Link Rating|Extra Monster Zone|co-linked|linked|Pendulum|Link-\d')
LIST=re.compile(r'Fusion, Synchro, Xyz,? (?:or|and) Link Monsters?')
byname={c['name']['en']:c for c in d if c.get('password')}
def ok(c):
    tl=c.get('monster_type_line') or ''
    if 'Link' in tl or 'Pendulum' in tl: return False
    if LP.search(LIST.sub('X',(c.get('text') or {}).get('en','')) if RELAX else (c.get('text') or {}).get('en','')): return False
    return c['password'] not in game
picked={}   # name -> group
# 1. Newer support for the four shows' families and aces
FOUR=["Dark Magician","Magician Girl","Blue-Eyes","Red-Eyes","Black Luster Soldier","Chaos","Exodia","Forbidden One","Toon","Kuriboh","Jinzo","Gaia","Elemental HERO","Destiny HERO","Masked HERO","Evil HERO","Vision HERO","HERO","Neo-Spacian","Neos","Yubel","Cyber Dragon","Cyberdark","Harpie","Ojama","Crystal Beast","Ancient Gear","Armed Dragon","Stardust","Synchron","Junk","Black Rose","Blackwing","Black-Winged","Red Dragon Archfiend","Power Tool","Majestic","Earthbound","Malefic","Infernity","Utopia","Utopic","ZW -","Zexal","Galaxy-Eyes","Photon","Number","Rank-Up-Magic","Gimmick Puppet","Shark","Gladiator Beast","Six Samurai","Noble Knight","Fire King","Machina","Evol","Artifact","Watt","Laval","Mecha Phantom","Hieratic","Geargia","Gogogo","Heraldic","Sylvan","Fortune Lady","Destiny Board","Spirit of","Celtic Guard","Celestial","Batteryman","Gravekeeper","Buster Blader"]
pool=[c for c in d if c.get('password') and (c.get('konami_id') or 0)>=11213 and ok(c)]
rank={'UR':0,'SR':1,'R':2,'N':3}
four=[]
for c in pool:
    n=c['name']['en']; t=(c.get('text') or {}).get('en','')
    if any(k in n or f'"{k}' in t for k in FOUR):
        four.append(c)
for c in four: picked[c['name']['en']]=('four',c)
# 2. Staples by name
STAPLES=[l.strip() for l in open('staples.txt') if l.strip() and not l.startswith('#')]
miss=[]
for n in STAPLES:
    c=byname.get(n)
    if not c: miss.append(n+' (not found)'); continue
    if c['password'] in game: miss.append(n+' (in game)'); continue
    if not ok(c): miss.append(n+' (link/pend)'); continue
    picked.setdefault(n,('staple',c))
# 3. Whole new families
FAM=sys.argv[1].split(',')
for c in pool:
    ss=c.get('series') or []
    for f in FAM:
        if f in ss or f in c['name']['en']:
            picked.setdefault(c['name']['en'],('fam:'+f,c))
# families: also members that are Link/Pend are dropped; report
for l in open('fam_extra.txt'):
    if '|' in l:
        g,n=l.strip().split('|',1); c=byname.get(n)
        if c and ok(c): picked.setdefault(n,('fam:'+g,c))
        else: print('fam extra problem', n)
for n in [l.strip() for l in open('drop.txt') if l.strip()]:
    picked.pop(n,None)
cnt=collections.Counter(v[0] for v in picked.values())
print(cnt, 'total', len(picked))
print('staple issues:', miss)
json.dump({n:{'group':g,'password':c['password'],'kid':c['konami_id']} for n,(g,c) in picked.items()}, open('picked.json','w'), indent=0)
