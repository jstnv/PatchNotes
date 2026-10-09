from pathlib import Path
import importlib.util,json,gzip,hashlib
HERE=Path(__file__).resolve().parent
spec=importlib.util.spec_from_file_location('prior',HERE.parent/'sim-v10/run.py');r=importlib.util.module_from_spec(spec);spec.loader.exec_module(r)
r.HERE=HERE;r.COPY=Path(r'C:/Users/64jus/Downloads/Patch Notes Design Folder/contracts-starwave-v11-source-copy');r.PROFILES=Path(r'C:/Users/64jus/Downloads/Patch Notes Design Folder/contracts-starwave-v11-profiles');r.SCRIPTS=(HERE/'reward_screen.gd',HERE/'starwave_timing_v10.gd')
m=json.loads((HERE/'source-manifest.json').read_text())
for rel,h in m['files'].items():
 assert hashlib.sha256((r.COPY/rel).read_bytes()).hexdigest()==h,rel
cards=json.loads((HERE/'cards.json').read_text());assert cards['valid']
for script in r.SCRIPTS:(r.COPY/'scripts/debug'/script.name).write_bytes(script.read_bytes())
matrix=[(14,224000,14),(14,224000,0),(14,300000,6),(12,224000,6),(16,224000,6)]
unique={};mapping=[]
for arm in cards['results']:
 for target,cap,promo in matrix:
  c=arm['completions'][str(target)];cash=cap*c['numerator']//c['denominator'];points=promo*c['numerator']//c['denominator']
  key=(cash,points);name=f'cash{cash}_p{points}'
  unique[key]=dict(mode=name,cycles=3,cash_cents=cash,extra_promotion=points)
  mapping.append(dict(policy=arm['policy'],seed=arm['seed'],target=target,cap=cap,promotion_cap=promo,numerator=c['numerator'],denominator=c['denominator'],cash_cents=cash,promotion=points,arm=name))
(HERE/'reward-matrix.json').write_text(json.dumps(mapping,indent=2))
arms=[dict(mode='delay_only',cycles=3,cash_cents=0,extra_promotion=0),dict(mode='pending',cycles=0,cash_cents=0,extra_promotion=0)]+list(unique.values())
reference=-1;summary=[]
for arm in arms:
 path=HERE/(arm['mode']+'.json');archive=HERE/(arm['mode']+'.json.gz')
 if archive.exists():d=json.loads(gzip.decompress(archive.read_bytes()))
 else:
  r.execute(arm['mode'],['--script','res://scripts/debug/reward_screen.gd','--',str(HERE/'foundation-1104.json'),json.dumps(arm,separators=(',',':')),str(reference),str(path)],240)
  raw=path.read_bytes();d=json.loads(raw);archive.write_bytes(gzip.compress(raw));path.unlink()
 assert d['success']
 if arm['mode']=='delay_only':reference=d['game4_launch']['cycle']
 summary.append({k:d[k] for k in ['mode','spec','game4_launch','game4_promotion','matched_L','cycle_plus_2','cycle_plus_4','sidestreet_eligible_at_foundation','sidestreet_ids']})
 (HERE/'reward-summary.json.gz').write_bytes(gzip.compress(json.dumps(summary).encode()))
 print(arm['mode'],d['cycle_plus_4']['cash_cents'],flush=True)
print('PASS',len(arms),'economic arms representing',len(mapping),'scored candidates',flush=True)
