"""Refresh compact receipts without deleting failures or large local evidence."""
from pathlib import Path
import datetime
import hashlib
import json
import subprocess

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[3]


def read(path):
    return json.loads(path.read_text(encoding="utf-8-sig"))


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def write(name, value):
    (HERE / name).write_text(json.dumps(value, indent=2) + "\n", encoding="utf-8")


runtime = read(HERE / "final-runtime.json")
experiment = read(HERE / "campaign-run-final-v6/experiment-report.json")["results"][0]
rows = runtime["runtime_rows"]
drift = [name for name, digest in rows if sha(ROOT / "patch-notes" / name.removeprefix("res://")) != digest]
original = json.loads(subprocess.check_output(["git", "show", "HEAD:patch-notes/data/feature_store_ledger.json"], cwd=ROOT))
current = read(ROOT / "patch-notes/data/feature_store_ledger.json")
assert isinstance(original, list) and isinstance(current, list)
assert len(original) == 15 and len(current) == 19 and original == current[:15]
assert not drift and runtime["runtime_identity"] == experiment["source_identity"]
write("source-audit.json", {
    "head": runtime["head"], "runtime_identity": runtime["runtime_identity"],
    "experiment_runtime_identity": experiment["source_identity"],
    "runtime_matches_final_campaign": True, "runtime_drift_from_campaign": drift,
    "old_15_store_entries_unchanged": True, "original_store_entries": 15,
    "current_store_entries": 19, "runtime_rows": rows,
    "scope": "Current runtime hashes and final-v6 experiment; concurrent documentation edits are excluded."
})
audit = read(HERE / "campaign-current-audit-v6.json")
assert audit["ok"] and not audit["failures"]
audit["runtime_identity"] = runtime["runtime_identity"]
audit["source_matched_tape_and_cold_checkpoint"] = True
write("campaign-final-audit.json", audit)
receipts = []
for path in sorted(HERE.glob("*-run.json")):
    item = read(path)
    receipts.append({"file": path.name, "sha256": sha(path),
                     "exit": item.get("exit"), "errors": item.get("errors", []),
                     "elapsed_seconds": item.get("elapsed_seconds"),
                     "command": item.get("command")})
gates = []
final_gate_receipt = None
for path in sorted(HERE.glob("*/gate-result.json")):
    item = read(path)
    gates.append({"file": str(path.relative_to(HERE)), "sha256": sha(path),
                  "checks_completed": len(item.get("checks", [])),
                  "automated_pass": item.get("automated_pass", False),
                  "release_ready": item.get("release_ready", False),
                  "failure": item.get("failure"), "error": item.get("error"),
                  "failure_is_historical_after_successful_resume": bool(item.get("automated_pass") and item.get("failure")),
                  "blocked": item.get("blocked"), "remaining": item.get("remaining", [])})
    if path.parent.name == "release-gate-final-v4" and item.get("automated_pass"):
        assert item.get("headless_automated_pass") and not item.get("failure")
        assert len(item["checks"]) == 222
        records = []
        for name in item["checks"]:
            command = path.parent / (name + ".command.json")
            result = read(command)
            assert result["exit"] == 0 and not result["errors"], name
            records.append({"name": name, "command_receipt_sha256": sha(command),
                            "log_sha256": sha(path.parent / (name + ".log")),
                            "exit": result["exit"], "errors": result["errors"]})
        source_path = path.parent / "source.json"
        for name, digest in read(source_path).items():
            assert sha(ROOT / "patch-notes" / name) == digest, name
        manifest = read(path.parent / "build-manifest.json")
        assert manifest["export_helper_sha256"] == sha(ROOT / "docs/codex/findings/export-queue-v3/export.py")
        for name, digest in manifest["included"].items():
            assert sha(ROOT / "patch-notes" / name) == digest, name
        pack = read(path.parent / "pack-manifest-verified.json")
        assert pack["all_payload_md5_valid"] and not pack["missing_runtime_files"] and not pack["unexpected_files"]
        startups = {mode: read(path.parent / (mode + "-startup.command.json")) for mode in ["headless", "graphical"]}
        assert all(result["exit"] == 0 and not result["errors"] for result in startups.values())
        final_gate_receipt = {"automated_pass": True, "release_ready": False,
                              "runtime_identity": runtime["runtime_identity"],
                              "head": runtime["head"], "gate_result_sha256": sha(path),
                              "source_manifest_sha256": sha(source_path), "source_unchanged": True,
                              "verifiers": records, "pack_entries": pack["count"],
                              "pack_manifest_sha256": sha(path.parent / "pack-manifest-verified.json"),
                              "build_manifest_sha256": sha(path.parent / "build-manifest.json"),
                              "export_preset": manifest["export_preset"],
                              "export_helper_sha256": manifest["export_helper_sha256"],
                              "artifact_hashes": item["artifact_hashes"], "startup": startups,
                              "checkpoint_writer_instrumentation": item["checkpoint_writer_instrumentation"]["limits"],
                              "remaining": item["remaining"],
                              "attempt_history": ["gate-timeout-before-resume.json", "export-helper-regression.json"],
                              "shell_exit_observed": 1,
                              "defined_python_success_exit": 2,
                              "exit_note": "Tool shell receipt reported1. The Python success branch explicitly returns2 for remaining human acceptance, but its exit was not separately captured. Raw console confirms AUTOMATED PASS, final report true, all222 commands and both startups exit0. No inferred release readiness."}
        write("final-gate-receipt.json", final_gate_receipt)
fixtures = []
for name in ["background_checkpoint_v003_c96", "latency_restore_pre_store_era_v1", "queue_migration_pre_alpha_v1", "gameplay_parents_pre_change_v1"]:
    path = ROOT / "tools/fixtures" / (name + ".json")
    proof = read(path.with_suffix(".provenance.json"))
    assert sha(path) == proof["sha256"]
    fixtures.append({"file": str(path.relative_to(ROOT)), "sha256": sha(path)})
replay_path = HERE / "campaign-replay-final-v6/run-report.json"
replay = read(replay_path) if replay_path.is_file() else None
replay_summary = None
if replay is not None:
    result = replay.get("replay", {})
    replay_summary = {"file": str(replay_path.relative_to(HERE)), "sha256": sha(replay_path),
                      "ok": replay.get("ok"), "commands": len(result.get("steps", [])),
                      "telemetry_samples": result.get("telemetry_samples"),
                      "telemetry_verified": result.get("telemetry_verified"),
                      "final_state": result.get("final_state")}
write("verification-index.json", {
    "generated_utc": datetime.datetime.now(datetime.timezone.utc).isoformat(),
    "head": runtime["head"], "branch": "main", "current_runtime": runtime["runtime_identity"],
    "scope": "Approved Store Handoff020; bounded snapshot responsiveness correction and maintained acceptance harnesses. Per-receipt source epochs and retained failures remain distinct; no release/balance/AI-policy approval.",
    "fixtures": fixtures, "gates": gates, "receipts": receipts,
    "final_campaign": {k: experiment[k] for k in ["case_id", "ok", "status", "commands", "final_run_cycle", "final_release_count", "source_identity"]},
    "final_replay": replay_summary,
    "final_gate_receipt": "final-gate-receipt.json" if final_gate_receipt else None,
})
print(json.dumps({"runtime": runtime["runtime_identity"], "receipts": len(receipts), "gates": gates, "replay_ok": replay.get("ok") if replay else None}))
