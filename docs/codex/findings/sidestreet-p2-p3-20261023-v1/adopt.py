"""One-time reviewed packet adoption. Exact baseline hashes or refuse."""
from pathlib import Path
import hashlib, json, shutil

ROOT=Path(__file__).resolve().parents[4]
WORK=Path('C:/Users/64jus/AppData/Local/Temp/pn-sidestreet-adoption-20261023-v1')
rows=json.loads((WORK/'overlap.json').read_text(encoding='utf8'))
for row in rows:
    p=ROOT/'patch-notes'/row['path']
    actual=hashlib.sha256(p.read_bytes()).hexdigest() if p.exists() else None
    assert actual==row['base'],row['path']
frozen=ROOT/'patch-notes/scripts/contracts/pre_commissions'
frozen.mkdir(exist_ok=False)
for source,name in [('scripts/persistence/studio_checkpoint.gd','studio.gd'),('scripts/persistence/checkpoint_schema.gd','schema.gd')]:
    s=(WORK/'baseline'/source).read_text(encoding='utf8')
    if name=='studio.gd':
        s=s.replace('class_name StudioCheckpoint\n','')
        s=s.replace('CheckpointSchema','PreviousCommissionSchema')
        s=s.replace('extends RefCounted\n','extends RefCounted\nconst PreviousCommissionSchema := preload("res://scripts/contracts/pre_commissions/schema.gd")\n',1)
    else:s=s.replace('class_name CheckpointSchema\n','')
    (frozen/name).write_text(s,encoding='utf8',newline='\n')
for row in rows:
    p=ROOT/'patch-notes'/row['path']; p.parent.mkdir(parents=True,exist_ok=True)
    p.write_text((WORK/'candidate'/row['path']).read_text(encoding='utf8'),encoding='utf8',newline='\n')
print('Adopted 12 exact-baseline deltas; frozen current P1 validators retained.')
