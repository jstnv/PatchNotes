from run import *
sys.path.insert(0,str(ROOT/'tools'));import simulate as sim
records=[]
for row in load(HERE/'selection.json'):
    project=Path(row['original_bundle'])/'project';before=sim.source_hashes(project)
    folder=RAW/('cross-'+row['route']);folder.mkdir(exist_ok=False);env=sim.isolated_environment(folder/'profile')
    target=prefix_output(row['group'])/'cases'/('prefix-'+row['route'])
    r=load(target/'result.json');assert r['status']=='completed'
    args=[GODOT,'--headless','--path',str(project),'--script',str(HERE/'cross_prefix.gd'),'--','--original='+str(Path(row['original_bundle'])/'cases'/row['original_case']),'--candidate='+str(target),'--out='+str(folder/'result.json')]
    try:sim.run_process('cross',args,folder,env,240);ok=load(folder/'result.json')['ok']
    except Exception as e:ok=False;print(str(e))
    assert before==sim.source_hashes(project)
    records.append(dict(route=row['route'],ok=ok,receipt=str(folder/'result.json')));print(row['route'],ok,flush=True)
write(HERE/'cross-checks.json',records)
assert all(r['ok'] for r in records)
