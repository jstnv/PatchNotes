from pathlib import Path
import json,hashlib,shutil,os,subprocess,gzip,tempfile,sys
HERE=Path(__file__).resolve().parent;OLD=HERE.parent/'quarter-trial-v1';ROOT=Path(r'C:/Users/64jus/Downloads/Patch Notes Design Folder/fanbase-near-neutral-20261007');PROJECT=ROOT/'patch-notes'
GODOT=r'C:/Users/64jus/Downloads/Godot_v4.7.1-stable_win64.exe/Godot_v4.7.1-stable_win64_console.exe'
if not PROJECT.exists():
 m=json.loads((OLD/'source.json').read_text());source=Path(m['project'])
 for k,h in m['files'].items():assert hashlib.sha256((source/k).read_bytes()).hexdigest()==h,k
 shutil.copytree(source,PROJECT,ignore=shutil.ignore_patterns('.godot','design-logs'))
 p=PROJECT/'analysis/task29_routes_v1.gd';s=p.read_text(encoding='utf-8').replace('[1,0,0] if _arg("--weak=", "none") == "restrained" else [2,1,0]','[3,3,4] if _arg("--weak=", "none") == "primary" else [3,4,4]');s=s.replace('_curtail(game, out, label, hand)\n\t\t\t\tcurtailed = true\n\t\t\t\tbreak','_stop(game,out,label,"first rejected hand; censored")\n\t\t\t\treturn false').replace('_curtail(game, out, "beta", hand)\n\t\t\tcurtailed = true\n\t\t\tbreak','_stop(game,out,"beta","first rejected hand; censored")\n\t\t\treturn false');p.write_text(s,encoding='utf-8',newline='\n')
 p=PROJECT/'analysis/task32_routes_v1.gd';s=p.read_text(encoding='utf-8').replace('range(1, 6)','range(1, 5)').replace('if number == 5: break','if number == 4: break').replace('"five releases"','"four releases"');p.write_text(s,encoding='utf-8',newline='\n');(PROJECT/'design-logs/task32-v1').mkdir(parents=True)
 (HERE/'source.json').write_text(json.dumps(dict(head=m['head'],branch=m['branch'],project=str(PROJECT),files={str(p.relative_to(PROJECT)):hashlib.sha256(p.read_bytes()).hexdigest() for folder in ['scripts','scenes','data','analysis'] for p in (PROJECT/folder).rglob('*') if p.is_file()}),indent=2))
def run(name,args):
 env=os.environ.copy();profile=Path(tempfile.mkdtemp(prefix='profile-',dir=ROOT))
 for k in ['APPDATA','LOCALAPPDATA']:
  p=profile/k;p.mkdir();env[k]=str(p)
 cmd=[GODOT,'--headless','--path',str(PROJECT),*args];r=subprocess.run(cmd,env=env,capture_output=True,timeout=240);output=r.stdout+r.stderr;(HERE/(name+'.log')).write_bytes(output)
 errors=[s for s in output.decode(errors='replace').splitlines() if ('ERROR:' in s or 'FAIL:' in s) and 'root certificate store' not in s]
 (HERE/(name+'.command.json')).write_text(json.dumps(dict(command=cmd,exit=r.returncode,errors=errors),indent=2));print(name,r.returncode,errors,flush=True);assert r.returncode==0 and not errors
for name in sys.argv[1:]:
 if name=='import':run(name,['--editor','--import','--quit'])
 elif name.startswith('verify_'):run(name,['--script','res://scripts/debug/'+name+'.gd'])
 else:
  run(name,['--script','res://analysis/fanbase_quarter_capture.gd','--','--policy=ordinary','--band=early','--seed=1104','--specialty=action','--contracts=available','--alignment=0','--neon=0','--weak='+name])
  raw=PROJECT/'design-logs/task32-v1/route_early_ordinary_1104_available_0_0.json';data=raw.read_bytes();(HERE/(name+'.json.gz')).write_bytes(gzip.compress(data));(ROOT/(name+'.json')).write_bytes(data);d=json.loads(data);print(name,d['valid'],[(x['cycle'],x['final_review']) for x in d['releases']],d['stop'],flush=True)
