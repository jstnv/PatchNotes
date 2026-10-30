from run import *
sys.path.insert(0,str(ROOT/'tools'))
import simulate as sim
project=RAW/'prefix/project'
before=sim.source_hashes(project)
out=RAW/'focused-checks';out.mkdir()
records=[]
for name in ['verify_contract_challenge_runtime','verify_contract_challenge_matrix','verify_publisher_relationships']:
    folder=out/name;folder.mkdir()
    env=sim.isolated_environment(folder/'profile')
    args=[GODOT,'--headless','--path',str(project),'--script','res://scripts/debug/'+name+'.gd']
    try:
        result=sim.run_process('check',args,folder,env,120)
        record=dict(suite=name,ok=True,result=result)
    except Exception as e:record=dict(suite=name,ok=False,error=str(e))
    records.append(record);print(name+' '+str(record['ok']),flush=True)
assert before==sim.source_hashes(project),'frozen source changed'
write(HERE/'focused-checks.json',dict(source_unchanged=True,suites=records))
