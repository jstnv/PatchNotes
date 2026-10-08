from concurrent.futures import ThreadPoolExecutor
import gzip, json, shutil, sys
from run import run,HERE,PROJECT
from prepare import digest

def execute(item):
    route,publisher=item
    name=f'{publisher}-{route}'
    output=HERE/(name+'.json')
    hashes={n:digest(HERE/n) for n in ('advance.gd','cohort_advance.gd')}
    stamp=HERE/(name+'.harness.json')
    compressed=output.with_suffix('.json.gz')
    if not ((output.exists() or compressed.exists()) and stamp.exists() and json.loads(stamp.read_text())==hashes):
        run(name,['--script','res://analysis/task34_cohort_advance_v3.gd','--','--input='+str(HERE/(route+'.bin')),'--publisher='+publisher,'--out='+str(output)],600)
        stamp.write_text(json.dumps(hashes,indent=2))
    raw=output.read_bytes() if output.exists() else gzip.decompress(compressed.read_bytes());data=json.loads(raw)
    log=(HERE/(name+'.log')).read_text()
    assert 'TASK34_COHORT_ADVANCE' in log and 'SCRIPT ERROR' not in log and not data['failures']
    assert all('root certificate store' in x for x in log.splitlines() if x.startswith('ERROR:'))
    output.with_suffix('.json.gz').write_bytes(gzip.compress(raw))
    return {'case':name,'eligible':data['eligible'],'arms':len(data['results']),'checks':data['checks']}

if __name__=='__main__':
    for source,target in [('advance.gd','task34_advance_v3.gd'),('cohort_advance.gd','task34_cohort_advance_v3.gd')]:
        shutil.copy2(HERE/source,PROJECT/'analysis'/target)
    publisher=sys.argv[1]
    routes=[x['route'] for x in json.loads((HERE/'cohort-index.json').read_text())]
    if len(sys.argv)>2:routes=[sys.argv[2]]
    with ThreadPoolExecutor(max_workers=2) as pool: results=list(pool.map(execute,[(r,publisher) for r in routes]))
    (HERE/(publisher+'-index.json')).write_text(json.dumps(results,indent=2))
    print('Completed',publisher,len(results),'routes',sum(x['arms'] for x in results),'arms')
