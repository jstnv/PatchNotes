from pathlib import Path
import hashlib, json, subprocess, zipfile

ROOT = Path(__file__).resolve().parents[5]
HERE = Path(__file__).resolve().parent
files = list((ROOT/'patch-notes/scripts').rglob('*.gd')) + [ROOT/'docs/codex/TODO.md', ROOT/'docs/codex/CURRENT_STATE.md', ROOT/'patch-notes/design-logs/candidate-pool-repair-v1/card-motion/animation-traces.json']
with zipfile.ZipFile(HERE/'before-scripts.zip', 'x', zipfile.ZIP_DEFLATED) as archive:
    for path in files:
        if path.exists(): archive.write(path, path.relative_to(ROOT))
(HERE/'before-hashes.json').write_text(json.dumps({str(p.relative_to(ROOT)):hashlib.sha256(p.read_bytes()).hexdigest() for p in files if p.exists()},indent=2),encoding='utf-8')
for args,name in [(['status','--short'],'status-before.txt'),(['diff','--','patch-notes/scripts'],'diff-before.patch'),(['rev-parse','HEAD'],'head.txt')]:
    (HERE/name).write_bytes(subprocess.run(['git',*args],cwd=ROOT,stdout=subprocess.PIPE,check=True).stdout)
for phase in ['design','alpha','beta']:
    original=(ROOT/f'patch-notes/scripts/phases/{phase}_phase.gd').read_text(encoding='utf-8')
    (HERE/f'{phase}_phase_oracle.gd').write_text(original.split('\n',1)[1],encoding='utf-8')
print('Archived',len(files),'paths')
