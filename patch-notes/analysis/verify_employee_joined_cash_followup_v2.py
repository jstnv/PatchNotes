"""Independent arithmetic and reconstruction checks for joined cash shadow rows.

Run: python -B analysis/verify_employee_joined_cash_followup_v2.py
"""
from __future__ import annotations

import gzip
import json
import statistics
from pathlib import Path

import employee_joined_cash_followup_v2 as trial
import employee_three_specialist_trial_v1 as source

ROOT = Path(__file__).resolve().parents[1]
LOGS = ROOT / "design-logs"
RAW = LOGS / "employee_joined_cash_followup_v2_raw.json.gz"
SUMMARY = LOGS / "employee_joined_cash_followup_v2_summary.json"


def run():
    rows = json.load(gzip.open(RAW, "rt", encoding="utf-8"))["rows"]
    summary = json.loads(SUMMARY.read_text(encoding="utf-8"))
    assert len(rows) == summary["cash_rows"] == 90000
    boundaries = releases = failures = 0
    for row in rows:
        result = row["result"]
        assert result["cash_cents"] >= 0
        assert result["complete"] == (result["first_failure"] is None)
        failures += not result["complete"]
        for boundary in result["boundaries"]:
            boundaries += 1
            assert boundary["after_cents"] == (boundary["before_cents"] +
                   boundary["sales_cents"] - boundary["bill_cents"] -
                   boundary["payroll_cents"])
            assert boundary["after_cents"] >= 0 and boundary["cycle"] % 2 == 0
        for release in result["releases"]:
            releases += 1
            assert 0 <= release["earned_cycles"] <= 2
            expected_units = release["units"] * release["earned_cycles"] // 2
            expected_net = expected_units * 999 * 70 // 100
            assert release["entitlement_cents"] == expected_net
            assert 0 <= release["settled_cents"] <= expected_net
        for key in ("ironclad_numerator", "sidestreet1_numerator", "sidestreet2_numerator"):
            assert 0 <= result[key] <= 96
    # Reconstruct varied complete and failed action ledgers from source seeds.
    selected = {}
    for row in rows:
        result = row["result"]
        if row["arm"] not in ("none", "production+qa", "all_three"):
            continue
        if row["arm"] == "none" and (row["courses"], row["optional"]) != (0, False):
            continue
        if row["arm"] != "none" and (row["courses"], row["optional"]) != (2, True):
            continue
        key = (row["cohort"], row["policy"], row["arm"], result["complete"])
        selected.setdefault(key, row)
    ledgers = []
    for key, row in selected.items():
        item = source.sample(row["index"], row["cohort"], row["policy"])
        reproduced = trial.simulate(item, row["arm"], row["courses"],
                                    row["optional"], row["store_cycle"])
        recorded = row["result"]
        for field in ("complete", "cash_cents", "cycle", "first_failure", "boundaries",
                      "game1_review", "game1_units", "game2_review", "game2_units",
                      "ironclad_numerator", "sidestreet1_numerator",
                      "sidestreet2_numerator", "releases"):
            assert reproduced[field] == recorded[field], (key, field)
        ledgers.append({"cohort": row["cohort"], "policy": row["policy"],
                        "arm": row["arm"], "courses": row["courses"],
                        "optional": row["optional"], "store_cycle": row["store_cycle"],
                        "source_index": row["index"], "result": reproduced})
    ledger_path = LOGS / "employee_joined_cash_followup_v2_representative_ledgers.json.gz"
    with gzip.open(ledger_path, "wt", encoding="utf-8") as f:
        json.dump(ledgers, f, separators=(",", ":"))
    boundary_groups = {}
    for arm, courses, optional, store_cycle in (
            ("none", 0, False, 0), ("production", 0, False, 0),
            ("production+qa", 2, True, 0), ("all_three", 2, True, 0)):
        chosen = [r["result"] for r in rows if r["cohort"] == "legal" and
                  r["arm"] == arm and r["courses"] == courses and
                  r["optional"] == optional and r["store_cycle"] == store_cycle]
        assert len(chosen) == 1000
        by_ordinal = {}
        for result in chosen:
            for ordinal, boundary in enumerate(result["boundaries"], 1):
                by_ordinal.setdefault(ordinal, []).append(boundary["after_cents"])
        boundary_groups[f"{arm}|courses{courses}|node{int(optional)}"] = {
            str(ordinal): {"n": len(values),
                           "median_after_cents": statistics.median(values),
                           "minimum_after_cents": min(values)}
            for ordinal, values in sorted(by_ordinal.items())}
    checks = {"rows": len(rows), "boundaries": boundaries, "release_snapshots": releases,
              "first_failures": failures, "violations": 0,
              "reconstructed_ledgers": len(ledgers),
              "legal_boundary_cash": boundary_groups,
              "representative_path": str(ledger_path)}
    (LOGS / "employee_joined_cash_followup_v2_validation.json").write_text(
        json.dumps(checks, indent=2), encoding="utf-8")
    print(json.dumps(checks, indent=2))


if __name__ == "__main__":
    run()
