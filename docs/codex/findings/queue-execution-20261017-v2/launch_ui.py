from pathlib import Path
import datetime,json,os,subprocess,sys

base=Path(__file__).resolve().parent
profile=sys.argv[1]
assert profile in ('long-ai','promotion','bank-age','education-new-bank')
manifest=json.loads((base/'acceptance-build-manifest.json').read_text())
exe=Path(manifest['workspace'])/'demo/Patch Notes Demo.exe'
env=os.environ.copy()
for key in ('APPDATA','LOCALAPPDATA'):
    directory=base/'profiles'/profile/key
    directory.mkdir(parents=True,exist_ok=True)
    env[key]=str(directory)
command=[str(exe),'--audio-driver','Dummy','--windowed']
record=dict(profile=profile,command=command,started_utc=datetime.datetime.now(datetime.timezone.utc).isoformat())
result=subprocess.run(command,env=env)
record.update(exit_code=result.returncode,finished_utc=datetime.datetime.now(datetime.timezone.utc).isoformat())
with (base/'ui-processes.jsonl').open('a',encoding='utf-8') as out:out.write(json.dumps(record)+'\n')
print(json.dumps(record))
sys.exit(result.returncode)
