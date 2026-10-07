"""Read-only B1 comparison on native no-loan traces; no gameplay mutation."""
from __future__ import annotations

from collections import Counter
from decimal import Decimal, ROUND_HALF_UP
import json
from pathlib import Path

HERE = Path(__file__).resolve().parent
EVIDENCE = HERE / "evidence"
PRINCIPAL = 50_000
RENT = 50_000


def installments(model: str) -> list[dict]:
    unpaid = PRINCIPAL
    result = []
    for number in range(1, 13):
        principal = 4166 if number < 12 else unpaid
        if model == "monthly_1pct":
            interest = int((Decimal(unpaid) * Decimal("0.01")).quantize(
                Decimal("1"), rounding=ROUND_HALF_UP))
        elif model == "task33_10pct_total":
            interest = 416 if number < 12 else 424
        else:
            raise ValueError(model)
        result.append({"number": number, "principal_cents": principal,
                       "interest_cents": interest, "payment_cents": principal + interest})
        unpaid -= principal
    assert unpaid == 0
    return result


def first_settlement_index(actions: list[dict]) -> int:
    for index, action in enumerate(actions):
        if any(t["kind"] == "sales_settlement" and t["amount_cents"] > 0
               for t in action["after"]["finance"]["transactions"]):
            return index
    raise ValueError("no positive settled sale")


def capacity_at(action: dict) -> dict:
    rows = [r for r in action["after"]["finance_report"]["rows"]
            if not r["partial"] and r["sales_settled_cents"] > 0]
    # This replay quotes at the first settled month; sample count is exactly one.
    assert len(rows) == 1
    sales = rows[0]["sales_settled_cents"]
    surplus = max(0, sales - RENT)
    capacity = surplus // 4
    return {"sales_cents": sales, "capacity_cents": capacity,
            "unpaid_rent_cents": action["after"]["finance_report"]["unpaid_rent_cents"]}


def due_start(issue_cycle: int, model: str) -> int:
    if model == "monthly_1pct":
        return issue_cycle + (2 if issue_cycle % 2 == 0 else 3)
    return issue_cycle + (2 if issue_cycle % 2 == 0 else 1)


def replay(route: dict, issue_index: int, model: str, timing: str) -> dict:
    actions = route["actions"]
    issue = actions[issue_index]
    issue_cycle = issue["after"]["cycle"]
    cap = capacity_at(issue)
    schedule = installments(model)
    eligible = cap["unpaid_rent_cents"] == 0 and cap["capacity_cents"] >= max(
        line["payment_cents"] for line in schedule)
    due = due_start(issue_cycle, model)
    for line in schedule:
        line["due_cycle"] = due + 2 * (line["number"] - 1)
    result = {"model": model, "timing": timing, "issue_cycle": issue_cycle,
              "issue_action_index": issue_index, "capacity": cap,
              "eligible": eligible, "first_due_cycle": due,
              "scheduled_interest_cents": sum(x["interest_cents"] for x in schedule),
              "scheduled_total_cents": sum(x["payment_cents"] for x in schedule),
              "payments": [], "low_cash_cents": None, "low_cash_cycle": None,
              "fixed_route_valid": eligible, "invalid_reason": None,
              "observed_through_cycle": actions[-1]["after"]["cycle"],
              "capacity_by_month": []}
    if not eligible:
        result["fixed_route_valid"] = False
        result["invalid_reason"] = "quote ineligible"
        return result

    paid = 0
    paid_numbers: set[int] = set()
    last_cycle = None
    for index in range(issue_index, len(actions)):
        after = actions[index]["after"]
        cycle = after["cycle"]
        # Loan issuance is at the end of the chosen Studio action; payments
        # begin at later completed-month boundaries.
        if last_cycle != cycle and cycle % 2 == 0 and cycle > issue_cycle:
            rows = [r for r in after["finance_report"]["rows"] if not r["partial"]]
            settled = [r for r in rows if r["month"] >= issue_cycle // 2 + 1][-3:]
            if settled:
                average = sum(r["sales_settled_cents"] for r in settled) // len(settled)
                result["capacity_by_month"].append({"cycle": cycle,
                    "sales_sample_cents": [r["sales_settled_cents"] for r in settled],
                    "capacity_cents": max(0, average - RENT) // 4})
        for line in schedule:
            if line["due_cycle"] <= cycle and line["number"] not in paid_numbers:
                cash_before_due = after["cash_cents"] + PRINCIPAL - paid
                payment = line["payment_cents"]
                if cash_before_due < payment:
                    result["fixed_route_valid"] = False
                    result["invalid_reason"] = "modeled cash cannot service installment"
                    result["missed_due_cycle"] = line["due_cycle"]
                    result["cash_before_missed_cents"] = cash_before_due
                    return result
                paid += payment
                paid_numbers.add(line["number"])
                result["payments"].append({**line, "cash_before_cents": cash_before_due,
                                           "cash_after_cents": cash_before_due - payment})
        adjusted_cash = after["cash_cents"] + PRINCIPAL - paid
        if result["low_cash_cents"] is None or adjusted_cash < result["low_cash_cents"]:
            result["low_cash_cents"] = adjusted_cash
            result["low_cash_cycle"] = cycle
        if adjusted_cash < 0:
            result["fixed_route_valid"] = False
            result["invalid_reason"] = "fixed native action would overdraw"
            result["invalid_action_index"] = index
            return result
        if after["finance_report"]["unpaid_rent_cents"] > 0:
            result["fixed_route_valid"] = False
            result["invalid_reason"] = "native rent arrears after issuance; cash ordering diverges"
            result["invalid_action_index"] = index
            return result
        last_cycle = cycle
    result["paid_cents"] = paid
    result["principal_remaining_cents"] = PRINCIPAL - sum(
        p["principal_cents"] for p in result["payments"])
    result["cash_at_route_end_cents"] = actions[-1]["after"]["cash_cents"] + PRINCIPAL - paid
    return result


def main() -> None:
    cases = []
    for path in sorted(EVIDENCE.glob("route_*.json")):
        route = json.loads(path.read_text(encoding="utf-8"))
        actions = route["actions"]
        first = first_settlement_index(actions)
        issue_cases = [(first, "immediate")]
        # Only the 13-cycle route has a reproducible Studio visit on an odd
        # cycle after settlement: Ironclad hand 2 returns to Studio at cycle 15.
        for index in range(first + 1, len(actions)):
            action = actions[index]
            if action.get("phase") == "ironclad hand" and action.get("hand") == 2 \
                    and action["after"]["cycle"] == actions[first]["after"]["cycle"] + 1:
                issue_cases.append((index, "delayed_odd_studio"))
                break
        row = {"route": path.name, "funding": route["funding"], "band": route["band"],
               "policy": route["policy"], "seed": route["seed"],
               "first_release_cycle": route["releases"][0]["cycle"],
               "first_settlement_cycle": actions[first]["after"]["cycle"],
               "native_cash_at_first_settlement_cents": actions[first]["after"]["cash_cents"],
               "native_cash_at_end_cents": actions[-1]["after"]["cash_cents"],
               "native_end_cycle": actions[-1]["after"]["cycle"],
               "native_credit_at_end": actions[-1]["after"]["finance_report"]["credit"]["score"],
               "native_low_cash_cents": min(a["after"]["cash_cents"] for a in actions),
               "overlays": [replay(route, index, model, timing)
                   for index, timing in issue_cases
                   for model in ("monthly_1pct", "task33_10pct_total")]}
        cases.append(row)
    output = {"method": "fixed-action additive overlay on native no-loan routes; no loan is implemented",
              "routes": len(cases), "overlays": sum(len(x["overlays"]) for x in cases),
              "cases": cases}
    (EVIDENCE / "b1-comparison-v1.json").write_text(
        json.dumps(output, indent=2) + "\n", encoding="utf-8")
    stats = Counter((o["model"], o["timing"], o["eligible"],
                     o["fixed_route_valid"], o["invalid_reason"])
                    for c in cases for o in c["overlays"])
    print("routes", len(cases), "overlays", output["overlays"])
    for key, count in sorted(stats.items(), key=lambda x: str(x[0])):
        print(key, count)


if __name__ == "__main__":
    main()
