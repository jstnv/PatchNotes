"""Prepare the actual legal campaign save, then launch the audited release EXE.

Native inputs and observations are performed separately through Computer Use.
No player save, source identity, or gameplay field is manually relabeled.
"""
from pathlib import Path
import importlib.util
import json
import subprocess
import sys

OUT = Path(__file__).resolve().parent
ROOT = OUT.parents[3]
spec = importlib.util.spec_from_file_location("sim", ROOT / "tools/simulate.py")
sim = importlib.util.module_from_spec(spec)
spec.loader.exec_module(sim)
gate = OUT / sys.argv[1]
label = sys.argv[2]
input_checkpoint = OUT / (sys.argv[3] if len(sys.argv) > 3 else "campaign-record.json.checkpoint.json")
manifest = json.loads((gate / "build-manifest.json").read_text())
demo = Path(manifest["workspace"]) / "demo"
exe = demo / "Patch Notes Demo.exe"
pck = demo / "Patch Notes Demo.pck"
profile = OUT / (label + "-profile")
if profile.exists():
    raise SystemExit("Use a new isolated profile label")
env = sim.isolated_environment(profile)
engine = r"C:\Users\64jus\Downloads\Godot_v4.7.1-stable_win64.exe\Godot_v4.7.1-stable_win64_console.exe"
prepare = [engine, "--headless", "--audio-driver", "Dummy", "--main-pack", str(pck),
           "--script", str(OUT / "prepare_native_checkpoint.gd"), "--",
           str(input_checkpoint),
           str(OUT / (label + "-prepared.json"))]
with (OUT / (label + "-prepare.log")).open("wb") as log:
    prepared = subprocess.run(prepare, env=env, stdout=log, stderr=subprocess.STDOUT, timeout=60)
if prepared.returncode:
    raise SystemExit(prepared.returncode)
command = [str(exe), "--rendering-method", "gl_compatibility"]
with (OUT / (label + ".log")).open("wb") as log:
    process = subprocess.Popen(command, env=env, stdout=log, stderr=subprocess.STDOUT,
                               creationflags=subprocess.CREATE_NO_WINDOW)
    sim.write_json(OUT / (label + "-process.json"), {
        "pid": process.pid, "command": command, "profile": str(profile),
        "exe_sha256": sim.sha(exe), "pck_sha256": sim.sha(pck),
        "gate": str(gate),
    })
    print(process.pid, flush=True)
    sim.write_json(OUT / (label + "-exit.json"), {"exit": process.wait()})
