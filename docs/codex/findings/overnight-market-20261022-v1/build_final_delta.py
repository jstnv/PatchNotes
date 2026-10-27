"""Clean export and audit after the final Market-only cancel routing change."""
from pathlib import Path
import importlib.util, json, os, runpy, shutil, subprocess, sys

ROOT = Path(__file__).resolve().parents[4]
OUT = Path(__file__).resolve().parent / (sys.argv[1] if len(sys.argv) > 1 else "final-build")
OUT.mkdir()
(OUT / ".gdignore").touch()

def load(name, path):
    spec = importlib.util.spec_from_file_location(name, path)
    value = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(value)
    return value

exporter = load("exporter", ROOT / "docs/codex/findings/export-queue-v3/export.py")
sim = load("sim", ROOT / "tools/simulate.py")
source = {p.relative_to(ROOT / "patch-notes").as_posix(): sim.sha(p)
          for base in ("scripts", "queries", "scenes", "data")
          for p in (ROOT / "patch-notes" / base).rglob("*") if p.is_file()}
sim.write_json(OUT / "source.json", source)
exporter.OUT = OUT
sys.argv = ["export.py", "--godot", str(exporter.GODOT)]
exporter.main()
shutil.copy2(ROOT / "docs/codex/findings/export-queue-v3/inspect.py", OUT / "inspect.py")
runpy.run_path(str(OUT / "inspect.py"), run_name="__main__")
manifest = sim.read_json(OUT / "build-manifest.json")
exe = Path(manifest["workspace"]) / "demo/Patch Notes Demo.exe"
checks = []
for name, args in (("headless", ["--headless"]), ("graphical", ["--rendering-method", "gl_compatibility"])):
    env = sim.isolated_environment(OUT / (name + "-profile"))
    command = [str(exe), *args, "--quit-after", "60"]
    with (OUT / (name + ".log")).open("wb") as log:
        result = subprocess.run(command, env=env, stdout=log, stderr=subprocess.STDOUT, timeout=90)
    text = (OUT / (name + ".log")).read_text(errors="replace")
    errors = [line for line in text.splitlines() if (line.startswith("ERROR:") or "SCRIPT ERROR" in line) and "root certificate store" not in line]
    row = {"name": name, "command": command, "exit": result.returncode, "errors": errors}
    checks.append(row)
    sim.write_json(OUT / (name + ".command.json"), row)
    if result.returncode or errors:
        raise RuntimeError(name + " failed")
changed = [rel for rel, digest in source.items() if sim.sha(ROOT / "patch-notes" / rel) != digest]
if changed:
    raise RuntimeError("Source changed: " + str(changed))
sim.write_json(OUT / "result.json", {"automated_export_pass": True, "release_ready": False,
               "source_unchanged": True, "checks": checks,
               "scope": "Final clean export/audit/startup plus separately recorded final3 affected suites; full 173-suite gate5 precedes only the Esc routing/known-predecessor delta."})
print("FINAL DELTA EXPORT PASS", flush=True)
