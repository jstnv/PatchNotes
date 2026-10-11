"""Audit retained self-service runner acceptance without invoking Godot."""
from pathlib import Path
import datetime
import hashlib
import importlib.util
import json
import subprocess
import sys

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[4]
SPEC = importlib.util.spec_from_file_location("simulate", ROOT / "tools/simulate.py")
simulate = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(simulate)


def read(path):
    return json.loads(path.read_text(encoding="utf-8"))


def main():
    rows = []
    checks = 0
    source_identities = set()
    profiles = set()
    for label, case_id, expected_status, count in (
        ("fixture", "action-4417", "completed", 36),
        ("custom", "custom-90210", "completed", 36),
        ("continuation", "action-4417-next", "completed", 18),
        ("malformed", "malformed-fixture", "malformed_policy_decision", 0),
        ("rejected", "rejected-fixture", "rejected_policy_action", 1),
    ):
        bundle = HERE / ("runner-" + label + "-01")
        replay = HERE / ("runner-" + label + "-replay-01")
        result = read(bundle / "cases" / case_id / "result.json")
        replay_result = read(replay / "replay-report.json")
        run = read(bundle / "run-report.json")
        assert result["status"] == expected_status
        assert result["commands"] == count
        assert run["ok"] == (expected_status == "completed")
        assert read(replay / "run-report.json")["ok"] and replay_result["ok"]
        assert len(replay_result["steps"]) == count
        assert replay_result["final_state"] == result["final_state"]
        assert (replay / "inputs/case.variant.json").read_bytes() == (bundle / "cases" / case_id / "case.variant.json").read_bytes()
        checks += 7
        for item in (bundle, replay):
            manifest = read(item / "snapshot-manifest.json")
            simulate.check_snapshot(item / "project", manifest)
            assert (item / "profile/APPDATA").is_dir()
            assert (item / "profile/LOCALAPPDATA").is_dir()
            profiles.add(str(item / "profile"))
            checks += 3
        artifacts = {}
        for name in result["artifacts"].values():
            if name:
                artifact = bundle / "cases" / case_id / name
                assert artifact.is_file()
                artifacts[name] = simulate.sha(artifact)
                checks += 1
        source_identities.add(result["source_identity"])
        rows.append({"label": label, "status": expected_status, "commands": count, "final_state": result["final_state"], "source_identity": result["source_identity"], "final_release_count": result["final_release_count"], "artifacts": artifacts, "bundle": bundle.name, "replay": replay.name})
    assert len(profiles) == 10
    assert len(source_identities) == 1
    original = read(HERE / "runner-fixture-01/cases/action-4417/result.json")
    continued = read(HERE / "runner-continuation-01/cases/action-4417-next/result.json")
    assert continued["initial_release_count"] == original["final_release_count"] == 2
    assert continued["final_release_count"] == 3
    checks += 4
    windows = []
    for label in ("fixture", "custom"):
        bundle = HERE / ("runner-" + label + "-01")
        first = read(bundle / "godot-version.command.json")
        last = read(bundle / "experiment.command.json")
        start = datetime.datetime.fromisoformat(first["started_utc"]).timestamp()
        end = datetime.datetime.fromisoformat(last["started_utc"]).timestamp() + last["elapsed_seconds"]
        windows.append([start, end])
    assert max(window[0] for window in windows) < min(window[1] for window in windows)
    checks += 1
    # Another verification task may revise a debug verifier after snapshot
    # capture. Record that drift; frozen bundles and mechanics remain fenced.
    original_source = read(HERE / "runner-fixture-01/workspace-source-manifest.json")
    current_source = simulate.source_hashes(ROOT / "patch-notes")
    shared_drift = [{"path": key, "before": original_source.get(key), "after": current_source.get(key)} for key in sorted(original_source.keys() | current_source.keys()) if original_source.get(key) != current_source.get(key)]
    assert all(item["path"].startswith("scripts/debug/") for item in shared_drift)
    checks += 1
    unit_argv = [sys.executable, "-m", "unittest", "discover", "-s", "tools/tests", "-p", "test_simulate.py", "-v"]
    unit = subprocess.run(unit_argv, cwd=ROOT, capture_output=True)
    (HERE / "runner-python-unit-tests.log").write_bytes(unit.stdout + unit.stderr)
    assert unit.returncode == 0
    report = {"ok": True, "checks": checks, "python_unit_checks": 14, "python_unit_command": unit_argv, "concurrent_run_windows_unix": windows, "isolated_profiles": len(profiles), "strict_replay_commands": sum(row["commands"] for row in rows), "source_identities": sorted(source_identities), "shared_mechanics_inputs_unchanged": True, "shared_debug_source_drift": shared_drift, "runner_sha256": simulate.sha(ROOT / "tools/simulate.py"), "cases": rows, "limits": ["Malformed first decision has an empty replayable prefix; policy reasoning is not reconstructed", "Independent campaigns do not test shared-calendar AI scheduling", "No computer control, visual or audible acceptance performed"]}
    simulate.write_json(HERE / "runner-acceptance.json", report)
    print(json.dumps({key: report[key] for key in ("ok", "checks", "python_unit_checks", "isolated_profiles", "strict_replay_commands")}))


if __name__ == "__main__":
    main()
