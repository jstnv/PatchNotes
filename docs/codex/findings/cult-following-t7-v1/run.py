from pathlib import Path
import os,json,subprocess,sys,shutil,hashlib,uuid
import provenance
sys.stdout.reconfigure(encoding='utf8',errors='replace')
HERE=Path(__file__).resolve().parent
COPY=Path(r'C:/Users/64jus/Downloads/Patch Notes Design Folder/cult-t7-v1-candidate-copy')
GODOT=r'C:/Users/64jus/Downloads/Godot_v4.7.1-stable_win64.exe/Godot_v4.7.1-stable_win64_console.exe'
BUILDS=[('none',0,0,''),('cult40p1',40,1,'cult_following'),('cult80p1',80,1,'cult_following'),('cult80p2',80,2,'cult_following'),('cult160p2',160,2,'cult_following'),('buzz',0,0,'studio_buzz'),('lean',0,0,'lean_production'),('family',0,0,'family_funding'),('cult80p1-buzz',80,1,'cult_following,studio_buzz'),('buzz-lean',0,0,'studio_buzz,lean_production')]
def execute(name,args,build,profile=None):
 profile=profile or HERE/'profiles'/(name+'-'+uuid.uuid4().hex[:8]);profile.mkdir(parents=True,exist_ok=True)
 env=os.environ.copy();env.update(APPDATA=str(profile),LOCALAPPDATA=str(profile),PN_CULT_SEED=str(build[1]),PN_CULT_PRICE=str(build[2]))
 command=[GODOT,'--headless','--path',str(COPY)]+args
 driver=next((Path(a).name for a in args if a.startswith('res://scripts/debug/candidate_')),'candidate_route.gd')
 source=provenance.capture(driver)
 result=subprocess.run(command,env=env,stdout=subprocess.PIPE,stderr=subprocess.STDOUT,timeout=240)
 text=result.stdout.decode('utf8',errors='replace');(HERE/(name+'.log')).write_text(text,encoding='utf8')
 (HERE/(name+'.command.json')).write_text(json.dumps(dict(command=command,exit_code=result.returncode,profile=str(profile),candidate_seed=build[1],candidate_price=build[2]),indent=2),encoding='utf8')
 print(name,result.returncode,text[-200:],flush=True)
 if result.returncode or "SCRIPT ERROR:" in text:raise RuntimeError(name)
 provenance.validate_log(text)
 assert source==provenance.capture(source['driver']),'source changed during process'
 if (HERE/(name+'.json')).exists():provenance.write_result(name,source)
 return profile
def route(name,build,seed,budget='3,4,4',search=False):
 output=HERE/(name+'.json')
 args=['--script','res://scripts/debug/candidate_route.gd','--','--out='+str(output),'--build='+build[0],'--traits='+build[3],'--seed='+str(seed),'--budget='+budget,'--search='+str(int(search))]
 if output.exists():
  provenance.validate(name,provenance.capture('candidate_route.gd'),[GODOT,'--headless','--path',str(COPY)]+args,build)
  info=json.loads((HERE/(name+'.command.json')).read_text(encoding='utf8'));assert info['exit_code']==0
  profile=Path(info['profile']);print('Preserving completed route',name,flush=True)
 else:profile=execute(name,args,build)
 data=json.loads(output.read_text(encoding='utf8'))
 if not data['valid']:raise RuntimeError('Invalid native route '+name)
 if not search:
  for label in ['initial','final']:
   result=HERE/(name+'-restart-'+label+'.json')
   args=['--script','res://scripts/debug/candidate_restart.gd','--',label,str(result)]
   if result.exists():
    assert json.loads(result.read_text(encoding='utf8'))['passed']
    provenance.validate(name+'-restart-'+label,provenance.capture('candidate_restart.gd'),[GODOT,'--headless','--path',str(COPY)]+args,build)
   else:execute(name+'-restart-'+label,args,build,profile)
 return data
for script in ['candidate_route.gd','candidate_restart.gd']:shutil.copy2(HERE/script,COPY/'scripts/debug'/script)
if 'import' in sys.argv:execute('import',['--editor','--import','--quit'],BUILDS[0])
if 'routes' in sys.argv:
 for seed in [1104,4417]:
  for build in BUILDS:route(f'route-{seed}-{build[0]}',build,seed)
if 'neutral' in sys.argv:
 found=None;attempts=[]
 for seed in [1104,2208,3312,4417]:
  for budget in ['3,4,4','3,3,4']:
   name=f'neutral-{seed}-{budget.replace(",","")}';data=route(name,BUILDS[0],seed,budget,True)
   score=data['releases'][0]['final_review'];attempts.append(dict(name=name,seed=seed,budget=budget,review=score))
   if score==5.0:found=attempts[-1];break
  if found:break
 (HERE/'neutral-search.json').write_text(json.dumps(dict(found=found,attempts=attempts),indent=2),encoding='utf8')
 if found:
  for build in BUILDS:route('neutral-matched-'+build[0],build,found['seed'],found['budget'],True)
if 'continue-neutral' in sys.argv:
 shutil.copy2(HERE/'candidate_neutral_continue.gd',COPY/'scripts/debug/candidate_neutral_continue.gd')
 found=json.loads((HERE/'neutral-search.json').read_text(encoding='utf8'))['found'];assert found
 for build in BUILDS:
  original='neutral-matched-'+build[0];name='neutral-earned-'+build[0];output=HERE/(name+'.json')
  route(original,build,found['seed'],found['budget'],True)
  args=['--script','res://scripts/debug/candidate_neutral_continue.gd','--','--out='+str(output)]
  if output.exists():
   provenance.validate(name,provenance.capture('candidate_neutral_continue.gd'),[GODOT,'--headless','--path',str(COPY)]+args,build)
   profile=Path(json.loads((HERE/(name+'.command.json')).read_text(encoding='utf8'))['profile'])
  else:
   info=json.loads((HERE/(original+'.command.json')).read_text(encoding='utf8'))
   profile=HERE/'profiles'/(name+'-'+uuid.uuid4().hex[:8]);shutil.copytree(info['profile'],profile)
   execute(name,args,build,profile)
  data=json.loads(output.read_text(encoding='utf8'));assert data['valid'] and data['foundation_exact']
  assert data['foundation']==json.loads((HERE/(original+'.json')).read_text(encoding='utf8'))['checkpoint']
  result=HERE/(name+'-restart.json');args=['--script','res://scripts/debug/candidate_restart.gd','--','neutral-earned',str(result)]
  if result.exists():provenance.validate(name+'-restart',provenance.capture('candidate_restart.gd'),[GODOT,'--headless','--path',str(COPY)]+args,build)
  else:execute(name+'-restart',args,build,profile)
  assert json.loads(result.read_text(encoding='utf8'))['passed']
