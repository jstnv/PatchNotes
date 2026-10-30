from run import *
sys.path.insert(0,str(ROOT/'tools'));import simulate as sim
records=[]
for row in load(HERE/'selection.json'):
 project=ACCESSRAW/row['pair']/'project';before=sim.source_hashes(project)
 folder=RAW/('cross-'+row['case']);folder.mkdir(exist_ok=False)
 env=sim.isolated_environment(folder/'profile')
 args=[GODOT,'--headless','--path',str(project),'--script',str(HERE/'cross_prefix.gd'),'--','--original='+str(ACCESSRAW/row['pair']/'cases'/row['case']),'--candidate='+str(RAW/'prefix/cases'/('prefix-'+row['case'])),'--out='+str(folder/'result.json')]
 try:sim.run_process('cross',args,folder,env,240);ok=True
 except Exception as e:ok=False;print(str(e))
 assert before==sim.source_hashes(project)
 records.append(dict(case=row['case'],ok=ok,receipt=str(folder/'result.json')));print(row['case'],ok,flush=True)
write(HERE/'cross-checks.json',records)
