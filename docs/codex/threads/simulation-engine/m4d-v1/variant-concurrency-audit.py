"""Check actual child process overlap and retained variant-run isolation evidence."""
import datetime as dt
import hashlib
import json
from pathlib import Path

OUT = Path(__file__).resolve().parent
def read(path):
    return json.loads(path.read_text(encoding="utf-8"))
def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()

commands = {arm: read(OUT / ("variant-run-" + arm) / "experiment.command.json") for arm in ("a", "b")}
starts = {arm: dt.datetime.fromisoformat(value["started_utc"]).timestamp() for arm, value in commands.items()}
ends = {arm: starts[arm] + commands[arm]["elapsed_seconds"] for arm in commands}
overlap = min(ends.values()) - max(starts.values())
assert overlap > 0
results = {arm: read(OUT / ("variant-run-" + arm) / "cases/action-4417/result.json") for arm in ("a", "b")}
assert results["a"]["final_rng"] == results["b"]["final_rng"]
assert results["a"]["outcome"]["releases"] == results["b"]["outcome"]["releases"]
assert results["a"]["source_identity"] != results["b"]["source_identity"]
telemetry = {arm: read(OUT / ("variant-run-" + arm) / "cases/action-4417/telemetry.json") for arm in ("a", "b")}
assert len(telemetry["a"]["samples"]) == len(telemetry["b"]["samples"]) == 37
profiles = {arm: str((OUT / ("variant-run-" + arm) / "profile").resolve()) for arm in ("a", "b")}
assert profiles["a"] != profiles["b"]
for arm in ("a", "b"):
    replay = read(OUT / ("variant-replay-" + arm) / "run-report.json")
    assert replay["ok"] and replay["replay"]["telemetry_verified"]
audit = {"ok": True, "actual_godot_experiment_overlap_seconds": overlap, "source_identity_distinct": True, "final_rng_equal": True, "release_histories_equal": True, "telemetry_samples_replayed": 74, "profiles": profiles, "frozen_runner_hashes": {arm: digest(OUT / ("variant-run-" + arm) / "runner.py") for arm in commands}, "current_runner_hash": digest(OUT.parents[4] / "tools/simulate.py"), "scope": "Frozen runner evidence precedes a later Python 3.10/3.11 Windows junction compatibility guard; that guard is covered by unit tests. Runtime source and candidate deltas are unchanged."}
(OUT / "variant-concurrency-audit.json").write_text(json.dumps(audit, indent=2) + "\n", encoding="utf-8")
print(json.dumps(audit))
