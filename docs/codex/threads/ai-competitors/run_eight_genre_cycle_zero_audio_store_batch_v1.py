"""Run declared independent 1977 specialist careers from one frozen runner bundle."""

from __future__ import annotations

import argparse
import datetime as dt
import json
from pathlib import Path
import subprocess
import sys
import time

THREAD = Path(__file__).resolve().parent
SIMS = THREAD / "sims"
ROOT = THREAD.parents[3]
sys.path.insert(0, str(ROOT))
from tools import simulate as sim  # noqa: E402

GENRES = ("action", "adventure", "role_playing", "strategy", "simulation", "puzzle", "sports", "racing")
SEEDS = ("5607", "5613")
TIMEOUT = 240


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--bundle", type=Path, required=True)
    parser.add_argument("--output", type=Path, required=True)
    parser.add_argument("--godot", required=True)
    args = parser.parse_args()
    bundle = args.bundle.resolve(strict=True)
    output = args.output.resolve()
    if not bundle.is_relative_to(SIMS.resolve()) or not (bundle / "run-report.json").is_file():
        raise SystemExit("Expected a retained AI isolated-runner bundle")
    if output.parent != SIMS.resolve() or output.exists():
        raise SystemExit("Output must be a new direct child of this thread's sims")
    expected = sim.read_json(bundle / "snapshot-manifest.json")
    sim.check_snapshot(bundle / "project", expected)
    godot = sim.resolve_godot(args.godot)
    output.mkdir(parents=False, exist_ok=False)
    report = {
        "ok": False, "mode": "eight-independent-specialty-1977-prelude",
        "bundle": str(bundle), "bundle_manifest_sha256": sim.sha(bundle / "snapshot-manifest.json"),
        "godot": str(godot), "godot_sha256": sim.sha(godot),
        "runner_sha256": sim.sha(Path(__file__)),
        "started_utc": dt.datetime.now(dt.timezone.utc).isoformat(),
        "policy": "audio_path", "standard": "midpoint", "stop_cycle": 72,
        "max_commands": 340, "per_process_timeout_seconds": TIMEOUT,
        "cases": [],
    }
    try:
        copied = sim.copy_snapshot(bundle / "project", output / "project")
        if copied != expected:
            raise RuntimeError("Copied source differs from frozen runner bundle")
        import_environment = sim.isolated_environment(output / "import-profile")
        frozen = sim.import_project(godot, output / "project", output, import_environment, TIMEOUT)
        script = output / "project/scripts/debug/one_action_prelude_probe.gd"
        for seed in SEEDS:
            for genre in GENRES:
                case_id = genre + "-" + seed
                case_dir = output / "cases" / case_id
                case_dir.mkdir(parents=True, exist_ok=False)
                environment = sim.isolated_environment(case_dir / "profile")
                result_path = case_dir / "prelude.json"
                tape_path = case_dir / "prelude.tape.json"
                argv = [str(godot), "--headless", "--audio-driver", "Dummy", "--path", str(output / "project"),
                        "--script", str(script), "--", "--seed=" + seed, "--genre=" + genre,
                        "--policy=audio_path", "--standard=midpoint", "--stop-cycle=72",
                        "--output=" + str(result_path), "--tape=" + str(tape_path)]
                sim.write_json(case_dir / "command.json", {"argv": argv, "cwd": str(case_dir), "timeout_seconds": TIMEOUT})
                case = {"case_id": case_id, "seed": seed, "genre": genre, "ok": False}
                started = time.monotonic()
                try:
                    process = subprocess.run(argv, cwd=case_dir, env=environment, stdout=subprocess.PIPE,
                                             stderr=subprocess.STDOUT, timeout=TIMEOUT, check=False)
                    (case_dir / "godot.log").write_bytes(process.stdout)
                    case["process_exit"] = process.returncode
                    case["elapsed_seconds"] = time.monotonic() - started
                    case["log_sha256"] = sim.sha(case_dir / "godot.log")
                    if result_path.is_file():
                        result = sim.read_json(result_path)
                        case["result_sha256"] = sim.sha(result_path)
                        case["source_identity"] = result.get("source_identity")
                        case["final_cycle"] = result.get("final_cycle")
                        case["issue"] = result.get("issue")
                        case["release_count"] = len(result.get("releases", []))
                        case["tape_saved"] = result.get("tape_saved")
                        case["source_checks"] = result.get("source_checks", {})
                        case["ok"] = (process.returncode == 0 and result.get("genre") == genre
                                      and result.get("final_cycle") == 72 and not result.get("issue")
                                      and result.get("tape_saved") is True)
                    else:
                        case["error"] = "Probe produced no result file"
                except subprocess.TimeoutExpired as error:
                    (case_dir / "godot.log").write_bytes(error.stdout or b"")
                    case.update(error="timeout", elapsed_seconds=time.monotonic() - started)
                except Exception as error:
                    case["error"] = str(error)
                sim.check_snapshot(output / "project", frozen)
                sim.write_json(case_dir / "case-report.json", case)
                report["cases"].append(case)
                sim.write_json(output / "batch-report.json", report)
                print(json.dumps({key: case.get(key) for key in ("case_id", "ok", "final_cycle", "release_count", "issue", "error")}, sort_keys=True), flush=True)
        sim.check_snapshot(bundle / "project", expected)
        report["ok"] = all(case["ok"] for case in report["cases"])
    except Exception as error:
        report["error"] = str(error)
        raise
    finally:
        report["finished_utc"] = dt.datetime.now(dt.timezone.utc).isoformat()
        sim.write_json(output / "batch-report.json", report)
        print(json.dumps({"ok": report["ok"], "case_count": len(report["cases"]), "error": report.get("error")}, sort_keys=True), flush=True)


if __name__ == "__main__":
    main()
