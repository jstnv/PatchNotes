"""Measure eight legal rival sessions on a frozen, isolated simulator bundle."""
from __future__ import annotations

import argparse
import hashlib
import importlib.util
import json
import math
import statistics
from pathlib import Path


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--bundle", type=Path, required=True)
    parser.add_argument("--output", type=Path, required=True)
    parser.add_argument("--godot", required=True)
    parser.add_argument("--timeout", type=float, default=240)
    args = parser.parse_args()

    output = args.output.resolve()
    if output.exists():
        raise SystemExit("Output folder already exists")
    bundle = args.bundle.resolve()
    project = bundle / "project"
    if not (project / "project.godot").is_file():
        raise SystemExit("Frozen simulator project missing")
    output.mkdir(parents=True)

    script = Path(__file__).with_name("verify_g4_eight_rival_cpu_v1.gd").resolve()
    repo = Path(__file__).resolve().parents[4]
    spec = importlib.util.spec_from_file_location("patch_notes_simulate", repo / "tools" / "simulate.py")
    assert spec and spec.loader
    sim = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(sim)

    before = sim.source_hashes(project)
    report_path = output / "world-cpu-report.json"
    environment = sim.isolated_environment(output / "profile")
    environment["PN_G4_WORLD_CPU_REPORT"] = str(report_path)
    summary = {
        "schema_version": "1",
        "bundle": str(bundle),
        "script": str(script),
        "script_sha256": hashlib.sha256(script.read_bytes()).hexdigest(),
        "limit": "eight rivals, twelve cycles, 180-second internal and requested external timeout",
        "ok": False,
    }

    try:
        command = sim.run_process(
            "g4-eight-rival-cpu",
            [str(sim.resolve_godot(args.godot)), "--headless", "--path", str(project), "--script", str(script)],
            output,
            environment,
            args.timeout,
        )
        summary["process_exit"] = command["exit"]
        summary["process_elapsed_seconds"] = command["elapsed_seconds"]
        if not report_path.is_file():
            raise RuntimeError("Godot did not write world-cpu-report.json")
        report = json.loads(report_path.read_text(encoding="utf-8"))
        rows = report.get("cycles", [])
        if not report.get("ok") or report.get("rival_count") != 8 or len(rows) != 12:
            raise RuntimeError("Incomplete or failed eight-rival report")
        timings = sorted(int(row["world_advance_elapsed_us"]) for row in rows)
        summary["timing"] = {
            "measurement": "in-process elapsed time, excluding player action, state digests and save capture",
            "samples": len(timings),
            "total_us": sum(timings),
            "median_us": statistics.median(timings),
            "p95_nearest_rank_us": timings[math.ceil(0.95 * len(timings)) - 1],
            "max_us": timings[-1],
        }
        summary["final_state_digest"] = report["final_state_digest"]
        summary["final_rng_digest"] = report["final_rng_digest"]
        summary["release_count"] = len(report["final_live_releases"])
        summary["world_payload_json_utf8_bytes"] = report.get("world_payload_json_utf8_bytes")
        summary["peak_static_bytes"] = report.get("peak_static_bytes")
        summary["ok"] = True
    except Exception as exc:
        summary["error"] = str(exc)
    finally:
        try:
            sim.check_snapshot(project, before)
            summary["project_source_unchanged"] = True
        except Exception as exc:
            summary["project_source_unchanged"] = False
            summary["source_error"] = str(exc)
            summary["ok"] = False
        (output / "result.json").write_text(json.dumps(summary, indent=2), encoding="utf-8")

    print(json.dumps(summary))
    return 0 if summary["ok"] else 1


if __name__ == "__main__":
    raise SystemExit(main())
