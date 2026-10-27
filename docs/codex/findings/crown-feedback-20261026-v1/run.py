"""Private current-source Crown checks; no player profiles."""
from pathlib import Path
import importlib.util, json, os, socket, subprocess, sys, time
OUT=Path(__file__).resolve().parent
ROOT=OUT.parents[3]
PROJECT=ROOT/"docs/codex/threads/contracts/simulators/crown-feedback-20261026-v1/project"
spec=importlib.util.spec_from_file_location("sim", ROOT/"tools/simulate.py")
sim=importlib.util.module_from_spec(spec);spec.loader.exec_module(sim)
label,script,*args=sys.argv[1:]
assert not (OUT/(label+"-run.json")).exists()
env=sim.isolated_environment(ROOT/".codex-godot-temp"/("crown-feedback-"+label))
env["PN_CARD_FRAME_OUTPUT"]=str(OUT/(label+".json"))
env["PN_CROWN_OUTPUT"]=str(OUT)
artifacts=OUT/(label+"-artifacts")
artifacts.mkdir(exist_ok=False)
env["PN_CROWN_RESULTS"]=str(artifacts)
with socket.socket() as sock:
 sock.bind(("127.0.0.1",0));env["PN_CHECKPOINT_TEST_PORT"]=str(sock.getsockname()[1])
native="--native" in args
pack=next((a.removeprefix("--pack=") for a in args if a.startswith("--pack=")),None)
args=[a for a in args if a!="--native"]
args=[a for a in args if not a.startswith("--pack=")]
command=[r"C:/Users/64jus/Downloads/Godot_v4.7.1-stable_win64.exe/Godot_v4.7.1-stable_win64_console.exe","--path",str(PROJECT),"--audio-driver","Dummy"]
if not native:command+=["--headless"]
else:command+=["--rendering-method","gl_compatibility","--resolution","1152x648","--position","80,80"]
if pack:command+=["--main-pack",pack]
if script=="import":command+=["--editor","--import"]
else:command+=["--script",script]
if args:command+=["--"]+args
start=time.monotonic()
source_before=sim.source_hashes(PROJECT)
with (OUT/(label+".log")).open("xb") as f:
 try:code=subprocess.run(command,env=env,stdout=f,stderr=subprocess.STDOUT,timeout=240).returncode
 except subprocess.TimeoutExpired:code=124
lines=(OUT/(label+".log")).read_text(encoding="utf-8",errors="replace").splitlines()
errors=[l for l in lines if any(x in l for x in ["SCRIPT ERROR","Parse Error","ERROR:","FAIL:"])]
result={"command":command,"exit":code,"seconds":round(time.monotonic()-start,3),"errors":errors,"tail":lines[-15:]}
source_after=sim.source_hashes(PROJECT)
result["candidate_source_unchanged"]=source_before==source_after
result["source_manifest"]=source_before
(OUT/(label+"-run.json")).write_text(json.dumps(result,indent=2)+"\n")
print(json.dumps(result),flush=True)
raise SystemExit(1 if errors else code)
