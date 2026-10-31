"""Run the embedded acceptance entrypoint; external --script is not an EXE entry."""
import argparse,json,subprocess,sys,time
from pathlib import Path
ROOT=Path(__file__).resolve().parents[4];sys.path.insert(0,str(ROOT));from tools import simulate as sim
def main():
 p=argparse.ArgumentParser();p.add_argument('--exe',type=Path,required=True);p.add_argument('--project',type=Path,required=True);p.add_argument('--output',type=Path,required=True);p.add_argument('--source',required=True);p.add_argument('--native',action='store_true');a=p.parse_args();a.output=a.output.resolve();a.output.mkdir(parents=True,exist_ok=False)
 env=sim.isolated_environment(a.output/'profile');before=sim.source_hashes(a.project.resolve());sim.write_json(a.output/'source-manifest.json',before);report=a.output/'report.json';argv=[str(a.exe.resolve()),'--audio-driver','Dummy']+([] if a.native else ['--headless'])+['--quit-after','100000','--','--output='+report.as_posix()];started=time.monotonic();code=None
 try:
  with (a.output/'godot.log').open('wb') as stream:code=subprocess.run(argv,cwd=a.exe.resolve().parent,env=env,stdout=stream,stderr=subprocess.STDOUT,timeout=180).returncode
 except subprocess.TimeoutExpired:pass
 log=(a.output/'godot.log').read_text(errors='replace');errors=[x for x in log.splitlines() if x.startswith(('SCRIPT ERROR:','ERROR:'))];sim.check_snapshot(a.project.resolve(),before);body=json.loads(report.read_text()) if report.exists() else {}
 result={'exit':code,'ok':code==0 and not errors and bool(body) and body.get('source')==a.source and not body.get('failures'),'engine_errors':errors,'report_source':body.get('source'),'expected_source':a.source,'seconds':time.monotonic()-started,'argv':argv,'exe_sha256':sim.sha(a.exe),'pack_sha256':sim.sha(a.exe.with_suffix('.pck')),'adapter_sha256':sim.sha(a.project/'acceptance/main.gd'),'runner_sha256':sim.sha(Path(__file__)),'log_sha256':sim.sha(a.output/'godot.log'),'source_unchanged':True};sim.write_json(a.output/'result.json',result);print(json.dumps(result));print(log[-3000:]);sys.exit(0 if result['ok'] else 1)
if __name__=='__main__':main()
