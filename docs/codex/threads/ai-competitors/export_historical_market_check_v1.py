"""Private acceptance export; no distribution, user profile or preset edits."""
from pathlib import Path
import argparse,json,shutil,subprocess,sys,time
ROOT=Path(__file__).resolve().parents[4];sys.path.insert(0,str(ROOT/'tools'));import simulate as sim
def main():
 p=argparse.ArgumentParser();p.add_argument('--output',type=Path,required=True);p.add_argument('--project',type=Path,default=ROOT/'patch-notes');a=p.parse_args();out=a.output.resolve();out.mkdir(parents=True,exist_ok=False)
 project=a.project.resolve();before=sim.source_hashes(project);sim.write_json(out/'before-manifest.json',before);shutil.copy2(__file__,out/'runner.py')
 env=sim.isolated_environment(out/'profile');folder=Path(env['APPDATA'])/'Godot/export_templates/4.7.1.stable';folder.mkdir(parents=True)
 templates=Path('C:/Users/64jus/AppData/Roaming/Godot/export_templates/4.7.1.stable');copies=[];inputs={}
 for name in ['windows_debug_x86_64.exe','windows_debug_x86_64_console.exe']:
  source=templates/name;target=folder/name;shutil.copy2(source,target);copies.append(target);inputs[name]=sim.sha(source);assert sim.sha(target)==inputs[name]
 godot=sim.resolve_godot('C:/Users/64jus/Downloads/Godot_v4.7.1-stable_win64.exe/Godot_v4.7.1-stable_win64.exe');exe=out/'MarketHistoryAcceptance.exe'
 command=[str(godot),'--headless','--audio-driver','Dummy','--path',str(project),'--export-debug','Patch Notes v0.01',str(exe)]
 started=time.monotonic();code=None;timeout=False
 with (out/'export.log').open('wb') as log:
  child=subprocess.Popen(command,env=env,cwd=ROOT,stdout=log,stderr=subprocess.STDOUT)
  try:code=child.wait(timeout=300)
  except subprocess.TimeoutExpired:timeout=True;child.terminate();child.wait()
 after=sim.source_hashes(project);meaningful=lambda d:{k:v for k,v in d.items() if not k.endswith(('.uid','.import'))}
 assert meaningful(before)==meaningful(after),'Export changed actual source'
 sim.write_json(out/'after-manifest.json',after)
 outputs={f.name:{'bytes':f.stat().st_size,'sha256':sim.sha(f)} for f in out.glob('MarketHistoryAcceptance*') if f.is_file()}
 result={'ok':code==0 and exe.exists() and not timeout,'exit':code,'timeout':timeout,'seconds':time.monotonic()-started,'argv':command,'template_inputs':inputs,'outputs':outputs,'source_semantics_unchanged':True,'log_sha256':sim.sha(out/'export.log')}
 # Remove only our verified private template copies, never the user's originals.
 for f in copies:
  assert f.resolve().is_relative_to(out) and not f.is_symlink();f.unlink()
 sim.write_json(out/'result.json',result);print(json.dumps(result));print((out/'export.log').read_text(errors='replace')[-1800:]);return 0 if result['ok'] else 1
if __name__=='__main__':sys.exit(main())
