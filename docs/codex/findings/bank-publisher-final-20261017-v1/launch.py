from pathlib import Path
import os,sys,json,shutil,subprocess,datetime,hashlib
BASE=Path(__file__).resolve().parent
OLD=BASE.parent/'queue-execution-20261017-v2'
sources={'bank-age':'education-distressed-committed/checkpoint.33.json','crown':'crown-pending/checkpoint.14.json','starwave':'starwave-completed/checkpoint.11.json','starwave-rollback':'starwave-completed/checkpoint.11.json'}
sources.update({'crown-small':sources['crown'],'neon-small':'neon-completed/checkpoint.2.json','starwave-small':sources['starwave']})
profile=sys.argv[1];assert profile in sources
env=os.environ.copy()
for key in ('APPDATA','LOCALAPPDATA'):
 p=BASE/'profiles'/profile/key;p.mkdir(parents=True,exist_ok=True);env[key]=str(p)
user=Path(env['APPDATA'])/'Godot/app_userdata/Patch Notes Demo'
save=user/'saves/studio'
if not save.exists():
 save.mkdir(parents=True)
 source=BASE.parent/'queue-completion-20261011-v1/checkpoints'/sources[profile]
 shutil.copy2(source,save/source.name)
 pref=OLD/'final-profiles/long-ai/APPDATA/Godot/app_userdata/Patch Notes Demo/preferences-v1.cfg'
 shutil.copy2(pref,user/pref.name)
 if profile.endswith('-small'):
  small_pref=user/pref.name
  small_pref.write_text(small_pref.read_text().replace('width=1280','width=1152').replace('height=720','height=648'))
 with (BASE/'origins.jsonl').open('a',encoding='utf-8') as f:f.write(json.dumps({'profile':profile,'source':str(source),'sha256':hashlib.sha256(source.read_bytes()).hexdigest()})+'\n')
manifest=json.loads((OLD/'final-delivery-v4/build-manifest.json').read_text(encoding='utf-8'))
exe=Path(manifest['workspace'])/'demo/Patch Notes Demo.exe'
cmd=[str(exe),'--audio-driver','Dummy','--windowed']
record={'profile':profile,'command':cmd,'started':datetime.datetime.now(datetime.timezone.utc).isoformat()}
result=subprocess.run(cmd,env=env)
record.update(exit_code=result.returncode,finished=datetime.datetime.now(datetime.timezone.utc).isoformat())
with (BASE/'processes.jsonl').open('a',encoding='utf-8') as f:f.write(json.dumps(record)+'\n')
print(json.dumps(record));sys.exit(result.returncode)
