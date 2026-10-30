"""Run one legal interleaved player/rival world from a frozen simulator bundle.

This is intentionally separate from simulate.py's independent-Studio campaign
runner. It reuses that runner's snapshot, import and isolated-profile helpers.
Each invocation makes a new source copy and retains every failed output.
"""

from __future__ import annotations

import argparse
import ctypes
from ctypes import wintypes
import datetime as dt
import json
import os
from pathlib import Path
import socket
import subprocess
import sys
import time


STUDY = Path(__file__).resolve().parent
THREAD = STUDY.parent
SIMS = THREAD / "sims"
ROOT = STUDY.parents[4]
sys.path.insert(0, str(ROOT))
from tools import simulate as sim  # noqa: E402


HARD_TIMEOUT_SECONDS = 480
HARNESS = STUDY / "world_study.gd"
ALLOWED = {("action-fantasy", "4417"), ("action-fantasy", "4418")}


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--bundle", type=Path, required=True,
                        help="completed simulate.py run --variant output")
    parser.add_argument("--output", type=Path, required=True,
                        help="new directory immediately under this thread's sims/")
    parser.add_argument("--godot", required=True)
    parser.add_argument("--source", required=True,
                        help="exact DevelopmentReplay.source_identity() from this bundle")
    parser.add_argument("--route", choices=("action-fantasy",), required=True)
    parser.add_argument("--seed", choices=("4417", "4418"), required=True)
    parser.add_argument("--arm", choices=("A", "B", "C"), required=True)
    parser.add_argument("--candidate", choices=(0, 1), type=int, required=True)
    mode = parser.add_mutually_exclusive_group()
    mode.add_argument("--replay-input", type=Path,
                      help="record tape from a prior output in this thread's sims/")
    mode.add_argument("--restore-input", type=Path,
                      help="completed Studio player/world checkpoint from a prior output")
    return parser.parse_args()


def filetime_seconds(value: wintypes.FILETIME) -> float:
    return ((value.dwHighDateTime << 32) + value.dwLowDateTime) / 10_000_000


def process_cpu_seconds(process: subprocess.Popen[bytes]) -> float | None:
    if os.name != "nt":
        return None
    times = [wintypes.FILETIME() for _ in range(4)]
    ok = ctypes.windll.kernel32.GetProcessTimes(
        wintypes.HANDLE(int(process._handle)),
        *(ctypes.byref(value) for value in times),
    )
    return filetime_seconds(times[2]) + filetime_seconds(times[3]) if ok else None


def measured_world(argv: list[str], output: Path, environment: dict[str, str]) -> dict:
    command_path = output / "world.command.json"
    log_path = output / "world.log"
    report = {"argv": argv, "cwd": str(output), "timeout_seconds": HARD_TIMEOUT_SECONDS,
              "started_utc": dt.datetime.now(dt.timezone.utc).isoformat(), "headless": True}
    sim.write_json(command_path, report)
    flags = subprocess.CREATE_NO_WINDOW if os.name == "nt" else 0
    started = time.monotonic()
    process = subprocess.Popen(argv, cwd=output, env=environment,
                               stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
                               creationflags=flags)
    timed_out = False
    try:
        data, _ = process.communicate(timeout=HARD_TIMEOUT_SECONDS)
    except subprocess.TimeoutExpired:
        timed_out = True
        process.kill()
        data, _ = process.communicate()
    elapsed = time.monotonic() - started
    cpu = process_cpu_seconds(process)
    log_path.write_bytes(data)
    lines = data.decode("utf-8", errors="replace").splitlines()
    errors = [line for line in lines if any(marker in line for marker in
              ("SCRIPT ERROR", "Parse Error", "FAIL:", "Assertion failed"))
              or line.startswith("ERROR:")]
    ignored = [line for line in errors if "root certificate store" in line]
    errors = [line for line in errors if line not in ignored]
    report.update(exit=process.returncode, timed_out=timed_out,
                  elapsed_seconds=elapsed, actual_process_cpu_seconds=cpu,
                  errors=errors, ignored_environment_errors=ignored,
                  log_sha256=sim.sha(log_path))
    sim.write_json(command_path, report)
    if timed_out or process.returncode != 0 or errors:
        raise RuntimeError("World process failed; retained world.log and world.command.json")
    return report


def main() -> None:
    args = parse_args()
    if (args.route, args.seed) not in ALLOWED:
        raise SystemExit("Route/seed pair was not predeclared")
    if len(args.source) != 64 or any(char not in "0123456789abcdef" for char in args.source):
        raise SystemExit("--source must be an explicit lowercase SHA-256 identity")
    bundle = args.bundle.resolve(strict=True)
    output = args.output.resolve()
    if not bundle.is_relative_to(SIMS.resolve()) or not (bundle / "run-report.json").is_file():
        raise SystemExit("--bundle must be a retained simulate.py output in this thread's sims/")
    if output.parent != SIMS.resolve() or output.exists():
        raise SystemExit("--output must be a new direct child of this thread's sims/")
    replay_input = args.replay_input.resolve(strict=True) if args.replay_input else None
    restore_input = args.restore_input.resolve(strict=True) if args.restore_input else None
    selected_input = replay_input or restore_input
    if selected_input is not None and not selected_input.is_relative_to(SIMS.resolve()):
        raise SystemExit("Replay tape or checkpoint must belong to this thread's sims/")
    expected = sim.read_json(bundle / "snapshot-manifest.json")
    if not isinstance(expected, dict) or not expected:
        raise SystemExit("Simulator bundle lacks its frozen source manifest")
    case_results = [sim.read_json(path) for path in sorted((bundle / "cases").glob("*/result.json"))]
    case_sources = {item.get("source_identity") for item in case_results if isinstance(item, dict)}
    if case_sources != {args.source}:
        raise SystemExit("--source does not match every retained simulator case identity")
    sim.check_snapshot(bundle / "project", expected)
    godot = sim.resolve_godot(args.godot)
    output.mkdir(parents=False, exist_ok=False)
    report = {"ok": False, "mode": "replay" if replay_input else "restore" if restore_input else "record",
              "route": args.route, "seed": args.seed, "arm": args.arm, "candidate": bool(args.candidate),
              "bundle": str(bundle), "bundle_run_report_sha256": sim.sha(bundle / "run-report.json"),
              "bundle_snapshot_manifest_sha256": sim.sha(bundle / "snapshot-manifest.json"),
              "expected_gameplay_source_identity": args.source,
              "godot": str(godot), "godot_sha256": sim.sha(godot),
              "runner_sha256": sim.sha(Path(__file__)), "harness_sha256": sim.sha(HARNESS),
              "replay_input": str(replay_input) if replay_input else None,
              "replay_input_sha256": sim.sha(replay_input) if replay_input else None,
              "restore_input": str(restore_input) if restore_input else None,
              "restore_input_sha256": sim.sha(restore_input) if restore_input else None,
              "hard_timeout_seconds": HARD_TIMEOUT_SECONDS}
    try:
        copied = sim.copy_snapshot(bundle / "project", output / "project")
        if copied != expected:
            raise RuntimeError("Copied frozen project differs from bundle's source manifest")
        sim.write_json(output / "bundle-source-manifest.json", copied)
        environment = sim.isolated_environment(output / "profile")
        with socket.socket() as reserve:
            reserve.bind(("127.0.0.1", 0))
            port = reserve.getsockname()[1]
        environment["PN_CHECKPOINT_TEST_PORT"] = str(port)
        report["checkpoint_test_port"] = port
        frozen = sim.import_project(godot, output / "project", output, environment,
                                    HARD_TIMEOUT_SECONDS)
        report["imported_source_manifest_sha256"] = sim.sha(output / "snapshot-manifest.json")
        result_path = output / "world-report.json"
        argv = [str(godot), "--headless", "--audio-driver", "Dummy", "--path",
                str(output / "project"), "--script", str(HARNESS), "--",
                "--output=" + str(result_path), "--route=" + args.route,
                "--seed=" + args.seed, "--source=" + args.source,
                "--candidate=" + str(args.candidate), "--arm=" + args.arm]
        if replay_input is not None:
            argv.extend(("--mode=replay", "--input=" + str(replay_input)))
        elif restore_input is not None:
            argv.extend(("--mode=restore", "--input=" + str(restore_input)))
        try:
            report["world_process"] = measured_world(argv, output, environment)
        finally:
            sim.check_snapshot(output / "project", frozen)
            sim.check_snapshot(bundle / "project", expected)
        if not result_path.is_file():
            raise RuntimeError("World process did not produce its study report")
        result = sim.read_json(result_path)
        if not isinstance(result, dict) or result.get("failures") != 0 or result.get("source_drift"):
            raise RuntimeError("World study reported failures or source drift")
        if result.get("source_identity") != args.source or result.get("candidate_mode") != bool(args.candidate) or result.get("arm") != args.arm:
            raise RuntimeError("World study source or arm differs from runner request")
        if replay_input is None and not result.get("completed"):
            raise RuntimeError("World study stopped before its legal release target")
        report["study_report_sha256"] = sim.sha(result_path)
        tape = Path(str(result_path) + ".tape.json")
        if replay_input is None and restore_input is None:
            if not tape.is_file():
                raise RuntimeError("Successful world record lacks exact tape")
            report["tape_sha256"] = sim.sha(tape)
        checkpoint = Path(str(result_path) + ".checkpoint.json")
        if checkpoint.is_file():
            report["checkpoint_sha256"] = sim.sha(checkpoint)
        report["checks"] = result.get("checks")
        report["commands"] = result.get("commands")
        report["initial_state_digest"] = result.get("initial_state_digest")
        report["ok"] = True
    except Exception as error:
        report["error"] = str(error)
        raise
    finally:
        sim.write_json(output / "world-run.json", report)
        print(json.dumps({key: value for key, value in report.items()
                          if key not in ("world_process",)}, sort_keys=True), flush=True)


if __name__ == "__main__":
    main()
