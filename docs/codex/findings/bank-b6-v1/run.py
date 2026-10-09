from pathlib import Path
import importlib.util,itertools,json,gzip,sys
H=Path(__file__).resolve().parent;REPO=H.parents[3]
s=importlib.util.spec_from_file_location('runner',REPO/'docs/codex/threads/contracts/sim-v10/run.py');r=importlib.util.module_from_spec(s);s.loader.exec_module(r)
r.HERE=H;r.COPY=Path(r'C:/Users/64jus/Downloads/Patch Notes Design Folder/bank-b6-v1-source-copy');r.PROFILES=Path(r'C:/Users/64jus/Downloads/Patch Notes Design Folder/bank-b6-v1-profiles');r.SCRIPTS=(H/'b6.gd',)
if sys.argv[1]=='prepare':
 r.prepare();r.execute('import',['--editor','--import','--quit'],300)
elif sys.argv[1]=='run':
 gate=json.loads((H.parent/'release-gate-queue-v6/gate-result.json').read_text())
 ui=json.loads((H.parent/'export-ui-queue-v1/audit-result.json').read_text())
 assert gate['automated_pass'] and ui['pass'] and 'second-continue' in ui['captured_boundaries'],'Upstream acceptance incomplete'
 routes=list(itertools.product(['legacy','current'],['ordinary','synergy'],['early','late'],[1104,4417]))
 (H/'route-manifest.json').write_text(json.dumps(routes,indent=2))
 for c,p,b,seed in routes:
  name=f'{c}-{p}-{b}-{seed}';out=H/(name+'.json');archive=H/(name+'.json.gz')
  if archive.exists():continue
  r.execute(name,['--script','res://scripts/debug/b6.gd','--',f'--creation={c}',f'--policy={p}',f'--band={b}',f'--seed={seed}',f'--out={out}'],240)
  archive.write_bytes(gzip.compress(out.read_bytes()));out.unlink()
else:raise SystemExit('prepare|run')
