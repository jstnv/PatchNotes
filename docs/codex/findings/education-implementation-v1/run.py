from pathlib import Path
import os,subprocess,json,sys,hashlib,shutil,time
HERE=Path(__file__).resolve().parent
ROOT=HERE.parents[3]
PROJECT=ROOT/'patch-notes'
GODOT=Path('C:/Users/64jus/Downloads/Godot_v4.7.1-stable_win64.exe/Godot_v4.7.1-stable_win64_console.exe')
PROFILES=Path('C:/Users/64jus/Downloads/Patch Notes Design Folder/education-implementation-v1-profiles')
def digest(path):return hashlib.sha256(path.read_bytes()).hexdigest()
def source_hashes():
 files=[]
 for directory in ['scripts','scenes','data','resources','assets','autoload','feature_profiles']:
  parent=PROJECT/directory
  if parent.exists():files.extend(p for p in parent.rglob('*') if p.is_file())
 files.extend(PROJECT/name for name in ['project.godot','export_presets.cfg'] if (PROJECT/name).exists())
 files.extend(p for p in (PROJECT/'analysis').rglob('*') if p.is_file() and p.suffix in {'.gd','.py'})
 return {str(p.relative_to(ROOT)).replace('\\','/'):digest(p) for p in sorted(set(files))}
def run(label,args,profile=None):
 p=PROFILES/(profile or label)
 for name in ['roaming','local']:(p/name).mkdir(parents=True,exist_ok=True)
 env=dict(os.environ,APPDATA=str(p/'roaming'),LOCALAPPDATA=str(p/'local'),PN_CHECKPOINT_TEST_PORT='48973')
 cmd=[str(GODOT),'--headless','--path',str(PROJECT),*args]
 before=source_hashes()
 prior_outputs={str(p):(p.stat().st_mtime_ns,p.stat().st_size) for p in HERE.glob('*.json')}
 driver_before=digest(Path(__file__))
 started=time.monotonic()
 proc=subprocess.run(cmd,env=env,capture_output=True,timeout=600)
 elapsed=time.monotonic()-started
 text=(proc.stdout+proc.stderr).decode('utf-8',errors='replace')
 (HERE/(label+'.log')).write_text(text,encoding='utf-8')
 exemption='ERROR: Failed to read the root certificate store.'
 errors=[x for x in text.splitlines() if ('SCRIPT ERROR' in x or 'FAIL:' in x or x.startswith('ERROR:')) and x.strip()!=exemption]
 after=source_hashes()
 (HERE/(label+'.source-before.json')).write_text(json.dumps(before,indent=2),encoding='utf-8')
 (HERE/(label+'.source-after.json')).write_text(json.dumps(after,indent=2),encoding='utf-8')
 changed={name for name in set(before)|set(after) if before.get(name)!=after.get(name)}
 # Import may create UID sidecars; final accepted behavior runs allow no drift.
 outputs={}
 outputs_fresh={}
 capture=HERE/'runs'/label
 capture.mkdir(parents=True,exist_ok=True)
 expected={'verify_education_debt.gd':'focused-cases.json','verify_education_edges.gd':'edge-cases.json','education_native_route.gd':'native-route.json','verify_education_ui.gd':'ui-cases.json','education_restart_probe.gd':'restart-trace.json'}
 expected_name=next((value for key,value in expected.items() if any(arg.endswith(key) for arg in args)),None)
 for path in HERE.glob(expected_name or '__no_output__'):
  if path.exists():
   target=capture/path.name
   shutil.copyfile(path,target)
   outputs[str(target.relative_to(HERE)).replace('\\','/')]=digest(target)
   outputs_fresh[str(target.relative_to(HERE)).replace('\\','/')]=prior_outputs.get(str(path))!=(path.stat().st_mtime_ns,path.stat().st_size)
 output_fresh=expected_name is None or bool(outputs) and all(outputs_fresh.values())
 record={'command':cmd,'exit':proc.returncode,'elapsed_seconds':elapsed,'profile':str(p),'errors':errors,'source_files':len(before),'source_unchanged':not changed,'changed_source_paths':sorted(changed),'driver_sha256':driver_before,'driver_unchanged':driver_before==digest(Path(__file__)),'source_before_sha256':digest(HERE/(label+'.source-before.json')),'source_after_sha256':digest(HERE/(label+'.source-after.json')),'log_sha256':digest(HERE/(label+'.log')),'outputs':outputs,'outputs_fresh':outputs_fresh,'output_fresh':output_fresh,'diagnostic_exemption':exemption}
 (HERE/(label+'.command.json')).write_text(json.dumps(record,indent=2),encoding='utf-8')
 print(label,proc.returncode,errors,flush=True)
 return proc.returncode or bool(errors) or bool(changed) or not record['driver_unchanged'] or not output_fresh
if __name__=='__main__':
 label=sys.argv[1]
 if len(sys.argv)>2:args=['--script',sys.argv[2],*sys.argv[3:]]
 else:args=['--editor','--import','--quit']
 sys.exit(run(label,args))
