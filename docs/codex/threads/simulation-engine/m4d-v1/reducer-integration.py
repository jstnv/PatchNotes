"""Reproduce a declared intentional rejection after two legal releases, then reduce."""
import importlib.util
import json
from pathlib import Path
import subprocess
import sys
import time

ROOT = Path(__file__).resolve().parents[5]
OUT = Path(__file__).resolve().parent
SPEC = importlib.util.spec_from_file_location("reducer_test_simulate", ROOT / "tools/simulate.py")
sim = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(sim)
PYTHON = sys.executable
GODOT = "C:/Users/64jus/Downloads/Godot_v4.7.1-stable_win64.exe/Godot_v4.7.1-stable_win64_console.exe"
before = sim.source_hashes(ROOT / "patch-notes")
sim.write_json(OUT / "reducer-canonical-before.json", before)
commands = []


def execute(label, arguments, expected=0):
    start = time.time()
    child = subprocess.run(arguments, cwd=ROOT, capture_output=True, creationflags=subprocess.CREATE_NO_WINDOW if sys.platform == "win32" else 0, timeout=600)
    (OUT / (label + ".log")).write_bytes(child.stdout + child.stderr)
    record = {"argv": arguments, "start": start, "end": time.time(), "exit": child.returncode, "expected_exit": expected}
    commands.append(record)
    sim.write_json(OUT / (label + ".command.json"), record)
    assert child.returncode == expected, label + " unexpected exit"


configuration = sim.read_json(ROOT / "docs/codex/threads/simulation-engine/examples/finite-fixture.json")
configuration["policy"] = {"script": "reducer-negative-policy.gd", "id": "intentional-rejection-fixture", "version": "1"}
case = configuration["cases"][0]
case["case_id"] = "intentional-rejection-after-two"
case["target_release_count"] = 3
case["max_commands"] = 100
case["telemetry"] = True
config = OUT / "reducer-negative-config.json"
sim.write_json(config, configuration)
bundle = OUT / "reducer-original-run"
reduced = OUT / "reducer-reduced-run"
execute("reducer-original", [PYTHON, "tools/simulate.py", "run", "--config", str(config), "--output", str(bundle), "--godot", GODOT, "--timeout", "240"], expected=1)
original = sim.read_json(bundle / "cases/intentional-rejection-after-two/result.json")
assert original["commands"] == 37 and original["accepted_commands"] == 36
assert original["final_release_count"] == 2 and original["replayable"]
assert original["status"] == "rejected_policy_action", original["status"]
execute("reducer-execute", [PYTHON, "tools/reduce_simulation.py", "--bundle", str(bundle), "--case", "intentional-rejection-after-two", "--kind", "rejection", "--max-commands", "100", "--output", str(reduced), "--godot", GODOT, "--timeout", "240"])
report = sim.read_json(reduced / "reduction-run.json")
reduction = report["reduction"]
confirmation = sim.read_json(reduced / "confirmation/reduction.json")
assert report["ok"] and report["fresh_process_confirmation"]
assert reduction["original_commands"] == 37 and reduction["reduced_commands"] == 1
assert reduction["removed_prefix_commands"] == 36 and reduction["removed_tail_commands"] == 0
assert reduction["first_failure_step"] == 36 and reduction["reduced_failure_step"] == 0
assert reduction["signature"] == confirmation["signature"]
assert reduction["signature"]["command_type"] == "intentional_reducer_rejection_fixture"
assert (reduced / "confirmation-profile/APPDATA").is_dir()
after = sim.source_hashes(ROOT / "patch-notes")
sim.write_json(OUT / "reducer-canonical-after.json", after)
assert before == after
audit = {"ok": True, "scope": "Deliberate unknown-command negative fixture after two legal releases; not a discovered gameplay failure", "canonical_files_unchanged": len(before), "original_commands": 37, "accepted_prefix_commands": 36, "reduced_commands": 1, "initial_origin": "recipe", "reduced_origin": "exact-restorable Studio checkpoint", "fresh_process_confirmation": True, "signature": reduction["signature"], "minimality": reduction["minimality"], "commands": commands, "source_identity": original["source_identity"], "runner_sha256": sim.sha(ROOT / "tools/simulate.py"), "reducer_sha256": sim.sha(ROOT / "tools/reduce_simulation.py")}
sim.write_json(OUT / "reducer-integration-audit.json", audit)
print(json.dumps({key: audit[key] for key in ("ok", "original_commands", "reduced_commands", "fresh_process_confirmation", "canonical_files_unchanged")}))
