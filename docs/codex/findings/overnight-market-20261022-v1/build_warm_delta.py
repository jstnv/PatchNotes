"""Current-source export using verified, unchanged Gate5 asset imports.

This is explicitly an incremental final build, not a new clean-import claim.
Every staged source is refreshed and checked; runtime identity is probed later.
"""
from pathlib import Path
import importlib.util, json, os, runpy, shutil, sys, subprocess

ROOT = Path(__file__).resolve().parents[4]
HERE = Path(__file__).resolve().parent
OUT = HERE / "final-build-warm"
OUT.mkdir()
(OUT / ".gdignore").touch()

def load(name, path):
    spec = importlib.util.spec_from_file_location(name, path)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module

sim = load("sim", ROOT / "tools/simulate.py")
exporter = load("exporter", ROOT / "docs/codex/findings/export-queue-v3/export.py")
old = sim.read_json(HERE / "gate5/build-manifest.json")
source = OUT / "source"
demo = OUT / "demo"
demo.mkdir()
shutil.copytree(Path(old["workspace"]) / "source", source)
manifest = json.loads(json.dumps(old))
manifest.update(workspace=str(OUT), baseline_build_manifest_sha256=sim.sha(HERE / "gate5/build-manifest.json"),
                import_provenance="Gate5 clean imports retained; canonical runtime sources refreshed and verified. No new clean-import acceptance.")
changed = []
for rel, previous in old["included"].items():
    current = ROOT / "patch-notes" / rel
    if sim.sha(current) != previous:
        changed.append(rel)
    shutil.copy2(current, source / rel)
    manifest["included"][rel] = sim.sha(current)
config = source / "project.godot"
config.write_text(config.read_text(encoding="utf8").replace('config/name="Patch Notes"', 'config/name="Patch Notes Demo"'), encoding="utf8")
assert changed == [rel for rel in old["included"] if rel in {"scripts/ui/market_browser.gd", "scripts/market/rival_world_checkpoint.gd"}], changed
for rel, digest in old.get("import_settings", {}).items():
    assert sim.sha(ROOT / "patch-notes" / rel) == digest
env = sim.isolated_environment(OUT / "profile")
templates = Path(old["workspace"]) / "APPDATA/Godot/export_templates"
shutil.copytree(templates, Path(env["APPDATA"]) / "Godot/export_templates")
manifest["runtime_source_delta"] = changed
exporter.OUT = OUT
sim.write_json(OUT / "build-manifest.json", manifest)
exporter.run("export-release", [exporter.GODOT, "--headless", "--text-driver", "Dummy", "--path", source,
             "--export-release", "Windows Desktop", demo / "Patch Notes Demo.exe"], env, OUT)
shutil.copy2(Path(old["workspace"]) / "demo/Tiny5-OFL.txt", demo / "Tiny5-OFL.txt")
manifest["artifacts"] = {p.name: {"sha256": sim.sha(p), "bytes": p.stat().st_size} for p in demo.iterdir() if p.is_file()}
sim.write_json(OUT / "build-manifest.json", manifest)
shutil.copy2(ROOT / "docs/codex/findings/export-queue-v3/inspect.py", OUT / "inspect.py")
runpy.run_path(str(OUT / "inspect.py"), run_name="__main__")
for name, args in (("headless", ["--headless"]), ("graphical", ["--rendering-method", "gl_compatibility"])):
    command = [str(demo / "Patch Notes Demo.exe"), *args, "--quit-after", "60"]
    with (OUT / (name + ".log")).open("wb") as log:
        result = subprocess.run(command, env=sim.isolated_environment(OUT / (name + "-profile")), stdout=log, stderr=subprocess.STDOUT, timeout=90)
    text = (OUT / (name + ".log")).read_text(errors="replace")
    errors = [line for line in text.splitlines() if (line.startswith("ERROR:") or "SCRIPT ERROR" in line) and "root certificate store" not in line]
    sim.write_json(OUT / (name + ".command.json"), {"command": command, "exit": result.returncode, "errors": errors})
    if result.returncode or errors:
        raise RuntimeError(name + " failed")
for rel, digest in manifest["included"].items():
    assert sim.sha(ROOT / "patch-notes" / rel) == digest, rel
sim.write_json(OUT / "result.json", {"current_source_export_pass": True, "new_clean_import": False, "release_ready": False,
               "runtime_source_delta": changed, "baseline": "Gate5 full173-suite clean build; final3 affected runs and campaign-delta follow the Esc change."})
print("CURRENT SOURCE WARM EXPORT PASS")
