"""Check source-compatible Studio continuations and second releases."""

import argparse
import json
from pathlib import Path


def load(path: Path) -> dict:
    return json.loads(path.read_text(encoding="utf-8"))


def release(result: dict, index: int) -> dict:
    return result["outcome"]["releases"][index]["metadata"]["review"]


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--first", type=Path, required=True)
    parser.add_argument("--second", type=Path, required=True)
    parser.add_argument("--output", type=Path, required=True)
    args = parser.parse_args()
    if args.output.exists():
        raise SystemExit(f"Refusing to overwrite {args.output}")
    checks = []
    rows = []
    for genre in ("adventure", "puzzle"):
        for mode in ("reference", "synergy", "synergy_beta"):
            first = load(args.first / "cases" / f"{genre}-4417-{mode}" / "result.json")
            second = load(args.second / "cases" / f"{genre}-4417-{mode}-second" / "result.json")
            checks += [
                (f"{genre}/{mode} completed", first["ok"] and second["ok"] and second["final_release_count"] == 2),
                (f"{genre}/{mode} state boundary", first["final_state"] == second["initial_state"]),
                (f"{genre}/{mode} RNG boundary", first["final_rng"] == second["initial_rng"]),
                (f"{genre}/{mode} same source", first["source_identity"] == second["source_identity"]),
                (f"{genre}/{mode} first Review frozen", release(first, 0)["final_review"] == release(second, 0)["final_review"]),
                (f"{genre}/{mode} no rejection", second.get("rejected_commands", 0) == 0),
            ]
            first_sales = second["outcome"]["releases"][0]["sales"]
            rows.append({
                "genre": genre,
                "mode": mode,
                "first_review": release(second, 0)["final_review"],
                "second_review": release(second, 1)["final_review"],
                "second_core": release(second, 1)["cores"],
                "second_scope": release(second, 1)["scope"],
                "second_bugs": release(second, 1)["remaining_bugs"],
                "final_cash_cents": second["outcome"]["cash_cents"],
                "final_fans": second["outcome"]["fans"],
                "first_earned_units": first_sales["earned_units"],
                "first_settled_cents": first_sales["settled_cents"],
                "second_cycle": second["final_run_cycle"],
            })
    passed = sum(ok for _, ok in checks)
    report = {"checks_passed": passed, "checks_total": len(checks), "failures": [label for label, ok in checks if not ok], "rows": rows}
    args.output.mkdir(parents=True)
    (args.output / "audit.json").write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
    lines = ["# G4 Beta synergy second-release audit", "", f"Checks: {passed}/{len(checks)}.", "", "| Genre | Mode | First Review | Second Review | Cash cents | Fans | First earned units | First settled cents |", "| --- | --- | ---: | ---: | ---: | ---: | ---: | ---: |"]
    for row in rows:
        lines.append(f"| {row['genre']} | {row['mode']} | {row['first_review']:.1f} | {row['second_review']:.1f} | {row['final_cash_cents']} | {row['final_fans']} | {row['first_earned_units']} | {row['first_settled_cents']} |")
    if report["failures"]:
        lines += ["", "Failures: " + "; ".join(report["failures"])]
    (args.output / "audit.md").write_text("\n".join(lines) + "\n", encoding="utf-8")
    print(json.dumps({key: value for key, value in report.items() if key != "rows"}))
    if report["failures"]:
        raise SystemExit(1)


if __name__ == "__main__":
    main()
