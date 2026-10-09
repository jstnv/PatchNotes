from pathlib import Path
import json,os,subprocess,time,shutil
H=Path(__file__).resolve().parent
m=json.loads((H/'startup-fault-results.json').read_text());w=Path(m['workspace']);project=w/'project'
shutil.copy2(H/'writer_lease_probe.gd',project/'scripts/debug/writer_lease_probe.gd')
env=os.environ.copy()
for k in ['APPDATA','LOCALAPPDATA']:env[k]=str(w/k)
godot=r'C:/Users/64jus/Downloads/Godot_v4.7.1-stable_win64.exe/Godot_v4.7.1-stable_win64_console.exe'
directory=w/'lease-fixture';ready=w/'lease-ready';args=[godot,'--headless','--path',str(project),'--script','res://scripts/debug/writer_lease_probe.gd','--']
hold=args+['hold',str(directory),str(ready)]
with (H/'lease-owner.log').open('wb') as log:
 owner=subprocess.Popen(hold,env=env,stdout=log,stderr=subprocess.STDOUT)
 try:
  deadline=time.monotonic()+15
  while not ready.exists() and owner.poll() is None and time.monotonic()<deadline:time.sleep(.1)
  if not ready.exists():raise RuntimeError('Owner unavailable; see lease-owner.log')
  p=subprocess.run(args+['contend',str(directory)],env=env,capture_output=True,timeout=20)
  (H/'lease-contender.log').write_bytes(p.stdout+p.stderr)
  assert p.returncode==0 and not directory.exists()
 finally:
  if owner.poll() is None:owner.terminate();owner.wait(timeout=10)
p=subprocess.run(args+['acquire',str(directory)],env=env,capture_output=True,timeout=20)
(H/'lease-reacquire.log').write_bytes(p.stdout+p.stderr)
assert p.returncode==0 and len(list(directory.glob('*.json')))==1
(H/'lease-results.json').write_text(json.dumps(dict(owner_command=hold,contender_command=args+['contend',str(directory)],reacquire_command=args+['acquire',str(directory)],contender_exit=0,reacquire_exit=0,physical_processes=3,blocked_write_created_no_directory=True),indent=2))
print('PASS separate-process production lease rejects second writer; OS releases after owner termination')
