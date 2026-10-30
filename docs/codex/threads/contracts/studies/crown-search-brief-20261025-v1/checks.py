from run import *
sys.path.insert(0,str(ROOT/'tools'));import simulate as sim
project=RAW/'prefix/project'
before=sim.source_hashes(project)
out=RAW/'checks';out.mkdir(exist_ok=False)
records=[]
for name in ['verify_contract_challenge_runtime','verify_publisher_relationships','verify_contract_search','crown_search_probe']:
 folder=out/name;folder.mkdir();env=sim.isolated_environment(folder/'profile')
 args=[GODOT,'--headless','--path',str(project),'--script','res://scripts/debug/'+name+'.gd']
 if name=='crown_search_probe':
  case=load(HERE/'prefix.json')['cases'][0]['case_id']
  args+=['--','--checkpoint='+str(RAW/'prefix/cases'/case/'studio_checkpoint.json'),'--out='+str(folder/'receipt.json')]
 try:
  result=sim.run_process('check',args,folder,env,180);record=dict(suite=name,ok=True,result=result)
 except Exception as e:record=dict(suite=name,ok=False,error=str(e))
 records.append(record);print(name,record['ok'],flush=True)
assert before==sim.source_hashes(project)
write(HERE/'checks.json',dict(source_unchanged=True,checks=records))
