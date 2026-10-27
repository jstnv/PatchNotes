"""Run the maintained two-rival verifier with simulator-style isolation."""

import argparse
import hashlib
import json
from pathlib import Path
import re
import socket
import sys

sys.path.insert(0, str(Path(__file__).resolve().parents[4]))
from tools import simulate as sim


THREAD = Path(__file__).resolve().parent
SUMMARY = re.compile(r"RIVAL_TRIAL_ACTIVATION checks=(\d+) failures=(\d+) cycles=(\d+) restore_at=(-?\d+) releases=(\d+)")


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--variant", type=Path, required=True)
    parser.add_argument("--output", type=Path, required=True)
    parser.add_argument("--godot", required=True)
    parser.add_argument("--timeout", type=float, default=180)
    args = parser.parse_args()
    variant = args.variant.resolve(strict=True)
    if variant.parent != (THREAD / "simulators").resolve() or variant.name not in {"g4-synergy-20261018-v1", "g4-synergy-20261018-v6"}:
        raise SystemExit("This verifier accepts only the two declared thread variants")
    output = args.output.resolve()
    if output.exists() or output.parent != (THREAD / "sims").resolve():
        raise SystemExit("Output must be a new directory under this thread's sims")
    output.mkdir(parents=True)
    report = {"variant": variant.name, "source": str(variant / "project"), "output": str(output), "ok": False}
    try:
        source = sim.copy_snapshot(variant / "project", output / "project")
        sim.write_json(output / "source-manifest.json", source)
        report["source_identity"] = hashlib.sha256(json.dumps(source, sort_keys=True).encode()).hexdigest()
        godot = sim.resolve_godot(args.godot)
        report["godot"] = str(godot)
        report["godot_sha256"] = sim.sha(godot)
        environment = sim.isolated_environment(output / "profile")
        with socket.socket() as reserve:
            reserve.bind(("127.0.0.1", 0))
            port = reserve.getsockname()[1]
        environment["PN_CHECKPOINT_TEST_PORT"] = str(port)
        report["checkpoint_test_port"] = port
        frozen = sim.import_project(godot, output / "project", output, environment, args.timeout)
        sim.write_json(output / "imported-source-manifest.json", frozen)
        try:
            result = sim.run_process(
                "rival-world-check",
                [str(godot), "--headless", "--path", str(output / "project"), "--script", "res://scripts/debug/verify_rival_trial_activation.gd"],
                output, environment, args.timeout,
            )
        finally:
            sim.check_snapshot(output / "project", frozen)
        log = (output / "rival-world-check.log").read_text(encoding="utf-8", errors="replace")
        match = SUMMARY.search(log)
        if match is None:
            raise RuntimeError("Rival trial summary absent")
        checks, failures, cycles, restore_at, releases = map(int, match.groups())
        report.update(checks=checks, failures=failures, cycles=cycles, restore_at=restore_at, releases=releases, elapsed_seconds=result["elapsed_seconds"])
        if failures or cycles != 20 or restore_at < 0 or releases < 1:
            raise RuntimeError("Rival-world verifier did not meet declared bounds")
        report["ok"] = True
    except Exception as error:
        report["error"] = str(error)
        raise
    finally:
        sim.write_json(output / "check-report.json", report)
        print(json.dumps({key: value for key, value in report.items() if key not in {"source", "output"}}))


if __name__ == "__main__":
    main()
