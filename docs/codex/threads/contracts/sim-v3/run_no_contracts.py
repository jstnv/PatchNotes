from concurrent.futures import ThreadPoolExecutor
import gzip,itertools,json
from run import run,HERE

def execute(config):
    startup,policy,alignment=config
    name=f'no-contract-{startup}-{policy}-{alignment}'
    path=HERE/name
    run(name,['--script','res://analysis/task34_cohort_v3.gd','--',f'--startup={startup}',f'--policy={policy}',f'--alignment={alignment}','--neon=0','--contracts=none',f'--out={path}'],180)
    raw=path.with_suffix('.json').read_bytes();a=json.loads(raw)
    assert a['valid'] and not a['errors'] and not a['discrepancies']
    path.with_suffix('.json.gz').write_bytes(gzip.compress(raw))
    return {'route':name,'stop':a['stop'],'releases':[{k:x[k] for k in ('cycle','final_review','awareness','cash_cents')} for x in a['releases']]}

if __name__=='__main__':
    with ThreadPoolExecutor(max_workers=2) as pool:
        results=list(pool.map(execute,itertools.product(('legacy','trait'),('ordinary','synergy'),(0,1))))
    (HERE/'no-contract-index.json').write_text(json.dumps(results,indent=2))
    print('No-Contract controls',len(results))
