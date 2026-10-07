"""Read-only two-settlement qualification comparison on Banking B1 traces."""
from __future__ import annotations

import json
from pathlib import Path

from b1_compare_v1 import installments

HERE = Path(__file__).resolve().parent
EVIDENCE = HERE / "evidence"
RENT = 50_000
PRINCIPAL = 50_000
MAX_PAYMENT = max(x["payment_cents"] for x in installments("monthly_1pct"))


def two_month_quote(first_sales: int, latest_sales: int, unpaid_rent: int) -> dict:
    average = (first_sales + latest_sales) // 2
    average_capacity = max(0, average - RENT) // 4
    conservative_sales = min(average, latest_sales)
    conservative_capacity = max(0, conservative_sales - RENT) // 4
    consecutive_positive = first_sales > 0 and latest_sales > 0
    return {"first_sales_cents": first_sales, "latest_sales_cents": latest_sales,
            "average_sales_cents": average, "average_capacity_cents": average_capacity,
            "conservative_sales_cents": conservative_sales,
            "conservative_capacity_cents": conservative_capacity,
            "consecutive_positive": consecutive_positive,
            "unpaid_rent_cents": unpaid_rent,
            "average_eligible": consecutive_positive and unpaid_rent == 0
                and average_capacity >= MAX_PAYMENT,
            "conservative_eligible": consecutive_positive and unpaid_rent == 0
                and conservative_capacity >= MAX_PAYMENT}


def overlay(actions: list[dict], issue_index: int) -> dict:
    issue_cycle = actions[issue_index]["after"]["cycle"]
    assert issue_cycle % 2 == 0
    schedule = installments("monthly_1pct")
    paid = 0
    payments = []
    low = None
    low_cycle = None
    for index in range(issue_index, len(actions)):
        action = actions[index]
        state = action["after"]
        cycle = state["cycle"]
        for line in schedule:
            if line["number"] <= len(payments) or issue_cycle + 2 * line["number"] > cycle:
                continue
            cash_before = state["cash_cents"] + PRINCIPAL - paid
            if cash_before < line["payment_cents"]:
                return {"valid": False, "reason": "missed installment",
                        "cycle": cycle, "cash_before_cents": cash_before}
            paid += line["payment_cents"]
            payments.append({"number": line["number"],
                             "due_cycle": issue_cycle + 2 * line["number"],
                             "payment_cents": line["payment_cents"],
                             "principal_cents": line["principal_cents"],
                             "interest_cents": line["interest_cents"],
                             "cash_after_cents": cash_before - line["payment_cents"]})
        cash = state["cash_cents"] + PRINCIPAL - paid
        if low is None or cash < low:
            low, low_cycle = cash, cycle
        if cash < 0 or state["finance_report"]["unpaid_rent_cents"] > 0:
            return {"valid": False,
                    "reason": "fixed native action overdraw or rent-service divergence",
                    "cycle": cycle, "action_index": index, "cash_cents": cash}
    return {"valid": True, "first_due_cycle": issue_cycle + 2,
            "payments_observed": payments, "low_cash_cents": low,
            "low_cash_cycle": low_cycle,
            "cash_at_route_end_cents": actions[-1]["after"]["cash_cents"] + PRINCIPAL - paid,
            "principal_remaining_cents": PRINCIPAL - sum(
                p["principal_cents"] for p in payments)}


def main() -> None:
    routes = []
    for path in sorted(EVIDENCE.glob("route_*.json")):
        route = json.loads(path.read_text(encoding="utf-8"))
        actions = route["actions"]
        first_index = next(i for i, a in enumerate(actions)
            if any(t["kind"] == "sales_settlement" and t["amount_cents"] > 0
                   for t in a["after"]["finance"]["transactions"]))
        first_cycle = actions[first_index]["after"]["cycle"]
        second_cycle = first_cycle + 2
        second_index = next(i for i, a in enumerate(actions)
                            if a["after"]["cycle"] == second_cycle)
        rows = {r["month"]: r for r in actions[second_index]["after"]
                ["finance_report"]["rows"] if not r["partial"]}
        first_sales = rows[first_cycle // 2]["sales_settled_cents"]
        latest_sales = rows[second_cycle // 2]["sales_settled_cents"]
        quote = two_month_quote(first_sales, latest_sales,
                  actions[second_index]["after"]["finance_report"]["unpaid_rent_cents"])
        result = {"route": path.name, "funding": route["funding"],
                  "band": route["band"], "policy": route["policy"],
                  "seed": route["seed"], "first_settlement_cycle": first_cycle,
                  "second_settlement_cycle": second_cycle,
                  "issue_action_index": second_index,
                  "issue_phase": actions[second_index].get("phase"),
                  "issue_cash_cents": actions[second_index]["after"]["cash_cents"],
                  "quote": quote,
                  "overlay": overlay(actions, second_index) if quote["conservative_eligible"] else None}
        routes.append(result)
    synthetic = []
    first = 279_020  # An actual first settlement from early ordinary seed 1104.
    for second in (0, 10_000, 60_000, 68_663, 68_664, 70_000):
        synthetic.append({"second_sales_cents": second,
                          "quote": two_month_quote(first, second, 0)})
    out = {"method": "two consecutive completed months with positive settled sales;"
                     " compare 25% of average post-rent surplus against 25% of"
                     " min(latest, average) post-rent surplus; fixed-action loan overlay",
           "max_payment_cents": MAX_PAYMENT, "routes": routes,
           "synthetic_second_month_boundaries": synthetic}
    (EVIDENCE / "b2-two-settlement-comparison-v1.json").write_text(
        json.dumps(out, indent=2) + "\n", encoding="utf-8")
    print("routes", len(routes), "average eligible",
          sum(r["quote"]["average_eligible"] for r in routes),
          "conservative eligible",
          sum(r["quote"]["conservative_eligible"] for r in routes),
          "overlay valid", sum(r["overlay"] is not None and r["overlay"]["valid"]
                               for r in routes))
    for r in routes:
        if not r["quote"]["conservative_eligible"]:
            print("rejected", r["route"], "second sales cents",
                  r["quote"]["latest_sales_cents"], "capacity cents",
                  r["quote"]["conservative_capacity_cents"])


if __name__ == "__main__":
    main()
