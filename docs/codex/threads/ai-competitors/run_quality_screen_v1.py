"""Declared all-eight ordinary-funding screen; retain every failure/tape."""
from pathlib import Path
from concurrent.futures import ThreadPoolExecutor,as_completed
import argparse,subprocess,json,sys,time
ROOT=Path(__file__).resolve().parents[4];sys.path.insert(0,str(ROOT/'tools'));import simulate as sim
def main():
 p=argparse.ArgumentParser();p.add_argument('--project',type=Path,required=True);p.add_argument('--output',type=Path,required=True);p.add_argument('--seeds',default='5607');a=p.parse_args();out=a.output.resolve();out.mkdir(parents=True,exist_ok=False);project=a.project.resolve();frozen=sim.source_hashes(project);sim.write_json(out/'source-manifest.json',frozen)
 godot=sim.resolve_godot('C:/Users/64jus/Downloads/Godot_v4.7.1-stable_win64.exe/Godot_v4.7.1-stable_win64.exe');rows=[]
 def run_case(genre,seed):
  case=out/(genre+'-'+seed);case.mkdir();output=case/'career.json';argv=[str(godot),'--headless','--audio-driver','Dummy','--path',str(project),'--script','res://scripts/debug/quality_career_probe.gd','--',f'--genre={genre}',f'--seed={seed}',f'--output={output}'];sim.write_json(case/'command.json',{'argv':argv,'timeout':240});start=time.monotonic();code=None;timeout=False
  with (case/'godot.log').open('wb') as log:
   child=subprocess.Popen(argv,env=sim.isolated_environment(case/'profile'),cwd=ROOT,stdout=log,stderr=subprocess.STDOUT)
   try:code=child.wait(timeout=240)
   except subprocess.TimeoutExpired:timeout=True;child.terminate();child.wait()
  log=(case/'godot.log').read_text(encoding='utf-8',errors='replace');result=sim.read_json(output) if output.exists() else {};records=result.get('releases',[])
  row={'genre':genre,'seed':seed,'exit':code,'timeout':timeout,'seconds':time.monotonic()-start,'issue':result.get('issue','missing result'),'cycle':result.get('cycle'),'scope':result.get('scope'),'cash':result.get('cash'),'phase':result.get('phase'),'reviews':[r['sales']['review_tenths'] for r in records],'all_full_scope':all(r['metadata']['review']['scope']>=r['metadata']['review']['required_scope'] for r in records),'all_zero_bugs':all(r['metadata']['review']['remaining_bugs']==0 for r in records),'source':result.get('source'),'errors':'SCRIPT ERROR' in log or '\nERROR:' in log,'log_sha256':sim.sha(case/'godot.log')};sim.write_json(case/'result.json',row);return row
 with ThreadPoolExecutor(max_workers=2) as pool:
  jobs=[pool.submit(run_case,g,seed) for seed in a.seeds.split(',') for g in ['action','adventure','role_playing','strategy','simulation','puzzle','sports','racing']]
  for future in as_completed(jobs):
   row=future.result();rows.append(row);sim.write_json(out/'screen.json',{'cases':rows});print(json.dumps(row),flush=True)
 sim.check_snapshot(project,frozen);sim.write_json(out/'screen.json',{'source_unchanged':True,'cases':rows,'full72':sum(r['exit']==0 and r['cycle']==72 for r in rows)});return 0 if all(r['exit']==0 and not r['errors'] for r in rows) else 1
if __name__=='__main__':sys.exit(main())
