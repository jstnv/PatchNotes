"""Run the private January prestart normalization gate from a frozen simulator bundle."""

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
    parser.add_argument("--godot", required=True)
    parser.add_argument("--seed", choices=("4417", "4418"), required=True)
    args = parser.parse_args()
    bundle = args.bundle.resolve(strict=True)
    output = args.output.resolve()
    if not bundle.is_relative_to(SIMS.resolve()) or not (bundle / "run-report.json").is_file():
        raise SystemExit("Bundle must be a retained ai-competitors simulator run")
    if output.parent != SIMS.resolve() or output.exists():
        raise SystemExit("Output must be a new direct child of this thread's sims")
    expected = sim.read_json(bundle / "snapshot-manifest.json")
    sim.check_snapshot(bundle / "project", expected)
    source = sim.read_json(bundle / "cases/foundation-legal-action-4417/result.json")["source_identity"]
    godot = sim.resolve_godot(args.godot)
    output.mkdir(parents=False, exist_ok=False)
    report = {
        "ok": False, "mode": "opening-prestart-normalization-gate-v1", "seed": args.seed,
        "bundle": str(bundle), "bundle_manifest_sha256": sim.sha(bundle / "snapshot-manifest.json"),
        "source_identity": source, "godot": str(godot), "godot_sha256": sim.sha(godot),
        "runner_sha256": sim.sha(Path(__file__)), "started_utc": dt.datetime.now(dt.timezone.utc).isoformat(),
        "timeout_seconds": 240,
    }
    try:
        copied = sim.copy_snapshot(bundle / "project", output / "project")
        if copied != expected:
            raise RuntimeError("Copied source differs from frozen bundle")
        environment = sim.isolated_environment(output / "profile")
        frozen = sim.import_project(godot, output / "project", output, environment, 240)
        probe = output / "project/scripts/debug/opening_prestart_normalization_gate.gd"
        result_path = output / "prestart-normalization-gate.json"
        argv = [str(godot), "--headless", "--audio-driver", "Dummy", "--path", str(output / "project"),
                "--script", str(probe), "--", "--seed=" + args.seed, "--output=" + str(result_path)]
        sim.write_json(output / "prestart-normalization-gate.command.json", {"argv": argv, "cwd": str(output), "timeout_seconds": 240})
        started = time.monotonic()
        process = subprocess.run(argv, cwd=output, env=environment, stdout=subprocess.PIPE,
                                 stderr=subprocess.STDOUT, timeout=240, check=False)
        (output / "prestart-normalization-gate.log").write_bytes(process.stdout)
        report["elapsed_seconds"] = time.monotonic() - started
        report["process_exit"] = process.returncode
        report["log_sha256"] = sim.sha(output / "prestart-normalization-gate.log")
        sim.check_snapshot(output / "project", frozen)
        sim.check_snapshot(bundle / "project", expected)
        if process.returncode != 0 or not result_path.is_file():
            raise RuntimeError("Probe process failed or produced no report")
        result = sim.read_json(result_path)
        if result.get("source_identity") != source or result.get("seed") != args.seed or result.get("failures"):
            raise RuntimeError("Probe source, seed or checks failed")
        report["result_sha256"] = sim.sha(result_path)
        report["legal_begin_accepted"] = result["action"]["ok"]
        report["source_unchanged"] = result["source_unchanged"]
        report["cycle_only_validation"] = result["cycle_only_validation"]
        report["cycle_and_finance_validation"] = result["cycle_and_finance_validation"]
        report["ok"] = True
    except Exception as error:
        report["error"] = str(error)
        raise
    finally:
        sim.write_json(output / "prestart-normalization-gate-run.json", report)
        print(json.dumps(report, sort_keys=True), flush=True)


if __name__ == "__main__":
    main()

