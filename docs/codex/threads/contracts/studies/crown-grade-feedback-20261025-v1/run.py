from pathlib import Path
import json,subprocess,sys,hashlib,time
HERE=Path(__file__).resolve().parent;ROOT=HERE.parents[5]
sys.path.insert(0,str(ROOT/'tools'));import simulator_variant as variant
def write(name,obj):(HERE/name).write_text(json.dumps(obj,indent=2)+'\n',encoding='utf-8')
assert not (HERE/'execution-v1.json').exists()
frozen=HERE.parents[1]/'simulators/early-brief-affordability-20261025-v1/project'
source=variant.sim.source_hashes(frozen)
assert variant.identity(source)=='f7de61169758dcd874972c59e584c7b6a9a36f1fedc4f24b2398f6a2edfdf60f'
canonical=variant.sim.source_hashes(ROOT/'patch-notes')
write('source-before.json',dict(frozen_identity=variant.identity(source),frozen_source=source,canonical_identity=variant.identity(canonical),canonical_source=canonical,head=(HERE/'head.txt').read_text().strip(),branch=(HERE/'branch.txt').read_text().strip()))
pins={p.name:hashlib.sha256(p.read_bytes()).hexdigest() for p in [HERE/'PLAN.md',HERE/'reference.py',HERE/'analyze.py',HERE/'run.py']}
args=[sys.executable,str(HERE/'analyze.py'),'run-v1'];write('command-v1.json',dict(command=args,cwd=str(ROOT),timeout_seconds=60,input_code=pins))
start=time.time()
try:
    with (HERE/'driver-v1.log').open('w',encoding='utf-8') as log:
        result=subprocess.run(args,cwd=ROOT,stdout=log,stderr=subprocess.STDOUT,timeout=60)
    record=dict(exit_code=result.returncode,seconds=time.time()-start,timed_out=False)
except subprocess.TimeoutExpired:
    record=dict(exit_code=None,seconds=time.time()-start,timed_out=True)
assert variant.sim.source_hashes(frozen)==source
record['frozen_source_unchanged']=True;write('execution-v1.json',record);print(json.dumps(record))
