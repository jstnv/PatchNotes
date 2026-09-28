"""Full matched action-calendar replay of candidate Month 2+ and campaigns.

Run: python -B patch-notes/analysis/post_launch_campaign_calendar_followup_v2.py
All later-month, campaign, salary, and bill rules remain unimplemented candidates.
"""
from __future__ import annotations

import gzip
import json
import random
import statistics
from collections import Counter
from pathlib import Path

import post_launch_campaign_followup_v2 as anchors
import post_launch_campaign_playtest_v1 as model
import publisher_cash_payroll_v1 as sampler


OUT = Path(__file__).resolve().parents[1] / "design-logs"
SEED = 26092773
PER_CELL = 10
ANCHOR_NAMES = tuple(k for k in anchors.ANCHORS if k.startswith("godot_") or
                     k in ("synthetic_review_9", "matched_high_awareness_low_review",
                           "matched_low_awareness_high_review"))


def describe(values):
    values = sorted(values)
    return {"n": len(values), "p10": values[int((len(values) - 1) * .1)],
            "median": statistics.median(values),
            "p90": values[int((len(values) - 1) * .9)]}


def pct(flags):
    flags = list(flags)
    return round(100 * sum(flags) / len(flags), 2)


def run_pair(row, review, awareness, carryover, boost, policy,
             employees=1, optional_node=False, cost=10_000, shift=0):
    args = {"employees": employees, "optional_node": optional_node,
            "campaign_cents": cost, "retention_shift_bp": shift,
            "discovery_carryover_bp": carryover, "boost_mode": boost,
            "ironclad_guarantee": True}
    control = model.simulate(row, review, awareness, "none_" + policy, **args)
    treated = model.simulate(row, review, awareness, policy, **args)
    return control, treated


def main():
    rng = random.Random(SEED)
    rows = [sampler.sample_run(target, policy, alignment, rng)
            for target in (7, 13, 19, 20, 21, 22, 23)
            for policy in ("conservative", "ordinary", "optimized")
            for alignment in (0, 1) for _ in range(PER_CELL)]
    assert len(rows) == 420
    assert [model.later_units(13, 100, 10_000, 2,
                              discovery_carryover_bp=c)[0]
            for c in (0, 1500, 3000)] == [23, 37, 51]
    summary = {}
    raw = []
    for label in ANCHOR_NAMES:
        review, awareness = anchors.ANCHORS[label]
        for carryover in (0, 1500, 3000):
            for boost in ("percent", "fixed10"):
                for policy in ("single", "repeat", "dormant"):
                    key = f"{label}|carryover{carryover}|{boost}|{policy}"
                    pairs = [run_pair(row, review, awareness, carryover, boost, policy) for row in rows]
                    none = [x[0] for x in pairs]
                    treated = [x[1] for x in pairs]
                    final_delta = [t["boundaries"][-1]["cash_cents"] - c["boundaries"][-1]["cash_cents"]
                                   for c, t in pairs]
                    summary[key] = {"n": len(pairs),
                                    "month1_units": describe(x["first_release_month_one_units"] for x in treated),
                                    "first_dormant_month": describe(model.first_dormant_month(review, awareness,
                                        row["market_bp"], discovery_carryover_bp=carryover) for row in rows),
                                    "campaign_accepted": describe(x["campaign_accepted"] for x in treated),
                                    "final_cash_delta_cents": describe(final_delta),
                                    "positive_final_delta_pct": pct(x > 0 for x in final_delta),
                                    "control_shortfall_pct": pct(x["first_shortfall"] is not None for x in none),
                                    "campaign_shortfall_pct": pct(x["first_shortfall"] is not None for x in treated),
                                    "first_shortfall_stage": dict(Counter(x["first_shortfall"]["stage"] for x in treated if x["first_shortfall"])),
                                    "monthly_boundary_cash_cents": {
                                        str(m + 1): {"control": describe(x["boundaries"][m]["cash_cents"] for x in none),
                                                     "campaign": describe(x["boundaries"][m]["cash_cents"] for x in treated)}
                                        for m in range(model.HORIZON_BOUNDARIES)}}
                    raw.append({"case": key,
                                "samples": [{"index": i, "target": row["target"], "policy": row["policy"],
                                             "alignment": row["alignment"], "market_bp": row["market_bp"],
                                             "control_cash_cents": [b["cash_cents"] for b in c["boundaries"]],
                                             "campaign_cash_cents": [b["cash_cents"] for b in t["boundaries"]],
                                             "control_shortfall": c["first_shortfall"],
                                             "campaign_shortfall": t["first_shortfall"],
                                             "campaigns": t["campaign_accepted"],
                                             "control_boundary_trace": c["boundaries"] if i < 2 else None,
                                             "campaign_boundary_trace": t["boundaries"] if i < 2 else None}
                                            for i, (row, (c, t)) in enumerate(zip(rows, pairs))]})
    sensitivity = {}
    subset = rows[::6]
    for label in ("godot_ordinary_median", "godot_optimizer_p90", "synthetic_review_9"):
        review, awareness = anchors.ANCHORS[label]
        for carryover in (0, 1500, 3000):
            for boost in ("percent", "fixed10"):
                for employees, optional in ((0, False), (2, False), (1, True)):
                    key = f"{label}|c{carryover}|{boost}|staff{employees}|node{int(optional)}"
                    pairs = [run_pair(row, review, awareness, carryover, boost, "single",
                                      employees, optional) for row in subset]
                    sensitivity[key] = {"n": len(pairs),
                                        "campaign_shortfall_pct": pct(t["first_shortfall"] is not None for _, t in pairs),
                                        "final_cash_delta_cents": describe(t["boundaries"][-1]["cash_cents"] -
                                                                            c["boundaries"][-1]["cash_cents"] for c, t in pairs)}
    output = {"source_revision": "ba616515ed1b039fd0da7cf03f73288fd7ccd8e4",
              "seed": SEED, "per_cell": PER_CELL, "n_rows": len(rows),
              "method": "Same 420 sampled first-game rosters/draw policies, markets, Contract outcomes, half-month alignments and Game 2 actions in each paired control/campaign arm. Current Ironclad $400 upfront plus floor($2000*n/96) remainder. Candidate $75 bill, $100 salary, one-cycle $100 campaign, Month 2+ Awareness and sales. The prior Game 2 Review/Marketing proxy is retained; this is not human play or live later-month gameplay. Candidate later Store node costs one cycle in sensitivity. Failed campaigns are treated as matched neutral productive actions; shortfalls are counterfactual, not permitted negative gameplay cash.",
              "summary": summary, "staff_store_sensitivity": sensitivity}
    (OUT / "post_launch_campaign_calendar_followup_v2_summary.json").write_text(json.dumps(output, indent=2) + "\n", encoding="utf-8")
    with gzip.open(OUT / "post_launch_campaign_calendar_followup_v2_raw.json.gz", "wt", encoding="utf-8") as handle:
        json.dump({"seed": SEED, "rows": rows, "cases": raw}, handle, separators=(",", ":"))
    for key in ("godot_ordinary_median|carryover0|percent|single",
                "godot_ordinary_median|carryover1500|fixed10|single",
                "godot_optimizer_p90|carryover1500|fixed10|single",
                "synthetic_review_9|carryover1500|fixed10|single"):
        x = summary[key]
        print(key, "delta", x["final_cash_delta_cents"],
              "shortfall", x["campaign_shortfall_pct"])


if __name__ == "__main__":
    main()
