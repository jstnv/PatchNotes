from pathlib import Path
import importlib.util,hashlib,json,socket,subprocess,sys,time
OUT=Path(__file__).resolve().parent
ROOT=OUT.parents[3]
spec=importlib.util.spec_from_file_location('sim',ROOT/'tools/simulate.py')
sim=importlib.util.module_from_spec(spec);spec.loader.exec_module(sim)
label,*args=sys.argv[1:]
assert not (OUT/(label+'-run.json')).exists()
manifest=json.loads((OUT/'diagnostic-release.json').read_text())
exe=Path(manifest['exe'])
assert hashlib.sha256(exe.read_bytes()).hexdigest()==manifest['exe_sha256']
script=OUT/'exe_research_latency.gd'
probe=(OUT.parent/'research-latency-20261027-v1/research_latency.gd').read_text(encoding='utf-8')
probe=probe.replace('"res://../tools/fixtures/background_checkpoint_v003_c96.json"','OS.get_environment("PN_BG_FIXTURE")')
script.write_text(probe,encoding='utf-8')
env=sim.isolated_environment(ROOT/'.codex-godot-temp'/label)
env['PN_CARD_FRAME_OUTPUT']=str(OUT/(label+'.json'))
fixture=ROOT/'tools/fixtures/background_checkpoint_v003_c96.json'
assert hashlib.sha256(fixture.read_bytes()).hexdigest()=='83e8e896a0641f95037b1ff908c1cba8daf7576252ad0aa9cda93efba1ba03be'
env['PN_BG_FIXTURE']=str(fixture)
with socket.socket() as sock:
 sock.bind(('127.0.0.1',0));env['PN_CHECKPOINT_TEST_PORT']=str(sock.getsockname()[1])
command=[str(exe),'--audio-driver','Dummy','--rendering-method','gl_compatibility','--resolution','1280x720','--position','80,80']
if '--headless' in args:command.append('--headless')
start=time.monotonic()
with (OUT/(label+'.log')).open('xb') as log:
 try:code=subprocess.run(command,env=env,stdout=log,stderr=subprocess.STDOUT,timeout=420).returncode
 except subprocess.TimeoutExpired:code=124
lines=(OUT/(label+'.log')).read_text(encoding='utf-8',errors='replace').splitlines()
errors=[line for line in lines if any(k in line for k in ['SCRIPT ERROR','ERROR:','Parse Error','FAIL:'])]
report={'command':command,'exit':code,'errors':errors,'elapsed_seconds':time.monotonic()-start,'exe_sha256':manifest['exe_sha256'],'probe_sha256':hashlib.sha256(script.read_bytes()).hexdigest(),'tail':lines[-4:]}
(OUT/(label+'-run.json')).write_text(json.dumps(report,indent=2),encoding='utf-8')
print(json.dumps(report),flush=True)
raise SystemExit(code if code else int(bool(errors)))
