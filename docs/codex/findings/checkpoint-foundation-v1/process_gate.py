from pathlib import Path
import json,os,subprocess,tempfile,time
import run_checks as v
v.PROFILE.mkdir(parents=True,exist_ok=True)
workspace=Path(tempfile.mkdtemp(prefix='process-',dir=v.PROFILE));slot=workspace/'slot';env=os.environ.copy()
for key in ['APPDATA','LOCALAPPDATA']:
 p=workspace/key;p.mkdir();env[key]=str(p)
results=[]
def execute(mode,hold=False):
 out=workspace/(str(len(results))+'-'+mode+'.json');log=v.HERE/('process-'+str(len(results))+'-'+mode+'.log')
 cmd=[v.GODOT,'--headless','--path',str(v.PROJECT),'--script','res://scripts/debug/checkpoint_store_process_probe.gd','--',mode,str(slot),str(out)]
 stream=log.open('wb');p=subprocess.Popen(cmd,env=env,stdout=stream,stderr=subprocess.STDOUT)
 deadline=time.monotonic()+20
 while not out.exists() and p.poll() is None and time.monotonic()<deadline:time.sleep(.05)
 if not out.exists():
  p.kill();p.wait();stream.close();raise RuntimeError('Probe did not report: '+str(log))
 record=json.loads(out.read_text());results.append(dict(command=cmd,result=record))
 if hold:return p,stream,record
 p.wait(timeout=20);stream.close();assert p.returncode==0;return record
try:
 holder,stream,r=execute('hold',True);assert r['acquired']
 assert execute('save')['status']=='writer_busy'
 holder.kill();holder.wait();stream.close()
 assert execute('save')['sequence']==1
 p,stream,r=execute('flush',True);assert r['status']=='io_error'
 p.kill();p.wait();stream.close()
 assert execute('read')['sequence']==1
 p,stream,r=execute('publish_hold',True);assert r['sequence']==2
 p.kill();p.wait();stream.close()
 restored=execute('read');assert restored['sequence']==2 and restored['payload']['cash']=='9007199254740993'
 assert len(list(slot.glob('checkpoint.*.json')))==2
 assert list(slot.glob('*.tmp'))
 result=dict(passed=True,workspace=str(workspace),cases=results)
 (v.HERE/'process-gate.json').write_text(json.dumps(result,indent=2));print('Separate-process store gate PASS',len(results),'executions')
finally:
 for label in ['holder','p']:
  proc=locals().get(label)
  if proc is not None and proc.poll() is None:proc.kill();proc.wait()
