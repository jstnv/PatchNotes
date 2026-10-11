from pathlib import Path
import importlib.util,os,sys,json
ROOT=Path(__file__).resolve().parents[4]
OUT=Path(__file__).resolve().parent/sys.argv[1]
OUT.mkdir()
def load(n,p):
 s=importlib.util.spec_from_file_location(n,p);m=importlib.util.module_from_spec(s);s.loader.exec_module(m);return m
g=load('gate',ROOT/'tools/release_gate.py');c=load('checks',ROOT/'docs/codex/findings/checkpoint-runtime-v1/run_checks.py')
c.HERE=OUT;c.PROFILE=OUT/'profiles'
os.environ['PN_CHECKPOINT_TEST_PORT']='47733'
results=[]
for name in sys.argv[2:]:
 try:
  path=ROOT/'patch-notes/scripts/debug'/f'{name}.gd';wrapper,meta=g.checkpoint_wrapper(path,OUT/'wrappers')
  os.environ['PN_CARD_FRAME_OUTPUT']=str(OUT/(name+'.json'))
  c.run(name,['--script',str(wrapper)])
  results.append({'suite':name,'pass':True})
 except Exception as exc:
  results.append({'suite':name,'pass':False,'error':str(exc)})
 (OUT/'result.json').write_text(json.dumps(results,indent=2))
(OUT/'result.json').write_text(json.dumps(results,indent=2))
sys.exit(0 if all(x['pass'] for x in results) else 1)
