"""Probe cycle-zero rival archive and Market Browser from a frozen bundle."""

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
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument("--bundle", type=Path, required=True)
    p.add_argument("--output", type=Path, required=True)
    p.add_argument("--godot", required=True)
    args = p.parse_args()
    bundle = args.bundle.resolve(strict=True)
    output = args.output.resolve()
    if not bundle.is_relative_to(SIMS.resolve()) or not (bundle / "run-report.json").is_file():
        raise SystemExit("Bundle must be a retained AI isolated runner output")
    if output.parent != SIMS.resolve() or output.exists():
        raise SystemExit("Output must be a new direct child of AI sims")
    source_report = sim.read_json(bundle / "run-report.json")
    cases = list((bundle / "cases").glob("*/result.json"))
    if len(cases) != 2:
        raise SystemExit("Expected two frozen source-freeze cases")
    sources = {sim.read_json(case).get("source_identity") for case in cases}
    if len(sources) != 1 or not isinstance(next(iter(sources)), str) or not next(iter(sources)):
        raise SystemExit("Frozen bundle has no shared gameplay source identity")
    source = next(iter(sources))
    expected = sim.read_json(bundle / "snapshot-manifest.json")
    sim.check_snapshot(bundle / "project", expected)
    godot = sim.resolve_godot(args.godot)
    output.mkdir(parents=False, exist_ok=False)
    report = {"ok": False, "bundle": str(bundle), "bundle_manifest_sha256": sim.sha(bundle / "snapshot-manifest.json"),
              "runner_snapshot_identity": source_report.get("frozen_source_identity"),
              "source_identity": source, "godot": str(godot), "godot_sha256": sim.sha(godot),
              "runner_sha256": sim.sha(Path(__file__)), "started_utc": dt.datetime.now(dt.timezone.utc).isoformat(),
              "timeout_seconds": 240}
    try:
        copied = sim.copy_snapshot(bundle / "project", output / "project")
        if copied != expected:
            raise RuntimeError("Copied source differs from frozen bundle")
        environment = sim.isolated_environment(output / "profile")
        frozen = sim.import_project(godot, output / "project", output, environment, 240)
        script = output / "project/scripts/debug/opening_rival_review_census_probe.gd"
        result_path = output / "opening-rival-reviews.json"
        argv = [str(godot), "--headless", "--audio-driver", "Dummy", "--path", str(output / "project"),
                "--script", str(script), "--", "--output=" + str(result_path)]
        sim.write_json(output / "opening-rival-reviews.command.json", {"argv": argv, "cwd": str(output), "timeout_seconds": 240})
        started = time.monotonic()
        process = subprocess.run(argv, cwd=output, env=environment, stdout=subprocess.PIPE,
                                 stderr=subprocess.STDOUT, timeout=240, check=False)
        (output / "opening-rival-reviews.log").write_bytes(process.stdout)
        log_text = process.stdout.decode("utf-8", errors="replace")
        log_errors = [line for line in log_text.splitlines()
                      if "SCRIPT ERROR" in line or "Parse Error" in line or line.lstrip().startswith("ERROR:")]
        report["elapsed_seconds"] = time.monotonic() - started
        report["process_exit"] = process.returncode
        report["log_sha256"] = sim.sha(output / "opening-rival-reviews.log")
        report["log_errors"] = log_errors
        sim.check_snapshot(output / "project", frozen)
        sim.check_snapshot(bundle / "project", expected)
        if not result_path.is_file():
            raise RuntimeError("Probe produced no report")
        result = sim.read_json(result_path)
        report["result_sha256"] = sim.sha(result_path)
        report["result"] = result
        report["ok"] = process.returncode == 0 and not log_errors and result.get("source_identity") == source and result.get("ok", False)
    except Exception as error:
        report["error"] = str(error)
        raise
    finally:
        sim.write_json(output / "opening-rival-reviews-run.json", report)
        print(json.dumps({k: v for k, v in report.items() if k != "result"}, sort_keys=True), flush=True)
    if not report["ok"]:
        raise SystemExit(1)


if __name__ == "__main__":
    main()
