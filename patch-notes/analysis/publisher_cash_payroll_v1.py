"""Read-only publisher cash/payroll sensitivity using current Primitive data.

Run from any directory: python analysis/publisher_cash_payroll_v1.py [seed] [per_cell]
This ports Godot rules; it does not alter a saved run or implement expenses.
"""
from __future__ import annotations

import itertools
import json
import math
import random
import statistics
import sys
from collections import Counter, defaultdict
from pathlib import Path

import fanbase_playtest_v1 as base

ROOT = Path(__file__).resolve().parents[1]
CORES = base.CORES
PASSES = base.PASSES
FEATURES = base.FEATURES
BY_ID = base.BY_ID
BETA = base.BETA


def beta_v2(bugs, policy, rng):
    """Current Beta card draw/selection port, including Marketing Specialization."""
    if policy == "conservative":
        return bugs, 0, 0, 0
    hidden, known, marketing = bugs, 0, 0
    old_marketing = 0
    specialized_hands = 0
    exhausted = set()
    hands = 2 if policy == "ordinary" else 4
    priority = {"qa": 35, "marketing": 35, "insider": 30} if policy == "ordinary" else {"qa": 50, "marketing": 35, "insider": 15}
    for _ in range(hands):
        pool = base.draw_beta(exhausted, priority, rng)
        ranked = sorted(range(7), key=lambda i: (
            (10 if pool[i]["id"] == "search_for_bugs" and hidden else 0)
            + (10 if pool[i]["id"] == "debug" and (known or hidden) else 0)
            + (pool[i]["beta_value"] * (2 if policy == "optimized" else 1) if pool[i]["beta_category"] == "marketing" else 0)
            + rng.random() * .01), reverse=True)
        chosen = [pool[i] for i in ranked[:4]]
        counts = Counter(c["beta_category"] for c in chosen)
        qa_special = counts["qa"] == 4
        marketing_special = counts["marketing"] == 4
        balanced = all(1 <= counts[x] <= 2 for x in ("qa", "marketing", "insider"))
        raw_marketing = sum(c["beta_value"] for c in chosen if c["beta_category"] == "marketing")
        old_marketing += math.ceil(raw_marketing * 1.25) if balanced else raw_marketing
        specialized_hands += int(marketing_special)
        marketing += math.floor(raw_marketing * 1.5) if marketing_special else math.ceil(raw_marketing * 1.25) if balanced else raw_marketing
        for c in chosen:
            if c["id"] == "search_for_bugs":
                v = c["beta_value"] * (1.5 if qa_special else 1)
                request = math.floor(1 + v + hidden * .15 * v)
                if balanced: request = math.ceil(request * 1.25)
                moved = min(hidden, request)
                hidden -= moved
                known += moved
            elif c["id"] == "debug":
                v = c["beta_value"] * (1.5 if qa_special else 1)
                request = math.floor(1 + v)
                if balanced: request = math.ceil(request * 1.25)
                known -= min(known, request)
            if not c["renewable"]:
                exhausted.add(c["id"])
    return hidden + known, marketing, old_marketing, specialized_hands


def draw_contract(owned, exhausted, rng):
    """ContractPhase: equal Core category priorities, uniform sorted definitions."""
    pool, reserved = [], set(exhausted)
    for _ in range(7):
        groups = {core: [] for core in CORES}
        for c in FEATURES:
            if c["id"] in owned and c["id"] not in reserved:
                groups[c["primary_stat"]].append(c)
        for c in PASSES:
            groups[c["primary_stat"]].append(c)
        category = rng.choice([core for core in CORES if groups[core]])
        card = rng.choice(sorted(groups[category], key=lambda x: x["id"]))
        pool.append(card)
        if card["type"] == "feature": reserved.add(card["id"])
    return pool


def redraw_contract_one(pool, position, owned, exhausted, rng):
    old = pool[position]
    if old["type"] == "feature":
        reserved = {c["id"] for c in pool if c["type"] == "feature"}
        eligible = [c for c in FEATURES if c["id"] in owned and c["id"] not in exhausted and c["id"] not in reserved]
    else:
        eligible = [c for c in PASSES if c["id"] != old["id"]]
    groups = {core: sorted([c for c in eligible if c["primary_stat"] == core], key=lambda x: x["id"]) for core in CORES}
    categories = [core for core in CORES if groups[core]]
    if not categories:
        return False
    pool[position] = rng.choice(groups[rng.choice(categories)])
    return True


def contract(owned, policy, rng):
    scope = 0
    half = {core: 0 for core in CORES}
    exhausted = set()
    redraws = 4
    used_redraws = 0
    for _ in range(2):
        pool = draw_contract(owned, exhausted, rng)
        attempts = 0 if policy == "conservative" else 1 if policy == "ordinary" else 2
        for _ in range(min(redraws, attempts)):
            index = min(range(7), key=lambda i: (pool[i]["scope"] * 4 + base.printed(pool[i]), i))
            if redraw_contract_one(pool, index, owned, exhausted, rng):
                redraws -= 1
                used_redraws += 1
        if policy == "conservative":
            hand = rng.sample(pool, 4)
        else:
            choices = []
            for indices in itertools.combinations(range(7), 4):
                cards = [pool[i] for i in indices]
                same = len({c["primary_stat"] for c in cards}) == 1
                factor = 3 if same else 2
                additions = {k: sum((c["primary_value"] if c["primary_stat"] == k else 0) +
                                    (c["secondary_value"] if c.get("secondary_stat") == k else 0) for c in cards) * factor for k in CORES}
                gained_scope = sum(c["scope"] for c in cards)
                after = {k: half[k] + additions[k] for k in CORES}
                numerator = 4 * min(12, scope + gained_scope) + sum(min(12, after[k]) for k in CORES)
                score = numerator + (0.01 * gained_scope if policy == "optimized" else 0)
                choices.append((score + rng.random() * .000001, indices))
            hand = [pool[i] for i in max(choices)[1]]
        same = len({c["primary_stat"] for c in hand}) == 1
        factor = 3 if same else 2
        scope += sum(c["scope"] for c in hand)
        for c in hand:
            half[c["primary_stat"]] += c["primary_value"] * factor
            if c.get("secondary_stat"):
                half[c["secondary_stat"]] += c["secondary_value"] * factor
            if c["type"] == "feature": exhausted.add(c["id"])
        redraws = min(4, redraws + 1)
    numerator = 4 * min(scope, 12) + sum(min(half[k], 12) for k in CORES)
    return {"scope": scope, "core_half": half, "redraws": used_redraws, "numerator": numerator,
            "completion_pct": round(numerator * 100 / 96, 2), "payout_cents": 240000 * numerator // 96}


def percentile(values, p):
    x = sorted(values)
    return x[min(len(x) - 1, math.floor((len(x) - 1) * p))]


def describe(values):
    return {"p10": percentile(values, .1), "median": statistics.median(values),
            "p90": percentile(values, .9), "mean": round(statistics.mean(values), 2)}


def sample_run(target, policy, alignment, rng):
    owned, acquisition = base.roster(target, rng)
    cash_at_start = 5500 - acquisition
    scores, scope, bugs, after_play, redraws, synergies, hands = base.production(owned, policy, rng, cash_at_start)
    spent_play = cash_at_start - after_play
    bugs_final, marketing, old_marketing, specialized_hands = beta_v2(bugs, policy, rng)
    genre = base.choose_genre(owned, policy, rng)
    review, rating, completion, fit, deviation = base.review(scores, scope, bugs_final, genre, rng)
    market_bp = base.market(rng)
    units = base.units(review, marketing, 0, market_bp)
    old_units = base.units(review, old_marketing, 0, market_bp)
    contract_result = contract(owned, policy, rng)
    # One unowned Scope-2 Primitive reserve: the cheapest lean Game 2 path.
    reserves = [c for c in FEATURES if c["id"] not in owned and c["scope"] == 2]
    reserve = rng.choice(reserves) if reserves else None
    owned2 = owned | ({reserve["id"]} if reserve else set())
    _, _, _, after_game2_play, _, _, game2_hands = base.production(owned2, policy, rng, 100000)
    game2_play_spend = 100000 - after_game2_play
    beta_hands = 0 if policy == "conservative" else 2 if policy == "ordinary" else 4
    game1_cycles = 1 + hands + beta_hands  # Begin Development + successful hands.
    game2_cycles = 1 + game2_hands + beta_hands
    return {"target": target, "policy": policy, "alignment": alignment, "acquisition": acquisition,
            "initial_cash": cash_at_start, "game1_play_spend": spent_play, "game1_hands": hands,
            "game1_cycles": game1_cycles, "game2_cycles": game2_cycles,
            "game2_play_spend": game2_play_spend, "reserve_id": reserve["id"] if reserve else None,
            "scores": scores, "scope": scope, "bugs": bugs_final, "marketing": marketing,
            "review": review, "fit": fit, "units": units, "old_units": old_units,
            "old_marketing": old_marketing, "marketing_special_hands": specialized_hands, "market_bp": market_bp,
            "contract": contract_result, "synergies": synergies, "redraws": redraws}


def cash_path(row, employees, courses_per_employee, bill=75, salary=100, raise_per_course=25,
              optional_node=False, bill_from_start=True, expense_after_settlement=True, payout_scale=1.0):
    """Candidate expense schedule. The cash-only Ironclad payout is the runtime case."""
    cash = row["initial_cash"] * 100
    cycle = row["alignment"]
    min_cash = cash
    failure = None
    checkpoints = {}
    cycle_lows = {cycle: cash}
    first_sales = (row["units"] // 2) * 999 * 70 // 100
    all_sales = row["units"] * 999 * 70 // 100
    earned = settled = sales_cycles = 0
    stage = ""
    completed_courses = 0

    def charge(amount, label):
        nonlocal cash, min_cash, failure
        cash -= amount
        min_cash = min(min_cash, cash)
        cycle_lows[cycle] = min(cycle_lows.get(cycle, cash), cash)
        if cash < 0 and failure is None:
            failure = {"stage": label, "cycle": cycle, "shortfall_cents": -cash}

    def tick(label, payout=0):
        nonlocal cycle, cash, earned, settled, sales_cycles, min_cash, failure
        cycle += 1
        cash += payout
        if label.startswith("Contract") or label.startswith("Course") or label.startswith("Reserve") or label.startswith("Store") or label.startswith("Game 2"):
            sales_cycles = min(2, sales_cycles + 1)
            earned = first_sales if sales_cycles == 1 else all_sales
        monthly = (cycle % 2 == 0)
        if monthly and expense_after_settlement:
            cash += earned - settled
            settled = earned
        if monthly and (bill_from_start or label != "Game 1"):
            payroll = 0 if stage == "Game 1" else employees * salary + completed_courses * raise_per_course
            charge((bill + payroll) * 100, label + " monthly expense")
        if monthly and not expense_after_settlement:
            cash += earned - settled
            settled = earned
        min_cash = min(min_cash, cash)
        cycle_lows[cycle] = min(cycle_lows.get(cycle, cash), cash)
        if cash < 0 and failure is None:
            failure = {"stage": label, "cycle": cycle, "shortfall_cents": -cash}

    # Conservative liquidity bound: all successful Game 1 Feature play spend precedes its cycles.
    charge(row["game1_play_spend"] * 100, "Game 1 Feature play")
    stage = "Game 1"
    for _ in range(row["game1_cycles"]): tick("Game 1")
    checkpoints["studio_cash_cents"] = cash
    stage = "Contract"
    tick("Contract hand 1")
    tick("Contract hand 2", math.floor(row["contract"]["payout_cents"] * payout_scale))
    checkpoints["after_contract_cash_cents"] = cash
    checkpoints["after_contract_earned_cents"] = earned
    checkpoints["after_contract_settled_cents"] = settled
    # No-fee, zero-cycle hiring is an analysis assumption, not a runtime rule.
    stage = "Courses"
    for _ in range(employees * courses_per_employee):
        completed_courses += 1
        tick("Course")
    stage = "Game 2"
    if row["reserve_id"] is None:
        failure = failure or {"stage": "No eligible Scope-2 reserve", "cycle": cycle, "shortfall_cents": 0}
    else:
        charge(45000, "Reserve Feature purchase")
        tick("Reserve Feature purchase")
    if optional_node:
        charge(170000, "Optional Store node")
        tick("Optional Store node")
    charge(row["game2_play_spend"] * 100, "Game 2 Feature play")
    for _ in range(row["game2_cycles"]): tick("Game 2")
    checkpoints["end_cash_cents"] = cash
    return {"min_cash_cents": min_cash, "first_failure": failure, "earned_net_cents": earned,
            "settled_net_cents": settled, "first_sales_cents": first_sales,
            "all_sales_cents": all_sales, "cash_low_by_cycle": cycle_lows, **checkpoints}


def main(seed=260927, per_cell=150):
    rng = random.Random(seed)
    assert 240000 * 96 // 96 == 240000 and 240000 * 48 // 96 == 120000
    assert base.review(dict(zip(CORES, (27, 30, 36, 36))), 30, 0,
                       {"ratios": [30, 20, 30, 20]}, rng, 50)[0] == 7.0
    rows = [sample_run(target, policy, alignment, rng)
            for target in (7, 13, 19, 20, 21, 22, 23)
            for policy in ("conservative", "ordinary", "optimized")
            for alignment in (0, 1)
            for _ in range(per_cell)]
    scenarios = {}
    for employees in (0, 1, 2):
        for courses in (0, 1, 2):
            for optional in (False, True):
                key = f"staff{employees}_courses{courses}_node{int(optional)}"
                paths = [cash_path(r, employees, courses, optional_node=optional) for r in rows]
                failures = [p["first_failure"] for p in paths]
                scenarios[key] = {"n": len(rows), "shortfall_pct": round(100 * sum(f is not None for f in failures) / len(rows), 1),
                                  "min_cash_cents": describe([p["min_cash_cents"] for p in paths]),
                                  "earliest_failure": min((f for f in failures if f is not None), key=lambda f: f["cycle"], default=None),
                                  "failure_stages": dict(Counter(f["stage"] for f in failures if f is not None))}
    baseline = [cash_path(r, 1, 2) for r in rows]
    cycle_values = defaultdict(list)
    for path in baseline:
        for cycle, low in path["cash_low_by_cycle"].items():
            cycle_values[cycle].append(low)
    baseline_by_cycle = {str(c): {"n": len(values), "minimum_cents": min(values),
                                  "p10_cents": percentile(values,.1), "median_cents": statistics.median(values)}
                         for c,values in sorted(cycle_values.items())}
    review_bins = {f"{lo:.1f}-{hi:.1f}": [i for i, r in enumerate(rows) if lo <= r["review"] <= hi]
                   for lo, hi in ((0, .7), (.8, 1.7), (1.8, 3), (3.1, 5), (5.1, 10))}
    by_review = {k: {"n": len(indices), "shortfall_pct": round(100 * sum(baseline[i]["first_failure"] is not None for i in indices) / len(indices), 1) if indices else None,
                     "min_cash_cents": describe([baseline[i]["min_cash_cents"] for i in indices]) if indices else None}
                 for k, indices in review_bins.items()}
    by_target = {}
    for target in (7,13,19,20,21,22,23):
        indices=[i for i,r in enumerate(rows) if r["target"]==target]
        by_target[str(target)]={"n":len(indices),"review":describe([rows[i]["review"] for i in indices]),
            "starting_cash_dollars":describe([rows[i]["initial_cash"] for i in indices]),
            "shortfall_pct":round(100*sum(baseline[i]["first_failure"] is not None for i in indices)/len(indices),1),
            "optional_node_shortfall_pct":round(100*sum(cash_path(rows[i],1,2,optional_node=True)["first_failure"] is not None for i in indices)/len(indices),1)}
    cash_order = sorted(range(len(rows)), key=lambda i: (rows[i]["initial_cash"], i))
    by_start_cash = {}
    for decile in range(10):
        indices = cash_order[math.floor(decile * len(rows) / 10):math.floor((decile+1) * len(rows) / 10)]
        lo = rows[indices[0]]["initial_cash"]
        hi = rows[indices[-1]]["initial_cash"]
        by_start_cash[str(decile+1)] = {"cash_range": [lo,hi], "n":len(indices), "shortfall_pct": round(100*sum(baseline[i]["first_failure"] is not None for i in indices)/len(indices),1)}
    sensitivity = {}
    for bill, salary in ((50,75),(75,100),(100,150)):
        for expense_after in (True,False):
            paths=[cash_path(r,1,2,bill=bill,salary=salary,expense_after_settlement=expense_after) for r in rows]
            sensitivity[f"bill{bill}_salary{salary}_expense_after_settlement{int(expense_after)}"] = round(100*sum(p["first_failure"] is not None for p in paths)/len(rows),1)
    for bill_from_start in (False,True):
        paths=[cash_path(r,1,2,bill_from_start=bill_from_start) for r in rows]
        sensitivity[f"bill_from_first_game_{int(bill_from_start)}"] = round(100*sum(p["first_failure"] is not None for p in paths)/len(rows),1)
    hypothetical_publishers = {}
    for name, scale in (("Ironclad",1.0),("SideStreet",.9),("Crown & Quill",.8),("Neon Circuit",.65),("Starwave",.8)):
        hypothetical_publishers[name] = {}
        for optional in (False,True):
            paths=[cash_path(r,1,2,optional_node=optional,payout_scale=scale) for r in rows]
            hypothetical_publishers[name][f"optional_node_{int(optional)}"] = {
                "shortfall_pct":round(100*sum(p["first_failure"] is not None for p in paths)/len(rows),1),
                "minimum_cash_cents":describe([p["min_cash_cents"] for p in paths])}
    # Marketing specialization delta on identical draws is small; compare current
    # Beta with the frozen earlier model on independent replays in a separate pass.
    by_policy={p:{"n":len(x),"review":describe([r["review"] for r in x]),"contract_pct":describe([r["contract"]["completion_pct"] for r in x]),
                   "shortfall_pct":round(100*sum(baseline[i]["first_failure"] is not None for i,r in enumerate(rows) if r["policy"]==p)/len(x),1)}
               for p in ("conservative","ordinary","optimized") for x in [[r for r in rows if r["policy"]==p]]}
    result={"seed":seed,"per_cell":per_cell,"n":len(rows),"approximations":"Python PRNG/policy model; Game 1 play cost charged up-front as liquidity bound; modeled no-fee zero-cycle hiring; monthly expenses after settlement by default; no new publisher offers; optional Store node modeled only as $1700/cycle cash stress.",
            "first_game_review":describe([r["review"] for r in rows]),"first_game_scope":describe([r["scope"] for r in rows]),
            "first_game_core_mean":{core:round(statistics.mean(r["scores"][core] for r in rows),2) for core in CORES},
            "first_game_bugs":describe([r["bugs"] for r in rows]),
            "first_game_genre_fit":describe([r["fit"] for r in rows]),
            "acquisition_dollars":describe([r["acquisition"] for r in rows]),"game1_play_dollars":describe([r["game1_play_spend"] for r in rows]),
            "studio_cash_cents":describe([cash_path(r,0,0)["studio_cash_cents"] for r in rows]),
            "month1_units":describe([r["units"] for r in rows]),"contract_completion_pct":describe([r["contract"]["completion_pct"] for r in rows]),
            "marketing_specialization":{"hands":sum(r["marketing_special_hands"] for r in rows),
                "runs_with_specialization":sum(r["marketing_special_hands"]>0 for r in rows),
                "total_extra_marketing":sum(r["marketing"]-r["old_marketing"] for r in rows),
                "total_extra_units":sum(r["units"]-r["old_units"] for r in rows),
                "changed_unit_projection_runs":sum(r["units"]!=r["old_units"] for r in rows)},
            "ironclad_payout_cents":describe([r["contract"]["payout_cents"] for r in rows]),
            "contract_full_settlement_pct":round(100*sum(cash_path(r,0,0)["after_contract_settled_cents"]==cash_path(r,0,0)["all_sales_cents"] for r in rows)/len(rows),1),
            "contract_half_only_settlement_pct":round(100*sum(0<cash_path(r,0,0)["after_contract_settled_cents"]<cash_path(r,0,0)["all_sales_cents"] for r in rows)/len(rows),1),
            "by_policy":by_policy,"by_target":by_target,"by_review":by_review,"by_start_cash_decile":by_start_cash,
            "scenarios":scenarios,"baseline_cash_by_calendar_cycle":baseline_by_cycle,
            "sensitivity":sensitivity,"hypothetical_publisher_caps":hypothetical_publishers,
            "publisher_offer_status":{"Ironclad":"playable one-shot cash-only offer", "SideStreet":"unlockable, no separate playable offer", "Crown & Quill":"Review>=7 unlock; no separate offer", "Neon Circuit":"Awareness>=125 unlock; no separate offer", "Starwave":"unreachable under one-shot ContractState"},
            "review_ge7_pct":round(100*sum(r["review"]>=7 for r in rows)/len(rows),1),
            "awareness_ge125_pct":round(100*sum(100+r["marketing"]>=125 for r in rows)/len(rows),1),
            "sample_trace":rows[0]}
    print(json.dumps(result,indent=2))


if __name__ == "__main__":
    main(int(sys.argv[1]) if len(sys.argv)>1 else 260927,
         int(sys.argv[2]) if len(sys.argv)>2 else 150)
