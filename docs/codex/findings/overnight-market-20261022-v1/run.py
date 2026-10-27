from pathlib import Path
import importlib.util,json,os,re,socket,subprocess,sys
ROOT=Path(__file__).resolve().parents[4]
OUT=Path(__file__).resolve().parent
def module(name,path):
 spec=importlib.util.spec_from_file_location(name,path); value=importlib.util.module_from_spec(spec);spec.loader.exec_module(value);return value
sim=module('sim',ROOT/'tools/simulate.py')
GODOT=r'C:\Users\64jus\Downloads\Godot_v4.7.1-stable_win64.exe\Godot_v4.7.1-stable_win64_console.exe'
if __name__=='__main__':
 stage=OUT/sys.argv[1];stage.mkdir(exist_ok=False);(stage/'.gdignore').touch()
 project=stage/'project';sim.write_json(stage/'source.json',sim.copy_snapshot(ROOT/'patch-notes',project))
 oracle=ROOT/'docs/codex/threads/simulation-engine/m3a-v1/gameplay_oracle.gd'
 target=stage/oracle.relative_to(ROOT);target.parent.mkdir(parents=True,exist_ok=True);target.write_bytes(oracle.read_bytes())
 sim.write_json(stage/'git.json',{'branch':subprocess.check_output(['git','branch','--show-current'],cwd=ROOT,text=True).strip(),'head':subprocess.check_output(['git','rev-parse','HEAD'],cwd=ROOT,text=True).strip()})
 results=[]
 for name in ['import',*sys.argv[2:]]:
  env=sim.isolated_environment(stage/('profile-'+name));env['PN_CARD_FRAME_OUTPUT']=str(stage/(name+'.json'))
  env['PN_MARKET_CAPTURE']=str(stage);env['PN_SALES_HUD_CAPTURE']=str(stage);env['PN_STORE_CAPTURE']=str(stage)
  env['PN_GAMEPLAY_PRIOR_SAVES']=str(ROOT/'tools/fixtures/gameplay_parents_pre_change_v1.json')
  if name=='verify_queue_source_migration':env['PN_OLD_WORLD_FRAME']=str(ROOT/'tools/fixtures/queue_migration_pre_alpha_v1.json')
  if name=='verify_market_release_index_cold':env['PN_INDEX_COLD']='1';env['PN_CARD_FRAME_OUTPUT']=str(stage/'verify_market_release_index.json')
  env['PN_PAUSE_PRIOR_WORLD']=str(OUT/'prior-world.json') if (OUT/'prior-world.json').is_file() else ''
  with socket.socket() as sock:sock.bind(('127.0.0.1',0));env['PN_CHECKPOINT_TEST_PORT']=str(sock.getsockname()[1])
  script=name.replace('capture_market_browser','verify_market_browser').replace('verify_market_release_index_cold','verify_market_release_index')
  args=['--editor','--import','--quit'] if name=='import' else ['--script','res://scripts/debug/'+script+'.gd']
  if name=='verify_world_restore_file':args+=['--',str(OUT/'prior-world.json'),str(stage/'restored-world.json')]
  if name=='calendar_distress_probe':args=['--script',str(OUT/'calendar_distress_probe.gd'),'--',str(stage/'calendar-distress.json')]
  cmd=[GODOT,*([] if name.startswith('capture_') else ['--headless']),'--audio-driver','Dummy','--path',str(project),*args]
  with (stage/(name+'.log')).open('wb') as log:
   done=subprocess.run(cmd,env=env,stdout=log,stderr=subprocess.STDOUT,timeout=300)
  lines=(stage/(name+'.log')).read_text(encoding='utf8',errors='replace').splitlines()
  row={'name':name,'command':cmd,'exit':done.returncode,'errors':[x for x in lines if re.search(r'SCRIPT ERROR|Parse Error|^ERROR:|FAIL:',x)],'summary':[x for x in lines if re.search(r'checks=|failures|passed',x,re.I)][-5:]}
  results.append(row);sim.write_json(stage/'results.json',results);print(json.dumps(row),flush=True)
  if done.returncode or row['errors']:sys.exit(1)
