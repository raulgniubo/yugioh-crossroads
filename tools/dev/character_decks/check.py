import re, json, db
from decks import D
def parse(s):
    out=[]
    for part in s.split('|'):
        part=part.strip()
        if not part: continue
        m=re.match(r'^(.*) x(\d)$',part)
        out.append((m.group(1),int(m.group(2))) if m else (part,1))
    return out
T=json.load(open('/tmp/dk/tune.json'))
allnew=set(); tot=0
for k,d in D.items():
    main=parse(d['m'])+parse(d['s'])+parse(d['t']); ex=parse(d['e'])
    nm=sum(c for _,c in main); ne=sum(c for _,c in ex)
    prob=[]
    for sec,lst,want in (('m',parse(d['m']),('effect','normal','ritual')),('s',parse(d['s']),('spell',)),('t',parse(d['t']),('trap',)),('e',ex,('fusion','synchro','xyz'))):
        for n,c in lst:
            x=db.BY.get(n.lower())
            if not x: prob.append('UNKNOWN '+n); continue
            f=x.get('frameType','')
            if 'pendulum' in f or f=='link': prob.append('LINK/PEND '+n)
            elif not any(f.startswith(w) for w in want): prob.append('WRONG SECTION %s (%s)'%(n,f))
            if c>3: prob.append('>3 '+n)
    names=[n for n,_ in main+ex]
    dup=set(n for n in names if names.count(n)>1)
    new=[n for n in dict.fromkeys(names) if n.lower() in db.BY and db.BY[n.lower()]['id'] not in db.POOL]
    allnew|=set(new)
    old=set(T[k]['main'])|set(T[k]['extra'])
    kept=[n for n in dict.fromkeys(names) if n in old]
    d['_new']=new; d['_kept']=kept; d['_nm']=nm; d['_ne']=ne
    print('%-8s main %d extra %d  new %d  kept-from-old %d  %s %s'%(k,nm,ne,len(new),len(kept),'DUP %s'%dup if dup else '', ' | '.join(prob)))
print('decks',len(D),'distinct new cards',len(allnew))
json.dump({k:{'new':d['_new'],'kept':d['_kept']} for k,d in D.items()},open('/tmp/dk/res.json','w'))
json.dump(sorted(allnew),open('/tmp/dk/allnew.json','w'))
