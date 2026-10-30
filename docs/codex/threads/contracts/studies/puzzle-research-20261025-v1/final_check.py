from run import *
import re
sys.path.insert(0,str(ROOT/'tools'))
import simulator_variant as v
assert load(HERE/'verification.json')['status']=='PASS'
assert hashlib.sha256((HERE/'discovery-analysis.json').read_bytes()).hexdigest()==load(HERE/'selection.json')['discovery_analysis_sha256']
assert hashlib.sha256((HERE/'policy.gd').read_bytes()).hexdigest()==load(HERE/'pin.json')['policy_sha256']
assert hashlib.sha256((HERE/'PLAN.md').read_bytes()).hexdigest()==load(HERE/'pin.json')['plan_sha256']
names=['PUZZLE-RESEARCH-FINDINGS-2026-10-25-v1.md','PUZZLE-RESEARCH-HANDOFF-2026-10-25-v1.md','SESSION-2026-10-25-PUZZLE-RESEARCH-v1.md'];links=0
for name in names:
    p=THREAD/name
    for target in re.findall(r'\]\(([^)]+)\)',p.read_text(encoding='utf-8')):
        if '://' in target:continue
        assert (p.parent/target.split('#')[0]).resolve().exists(),(name,target);links+=1
todo=(ROOT/'docs/codex/TODO.md').read_bytes();prior=(HERE/'TODO.before').read_bytes();old=(HERE/'TODO-replaced-paragraph.before').read_bytes()
start=todo.index(b'**Crown paid-Search Brief');nl=b'\r\n' if b'\r\n' in todo else b'\n';end=todo.index(nl+nl,start);assert todo[:start]+old+todo[end:]==prior
for name in ['README.md','HANDOFF.md']:
    b=(HERE/(name+'.before')).read_bytes();now=(THREAD/name).read_bytes();first=b.index(b'\n')+1;assert now.startswith(b[:first]) and now.endswith(b[first:])
canonical=v.sim.source_hashes(ROOT/'patch-notes');candidate=v.sim.source_hashes(VAR/'project');before=load(HERE/'source-before.json');assert candidate==before['candidate']
delta=v.delta(before['canonical'],canonical)
# The initial strict check caught a concurrent standalone diagnostic addition.
# It was inspected (no class_name, no runtime references); preserve it and report it.
assert all(d['path']=='scripts/debug/profile_campaign_latency.gd' and d['change']=='added' for d in delta),delta
status=subprocess.run(['git','status','--short'],cwd=ROOT,capture_output=True,text=True,encoding='utf-8',errors='replace');(HERE/'status-after.txt').write_text(status.stdout,encoding='utf-8')
write(HERE/'final-check.json',dict(status='PASS_WITH_RECORDED_CANONICAL_DIAGNOSTIC_DRIFT',links=links,unrelated_todo_bytes_preserved=True,old_thread_index_bytes_preserved=True,frozen_candidate_unchanged=True,canonical_full_source_unchanged=not delta,canonical_delta=delta,canonical_identity=v.identity(canonical),policy_plan_unchanged=True,discovery_selection_hash_exact=True,document_hashes={name:hashlib.sha256((THREAD/name).read_bytes()).hexdigest() for name in names}))
print('PASS with recorded standalone diagnostic drift: '+str(links)+' links; untouched TODO/index bytes; frozen candidate/policy/plan hashes; retained discovery selection hash.')
