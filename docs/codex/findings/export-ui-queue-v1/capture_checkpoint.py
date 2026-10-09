"""Read-only captures of the unique UI acceptance profile, never inject saves."""
from pathlib import Path
import sys,json,hashlib,shutil,struct,re
H=Path(__file__).resolve().parent
profile=Path(r'C:/Users/64jus/AppData/Roaming/Patch Notes Acceptance 20261008 Queue')
label=sys.argv[1];assert re.fullmatch('[a-z0-9-]+',label)
out=H/label;out.mkdir(exist_ok=False)
files=sorted((profile/'saves/studio').glob('checkpoint.*.json'),key=lambda p:int(p.name.split('.')[1]))
hashes={}
for p in files:
 shutil.copy2(p,out/p.name);hashes[p.name]=hashlib.sha256(p.read_bytes()).hexdigest()
envelope=json.loads(files[-1].read_text(encoding='utf-8'));raw=envelope['payload_utf8']
assert hashlib.sha256(raw.encode()).hexdigest()==envelope['payload_sha256']
d=json.loads(raw);r=d['run']
def decode(v):
 if isinstance(v,dict):
  if set(v)=={'f64'}:return struct.unpack('>d',bytes.fromhex(v['f64']))[0]
  return {k:decode(x) for k,x in v.items()}
 if isinstance(v,list):
  if v and all(isinstance(x,dict) and set(x)=={'key','value'} for x in v):return {str(x['key']):decode(x['value']) for x in v}
  return [decode(x) for x in v]
 if isinstance(v,str) and re.fullmatch('-?[0-9]+',v):return int(v)
 return v
r=decode(r)
summary=dict(label=label,files=hashes,cycle=r['completed_run_cycles'],cash=r['cash_cents'],releases=r['release_metadata'],sales=r['released_games'],finance=r['studio_finance'],bank=r['bank_run_id'])
(out/'decoded.json').write_text(json.dumps(r,indent=2),encoding='utf-8')
(out/'summary.json').write_text(json.dumps(summary,indent=2),encoding='utf-8')
for log in (profile/'logs').glob('godot.log'):shutil.copy2(log,out/log.name)
print(label,'cycle',summary['cycle'],'cash',summary['cash'],'releases',len(summary['releases']))
