import importlib.util,sys
for k in sys.argv[1:]:
    s=importlib.util.spec_from_file_location('m','/home/claude/work/cardes2/%s.py'%k);m=importlib.util.module_from_spec(s);s.loader.exec_module(m)
    names=[l.split(' || ')[0] for l in open('/tmp/tr_%s.txt'%k) if l.strip()]
    print(k,len(m.ES),'missing',[n for n in names if n not in m.ES],'extra',[n for n in m.ES if n not in names])
