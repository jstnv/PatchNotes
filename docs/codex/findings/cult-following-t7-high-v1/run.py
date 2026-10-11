from pathlib import Path
import json,os,subprocess,uuid,shutil
import evidence as e
H=e.HERE
GODOT=r'C:/Users/64jus/Downloads/Godot_v4.7.1-stable_win64.exe/Godot_v4.7.1-stable_win64_console.exe'
BUILDS=[('none',0,0,''),('cult40p1',40,1,'cult_following'),('cult80p1',80,1,'cult_following'),('cult80p2',80,2,'cult_following'),('cult160p2',160,2,'cult_following'),('buzz',0,0,'studio_buzz'),('lean',0,0,'lean_production'),('family',0,0,'family_funding'),('cult80p1-buzz',80,1,'cult_following,studio_buzz'),('buzz-lean',0,0,'studio_buzz,lean_production')]
def execute(name,driver,user_args,build,profile=None):
 command=[GODOT,'--headless','--path',str(e.COPY),'--script','res://scripts/debug/'+driver,'--']+user_args
 source=e.capture()
 if (H/(name+'.json')).exists():
  e.accept(name,source,command,build);return Path(json.loads((H/(name+'.command.json')).read_text())['profile'])
 profile=profile or H/'profiles'/(name+'-'+uuid.uuid4().hex[:8]);profile.mkdir(parents=True,exist_ok=True)
 env=os.environ.copy();env.update(APPDATA=str(profile),LOCALAPPDATA=str(profile),PN_CULT_SEED=str(build[1]),PN_CULT_PRICE=str(build[2]))
 r=subprocess.run(command,env=env,stdout=subprocess.PIPE,stderr=subprocess.STDOUT,timeout=240);text=r.stdout.decode('utf8',errors='replace')
 (H/(name+'.log')).write_text(text,encoding='utf8');(H/(name+'.command.json')).write_text(json.dumps(dict(command=command,seed=build[1],price=build[2],profile=str(profile),exit_code=r.returncode),indent=2),encoding='utf8')
 print(name,r.returncode,text[-200:],flush=True);assert r.returncode==0,name;e.check_log(text)
 assert source==e.capture(),'source changed during native run'
 (H/(name+'.manifest.json')).write_text(json.dumps(dict(source=source,files={ext:e.sha(H/(name+'.'+ext)) for ext in ['json','log','command.json']}),indent=2),encoding='utf8')
 return profile
if __name__=='__main__':
 for file in ['candidate_high.gd','candidate_route.gd','candidate_restart.gd']:shutil.copy2(H/file,e.COPY/'scripts/debug'/file)
 source=e.capture();(H/'preflight.json').write_text(json.dumps(source,indent=2),encoding='utf8')
 for b in BUILDS:
  name='high-'+b[0];output=H/(name+'.json')
  profile=execute(name,'candidate_high.gd',['--out='+str(output),'--build='+b[0],'--traits='+b[3],'--budget=5,6,6','--foundation='+str(H/'foundation.json')],b)
  d=json.loads(output.read_text());assert d['valid'] and d['foundation_parity'],name
  name+='-restart';output=H/(name+'.json')
  execute(name,'candidate_restart.gd',['high-final',str(output)],b,profile)
  assert json.loads(output.read_text())['passed'],name
