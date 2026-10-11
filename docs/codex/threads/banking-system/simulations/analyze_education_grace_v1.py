"""Summarize the predeclared education-grace run without mutating its bundle."""
from __future__ import annotations

import json
import sys
from pathlib import Path


def read(path: Path):
    return json.loads(path.read_text(encoding="utf-8"))


def main() -> int:
    bundle = Path(sys.argv[1]).resolve()
    output = Path(sys.argv[2]).resolve()
    report = read(bundle / "run-report.json")
    if not report.get("ok") or report.get("case_count") != 6:
        raise ValueError("Expected completed six-case run")
    cases = []
    traces = {}
    initial_rngs = {}
    initial_states = {}
    for case_id in ["control-4417", "dropout-4417", "graduate-4417", "control-90210", "dropout-90210", "graduate-90210"]:
        folder = bundle / "cases" / case_id
        result = read(folder / "result.json")
        telemetry = read(folder / "telemetry.json")
        if not result.get("ok") or result.get("status") != "completed" or result.get("final_release_count") != 3:
            raise ValueError(f"Incomplete case: {case_id}")
        samples = telemetry["samples"]
        if samples[-1]["state_digest"] != result["final_state"]:
            raise ValueError(f"Telemetry state mismatch: {case_id}")
        outcome = result["outcome"]
        initial_rngs[case_id] = result["initial_rng"]
        initial_states[case_id] = telemetry["initial_state"]
        traces[case_id] = [
            {
                "cycle": int(sample["run_cycle"]),
                "type": sample["request"].get("type"),
                "inner_type": sample["request"].get("payload", {}).get("request", {}).get("type"),
                "candidate_ids": sample["request"].get("payload", {}).get("request", {}).get("payload", {}).get("candidate_ids", []),
            }
            for sample in samples[1:]
        ]
        finance = outcome["finance"]
        rows = {int(row["month"]): row for row in finance["rows"] if not row.get("partial")}
        monthly_credit = {int(item["month"]): item for item in finance["credit"]["history"]}
        by_cycle = {}
        for sample in samples:
            by_cycle[int(sample["run_cycle"])] = sample
        due_rows = [row for month, row in sorted(rows.items()) if int(row.get("interest_cents", 0)) or int(row.get("principal_paid_cents", 0))]
        no_early_due = all(not int(row.get("interest_cents", 0)) and not int(row.get("principal_paid_cents", 0)) for month, row in rows.items() if month < 13)
        if not no_early_due:
            raise ValueError(f"Education payment before month 13: {case_id}")
        kind = case_id.split("-")[0]
        expected_due = {"control": 0, "dropout": 7068, "graduate": 28273}[kind]
        due13 = rows[13]
        paid13 = int(due13.get("interest_paid_cents", 0)) + int(due13.get("principal_paid_cents", 0))
        if paid13 != expected_due or int(due13.get("interest_cents", 0)) != int(due13.get("interest_paid_cents", 0)):
            raise ValueError(f"First due mismatch: {case_id}: {paid13} != {expected_due}")
        if any(not sample.get("accepted", True) for sample in samples[1:]):
            raise ValueError(f"Rejected command in complete case: {case_id}")
        case = {
            "id": case_id,
            "status": result["status"],
            "commands": result["commands"],
            "initial_cash_cents": int(samples[0]["cash_cents"]),
            "final_cash_cents": int(outcome["cash_cents"]),
            "cash_low_cents": min(int(sample["cash_cents"]) for sample in samples),
            "transaction_cash_low_cents": min(int(sample["transaction_cash_low_cents"]) for sample in samples),
            "max_overdue_cents": max(int(sample["overdue_cents"]) for sample in samples),
            "first_financial_block_cycle": next((int(sample["run_cycle"]) for sample in samples if sample["financially_blocked"]), None),
            "final_credit": int(finance["credit"]["score"]),
            "first_due_month": 13 if expected_due else None,
            "first_due_paid_cents": paid13,
            "first_due_interest_cents": int(due13.get("interest_cents", 0)),
            "due_rows_count": len(due_rows),
            "education_principal_paid_cents": int(finance["education"].get("principal_paid_cents", 0)) if finance.get("education") else 0,
            "education_interest_paid_cents": int(finance["education"].get("interest_paid_cents", 0)) if finance.get("education") else 0,
            "release_cycles": [int(release["metadata"]["release_cycle"]) for release in outcome["releases"]],
            "release_reviews": [float(release["metadata"]["review"]["final_review"]) for release in outcome["releases"]],
            "calendar_cash_cents": {str(cycle): int(by_cycle[cycle]["cash_cents"]) if cycle in by_cycle else None for cycle in (24, 26, 28, 30, 36, 39)},
            "month_13": {key: int(due13.get(key, 0)) for key in ("opening_cash_cents", "closing_cash_cents", "sales_settled_cents", "rent_due_cents", "rent_paid_cents", "interest_cents", "interest_paid_cents", "principal_paid_cents", "net_profit_cents")},
            "credit_at_month_13": int(monthly_credit[13]["after"]),
            "state_digest": result["final_state"],
        }
        cases.append(case)
    compatibility = {}
    for seed in ("4417", "90210"):
        ids = [f"{kind}-{seed}" for kind in ("control", "dropout", "graduate")]
        same_rng = all(initial_rngs[id] == initial_rngs[ids[0]] for id in ids[1:])
        same_trace = all(traces[id] == traces[ids[0]] for id in ids[1:])
        different_state = len({initial_states[id] for id in ids}) == 3
        if not (same_rng and same_trace and different_state):
            raise ValueError(f"Cohort compatibility changed: {seed}")
        compatibility[seed] = {"same_initial_rng": same_rng, "same_command_choices_and_cycles": same_trace, "different_legal_initial_states": different_state}
    summary = {"source_identity": report["frozen_source_identity"], "policy_identity": report["policy"]["source_identity"], "cohort_compatibility": compatibility, "cases": cases}
    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_text(json.dumps(summary, indent=2) + "\n", encoding="utf-8")
    print(json.dumps({"ok": True, "cases": len(cases), "output": str(output)}))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
