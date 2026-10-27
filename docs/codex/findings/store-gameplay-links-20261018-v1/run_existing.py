from pathlib import Path
import importlib.util,json,re,subprocess,sys,socket
ROOT=Path(__file__).resolve().parents[4]
OUT=Path(__file__).resolve().parent
spec=importlib.util.spec_from_file_location('sim',ROOT/'tools/simulate.py')
sim=importlib.util.module_from_spec(spec);spec.loader.exec_module(sim)
GODOT=r'C:\Users\64jus\Downloads\Godot_v4.7.1-stable_win64.exe\Godot_v4.7.1-stable_win64_console.exe'
if __name__=='__main__':
 stage=OUT/sys.argv[1];stage.mkdir(exist_ok=True)
 project=stage/'project';None
 sim.write_json(stage/'git.json',{'branch':subprocess.check_output(['git','branch','--show-current'],cwd=ROOT,text=True).strip(),'head':subprocess.check_output(['git','rev-parse','HEAD'],cwd=ROOT,text=True).strip(),'status':subprocess.check_output(['git','status','--porcelain=v1'],cwd=ROOT,text=True)})
 results=json.loads((stage/'results.json').read_text()) if (stage/'results.json').exists() else []
 for name in sys.argv[2:]:
  env=sim.isolated_environment(stage/('profile-'+name));env['PN_CARD_FRAME_OUTPUT']=str(stage/(name+'.json'))
  env['PN_AUDIO_LONG']='1' if sys.argv[1].startswith('long-') and name=='verify_pause_music' else '0'
  env['PN_PAUSE_PRIOR_WORLD']=str(OUT/'before/verify_legacy_world.json')
  env['PN_GUIDE_CAPTURE']=str(stage)
  env['PN_STORE_CAPTURE']=str(stage)
  env['PN_SALES_HUD_CAPTURE']=str(stage)
  env['PN_OLD_WORLD_FRAME']=str(OUT/'before/verify_legacy_world.json')
  env['PN_GAMEPLAY_PRIOR_SAVES']=str(OUT/'before/produce_gameplay_prior.json')
  env['PN_BRANCH_REPLAY_INPUT']=str(stage/'verify_primitive_branches.json')
  env['PN_OLD_CONTRACT_STORAGE']=str(OUT/'prior-contract-storage-v2')
  env['PN_CHALLENGE_CAPTURE']=str(stage)
  with socket.socket() as sock:sock.bind(('127.0.0.1',0));env['PN_CHECKPOINT_TEST_PORT']=str(sock.getsockname()[1])
  args=['--editor','--import','--quit'] if name=='import' else ['--script','res://scripts/debug/'+name+'.gd']
  if name=='verify_world_restore_file':
   args+=['--',str(OUT/'before/verify_legacy_world.json'),str(stage/'restored-world.json')]
  if name=='verify_feature_store_navigation':
   wrapper=stage/(name+'-isolated.gd')
   wrapper.write_text('extends "res://scripts/debug/verify_feature_store_navigation.gd"\nfunc _initialize()->void:\n\tnode_added.connect(func(node:Node):\n\t\tif node is CheckpointCoordinator:node.store=preload("res://scripts/debug/verify_rival_gameplay_activation.gd").TestStore.new("user://saves/studio",node._validate_payload))\n\tsuper._initialize()\n')
   args=['--script',str(wrapper)]
  if name=='verify_gameplay_extra':args=['--script',str(OUT/'verify_gameplay_extra.gd')]
  if name=='produce_gameplay_prior':args=['--script',str(OUT/'produce_gameplay_prior.gd')]
  if name=='verify_pause_track_long':args=['--script',str(OUT/'verify_pause_track_long.gd')]
  display=[] if name.startswith('capture_') else ['--headless']
  cmd=[GODOT,*display,'--audio-driver',('WASAPI' if name.startswith('verify_pause_track') else 'Dummy'),'--path',str(project),*args]
  with (stage/(name+'.log')).open('wb') as log:done=subprocess.run(cmd,env=env,stdout=log,stderr=subprocess.STDOUT,timeout=240)
  lines=(stage/(name+'.log')).read_text(encoding='utf-8',errors='replace').splitlines()
  errors=[x for x in lines if re.search(r'SCRIPT ERROR|Parse Error|^ERROR:|FAIL:',x)]
  row={'name':name,'command':cmd,'exit':done.returncode,'errors':errors,'summary':[x for x in lines if re.search(r'checks|failures|passed',x,re.I)][-5:]}
  results.append(row);sim.write_json(stage/'results.json',results);print(json.dumps(row),flush=True)
  if done.returncode or errors:raise RuntimeError(name)
