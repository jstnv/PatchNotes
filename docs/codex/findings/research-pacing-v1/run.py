from pathlib import Path
import importlib.util,itertools,json,gzip,hashlib,shutil
HERE=Path(__file__).resolve().parent;REPO=HERE.parents[3]
spec=importlib.util.spec_from_file_location('prior',REPO/'docs/codex/threads/contracts/sim-v10/run.py');r=importlib.util.module_from_spec(spec);spec.loader.exec_module(r)
r.HERE=HERE;r.COPY=Path(r'C:/Users/64jus/Downloads/Patch Notes Design Folder/contracts-starwave-v11-source-copy');r.PROFILES=Path(r'C:/Users/64jus/Downloads/Patch Notes Design Folder/research-pacing-v1-profiles');r.SCRIPTS=(HERE/'pacing.gd',)
source=REPO/'docs/codex/threads/contracts/sim-v11/source-manifest.json';m=json.loads(source.read_text())
for rel,h in m['files'].items():assert hashlib.sha256((r.COPY/rel).read_bytes()).hexdigest()==h,rel
shutil.copy2(source,HERE/'source-manifest.json');shutil.copy2(HERE/'pacing.gd',r.COPY/'scripts/debug/pacing.gd')
strata=list(itertools.product(['legacy','current'],['ordinary','synergy'],[1104,4417]))
routes=[(c,p,s,t,a) for c,p,s in strata for t in ['colored_text','recorded_sounds'] for a in ['none','instant','immediate','defer']]
routes += [(c,p,s,'both',a) for c,p,s in strata for a in ['fifo','sequential']]
(HERE/'route-manifest.json').write_text(json.dumps(routes,indent=2))
for c,p,s,t,a in routes:
 name=f'{c}-{p}-{s}-{t}-{a}';path=HERE/(name+'.json');archive=HERE/(name+'.json.gz')
 if archive.exists():continue
 r.execute(name,['--script','res://scripts/debug/pacing.gd','--',f'--creation={c}',f'--policy={p}',f'--seed={s}',f'--target={t}',f'--acquisition={a}',f'--out={path}'],180)
 raw=path.read_bytes();archive.write_bytes(gzip.compress(raw));path.unlink()
print('PASS',len(routes),'routes',flush=True)
