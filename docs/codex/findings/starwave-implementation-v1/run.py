from pathlib import Path
import os,subprocess,json,sys,hashlib
HERE=Path(__file__).resolve().parent
ROOT=HERE.parents[3]
PROJECT=ROOT/'patch-notes'
GODOT=Path(r'C:/Users/64jus/Downloads/Godot_v4.7.1-stable_win64.exe/Godot_v4.7.1-stable_win64_console.exe')
PROFILES=Path(r'C:/Users/64jus/Downloads/Patch Notes Design Folder/starwave-implementation-v1-profiles')
def run(label,args,profile=None):
 p=PROFILES/(profile or label)
 for name in ['roaming','local']:(p/name).mkdir(parents=True,exist_ok=True)
 env=dict(os.environ,APPDATA=str(p/'roaming'),LOCALAPPDATA=str(p/'local'),PN_CHECKPOINT_TEST_PORT='47921')
 cmd=[str(GODOT),'--headless','--path',str(PROJECT),*args]
 proc=subprocess.run(cmd,env=env,capture_output=True,timeout=300)
 text=(proc.stdout+proc.stderr).decode('utf-8',errors='replace')
 (HERE/(label+'.log')).write_text(text,encoding='utf-8')
 failures=[x for x in text.splitlines() if ('SCRIPT ERROR' in x or 'FAIL:' in x or x.startswith('ERROR:')) and 'root certificate' not in x]
 (HERE/(label+'.command.json')).write_text(json.dumps({'command':cmd,'exit':proc.returncode,'profile':str(p),'errors':failures},indent=2),encoding='utf-8')
 print(label,proc.returncode,failures,flush=True)
 return proc.returncode or bool(failures)
if __name__=='__main__':
 if sys.argv[1]=='import':sys.exit(run('import-v2',['--editor','--import','--quit']))
 elif sys.argv[1]=='focused':
  scripts=['verify_starwave','verify_publisher_trial_offers','verify_publisher_trial_cash','verify_publisher_trial_promotion','verify_publisher_trial_liquidity','verify_publisher_browser_states','verify_publisher_connections','verify_balanced_primitive_contract','verify_sidestreet_contract','verify_studio_checkpoint','verify_checkpoint_rng','verify_fanbase_checkpoint','verify_feature_research']
  result={n:run(n,['--script',f'res://scripts/debug/{n}.gd']) for n in scripts}
  (HERE/'focused-results.json').write_text(json.dumps(result,indent=2),encoding='utf-8')
  sys.exit(any(result.values()))
 elif sys.argv[1]=='restart':
  version=sys.argv[2] if len(sys.argv)>2 else 'native-v2'
  result={}
  for index,mode in enumerate(['seed','rollback0','rollback1','rollback2','rollback3','rollback3','complete','continued','launch','launched']):
   label=f'{version}-restart-{index:02d}-{mode}'
   result[label]=run(label,['--script','res://scripts/debug/starwave_restart_probe.gd','--','--mode='+mode,'--directory='+str(HERE/version)],profile='restart-'+version)
   if result[label]:break
  (HERE/(version+'-restart-results.json')).write_text(json.dumps(result,indent=2),encoding='utf-8')
  sys.exit(any(result.values()))
