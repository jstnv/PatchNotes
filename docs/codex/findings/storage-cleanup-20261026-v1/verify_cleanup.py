"""Verify successful removals and the preserved source/toolchain boundaries."""
from pathlib import Path
import hashlib,importlib.util,json,subprocess,sys
sys.dont_write_bytecode=True
OUT=Path(__file__).resolve().parent;ROOT=OUT.parents[3]
receipt=json.loads((OUT/'deletion-receipt.json').read_text(encoding='utf-8-sig'))
def sha(p):
    h=hashlib.sha256()
    with p.open('rb') as s:
        for b in iter(lambda:s.read(1024*1024),b''):h.update(b)
    return h.hexdigest()
removed=receipt['removed'];failures=[]
for row in removed:
    p=ROOT/row['path']
    if not p.resolve().is_relative_to((ROOT/'docs').resolve()):failures.append('unexpected deletion scope: '+row['path'])
    if p.exists():failures.append('removed target exists: '+row['path'])
spec=importlib.util.spec_from_file_location('cleanup_verify_sim',ROOT/'tools/simulate.py')
sim=importlib.util.module_from_spec(spec);spec.loader.exec_module(sim)
before=json.loads((OUT/'canonical-source-before.json').read_text())
after=sim.source_hashes(ROOT/'patch-notes')
if before!=after:failures.append('canonical source inventory/bytes changed')
status=subprocess.check_output(['git','status','--porcelain=v1','--untracked-files=no'],cwd=ROOT).decode('utf-8')
if status!=(OUT/'tracked-status-before.txt').read_text(encoding='utf-8'):failures.append('tracked status changed')
templates=json.loads((OUT/'approved-template-preflight.json').read_text())
for name,row in templates['retained_original_templates'].items():
    if sha(Path(row['path']))!=row['sha256']:failures.append('installed template changed: '+name)
for name in ['.git','.codex-godot-temp','patch-notes/.godot']:
    if not (ROOT/name).is_dir():failures.append('protected root missing: '+name)
result={'ok':not failures,'removed_directories':len(removed),'logical_bytes_removed':sum(r['logical_bytes'] for r in removed),
        'removed_files':sum(r['files'] for r in removed),'source_files_verified':len(before),'canonical_source_identical':before==after,
        'tracked_status_identical':status==(OUT/'tracked-status-before.txt').read_text(encoding='utf-8'),
        'installed_templates_verified':len(templates['retained_original_templates']),'protected_roots_present':True,
        'failures':failures,'notes':'No gameplay test; this verifies storage cleanup boundaries. Per-target preflight metadata and template hashes are retained.'}
(OUT/'verification.json').write_text(json.dumps(result,indent=2)+'\n')
print(json.dumps(result,indent=2));sys.exit(0 if result['ok'] else 1)
