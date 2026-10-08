from pathlib import Path
import json,os,subprocess,tempfile,gzip,concurrent.futures,itertools,sys
HERE=Path(__file__).resolve().parent;REPO=HERE.parents[4];M=json.loads((HERE/'source.json').read_text());PROJECT=Path(M['project']);ROOT=PROJECT.parent
GODOT=r'C:\Users\64jus\Downloads\Godot_v4.7.1-stable_win64.exe\Godot_v4.7.1-stable_win64_console.exe'
def execute(case):
 name='_'.join(map(str,case));startup,band,policy,contracts,stratum,wage=case
 done=HERE/(name+'.command.json')
 if done.exists() and (HERE/(name+'.json.gz')).exists():
  previous=json.loads(done.read_text())
  if previous.get('valid') and previous['exit']==0 and not previous['errors']:return previous
 profile=Path(tempfile.mkdtemp(prefix='profile-',dir=ROOT));env=os.environ.copy()
 for k in ['APPDATA','LOCALAPPDATA']:
  p=profile/k;p.mkdir();env[k]=str(p)
 raw=ROOT/(name+'.json');env.update(WAGE_CENTS=str(wage),STARTUP=startup,STRATUM=stratum,OUTPUT_JSON=str(raw))
 cmd=[GODOT,'--headless','--path',str(PROJECT),'--script','res://analysis/wage_route.gd','--','--seed=1104','--band='+band,'--policy='+policy,'--contracts='+contracts]
 result=subprocess.run(cmd,cwd=REPO,env=env,capture_output=True,timeout=240);output=result.stdout+result.stderr;(HERE/(name+'.log')).write_bytes(output)
 errors=[x for x in output.decode('utf-8',errors='replace').splitlines() if ('ERROR:' in x or 'FAIL:' in x) and 'root certificate store' not in x]
 record=dict(case=case,command=cmd,exit=result.returncode,errors=errors)
 if raw.exists():
  data=raw.read_bytes();(HERE/(name+'.json.gz')).write_bytes(gzip.compress(data));d=json.loads(data);record.update(valid=d['valid'],releases=len(d['releases']),cycle=d['final']['cycle'],cash=d['final']['cash_cents'],stop=d['stop'])
 done.write_text(json.dumps(record,indent=2));print(name,record.get('releases'),record.get('cycle'),result.returncode,len(errors),flush=True);return record
if __name__=='__main__':
 if '--import' in sys.argv:
  env=os.environ.copy();profile=Path(tempfile.mkdtemp(prefix='import-',dir=ROOT))
  for key in ['APPDATA','LOCALAPPDATA']:
   q=profile/key;q.mkdir();env[key]=str(q)
  r=subprocess.run([GODOT,'--headless','--path',str(PROJECT),'--editor','--import','--quit'],env=env,capture_output=True);(HERE/'import-final.log').write_bytes(r.stdout+r.stderr);print('import',r.returncode);raise SystemExit(r.returncode)
 cases=list(itertools.product(['legacy','current'],['early','slow','stress'],['ordinary','synergy'],['none','available'],['base'],[0,1000,2500,5000,7500]))
 cases += [('current','early','ordinary','available',stratum,wage) for stratum in ['lease','bank','store'] for wage in [0,1000,2500,5000,7500]]
 if '--pilot' in sys.argv:cases=[('current','early','synergy','available','base',5000)]
 if '--extension' in sys.argv:cases=list(itertools.product(['legacy','current'],['stress'],['frugal'],['none','available'],['base'],[0,1000,2500,5000,7500]))
 if "--coverage" in sys.argv:cases=list(itertools.product(["legacy","current"],["stress20"],["frugal"],["none","available"],["base"],[0,1000,2500,5000,7500]))+[("current","slow","ordinary","available","bankfunded",w) for w in [0,1000,2500,5000,7500]]
 with concurrent.futures.ThreadPoolExecutor(max_workers=3) as pool:results=list(pool.map(execute,cases))
 (HERE/('pilot.json' if '--pilot' in sys.argv else 'extension-report.json' if '--extension' in sys.argv else 'coverage-report.json' if '--coverage' in sys.argv else 'run-report.json')).write_text(json.dumps(results,indent=2))
 assert all(r['exit']==0 and not r['errors'] and r.get('valid') for r in results)
