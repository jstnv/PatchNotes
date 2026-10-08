from concurrent.futures import ThreadPoolExecutor
import json
from run_advances import execute,HERE

if __name__=='__main__':
    routes=[x['route'] for x in json.loads((HERE/'no-contract-index.json').read_text())]
    with ThreadPoolExecutor(max_workers=2) as pool:
        results=list(pool.map(execute,[(r,'crown') for r in routes]))
    (HERE/'crown-supplement-index.json').write_text(json.dumps(results,indent=2))
    print('Supplement',len(results),'routes',sum(x['arms'] for x in results),'arms')
