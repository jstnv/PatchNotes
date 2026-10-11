"""Build a source-pinned, dedicated-profile acceptance export without source edits."""
from pathlib import Path
import hashlib
import importlib.util
import json
import os
import runpy
import shutil
import subprocess
import sys

repo = Path(r"C:\Users\64jus\OneDrive\Documents\GitHub\PatchNotes")
base = Path(__file__).resolve().parent
out = base / "export"
playable = base / "playable"
godot = Path(r"C:\Users\64jus\Downloads\Godot_v4.7.1-stable_win64.exe\Godot_v4.7.1-stable_win64_console.exe")
source_pin = json.loads((repo / "docs/codex/findings/overnight-20261011-v2/source-final.json").read_text())


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def load(name, path):
    spec = importlib.util.spec_from_file_location(name, path)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def drift():
    return [rel for rel, expected in source_pin.items()
            if not (repo / "patch-notes" / rel).is_file()
            or sha(repo / "patch-notes" / rel) != expected]


if drift():
    raise SystemExit("Source drift since maintained checks")
out.mkdir(parents=True, exist_ok=False)
exporter = load("exporter", repo / "docs/codex/findings/export-queue-v3/export.py")
exporter.OUT = out
saved = sys.argv
sys.argv = ["export.py", "--godot", str(godot)]
try:
    exporter.main()
finally:
    sys.argv = saved

manifest_path = out / "build-manifest.json"
manifest = json.loads(manifest_path.read_text())
workspace = Path(manifest["workspace"])
project = workspace / "source"
demo = workspace / "demo"
config = project / "project.godot"
before = config.read_text(encoding="utf-8")
needle = 'config/name="Patch Notes Demo"'
assert before.count(needle) == 1
after = before.replace(needle, needle + '\nconfig/use_custom_user_dir=true\nconfig/custom_user_dir_name="Patch Notes Acceptance 20261011 v3"')
config.write_text(after, encoding="utf-8")
env = os.environ.copy()
for key in ["APPDATA", "LOCALAPPDATA"]:
    profile = out / "builder-profile" / key
    profile.mkdir(parents=True, exist_ok=True)
    env[key] = str(profile)
    original = workspace / key / "Godot" / "export_templates" / exporter.VERSION
    if key == "APPDATA":
        target = profile / "Godot" / "export_templates" / exporter.VERSION
        shutil.copytree(original, target, dirs_exist_ok=True)
exporter.run("acceptance-import", [godot, "--headless", "--path", project, "--editor", "--import", "--quit"], env, workspace)
exe = demo / "Patch Notes Demo.exe"
exporter.run("acceptance-export", [godot, "--headless", "--path", project, "--export-release", "Windows Desktop", exe], env, workspace)
manifest["build_only_override"] = "application/config/name=Patch Notes Demo; use_custom_user_dir=true; custom_user_dir_name=Patch Notes Acceptance 20261011 v3"
manifest["copied_project_godot_sha256"] = sha(config)
manifest["artifacts"] = {p.name: {"sha256": sha(p), "bytes": p.stat().st_size} for p in demo.iterdir() if p.is_file()}
manifest_path.write_text(json.dumps(manifest, indent=2))
shutil.copy2(repo / "docs/codex/findings/export-queue-v3/inspect.py", out / "inspect.py")
runpy.run_path(str(out / "inspect.py"), run_name="__main__")

playable.mkdir(parents=True, exist_ok=False)
for name in manifest["artifacts"]:
    shutil.copy2(demo / name, playable / name)
    assert sha(playable / name) == manifest["artifacts"][name]["sha256"]

smoke = out / "smoke-profile"
for key in ["APPDATA", "LOCALAPPDATA"]:
    profile = smoke / key
    profile.mkdir(parents=True, exist_ok=True)
    env[key] = str(profile)
command = [str(playable / "Patch Notes Demo.exe"), "--headless", "--quit-after", "60"]
result = subprocess.run(command, env=env, capture_output=True, timeout=90)
log = (result.stdout + result.stderr).decode(errors="replace")
(out / "headless-startup.log").write_text(log)
errors = [line for line in log.splitlines() if ("SCRIPT ERROR" in line or line.startswith("ERROR:")) and "root certificate store" not in line]
(out / "headless-startup.command.json").write_text(json.dumps({"command": command, "exit": result.returncode, "errors": errors}, indent=2))
if result.returncode or errors:
    raise SystemExit("Headless startup failed")

all_drift = [rel for rel, expected in manifest["included"].items()
             if not (repo / "patch-notes" / rel).is_file() or sha(repo / "patch-notes" / rel) != expected]
summary = {"playable": str(playable), "artifacts": manifest["artifacts"], "package_entries": json.loads((out / "pack-manifest-verified.json").read_text())["count"], "headless_startup_exit": result.returncode, "source_drift_since_gate": drift(), "included_source_drift_after_export": all_drift}
(out / "playable-summary.json").write_text(json.dumps(summary, indent=2))
print("PLAYABLE SUMMARY", json.dumps(summary, indent=2), flush=True)
