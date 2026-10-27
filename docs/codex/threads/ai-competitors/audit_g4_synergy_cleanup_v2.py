"""Compare cleaned v6 against the measured v5 without bypassing source fences."""

import argparse
import json
from pathlib import Path


def read(path: Path) -> dict:
    return json.loads(path.read_text(encoding="utf-8"))


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--previous", type=Path, required=True)
    parser.add_argument("--current", type=Path, required=True)
    parser.add_argument("--output", type=Path, required=True)
    args = parser.parse_args()
    if args.output.exists():
        raise SystemExit(f"Refusing to overwrite {args.output}")
    ids = [f"{genre}-{seed}-{mode}" for genre in ("action", "adventure", "puzzle", "sports") for seed in ("4417", "90210") for mode in ("reference", "synergy", "synergy_beta")]
    checks = []
    for case_id in ids:
        old = read(args.previous / "cases" / case_id / "result.json")
        new = read(args.current / "cases" / case_id / "result.json")
        old_t = read(args.previous / "cases" / case_id / "telemetry.json")
        new_t = read(args.current / "cases" / case_id / "telemetry.json")
        checks.append((f"{case_id} completed", old["ok"] and new["ok"] and old["final_release_count"] == new["final_release_count"] == 1))
        for field in ("initial_state", "initial_rng", "final_state", "final_rng", "outcome", "accepted_commands", "final_run_cycle"):
            checks.append((f"{case_id} {field}", old[field] == new[field]))
        # Each telemetry document also pins its own source identity, which must
        # differ across private versions. Compare the actual steps and requests.
        checks.append((f"{case_id} source identities differ", old_t["source_identity"] != new_t["source_identity"]))
        checks.append((f"{case_id} exact command/step telemetry", old_t["samples"] == new_t["samples"] and old_t["sampling"] == new_t["sampling"]))
    report = {"checks_passed": sum(ok for _, ok in checks), "checks_total": len(checks), "failures": [label for label, ok in checks if not ok], "cases": len(ids)}
    args.output.mkdir(parents=True)
    (args.output / "audit.json").write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
    (args.output / "audit.md").write_text(f"# G4 cleanup parity\n\nChecks: {report['checks_passed']}/{report['checks_total']} across {len(ids)} first-release routes.\n\nFailures: {', '.join(report['failures']) or 'none'}.\n", encoding="utf-8")
    print(json.dumps(report))
    if report["failures"]:
        raise SystemExit(1)


if __name__ == "__main__":
    main()
