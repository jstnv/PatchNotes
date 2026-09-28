"""Read-only studio secondary-trait point/cash trial; no trait is implemented.

Run: python -B patch-notes/analysis/studio_point_budget_trial_v0.py
Uses matched 840 publisher sampler paths, candidate salaries/bills, and Ironclad
guarantee. Game 2 sales and later-month sales are outside the cash horizon.
"""
from __future__ import annotations

import copy
import gzip
import itertools
import json
import random
import statistics
from collections import Counter
from pathlib import Path

import fanbase_playtest_v1 as base
import ironclad_guarantee_cashflow_v1 as cashflow
import publisher_cash_payroll_v1 as source
import studio_trait_choices_v1 as previous


ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "design-logs"
SEED = 26092741
POSITIVES = {"resourceful": 2, "lean": 3, "buzz": 3}
NEGATIVES = {"none": 0, "student_loan": 2, "expensive_lease": 1, "unknown_name": 2}
BACKGROUNDS = ("family", "cult", "publisher")


def builds():
    for count in range(3):
        for selected in itertools.combinations(POSITIVES, count):
            for negative, refund in NEGATIVES.items():
                points = 4 + refund - sum(POSITIVES[p] for p in selected)
                if points >= 0:
                    yield {"positive": selected, "negative": negative,
                           "points_left": points,
                           "conversion_cents": min(30_000, points * 5_000)}


def label(build):
    return "+".join(build["positive"]) if build["positive"] else "none"


def percentile(x, fraction):
    x = sorted(x)
    return x[int((len(x) - 1) * fraction)]


def describe(x):
    x = list(x)
    return {"n": len(x), "p10": percentile(x, .1),
            "median": statistics.median(x), "p90": percentile(x, .9)}


def run(row, background, build, optional_node, staff=1, courses=2,
        store_cycle=1, specialty=False):
    adjusted = copy.deepcopy(row)
    positives = build["positive"]
    negative = build["negative"]
    adjusted["initial_cash"] += build["conversion_cents"] // 100
    if background == "family":
        adjusted["initial_cash"] += 300
    fans = 200 if background == "cult" else 0
    awareness_delta = previous.fan_awareness(fans) + (10 if specialty else 0)
    if "buzz" in positives:
        awareness_delta += 10
    if negative == "unknown_name":
        awareness_delta = max(-100 - row["marketing"], awareness_delta - 15)
    adjusted["units"] = base.units(row["review"], row["marketing"], awareness_delta,
                                   row["market_bp"])
    first_units_delta = adjusted["units"] - row["units"]
    if "lean" in positives:
        adjusted["game1_play_spend"] -= min(100, adjusted["game1_play_spend"] // 10)
        adjusted["game2_play_spend"] -= min(100, adjusted["game2_play_spend"] // 10)
    monthly_extra = 2500 if negative == "student_loan" else 1500 if negative == "expensive_lease" else 0
    publisher_bonus = ((40000 + 200000 * row["contract"]["numerator"] // 96) * 15 // 100
                       if background == "publisher" else 0)
    node_cost = 160000 if optional_node and "resourceful" in positives else 170000
    path = cashflow.run_path(adjusted, 40000, staff, courses, optional_node,
                             monthly_extra_cents=monthly_extra,
                             optional_node_cost_cents=node_cost,
                             store_cycle=store_cycle,
                             contract_bonus_cents=publisher_bonus)
    # No later-month sales implementation exists. This is a zero-new-sales
    # survival bound for the loan's remaining 96 due dates, not a forecast.
    dues_paid = min(96, len(path["boundaries"])) if negative == "student_loan" else 0
    remaining_loan = (96 - dues_paid) * 2500 if negative == "student_loan" else 0
    game2_awareness_delta = previous.fan_awareness(fans) + (10 if specialty else 0)
    if "buzz" in positives:
        game2_awareness_delta += 10
    if negative == "unknown_name":
        game2_awareness_delta -= 15
    game2_proxy_delta_units = base.units(row["review"], row["marketing"],
                                         game2_awareness_delta,
                                         row["market_bp"]) - row["units"]
    return {"path": path, "first_units_delta": first_units_delta,
            "game2_proxy_delta_units": game2_proxy_delta_units,
            "remaining_loan_cents": remaining_loan,
            "post_96_loan_cash_bound_cents": path["checkpoints"]["end_cents"] - remaining_loan,
            "publisher_bonus_cents": publisher_bonus,
            "initial_cash_cents": adjusted["initial_cash"] * 100,
            "feature_savings_cents": (row["game1_play_spend"] + row["game2_play_spend"] -
                                       adjusted["game1_play_spend"] - adjusted["game2_play_spend"]) * 100}


def main():
    rng = random.Random(SEED)
    rows = [source.sample_run(target, policy, alignment, rng)
            for target in (7, 13, 19, 20, 21, 22, 23)
            for policy in ("conservative", "ordinary", "optimized")
            for alignment in (0, 1) for _ in range(20)]
    assert len(rows) == 840
    all_builds = list(builds())
    assert len({(b["positive"], b["negative"]) for b in all_builds}) == len(all_builds)
    assert next(b for b in all_builds if b["positive"] == () and b["negative"] == "student_loan")["conversion_cents"] == 30000
    summary = {}
    raw = []
    for background in BACKGROUNDS:
        for build in all_builds:
            for optional in (False, True):
                key = f"{background}|{label(build)}|{build['negative']}|node{int(optional)}"
                outcomes = [run(row, background, build, optional) for row in rows]
                summary[key] = {"n": len(rows), "points_left": build["points_left"],
                                "conversion_cents": build["conversion_cents"],
                                "shortfall_pct": round(100 * sum(o["path"]["first_shortfall"] is not None for o in outcomes) / len(rows), 2),
                                "first_shortfall_stage": dict(Counter(o["path"]["first_shortfall"]["stage"] for o in outcomes if o["path"]["first_shortfall"])),
                                "studio_cash_cents": describe(o["path"]["checkpoints"]["studio_entry_cents"] for o in outcomes),
                                "game2_release_cash_cents": describe(o["path"]["checkpoints"]["end_cents"] for o in outcomes),
                                "post_96_loan_cash_bound_cents": describe(o["post_96_loan_cash_bound_cents"] for o in outcomes),
                                "first_units_delta": describe(o["first_units_delta"] for o in outcomes),
                                "game2_proxy_units_delta": describe(o["game2_proxy_delta_units"] for o in outcomes),
                                "feature_savings_cents": describe(o["feature_savings_cents"] for o in outcomes),
                                "publisher_bonus_cents": describe(o["publisher_bonus_cents"] for o in outcomes)}
                raw.append({"case": key, "build": build,
                            "outcomes": [{"index": i, "target": row["target"], "policy": row["policy"],
                                          "alignment": row["alignment"],
                                          "first_units_delta": o["first_units_delta"],
                                          "game2_proxy_delta_units": o["game2_proxy_delta_units"],
                                          "shortfall": o["path"]["first_shortfall"],
                                          "studio_cash_cents": o["path"]["checkpoints"]["studio_entry_cents"],
                                          "end_cents": o["path"]["checkpoints"]["end_cents"],
                                          "boundaries": o["path"]["boundaries"] if i < 2 else None}
                                         for i, (row, o) in enumerate(zip(rows, outcomes))]})
    sensitivity = {}
    selected = [b for b in all_builds if (b["positive"], b["negative"]) in
                (((), "none"), ((), "student_loan"), (("resourceful", "lean"), "student_loan"),
                 (("resourceful", "buzz"), "student_loan"))]
    for staff in (0, 1, 2):
        for store_cycle in (0, 1):
            for build in selected:
                key = f"staff{staff}|storecycle{store_cycle}|{label(build)}|{build['negative']}"
                outcomes = [run(row, "family", build, True, staff, 0, store_cycle) for row in rows]
                sensitivity[key] = {"n": len(rows), "shortfall_pct": round(100 * sum(o["path"]["first_shortfall"] is not None for o in outcomes) / len(rows), 2),
                                    "end_cash_cents": describe(o["path"]["checkpoints"]["end_cents"] for o in outcomes)}
    output = {"source_revision": "ba616515ed1b039fd0da7cf03f73288fd7ccd8e4",
              "seed": SEED, "n": len(rows), "valid_build_count": len(all_builds),
              "notes": "All secondary values, $75 bill, $100 salary, $25/course raise, one-cycle optional node and backgrounds' numerical effects are trial-only. No Game 2 sales; its Unknown Name units use Game 1 Review/Marketing/market as an explicit proxy. The 96-due loan bound excludes future sales and ordinary bills/payroll. Store cycle 0 sensitivity reflects current runtime conflict.",
              "summary": summary, "sensitivity": sensitivity}
    (OUT / "studio_point_budget_trial_v0_summary.json").write_text(json.dumps(output, indent=2) + "\n", encoding="utf-8")
    with gzip.open(OUT / "studio_point_budget_trial_v0_raw.json.gz", "wt", encoding="utf-8") as handle:
        json.dump({"seed": SEED, "rows": rows, "cases": raw}, handle, separators=(",", ":"))
    print("n", len(rows), "valid builds", len(all_builds))
    for name in ("family|none|none|node1", "family|none|student_loan|node1",
                 "family|lean|none|node1", "family|resourceful+lean|student_loan|node1",
                 "cult|none|none|node1", "publisher|none|none|node1"):
        if name in summary:
            x = summary[name]
            print(name, "shortfall", x["shortfall_pct"],
                  "end median", x["game2_release_cash_cents"]["median"],
                  "loan96 bound", x["post_96_loan_cash_bound_cents"]["median"])


if __name__ == "__main__":
    main()
