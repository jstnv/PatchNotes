from run import *
import re
sys.path.insert(0,str(ROOT/'tools'))
import simulator_variant as v
names=['CROWN-ACCESS-POLICY-FINDINGS-2026-10-25-v1.md','CROWN-ACCESS-POLICY-HANDOFF-2026-10-25-v1.md','CROWN-PREVIEW-HANDOFF-2026-10-25-v2.md','SESSION-2026-10-25-CROWN-ACCESS-POLICY-v1.md']
checked=[]
for name in names:
    p=THREAD/name
    for target in re.findall(r'\]\(([^)]+)\)',p.read_text(encoding='utf-8')):
        if '://' in target:continue
        dest=(p.parent/target.split('#')[0]).resolve();assert dest.exists(),(name,target);checked.append(str(dest))
todo=(ROOT/'docs/codex/TODO.md').read_bytes();prior=(HERE/'TODO.before').read_bytes();old=(HERE/'TODO-replaced-paragraph.before').read_bytes()
start=todo.index(b'**Crown paid-Search Brief');nl=b'\r\n' if b'\r\n' in todo else b'\n';end=todo.index(nl+nl,start)
assert todo[:start]+old+todo[end:]==prior
for name in ['README.md','HANDOFF.md']:
    now=(THREAD/name).read_bytes();before=(HERE/(name+'.before')).read_bytes();first=before.index(b'\n')+1
    assert now.startswith(before[:first]) and now.endswith(before[first:])
canonical=v.sim.source_hashes(ROOT/'patch-notes');candidate=v.sim.source_hashes(VAR/'project');pin=load(HERE/'source-before.json')
assert canonical==pin['canonical'] and candidate==pin['candidate']
assert hashlib.sha256((HERE/'policy.gd').read_bytes()).hexdigest()==load(HERE/'pin.json')['policy_sha256']
status=subprocess.run(['git','status','--short'],cwd=ROOT,capture_output=True,text=True,encoding='utf-8',errors='replace');(HERE/'status-after.txt').write_text(status.stdout,encoding='utf-8')
write(HERE/'final-check.json',dict(status='PASS',relative_links=len(checked),unrelated_todo_bytes_preserved=True,old_thread_index_bytes_preserved=True,canonical_identity=v.identity(canonical),candidate_identity=v.identity(candidate),policy_hash_unchanged=True,document_hashes={name:hashlib.sha256((THREAD/name).read_bytes()).hexdigest() for name in names}))
print('PASS: '+str(len(checked))+' links; unrelated TODO/index bytes preserved; canonical/candidate/policy hashes unchanged.')
