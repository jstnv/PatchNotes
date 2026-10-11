from pathlib import Path
import importlib.util,os,json
ROOT=Path(__file__).resolve().parents[4];OUT=Path(__file__).resolve().parent/'text-fix-checks';OUT.mkdir()
def load(n,p):
 s=importlib.util.spec_from_file_location(n,p);m=importlib.util.module_from_spec(s);s.loader.exec_module(m);return m
g=load('gate',ROOT/'tools/release_gate.py');c=load('checks',ROOT/'docs/codex/findings/checkpoint-runtime-v1/run_checks.py')
c.HERE=OUT;c.PROFILE=OUT/'profiles'
c.GODOT=r'C:/Users/64jus/Downloads/Godot_v4.7.1-stable_win64.exe/Godot_v4.7.1-stable_win64_console.exe'
os.environ['PN_CHECKPOINT_TEST_PORT']='47733'
c.run('import',['--editor','--import','--quit'])
for name in ['verify_first_game_and_tips','verify_design_phase']:
 path=ROOT/'patch-notes/scripts/debug'/f'{name}.gd';wrapper,meta=g.checkpoint_wrapper(path,OUT/'wrappers')
 os.environ['PN_CARD_FRAME_OUTPUT']=str(OUT/(name+'.json'))
 c.run(name,['--script',str(wrapper)])
(OUT/'result.json').write_text(json.dumps({'passed':['verify_first_game_and_tips','verify_design_phase'],'source_sha256':g.sha(ROOT/'patch-notes/scripts/phases/design_phase.gd')},indent=2))
