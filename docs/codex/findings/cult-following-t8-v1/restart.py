from pathlib import Path
import hashlib,json,os,subprocess,time
from run import ROOT,HERE,GODOT,source

def process(folder,mode,input_path=''):
 env=os.environ.copy()
 for key in ['APPDATA','LOCALAPPDATA']:
  p=folder/key;p.mkdir(exist_ok=True);env[key]=str(p)
 env.update(PN_CULT_MODE=mode,PN_CULT_INPUT=str(input_path),PN_CULT_OUTPUT=str(folder/(mode+'.json')))
 command=[str(GODOT),'--headless','--path',str(ROOT/'patch-notes'),'--script','res://scripts/debug/cult_restart_probe.gd']
 before=source();start=time.monotonic()
 with (folder/(mode+'.log')).open('wb') as log:result=subprocess.run(command,env=env,stdout=log,stderr=subprocess.STDOUT,timeout=60)
 lines=(folder/(mode+'.log')).read_text(encoding='utf-8',errors='replace').splitlines()
 errors=[x for x in lines if ('SCRIPT ERROR' in x or x.startswith('ERROR:') or 'FAIL:' in x) and x!='ERROR: Failed to read the root certificate store.']
 report=dict(command=command,environment={k:env[k] for k in ['APPDATA','LOCALAPPDATA','PN_CULT_MODE','PN_CULT_INPUT','PN_CULT_OUTPUT']},exit=result.returncode,errors=errors,source_unchanged=before==source(),seconds=time.monotonic()-start)
 (folder/(mode+'-command.json')).write_text(json.dumps(report,indent=2),encoding='utf-8')
 assert result.returncode==0 and not errors and report['source_unchanged'],report
 print(folder.name,mode,'PASS',flush=True)

if __name__=='__main__':
 before=source();records=[]
 for arm in ['control','cult']:
  route=json.loads((HERE/('route-'+arm)/'fit.json').read_text(encoding='utf-8'))
  for name,payload in route['checkpoints'].items():
   folder=HERE/('restart-'+arm+'-'+name);folder.mkdir()
   path=folder/'input.json';path.write_text(json.dumps(payload),encoding='utf-8')
   process(folder,'seed',path);process(folder,'check')
   if arm=='cult' and name=='creation':process(folder,'neutral');process(folder,'check_neutral')
   records.append(folder.name)
 folder=HERE/'restart-old';folder.mkdir();process(folder,'old');process(folder,'old_check');records.append(folder.name)
 after=source();assert before==after
 (HERE/'restart-summary.json').write_text(json.dumps(dict(profiles=records,processes=20,source=before,unchanged=True),indent=2),encoding='utf-8')
