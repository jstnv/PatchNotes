from pathlib import Path
import os, subprocess, tempfile, json
from run_checks import GODOT, PROJECT, PROFILE, HERE
profile = Path(tempfile.mkdtemp(prefix="render-", dir=PROFILE))
env = os.environ.copy()
for key in ("APPDATA", "LOCALAPPDATA"):
    directory = profile / key
    directory.mkdir()
    env[key] = str(directory)
command = [GODOT, "--path", str(PROJECT), "--rendering-method", "gl_compatibility",
           "--script", "res://scripts/debug/capture_checkpoint_ui.gd"]
with (HERE / "capture-ui.log").open("wb") as log:
    result = subprocess.run(command, env=env, stdout=log, stderr=subprocess.STDOUT, timeout=90)
text = (HERE / "capture-ui.log").read_text(errors="replace")
errors = [line for line in text.splitlines() if (line.startswith("ERROR:") or "SCRIPT ERROR" in line)
          and "root certificate store" not in line]
(HERE / "capture-ui.command.json").write_text(json.dumps(dict(command=command, exit=result.returncode, errors=errors), indent=2))
print(result.returncode, errors)
raise SystemExit(1 if result.returncode or errors else 0)
