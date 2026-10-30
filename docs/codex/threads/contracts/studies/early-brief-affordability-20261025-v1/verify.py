from run import *
sys.path.insert(0,str(ROOT/'tools'));import simulate as sim
a=load(HERE/'analysis.json');assert len(a['rows'])==12 and len(a['prefixes'])==6
lowest=min(a['prefixes'],key=lambda p:(p['cash_cents'],p['route']))
first_skip=min((r for r in a['rows'] if r['arm']=='skip'),key=lambda r:r['case'])
mean=next(r for r in a['rows'] if r['case']=='mean-'+lowest['route'])
failure=next((r for r in sorted(a['rows'],key=lambda r:r['case']) if r['rejection']),None)
selected=[mean,first_skip]
if failure and failure['case'] not in [r['case'] for r in selected]:selected.append(failure)
write(HERE/'verification-selection.json',dict(lowest_prefix=lowest,replays=[r['case'] for r in selected],reduction=failure['case'] if failure else None))
for r in selected:
    execute('replay-'+r['case'],[sys.executable,'tools/simulate.py','replay','--bundle',str(RAW/('branches-'+r['group'])),'--case',r['case'],'--output',str(RAW/('replay-'+r['case'])),'--timeout','240','--godot',GODOT])
if failure:execute('reduce-'+failure['case'],[sys.executable,'tools/reduce_simulation.py','--bundle',str(RAW/('branches-'+failure['group'])),'--case',failure['case'],'--kind','rejection','--max-commands','500','--output',str(RAW/('reduce-'+failure['case'])),'--timeout','240','--godot',GODOT])
# Existing structural probe on the lowest-liquidity earned start; private profile only.
project=prefix_output(lowest['group'])/'project';before=sim.source_hashes(project);folder=RAW/'structural';folder.mkdir(exist_ok=False)
args=[GODOT,'--headless','--path',str(project),'--script','res://scripts/debug/crown_search_probe.gd','--','--checkpoint='+str(prefix_output(lowest['group'])/'cases'/('prefix-'+lowest['route'])/'studio_checkpoint.json'),'--out='+str(folder/'receipt.json')]
try:sim.run_process('structural',args,folder,sim.isolated_environment(folder/'profile'),180);ok=True
except Exception as e:ok=False;print(str(e))
assert before==sim.source_hashes(project);write(HERE/'structural.json',dict(ok=ok,route=lowest['route'],receipt=str(folder/'receipt.json')))
success=next((r for r in sorted(a['rows'],key=lambda r:r['case']) if r['arm']=='mean' and r['status']=='completed'),None)
if success:
    c=copy.deepcopy(next(c for c in load(HERE/('branches-'+success['group']+'.json'))['cases'] if c['case_id']==success['case']))
    c['initial']={'checkpoint':load(RAW/('branches-'+success['group'])/'cases'/success['case']/'studio_checkpoint.json')};c['case_id']='early-brief-cold';c['target_release_count']=success['final_releases']+1;c['max_commands']=100;c['policy']['config'].update(arm='skip',label='early-brief-cold',starting_reputation=success['reputation_bp']);c.pop('study',None)
    write(HERE/'cold-source.json',success);write(HERE/'cold.json',dict(schema_version='1',policy=dict(script='policy.gd',id='crown-public-mean256-early',version='1'),cases=[c]));run('cold','240')
