from pathlib import Path
import json,hashlib,re,subprocess
HERE=Path(__file__).resolve().parent;ROOT=HERE.parents[5];THREAD=HERE.parents[1]
load=lambda p:json.loads(p.read_text(encoding='utf-8-sig'))
sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
pub=load(HERE/'publication.json');links=0
for r in pub['records']:
    current=(ROOT/r['path']).read_bytes()
    assert hashlib.sha256(current).hexdigest()==r['after']
    assert current.replace(r['new'].encode(),r['old'].encode(),1)==(HERE/r['backup']).read_bytes()
docs=[THREAD/f'CROWN-PREVIEW-{kind}-2026-10-25-v1.md' for kind in ['DESIGN','FINDINGS','HANDOFF']]
for p in docs:
    content=p.read_text(encoding='utf-8')
    assert all(line==line.rstrip() for line in content.splitlines())
    for t in re.findall(r'\]\(([^)]+)\)',content):
        if '://' not in t:assert (p.parent/t.split('#')[0]).exists(),(p,t);links+=1
e=load(HERE/'evidence.json')
canonical_drift=[f for f,h in e['canonical_read_hashes'].items() if sha(ROOT/f)!=h]
assert not canonical_drift,canonical_drift
args=['git','-c','core.whitespace=cr-at-eol','diff','--check','--','docs/codex/TODO.md','docs/codex/threads/contracts/README.md','docs/codex/threads/contracts/HANDOFF.md']
r=subprocess.run(args,cwd=ROOT,capture_output=True,text=True,encoding='utf-8',errors='replace');assert r.returncode==0,r.stdout+r.stderr
record=dict(status='PASS',local_links=links,publication_outside_bytes_exact=True,inspected_canonical_files_unchanged=True,source_pin=e['source_identity'],diff_check=dict(command=args,exit_code=r.returncode,output=r.stdout+r.stderr),files={p.name:sha(p) for p in docs},extraction_script_sha256=sha(HERE/'extract.py'),campaign_runs=0)
(HERE/'verification.json').write_text(json.dumps(record,indent=2)+'\n',encoding='utf-8')
print(json.dumps({k:v for k,v in record.items() if k not in ['files','diff_check']},indent=2))
