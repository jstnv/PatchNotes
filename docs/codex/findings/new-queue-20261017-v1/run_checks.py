from pathlib import Path
import importlib.util,json,re,subprocess,sys,socket
BASE=Path(__file__).resolve().parent
ROOT=BASE.parents[3]
GODOT=Path(r'C:\Users\64jus\Downloads\Godot_v4.7.1-stable_win64.exe\Godot_v4.7.1-stable_win64_console.exe')
spec=importlib.util.spec_from_file_location('sim',ROOT/'tools/simulate.py')
sim=importlib.util.module_from_spec(spec);spec.loader.exec_module(sim)
def run(stage,names,source=None):
 out=BASE/stage;out.mkdir(exist_ok=False)
 project=out/'project';sim.write_json(out/'source.json',sim.copy_snapshot(source or ROOT/'patch-notes',project))
 results=[]
 for name in ['import',*names]:
  env=sim.isolated_environment(out/('profile-'+name))
  env['PN_CARD_FRAME_OUTPUT']=str(out/'frame.json')
  with socket.socket() as s:s.bind(('127.0.0.1',0));env['PN_CHECKPOINT_TEST_PORT']=str(s.getsockname()[1])
  if name=='market-cold':env['PN_INDEX_COLD']='1'
  if name=='alpha-cold':env['PN_ALPHA_PACK_COLD']='1'
  env['PN_OLD_WORLD_FRAME']=str(BASE/'founder-baseline/frame.json')
  script='verify_market_release_index' if name=='market-cold' else name
  if name=='alpha-cold':script='verify_alpha_shop_pack'
  args=['--editor','--import','--quit'] if name=='import' else ['--script','res://scripts/debug/'+script+'.gd']
  cmd=[str(GODOT),* ([] if name=='verify_alpha_pack_ui' else ['--headless']),'--audio-driver','Dummy','--path',str(project),*args]
  with (out/(name+'.log')).open('wb') as log:
   done=subprocess.run(cmd,env=env,stdout=log,stderr=subprocess.STDOUT,timeout=240)
  lines=(out/(name+'.log')).read_text(encoding='utf-8',errors='replace').splitlines()
  errors=[x for x in lines if re.search(r'SCRIPT ERROR|Parse Error|^ERROR:|FAIL:',x)]
  row={'name':name,'command':cmd,'exit':done.returncode,'errors':errors,'summary':[x for x in lines if re.search(r'checks|failures|passed|source=',x,re.I)][-6:]}
  results.append(row);sim.write_json(out/'results.json',results);print(json.dumps(row),flush=True)
  if done.returncode or errors:raise RuntimeError(name)
 return out
if __name__=='__main__':run(sys.argv[1],sys.argv[2:])
