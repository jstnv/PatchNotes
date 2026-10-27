"""Audit the predeclared A/B first-release proxy without modifying outcomes."""

from __future__ import annotations

import json
from pathlib import Path
import statistics


THREAD = Path(__file__).resolve().parent
SIMS = THREAD / "sims"
A = SIMS / "first-release-bootstrap-A-20261026-v1"
B = SIMS / "first-release-bootstrap-B-20261026-v1"
OUT = SIMS / "first-release-bootstrap-analysis-20261026-v1.json"
CONFIG = THREAD / "first-release-bootstrap-config-20261026-v1.json"


def read(path: Path) -> dict:
    return json.loads(path.read_text(encoding="utf-8"))


def main() -> None:
    if OUT.exists():
        raise SystemExit(f"Preserve existing analysis: {OUT}")
    config = read(CONFIG)
    reports = {name: read(root / "run-report.json") for name, root in (("A", A), ("B", B))}
    rows = []
    failures = []
    for declared in config["cases"]:
        case_id = declared["case_id"]
        pair = {name: read(root / "cases" / case_id / "result.json") for name, root in (("A", A), ("B", B))}
        a, b = pair["A"], pair["B"]
        start_equal = a["initial_state"] == b["initial_state"] and a["initial_rng"] == b["initial_rng"]
        if not start_equal:
            failures.append(f"{case_id}: starting state/RNG mismatch")
        row = {"case_id": case_id, "specialty": declared["initial"]["recipe"]["specialty"],
               "seed": declared["initial"]["recipe"]["seed"], "starting_state_rng_equal": start_equal}
        for name, result in pair.items():
            releases = result.get("outcome", {}).get("releases", [])
            if not result.get("ok") or result.get("status") != "completed" or len(releases) != 1:
                failures.append(f"{case_id}/{name}: incomplete first release")
                row[name] = {"status": result.get("status"), "error": result.get("error")}
                continue
            review = releases[0]["metadata"]["review"]
            row[name] = {
                "source_identity": result["source_identity"],
                "commands": result["commands"], "cycle": result["final_run_cycle"],
                "review": review["final_review"], "production": review["production_rating"],
                "cores": review["cores"], "standards": review["standards"],
                "scope": review["scope"], "required_scope": review["required_scope"],
                "bugs": review["remaining_bugs"],
                "cash_cents": result["outcome"]["cash_cents"],
                "in_range": 6.0 <= review["final_review"] <= 7.0,
            }
        if "review" in row.get("A", {}) and "review" in row.get("B", {}):
            row["same_played_output"] = all(row["A"][key] == row["B"][key]
                                            for key in ("commands", "cycle", "cores", "scope", "required_scope", "bugs", "cash_cents"))
            if not row["same_played_output"]:
                failures.append(f"{case_id}: played output differed across rules")
            row["review_delta"] = round(row["B"]["review"] - row["A"]["review"], 1)
        rows.append(row)
    summary = {}
    for name in ("A", "B"):
        present = [row[name] for row in rows if "review" in row.get(name, {})]
        summary[name] = {
            "completed": len(present),
            "in_6_to_7": sum(row["in_range"] for row in present),
            "below_6": sum(row["review"] < 6.0 for row in present),
            "above_7": sum(row["review"] > 7.0 for row in present),
            "under_scope": sum(row["scope"] < row["required_scope"] for row in present),
            "mean_review": round(statistics.mean(row["review"] for row in present), 3) if present else None,
            "min_review": min((row["review"] for row in present), default=None),
            "max_review": max((row["review"] for row in present), default=None),
            "source_identities": sorted({row["source_identity"] for row in present}),
        }
    output = {
        "kind": "read-only-first-release-bootstrap-proxy",
        "input_config": str(CONFIG), "bundles": {"A": str(A), "B": str(B)},
        "run_ok": {name: report["ok"] for name, report in reports.items()},
        "baseline_identities": {name: report["variant"]["base_identity"] for name, report in reports.items()},
        "candidate_identities": {name: report["variant"]["candidate_identity"] for name, report in reports.items()},
        "summary": summary, "rows": rows, "failures": failures,
        "standard_transform": "NOT RUN: released four-Core vectors retained; transform remains OPEN",
        "limitations": "Independent fresh player Studio routes; no rival AI, 1977 calendar, historical generator, or persisted generated standards.",
    }
    OUT.write_text(json.dumps(output, indent=2) + "\n", encoding="utf-8")
    print(json.dumps({"output": str(OUT), "summary": summary, "failures": failures}))


if __name__ == "__main__":
    main()
