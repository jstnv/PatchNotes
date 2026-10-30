from pathlib import Path
import json,os,subprocess,re,hashlib
OUT=Path(__file__).resolve().parent
manifest=json.loads((OUT/'internal-release/build-manifest.json').read_text())
workspace=Path(manifest['workspace']);project=workspace/'source'
probe=(OUT.parent/'research-latency-20261027-v1/research_latency.gd').read_text(encoding='utf-8').replace('"res://../tools/fixtures/background_checkpoint_v003_c96.json"','OS.get_environment("PN_BG_FIXTURE")')
(project/'perf_probe.gd').write_text(probe,encoding='utf-8')
(project/'perf_boot.gd').write_text('extends Node\nfunc _ready() -> void:\n\tvar tree:=get_tree()\n\ttree.set_script(load("res://perf_probe.gd"))\n\ttree.call("_initialize")\n',encoding='utf-8')
(project/'perf_boot.tscn').write_text('[gd_scene load_steps=2 format=3]\n[ext_resource type="Script" path="res://perf_boot.gd" id="1"]\n[node name="PerformanceProbe" type="Node"]\nscript = ExtResource("1")\n',encoding='utf-8')
config=project/'project.godot';source=config.read_text(encoding='utf-8')
source,count=re.subn(r'run/main_scene="[^"]+"','run/main_scene="res://perf_boot.tscn"',source)
assert count==1;config.write_text(source,encoding='utf-8')
receipt=json.loads((OUT/'internal-release/export-release.command.json').read_text())
env=os.environ.copy();env.update(receipt['profile'])
godot=receipt['command'][0]
exe=workspace/'demo/Research Performance Probe.exe'
results=[]
for label,command in [('probe-import',[godot,'--headless','--path',str(project),'--editor','--import','--quit']),('probe-export',[godot,'--headless','--text-driver','Dummy','--path',str(project),'--export-release',manifest['export_preset'],str(exe)])]:
 result=subprocess.run(command,env=env,stdout=subprocess.PIPE,stderr=subprocess.STDOUT,timeout=180)
 text=result.stdout.decode('utf-8',errors='replace');(OUT/(label+'.log')).write_text(text,encoding='utf-8')
 errors=[line for line in text.splitlines() if any(k in line for k in ['SCRIPT ERROR','ERROR:','Parse Error','FAIL:'])]
 results.append({'label':label,'command':command,'exit':result.returncode,'errors':errors})
 assert not result.returncode and not errors,results[-1]
report={'exe':str(exe),'exe_sha256':hashlib.sha256(exe.read_bytes()).hexdigest(),'checks':results,'build_only_probe_files':['perf_probe.gd','perf_boot.gd','perf_boot.tscn'],'canonical_modified':False}
(OUT/'diagnostic-release.json').write_text(json.dumps(report,indent=2),encoding='utf-8');print(json.dumps(report))
