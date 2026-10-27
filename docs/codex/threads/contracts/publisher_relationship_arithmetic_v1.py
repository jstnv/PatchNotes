"""Read-only fixed-point boundary screen for proposed publisher relationship rules."""

from __future__ import annotations

import argparse
import json
from pathlib import Path


SCALE = 10000
TIERS = (
    {"tier": 1, "gate": 2000, "fee_cents": 600000, "review_tenths": 60, "award": 1500},
    {"tier": 2, "gate": 5000, "fee_cents": 800000, "review_tenths": 70, "award": 2000},
    {"tier": 3, "gate": 8000, "fee_cents": 1000000, "review_tenths": 80, "award": 2500},
)


def clamp(value: int) -> int:
    return max(0, min(SCALE, value))


def brief_award(completion_bp: int, promise_bp: int) -> int:
    return 1000 * min(clamp(completion_bp), clamp(promise_bp)) // SCALE


def commission(tier: dict, scope_bp: int, actual_review_tenths: int) -> dict:
    quality = clamp((actual_review_tenths - (tier["review_tenths"] - 20)) * 500)
    delivery = min(clamp(scope_bp), quality)
    return {
        "tier": tier["tier"], "scope_bp": scope_bp, "actual_review_tenths": actual_review_tenths,
        "review_grade_bp": quality, "delivery_grade_bp": delivery,
        "fee_paid_cents": tier["fee_cents"] * delivery // SCALE,
        "reputation_gain": tier["award"] * delivery // SCALE,
        "investment_gain": tier["award"] * delivery // SCALE,
    }


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--output", required=True, type=Path)
    args = parser.parse_args()
    brief_rows = [{"completion_bp": c, "promise_bp": p, "award": brief_award(c, p)}
                  for c in (0, 5000, 10000) for p in (0, 5000, 10000)]
    assert brief_award(10000, 10000) == 1000
    assert brief_award(10000, 5000) == brief_award(5000, 10000) == 500
    assert brief_award(0, 10000) == 0
    commission_rows = []
    for tier in TIERS:
        review_values = [tier["review_tenths"] + delta for delta in (-20, -10, -1, 0, 10)]
        for scope in (0, 5000, 10000):
            prior = None
            for review in review_values:
                row = commission(tier, scope, review)
                assert 0 <= row["fee_paid_cents"] <= tier["fee_cents"]
                assert 0 <= row["reputation_gain"] <= tier["award"]
                assert row["reputation_gain"] == row["investment_gain"]
                if prior is not None:
                    assert prior["fee_paid_cents"] <= row["fee_paid_cents"]
                prior = row
                commission_rows.append(row)
        for review in review_values:
            matches = [r for r in commission_rows if r["tier"] == tier["tier"] and r["actual_review_tenths"] == review]
            assert [r["fee_paid_cents"] for r in matches] == sorted(r["fee_paid_cents"] for r in matches)
        full = commission(tier, 10000, tier["review_tenths"])
        zero = commission(tier, 10000, tier["review_tenths"] - 20)
        assert full["fee_paid_cents"] == tier["fee_cents"] and full["reputation_gain"] == tier["award"]
        assert zero["fee_paid_cents"] == zero["reputation_gain"] == 0

    ledgers = {"sidestreet": {"reputation": 0, "investment": 0},
               "crown_quill": {"reputation": 0, "investment": 0}}
    path = []

    def event(label: str, rep: int = 0, investment: int = 0) -> None:
        row = ledgers["sidestreet"]
        row["reputation"] = min(SCALE, row["reputation"] + rep)
        row["investment"] = min(SCALE, row["investment"] + investment)
        assert ledgers["crown_quill"] == {"reputation": 0, "investment": 0}
        path.append({"event": label, **row.copy()})

    event("brief_1", brief_award(SCALE, SCALE))
    event("brief_2", brief_award(SCALE, SCALE))
    assert ledgers["sidestreet"]["reputation"] == TIERS[0]["gate"]
    full_1 = commission(TIERS[0], SCALE, TIERS[0]["review_tenths"])
    event("commission_1", full_1["reputation_gain"], full_1["investment_gain"])
    event("support_success", investment=1000)
    event("brief_3", brief_award(SCALE, SCALE))
    event("brief_4", brief_award(SCALE, SCALE))
    assert ledgers["sidestreet"]["reputation"] >= TIERS[1]["gate"]
    full_2 = commission(TIERS[1], SCALE, TIERS[1]["review_tenths"])
    event("commission_2", full_2["reputation_gain"], full_2["investment_gain"])
    event("brief_5", brief_award(SCALE, SCALE))
    assert ledgers["sidestreet"]["reputation"] >= TIERS[2]["gate"]
    assert path == [
        {"event": "brief_1", "reputation": 1000, "investment": 0},
        {"event": "brief_2", "reputation": 2000, "investment": 0},
        {"event": "commission_1", "reputation": 3500, "investment": 1500},
        {"event": "support_success", "reputation": 3500, "investment": 2500},
        {"event": "brief_3", "reputation": 4500, "investment": 2500},
        {"event": "brief_4", "reputation": 5500, "investment": 2500},
        {"event": "commission_2", "reputation": 7500, "investment": 4500},
        {"event": "brief_5", "reputation": 8500, "investment": 4500},
    ]
    result = {"model": "publisher_relationship_arithmetic_v1", "brief_rows": brief_rows,
              "commission_rows": commission_rows, "tier_terms": TIERS, "sequence": path,
              "checks": {"brief_rows": len(brief_rows), "commission_rows": len(commission_rows),
                         "progression_events": len(path), "publisher_isolation": True}}
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(json.dumps(result, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    print(json.dumps({"output": str(args.output), "checks": result["checks"]}, sort_keys=True))


if __name__ == "__main__":
    main()
