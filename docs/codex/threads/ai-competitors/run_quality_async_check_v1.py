"""Bounded native/headless async verifier, private profile, full raw source fence."""
import argparse,json,subprocess,sys,time
from pathlib import Path
ROOT=Path(__file__).resolve().parents[4];sys.path.insert(0,str(ROOT));from tools import simulate as sim
def main():
 p=argparse.ArgumentParser();p.add_argument('--project',type=Path,required=True);p.add_argument('--script',type=Path,required=True);p.add_argument('--output',type=Path,required=True);p.add_argument('--native',action='store_true');p.add_argument('--timeout',type=int,default=180);a=p.parse_args();a.output=a.output.resolve();a.output.mkdir(parents=True,exist_ok=False)
 env=sim.isolated_environment(a.output/'profile');godot=sim.resolve_godot('C:/Users/64jus/Downloads/Godot_v4.7.1-stable_win64.exe/Godot_v4.7.1-stable_win64.exe');hashes=sim.source_hashes(a.project.resolve());sim.write_json(a.output/'snapshot-manifest.json',hashes);report=a.output/'report.json'
 argv=[str(godot)]+([] if a.native else ['--headless','--audio-driver','Dummy'])+['--path',str(a.project.resolve()),'--script',str(a.script.resolve()),'--quit-after','100000','--','--output='+report.as_posix()]
 started=time.monotonic();code=None
 try:
  with (a.output/'godot.log').open('wb') as stream:code=subprocess.run(argv,cwd=ROOT,env=env,stdout=stream,stderr=subprocess.STDOUT,timeout=a.timeout).returncode
 except subprocess.TimeoutExpired:pass
 log=(a.output/'godot.log').read_text(errors='replace');errors=[x for x in log.splitlines() if x.startswith(('ERROR:','SCRIPT ERROR:'))];sim.check_snapshot(a.project.resolve(),hashes)
 result={'exit':code,'ok':code==0 and not errors and report.exists(),'engine_errors':errors,'source_unchanged':True,'native':a.native,'seconds':time.monotonic()-started,'argv':argv,'probe_sha256':sim.sha(a.script),'runner_sha256':sim.sha(Path(__file__)),'log_sha256':sim.sha(a.output/'godot.log')};sim.write_json(a.output/'result.json',result);print(json.dumps(result));print(log[-3000:]);sys.exit(0 if result['ok'] else 1)
if __name__=='__main__':main()
