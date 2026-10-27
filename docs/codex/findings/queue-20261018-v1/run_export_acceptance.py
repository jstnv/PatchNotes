from pathlib import Path
import hashlib,importlib.util,json,os,re,shutil,socket,subprocess,sys
OUT=Path(__file__).resolve().parent
ROOT=OUT.parents[3]
s=importlib.util.spec_from_file_location('sim',ROOT/'tools/simulate.py');sim=importlib.util.module_from_spec(s);s.loader.exec_module(sim)
stage=OUT/sys.argv[1];stage.mkdir()
m=json.loads((OUT/'export-v1/build-manifest.json').read_text())
exe=Path(m['workspace'])/'demo/Patch Notes Demo.exe'
with socket.socket() as sock:sock.bind(('127.0.0.1',62741))
jobs=[(p,w,h) for w,h in [(1152,648),(1280,720)] for p in ['sidestreet','crown_quill','neon_circuit','starwave']]
if '--smoke' in sys.argv:jobs=jobs[:1]
results=[]
for p,w,h in jobs+[('legacy',1152,648)]:
 name=f'{p}-{w}x{h}';base=stage/name
 env=sim.isolated_environment(stage/('profile-'+name))
 env.update(PN_EXPORT_CASE=str(base),PN_EXPORT_PUBLISHER=p,PN_EXPORT_WIDTH=str(w),PN_EXPORT_HEIGHT=str(h))
 env['PN_EXPORT_INPUT']=str(OUT/('prior-contract-storage-v2/checkpoint.1.json' if p=='legacy' else f'challenge-render-v2/{p}-initial-{w}.json'))
 modes=['legacy'] if p=='legacy' else ['rollback','complete','cold'] if p=='crown_quill' and w==1152 else ['complete','cold']
 for mode in modes:
  env['PN_EXPORT_MODE']=mode;log=stage/f'{name}-{mode}.engine.log'
  cmd=[str(exe),'--audio-driver','Dummy','--log-file',str(log),'--script',str(OUT/'export_acceptance.gd')]
  proc=subprocess.run(cmd,cwd=exe.parent,env=env,stdout=subprocess.PIPE,stderr=subprocess.STDOUT,timeout=130)
  (stage/f'{name}-{mode}.stdout.log').write_bytes(proc.stdout)
  output=log.read_text(encoding='utf8',errors='replace') if log.exists() else proc.stdout.decode(errors='replace')
  errors=[line for line in output.splitlines() if re.search(r'ERROR:|SCRIPT ERROR|FAIL:',line)]
  record=base.with_name(base.name+'-'+mode+'.json')
  row={'command':cmd,'exit':proc.returncode,'errors':errors,'result':json.loads(record.read_text()) if record.exists() else None,'driver_sha256':hashlib.sha256((OUT/'export_acceptance.gd').read_bytes()).hexdigest(),'artifact_hashes':m['artifacts']}
  results.append(row);(stage/'results.json').write_text(json.dumps(results,indent=2));print(name,mode,proc.returncode,errors,row['result'],flush=True)
  if proc.returncode or errors or row['result'] is None or row['result']['failures']:raise RuntimeError(name+' '+mode)
 if '--smoke' in sys.argv:break
