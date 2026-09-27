"""Read-only, paired Ironclad guarantee and payroll cash-flow trial.

No gameplay state is read or written. All cash is integer cents. The source
sample is publisher_cash_payroll_v1.sample_run, reused for every scenario.
"""
from __future__ import annotations

import gzip
import json
import random
import statistics
import sys
from collections import Counter, defaultdict
from pathlib import Path

import publisher_cash_payroll_v1 as source

OUT = Path(__file__).resolve().parents[1] / "design-logs"
BONUSES = (0, 25000, 40000, 60000)
PROFILES = ((0, 0), (1, 0), (1, 2), (2, 2))
CAP = 240000


def reward(numerator: int, bonus_cents: int) -> tuple[int, int]:
    assert 0 <= numerator <= 96 and bonus_cents in BONUSES
    return bonus_cents, (CAP - bonus_cents) * numerator // 96


def describe(values):
    if not values:
        return None
    return source.describe(values)


def run_path(row, bonus_cents, staff, courses_per_staff, optional_node=False,
             bill_from_start=True, hire_boundary="same", raise_boundary="same"):
    """Hypothetical direct effects -> cycle -> earned sales -> net month boundary.

    All Game 1/2 play fees are charged before their modeled hands, a deliberate
    conservative liquidity bound inherited from the source trial. A negative
    balance records the first failed action; the path continues counterfactually
    so paired downstream cash can be compared.
    """
    cash = row["initial_cash"] * 100
    cycle = row["alignment"]
    minimum = cash
    failure = None
    boundaries = []
    checkpoints = {}
    hired = 0
    completed_courses = 0
    payroll_staff = 0
    payroll_courses = 0
    released = False
    sales_cycles = 0
    earned = settled = 0
    first_sales = (row["units"] // 2) * 999 * 70 // 100
    all_sales = row["units"] * 999 * 70 // 100

    def record(label):
        nonlocal minimum, failure
        minimum = min(minimum, cash)
        if cash < 0 and failure is None:
            failure = {"stage": label, "cycle": cycle, "shortfall_cents": -cash}

    def charge(amount, label):
        nonlocal cash
        cash -= amount
        record(label)

    def tick(label):
        nonlocal cycle, cash, sales_cycles, earned, settled, payroll_staff, payroll_courses
        cycle += 1
        if released:
            sales_cycles = min(2, sales_cycles + 1)
            earned = first_sales if sales_cycles == 1 else all_sales
        if cycle % 2 == 0:
            prior = cash
            sales = earned - settled
            bill = 7500 if bill_from_start or released else 0
            payroll = (payroll_staff * 10000 + payroll_courses * 2500) if released else 0
            cash += sales - bill - payroll  # One exact-cent net transaction.
            settled = earned
            boundaries.append({"cycle": cycle, "month": cycle // 2 + 1,
                               "stage": label, "before_cents": prior,
                               "sales_cents": sales, "bill_cents": bill,
                               "payroll_cents": payroll, "after_cents": cash})
            record(label + " month boundary")
            if hire_boundary == "next":
                payroll_staff = hired
            if raise_boundary == "next":
                payroll_courses = completed_courses
        record(label)

    charge(row["game1_play_spend"] * 100, "Game 1 Feature play")
    for _ in range(row["game1_cycles"]):
        tick("Game 1")
    released = True
    checkpoints["studio_entry_cents"] = cash

    # One productive cycle per hire; the hiring-cycle boundary can affect both
    # first sales settlement and first payroll. Same-boundary is the main case.
    for _ in range(staff):
        hired += 1
        if hire_boundary == "same":
            payroll_staff = hired
        tick("Hire")
    checkpoints["before_acceptance_cents"] = cash
    upfront, remainder = reward(row["contract"]["numerator"], bonus_cents)
    cash += upfront  # Acceptance itself never advances a cycle.
    checkpoints["after_upfront_cents"] = cash
    tick("Contract hand 1")
    checkpoints["after_hand_1_cents"] = cash
    cash += remainder  # Completion direct effect precedes its cycle boundary.
    tick("Contract hand 2")
    checkpoints["after_hand_2_cents"] = cash

    for _ in range(staff * courses_per_staff):
        completed_courses += 1
        if raise_boundary == "same":
            payroll_courses = completed_courses
        tick("Course")
    if row["reserve_id"] is None:
        failure = failure or {"stage": "No eligible Scope-2 reserve", "cycle": cycle,
                              "shortfall_cents": 0}
    else:
        charge(45000, "Reserve Feature purchase")
        tick("Reserve Feature purchase")
    if optional_node:
        charge(170000, "Optional Store node")
        tick("Optional Store node")
    charge(row["game2_play_spend"] * 100, "Game 2 Feature play")
    for _ in range(row["game2_cycles"]):
        tick("Game 2")
    checkpoints["end_cents"] = cash
    return {"minimum_cents": minimum, "first_shortfall": failure,
            "boundaries": boundaries, "checkpoints": checkpoints,
            "upfront_cents": upfront, "remainder_cents": remainder,
            "total_reward_cents": upfront + remainder,
            "sales_earned_cents": earned, "sales_settled_cents": settled}


def summarize_paths(rows, paths):
    failures = [p["first_shortfall"] for p in paths]
    return {"n": len(paths),
            "shortfall_pct": round(100 * sum(f is not None for f in failures) / len(paths), 2),
            "minimum_cash_cents": describe([p["minimum_cents"] for p in paths]),
            "first_shortfall_stage_counts": dict(Counter(f["stage"] for f in failures if f)),
            "first_shortfall_amount_cents": describe([f["shortfall_cents"] for f in failures if f]),
            "checkpoints_cents": {k: describe([p["checkpoints"][k] for p in paths])
                                  for k in paths[0]["checkpoints"]},
            "month_boundaries": {str(c): {"n": len(items),
                    "cash_after_cents": describe([b["after_cents"] for b in items]),
                    "sales_cents": describe([b["sales_cents"] for b in items]),
                    "bill_cents": describe([b["bill_cents"] for b in items]),
                    "payroll_cents": describe([b["payroll_cents"] for b in items])}
                    for c, items in sorted(_by_cycle(paths).items())},
            "total_reward_cents": describe([p["total_reward_cents"] for p in paths])}


def _by_cycle(paths):
    grouped = defaultdict(list)
    for p in paths:
        for b in p["boundaries"]:
            grouped[b["cycle"]].append(b)
    return grouped


def bands(rows, paths):
    def group(labeler):
        grouped = defaultdict(list)
        for row, path in zip(rows, paths):
            grouped[labeler(row)].append(path)
        return {str(k): {"n": len(v), "shortfall_pct": round(100 * sum(
                    p["first_shortfall"] is not None for p in v) / len(v), 2),
                    "minimum_cash_cents": describe([p["minimum_cents"] for p in v])}
                for k, v in sorted(grouped.items())}
    def review_band(r):
        x = r["review"]
        return "0-.7" if x <= .7 else ".8-1.7" if x <= 1.7 else "1.8-3" if x <= 3 else "3.1-5" if x <= 5 else "5.1-10"
    def completion_band(r):
        n = r["contract"]["numerator"]
        return "0-24" if n <= 24 else "25-48" if n <= 48 else "49-72" if n <= 72 else "73-96"
    cash_order = sorted(range(len(rows)), key=lambda i: (rows[i]["initial_cash"], i))
    decile = {}
    for d in range(10):
        indices = cash_order[d * len(rows) // 10:(d + 1) * len(rows) // 10]
        subset = [paths[i] for i in indices]
        decile[str(d + 1)] = {"initial_cash_dollars_range": [rows[indices[0]]["initial_cash"], rows[indices[-1]]["initial_cash"]],
                "n": len(subset), "shortfall_pct": round(100 * sum(p["first_shortfall"] is not None for p in subset) / len(subset), 2)}
    return {"review": group(review_band), "starter_scope_target": group(lambda r: r["target"]),
            "starter_spend_dollars": group(lambda r: r["acquisition"]),
            "contract_completion_numerator": group(completion_band),
            "initial_cash_decile": decile}


def main(seed=260927, per_cell=150):
    rng = random.Random(seed)
    rows = [source.sample_run(target, policy, alignment, rng)
            for target in (7, 13, 19, 20, 21, 22, 23)
            for policy in ("conservative", "ordinary", "optimized")
            for alignment in (0, 1) for _ in range(per_cell)]
    scenarios = {}
    OUT.mkdir(exist_ok=True)
    raw_path = OUT / "ironclad_guarantee_cashflow_v1_results.json.gz"
    with gzip.open(raw_path, "wt", encoding="utf-8") as output:
        output.write(json.dumps({"type": "sample", "rows": rows}, separators=(",", ":")) + "\n")
        for staff, courses in PROFILES:
            for optional in (False, True):
                for bonus in BONUSES:
                    key = f"staff{staff}_courses{courses}_node{int(optional)}_bonus{bonus//100}"
                    paths = [run_path(r, bonus, staff, courses, optional) for r in rows]
                    scenarios[key] = summarize_paths(rows, paths)
                    if staff == 1 and courses == 2:
                        scenarios[key]["by_band"] = bands(rows, paths)
                    output.write(json.dumps({"type": "scenario", "name": key, "paths": paths}, separators=(",", ":")) + "\n")
    sensitivity = {}
    for bill_start, hire_boundary, raise_boundary in ((False, "same", "same"),
                 (True, "next", "same"), (True, "same", "next"),
                 (False, "next", "next")):
        for bonus in BONUSES:
            key = f"bill_start{int(bill_start)}_hire{hire_boundary}_raise{raise_boundary}_bonus{bonus//100}"
            paths = [run_path(r, bonus, 1, 2, False, bill_start, hire_boundary, raise_boundary) for r in rows]
            sensitivity[key] = {"shortfall_pct": summarize_paths(rows, paths)["shortfall_pct"],
                                "minimum_cash_cents": describe([p["minimum_cents"] for p in paths])}
    result = {"version": 1, "seed": seed, "per_cell": per_cell, "n": len(rows),
              "paired": True, "candidate_only": True,
              "cash_formula": "bonus + floor((240000 - bonus) * numerator / 96)",
              "reward_examples_cents": {str(b//100): {str(n): sum(reward(n, b)) for n in (0, 24, 48, 72, 96)} for b in BONUSES},
              "contract_numerator": describe([r["contract"]["numerator"] for r in rows]),
              "review": describe([r["review"] for r in rows]),
              "scenarios": scenarios, "timing_sensitivity": sensitivity,
              "model_boundaries": ["Game 1 play charged upfront as conservative bound",
                   "hire zero fee, one productive cycle, before Contract acceptance",
                   "course zero fee, one productive cycle, after Contract completion",
                   "same-boundary payroll and raise is main case; delayed variants tested",
                   "month boundary nets earned Game 1 sales with bill and payroll once",
                   "Game 2 sales and later-month sales excluded", "paths after shortfall are counterfactual"]}
    summary_path = OUT / "ironclad_guarantee_cashflow_v1_summary.json"
    summary_path.write_text(json.dumps(result, indent=2), encoding="utf-8")
    print(json.dumps({"n": len(rows), "summary": str(summary_path), "raw": str(raw_path),
                      "shortfall_pct": {k: v["shortfall_pct"] for k, v in scenarios.items()},
                      "reward_examples_cents": result["reward_examples_cents"]}, indent=2))


if __name__ == "__main__":
    main(int(sys.argv[1]) if len(sys.argv) > 1 else 260927,
         int(sys.argv[2]) if len(sys.argv) > 2 else 150)
