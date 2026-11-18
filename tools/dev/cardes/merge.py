import json,sys,importlib.util
p='/home/claude/yugioh-crossroads/data/card_text_es.json'
d=json.load(open(p,encoding='utf-8'))
for f in sys.argv[1:]:
    spec=importlib.util.spec_from_file_location('m',f); m=importlib.util.module_from_spec(spec); spec.loader.exec_module(m)
    n=0
    for k,v in m.ES.items():
        if d.get(k)!=v: n+=1
        d[k]=v
    print(f, len(m.ES), 'entries,', n, 'new or changed')
ks=sorted(d.keys())
out="{\n"+",\n".join(json.dumps(k,ensure_ascii=False)+": "+json.dumps(d[k],ensure_ascii=False) for k in ks)+"\n}\n"
open(p,'w',encoding='utf-8').write(out)
print('total',len(d))
