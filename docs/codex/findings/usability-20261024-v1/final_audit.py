"""Final immutable source: current/previous saves, independent cold reader, native UI."""
from work import ROOT,HOME,GODOT,sim
from pathlib import Path
import json,shutil,subprocess,time

out=HOME/'final-audit-v1';out.mkdir(exist_ok=False)
source=sim.copy_snapshot(ROOT/'patch-notes',out/'project')
sim.write_json(out/'source.json',source)
frozen=sim.import_project(GODOT,out/'project',out,sim.isolated_environment(out/'import-profile'),180)
report={'checks':[],'pass':False,'release_ready':False}
jobs=[('persistence','res://scripts/debug/verify_usability_persistence.gd',False,[]),
      ('cold','res://scripts/debug/verify_usability_persistence.gd',False,['--input='+str(out/'persistence/current-save.json')]),
      ('review','review_cases.gd',False,[]),('native','native.gd',True,[])]
for name,script,native,extra in jobs:
    folder=out/name;folder.mkdir()
    if not script.startswith('res://'):
        original=Path(__file__).parent/script;harness=folder/'harness.gd';shutil.copy2(original,harness);script=str(harness)
        sim.write_json(folder/'harness-source.json',{'original':str(original),'sha256':sim.sha(harness)})
    env=sim.isolated_environment(folder/'profile');env['PN_CHECKPOINT_TEST_PORT']='47734'
    env['PN_USABILITY_PREVIOUS_ROOT']='C:/Users/64jus/AppData/Local/Temp/pn-p4-execution-20261024-v1'
    cmd=[str(GODOT),'--path',str(out/'project')]+([] if native else ['--headless'])+['--script',script,'--','--out='+str(folder)]+extra
    log=folder/'run.log'
    with log.open('w',encoding='utf8') as stream:
        child=subprocess.Popen(cmd,cwd=folder,env=env,stdout=stream,stderr=subprocess.STDOUT);started=time.monotonic()
        while child.poll() is None:
            if time.monotonic()-started>180 or 'SCRIPT ERROR' in log.read_text(encoding='utf8',errors='replace'):child.kill();break
            time.sleep(.25)
        child.wait()
    lines=log.read_text(encoding='utf8',errors='replace').splitlines()
    errors=[line for line in lines if 'SCRIPT ERROR' in line or line.startswith('ERROR:') or 'FAIL:' in line]
    row={'name':name,'command':cmd,'exit':child.returncode,'errors':errors,'pass':child.returncode==0 and not errors}
    report['checks'].append(row);sim.write_json(out/'result.json',report);print(json.dumps(row),flush=True)
sim.check_snapshot(out/'project',frozen)
report['canonical_unchanged']=sim.source_hashes(ROOT/'patch-notes')==source
report['pass']=all(row['pass'] for row in report['checks']) and report['canonical_unchanged']
sim.write_json(out/'result.json',report)
print(json.dumps({'pass':report['pass'],'canonical_unchanged':report['canonical_unchanged']}),flush=True)
raise SystemExit(0 if report['pass'] else 1)
