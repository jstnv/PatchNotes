"""Focused checks in isolated profiles; real device audio only when requested."""
from pathlib import Path
import importlib.util
import json
import socket
import subprocess
import sys
import time

OUT = Path(__file__).resolve().parent
ROOT = OUT.parents[3]
spec = importlib.util.spec_from_file_location("sim", ROOT / "tools/simulate.py")
sim = importlib.util.module_from_spec(spec)
spec.loader.exec_module(sim)
label, script, *args = sys.argv[1:]
assert not (OUT / (label + "-run.json")).exists(), "Use a fresh output label"
driver = "WASAPI" if "--device" in args else "Dummy"
native = "--native" in args
args = [arg for arg in args if arg not in ["--device", "--native"]]
env = sim.isolated_environment(OUT / ("profile-" + label))
env["PN_CARD_FRAME_OUTPUT"] = str(OUT / (label + ".json"))
with socket.socket() as sock:
    sock.bind(("127.0.0.1", 0))
    env["PN_CHECKPOINT_TEST_PORT"] = str(sock.getsockname()[1])
command = [r"C:\Users\64jus\Downloads\Godot_v4.7.1-stable_win64.exe\Godot_v4.7.1-stable_win64.exe",
           "--headless", "--audio-driver", driver, "--path", str(ROOT / "patch-notes"), "--script", script]
if native:
    command.remove("--headless")
    command += ["--rendering-method", "gl_compatibility", "--resolution", "1152x648", "--position", "80,80"]
if args:
    command += ["--"] + args
start = time.monotonic()
timed_out = False
with (OUT / (label + ".log")).open("xb") as log:
    try:
        process = subprocess.run(command, env=env, stdout=log, stderr=subprocess.STDOUT, timeout=130)
        code = process.returncode
    except subprocess.TimeoutExpired:
        timed_out = True
        code = 124
lines = (OUT / (label + ".log")).read_text(encoding="utf-8", errors="replace").splitlines()
errors = [line for line in lines if any(marker in line for marker in ["SCRIPT ERROR", "Parse Error", "ERROR:", "FAIL:"])]
result = {"command": command, "profile": str(OUT / ("profile-" + label)), "exit": code,
          "timed_out": timed_out, "elapsed_seconds": round(time.monotonic() - start, 3),
          "errors": errors, "tail": lines[-10:]}
(OUT / (label + "-run.json")).write_text(json.dumps(result, indent=2) + "\n", encoding="utf-8")
print(json.dumps(result), flush=True)
raise SystemExit(1 if errors else code)
