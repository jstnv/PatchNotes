from pathlib import Path
import os,json,subprocess,hashlib,uuid,re
H=Path(__file__).resolve().parent
PROJECT=H.parents[3]/'patch-notes'
GODOT=r'C:/Users/64jus/Downloads/Godot_v4.7.1-stable_win64.exe/Godot_v4.7.1-stable_win64_console.exe'
def sha(p):return hashlib.sha256(Path(p).read_bytes()).hexdigest()
def capture():
 paths=[PROJECT/'project.godot']+list((PROJECT/'scripts').rglob('*.gd'))+list((PROJECT/'data').rglob('*.json'))
 return dict(project=str(PROJECT),files={p.relative_to(PROJECT).as_posix():sha(p) for p in sorted(paths)},producer_sha256=sha(H/'create_fixture.gd'),runner_sha256=sha(H/'run.py'),plan_sha256=sha(H/'PLAN.md'),godot_sha256=sha(GODOT))
source=capture();(H/'source-before.json').write_text(json.dumps(source,indent=2),encoding='utf8')
results=[]
fixtures=[(f'v{version}-{trait}',trait,version) for version in [3,4,5] for trait in ['college_dropout','graduate']]+[('v5-ordinary','',5)]
for name,trait,version in fixtures:
 assert not (H/(name+'.result.json')).exists(),('preserve completed fixture',name)
 assert source==capture(),'source drift before fixture'
 profile=H/'profiles'/(name+'-'+uuid.uuid4().hex[:8]);profile.mkdir(parents=True)
 env=os.environ.copy();env.update(APPDATA=str(profile),LOCALAPPDATA=str(profile))
 command=[GODOT,'--headless','--path',str(PROJECT),'--script',str(H/'create_fixture.gd'),'--',name,trait or 'none',str(version),str(H)]
 r=subprocess.run(command,env=env,stdout=subprocess.PIPE,stderr=subprocess.STDOUT,timeout=90)
 text=r.stdout.decode('utf8',errors='replace');(H/(name+'.log')).write_text(text,encoding='utf8');(H/(name+'.command.json')).write_text(json.dumps(dict(command=command,profile=str(profile),exit_code=r.returncode),indent=2),encoding='utf8')
 errors=[line for line in text.splitlines() if re.search(r'SCRIPT ERROR:|\bERROR:|\bFAIL(?:ED|URE)?\b',line,re.I) and line.strip()!='ERROR: Failed to read the root certificate store.']
 print(name,r.returncode,text[-150:],flush=True);assert r.returncode==0 and not errors,(name,errors)
 assert source==capture(),'source drift during fixture'
 result=json.loads((H/(name+'.result.json')).read_text(encoding='utf8'));assert result['passed']
 envelope=json.loads((H/(name+'.checkpoint.json')).read_text(encoding='utf8'));payload=(H/(name+'.payload.json')).read_bytes()
 assert envelope['schema_version']=='1' and envelope['payload_utf8'].encode()==payload
 assert sha(H/(name+'.payload.json'))==envelope['payload_sha256']==result['payload_sha256']
 assert sha(H/(name+'.checkpoint.json'))==result['envelope_sha256']
 manifest=dict(source_sha256=sha(H/'source-before.json'),fixture=name,trait=trait,version=version,files={ext:sha(H/(name+'.'+ext)) for ext in ['checkpoint.json','payload.json','result.json','log','command.json']})
 (H/(name+'.manifest.json')).write_text(json.dumps(manifest,indent=2),encoding='utf8');results.append(result)
assert source==capture(),'final source drift'
(H/'source-after.json').write_text(json.dumps(source,indent=2),encoding='utf8')
(H/'summary.json').write_text(json.dumps(dict(passed=True,fixtures=len(results),source_unchanged=True,results=results),indent=2),encoding='utf8')
print('Seven actual pre-education fixtures exported and verified')
