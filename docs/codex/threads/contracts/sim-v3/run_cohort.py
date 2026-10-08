from concurrent.futures import ThreadPoolExecutor
import gzip, itertools, json
from run import run, HERE

def execute(config):
    startup,policy,alignment,neon=config
    name=f'route-{startup}-{policy}-{alignment}-{neon}'
    path=HERE/name
    args=['--script','res://analysis/task34_cohort_v3.gd','--',f'--startup={startup}',f'--policy={policy}',f'--alignment={alignment}',f'--neon={neon}',f'--out={path}']
    run(name,args,180)
    raw=path.with_suffix('.json').read_bytes()
    data=json.loads(raw)
    assert data['valid'] and not data['errors'] and not data['discrepancies']
    path.with_suffix('.json.gz').write_bytes(gzip.compress(raw))
    return {'route':name,'releases':[{k:x[k] for k in ('cycle','final_review','awareness','cash_cents')} for x in data['releases']],'stop':data['stop']}

if __name__ == '__main__':
    configs=list(itertools.product(('legacy','trait'),('ordinary','synergy'),(0,1),(0,1)))
    with ThreadPoolExecutor(max_workers=2) as pool: results=list(pool.map(execute,configs))
    (HERE/'cohort-index.json').write_text(json.dumps(results,indent=2))
    print('Native preparation routes',len(results))
