"""Frozen-source checks with independent short profiles and retained failures."""
from pathlib import Path
import datetime, hashlib, importlib.util, json, os, shutil, socket, subprocess, sys

ROOT = Path(__file__).resolve().parents[4]
BASE = Path(__file__).resolve().parent
GODOT = r'C:\Users\64jus\Downloads\Godot_v4.7.1-stable_win64.exe\Godot_v4.7.1-stable_win64_console.exe'
spec = importlib.util.spec_from_file_location('simulate', ROOT/'tools/simulate.py')
sim = importlib.util.module_from_spec(spec); spec.loader.exec_module(sim)
out = BASE/sys.argv[1]
out.mkdir(exist_ok=False)
project = out/'project'
pin = {}
for name, source in sim.source_files(ROOT/'patch-notes').items():
    target=project/name;target.parent.mkdir(parents=True,exist_ok=True)
    shutil.copy2(source,target);pin[name]=sim.sha(target)
sim.write_json(out/'source.json', pin)
for source in (ROOT/'docs/codex/findings/education-legacy-fixtures-v1').glob('*.json'):
    target=out/source.relative_to(ROOT);target.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(source,target)
# Maintained parity suites load their frozen pre-extraction oracle beside res://.
for source in (ROOT/'docs/codex/threads/simulation-engine').rglob('*oracle.gd'):
    target=out/source.relative_to(ROOT);target.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(source,target)
records=[]
for index,name in enumerate(['import',*sys.argv[2:]]):
    profile=ROOT/'.codex-godot-temp'/('qv2-'+out.name+'-'+str(index))
    env=os.environ.copy()
    env['PN_CARD_FRAME_OUTPUT']=str(out/(name+'-result.json'))
    with socket.socket() as probe:
        probe.bind(('127.0.0.1',0));env['PN_CHECKPOINT_TEST_PORT']=str(probe.getsockname()[1])
    for key in ('APPDATA','LOCALAPPDATA'):
        path=profile/key;path.mkdir(parents=True,exist_ok=True);env[key]=str(path)
    args=['--editor','--import','--quit'] if name=='import' else ['--script','res://scripts/debug/'+name+'.gd']
    command=[GODOT,'--headless','--audio-driver','Dummy','--path',str(project),*args]
    with (out/(name+'.log')).open('wb') as log:
        try: result=subprocess.run(command,env=env,stdout=log,stderr=subprocess.STDOUT,timeout=1200 if name=='verify_sidestreet_calendar_parity' else 240);code=result.returncode
        except subprocess.TimeoutExpired: code='TIMEOUT'
    text=(out/(name+'.log')).read_text(errors='replace')
    errors=[line for line in text.splitlines() if ('SCRIPT ERROR' in line or line.startswith('ERROR:') or 'FAIL:' in line) and 'root certificate store' not in line]
    record=dict(name=name,exit=code,errors=errors,passes=text.count('PASS:'),command=command,profile=str(profile),utc=datetime.datetime.now(datetime.timezone.utc).isoformat())
    records.append(record);sim.write_json(out/'results.json',records)
    print(name,code,len(errors),'errors',record['passes'],'assertions',flush=True)
    if name=='import' and (code or errors):break
sys.exit(any(row['exit'] or row['errors'] for row in records))
