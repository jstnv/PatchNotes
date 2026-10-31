"""Bounded, isolated headless/native/exported Market checks with actual logs."""
from pathlib import Path
import argparse,hashlib,json,socket,subprocess,sys,time,shutil
ROOT=Path(__file__).resolve().parents[4];sys.path.insert(0,str(ROOT/'tools'));import simulate as sim
def main():
 p=argparse.ArgumentParser();p.add_argument('--output',type=Path,required=True);p.add_argument('--script',default='res://scripts/debug/verify_historical_market.gd');p.add_argument('--native',action='store_true');p.add_argument('--exe',type=Path);p.add_argument('--timeout',type=int,default=180);p.add_argument('extra',nargs='*');a=p.parse_args()
 out=a.output.resolve();out.mkdir(parents=True,exist_ok=False);env=sim.isolated_environment(out/'profile')
 env['PN_CARD_FRAME_OUTPUT']=str(out/'report.json');env['PN_MARKET_CAPTURE']=str(out)
 with socket.socket() as sock:sock.bind(('127.0.0.1',0));env['PN_CHECKPOINT_TEST_PORT']=str(sock.getsockname()[1])
 project=ROOT/'patch-notes';before=sim.source_hashes(project);sim.write_json(out/'source-manifest.json',before)
 script=project/a.script[6:] if a.script.startswith('res://') else Path(a.script)
 shutil.copy2(script,out/'probe.gd');shutil.copy2(__file__,out/'runner.py')
 godot=a.exe.resolve() if a.exe else sim.resolve_godot('C:/Users/64jus/Downloads/Godot_v4.7.1-stable_win64.exe/Godot_v4.7.1-stable_win64.exe')
 command=[str(godot),'--audio-driver','Dummy']
 if not a.exe:command+=['--path',str(project)]
 if a.native:command+=['--rendering-method','gl_compatibility','--resolution','1152x648','--position','80,80']
 else:command+=['--headless']
 command+=['--script',str(script) if a.exe else a.script]
 if a.extra:command+=['--']+a.extra
 started=time.monotonic();code=None;timeout=False
 with (out/'godot.log').open('wb') as log:
  process=subprocess.Popen(command,env=env,cwd=godot.parent if a.exe else ROOT,stdout=log,stderr=subprocess.STDOUT)
  try:code=process.wait(timeout=a.timeout)
  except subprocess.TimeoutExpired:timeout=True;process.terminate();process.wait()
 text=(out/'godot.log').read_text(errors='replace');sim.check_snapshot(project,before)
 ok=code==0 and not timeout and 'SCRIPT ERROR' not in text and '\nERROR:' not in text
 if a.script.endswith('verify_historical_market.gd'):ok=ok and 'HISTORICAL_MARKET {' in text
 if a.script.endswith('verify_market_browser.gd'):ok=ok and 'MARKET_BROWSER checks=' in text
 result={'ok':ok,'exit':code,'timeout':timeout,'seconds':time.monotonic()-started,'argv':command,'settings':{key:env[key] for key in ['PN_CHECKPOINT_TEST_PORT','PN_CARD_FRAME_OUTPUT','PN_MARKET_CAPTURE']},'script_sha256':sim.sha(script),'runner_sha256':sim.sha(Path(__file__)),'engine_sha256':sim.sha(godot),'log_sha256':sim.sha(out/'godot.log'),'source_unchanged':True}
 sim.write_json(out/'result.json',result);print(json.dumps(result));print(text[-2200:]);return 0 if ok else 1
if __name__=='__main__':sys.exit(main())
