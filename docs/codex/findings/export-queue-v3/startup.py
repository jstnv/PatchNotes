from pathlib import Path
import json,os,subprocess,shutil,tempfile,hashlib
h=Path(__file__).resolve().parent;m=json.loads((h/"build-manifest.json").read_text());w=Path(m["workspace"])
env=os.environ.copy(); profile=Path(tempfile.mkdtemp(prefix="startup-",dir=w))
for k in ["APPDATA","LOCALAPPDATA"]:
 d=profile/k;d.mkdir();env[k]=str(d)
results=[]
for name,args in [("headless-start",["--headless"]),("graphical-start",["--rendering-method","gl_compatibility"])]:
 command=[str(w/"demo/Patch Notes Demo.exe"),*args,"--quit-after","60"]
 with (h/(name+".log")).open("wb") as f:p=subprocess.run(command,env=env,stdout=f,stderr=subprocess.STDOUT,timeout=60)
 text=(h/(name+".log")).read_text(errors="replace")
 errors=[x for x in text.splitlines() if ("SCRIPT ERROR" in x or x.startswith("ERROR:")) and "root certificate store" not in x]
 result=dict(command=command,exit=p.returncode,errors=errors,profile=str(profile));results.append(result)
 (h/(name+".command.json")).write_text(json.dumps(result,indent=2));print(name,p.returncode,errors)
 assert p.returncode==0 and not errors
out=Path(r"C:\Users\64jus\Downloads\Patch Notes Design Folder\Builds\2026-10-08-queue-7c3e92d9")
out.mkdir(parents=True,exist_ok=True)
for name,entry in m["artifacts"].items():
 target=out/name
 if target.exists():assert hashlib.sha256(target.read_bytes()).hexdigest()==entry["sha256"]
 else:shutil.copy2(w/"demo"/name,target)
 assert hashlib.sha256(target.read_bytes()).hexdigest()==entry["sha256"]
(h/"delivery.json").write_text(json.dumps(dict(directory=str(out),artifacts=m["artifacts"],status="startup/package verified; interactive playthrough pending"),indent=2))
print(out)

