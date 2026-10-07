"""Read-only selectable amount/term schedule and capacity sensitivity."""
from __future__ import annotations

from decimal import Decimal, ROUND_HALF_UP
import json
from pathlib import Path

HERE = Path(__file__).resolve().parent
EVIDENCE = HERE / "evidence"
RATE = Decimal("0.01")
AMOUNTS = (500, 1000, 1500, 2000, 2500)
TERMS = (6, 12, 18, 24)


def cents(value: Decimal) -> int:
    return int(value.quantize(Decimal("1"), rounding=ROUND_HALF_UP))


def schedule(amount: int, term: int, shape: str) -> list[dict]:
    outstanding = amount
    rows = []
    if shape == "level_payment":
        factor = (Decimal(1) + RATE) ** term
        regular = cents(Decimal(amount) * RATE * factor / (factor - Decimal(1)))
    elif shape == "equal_principal":
        regular = 0
    else:
        raise ValueError(shape)
    for number in range(1, term + 1):
        interest = cents(Decimal(outstanding) * RATE)
        if number == term:
            principal = outstanding
        elif shape == "equal_principal":
            principal = amount // term
        else:
            principal = regular - interest
        assert 0 < principal <= outstanding
        rows.append({"number": number, "opening_principal_cents": outstanding,
                     "principal_cents": principal, "interest_cents": interest,
                     "payment_cents": principal + interest})
        outstanding -= principal
    assert outstanding == 0 and sum(x["principal_cents"] for x in rows) == amount
    return rows


def main() -> None:
    b2 = json.loads((EVIDENCE / "b2-two-settlement-comparison-v1.json").read_text())
    caps = [r["quote"]["conservative_capacity_cents"] for r in b2["routes"]]
    results = []
    for amount_dollars in AMOUNTS:
        for term in TERMS:
            for shape in ("level_payment", "equal_principal"):
                rows = schedule(amount_dollars * 100, term, shape)
                maximum = max(x["payment_cents"] for x in rows)
                results.append({"amount_cents": amount_dollars * 100,
                                "term_months": term, "shape": shape,
                                "first_payment_cents": rows[0]["payment_cents"],
                                "last_payment_cents": rows[-1]["payment_cents"],
                                "maximum_payment_cents": maximum,
                                "total_interest_cents": sum(x["interest_cents"] for x in rows),
                                "qualifying_routes": sum(cap >= maximum for cap in caps),
                                "schedule": rows})
    maximum_by_route = []
    for r in b2["routes"]:
        cap = r["quote"]["conservative_capacity_cents"]
        per_term = {}
        for term in TERMS:
            # Diagnostic only: $100 increments up to $10,000 with no principal ceiling.
            affordable = [amount for amount in range(500, 10001, 100)
                if max(x["payment_cents"] for x in schedule(amount * 100, term,
                                                            "level_payment")) <= cap]
            per_term[str(term)] = max(affordable) if affordable else 0
        maximum_by_route.append({"route": r["route"], "band": r["band"],
                                 "funding": r["funding"], "policy": r["policy"],
                                 "seed": r["seed"], "capacity_cents": cap,
                                 "uncapped_max_amount_dollars_by_term": per_term})
    out = {"method": "candidate 1% interest on scheduled opening principal;"
                     " compare level payment and equal principal schedules against"
                     " locked two-month capacity, with no gameplay loan",
           "amounts_dollars": AMOUNTS, "terms_months": TERMS,
           "results": results, "maximum_by_route": maximum_by_route}
    (EVIDENCE / "b4-flexible-term-comparison-v1.json").write_text(
        json.dumps(out, indent=2) + "\n", encoding="utf-8")
    for r in results:
        if r["amount_cents"] in (50000, 150000, 250000):
            print(r["amount_cents"] // 100, r["term_months"], r["shape"],
                  "first", r["first_payment_cents"],
                  "last", r["last_payment_cents"],
                  "max", r["maximum_payment_cents"],
                  "interest", r["total_interest_cents"],
                  "eligible", r["qualifying_routes"])


if __name__ == "__main__":
    main()
