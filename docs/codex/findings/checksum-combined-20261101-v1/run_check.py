"""Bounded checks with private profiles; optional final full-source fence."""
from pathlib import Path
import argparse,json,os,socket,subprocess,sys,time
ROOT=Path(__file__).resolve().parents[4]
sys.path.insert(0,str(ROOT))
from tools import simulate as sim
p=argparse.ArgumentParser()
p.add_argument('--script',required=True)
p.add_argument('--output',type=Path,required=True)
p.add_argument('--fixture',type=Path)
p.add_argument('--native',action='store_true')
p.add_argument('--fence',action='store_true')
p.add_argument('--second-year',action='store_true')
p.add_argument('--timeout',type=int,default=150)
a=p.parse_args();out=a.output.resolve();out.mkdir(parents=True,exist_ok=False)
env=sim.isolated_environment(out/'profile')
with socket.socket() as sock:
    sock.bind(('127.0.0.1',0));env['PN_CHECKPOINT_TEST_PORT']=str(sock.getsockname()[1])
env['PN_AWARDS_FIXTURE_OUTPUT']=str(out/'fixture.json')
env['PN_AWARDS_REPORT_OUTPUT']=str(out/'report.json')
if a.second_year:env['PN_AWARDS_SECOND_YEAR']='1'
if a.fixture:env['PN_AWARDS_UI_FIXTURE']=str(a.fixture.resolve())
before=sim.source_hashes(ROOT/'patch-notes') if a.fence else None
argv=['C:/Users/64jus/Downloads/Godot_v4.7.1-stable_win64.exe/Godot_v4.7.1-stable_win64.exe']+([] if a.native else ['--headless'])+['--audio-driver','Dummy','--path',str(ROOT/'patch-notes'),'--script',a.script]
start=time.monotonic();code=None
try:
    with (out/'godot.log').open('wb') as f:code=subprocess.run(argv,cwd=ROOT,env=env,stdout=f,stderr=subprocess.STDOUT,timeout=a.timeout).returncode
except subprocess.TimeoutExpired:pass
log=(out/'godot.log').read_text(encoding='utf-8',errors='replace');errors=[x for x in log.splitlines() if x.startswith(('ERROR:','SCRIPT ERROR:','FAIL:'))]
fenced=before is None or sim.source_hashes(ROOT/'patch-notes')==before
result={'exit':code,'errors':errors,'ok':code==0 and not errors and fenced,'source_fenced':before is not None,'source_unchanged':fenced,'seconds':time.monotonic()-start,'argv':argv}
sim.write_json(out/'result.json',result)
if before is not None:sim.write_json(out/'source-manifest.json',before)
print(json.dumps(result));print(log[-5000:]);sys.exit(0 if result['ok'] else 1)
