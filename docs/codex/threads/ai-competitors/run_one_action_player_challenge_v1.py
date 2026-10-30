"""Run paired legal player projects from frozen source-matched world fixtures."""

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
    p.add_argument("--control-fixture", type=Path, required=True)
    p.add_argument("--market-fixture", type=Path, required=True)
    p.add_argument("--output", type=Path, required=True)
    p.add_argument("--godot", required=True)
    args = p.parse_args()
    bundle = args.bundle.resolve(strict=True)
    control = args.control_fixture.resolve(strict=True)
    market = args.market_fixture.resolve(strict=True)
    output = args.output.resolve()
    if not bundle.is_relative_to(SIMS.resolve()) or not (bundle / "run-report.json").is_file():
        raise SystemExit("Bundle must be a retained AI runner result")
    if not control.is_relative_to(SIMS.resolve()) or not market.is_relative_to(SIMS.resolve()):
        raise SystemExit("Fixtures must be retained AI simulator outputs")
    if output.parent != SIMS.resolve() or output.exists():
        raise SystemExit("Output must be a fresh direct child of AI sims")
    expected = sim.read_json(bundle / "snapshot-manifest.json")
    sim.check_snapshot(bundle / "project", expected)
    cases = list((bundle / "cases").glob("*/result.json"))
    if len(cases) != 1:
        raise SystemExit("Expected one smoke case")
    source = sim.read_json(cases[0])["source_identity"]
    if any(sim.read_json(path).get("source_identity") != source for path in (control, market)):
        raise SystemExit("Fixture and frozen bundle source identities differ")
    godot = sim.resolve_godot(args.godot)
    output.mkdir(parents=False, exist_ok=False)
    report = {"ok": False, "bundle": str(bundle), "control_fixture": str(control), "market_fixture": str(market),
              "control_fixture_sha256": sim.sha(control), "market_fixture_sha256": sim.sha(market),
              "bundle_manifest_sha256": sim.sha(bundle / "snapshot-manifest.json"), "source_identity": source,
              "godot": str(godot), "godot_sha256": sim.sha(godot), "runner_sha256": sim.sha(Path(__file__)),
              "started_utc": dt.datetime.now(dt.timezone.utc).isoformat(), "timeout_seconds": 240}
    try:
        copied = sim.copy_snapshot(bundle / "project", output / "project")
        if copied != expected:
            raise RuntimeError("Copied source differs from frozen bundle")
        environment = sim.isolated_environment(output / "profile")
        frozen = sim.import_project(godot, output / "project", output, environment, 240)
        script = output / "project/scripts/debug/one_action_player_challenge_probe.gd"
        result_path = output / "player-challenge.json"
        argv = [str(godot), "--headless", "--audio-driver", "Dummy", "--path", str(output / "project"),
                "--script", str(script), "--", "--control-fixture=" + str(control),
                "--market-fixture=" + str(market), "--output=" + str(result_path)]
        sim.write_json(output / "player-challenge.command.json", {"argv": argv, "cwd": str(output), "timeout_seconds": 240})
        started = time.monotonic()
        process = subprocess.run(argv, cwd=output, env=environment, stdout=subprocess.PIPE,
                                 stderr=subprocess.STDOUT, timeout=240, check=False)
        (output / "player-challenge.log").write_bytes(process.stdout)
        report["elapsed_seconds"] = time.monotonic() - started
        report["process_exit"] = process.returncode
        report["log_sha256"] = sim.sha(output / "player-challenge.log")
        sim.check_snapshot(output / "project", frozen)
        sim.check_snapshot(bundle / "project", expected)
        if not result_path.is_file():
            raise RuntimeError("Probe produced no report")
        result = sim.read_json(result_path)
        report["result_sha256"] = sim.sha(result_path)
        report["result"] = result
        report["ok"] = process.returncode == 0 and result.get("source_identity") == source and result.get("ok", False)
    except Exception as error:
        report["error"] = str(error)
        raise
    finally:
        sim.write_json(output / "player-challenge-run.json", report)
        print(json.dumps({k: v for k, v in report.items() if k != "result"}, sort_keys=True), flush=True)
    if not report["ok"]:
        raise SystemExit(1)


if __name__ == "__main__":
    main()
