from pathlib import Path
import json, os, subprocess

OUT=Path(__file__).resolve().parent
RUN=OUT/'world-process-v2'
RUN.mkdir(exist_ok=False)
GODOT=Path('C:/Users/64jus/Downloads/Godot_v4.7.1-stable_win64.exe/Godot_v4.7.1-stable_win64_console.exe')
profile=RUN/'profile'
env=os.environ.copy()
for key in ('APPDATA','LOCALAPPDATA'):
    path=profile/key
    path.mkdir(parents=True,exist_ok=True)
    env[key]=str(path)
results=[]
for mode in ('seed','rollback','restore','continue'):
    env['PN_ACCEPT_MODE']=mode
    command=[str(GODOT),'--headless','--path',str(OUT/'snapshot/patch-notes'),'--script',str(OUT/'world_process_probe.gd')]
    process=subprocess.run(command,env=env,capture_output=True,timeout=100)
    output=(process.stdout+process.stderr).decode(errors='replace')
    (RUN/('world-'+mode+'.log')).write_text(output)
    errors=[line for line in output.splitlines() if 'ERROR:' in line or 'SCRIPT ERROR' in line]
    record={'mode':mode,'command':command,'exit':process.returncode,'errors':errors,'summary':[line for line in output.splitlines() if line.startswith('REFRESHED_WORLD_PROCESS')]}
    results.append(record)
    (RUN/'world-process-results.json').write_text(json.dumps(results,indent=2)+'\n')
    print(json.dumps(record),flush=True)
    if process.returncode or errors: raise SystemExit(1)
