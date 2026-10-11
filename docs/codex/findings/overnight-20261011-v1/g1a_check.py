from pathlib import Path
import importlib.util, json, os, subprocess, sys
HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[3]
variant = HERE/'g1a-archive-validation-v1'
project = variant/'project'
spec=importlib.util.spec_from_file_location('sim',ROOT/'tools/simulate.py'); sim=importlib.util.module_from_spec(spec); spec.loader.exec_module(sim)
godot=Path('C:/Users/64jus/Downloads/Godot_v4.7.1-stable_win64.exe/Godot_v4.7.1-stable_win64_console.exe')
out=HERE/sys.argv[1];out.mkdir()
env=sim.isolated_environment(out/'profile')
sim.run_process('import',[str(godot),'--headless','--path',str(project),'--editor','--import','--quit'],out,env,240)
before=sim.source_hashes(project)
result=sim.run_process('unit',[str(godot),'--headless','--path',str(project),'--script','res://scripts/debug/verify_incumbent_archive.gd'],out,env,120)
after=sim.source_hashes(project)
(out/'source.json').write_text(json.dumps({'before':before,'after':after,'unchanged':before==after},indent=2))
if before!=after:raise SystemExit('Candidate changed during test')
print(json.dumps(result))
config=json.loads((ROOT/'docs/codex/threads/ai-competitors/sims/g1a-archive-candidate-2026-10-11-v2/inputs/requested.json').read_text())
config['cases']=[c for c in config['cases'] if 'incumbent' in c['initial']['recipe']]
for case in config['cases']:case['max_commands']=100;case['target_release_count']=2
(HERE/'g1a-two-release-input.json').write_text(json.dumps(config,indent=2))
