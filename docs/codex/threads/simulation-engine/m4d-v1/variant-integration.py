"""Declared synthetic isolation study; numeric changes are not balance proposals."""
from concurrent.futures import ThreadPoolExecutor
import importlib.util
import json
from pathlib import Path
import subprocess
import sys
import time

ROOT = Path(__file__).resolve().parents[5]
OUT = Path(__file__).resolve().parent
SPEC = importlib.util.spec_from_file_location("variant_sim", ROOT / "tools/simulate.py")
sim = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(sim)
GODOT = "C:/Users/64jus/Downloads/Godot_v4.7.1-stable_win64.exe/Godot_v4.7.1-stable_win64_console.exe"
PYTHON = sys.executable
before = sim.source_hashes(ROOT / "patch-notes")
sim.write_json(OUT / "variant-canonical-before.json", before)
commands = []


def execute(label, command, expected=0):
    start = time.time()
    process = subprocess.run(command, cwd=ROOT, capture_output=True, creationflags=subprocess.CREATE_NO_WINDOW if sys.platform == "win32" else 0, timeout=600)
    (OUT / (label + ".log")).write_bytes(process.stdout + process.stderr)
    record = {"label": label, "argv": command, "start": start, "end": time.time(), "exit": process.returncode}
    sim.write_json(OUT / (label + ".command.json"), record)
    commands.append(record)
    if process.returncode != expected:
        raise RuntimeError(label + " unexpected exit: " + str(process.returncode))
    return record


a = OUT / "variant-a-v1"
b = OUT / "variant-b-v2"
execute("variant-create-a", [PYTHON, "tools/simulator_variant.py", "create", "--id", "isolation-a-v1", "--owner", "M4d synthetic verification", "--output", str(a)])
path_a = a / "project/scripts/run_state.gd"
original_a = path_a.read_bytes()
assert original_a.count(b"const FIRST_STUDIO_CASH_CENTS := 550000") == 1
path_a.write_bytes(original_a.replace(b"const FIRST_STUDIO_CASH_CENTS := 550000", b"const FIRST_STUDIO_CASH_CENTS := 560000"))
execute("variant-fork-b", [PYTHON, "tools/simulator_variant.py", "create", "--id", "isolation-b-v2", "--owner", "M4d second synthetic thread", "--from-variant", str(a), "--output", str(b)])
path_b = b / "project/scripts/run_state.gd"
path_b.write_bytes(path_b.read_bytes().replace(b"const FIRST_STUDIO_CASH_CENTS := 560000", b"const FIRST_STUDIO_CASH_CENTS := 570000"))
configuration = sim.read_json(ROOT / "docs/codex/threads/simulation-engine/examples/finite-fixture.json")
configuration["cases"][0]["telemetry"] = True
config = OUT / "variant-config.json"
sim.write_json(config, configuration)
decision = OUT / "variant-test-decision.md"
decision.write_text("# Synthetic candidate isolation fixture\n\nThis is a tooling test, not an accepted balance proposal. Canonical starting capital remains unchanged. Candidate A adds $100 to FIRST_STUDIO_CASH_CENTS; B forks A and instead adds $200. Both run the same declared two-release seed-4417 policy. The expected difference is $100 of cash and identical non-financial release/RNG behavior. Neither candidate is to be adopted.\n", encoding="utf-8")


def run_arm(arm):
    variant = a if arm == "a" else b
    return execute("variant-run-" + arm, [PYTHON, "tools/simulate.py", "run", "--variant", str(variant), "--config", str(config), "--output", str(OUT / ("variant-run-" + arm)), "--godot", GODOT, "--timeout", "240"])


with ThreadPoolExecutor(max_workers=2) as pool:
    runs = list(pool.map(run_arm, ("a", "b")))
assert max(item["start"] for item in runs) < min(item["end"] for item in runs)


def replay_arm(arm):
    return execute("variant-replay-" + arm, [PYTHON, "tools/simulate.py", "replay", "--bundle", str(OUT / ("variant-run-" + arm)), "--case", "action-4417", "--output", str(OUT / ("variant-replay-" + arm)), "--godot", GODOT, "--timeout", "240"])


with ThreadPoolExecutor(max_workers=2) as pool:
    list(pool.map(replay_arm, ("a", "b")))

handoff_arguments = [PYTHON, "tools/simulator_variant.py", "handoff", "--variant", str(a), "--evidence", str(OUT / "variant-run-a"), "--design-record", str(decision), "--summary", "Synthetic isolation fixture only; do not adopt its capital change", "--acceptance", "Two candidate processes overlap, canonical source remains unchanged and each exact replay passes"]
candidate_a = path_a.read_bytes()
path_a.write_bytes(candidate_a + b"\n# later candidate edit for stale-evidence rejection\n")
try:
    execute("variant-stale-handoff-rejected", handoff_arguments + ["--output", str(OUT / "variant-stale-handoff")], expected=1)
    assert "predates candidate edits" in (OUT / "variant-stale-handoff-rejected.log").read_text()
finally:
    path_a.write_bytes(candidate_a)
execute("variant-create-handoff", handoff_arguments + ["--output", str(OUT / "variant-handoff-a")])

reports = {arm: sim.read_json(OUT / ("variant-run-" + arm) / "run-report.json") for arm in ("a", "b")}
results = {arm: sim.read_json(OUT / ("variant-run-" + arm) / "cases/action-4417/result.json") for arm in ("a", "b")}
replays = {arm: sim.read_json(OUT / ("variant-replay-" + arm) / "run-report.json") for arm in ("a", "b")}
assert reports["a"]["variant"]["base_identity"] == reports["b"]["variant"]["base_identity"]
assert reports["a"]["variant"]["candidate_identity"] != reports["b"]["variant"]["candidate_identity"]
assert reports["b"]["variant"]["lineage"][-1]["id"] == "isolation-a-v1"
assert results["a"]["outcome"]["releases"] == results["b"]["outcome"]["releases"]
assert int(results["b"]["outcome"]["cash_cents"]) - int(results["a"]["outcome"]["cash_cents"]) == 10000
for arm in ("a", "b"):
    assert reports[arm]["ok"] and replays[arm]["ok"]
    assert replays[arm]["replay"]["telemetry_verified"]
    assert not reports[arm]["variant"]["baseline_drift"]
    assert (OUT / ("variant-run-" + arm) / "profile/APPDATA").is_dir()
after = sim.source_hashes(ROOT / "patch-notes")
sim.write_json(OUT / "variant-canonical-after.json", after)
assert before == after
audit = {"ok": True, "scope": "Two synthetic capital changes only; no balance approval or canonical adoption", "overlapping_runs": True, "separate_profiles": True, "canonical_files_unchanged": len(before), "commands_per_arm": {arm: results[arm]["commands"] for arm in results}, "cash_cents": {arm: results[arm]["outcome"]["cash_cents"] for arm in results}, "release_histories_equal": True, "fresh_replay_telemetry_verified": True, "lineage_preserved": True, "stale_evidence_rejected": True, "source_identities": {arm: reports[arm]["variant"] for arm in reports}, "commands": commands}
sim.write_json(OUT / "variant-audit.json", audit)
print(json.dumps({key: audit[key] for key in ("ok", "canonical_files_unchanged", "commands_per_arm", "cash_cents")}))
