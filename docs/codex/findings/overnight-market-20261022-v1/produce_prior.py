from pathlib import Path
import importlib.util,subprocess
ROOT=Path(__file__).resolve().parents[4];OUT=Path(__file__).resolve().parent
spec=importlib.util.spec_from_file_location('sim',ROOT/'tools/simulate.py');sim=importlib.util.module_from_spec(spec);spec.loader.exec_module(sim)
project=ROOT/'docs/codex/findings/store-gameplay-links-20261018-v1/w/project'
env=sim.isolated_environment(OUT/'prior-profile');env['PN_CARD_FRAME_OUTPUT']=str(OUT/'prior-world.json')
cmd=[r'C:\Users\64jus\Downloads\Godot_v4.7.1-stable_win64.exe\Godot_v4.7.1-stable_win64_console.exe','--headless','--audio-driver','Dummy','--path',str(project),'--script','res://scripts/debug/verify_legacy_world.gd']
with (OUT/'prior-world.log').open('wb') as log:r=subprocess.run(cmd,env=env,stdout=log,stderr=subprocess.STDOUT,timeout=180)
print(r.returncode)
print((OUT/'prior-world.log').read_text(encoding='utf8',errors='replace').splitlines()[-5:])
print(sim.read_json(OUT/'prior-world.json')['world']['source_identity'])
