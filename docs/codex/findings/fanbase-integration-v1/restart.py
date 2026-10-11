from pathlib import Path
import os,subprocess,json,uuid
HERE=Path(__file__).resolve().parent
ROOT=HERE.parents[3]
profile=HERE/"profiles"/("restart-"+uuid.uuid4().hex[:8]);profile.mkdir(parents=True)
env=os.environ.copy();env.update(APPDATA=str(profile),LOCALAPPDATA=str(profile))
results=[]
for mode in ["launch","first","second","weak","weak_first","weak_second","later","inspect"]:
 command=[r"C:/Users/64jus/Downloads/Godot_v4.7.1-stable_win64.exe/Godot_v4.7.1-stable_win64_console.exe","--headless","--path",str(ROOT/"patch-notes"),"--script","res://scripts/debug/fanbase_restart_probe.gd","--",mode]
 r=subprocess.run(command,env=env,stdout=subprocess.PIPE,stderr=subprocess.STDOUT,timeout=90)
 output=r.stdout.decode("utf8",errors="replace")
 (HERE/("restart-final-"+mode+".log")).write_text(output,encoding="utf8")
 results.append(dict(mode=mode,command=command,exit_code=r.returncode))
 print(mode,r.returncode,output[-250:],flush=True)
 if r.returncode:break
(HERE/"restart-final.json").write_text(json.dumps(dict(profile=str(profile),processes=results),indent=2),encoding="utf8")
raise SystemExit(0 if len(results)==8 and all(x["exit_code"]==0 for x in results) else 1)
