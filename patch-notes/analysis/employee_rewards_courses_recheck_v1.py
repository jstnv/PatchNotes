"""Read-only employee/course trial on current Godot action traces.

Run: python -B analysis/employee_rewards_courses_recheck_v1.py
Rewards, hires, courses, payroll and bills here are shadow candidates only.
"""
from __future__ import annotations

import gzip
import itertools
import json
import math
import statistics
from collections import Counter, defaultdict
from pathlib import Path

import studio_trait_post_integration_recheck_v1 as sales

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "design-logs"
REVISION = "606f011d0bfdaca27dc662062ec6498a5942627a"
LEDGER = {x["id"]: x for x in json.loads((ROOT / "data/card_ledger.json").read_text(encoding="utf-8"))
          + json.loads((ROOT / "data/feature_store_ledger.json").read_text(encoding="utf-8"))}
PRIMITIVE = {x["id"] for x in json.loads((ROOT / "data/card_ledger.json").read_text(encoding="utf-8")) if x["type"] == "feature"}


def rows():
    for policy in ("cautious", "ordinary", "optimizer"):
        for file in (f"sidestreet_acceptance_stress_v1_{policy}_task7_current.json",
                     f"employee_mixed_beta_capture_v1_{policy}_task8_current.json"):
            obj = json.loads((OUT / file).read_text(encoding="utf-8"))
            assert obj["failures"] == 0
            for row in obj["rows"]:
                assert row["valid"] and row["game_2"]["released"]
                yield row


def feature_cost(id_):
    x = LEDGER[id_]
    if x["type"] != "feature" or id_ not in PRIMITIVE:
        return 0
    return 1000 * (x["primary_value"] + x["secondary_value"] + 2 * x["scope"])


def matching_feature(hand):
    selected = hand["selected"]
    passes = [LEDGER[i]["primary_stat"] for i in selected if LEDGER[i]["type"] == "pass"]
    matches = [i for i in selected if LEDGER[i]["type"] == "feature" and any(
        p in (LEDGER[i]["primary_stat"], LEDGER[i]["secondary_stat"]) for p in passes)]
    return max(matches, key=feature_cost) if matches else None


def production(row, game):
    design = [a for a in row["actions"] if a["phase"] == "design" and a.get("game") == game]
    alpha = [a for a in row["actions"] if a["phase"] == "alpha" and a.get("game") == game]
    priority = [a for a in row["actions"] if a["phase"] in ("design_priority", "alpha_priority") and a.get("game") == game]
    trigger = next(((idx, h, matching_feature(h)) for idx, h in enumerate(design) if matching_feature(h)), None)
    free_priority = next((a for a in priority if trigger and a["before"]["cycle"] >= trigger[1]["after"]["cycle"]), None)
    discount = {"cap60": 0, "cap90": 0, "cap120": 0}
    if trigger:
        _, h, card = trigger
        cost = feature_cost(card)
        discount["cap60"] = min(6000, cost // 2)
        discount["cap90"] = min(9000, cost)
        discount["cap120"] = min(12000, cost)
        later = [a for a in design + alpha if 0 < a["after"]["cycle"] - h["after"]["cycle"] <= 6]
        extra = min(8000, sum(int(a.get("cost_cents", 0)) * 20 // 100 for a in later))
        for key in discount:
            discount[key] += extra
    return {"triggered": trigger is not None, "trigger_hand": None if trigger is None else trigger[0] + 1,
            "matching_card": None if trigger is None else trigger[2],
            "training_game_free_priority": free_priority is not None,
            "free_priority_phase": None if free_priority is None else free_priority["phase"],
            "discount_savings_cents": discount,
            "design_redraw_uses": sum(t["success"] for h in design for t in h["redraws"]),
            "alpha_redraw_uses": sum(t["success"] for h in alpha for t in h["redraws"]),
            "design_hand_count": len(design)}


def free_priority_redraw_effect(row, game, phase):
    if not phase:
        return {"free_commit": False, "foregone_normal_refill": 0, "later_redraw_shortfalls": 0}
    actions = row["actions"]
    index = next(i for i, a in enumerate(actions) if a["phase"] == phase and a.get("game") == game)
    priority = actions[index]
    bank = priority["before"]["redraws"]
    lost_refill = priority["after"]["redraws"] - bank
    shortfalls = 0
    for a in actions[index + 1:]:
        if a.get("game") != game:
            if a.get("game") is not None:
                break
            continue
        if a["phase"] not in ("design", "alpha", "beta", "design_priority", "alpha_priority", "beta_priority"):
            continue
        used = sum(x["success"] for x in a.get("redraws", []))
        shortfalls += max(0, used - bank)
        bank = min(4, max(0, bank - used) + 1)
    return {"free_commit": True, "foregone_normal_refill": lost_refill,
            "later_redraw_shortfalls": shortfalls}


def planning(row, game):
    design = [a for a in row["actions"] if a["phase"] == "design" and a.get("game") == game]
    alpha = [a for a in row["actions"] if a["phase"] == "alpha" and a.get("game") == game]
    redraws = sum(t["success"] for h in design for t in h["redraws"])
    finite = sum(LEDGER[i]["type"] == "feature" for h in design for i in h["selected"])
    eligible = len(design) >= 2 and finite >= 2 and redraws == 0
    alpha_redraws = sum(t["success"] for h in alpha for t in h["redraws"])
    # Voucher is first future-project Alpha redraw only; cap/burst are capacity,
    # not played replacements under a fixed recorded action policy.
    return {"eligible_baseline": eligible, "finite_design_plays": finite,
            "design_redraws_to_forgo_if_training": redraws,
            "future_voucher_uses_at_recorded_policy": min(1, alpha_redraws),
            "alpha_redraws_recorded": alpha_redraws,
            "burst_extra_capacity_upper_bound": min(2, alpha_redraws + 2) if eligible else 0}


def planning_bank_bound(row, game, voucher: bool, burst: bool):
    # Count legal shared-bank capacity on the fixed recorded hand schedule.
    # Extra replacement cards and resulting Review are unknown, so this is
    # an opportunity upper bound rather than a played perk outcome.
    sequence = [a for a in row["actions"] if a.get("game") == game and
                a["phase"] in ("alpha", "alpha_priority", "beta", "beta_priority")]
    alpha = next(a for a in sequence if a["phase"] == "alpha")
    bank = 6 if burst else alpha["before"]["redraws"]
    cap = 6 if burst else 4
    extra = 0
    free_used = 0
    for a in sequence:
        if a["phase"] in ("alpha", "beta"):
            requested = (0 if row["policy"] == "cautious" else 2 if row["policy"] == "optimizer" and a["phase"] == "alpha" else 1)
            recorded = sum(x["success"] for x in a["redraws"])
            served = 0
            for _ in range(requested):
                if voucher and a["phase"] == "alpha" and not free_used:
                    free_used = 1
                    served += 1
                elif bank:
                    bank -= 1
                    served += 1
            extra += max(0, served - recorded)
        bank = min(cap, bank + (2 if burst else 1))
    return {"extra_redraw_opportunity_upper_bound": extra,
            "voucher_redeemed": free_used, "bank_end_before_studio": min(4, bank)}


def qa(row, game):
    hands = [a for a in row["actions"] if a["phase"] == "beta" and a.get("game") == game]
    search_at = debug_at = None
    mixed_options = []
    four_marketing = 0
    for index, h in enumerate(hands):
        ids = h["selected"]
        cats = [LEDGER[i]["beta_category"] for i in ids]
        if all(c == "marketing" for c in cats):
            four_marketing += 1
        productive_search = "search_for_bugs" in ids and h["after"]["hidden_bugs"] < h["before"]["hidden_bugs"]
        productive_debug = "debug" in ids and h["after"]["fixed_bugs"] > h["before"]["fixed_bugs"]
        if productive_search and search_at is None:
            search_at = index
        if productive_debug and search_at is not None and debug_at is None:
            debug_at = index
        if "marketing" in cats and (productive_search or productive_debug):
            selected_marketing = [LEDGER[i]["beta_value"] for i in ids if LEDGER[i]["beta_category"] == "marketing"]
            if selected_marketing:
                mixed_options.append({"index": index, "best_printed_value": max(selected_marketing),
                                      "total_printed_marketing": sum(selected_marketing),
                                      "balanced_operations": h["synergy"] == "balanced operations",
                                      "after_training": debug_at is not None and index > debug_at})
    first = next((v for v in mixed_options if v["after_training"]), None)
    def output_delta(rate):
        if not first:
            return 0
        printed_bonus = first["best_printed_value"] * rate // 100
        raw = first["total_printed_marketing"]
        if first["balanced_operations"]:
            return math.ceil((raw + printed_bonus) * 1.25) - math.ceil(raw * 1.25)
        return printed_bonus
    bonus25, bonus50 = output_delta(25), output_delta(50)
    return {"search_hand": search_at, "debug_hand_after_search": debug_at,
            "trained": debug_at is not None, "mixed_productive_hands": len(mixed_options),
            "reward_hand_after_training": None if first is None else first["index"] + 1,
            "marketing_output_bonus_25": bonus25, "marketing_output_bonus_50": bonus50,
            "four_marketing_specializations": four_marketing,
            "old_known_fix_possible_after_training": any(
                "debug" in h["selected"] and h["before"]["known_bugs"] > 0
                for h in hands[debug_at + 1:]) if debug_at is not None else False}


def contracts(row):
    offers = {}
    for label in ("ironclad", "sidestreet_1", "sidestreet_2"):
        hands = row[label]["hands"]
        mixed = [any(LEDGER[i]["type"] == "feature" for i in h["selected"]) and
                 any(LEDGER[i]["type"] == "pass" for i in h["selected"]) for h in hands]
        after_first_redraw = sum(x["success"] for x in hands[1]["redraws"])
        offers[label] = {"mixed_first": mixed[0], "mixed_second_only": mixed[1] and not mixed[0],
            "trained_any": any(mixed), "second_hand_redraws": after_first_redraw,
            "free_use_one": min(1, after_first_redraw) if mixed[0] else 0,
            "free_use_two": min(2, after_first_redraw) if mixed[0] else 0,
            "old_refill_one": min(1, max(0, 4 - hands[0]["after"]["redraws"])) if mixed[0] else 0,
            "old_refill_two": min(2, max(0, 4 - hands[0]["after"]["redraws"])) if mixed[0] else 0,
            "payout_cents": row[label]["completion"]["payout_cents"]}
    return offers


def cash_envelope(row, *, staff_count: int, salary: int, bill: int, hire_cost: int,
                  hire_cycle: int, boundary_timing: str, course_cost: int = 0,
                  course_raise: int = 0, course: bool = False, month1_only: bool = False):
    assert boundary_timing in ("crossed", "following")
    hire_cents = staff_count * hire_cost * 100
    first = None
    min_cash = 10**18
    if "_expense_replay" not in row:
        releases = [dict(row[k], market_bp=sales.old.market(row[k])) for k in ("game_1", "game_2")]
        snapshots = sales.old.snapshots(row)
        assert not any("campaign" in a["phase"] for a in row["actions"])
        for _, snap in snapshots:
            settled = sum(item["settled_cents"] for item in snap["sales"])
            predicted = sum(sales.net(sales.age_units(rel, rel["market_bp"], snap["cycle"] - snap["cycle"] % 2)) for rel in releases)
            assert settled == predicted
        row["_expense_replay"] = (releases, snapshots)
    releases, snapshots = row["_expense_replay"]
    hire_offset = hire_cycle * staff_count
    for stage, snap in snapshots:
        course_taken = course and staff_count > 0 and snap["cycle"] > row["game_1"]["cycle"]
        course_offset = int(course_taken)
        cycle = snap["cycle"] + hire_offset + course_offset
        month = cycle // 2
        bill_months = month
        payroll_months = max(0, month - (1 if boundary_timing == "following" else 0))
        # Fixed-action timing overlay: the extra hire/course productive cycles
        # shift release ages and boundary settlement, but cards stay frozen.
        course_cycle = row["game_1"]["cycle"] + hire_offset + 1
        course_boundary_month = (course_cycle + 1) // 2
        raise_months = max(0, month - course_boundary_month + (1 if boundary_timing == "crossed" else 0)) if course_taken else 0
        baseline_settled = sum(item["settled_cents"] for item in snap["sales"])
        shadow_settled = 0
        boundary = cycle - cycle % 2
        for i, original in enumerate(releases):
            shifted = dict(original, cycle=original["cycle"] + hire_offset + (course_offset if i == 1 else 0))
            age_boundary = min(boundary, shifted["cycle"] + 2) if month1_only else boundary
            shadow_settled += sales.net(sales.age_units(shifted, shifted["market_bp"], age_boundary))
        cash = (snap["cash_cents"] + shadow_settled - baseline_settled - hire_cents
                - (course_cost if course_taken else 0) - bill_months * bill * 100
                - payroll_months * staff_count * salary * 100 - raise_months * course_raise * 100)
        min_cash = min(min_cash, cash)
        if cash < 0 and first is None:
            first = {"stage": stage, "cycle": cycle, "shortfall_cents": -cash}
    return {"first_unaffordable": first, "minimum_cash_cents": min_cash,
            "added_hire_cycles": hire_cycle * staff_count,
            "added_course_cycles": 1 if staff_count and course else 0}


def percentile(values):
    if not values:
        return {"n": 0}
    ordered = sorted(values)
    return {"n": len(ordered), "min": ordered[0], "p10": ordered[int((len(ordered)-1)*.1)],
            "median": statistics.median(ordered), "p90": ordered[int((len(ordered)-1)*.9)], "max": ordered[-1]}


def main():
    live_rows = list(rows())
    planning_pairs = []
    for policy in ("ordinary", "optimizer"):
        baseline = json.loads((OUT / f"sidestreet_acceptance_stress_v1_{policy}_task7_current.json").read_text(encoding="utf-8"))["rows"][:15]
        alternative = json.loads((OUT / f"employee_planning_capture_v1_{policy}_task8_current.json").read_text(encoding="utf-8"))["rows"]
        assert len(baseline) == len(alternative) == 15
        for original, changed in zip(baseline, alternative):
            assert original["seed"] == changed["seed"] and original["case"] == changed["case"] and changed["valid"]
            first_planning = planning(changed, 1)
            planning_pairs.append({"policy": policy, "case": original["case"], "seed": original["seed"],
                "first_game_path_trigger": first_planning["eligible_baseline"],
                "design_redraws_forgone": planning(original, 1)["design_redraws_to_forgo_if_training"],
                "game1_review_delta": changed["game_1"]["final_review"] - original["game_1"]["final_review"],
                "game2_review_delta": changed["game_2"]["final_review"] - original["game_2"]["final_review"],
                "final_cash_delta_cents": changed["sidestreet_2"]["after_dismiss"]["cash_cents"] - original["sidestreet_2"]["after_dismiss"]["cash_cents"],
                "game2_alpha_redraws_available_for_voucher": planning(changed, 2)["alpha_redraws_recorded"],
                "game2_bank_arms": {name: planning_bank_bound(changed, 2, voucher, burst) for name, voucher, burst in
                    (("neither", False, False), ("voucher", True, False), ("burst", False, True), ("combined", True, True))}})
    with gzip.open(OUT / "remaining_publisher_contracts_rebaseline_v1_raw.json.gz", "rt", encoding="utf-8") as f:
        task7 = json.load(f)
    game3 = []
    for policy in ("cautious", "ordinary", "optimizer"):
        path = OUT / f"sidestreet_acceptance_stress_v1_{policy}_trait_task3_long_v1.json"
        row = json.loads(path.read_text(encoding="utf-8"))["rows"][0]
        assert row["valid"] and row["long_run"][0]["release"]["released"]
        game3.append({"policy": policy, "seed": row["seed"],
                      "production": production(row, 3), "planning": planning(row, 3),
                      "qa": qa(row, 3), "review": row["long_run"][0]["release"]["final_review"],
                      "cycle": row["long_run"][0]["release"]["cycle"]})
    raw = []
    for row in live_rows:
        p1, p2 = production(row, 1), production(row, 2)
        pl1, pl2 = planning(row, 1), planning(row, 2)
        q1, q2 = qa(row, 1), qa(row, 2)
        co = contracts(row)
        release = row["game_2"]
        market = sales.old.market(release)
        qa_bonus = q2["marketing_output_bonus_50"]
        if qa_bonus:
            boosted = sales.age_units(release, market, release["cycle"] + 2, qa_bonus)
            assert boosted >= release["month_1_units"]
        synthetic_strong = dict(release, final_review=9.1)
        synthetic_qa_delta = (sales.age_units(synthetic_strong, market, release["cycle"] + 2, qa_bonus)
                              - sales.age_units(synthetic_strong, market, release["cycle"] + 2))
        game2_design_priority = any(a["phase"] == "design_priority" and a.get("game") == 2 for a in row["actions"])
        free1 = free_priority_redraw_effect(row, 1, p1["free_priority_phase"])
        phase2 = ("design_priority" if p1["triggered"] and game2_design_priority else
                  p2["free_priority_phase"] if not p1["triggered"] else None)
        free2 = free_priority_redraw_effect(row, 2, phase2)
        career_saved = int(free1["free_commit"]) + int(free2["free_commit"])
        raw.append({"policy": row["policy"], "case": row["case"], "seed": row["seed"],
                    "beta_mode": row["beta_mode"], "reviews": [row["game_1"]["final_review"], release["final_review"]],
                    "awareness": [row["game_1"]["awareness"], release["awareness"]],
                    "production": [p1, p2], "planning": [pl1, pl2], "qa": [q1, q2],
                    "contracts": co, "no_staff_cash_cents": row["sidestreet_2"]["after_dismiss"]["cash_cents"],
                    "production_priority_cycles_saved_through_game2": career_saved,
                    "production_free_priority_redraw_effects": [free1, free2],
                    "qa_50_game2_month1_units_delta": (sales.age_units(release, market, release["cycle"] + 2, qa_bonus)
                                                       - release["month_1_units"]),
                    "synthetic_9_1_qa_50_game2_month1_units_delta": synthetic_qa_delta,
                    "game2_campaign_observed": any("campaign" in a["phase"] for a in row["actions"])})
    assert len(raw) == 135
    summary = {"revision": REVISION, "current_godot_two_game_routes": len(raw),
               "policies": dict(Counter(x["policy"] for x in raw)),
               "beta_modes": dict(Counter(x["beta_mode"] for x in raw)),
               "live_game3_route_count": len(game3), "live_game3": game3,
               "production": {}, "planning": {}, "planning_paired_capture": {}, "qa": {}, "qa_by_mode": {}, "contracts": {},
               "new_offer_contract_shadow": {}, "cash_sensitivity": {}}
    for game in (0, 1):
        label = f"game_{game+1}"
        summary["production"][label] = {
            "triggered": sum(x["production"][game]["triggered"] for x in raw),
            "training_game_free_priority": sum(x["production"][game]["training_game_free_priority"] for x in raw),
            "discount60_cents": percentile([x["production"][game]["discount_savings_cents"]["cap60"] for x in raw]),
            "discount90_cents": percentile([x["production"][game]["discount_savings_cents"]["cap90"] for x in raw]),
            "discount120_cents": percentile([x["production"][game]["discount_savings_cents"]["cap120"] for x in raw])}
        summary["planning"][label] = {"baseline_triggers": sum(x["planning"][game]["eligible_baseline"] for x in raw),
            "design_redraws_to_forgo": percentile([x["planning"][game]["design_redraws_to_forgo_if_training"] for x in raw]),
            "future_vouchers_redeemable_on_recorded_alpha_policy": sum(x["planning"][game]["eligible_baseline"] and x["planning"][1]["future_voucher_uses_at_recorded_policy"] for x in raw if game == 0)}
        summary["qa"][label] = {"trained": sum(x["qa"][game]["trained"] for x in raw),
            "mixed_reward_hands_after_training": sum(x["qa"][game]["reward_hand_after_training"] is not None for x in raw),
            "marketing25_positive": sum(x["qa"][game]["marketing_output_bonus_25"] > 0 for x in raw),
            "marketing50_positive": sum(x["qa"][game]["marketing_output_bonus_50"] > 0 for x in raw),
            "four_marketing_hands": sum(x["qa"][game]["four_marketing_specializations"] for x in raw),
            "old_fix_opportunities_after_training": sum(x["qa"][game]["old_known_fix_possible_after_training"] for x in raw)}
    for policy in ("ordinary", "optimizer"):
        pair = [x for x in planning_pairs if x["policy"] == policy]
        summary["planning_paired_capture"][policy] = {"n": len(pair),
            "first_game_triggers": sum(x["first_game_path_trigger"] for x in pair),
            "design_redraws_forgone": percentile([x["design_redraws_forgone"] for x in pair]),
            "game1_review_delta": percentile([x["game1_review_delta"] for x in pair]),
            "game2_review_delta": percentile([x["game2_review_delta"] for x in pair]),
            "cash_delta_cents": percentile([x["final_cash_delta_cents"] for x in pair]),
            "game2_voucher_redeemable": sum(x["first_game_path_trigger"] and x["game2_alpha_redraws_available_for_voucher"] > 0 for x in pair),
            "bank_arms_extra_opportunities": {arm: percentile([x["game2_bank_arms"][arm]["extra_redraw_opportunity_upper_bound"] for x in pair])
                for arm in ("neither", "voucher", "burst", "combined")}}
    for mode in ("qa", "marketing", "mixed"):
        group = [x for x in raw if x["beta_mode"] == mode]
        summary["qa_by_mode"][mode] = {"n_two_game_routes": len(group),
            "game1_trained": sum(x["qa"][0]["trained"] for x in group),
            "game1_50pct_positive": sum(x["qa"][0]["marketing_output_bonus_50"] > 0 for x in group),
            "game2_trained": sum(x["qa"][1]["trained"] for x in group),
            "game2_50pct_positive": sum(x["qa"][1]["marketing_output_bonus_50"] > 0 for x in group),
            "all_four_marketing_hands": sum(q["four_marketing_specializations"] for x in group for q in x["qa"])}
    for label in ("ironclad", "sidestreet_1", "sidestreet_2"):
        values = [x["contracts"][label] for x in raw]
        summary["contracts"][label] = {"mixed_first": sum(x["mixed_first"] for x in values),
            "mixed_second_only": sum(x["mixed_second_only"] for x in values),
            "free_uses_one": sum(x["free_use_one"] for x in values),
            "free_uses_two": sum(x["free_use_two"] for x in values),
            "old_refill_one": sum(x["old_refill_one"] for x in values),
            "old_refill_two": sum(x["old_refill_two"] for x in values)}
    for name in ("neon", "starwave", "synthetic_crown"):
        offers = [(r["synthetic_crown"] if name == "synthetic_crown" else r["candidates"].get(name)) for r in task7]
        offers = [x for x in offers if x]
        def mixed(hand):
            return any(LEDGER[i]["type"] == "pass" for i in hand["selected"]) and any(LEDGER[i]["type"] == "feature" for i in hand["selected"])
        summary["new_offer_contract_shadow"][name] = {"n": len(offers),
            "mixed_first": sum(mixed(x["hands"][0]) for x in offers),
            "first_mixed_only_on_final_hand": sum(not mixed(x["hands"][0]) and mixed(x["hands"][-1]) for x in offers),
            "redeemable_second_hand_free_redraws": sum(mixed(x["hands"][0]) and x["hands"][1]["redraw"] is not None for x in offers)}
    for staff in (0, 1, 2):
        for salary, bill, hire_cost, hire_cycle, timing in itertools.product(
                (50, 75, 100), (0, 75), (0, 100, 200), (0, 1), ("crossed", "following")):
            results = [cash_envelope(row, staff_count=staff, salary=salary, bill=bill,
                        hire_cost=hire_cost, hire_cycle=hire_cycle, boundary_timing=timing) for row in live_rows]
            key = f"staff{staff}|salary{salary}|bill{bill}|hire{hire_cost}|cycle{hire_cycle}|{timing}"
            summary["cash_sensitivity"][key] = {"first_unaffordable_count": sum(x["first_unaffordable"] is not None for x in results),
                "minimum_cash_cents": percentile([x["minimum_cash_cents"] for x in results]),
                "first_block_stages": dict(Counter(x["first_unaffordable"]["stage"] for x in results if x["first_unaffordable"])),
                "first_block_examples": [{"policy": row["policy"], "case": row["case"], **result["first_unaffordable"]}
                    for row, result in zip(live_rows, results) if result["first_unaffordable"]][:3]}
    summary["course_sensitivity"] = {}
    for price, raise_dollars, timing in itertools.product((0, 75, 150), (0, 25), ("crossed", "following")):
        results = [cash_envelope(row, staff_count=1, salary=75, bill=75, hire_cost=100,
                    hire_cycle=1, boundary_timing=timing, course_cost=price*100,
                    course_raise=raise_dollars, course=True) for row in live_rows]
        summary["course_sensitivity"][f"price{price}|raise{raise_dollars}|{timing}"] = {
            "first_unaffordable_count": sum(x["first_unaffordable"] is not None for x in results),
            "minimum_cash_cents": percentile([x["minimum_cash_cents"] for x in results]),
            "first_block_stages": dict(Counter(x["first_unaffordable"]["stage"] for x in results if x["first_unaffordable"]))}
    summary["qa_50_game2_month1_units_delta"] = percentile([x["qa_50_game2_month1_units_delta"] for x in raw])
    summary["synthetic_9_1_qa_50_game2_month1_units_delta"] = percentile([x["synthetic_9_1_qa_50_game2_month1_units_delta"] for x in raw])
    summary["two_employee_trigger_pairs"] = {
        "production_and_qa_game1": sum(x["production"][0]["triggered"] and x["qa"][0]["trained"] for x in raw),
        "production_and_contract_ironclad": sum(x["production"][0]["triggered"] and x["contracts"]["ironclad"]["trained_any"] for x in raw),
        "qa_and_contract_ironclad": sum(x["qa"][0]["trained"] and x["contracts"]["ironclad"]["trained_any"] for x in raw),
        "planning_and_production_same_design_path": sum(x["planning"][0]["eligible_baseline"] and x["production"][0]["triggered"] for x in raw),
        "note": "Co-occurring triggers are not stacked Production/Planning project burst grants; those paths remain mutually selected."}
    summary["production_priority_cycles_saved_through_game2"] = percentile([x["production_priority_cycles_saved_through_game2"] for x in raw])
    summary["production_free_priority_redraw_effects"] = {
        "foregone_normal_refills": sum(v["foregone_normal_refill"] for x in raw for v in x["production_free_priority_redraw_effects"]),
        "routes_with_later_fixed_choice_redraw_shortfall": sum(any(v["later_redraw_shortfalls"] for v in x["production_free_priority_redraw_effects"]) for x in raw),
        "total_later_redraw_shortfalls": sum(v["later_redraw_shortfalls"] for x in raw for v in x["production_free_priority_redraw_effects"])}
    summary["month1_only_finance_bound"] = {}
    for staff, bill in ((0, 0), (1, 0), (1, 75), (2, 75)):
        results = [cash_envelope(row, staff_count=staff, salary=75, bill=bill,
                    hire_cost=100, hire_cycle=1, boundary_timing="crossed", month1_only=True) for row in live_rows]
        summary["month1_only_finance_bound"][f"staff{staff}|bill{bill}"] = {
            "first_unaffordable_count": sum(x["first_unaffordable"] is not None for x in results),
            "minimum_cash_cents": percentile([x["minimum_cash_cents"] for x in results])}
    campaign = json.loads((OUT / "fanbase_48_57_current_v1_optimizer_task6.json").read_text(encoding="utf-8"))["rows"][0]["game_2_campaign"]
    assert campaign["after"]["cycle"] == campaign["before"]["cycle"] + 1
    summary["current_playable_campaign_example"] = {"cycle_before": campaign["before"]["cycle"],
        "cycle_after": campaign["after"]["cycle"], "cash_before_cents": campaign["before"]["cash_cents"],
        "cash_after_cents": campaign["after"]["cash_cents"],
        "direct_cost_cents": 10000,
        "sales_settlement_cents": campaign["after"]["cash_cents"] - campaign["before"]["cash_cents"] + 10000,
        "source": "current Godot same-seed 3.4/2.5 campaign route; no employee active"}
    for row, record in zip(live_rows, raw):
        record["finance_selected"] = {
            "playable_no_staff": cash_envelope(row, staff_count=0, salary=0, bill=0,
                hire_cost=0, hire_cycle=0, boundary_timing="crossed"),
            "one_staff_low": cash_envelope(row, staff_count=1, salary=50, bill=0,
                hire_cost=0, hire_cycle=0, boundary_timing="following"),
            "one_staff_course_mid": cash_envelope(row, staff_count=1, salary=75, bill=75,
                hire_cost=100, hire_cycle=1, boundary_timing="crossed", course=True,
                course_cost=7500, course_raise=25),
            "two_staff_high": cash_envelope(row, staff_count=2, salary=100, bill=75,
                hire_cost=200, hire_cycle=1, boundary_timing="crossed"),
            "month1_only_one_staff": cash_envelope(row, staff_count=1, salary=75, bill=75,
                hire_cost=100, hire_cycle=1, boundary_timing="crossed", month1_only=True)}
    with gzip.open(OUT / "employee_rewards_courses_recheck_v1_raw.json.gz", "wt", encoding="utf-8") as f:
        json.dump({"routes": raw, "planning_pairs": planning_pairs}, f, separators=(",", ":"))
    (OUT / "employee_rewards_courses_recheck_v1_summary.json").write_text(json.dumps(summary, indent=2), encoding="utf-8")
    print(json.dumps({"routes": len(raw), "production_game1": summary["production"]["game_1"]["triggered"],
                      "qa_game1": summary["qa"]["game_1"]["trained"]}))


if __name__ == "__main__":
    main()
