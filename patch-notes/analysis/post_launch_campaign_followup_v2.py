"""Read-only Month 2+ carryover/campaign sensitivity, not gameplay rules.

Run: python -B patch-notes/analysis/post_launch_campaign_followup_v2.py
Matched schedules give controls a neutral productive cycle wherever campaigns act.
"""
from __future__ import annotations

import gzip
import json
from pathlib import Path

import post_launch_campaign_playtest_v1 as prior


ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "design-logs"
HORIZON = 24
START_CENTS = 100_000
MONTHLY_EXPENSE_CENTS = 17_500  # $75 bill + one $100 salary: candidate, not live.
ANCHORS = {
    "godot_cautious_p10": (6, 100),
    "godot_cautious_median": (10, 103),
    "godot_cautious_p90": (16, 105),
    "godot_ordinary_p10": (19, 102),
    "godot_ordinary_median": (26, 109),
    "godot_ordinary_p90": (33, 124),
    "godot_optimizer_p10": (26, 103),
    "godot_optimizer_median": (36, 114),
    "godot_optimizer_p90": (49, 136),
    "synthetic_review_9": (90, 100),
    "synthetic_weak_4": (40, 100),
    "synthetic_typical_7": (70, 100),
    "matched_high_awareness_low_review": (40, 325),
    "matched_low_awareness_high_review": (70, 100),
}


def organic_awareness_bp(review_tenths: int, launch_awareness: int,
                         month: int, carryover_bp: int, retention_shift_bp: int = 0) -> int:
    assert month >= 2 and 0 <= carryover_bp <= 10_000
    # Keep V1's 50% of launch Awareness, then add 0/15/30% of the separate
    # 200-point discovery baseline. Review 1.3 therefore gives 23/37/51 units.
    awareness_bp = launch_awareness * 5_000 + 200 * carryover_bp
    retention = 2_500 + 55 * review_tenths + retention_shift_bp
    assert 0 <= retention <= 10_000
    for _ in range(2, month):
        awareness_bp = awareness_bp * retention // 10_000
    return awareness_bp


def month_units(review_tenths: int, launch_awareness: int, month: int,
                carryover_bp: int, market_bp: int = 10_000,
                boost: str = "none", prior_campaigns: int = 0,
                retention_shift_bp: int = 0) -> tuple[int, int, int]:
    if month == 1:
        return prior.month_one_units(review_tenths, launch_awareness, market_bp), launch_awareness * 10_000, launch_awareness * 10_000
    organic = organic_awareness_bp(review_tenths, launch_awareness, month,
                                   carryover_bp, retention_shift_bp)
    active = organic
    if boost == "launch_percent":
        active += launch_awareness * 1_000 // (prior_campaigns + 1)
    elif boost == "fixed_10":
        active += 100_000 // (prior_campaigns + 1)
    else:
        assert boost == "none"
    units = 500 * review_tenths * active * market_bp // (70 * 200 * 10_000 * 10_000)
    return units, organic, active


def simulate(review_tenths: int, awareness: int, carryover_bp: int,
             boost: str, policy: str, cost_cents: int = 10_000,
             retention_shift_bp: int = 0, market_bp: int = 10_000) -> dict:
    assert policy in ("none", "once", "repeat", "dormant")
    dormant_month = next((m for m in range(2, HORIZON + 1)
                          if month_units(review_tenths, awareness, m, carryover_bp,
                                         market_bp, retention_shift_bp=retention_shift_bp)[0] == 0), None)
    cash = START_CENTS
    cum_units = 0
    previous_entitlement = 0
    campaigns = 0
    rows = []
    for month in range(1, HORIZON + 1):
        selected = month >= 2 and ((policy == "once" and month == 2) or
                                   (policy == "repeat") or
                                   (policy == "dormant" and month == dormant_month))
        paid = selected and cash >= cost_cents
        if paid:
            cash -= cost_cents  # Campaign consumes the first of two monthly cycles.
        units, organic, active = month_units(
            review_tenths, awareness, month, carryover_bp, market_bp,
            boost if paid else "none", campaigns, retention_shift_bp)
        base_units = month_units(review_tenths, awareness, month, carryover_bp,
                                 market_bp, retention_shift_bp=retention_shift_bp)[0]
        if paid:
            campaigns += 1
        cum_units += units
        entitlement = prior.net_cents(cum_units)
        settled = entitlement - previous_entitlement
        previous_entitlement = entitlement
        cash += settled - MONTHLY_EXPENSE_CENTS
        rows.append({"month": month, "review_tenths": review_tenths,
                     "launch_awareness": awareness, "organic_awareness_bp": organic,
                     "active_awareness_bp": active, "units": units,
                     "base_units": base_units, "campaign_paid": paid,
                     "campaign_count": campaigns, "settled_cents": settled,
                     "expense_cents": MONTHLY_EXPENSE_CENTS,
                     "cash_cents": cash})
    return {"rows": rows, "dormant_month": dormant_month,
            "campaigns": campaigns, "minimum_cash_cents": min(r["cash_cents"] for r in rows),
            "end_cash_cents": cash}


def main() -> None:
    assert prior.month_one_units(70, 100, 10_000) == 750
    assert prior.net_cents(750) == 524_475
    assert month_units(70, 100, 2, 0)[0] == 125
    assert month_units(70, 100, 2, 0, boost="launch_percent")[0] == 150
    assert [month_units(13, 100, 2, bp)[0] for bp in (0, 1500, 3000)] == [23, 37, 51]
    cases = {}
    raw = []
    for label, (review, awareness) in ANCHORS.items():
        for carryover in (0, 1500, 3000):
            for boost in ("launch_percent", "fixed_10"):
                control = simulate(review, awareness, carryover, boost, "none")
                once = simulate(review, awareness, carryover, boost, "once")
                repeat = simulate(review, awareness, carryover, boost, "repeat")
                dormant = simulate(review, awareness, carryover, boost, "dormant")
                key = f"{label}|carryover{carryover}|{boost}"
                marginal = [r["settled_cents"] - c["settled_cents"] -
                            (10_000 if r["campaign_paid"] else 0)
                            for r, c in zip(repeat["rows"], control["rows"])]
                cases[key] = {"review_tenths": review, "launch_awareness": awareness,
                              "dormant_month": control["dormant_month"],
                              "month1_units": control["rows"][0]["units"],
                              "month2_units_control": control["rows"][1]["units"],
                              "month2_units_campaign": once["rows"][1]["units"],
                              "once_profit_cents": once["end_cash_cents"] - control["end_cash_cents"],
                              "repeat_profit_cents": repeat["end_cash_cents"] - control["end_cash_cents"],
                              "dormant_profit_cents": dormant["end_cash_cents"] - control["end_cash_cents"],
                              "repeat_profitable_months": [i + 1 for i, value in enumerate(marginal) if value > 0],
                              "repeat_campaigns": repeat["campaigns"],
                              "cash_boundaries_cents": {p: [r["cash_cents"] for r in result["rows"]]
                                                        for p, result in (("none", control), ("once", once),
                                                                          ("repeat", repeat), ("dormant", dormant))}}
                raw.append({"case": key, "control": control, "once": once,
                            "repeat": repeat, "dormant": dormant})
    sensitivity = {}
    for label in ("godot_ordinary_median", "godot_optimizer_p90", "synthetic_review_9"):
        review, awareness = ANCHORS[label]
        for carryover in (0, 1500, 3000):
            for boost in ("launch_percent", "fixed_10"):
                for cost in (5000, 10000, 20000):
                    for shift in (-500, 0, 500):
                        none = simulate(review, awareness, carryover, boost, "none", cost, shift)
                        once = simulate(review, awareness, carryover, boost, "once", cost, shift)
                        repeat = simulate(review, awareness, carryover, boost, "repeat", cost, shift)
                        key = f"{label}|c{carryover}|{boost}|cost{cost}|retention{shift}"
                        sensitivity[key] = {"once_profit_cents": once["end_cash_cents"] - none["end_cash_cents"],
                                            "repeat_profit_cents": repeat["end_cash_cents"] - none["end_cash_cents"],
                                            "repeat_count": repeat["campaigns"],
                                            "minimum_cash_cents": repeat["minimum_cash_cents"]}
    result = {"source_revision": "ba616515ed1b039fd0da7cf03f73288fd7ccd8e4",
              "source": "Current Godot Review percentiles from overnight_current_playtest_v1_summary.json; locked Month 1 arithmetic; all Month 2+ and campaign rules candidate only",
              "market_bp": 10_000, "horizon_month_boundaries": HORIZON,
              "carryover_interpretation": "50% of launch Awareness plus the tested 0/15/30% of the separate 200-point discovery baseline; 0 is V1",
              "candidate_start_cents": START_CENTS,
              "candidate_monthly_expense_cents": MONTHLY_EXPENSE_CENTS,
              "cases": cases, "sensitivity": sensitivity}
    (OUT / "post_launch_campaign_followup_v2_summary.json").write_text(json.dumps(result, indent=2) + "\n", encoding="utf-8")
    with gzip.open(OUT / "post_launch_campaign_followup_v2_raw.json.gz", "wt", encoding="utf-8") as output:
        json.dump(raw, output, separators=(",", ":"))
    for key, case in cases.items():
        if "median" in key or "synthetic_review_9" in key or "matched_" in key:
            print(key, "month2", case["month2_units_control"],
                  "once", case["once_profit_cents"], "repeat", case["repeat_profit_cents"],
                  "dormant", case["dormant_profit_cents"])


if __name__ == "__main__":
    main()
