"""Bounded, source-pinned Banking comparison audit; reads retained JSON only."""
import json
import sys
from pathlib import Path


def read(path: Path):
    return json.loads(path.read_text(encoding="utf-8-sig"))


def main(root: Path, output: Path):
    first = root / "eligible-sales-variant-first-v2" / "cases"
    studio = root / "eligible-sales-variant-studio-v2" / "cases"
    pairs = root / "eligible-sales-pairs-run-v1" / "cases"
    rows = []
    for cohort in ("control-4417", "graduate-4417", "control-90210", "graduate-90210"):
        first_result = read(first / cohort / "result.json")
        studio_result = read(studio / cohort / "result.json")
        studio_samples = read(studio / cohort / "telemetry.json")["samples"]
        left = read(pairs / f"{cohort}-no-loan" / "result.json")
        right = read(pairs / f"{cohort}-borrow-500-12" / "result.json")
        right_samples = read(pairs / f"{cohort}-borrow-500-12" / "telemetry.json")["samples"]
        comparison = read(root / f"eligible-sales-comparison-{cohort}-v1" / "comparison.json")
        assert first_result["ok"] and first_result["final_run_cycle"] == 13
        assert studio_result["status"] == "command_bound" and studio_result["commands"] == 5
        assert studio_result["final_run_cycle"] == 16 and studio_result["final_release_count"] == 1
        assert studio_result["accepted_commands"] == 5
        assert left["ok"] and right["ok"] and comparison["both_cases_completed"]
        assert left["initial_state"] == right["initial_state"]
        assert left["initial_rng"] == right["initial_rng"]
        assert left["final_run_cycle"] == right["final_run_cycle"] == 29
        assert left["final_release_count"] == right["final_release_count"] == 2
        assert left["outcome"]["finance"]["total_overdue_cents"] == 0
        assert right["outcome"]["finance"]["total_overdue_cents"] == 0
        assert left["outcome"]["finance"]["credit"]["score"] == right["outcome"]["finance"]["credit"]["score"]
        assert not left["outcome"]["finance"]["bank_loans"]
        loan = right["outcome"]["finance"]["bank_loans"][0]
        quote = next(x["request"]["payload"]["quote"] for x in right_samples if x["command_type"] == "bank_borrow")
        assert quote["eligible"] and quote["accepted"]
        assert loan["issued"] == 6 and loan["schedule"]["principal_cents"] == 50000
        outstanding_principal = 50000 - loan["principal_paid_cents"]
        cash_delta = right["outcome"]["cash_cents"] - left["outcome"]["cash_cents"]
        adjusted_delta = cash_delta - outstanding_principal
        assert adjusted_delta == -loan["interest_paid_cents"]
        reviews_left = [(r["metadata"]["release_cycle"], r["metadata"]["review"]["final_review"]) for r in left["outcome"]["releases"]]
        reviews_right = [(r["metadata"]["release_cycle"], r["metadata"]["review"]["final_review"]) for r in right["outcome"]["releases"]]
        assert reviews_left == reviews_right
        purchases = [x["request"]["payload"]["quote"] for x in studio_samples if x["command_type"] == "admit_research"]
        research = [x["request"]["payload"]["quote"] for x in studio_samples if x["command_type"] == "research"]
        settlements = [(r["month"], r["sales_settled_cents"]) for r in studio_result["outcome"]["finance"]["rows"] if r["sales_settled_cents"]]
        education = right["outcome"]["finance"].get("education", {})
        rows.append({
            "cohort": cohort,
            "start_cash_cents": read(first / cohort / "telemetry.json")["samples"][0]["cash_cents"],
            "first_review": first_result["outcome"]["releases"][0]["metadata"]["review"]["final_review"],
            "studio_cash_cents": studio_result["outcome"]["cash_cents"],
            "store_purchases": [{"feature_id": q["feature_id"], "down_cents": q["down_cents"], "due_cents": next(r["due_cents"] for r in research if r["feature_id"] == q["feature_id"])} for q in purchases],
            "settled_sales_months": settlements,
            "bank_quote": quote,
            "second_reviews": reviews_left,
            "cash_no_loan_cents": left["outcome"]["cash_cents"],
            "cash_loan_cents": right["outcome"]["cash_cents"],
            "cash_delta_cents": cash_delta,
            "bank_principal_outstanding_cents": outstanding_principal,
            "interest_paid_cents": loan["interest_paid_cents"],
            "debt_adjusted_cash_delta_cents": adjusted_delta,
            "education_principal_paid_cents": education.get("principal_paid_cents", 0),
            "education_interest_paid_cents": education.get("interest_paid_cents", 0),
            "credit": right["outcome"]["finance"]["credit"]["score"],
            "overdue_cents": right["outcome"]["finance"]["total_overdue_cents"],
        })
    output.write_text(json.dumps({"schema_version": "1", "audit": "4 matched completed pairs; exact checkpoint and RNG; quote/loan/interest reconciliation", "cases": rows}, indent=2) + "\n", encoding="utf-8")
    print(f"audited {len(rows)} completed pairs; output={output}")


if __name__ == "__main__":
    main(Path(sys.argv[1]), Path(sys.argv[2]))
