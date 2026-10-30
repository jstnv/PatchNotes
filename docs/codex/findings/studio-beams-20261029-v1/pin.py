from pathlib import Path
import json,hashlib
out=Path(__file__).resolve().parent;root=out.parents[3];files={}
for area in ['scripts','data']:
 for f in (root/'patch-notes'/area).rglob('*'):
  if f.is_file() and f.suffix in ['.gd','.gdc','.json'] and not f.relative_to(root/'patch-notes').as_posix().startswith('scripts/debug/'):
   files['res://'+f.relative_to(root/'patch-notes').as_posix()]=hashlib.sha256(f.read_bytes()).hexdigest()
f=root/'patch-notes/queries/market_release_index.gd'
if f.exists():files['res://queries/market_release_index.gd']=hashlib.sha256(f.read_bytes()).hexdigest()
files=dict(sorted(files.items()));identity=hashlib.sha256(json.dumps(list(map(list,files.items())),separators=(',',':')).encode()).hexdigest()
(out/'source.json').write_text(json.dumps({'runtime_identity':identity,'runtime_files':files},indent=2),encoding='utf-8');print(identity)
