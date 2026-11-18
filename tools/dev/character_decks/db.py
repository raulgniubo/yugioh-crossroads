import json,re,sys
C=json.load(open('/tmp/testassets2/cards.json'))
C = C if isinstance(C,list) else C.get('data',C)
BY={x['name'].lower():x for x in C}
POOL=set(int(l) for l in open('/tmp/ocg_ids.txt') if l.strip())
def kind(x):
    f=x.get('frameType','')
    return f
def info(n,full=False):
    x=BY.get(n.lower())
    if not x: return None
    f=kind(x); lv=x.get('level') or x.get('linkval') or ''
    s='%s [%s%s %s %s/%s]%s'%(x['name'],f,(' L%s'%lv) if lv else '',x.get('race',''),x.get('atk',''),x.get('def',''),'' if x['id'] in POOL else ' NEW')
    if full: s+='\n    '+x.get('desc','').replace('\n',' ')[:full if isinstance(full,int) and full>1 else 600]
    return s
def find(pat,frame=None):
    r=re.compile(pat,re.I)
    return [x for x in C if r.search(x['name']) and (frame is None or frame in x.get('frameType',''))]
if __name__=='__main__':
    for a in sys.argv[1:]:
        if a.startswith('~'):
            for x in find(a[1:]): print(info(x['name']))
        else: print(info(a,True) or ('?? '+a))
