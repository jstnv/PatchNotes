"""Read-only, release-linked SideStreet cash-cap trial; no offer is implemented.

Reuses the 6,300-path publisher policy sampler unchanged. SideStreet Contract
draws have independent deterministic RNG streams and distinct local exhaustion.
Run: python -B patch-notes/analysis/sidestreet_repeatable_cash_trial_v1.py
"""
from __future__ import annotations

import gzip
import json
import math
import random
import statistics
from collections import Counter, defaultdict
from pathlib import Path

import fanbase_playtest_v1 as base
import publisher_cash_payroll_v1 as prior

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "design-logs"
SEED = 260927
CAPS = (80000, 120000, 160000)
TARGETS = (7, 13, 19, 20, 21, 22, 23)
POLICIES = ("conservative", "ordinary", "optimized")


def describe(values):
    values = sorted(values)
    return {"n": len(values), "p10": values[int((len(values) - 1) * .1)],
            "median": statistics.median(values), "p90": values[int((len(values) - 1) * .9)]}


def sample_rows(per_cell=150):
    rng = random.Random(SEED)
    rows = []
    for target in TARGETS:
        for policy in POLICIES:
            for alignment in (0, 1):
                for _ in range(per_cell):
                    index = len(rows)
                    copy = random.Random()
                    copy.setstate(rng.getstate())
                    owned, spent = base.roster(target, copy)
                    row = prior.sample_run(target, policy, alignment, rng)
                    assert row["acquisition"] == spent
                    reserve = row["reserve_id"]
                    owned2 = owned | ({reserve} if reserve else set())
                    side1 = prior.contract(owned, policy, random.Random(SEED * 100000 + index * 2 + 1))
                    side2 = prior.contract(owned2, policy, random.Random(SEED * 100000 + index * 2 + 2))
                    assert 0 <= side1["numerator"] <= 96 and 0 <= side2["numerator"] <= 96
                    rows.append({"index": index, "row": row, "starter_ids": sorted(owned),
                                 "side1": side1, "side2": side2})
    return rows


def simulate(item, cap, order="early", staff=1, courses=0, optional_node=False,
             store_cycle=1, game2_units_mode="none", bill_from_start=True):
    row, first, second = item["row"], item["side1"], item["side2"]
    cash = row["initial_cash"] * 100
    cycle = row["alignment"]
    minimum = cash
    first_shortfall = None
    releases = []
    boundaries = []
    checkpoints = {}
    completed_contracts = []
    hired = 0
    course_count = 0

    def record(stage):
        nonlocal minimum, first_shortfall
        minimum = min(minimum, cash)
        if cash < 0 and first_shortfall is None:
            first_shortfall = {"stage": stage, "cycle": cycle, "shortfall_cents": -cash}

    def add(amount, stage):
        nonlocal cash
        cash += amount
        record(stage)

    def tick(stage, direct_cash_delta=0):
        nonlocal cycle, cash
        cycle += 1
        cash += direct_cash_delta  # RunState applies direct cash before settlement.
        for release in releases:
            release["earned_cycles"] = min(2, release["earned_cycles"] + 1)
            earned_units = release["units"] * release["earned_cycles"] // 2
            release["entitlement_cents"] = earned_units * 999 * 70 // 100
        if cycle % 2 == 0:
            sales = sum(release["entitlement_cents"] - release["settled_cents"] for release in releases)
            bill = 7500 if bill_from_start or releases else 0
            payroll = hired * 10000 + course_count * 2500
            cash += sales - bill - payroll
            for release in releases:
                release["settled_cents"] = release["entitlement_cents"]
            boundaries.append({"cycle": cycle, "stage": stage, "sales_cents": sales,
                               "bill_cents": bill, "payroll_cents": payroll, "cash_cents": cash})
        record(stage)

    def ironclad():
        assert len(releases) >= 1
        add(40000, "Ironclad acceptance")
        tick("Ironclad hand 1")
        tick("Ironclad hand 2", 200000 * row["contract"]["numerator"] // 96)
        completed_contracts.append("ironclad_release_1")
        checkpoints["after_ironclad_cents"] = cash

    def side(which, result):
        assert len(releases) >= which
        checkpoints[f"before_side_{which}_cents"] = cash
        tick(f"SideStreet {which} hand 1")
        tick(f"SideStreet {which} hand 2", cap * result["numerator"] // 96)
        completed_contracts.append(f"sidestreet_release_{which}")
        checkpoints[f"after_side_{which}_cents"] = cash

    def game2():
        assert row["reserve_id"] is not None
        add(-45000, "Game 2 Primitive reserve")
        tick("Game 2 Primitive reserve")
        if optional_node:
            add(-170000, "Optional Store node")
            if store_cycle:
                tick("Optional Store node")
        add(-row["game2_play_spend"] * 100, "Game 2 Feature play")
        checkpoints["before_game2_cents"] = cash
        for _ in range(row["game2_cycles"]):
            tick("Game 2")
        units = row["units"] if game2_units_mode == "game1_proxy" else 0
        releases.append({"id": "release_2", "units": units, "earned_cycles": 0,
                         "entitlement_cents": 0, "settled_cents": 0})
        checkpoints["after_game2_release_cents"] = cash

    add(-row["game1_play_spend"] * 100, "Game 1 Feature play")
    for _ in range(row["game1_cycles"]):
        tick("Game 1")
    releases.append({"id": "release_1", "units": row["units"], "earned_cycles": 0,
                     "entitlement_cents": 0, "settled_cents": 0})
    checkpoints["studio_entry_cents"] = cash
    for _ in range(staff):
        tick("Hire")
        hired += 1  # Candidate next-boundary payroll entry; same-boundary timing is unresolved.
    if order == "early":
        ironclad()
        side(1, first)
    for _ in range(staff * courses):
        tick("Course")
        course_count += 1  # Candidate next-boundary raise.
    game2()
    if order == "late":
        ironclad()
        side(1, first)
    side(2, second)
    checkpoints["end_cents"] = cash
    assert len(releases) == 2 and len(completed_contracts) == 3 and len(set(completed_contracts)) == 3
    return {"minimum_cents": minimum, "first_shortfall": first_shortfall,
            "checkpoints": checkpoints, "boundaries": boundaries,
            "contracts": completed_contracts, "starwave_gate_met": True,
            "starwave_gate_feasible": first_shortfall is None,
            "side1_payout_cents": cap * first["numerator"] // 96,
            "side2_payout_cents": cap * second["numerator"] // 96,
            "sales_earned_cents": sum(r["entitlement_cents"] for r in releases),
            "sales_settled_cents": sum(r["settled_cents"] for r in releases)}


def main():
    samples = sample_rows()
    assert len(samples) == 6300
    cases = {}
    raw = []
    for cap in CAPS:
        for order in ("early", "late"):
            for staff, courses, optional in ((0, 0, False), (1, 0, False), (1, 2, False),
                                             (2, 2, False), (1, 2, True), (2, 2, True)):
                key = f"cap{cap}_order{order}_staff{staff}_courses{courses}_node{int(optional)}"
                results = [simulate(item, cap, order, staff, courses, optional) for item in samples]
                cases[key] = {"n": len(results), "shortfall_pct": round(100 * sum(x["first_shortfall"] is not None for x in results) / len(results), 2),
                              "minimum_cash_cents": describe(x["minimum_cents"] for x in results),
                              "first_shortfall_stage_counts": dict(Counter(x["first_shortfall"]["stage"] for x in results if x["first_shortfall"])),
                              "cash_checkpoints_cents": {name: describe(x["checkpoints"][name] for x in results)
                                                         for name in results[0]["checkpoints"]},
                              "first_payout_cents": describe(x["side1_payout_cents"] for x in results),
                              "second_payout_cents": describe(x["side2_payout_cents"] for x in results),
                              "starwave_reached_if_counterfactual_actions_allowed": sum(x["starwave_gate_met"] for x in results),
                              "starwave_reached_on_nonnegative_path": sum(x["starwave_gate_feasible"] for x in results)}
                # Store all matched outcome rows, but full boundary traces only for a few
                # reproducible examples; the script recomputes every boundary exactly.
                raw.append({"case": key,
                            "items": [{"index": item["index"], "target": item["row"]["target"],
                                       "policy": item["row"]["policy"], "alignment": item["row"]["alignment"],
                                       "ironclad_numerator": item["row"]["contract"]["numerator"],
                                       "side1_numerator": item["side1"]["numerator"], "side2_numerator": item["side2"]["numerator"],
                                       "minimum_cents": result["minimum_cents"], "first_shortfall": result["first_shortfall"],
                                       "checkpoints": result["checkpoints"],
                                       "boundaries": result["boundaries"] if item["index"] < 3 else None}
                                      for item, result in zip(samples, results)]})
    sensitivities = {}
    for cap in CAPS:
        for mode in ("none", "game1_proxy"):
            for store_cycle in (0, 1):
                subset = samples[::6]
                result = [simulate(item, cap, "early", 1, 2, True, store_cycle, mode) for item in subset]
                sensitivities[f"cap{cap}_{mode}_storecycle{store_cycle}"] = {
                    "n": len(result), "shortfall_pct": round(100 * sum(x["first_shortfall"] is not None for x in result) / len(result), 2),
                    "end_cash_cents": describe(x["checkpoints"]["end_cents"] for x in result)}
    summary = {"seed": SEED, "n": len(samples), "caps_cents": CAPS,
               "side_numerator_1": describe(x["side1"]["numerator"] for x in samples),
               "side_numerator_2": describe(x["side2"]["numerator"] for x in samples),
               "cases": cases, "sensitivities": sensitivities,
               "source": "publisher_cash_payroll_v1 policy sampler and Contract draw port; not live SideStreet gameplay"}
    (OUT / "sidestreet_repeatable_cash_trial_v1_summary.json").write_text(json.dumps(summary, indent=2) + "\n", encoding="utf-8")
    with gzip.open(OUT / "sidestreet_repeatable_cash_trial_v1_raw.json.gz", "wt", encoding="utf-8") as out:
        json.dump({"seed": SEED, "samples": [{"index": x["index"], "row": x["row"], "starter_ids": x["starter_ids"],
                                             "side1": x["side1"], "side2": x["side2"]} for x in samples],
                   "cases": raw, "sensitivities": sensitivities}, out, separators=(",", ":"))
    print(json.dumps({"n": len(samples), "side1": summary["side_numerator_1"], "side2": summary["side_numerator_2"],
                      "selected_cases": {key: {k: value[k] for k in ("shortfall_pct", "first_payout_cents", "second_payout_cents")}
                                         for key, value in cases.items() if "orderearly_staff1_courses2_node1" in key}}, indent=2))


if __name__ == "__main__":
    main()
