from pathlib import Path
import hashlib,json
ROOT=Path(__file__).resolve().parents[6];HERE=Path(__file__).resolve().parent
files={}
for p in sorted(HERE.iterdir()):
    if p.is_file() and p.name not in ('evidence-index.json',):
        files[str(p.relative_to(ROOT)).replace('\\','/')]=hashlib.sha256(p.read_bytes()).hexdigest()
for p in sorted((HERE/'checks').glob('*/*')):
    if p.is_file(): files[str(p.relative_to(ROOT)).replace('\\','/')]=hashlib.sha256(p.read_bytes()).hexdigest()
for name in ('PUBLISHER-P1-FOUNDATION-SPEC-2026-10-23-v1.md','PUBLISHER-P1-FINDINGS-2026-10-23-v1.md'):
    p=HERE.parents[1]/name
    files[str(p.relative_to(ROOT)).replace('\\','/')]=hashlib.sha256(p.read_bytes()).hexdigest()
with (HERE/'evidence-index.json').open('x',encoding='utf-8') as f: json.dump({'scope':'supplemental focused evidence; paths relative to repo; preserve all referenced bytes','files':files},f,indent=2)
print('Hashed supplemental files:',len(files))
