from pathlib import Path
import json, os, subprocess

OUT = Path(__file__).resolve().parent
destination = OUT / "export-memory-probe"
destination.mkdir()
manifest = json.loads((OUT / "gate3/build-manifest.json").read_text())
workspace = Path(manifest["workspace"])
env = os.environ.copy()
for key in ("APPDATA", "LOCALAPPDATA"):
    env[key] = str(workspace / key)
for key in ("TMP", "TEMP", "TMPDIR"):
    env[key] = str(workspace / "temp")
command = [r"C:\Users\64jus\Downloads\Godot_v4.7.1-stable_win64.exe\Godot_v4.7.1-stable_win64_console.exe",
           "--headless", "--text-driver", "Dummy", "--path", str(workspace / "source"),
           "--export-release", "Windows Desktop", str(destination / "Patch Notes Demo.exe")]
with (destination / "export.log").open("wb") as log:
    result = subprocess.run(command, env=env, stdout=log, stderr=subprocess.STDOUT, timeout=180)
text = (destination / "export.log").read_text(errors="replace")
errors = [line for line in text.splitlines() if "ERROR:" in line or "SCRIPT ERROR" in line]
(destination / "command.json").write_text(json.dumps({"command": command, "exit": result.returncode, "errors": errors}, indent=2))
print(result.returncode, errors)
