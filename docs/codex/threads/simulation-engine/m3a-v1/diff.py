import json,sys
from pathlib import Path
def diff(a,b,p=''):
    if type(a)!=type(b): print(p,a,b)
    elif isinstance(a,dict):
        for k in a: diff(a[k],b.get(k),p+'/'+k)
    elif a!=b: print(p,a,b)
for row in json.loads(Path(sys.argv[1]).read_text(encoding='utf-8')):
    print(row['seed'],row.get('controlled',row.get('scenario')))
    diff(row['original'],row['live'],'original/live')
    diff(row['live'],row['headless'],'live/headless')
