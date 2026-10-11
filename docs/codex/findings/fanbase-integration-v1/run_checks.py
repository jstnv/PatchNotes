from pathlib import Path
import os,sys,subprocess,json,time
sys.stdout.reconfigure(encoding="utf8",errors="replace")
HERE=Path(__file__).resolve().parent
ROOT=HERE.parents[3]
GODOT=Path(r"C:/Users/64jus/Downloads/Godot_v4.7.1-stable_win64.exe/Godot_v4.7.1-stable_win64_console.exe")
for name in sys.argv[1:]:
 profile=HERE/"profiles"/name
 profile.mkdir(parents=True,exist_ok=True)
 env=os.environ.copy();env.update(APPDATA=str(profile),LOCALAPPDATA=str(profile),PN_CHECKPOINT_TEST_PORT="47842")
 args=[str(GODOT),"--headless","--path",str(ROOT/"patch-notes")]
 if name=="import":args += ["--editor","--import","--quit"]
 else:args += ["--script","res://scripts/debug/"+name+".gd"]
 start=time.time()
 try:
  result=subprocess.run(args,env=env,stdout=subprocess.PIPE,stderr=subprocess.STDOUT,timeout=240)
  output=result.stdout.decode("utf8",errors="replace");code=result.returncode
 except subprocess.TimeoutExpired as e:output=(e.stdout or b"").decode("utf8",errors="replace");code=124
 (HERE/(name+".log")).write_text(output,encoding="utf8")
 (HERE/(name+".command.json")).write_text(json.dumps({"command":args,"exit_code":code,"seconds":time.time()-start,"profile":str(profile)},indent=2),encoding="utf8")
 print(name,code,output[-1800:],flush=True)
 if code:sys.exit(code)
