from pathlib import Path
import importlib.util, json, shutil, zipfile
ROOT=Path(__file__).resolve().parents[4];HERE=Path(__file__).resolve().parent
spec=importlib.util.spec_from_file_location('sim',ROOT/'tools/simulate.py')
sim=importlib.util.module_from_spec(spec);spec.loader.exec_module(sim)
GODOT=Path('C:/Users/64jus/Downloads/Godot_v4.7.1-stable_win64.exe/Godot_v4.7.1-stable_win64_console.exe')
old=HERE/'old-project-03';new=HERE/'new-project-02'
sim.copy_snapshot(HERE/'old-project-02',old)
sim.copy_snapshot(ROOT/'patch-notes',new)
sim.write_json(HERE/'restart-v2-canonical-before.json',sim.source_hashes(ROOT/'patch-notes'))
for label,project in [('old',old),('new',new)]:
    shutil.copy2(HERE/'restart_probe_v2.gd',project/'scripts/debug/cult20_restart_probe_v2.gd')
    folder=HERE/(label+'-import-02');folder.mkdir()
    sim.import_project(GODOT,project,folder,sim.isolated_environment(folder/'profile'),240)
records=[]
def process(project,folder,mode,config):
    env=sim.isolated_environment(folder/'profile')
    env.update(PN_CULT20_MODE=mode,PN_CULT20_CONFIG=json.dumps(config),PN_CULT20_OUTPUT=str(folder/(mode+'.json')))
    command=[str(GODOT),'--headless','--path',str(project),'--script','res://scripts/debug/cult20_restart_probe_v2.gd']
    frozen=sim.source_hashes(project)
    sim.run_process(mode,command,folder,env,90)
    sim.check_snapshot(project,frozen)
    result=sim.read_json(folder/(mode+'.json'));assert result['ok'],result
    records.append({'folder':folder.name,'mode':mode,'project':str(project),'checks':result['checks'],'commands':result['commands']})
    print(folder.name,mode,'PASS',flush=True)
cases=[]
for label,traits,releases in [('control',[],2),('cult-creation',['cult_following'],0),('cult-launch',['cult_following'],1),('cult-months',['cult_following'],2),('cult-buzz',['cult_following','studio_buzz'],2),('cult-graduate',['cult_following','graduate'],2)]:
    cases.append({'id':label,'traits':traits,'releases':releases})
for era,writer,version,seed in [('old',old,7,40),('new',new,8,20)]:
    for case in cases:
        config=dict(case,version=version,seed_fans=seed if 'cult_following' in case['traits'] else 0)
        folder=HERE/(era+'-restart-'+case['id']+'-v2');folder.mkdir()
        process(writer,folder,'write',config)
        process(new,folder,'read',config)
        if era=='old' and case['id']=='cult-months':
            process(new,folder,'upgrade',config);process(new,folder,'read-upgraded',config)
for version in [3,4,5,6]:
    config={'id':'historical-'+str(version),'historical_version':version,'version':version,'seed_fans':0}
    folder=HERE/('old-inactive-'+str(version)+'-v2');folder.mkdir()
    process(old,folder,'write',config);process(new,folder,'read',config)
before=sim.read_json(HERE/'restart-v2-canonical-before.json');sim.check_snapshot(ROOT/'patch-notes',before)
sim.write_json(HERE/'restart-summary.json',{'ok':True,'processes':len(records),'checks':sum(r['checks'] for r in records),'records':records,'canonical_unchanged':True,'source':before})
print('Restart processes:',len(records),'checks:',sum(r['checks'] for r in records))
