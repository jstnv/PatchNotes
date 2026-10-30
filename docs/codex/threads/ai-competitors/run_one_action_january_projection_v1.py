"""Run the private Action c72 January projection checkpoint probe."""

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


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--bundle", type=Path, required=True)
    parser.add_argument("--output", type=Path, required=True)
    parser.add_argument("--seed", choices=("5607", "5613"), required=True)
    parser.add_argument("--policy", choices=("core_shop", "core_shop_hand", "full_pool", "store_one_gap", "store_two_gaps"), required=True)
    parser.add_argument("--standard", choices=("none", "midpoint"), required=True)
    parser.add_argument("--godot", required=True)
    parser.add_argument("--replay-tape", type=Path)
    args = parser.parse_args()
    bundle = args.bundle.resolve(strict=True)
    output = args.output.resolve()
    if not bundle.is_relative_to(SIMS.resolve()) or not (bundle / "run-report.json").is_file():
        raise SystemExit("Bundle must be a retained AI runner result")
    if output.parent != SIMS.resolve() or output.exists():
        raise SystemExit("Output must be a new direct child of this thread's sims")
    tape = args.replay_tape.resolve(strict=True) if args.replay_tape else None
    if tape is not None and not tape.is_relative_to(SIMS.resolve()):
        raise SystemExit("Replay tape must belong to this thread's sims")
    expected = sim.read_json(bundle / "snapshot-manifest.json")
    sim.check_snapshot(bundle / "project", expected)
    cases = list((bundle / "cases").glob("*/result.json"))
    if len(cases) != 1:
        raise SystemExit("Expected one declared smoke case in frozen bundle")
    source = sim.read_json(cases[0])["source_identity"]
    godot = sim.resolve_godot(args.godot)
    output.mkdir(parents=False, exist_ok=False)
    report = {
        "ok": False, "mode": "one-action-core-replay" if tape else "one-action-core",
        "seed": args.seed, "policy": args.policy, "standard":args.standard, "bundle": str(bundle),
        "bundle_manifest_sha256": sim.sha(bundle / "snapshot-manifest.json"),
        "source_identity": source, "godot": str(godot), "godot_sha256": sim.sha(godot),
        "runner_sha256": sim.sha(Path(__file__)),
        "started_utc": dt.datetime.now(dt.timezone.utc).isoformat(),
        "timeout_seconds": 240,
    }
    try:
        copied = sim.copy_snapshot(bundle / "project", output / "project")
        if copied != expected:
            raise RuntimeError("Copied source differs from frozen bundle")
        environment = sim.isolated_environment(output / "profile")
        frozen = sim.import_project(godot, output / "project", output, environment, 240)
        script = output / "project/scripts/debug/one_action_prelude_probe.gd"
        result_path = output / ("replay.json" if tape else "prelude.json")
        argv = [str(godot), "--headless", "--audio-driver", "Dummy", "--path", str(output / "project"),
                "--script", str(script), "--", "--seed=" + args.seed, "--policy=" + args.policy,
                "--standard=" + args.standard, "--stop-cycle=72",
                "--output=" + str(result_path)]
        if tape is None:
            argv.append("--tape=" + str(output / "prelude.tape.json"))
        else:
            argv.append("--replay=" + str(tape))
        sim.write_json(output / "prelude.command.json", {"argv": argv, "cwd": str(output), "timeout_seconds": 240})
        started = time.monotonic()
        process = subprocess.run(argv, cwd=output, env=environment, stdout=subprocess.PIPE,
                                 stderr=subprocess.STDOUT, timeout=240, check=False)
        (output / "prelude.log").write_bytes(process.stdout)
        report["elapsed_seconds"] = time.monotonic() - started
        report["process_exit"] = process.returncode
        report["log_sha256"] = sim.sha(output / "prelude.log")
        sim.check_snapshot(output / "project", frozen)
        sim.check_snapshot(bundle / "project", expected)
        if not result_path.is_file():
            raise RuntimeError("Probe produced no report")
        result = sim.read_json(result_path)
        report["result_sha256"] = sim.sha(result_path)
        report["final_cycle"] = result.get("final_cycle")
        report["release_count"] = len(result.get("releases", []))
        report["issue"] = result.get("issue", "")
        report["replay_ok"] = result.get("replay", {}).get("ok")
        report["projection"] = result.get("projection", {})
        report["ok"] = process.returncode == 0 and result.get("source_identity") == source
    except Exception as error:
        report["error"] = str(error)
        raise
    finally:
        sim.write_json(output / "prelude-run.json", report)
        print(json.dumps(report, sort_keys=True), flush=True)


if __name__ == "__main__":
    main()
