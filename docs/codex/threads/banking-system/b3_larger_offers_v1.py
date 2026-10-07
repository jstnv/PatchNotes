"""Read-only larger-loan quote and fixed-action repayment sensitivity."""
from __future__ import annotations

from collections import Counter
from decimal import Decimal, ROUND_HALF_UP
import json
from pathlib import Path

HERE = Path(__file__).resolve().parent
EVIDENCE = HERE / "evidence"
AMOUNTS = (500, 750, 1000, 1250, 1500, 2000, 2500)
TERMS = (12, 18)


def schedule(amount_cents: int, term: int) -> list[dict]:
    opening = amount_cents
    result = []
    for number in range(1, term + 1):
        principal = amount_cents // term if number < term else opening
        interest = int((Decimal(opening) * Decimal("0.01")).quantize(
            Decimal("1"), rounding=ROUND_HALF_UP))
        result.append({"number": number, "principal_cents": principal,
                       "interest_cents": interest,
                       "payment_cents": principal + interest})
        opening -= principal
    assert opening == 0 and sum(x["principal_cents"] for x in result) == amount_cents
    return result


def overlay(actions: list[dict], issue_index: int, amount_cents: int,
            lines: list[dict]) -> dict:
    issue_cycle = actions[issue_index]["after"]["cycle"]
    assert issue_cycle % 2 == 0
    paid_cents = 0
    paid_count = 0
    low_cash = None
    low_cycle = None
    for index in range(issue_index, len(actions)):
        state = actions[index]["after"]
        cycle = state["cycle"]
        while paid_count < len(lines) and issue_cycle + 2 * (paid_count + 1) <= cycle:
            payment = lines[paid_count]["payment_cents"]
            before = state["cash_cents"] + amount_cents - paid_cents
            if before < payment:
                return {"valid": False, "reason": "insufficient cash at due",
                        "cycle": cycle, "before_due_cents": before,
                        "installment": paid_count + 1}
            paid_cents += payment
            paid_count += 1
        cash = state["cash_cents"] + amount_cents - paid_cents
        if low_cash is None or cash < low_cash:
            low_cash, low_cycle = cash, cycle
        if cash < 0 or state["finance_report"]["unpaid_rent_cents"] > 0:
            return {"valid": False, "reason": "fixed action/rent service divergence",
                    "cycle": cycle, "action_index": index, "cash_cents": cash}
    return {"valid": True, "observed_payments": paid_count,
            "observed_paid_cents": paid_cents,
            "remaining_principal_cents": amount_cents - sum(
                x["principal_cents"] for x in lines[:paid_count]),
            "low_cash_cents": low_cash, "low_cash_cycle": low_cycle,
            "cash_at_route_end_cents": actions[-1]["after"]["cash_cents"]
                + amount_cents - paid_cents}


def main() -> None:
    b2 = json.loads((EVIDENCE / "b2-two-settlement-comparison-v1.json").read_text())
    cases = []
    for source in b2["routes"]:
        path = EVIDENCE / source["route"]
        native = json.loads(path.read_text(encoding="utf-8"))
        actions = native["actions"]
        cap = source["quote"]["conservative_capacity_cents"]
        quotes = []
        for amount in AMOUNTS:
            for term in TERMS:
                amount_cents = amount * 100
                lines = schedule(amount_cents, term)
                maximum = max(x["payment_cents"] for x in lines)
                eligible = source["quote"]["consecutive_positive"] \
                    and source["quote"]["unpaid_rent_cents"] == 0 \
                    and maximum <= cap
                quotes.append({"amount_cents": amount_cents, "term_months": term,
                               "maximum_payment_cents": maximum,
                               "first_payment_cents": lines[0]["payment_cents"],
                               "last_payment_cents": lines[-1]["payment_cents"],
                               "total_interest_cents": sum(
                                   x["interest_cents"] for x in lines),
                               "eligible": eligible,
                               "overlay": overlay(actions, source["issue_action_index"],
                                                  amount_cents, lines) if eligible else None})
        cases.append({"route": source["route"], "funding": source["funding"],
                      "band": source["band"], "policy": source["policy"],
                      "seed": source["seed"], "issue_cycle": source["second_settlement_cycle"],
                      "capacity_cents": cap, "quotes": quotes})
    output = {"method": "candidate 1% monthly scheduled-opening-principal interest;"
                       " 12/18-month terms; locked two-settlement capacity; fixed native actions",
              "amounts_dollars": AMOUNTS, "terms_months": TERMS, "cases": cases}
    (EVIDENCE / "b3-larger-offer-comparison-v1.json").write_text(
        json.dumps(output, indent=2) + "\n", encoding="utf-8")
    for term in TERMS:
        for amount in AMOUNTS:
            quotes = [q for c in cases for q in c["quotes"]
                      if q["term_months"] == term and q["amount_cents"] == amount * 100]
            eligible = [q for q in quotes if q["eligible"]]
            failed = Counter(q["overlay"]["reason"] for q in eligible
                             if not q["overlay"]["valid"])
            print(term, amount, "max due", quotes[0]["maximum_payment_cents"],
                  "interest", quotes[0]["total_interest_cents"],
                  "eligible", len(eligible), "overlay failures", dict(failed))


if __name__ == "__main__":
    main()
