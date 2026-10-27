"""Launch one private profile for real Windows input; no script injection."""
from pathlib import Path
import importlib.util,json,subprocess,sys,hashlib,shutil
OUT=Path(__file__).resolve().parent;ROOT=OUT.parents[3]
s=importlib.util.spec_from_file_location('sim',ROOT/'tools/simulate.py');sim=importlib.util.module_from_spec(s);s.loader.exec_module(sim)
m=json.loads((OUT/'export-v5/build-manifest.json').read_text());workspace=Path(m['workspace'])
p=sys.argv[1];width=int(sys.argv[2]);height=648 if width==1152 else 720
stage=OUT/'export-ui-v1'/f'{p}-{width}';stage.mkdir(parents=True,exist_ok=True)
env=sim.isolated_environment(stage/'profile');env['PN_EXPORT_INPUT']=str(OUT/f'challenge-render-v2/{p}-initial-{width}.json')
save=Path(env['APPDATA'])/'Godot/app_userdata/Patch Notes Demo/saves/studio'
if not save.exists():
 if p=='legacy':
  save.mkdir(parents=True);shutil.copy2(OUT/'prior-contract-storage-v2/checkpoint.1.json',save/'checkpoint.1.json')
 else:
  cmd=[r'C:\Users\64jus\Downloads\Godot_v4.7.1-stable_win64.exe\Godot_v4.7.1-stable_win64_console.exe','--headless','--path',str(workspace/'source'),'--script',str(OUT/'seed_export.gd')]
  proc=subprocess.run(cmd,env=env,capture_output=True,timeout=80);(stage/'seed.log').write_bytes(proc.stdout+proc.stderr)
  if proc.returncode:raise RuntimeError('seed failed')
# The game applies saved/default settings after CLI resolution; pin this private profile explicitly.
preferences=save.parent.parent/'preferences-v1.cfg'
preferences.write_text('[settings]\nversion=1\nfullscreen=false\nwidth='+str(width)+'\nheight='+str(height)+'\nMaster=80\nMusic=80\nSFX=80\nMaster_muted=false\nMusic_muted=false\nSFX_muted=false\n')
label=sys.argv[3] if len(sys.argv)>3 else 'play'
before={f.name:hashlib.sha256(f.read_bytes()).hexdigest() for f in save.glob('checkpoint.*.json')}
cmd=[str(workspace/'demo/Patch Notes Demo.exe'),'--audio-driver','Dummy','--resolution',f'{width}x{height}','--log-file',str(stage/(label+'.engine.log'))]
(stage/(label+'.command.json')).write_text(json.dumps({'command':cmd,'profile':str(stage/'profile'),'before_generations':before,'artifacts':m['artifacts']},indent=2))
with (stage/(label+'.stdout.log')).open('wb') as log:
 proc=subprocess.Popen(cmd,env=env,cwd=workspace/'demo',stdout=log,stderr=subprocess.STDOUT)
 print(json.dumps({'pid':proc.pid,'profile':str(stage/'profile'),'save':str(save)}),flush=True)
 code=proc.wait(timeout=900)
after={f.name:hashlib.sha256(f.read_bytes()).hexdigest() for f in save.glob('checkpoint.*.json')}
(stage/(label+'.exit.json')).write_text(json.dumps({'exit':code,'after_generations':after},indent=2));print('EXIT',code,flush=True)
