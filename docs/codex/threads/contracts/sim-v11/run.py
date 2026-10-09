from pathlib import Path
import importlib.util,sys
HERE=Path(__file__).resolve().parent
spec=importlib.util.spec_from_file_location('prior',HERE.parent/'sim-v10/run.py')
r=importlib.util.module_from_spec(spec);spec.loader.exec_module(r)
r.HERE=HERE
r.COPY=Path(r'C:/Users/64jus/Downloads/Patch Notes Design Folder/contracts-starwave-v11-source-copy')
r.PROFILES=Path(r'C:/Users/64jus/Downloads/Patch Notes Design Folder/contracts-starwave-v11-profiles')
r.SCRIPTS=tuple(HERE/n for n in ['crown_neon_chain_base_v10.gd','starwave_timing_v10.gd','foundation.gd'])
if sys.argv[1]=='prepare':
 for name in ['crown_neon_chain_base_v10.gd','starwave_timing_v10.gd']:
  s=(HERE.parent/'sim-v10'/name).read_text()
  if name=='starwave_timing_v10.gd':
   s=s.replace(' or run.get_pending_promotion() != 18','')
  (HERE/name).write_text(s,encoding='utf-8')
 r.prepare()
elif sys.argv[1]=='import':r.execute('import',['--editor','--import','--quit'],300)
elif sys.argv[1]=='foundation':
 import json
 for seed in [1104,4417,2027]:
  target=HERE/f'foundation-{seed}.json'
  if target.exists():raise RuntimeError('Preserve prior attempt')
  r.execute(f'foundation-{seed}',['--script','res://scripts/debug/foundation.gd','--',f'--seed={seed}',f'--out={target}'],240)
  d=json.loads(target.read_text())
  print('FOUNDATION',seed,d['valid'],flush=True)
  if d['valid']:break
