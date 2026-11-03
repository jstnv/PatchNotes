from pathlib import Path
import argparse,subprocess,os,tempfile,json,hashlib,sys,socket,time
P=argparse.ArgumentParser();P.add_argument("--script",type=Path,required=True);P.add_argument("--out",type=Path,required=True);P.add_argument("--fixture",type=Path);P.add_argument("--native",action="store_true");P.add_argument("--size",default="1152x648");P.add_argument("--timeout",type=int,default=180);P.add_argument("--port",type=int,default=0);P.add_argument("--arg",action="append",default=[]);a=P.parse_args()
ROOT=Path.cwd();sys.path.insert(0,str(ROOT/"tools"));import simulate
out=a.out.resolve();out.mkdir(exist_ok=False,parents=True);project=ROOT/"patch-notes";script=a.script.resolve();sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest();before=simulate.source_hashes(project);harness={str(p):sha(p) for p in [script,Path(__file__).resolve()]};inputs={str(a.fixture.resolve()):sha(a.fixture)} if a.fixture else {}
viz=Path("C:/Users/64jus/.codex/visualizations/2026/10/07/01a11488-6601-7cf0-9b09-7fa2b3f5efdd");profile=Path(tempfile.mkdtemp(prefix="central-progression-",dir=viz));env=os.environ.copy()
for k in ["APPDATA","LOCALAPPDATA","TEMP","TMP","USERPROFILE"]:
 d=profile/k;d.mkdir();env[k]=str(d)
for port in ([a.port] if a.port else range(49300,49999)):
 with socket.socket() as probe:
  try:probe.bind(("127.0.0.1",port));break
  except OSError:continue
env.update({"PN_CHECKPOINT_TEST_PORT":str(port),"PN_CONTRACT_REPORT":str(out/"result.json"),"PN_CARD_FRAME_OUTPUT":str(out/"result.json"),"PN_FOCUS_TEST_DIRECTORY":str(out),"PN_FOCUS_SIZE":a.size})
if a.fixture:env["PN_CONTRACT_FIXTURE"]=str(a.fixture.resolve())
argv=["C:/Users/64jus/Downloads/Godot_v4.7.1-stable_win64.exe/Godot_v4.7.1-stable_win64.exe","--audio-driver","Dummy"]+([] if a.native else ["--headless"])+["--path",str(project),"--script",str(script)]
argv += ["--"]+a.arg if a.arg else []
start=time.monotonic();stop_reason=""
with (out/"godot.log").open("wb") as stream:
 with subprocess.Popen(argv,env=env,stdout=stream,stderr=subprocess.STDOUT,creationflags=subprocess.CREATE_NO_WINDOW) as process:
  (out/"process.json").write_text(json.dumps({"pid":process.pid,"private_profile":str(profile),"argv":argv}),encoding="utf-8")
  while process.poll() is None:
   log=(out/"godot.log").read_bytes().decode("utf-8",errors="replace")
   if "SCRIPT ERROR:" in log:stop_reason="script_error"
   elif time.monotonic()-start>a.timeout:stop_reason="timeout"
   if stop_reason:process.kill();break
   time.sleep(0.2)
  exit_code=process.wait()
log=(out/"godot.log").read_text(encoding="utf-8",errors="replace");r=subprocess.CompletedProcess(argv,124 if stop_reason=="timeout" else 1 if stop_reason else exit_code)
errors=[x for x in log.splitlines() if x.startswith(("ERROR:","SCRIPT ERROR:"))];expected=[]
if script.name=="verify_focused_onboarding.gd" and "EXPECTED_CORRUPT_FOCUSED_PREFERENCE" in log:
 expected=[x for x in errors if x.replace(chr(92),"/").startswith("ERROR: ConfigFile parse error at "+str(out/"preferences.cfg").replace(chr(92),"/"))]
 errors=[x for x in errors if x not in expected]
after=simulate.source_hashes(project);receipt={"argv":argv,"exit":r.returncode,"stop_reason":stop_reason,"seconds":time.monotonic()-start,"native":a.native,"private_profile":str(profile),"private_port":port,"source_unchanged":before==after,"harness_unchanged":harness=={str(p):sha(Path(p)) for p in harness},"fixture_unchanged":inputs=={p:sha(Path(p)) for p in inputs},"errors":errors,"expected_fixture_errors":expected};(out/"receipt.json").write_text(json.dumps(receipt,indent=2),encoding="utf-8");(out/"source-before.json").write_text(json.dumps(before,indent=2),encoding="utf-8");(out/"source-after.json").write_text(json.dumps(after,indent=2),encoding="utf-8");print(json.dumps(receipt));print(log[-2200:].encode("ascii",errors="backslashreplace").decode());sys.exit(r.returncode or int(bool(errors) or not all(receipt[k] for k in ["source_unchanged","harness_unchanged","fixture_unchanged"])))
