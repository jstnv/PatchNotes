from pathlib import Path
import os,json,subprocess,re
BASE=Path(__file__).resolve().parent;ROOT=BASE.parents[3]
project=BASE.parent/'queue-execution-20261017-v2/final-ui-wire-v7/project'
out=BASE/'focused';out.mkdir(exist_ok=False)
results=[]
for name in ['verify_bank_finance','verify_education_edges','verify_publisher_trial_promotion','verify_studio_checkpoint','verify_starwave']:
 env=os.environ.copy()
 for key in ['APPDATA','LOCALAPPDATA']:
  p=ROOT/'.codex-godot-temp'/('bpf-'+name)/key;p.mkdir(parents=True,exist_ok=True);env[key]=str(p)
 env['PN_CARD_FRAME_OUTPUT']=str(out/(name+'.json'))
 cmd=[r'C:\Users\64jus\Downloads\Godot_v4.7.1-stable_win64.exe\Godot_v4.7.1-stable_win64_console.exe','--headless','--audio-driver','Dummy','--path',str(project),'--script','res://scripts/debug/'+name+'.gd']
 with (out/(name+'.log')).open('wb') as log:r=subprocess.run(cmd,env=env,stdout=log,stderr=subprocess.STDOUT,timeout=240)
 text=(out/(name+'.log')).read_text(encoding='utf-8',errors='replace')
 errors=[s for s in text.splitlines() if 'ERROR:' in s or s.startswith('FAIL')]
 results.append({'name':name,'command':cmd,'exit':r.returncode,'errors':errors,'summary':[s for s in text.splitlines() if re.search(r'checks|failures|passed',s,re.I)][-5:]})
 print(json.dumps(results[-1]),flush=True)
(out/'results.json').write_text(json.dumps(results,indent=2),encoding='utf-8')
raise SystemExit(0 if all(r['exit']==0 and not r['errors'] for r in results) else 1)
