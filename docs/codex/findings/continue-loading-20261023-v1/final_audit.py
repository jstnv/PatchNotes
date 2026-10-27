"""Pin the final runtime, retained focused runs and real-size native captures."""
from pathlib import Path
import hashlib
import importlib.util
import json
import shutil
import struct
import subprocess

ROOT = Path(__file__).resolve().parents[4]
HERE = Path(__file__).resolve().parent
TEMP = Path("C:/Users/64jus/AppData/Local/Temp")
spec = importlib.util.spec_from_file_location("loading_simulate", ROOT / "tools/simulate.py")
sim = importlib.util.module_from_spec(spec)
spec.loader.exec_module(sim)
before = sim.read_json(TEMP / "pn-continue-loading-20261023-red/source.json")
headless_dir = TEMP / "pn-continue-loading-20261023-green5"
native_dir = TEMP / "pn-continue-loading-20261023-final"
headless = sim.read_json(headless_dir / "result.json")
native = sim.read_json(native_dir / "result.json")
tested = sim.read_json(headless_dir / "source.json")
final = sim.read_json(native_dir / "source.json")
assert headless["pass"] and len(headless["checks"]) == 9
assert native["pass"] and native["native"] and len(native["checks"]) == 9
assert all(row["command"]["exit"] == 0 and not row["command"]["errors"] for row in native["checks"])
assert sim.source_hashes(ROOT / "patch-notes") == final
delta = sorted(k for k in tested.keys() | final.keys() if tested.get(k) != final.get(k))
assert delta == ["scripts/debug/verify_continue_loading.gd", "scripts/gameplay.gd", "scripts/ui/continue_loading.gd"], delta
result = sim.read_json(native_dir / "verify_continue_loading.json")
assert result["failures"] == 0 and result["audio_driver"] == "WASAPI"
assert [v["window"] for v in result["viewports"]] == [[1152,648],[1280,720]]
assert len(result["audio_samples"]) >= 4 and all(s["energy"] > .001 for s in result["audio_samples"])
changed = sorted(k for k in before.keys() | final.keys() if before.get(k) != final.get(k))
expected = sorted(["scripts/gameplay.gd", "scripts/persistence/checkpoint_coordinator.gd", "scripts/persistence/checkpoint_load.gd", "scripts/persistence/checkpoint_load.gd.uid", "scripts/ui/continue_loading.gd", "scripts/ui/continue_loading.gd.uid", "scripts/debug/verify_continue_loading.gd", "scripts/debug/verify_continue_loading.gd.uid", "scripts/debug/verify_checkpoint_recovery_ui.gd"])
assert changed == expected, changed
captures = []
for name in ["loading-1152x648.png", "loading-1280x720.png", "studio-1280x720.png"]:
    path = native_dir / "captures" / name
    size = list(struct.unpack(">II", path.read_bytes()[16:24]))
    assert size == ([1152,648] if "1152" in name else [1280,720])
    target = HERE / name
    shutil.copyfile(path, target)
    captures.append({"file": name, "size": size, "sha256": sim.sha(target)})
for name, source in [("preceding-headless-result.json",headless_dir / "result.json"), ("focused-result.json",native_dir / "result.json"), ("native-result.json",native_dir / "verify_continue_loading.json"), ("final-source.json",native_dir / "source.json")]:
    shutil.copyfile(source, HERE / name)
names = ["patch-notes/" + name for name in changed] + ["docs/codex/TODO.md", "docs/codex/CURRENT_STATE.md", "docs/codex/design/release-engineering.md"]
whitespace = subprocess.run(["git","-c","core.whitespace=cr-at-eol","diff","--check","--",*names],cwd=ROOT,capture_output=True)
assert whitespace.returncode == 0, whitespace.stdout.decode("utf8",errors="replace")
for path in [ROOT / "patch-notes" / name for name in changed]:
    assert all(line == line.rstrip() for line in path.read_text(encoding="utf8").splitlines()), path
report = {"pass": True, "branch":subprocess.check_output(["git","branch","--show-current"],cwd=ROOT,text=True).strip(), "head":subprocess.check_output(["git","rev-parse","HEAD"],cwd=ROOT,text=True).strip(), "local_uncommitted": True, "source_files":len(final), "source_manifest_sha256":hashlib.sha256(json.dumps(final,sort_keys=True,separators=(",",":")).encode()).hexdigest(), "changed_source":[{"path":k,"before":before.get(k),"after":final.get(k)} for k in changed], "focused_suites":9, "preceding_headless_to_final_delta":delta, "native_checks":result["checks"], "audio_backend":result["audio_driver"], "captures":captures, "whitespace_errors":0, "boundary":"Nine focused native runs pass on one unchanged final source snapshot. Nine earlier headless runs pass before the final visual entrance/viewport correction, recorded separately. No source files in either frozen run were rewritten. No full174-suite or export claim."}
sim.write_json(HERE / "final-audit.json",report)
print(json.dumps({"pass":True,"changed_source_paths":len(changed),"focused_suites":9,"native_checks":result["checks"],"manifest":report["source_manifest_sha256"]}))
