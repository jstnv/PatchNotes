"""Bounded store-era presentation checks using private profiles and writer ports."""
from pathlib import Path
import importlib.util
import hashlib
import json
import socket
import subprocess
import sys
import time

OUT = Path(__file__).resolve().parent
ROOT = OUT.parents[3]
PIN=json.loads((OUT/"source.json").read_text(encoding="utf-8"))
def source_matches():
    return all(hashlib.sha256((ROOT/"patch-notes"/path.removeprefix("res://")).read_bytes()).hexdigest()==sha for path,sha in PIN["runtime_files"].items())
assert source_matches(), "Runtime changed from pinned source"
spec = importlib.util.spec_from_file_location("sim", ROOT / "tools/simulate.py")
sim = importlib.util.module_from_spec(spec)
spec.loader.exec_module(sim)
label, script, *args = sys.argv[1:]
assert not (OUT / (label + "-run.json")).exists(), "Use a fresh label"
driver = "WASAPI" if "--device" in args else "Dummy"
check_only = "--check-only" in args
native = "--native" in args
args = [arg for arg in args if arg not in ["--device", "--native", "--check-only"]]
env = sim.isolated_environment(ROOT / ".codex-godot-temp" / ("tech-row-" + label))
env["PN_CARD_FRAME_OUTPUT"] = str(OUT / (label + ".json"))
for marker, variable, filename in [("verify_background_", "PN_BG_FIXTURE", "background_checkpoint_v003_c96.json"), ("verify_latency_restore", "PN_LATENCY_PRIOR_SAVES", "latency_restore_pre_store_era_v1.json"), ("verify_gameplay_tree", "PN_GAMEPLAY_PRIOR_SAVES", "gameplay_parents_pre_change_v1.json"), ("verify_store_grid_graph", "PN_STORE_GRID_PRIOR_SAVES", "store_grid_graph_predecessor.json")]:
    if marker in script:
        fixture = ROOT / "tools/fixtures" / filename
        proof = json.loads(fixture.with_suffix(".provenance.json").read_text(encoding="utf-8"))
        assert hashlib.sha256(fixture.read_bytes()).hexdigest() == proof["sha256"]
        env[variable] = str(fixture)
env["PN_PAUSE_BASELINE"] = str(OUT / "before-pair.json")
with socket.socket() as sock:
    sock.bind(("127.0.0.1", 0))
    env["PN_CHECKPOINT_TEST_PORT"] = str(sock.getsockname()[1])
command = [r"C:\Users\64jus\Downloads\Godot_v4.7.1-stable_win64.exe\Godot_v4.7.1-stable_win64_console.exe",
           "--headless", "--audio-driver", driver, "--path", str(ROOT / "patch-notes"), "--script", script]
if check_only: command.append("--check-only")
if native:
    command.remove("--headless")
    command += ["--rendering-method", "gl_compatibility", "--resolution", "1152x648", "--position", "80,80"]
if args:
    command += ["--"] + args
script_input = ROOT / "patch-notes" / script.removeprefix("res://") if script.startswith("res://") else Path(script)
script_hash = hashlib.sha256(script_input.read_bytes()).hexdigest() if script_input.is_file() else None
start = time.monotonic()
if script_input.is_file():
    (OUT / (label + "-probe.gd")).write_bytes(script_input.read_bytes())
with (OUT / (label + ".log")).open("xb") as log:
    try:
        code = subprocess.run(command, env=env, stdout=log, stderr=subprocess.STDOUT, timeout=600 if "research_latency.gd" in script else 600 if any(name in script for name in ["verify_contract_search","verify_qa_career"]) else 130).returncode
    except subprocess.TimeoutExpired:
        code = 124
lines = (OUT / (label + ".log")).read_text(encoding="utf-8", errors="replace").splitlines()
errors = [line for line in lines if any(marker in line for marker in ["SCRIPT ERROR", "Parse Error", "ERROR:", "FAIL:"])]
result = {"command": command, "exit": code, "elapsed_seconds": round(time.monotonic() - start, 3),
          "errors": errors, "tail": lines[-10:], "runtime_identity":PIN["runtime_identity"],"runtime_source_unchanged":source_matches()}
(OUT / (label + "-run.json")).write_text(json.dumps(result, indent=2) + "\n", encoding="utf-8")
print(json.dumps({**result, "errors": errors[:6], "error_count": len(errors)}), flush=True)
if script_hash is not None:
    (OUT / (label + "-probe.json")).write_text(json.dumps({"script":script,"sha256":script_hash,"copy":label+"-probe.gd"},indent=2))
raise SystemExit(1 if errors or not result["runtime_source_unchanged"] else code)
