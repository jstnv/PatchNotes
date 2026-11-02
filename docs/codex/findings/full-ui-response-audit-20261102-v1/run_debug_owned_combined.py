from pathlib import Path
import os,json,hashlib,subprocess,sys,tempfile
ROOT=Path.cwd(); B=ROOT/"docs/codex/findings/full-ui-response-audit-20261102-v1"; OUT=B/"combined-debug-owned-final-v1"; OUT.mkdir(exist_ok=False)
PYTOOLS=ROOT/"tools";sys.path.insert(0,str(PYTOOLS));import simulate
project=ROOT/"patch-notes"; source=simulate.source_hashes(project)
script=ROOT/"patch-notes/scripts/debug/verify_debug_owned_engine.gd";fixture=ROOT/"patch-notes/scripts/debug/fixtures/debug_owned_normal_predecessor_20261102.json"
sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
fences={str(p):sha(p) for p in [script,fixture,Path(__file__)]}
VIZ=Path("C:/Users/64jus/.codex/visualizations/2026/10/07/01a11488-6601-7cf0-9b09-7fa2b3f5efdd");profile=Path(tempfile.mkdtemp(prefix="commission-cold-",dir=VIZ));env=os.environ.copy()
for key in ["APPDATA","LOCALAPPDATA","TEMP","TMP"]:
 target=profile/key;target.mkdir();env[key]=str(target)
env["PN_CARD_FRAME_OUTPUT"]=str(OUT/"report.json");env["PN_CHECKPOINT_TEST_PORT"]="49962"
argv=["C:/Users/64jus/Downloads/Godot_v4.7.1-stable_win64.exe/Godot_v4.7.1-stable_win64.exe","--headless","--audio-driver","Dummy","--path",str(project),"--script",str(script),"--"]
result=subprocess.run(argv,env=env,stdout=subprocess.PIPE,stderr=subprocess.STDOUT,timeout=120,creationflags=subprocess.CREATE_NO_WINDOW);log=result.stdout.decode("utf-8",errors="replace");(OUT/"godot.log").write_text(log,encoding="utf-8")
receipt={"argv":argv,"exit":result.returncode,"source_unchanged":source==simulate.source_hashes(project),"harness_fixture_unchanged":fences=={str(p):sha(p) for p in [script,fixture,Path(__file__)]},"fences":fences,"profile":str(profile),"errors":[line for line in log.splitlines() if line.startswith(("ERROR:","SCRIPT ERROR:"))]};(OUT/"receipt.json").write_text(json.dumps(receipt,indent=2),encoding="utf-8");(OUT/"source.json").write_text(json.dumps(source,indent=2),encoding="utf-8");print(log[-1800:]);print(json.dumps(receipt));sys.exit(result.returncode or int(not receipt["source_unchanged"] or not receipt["harness_fixture_unchanged"] or bool(receipt["errors"])))
