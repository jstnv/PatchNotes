from pathlib import Path
import hashlib,json,re,sys,subprocess
HERE=Path(__file__).resolve().parent;ROOT=HERE.parents[5];THREAD=HERE.parents[1]
sys.path.insert(0,str(ROOT/'tools'));import simulator_variant as variant
def load(p):return json.loads(p.read_text(encoding='utf-8-sig'))
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
files=['CROWN-GRADE-FEEDBACK-DESIGN-2026-10-25-v1.md','CROWN-GRADE-FEEDBACK-FINDINGS-2026-10-25-v1.md','CROWN-PREVIEW-HANDOFF-2026-10-25-v3.md','SESSION-2026-10-25-CROWN-GRADE-FEEDBACK-v1.md']
links=0
for name in files:
    for target in re.findall(r'\]\(([^)]+)\)',(THREAD/name).read_text(encoding='utf-8')):
        if target.startswith(('https:','http:','#')):continue
        assert (THREAD/target.split('#')[0]).exists(),(name,target)
        links+=1
p=load(HERE/'publication.json');todo=(ROOT/'docs/codex/TODO.md').read_bytes()
assert todo.count(p['todo_replacement'].encode())==1
assert todo.replace(p['todo_replacement'].encode(),p['todo_original'].encode(),1)==(HERE/'TODO.before.md').read_bytes()
for name,r in p['indexes'].items():
    current=(THREAD/name).read_bytes();addition=r['addition'].encode()
    assert current.count(addition)==1 and current.replace(addition,b'',1)==(HERE/(name+'.before')).read_bytes()
pins=load(HERE/'command-v1.json')['input_code']
assert all(sha(HERE/name)==h for name,h in pins.items())
input_pins=load(HERE/'run-v1/input-pins.json');assert all(sha(Path(name))==h for name,h in input_pins.items())
assert sha(HERE/'cap_reminder_check.py')==load(HERE/'cap-reminder-v1.json')['script_sha256']
frozen=variant.sim.source_hashes(THREAD/'simulators/early-brief-affordability-20261025-v1/project')
before=load(HERE/'source-before.json');assert frozen==before['frozen_source']
canonical=variant.sim.source_hashes(ROOT/'patch-notes')
after=dict(canonical_identity=variant.identity(canonical),canonical_source=canonical,canonical_delta_since_start=variant.delta(before['canonical_source'],canonical),frozen_identity=variant.identity(frozen),frozen_source_unchanged=True)
(HERE/'source-after.json').write_text(json.dumps(after,indent=2)+'\n',encoding='utf-8')
for name,args in [('head',['git','rev-parse','HEAD']),('status',['git','status','--short']),('diff',['git','diff','--stat'])]:
    r=subprocess.run(args,cwd=ROOT,capture_output=True,text=True,encoding='utf-8',errors='replace');assert r.returncode==0
    (HERE/(name+'-after.txt')).write_text(r.stdout,encoding='utf-8')
hashes={str(path.relative_to(THREAD)):sha(path) for path in list(HERE.glob('*.py'))+list(HERE.glob('*.md'))+list(HERE.glob('*.json'))+list((HERE/'run-v1').glob('*.json'))+[THREAD/name for name in files] if path.name!='final-check.json'}
report=dict(status='PASS',local_links=links,original_inputs_unchanged=len(input_pins),original_reference_and_plan_unchanged=True,old_thread_index_bytes_preserved=True,unrelated_todo_bytes_preserved=True,frozen_source_unchanged=True,canonical_drift_paths=len(after['canonical_delta_since_start']),document_and_evidence_hashes=hashes)
(HERE/'final-check.json').write_text(json.dumps(report,indent=2)+'\n',encoding='utf-8')
print(json.dumps({k:v for k,v in report.items() if k!='document_and_evidence_hashes'}))
