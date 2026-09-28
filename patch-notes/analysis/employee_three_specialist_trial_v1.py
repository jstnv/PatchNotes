"""Paired read-only Production, QA, and Contract employee trial.

Run: python -B patch-notes/analysis/employee_three_specialist_trial_v1.py
No employee, payroll, perk, or course rule is implemented by this script.
"""
from __future__ import annotations

import copy
import gzip
import itertools
import json
import math
import random
import statistics
from collections import Counter, defaultdict
from pathlib import Path

import fanbase_playtest_v1 as base
import ironclad_guarantee_cashflow_v1 as finance
import publisher_cash_payroll_v1 as publisher
import qa_analyst_counterfactual_v1 as qa_prior


OUT = Path(__file__).resolve().parents[1] / "design-logs"
SEED = 26092763
ARMS = ("none", "production", "qa", "contracts",
        "production+qa", "production+contracts", "qa+contracts", "combined")


def pct(values, part):
    values = sorted(values)
    return values[int((len(values) - 1) * part)]


def describe(values):
    values = list(values)
    return {"n": len(values), "p10": pct(values, .1),
            "median": statistics.median(values), "p90": pct(values, .9),
            "mean": round(statistics.mean(values), 3)}


def production_trace(owned, policy, rng, starting_cash):
    """Same draw/choice/bug order as fanbase_playtest_v1.production, with hands."""
    scores = {k: 0 for k in base.CORES}
    scope = bugs = played = 0
    cash = starting_cash
    events = []
    failed = []
    for phase, hands in (("design", 2 if policy != "optimized" else 3),
                         ("alpha", 2 if policy == "conservative" else 3 if policy == "ordinary" else 4)):
        exhausted = set()
        pressure = 0.0
        redraws = 4
        for _ in range(hands):
            pool = base.draw_production(phase, owned, exhausted, {k: 25 for k in base.CORES}, rng)
            attempts = 0 if policy == "conservative" else 1 if policy == "ordinary" else 2
            for _ in range(attempts):
                if redraws <= 0:
                    break
                index = min(range(7), key=lambda i: base.printed(pool[i]) + 2 * pool[i]["scope"])
                if base.redraw_production(pool, index, owned, exhausted,
                                          {k: 25 for k in base.CORES}, rng):
                    redraws -= 1
            hand = [pool[i] for i in base.choose_hand(pool, scores, scope, policy, rng)]
            cost = sum(10 * (base.printed(c) + 2 * c["scope"])
                       for c in hand if c["type"] == "feature")
            if cost > cash:
                failed.append({"phase": phase, "cost_dollars": cost,
                               "cash_dollars": cash, "cards": [c["id"] for c in hand]})
                break
            cash -= cost
            additions, gained_scope, bug_pressure, _, _ = base.hand_output(hand, scores)
            for k in base.CORES:
                scores[k] += additions[k]
            scope += gained_scope
            pressure += bug_pressure
            played += 1
            events.append({"phase": phase, "cycle": played,
                           "cards": [c["id"] for c in hand], "cost_dollars": cost,
                           "scope": gained_scope, "additions": additions})
            exhausted.update(c["id"] for c in hand if c["type"] == "feature")
            redraws = min(4, redraws + 1)
        mean = sum(scores.values()) / 4
        perfect = phase == "design" and all(mean * .95 <= x <= mean * 1.05 for x in scores.values())
        bugs += base.bug_final(pressure, rng, perfect)
    return {"scores": scores, "scope": scope, "bugs": bugs, "spent_dollars": starting_cash - cash,
            "played": played, "events": events, "failed": failed}


def matching_feature_costs(cards):
    passes = [base.BY_ID[i] for i in cards if base.BY_ID[i]["type"] == "pass"]
    eligible = []
    for ident in cards:
        card = base.BY_ID[ident]
        if card["type"] != "feature":
            continue
        if any(p["primary_stat"] in (card["primary_stat"], card.get("secondary_stat"))
               for p in passes):
            eligible.append(10 * (base.printed(card) + 2 * card["scope"]))
    return eligible


def production_perk(trace, trained=False, permanent_cap=60, temporary_rate=20,
                    temporary_cap=80):
    trigger = None
    permanent = temporary = 0
    gross_only = 0
    for event in trace["events"]:
        costs = matching_feature_costs(event["cards"]) if event["phase"] == "design" else []
        if trigger is None and costs:
            trigger = event["cycle"]
            trained = True
            permanent = min(permanent_cap, max(costs) * 50 // 100)
        elif trigger is not None and event["cycle"] - trigger <= 6:
            temporary += min(temporary_cap - temporary,
                             event["cost_dollars"] * temporary_rate // 100)
    # Fixed-action pair: a failed baseline hand is not secretly committed. Flag
    # gross-vs-net opportunities for a separate adaptive policy rerun.
    for failed in trace["failed"]:
        costs = matching_feature_costs(failed["cards"]) if failed["phase"] == "design" else []
        potential = min(permanent_cap, max(costs) * 50 // 100) if costs else 0
        gross_only += int(failed["cost_dollars"] > failed["cash_dollars"] >= failed["cost_dollars"] - potential)
    return {"trained": trained, "trigger_cycle": trigger,
            "permanent_dollars": permanent, "temporary_dollars": temporary,
            "savings_dollars": permanent + temporary,
            "gross_only_opportunities": gross_only}


def beta_actions(initial_bugs, budget, policy, seed):
    if budget == 0:
        return []
    priority = {"qa": 50, "marketing": 35, "insider": 15} if policy == "qa_first" else (
        {"qa": 20, "marketing": 50, "insider": 30} if policy == "marketing_first" else
        {"qa": 35, "marketing": 35, "insider": 30})
    return [a[1] for a in qa_prior.schedule(initial_bugs, priority, budget,
                                             policy, random.Random(seed))]


def qa_replay(initial_bugs, actions, perk=False, old_two_search=False):
    hidden, known, marketing = initial_bugs, 0, 0
    first_search = None
    second_search = None
    award_hand = None
    extra_fixes = extra_found = useful_search_hands = 0
    marketing_special_hands = 0
    for hand_index, ids in enumerate(actions):
        cards = [base.BY_ID[i] for i in ids]
        cats = Counter(c["beta_category"] for c in cards)
        qa_special = cats["qa"] == 4
        marketing_special = cats["marketing"] == 4
        balanced = all(1 <= cats[x] <= 2 for x in ("qa", "marketing", "insider"))
        marketing_special_hands += int(marketing_special)
        ordinary_discovered = 0
        for card in cards:
            if card["id"] != "search_for_bugs":
                continue
            value = card["beta_value"] * (1.5 if qa_special else 1)
            request = math.floor(1 + value + hidden * .15 * value)
            if balanced:
                request = math.ceil(request * 1.25)
            moved = min(request, hidden)
            hidden -= moved
            known += moved
            ordinary_discovered += moved
        if ordinary_discovered:
            if first_search is None:
                first_search = hand_index
            elif second_search is None:
                second_search = hand_index
        if (perk and award_hand is not None and hand_index > award_hand and
                hand_index - award_hand <= 6 and "search_for_bugs" in ids and
                hidden > 0 and useful_search_hands < 2):
            hidden -= 1
            known += 1
            extra_found += 1
            useful_search_hands += 1
        ordinary_fixed = 0
        for card in cards:
            if card["id"] != "debug":
                continue
            value = card["beta_value"] * (1.5 if qa_special else 1)
            request = math.floor(1 + value)
            if balanced:
                request = math.ceil(request * 1.25)
            moved = min(request, known)
            known -= moved
            ordinary_fixed += moved
        prior_search = second_search if old_two_search else first_search
        if award_hand is None and prior_search is not None and hand_index > prior_search and ordinary_fixed:
            award_hand = hand_index
            if perk and known:
                known -= 1
                extra_fixes += 1
        raw = sum(c["beta_value"] for c in cards if c["beta_category"] == "marketing")
        marketing += (math.floor(raw * 1.5) if marketing_special else
                      math.ceil(raw * 1.25) if balanced else raw)
    return {"remaining_bugs": hidden + known, "hidden": hidden, "known": known,
            "marketing": marketing, "award_hand": award_hand,
            "extra_fixes": extra_fixes, "extra_found": extra_found,
            "useful_search_hands": useful_search_hands,
            "marketing_special_hands": marketing_special_hands,
            "first_search_hand": first_search}


def contract_trace(owned, policy, seed, extra_restore=0, deliberate=False):
    rng = random.Random(seed)
    scope = 0
    half = {core: 0 for core in base.CORES}
    exhausted = set()
    redraws = 4
    used = []
    mixed_first = False
    extra_restored = 0
    for hand_number in range(2):
        pool = publisher.draw_contract(owned, exhausted, rng)
        requested = (4 if deliberate else 0 if policy == "conservative" else 1 if policy == "ordinary" else 2)
        spent = 0
        for _ in range(min(redraws, requested)):
            index = min(range(7), key=lambda i: (pool[i]["scope"] * 4 + base.printed(pool[i]), i))
            if publisher.redraw_contract_one(pool, index, owned, exhausted, rng):
                redraws -= 1
                spent += 1
        if policy == "conservative" and not deliberate:
            hand = rng.sample(pool, 4)
        else:
            choices = []
            for indices in itertools.combinations(range(7), 4):
                cards = [pool[i] for i in indices]
                factor = 3 if len({c["primary_stat"] for c in cards}) == 1 else 2
                additions = {k: sum((c["primary_value"] if c["primary_stat"] == k else 0) +
                                    (c["secondary_value"] if c.get("secondary_stat") == k else 0)
                                    for c in cards) * factor for k in base.CORES}
                gained = sum(c["scope"] for c in cards)
                numerator = 4 * min(12, scope + gained) + sum(min(12, half[k] + additions[k]) for k in base.CORES)
                choices.append((numerator + rng.random() * .000001, indices))
            hand = [pool[i] for i in max(choices)[1]]
        if hand_number == 0:
            mixed_first = any(c["type"] == "feature" for c in hand) and any(c["type"] == "pass" for c in hand)
        factor = 3 if len({c["primary_stat"] for c in hand}) == 1 else 2
        scope += sum(c["scope"] for c in hand)
        for c in hand:
            half[c["primary_stat"]] += c["primary_value"] * factor
            if c.get("secondary_stat"):
                half[c["secondary_stat"]] += c["secondary_value"] * factor
            if c["type"] == "feature":
                exhausted.add(c["id"])
        normal = min(4, redraws + 1)
        redraws = normal
        if hand_number == 0 and spent >= 2 and mixed_first:
            redraws = min(4, redraws + extra_restore)
            extra_restored = redraws - normal
        used.append(spent)
    numerator = 4 * min(scope, 12) + sum(min(half[k], 12) for k in base.CORES)
    return {"numerator": numerator, "total_payout_cents": 40000 + 200000 * numerator // 96,
            "first_mixed": mixed_first, "used_redraws": used,
            "challenge": used[0] >= 2 and mixed_first,
            "extra_restored": extra_restored, "scope": scope,
            "core_half": half}


def sample(index, cohort, policy):
    rng = random.Random(SEED + index * 7919)
    target = rng.choice((20, 21, 22, 23) if cohort == "legal" else (7, 13, 19))
    owned, acquisition = (base.roster(target, rng) if cohort != "expanded" else
                          ({c["id"] for c in base.FEATURES}, 0))
    initial_cash = 5500 - acquisition if cohort != "expanded" else 100000
    game1 = production_trace(owned, policy, rng, initial_cash)
    genre = base.choose_genre(owned, policy, rng)
    variance = rng.randrange(100)
    market = base.market(rng)
    beta_budget = 0 if policy == "conservative" else 2 if policy == "ordinary" else 4
    beta_policy = "fixed" if policy == "ordinary" else "qa_first"
    actions1 = beta_actions(game1["bugs"], beta_budget, beta_policy, SEED + index * 13 + 1)
    reserve = next((c for c in base.FEATURES if c["id"] not in owned and c["scope"] == 2), None)
    owned2 = owned | ({reserve["id"]} if reserve else set())
    game2 = production_trace(owned2, policy, random.Random(SEED + index * 7919 + 399), 100000)
    actions2 = beta_actions(game2["bugs"], beta_budget, beta_policy, SEED + index * 13 + 2)
    return {"index": index, "cohort": cohort, "policy": policy, "target": target,
            "owned": sorted(owned), "acquisition": acquisition,
            "initial_cash": initial_cash, "game1": game1, "game2": game2,
            "actions1": actions1, "actions2": actions2, "genre": genre,
            "variance": variance, "market_bp": market,
            "contract_seed": SEED + index * 31 + 91,
            "reserve_id": reserve["id"] if reserve else None,
            "alignment": index % 2}


def arm_result(item, arm, contract_policy="ordinary", deliberate=False,
               prod_cap=60, temp_rate=20, temp_cap=80,
               qa_old_two_search=False, contract_restore=2):
    use_production = "production" in arm or arm == "combined"
    use_qa = "qa" in arm or arm == "combined"
    use_contract = "contracts" in arm or arm == "combined"
    prod1 = production_perk(item["game1"], False, prod_cap, temp_rate, temp_cap)
    prod2 = production_perk(item["game2"], prod1["trained"], prod_cap, temp_rate, temp_cap)
    beta1 = qa_replay(item["game1"]["bugs"], item["actions1"], use_qa, qa_old_two_search)
    beta2 = qa_replay(item["game2"]["bugs"], item["actions2"], use_qa, qa_old_two_search)
    review1 = base.review(item["game1"]["scores"], item["game1"]["scope"],
                          beta1["remaining_bugs"], item["genre"], random.Random(0), item["variance"])[0]
    review2 = base.review(item["game2"]["scores"], item["game2"]["scope"],
                          beta2["remaining_bugs"], item["genre"], random.Random(0), item["variance"])[0]
    units = base.units(review1, beta1["marketing"], 0, item["market_bp"])
    contract = contract_trace(set(item["owned"]), contract_policy,
                              item["contract_seed"], contract_restore if use_contract else 0,
                              deliberate)
    row = {"initial_cash": item["initial_cash"], "alignment": item["alignment"],
           "game1_play_spend": item["game1"]["spent_dollars"] - (prod1["savings_dollars"] if use_production else 0),
           "game2_play_spend": item["game2"]["spent_dollars"] - (prod2["savings_dollars"] if use_production else 0),
           "game1_cycles": 1 + item["game1"]["played"] + len(item["actions1"]),
           "game2_cycles": 1 + item["game2"]["played"] + len(item["actions2"]),
           "reserve_id": item["reserve_id"], "units": units,
           "contract": {"numerator": contract["numerator"]}}
    return {"review1": review1, "review2": review2, "units": units,
            "scope1": item["game1"]["scope"], "cores1": item["game1"]["scores"],
            "bugs1": beta1["remaining_bugs"], "marketing": beta1["marketing"],
            "production1": prod1, "production2": prod2, "qa1": beta1, "qa2": beta2,
            "contract": contract, "row": row}


def main():
    # Fixed-action invariants for the revised one-Search/later-Debug trigger.
    eligible = qa_replay(8, [["search_for_bugs"], ["debug"]], True)
    assert eligible["award_hand"] == 1 and eligible["extra_fixes"] <= 1
    assert qa_replay(0, [["search_for_bugs"], ["debug"]], True)["award_hand"] is None
    assert qa_replay(8, [["search_for_bugs"], ["debug"]], True, True)["award_hand"] is None
    samples = [sample(i, ("legal" if i % 3 == 0 else "below_20" if i % 3 == 1 else "expanded"),
                      ("conservative", "ordinary", "optimized")[(i // 3) % 3])
               for i in range(600)]
    records = []
    for item in samples:
        standard = {arm: arm_result(item, arm, "ordinary") for arm in ARMS}
        deliberate = {restore: arm_result(item, "contracts", "optimized", True,
                                          contract_restore=restore)
                      for restore in (0, 1, 2)}
        finance_paths = {}
        if item["cohort"] != "expanded":
            for arm in ARMS:
                result = standard[arm]
                staff = 0 if arm == "none" else 3 if arm == "combined" else 2 if "+" in arm else 1
                for courses in (0, 1, 2):
                    for optional in (False, True):
                        key = f"{arm}|courses{courses}|node{int(optional)}"
                        finance_paths[key] = finance.run_path(result["row"], 40000,
                                                               staff, courses, optional,
                                                               studio_hire_cycle=False)
                if arm in ("none", "combined"):
                    finance_paths[f"{arm}|prehire|node1"] = finance.run_path(
                        result["row"], 40000, staff, 0, True, hire_before_game1=True)
        records.append({"item": item, "standard": standard, "deliberate_contract": deliberate,
                        "finance": finance_paths})
    summary = {}
    for cohort in ("legal", "below_20", "expanded"):
        group = [r for r in records if r["item"]["cohort"] == cohort]
        for arm in ARMS:
            effects = [r["standard"][arm] for r in group]
            baseline = [r["standard"]["none"] for r in group]
            key = f"{cohort}|{arm}"
            summary[key] = {"n": len(group),
                            "review1": describe(x["review1"] for x in effects),
                            "review2": describe(x["review2"] for x in effects),
                            "review_delta": describe(x["review1"] - b["review1"] for x, b in zip(effects, baseline)),
                            "units_delta": describe(x["units"] - b["units"] for x, b in zip(effects, baseline)),
                            "cross5_up_pct": round(100 * sum(x["review1"] >= 5 > b["review1"] for x, b in zip(effects, baseline)) / len(group), 2),
                            "cross7_up_pct": round(100 * sum(x["review1"] >= 7 > b["review1"] for x, b in zip(effects, baseline)) / len(group), 2),
                            "production_challenge_opportunity_pct": round(100 * sum(x["production1"]["trigger_cycle"] is not None for x in effects) / len(group), 2),
                            "production_awarded_pct": round(100 * sum(x["production1"]["trigger_cycle"] is not None for x in effects) / len(group), 2) if ("production" in arm or arm == "combined") else 0,
                            "production_permanent_game1_dollars": describe(x["production1"]["permanent_dollars"] if ("production" in arm or arm == "combined") else 0 for x in effects),
                            "production_temporary_game1_dollars": describe(x["production1"]["temporary_dollars"] if ("production" in arm or arm == "combined") else 0 for x in effects),
                            "production_savings_game1_dollars": describe(x["production1"]["savings_dollars"] if ("production" in arm or arm == "combined") else 0 for x in effects),
                            "production_savings_game2_dollars": describe(x["production2"]["savings_dollars"] if ("production" in arm or arm == "combined") else 0 for x in effects),
                            "production_gross_net_affordability_opportunities": sum(x["production1"]["gross_only_opportunities"] for x in effects),
                            "qa_challenge_opportunity_pct": round(100 * sum(x["qa1"]["award_hand"] is not None for x in effects) / len(group), 2),
                            "qa_awarded_pct": round(100 * sum(x["qa1"]["award_hand"] is not None for x in effects) / len(group), 2) if ("qa" in arm or arm == "combined") else 0,
                            "qa_extra_fixes": describe(x["qa1"]["extra_fixes"] for x in effects),
                            "qa_extra_found": describe(x["qa1"]["extra_found"] for x in effects),
                            "contract_challenge_opportunity_pct": round(100 * sum(x["contract"]["challenge"] for x in effects) / len(group), 2),
                            "contract_extra_restored": describe(x["contract"]["extra_restored"] for x in effects),
                            "contract_payout_delta_cents": describe(x["contract"]["total_payout_cents"] - b["contract"]["total_payout_cents"] for x, b in zip(effects, baseline))}
            if cohort != "expanded":
                for courses, optional in ((0, False), (1, False), (2, False), (2, True)):
                    label = f"{arm}|courses{courses}|node{int(optional)}"
                    paths = [r["finance"][label] for r in group]
                    summary[key][f"finance_courses{courses}_node{int(optional)}"] = {
                        "shortfall_pct": round(100 * sum(p["first_shortfall"] is not None for p in paths) / len(paths), 2),
                        "first_shortfall_stage": dict(Counter(p["first_shortfall"]["stage"] for p in paths if p["first_shortfall"])),
                        "studio_cash_cents": describe(p["checkpoints"]["studio_entry_cents"] for p in paths),
                        "game2_release_cash_cents": describe(p["checkpoints"]["end_cents"] for p in paths)}
    sensitivity = {}
    for cap in (40, 60, 80):
        for rate in (10, 20, 30):
            vals = [production_perk(r["item"]["game1"], False, cap, rate, 80) for r in records]
            sensitivity[f"production_cap{cap}_rate{rate}"] = {
                "challenge_pct": round(100 * sum(x["trigger_cycle"] is not None for x in vals) / len(vals), 2),
                "savings_dollars": describe(x["savings_dollars"] for x in vals)}
    for cohort in ("legal", "below_20", "expanded"):
        group = [r for r in records if r["item"]["cohort"] == cohort]
        for restore in (0, 1, 2):
            outcomes = [r["deliberate_contract"][restore]["contract"] for r in group]
            controls = [r["deliberate_contract"][0]["contract"] for r in group]
            sensitivity[f"{cohort}|deliberate_restore{restore}"] = {
                "n": len(outcomes), "challenge_pct": round(100 * sum(x["challenge"] for x in outcomes) / len(outcomes), 2),
                "actual_extra_redraws": describe(x["extra_restored"] for x in outcomes),
                "payout_cents": describe(x["total_payout_cents"] for x in outcomes),
                "paired_payout_delta_cents": describe(x["total_payout_cents"] - c["total_payout_cents"] for x, c in zip(outcomes, controls))}
    for cohort in ("legal", "below_20", "expanded"):
        group = [r for r in records if r["item"]["cohort"] == cohort]
        old_count = 0
        marketing_count = marketing_extra_fixes = 0
        marketing_reviews = []
        for r in group:
            item = r["item"]
            old_count += int(qa_replay(item["game1"]["bugs"], item["actions1"], True, True)["award_hand"] is not None)
            actions = beta_actions(item["game1"]["bugs"], len(item["actions1"]),
                                   "marketing_first", SEED + item["index"] * 13 + 1)
            result = qa_replay(item["game1"]["bugs"], actions, True)
            marketing_count += int(result["award_hand"] is not None)
            marketing_extra_fixes += result["extra_fixes"]
            marketing_reviews.append(base.review(item["game1"]["scores"], item["game1"]["scope"],
                                                  result["remaining_bugs"], item["genre"],
                                                  random.Random(0), item["variance"])[0])
        sensitivity[f"{cohort}|qa_policy_negative_controls"] = {
            "new_one_search_challenge_pct": summary[f"{cohort}|qa"]["qa_challenge_opportunity_pct"],
            "old_two_search_challenge_pct": round(100 * old_count / len(group), 2),
            "marketing_first_challenge_pct": round(100 * marketing_count / len(group), 2),
            "marketing_first_extra_fixes_total": marketing_extra_fixes,
            "marketing_first_review": describe(marketing_reviews)}
    output = {"seed": SEED, "source_revision": "ba616515ed1b039fd0da7cf03f73288fd7ccd8e4",
              "n": len(records), "notes": "Fixed-action Python port, not Godot PRNG/human play. Production and QA use recorded legal hands; perk affordability does not create a new hand in the fixed pair. Candidate salary $100 and bill $75 per month; $25 course raise, zero tuition, one cycle. Hiring is zero cash/zero cycle at Studio or before first Pre-Development, with payroll only while hired. First-game payroll only in explicit prehire sensitivity. Ironclad $400 upfront plus completion-dependent remainder, one offer. Game 2 cash horizon ends at release, before its sales. Expanded all-owned cohort has no unowned Scope-2 reserve and is excluded from cash scenarios.",
              "summary": summary, "sensitivity": sensitivity,
              "fixed_action_checks": {"one_search_later_debug": eligible["award_hand"] == 1,
                                      "zero_hidden_no_challenge": True,
                                      "old_two_search_negative_control": True}}
    (OUT / "employee_three_specialist_trial_v1_summary.json").write_text(json.dumps(output, indent=2) + "\n", encoding="utf-8")
    with gzip.open(OUT / "employee_three_specialist_trial_v1_raw.json.gz", "wt", encoding="utf-8") as handle:
        json.dump(records, handle, separators=(",", ":"))
    for key in ("legal|none", "legal|production", "legal|qa", "legal|contracts", "legal|combined"):
        x = summary[key]
        print(key, "review_delta", x["review_delta"]["mean"], "prod opportunity", x["production_challenge_opportunity_pct"],
              "qa opportunity", x["qa_challenge_opportunity_pct"], "contract opportunity", x["contract_challenge_opportunity_pct"],
              "shortfall node", x["finance_courses2_node1"]["shortfall_pct"])


if __name__ == "__main__":
    main()
