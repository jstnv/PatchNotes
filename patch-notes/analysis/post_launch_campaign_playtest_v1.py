"""Read-only, paired post-launch campaign sensitivity. No Godot state is written.

Usage: python analysis/post_launch_campaign_playtest_v1.py [seed] [per_cell]
All unimplemented Month 2+ and expense rules below are explicit candidates.
"""
from __future__ import annotations

import gzip
import json
import math
import random
import statistics
import sys
from functools import lru_cache
from pathlib import Path

import publisher_cash_payroll_v1 as prior

ROOT = Path(__file__).resolve().parents[1]
MARKETS = prior.base.MARKETS
PRICE_CENTS = 999
SHARE_PERCENT = 70
CAMPAIGN_CENTS = 10_000
HORIZON_BOUNDARIES = 24
REVIEWS = {"weak": 20, "typical": 70, "strong": 90,
           "matched_high_awareness_low_review": 40,
           "matched_low_awareness_high_review": 70}


def net_cents(units: int) -> int:
    return units * PRICE_CENTS * SHARE_PERCENT // 100


def month_one_units(review_tenths: int, awareness: int, market_bp: int) -> int:
    # Exact locked launch calculation; organic 100 is already in awareness.
    return 500 * review_tenths * (200 + awareness) * market_bp // (70 * 200 * 10_000)


@lru_cache(maxsize=None)
def organic_awareness_bp(launch_awareness: int, review_tenths: int,
                         month: int, retention_shift_bp: int = 0,
                         discovery_carryover_bp: int = 0) -> int:
    assert month >= 2
    value = launch_awareness * 5_000 + 200 * discovery_carryover_bp
    retention_bp = 2_500 + 55 * review_tenths + retention_shift_bp
    assert 0 <= retention_bp <= 10_000
    for _ in range(2, month):
        value = value * retention_bp // 10_000
    return value


@lru_cache(maxsize=None)
def later_units(review_tenths: int, launch_awareness: int, market_bp: int,
                month: int, prior_campaigns: int = -1, boost_bp: int = 1_000,
                boost_reference: str = "launch", retention_shift_bp: int = 0,
                discovery_carryover_bp: int = 0,
                boost_mode: str = "percent") -> tuple[int, int, int]:
    """Return units, organic Awareness basis points, active Awareness basis points.

    Unlike locked Month 1, the candidate later-month curve uses current Awareness
    without the +200 baseline. This is necessary for zero-unit dormancy; it is not
    an interpretation of existing gameplay. Fractional Awareness is floored to 4dp.
    """
    organic = organic_awareness_bp(launch_awareness, review_tenths, month,
                                   retention_shift_bp, discovery_carryover_bp)
    active = organic
    if prior_campaigns >= 0:
        if boost_mode == "fixed10":
            active += 100_000 // (prior_campaigns + 1)
        else:
            assert boost_mode == "percent"
            reference = launch_awareness * 10_000 if boost_reference == "launch" else organic
            active += reference * boost_bp // (10_000 * (prior_campaigns + 1))
    units = 500 * review_tenths * active * market_bp // (70 * 200 * 10_000 * 10_000)
    return units, organic, active


@lru_cache(maxsize=None)
def first_dormant_month(review_tenths: int, awareness: int, market_bp: int,
                        limit: int = 120, discovery_carryover_bp: int = 0) -> int | None:
    for month in range(2, limit + 1):
        if later_units(review_tenths, awareness, market_bp, month,
                       discovery_carryover_bp=discovery_carryover_bp)[0] == 0:
            return month
    return None


def studio_cash_at_release(row: dict) -> int:
    # Same conservative up-front Game 1 Feature play cost as the prior 6,300-path model.
    end_cycle = row["alignment"] + row["game1_cycles"]
    crossings = end_cycle // 2 - row["alignment"] // 2
    return (row["initial_cash"] - row["game1_play_spend"] - 75 * crossings) * 100


def release(review_tenths: int, awareness: int, market_bp: int) -> dict:
    return {"review_tenths": review_tenths, "awareness": awareness,
            "market_bp": market_bp, "age_cycles": 0, "earned_units": 0,
            "entitlement_cents": 0, "settled_cents": 0, "campaigns": 0,
            "campaign_months": {}, "monthly": {}}


def simulate(row: dict, review_tenths: int, launch_awareness: int,
             campaign_policy: str, employees: int = 1, optional_node: bool = False,
             boost_bp: int = 1_000, campaign_cents: int = CAMPAIGN_CENTS,
             boost_reference: str = "launch", retention_shift_bp: int = 0,
             insert_matched_slots: bool = True,
             discovery_carryover_bp: int = 0,
             boost_mode: str = "percent",
             ironclad_guarantee: bool = False) -> dict:
    """Run a matched action calendar, with campaign slots as neutral actions in control.

    Unaffordable campaigns fall back to neutral actions. Other hypothetical expenses
    continue below zero solely to measure the first shortfall, never as gameplay.
    """
    cycle = row["alignment"]
    cash = studio_cash_at_release(row) + (40_000 if ironclad_guarantee else 0)
    min_cash = cash
    first_shortfall = None
    initial = release(review_tenths, launch_awareness, row["market_bp"])
    releases = [initial]
    queue = ["contract_1", "contract_2", "reserve"]
    if optional_node:
        queue.append("store_node")
    queue += ["game2"] * row["game2_cycles"]
    game2_play_charged = False
    boundaries = []
    campaign_spend = 0
    campaign_attempts = 0
    campaign_accepted = 0
    slot_months = set()
    if campaign_policy in ("single", "repeat", "dormant") or insert_matched_slots:
        if campaign_policy == "single":
            slot_months.add(2)
        elif campaign_policy == "repeat":
            slot_months.update(range(2, HORIZON_BOUNDARIES + 2))
        elif campaign_policy == "dormant":
            dormant = first_dormant_month(review_tenths, launch_awareness,
                                          row["market_bp"],
                                          discovery_carryover_bp=discovery_carryover_bp)
            if dormant:
                slot_months.add(dormant)
        # Control arms receive the same slots supplied by the caller's policy.
    reserved_slots = set(slot_months)
    if campaign_policy == "none_single":
        reserved_slots = {2}
    elif campaign_policy == "none_repeat":
        reserved_slots = set(range(2, HORIZON_BOUNDARIES + 2))
    elif campaign_policy == "none_dormant":
        dormant = first_dormant_month(review_tenths, launch_awareness,
                                      row["market_bp"],
                                      discovery_carryover_bp=discovery_carryover_bp)
        reserved_slots = {dormant} if dormant else set()

    def mark_shortfall(stage: str):
        nonlocal min_cash, first_shortfall
        min_cash = min(min_cash, cash)
        if cash < 0 and first_shortfall is None:
            first_shortfall = {"stage": stage, "cycle": cycle,
                               "shortfall_cents": -cash}

    while len(boundaries) < HORIZON_BOUNDARIES:
        age_month = initial["age_cycles"] // 2 + 1
        first_age_cycle = initial["age_cycles"] % 2 == 0
        slot = first_age_cycle and age_month in reserved_slots
        if slot:
            reserved_slots.remove(age_month)
            action = "campaign_slot"
        elif queue:
            action = queue.pop(0)
        else:
            action = "neutral_productive_action"

        if action == "campaign_slot" and campaign_policy in ("single", "repeat", "dormant"):
            campaign_attempts += 1
            if cash >= campaign_cents:
                cash -= campaign_cents
                campaign_spend += campaign_cents
                initial["campaign_months"][age_month] = initial["campaigns"]
                initial["campaigns"] += 1
                campaign_accepted += 1
            else:
                # Failed campaign cannot spend cash, advance time, or boost sales.
                # The matched non-campaign productive action supplies this cycle.
                pass
        elif action == "contract_2":
            cash += (200_000 * row["contract"]["numerator"] // 96
                     if ironclad_guarantee else row["contract"]["payout_cents"])
        elif action == "reserve":
            cash -= 45_000
        elif action == "store_node":
            cash -= 170_000
        elif action == "game2" and not game2_play_charged:
            cash -= row["game2_play_spend"] * 100
            game2_play_charged = True
        mark_shortfall(action)

        cycle += 1
        for game in releases:
            game["age_cycles"] += 1
            m = (game["age_cycles"] - 1) // 2 + 1
            k = (game["age_cycles"] - 1) % 2 + 1
            if m == 1:
                units = month_one_units(game["review_tenths"], game["awareness"],
                                        game["market_bp"])
                organic_bp = game["awareness"] * 10_000
                active_bp = organic_bp
            else:
                units, organic_bp, active_bp = later_units(
                    game["review_tenths"], game["awareness"], game["market_bp"],
                    m, game["campaign_months"].get(m, -1), boost_bp,
                    boost_reference, retention_shift_bp,
                    discovery_carryover_bp, boost_mode)
            current_month_units = units * k // 2
            previous_month_units = units * (k - 1) // 2
            game["earned_units"] += current_month_units - previous_month_units
            game["entitlement_cents"] = net_cents(game["earned_units"])
            game["monthly"][m] = {"organic_awareness_bp": organic_bp,
                                   "active_awareness_bp": active_bp,
                                   "review_tenths": game["review_tenths"],
                                   "market_bp": game["market_bp"],
                                   "calculated_units": units,
                                   "earned_units": current_month_units}

        # A newly finished Game 2 is registered after this cycle; it earns later.
        if action == "game2" and "game2" not in queue:
            releases.append(release(round(row["review"] * 10),
                                    100 + row["marketing"], row["market_bp"]))

        if cycle % 2 == 0:
            settlement = 0
            earned = 0
            for game in releases:
                settlement += game["entitlement_cents"] - game["settled_cents"]
                game["settled_cents"] = game["entitlement_cents"]
                earned += game["entitlement_cents"]
            cash += settlement
            expense = (75 + employees * 100) * 100
            cash -= expense
            mark_shortfall("monthly bill and payroll")
            boundaries.append({"boundary": len(boundaries) + 1, "cycle": cycle,
                               "cash_cents": cash, "settled_this_boundary_cents": settlement,
                               "earned_cumulative_cents": earned,
                               "settled_cumulative_cents": sum(g["settled_cents"] for g in releases),
                               "expense_cents": expense,
                               "campaign_spend_cumulative_cents": campaign_spend,
                               "first_release_month": initial["age_cycles"] // 2,
                               "first_release_monthly": initial["monthly"].get(
                                   (initial["age_cycles"] + 1) // 2, {}),
                               "release_count": len(releases)})
        else:
            mark_shortfall(action)

    return {"boundaries": boundaries, "campaign_attempts": campaign_attempts,
            "campaign_accepted": campaign_accepted,
            "campaign_spend_cents": campaign_spend,
            "first_shortfall": first_shortfall, "min_cash_cents": min_cash,
            "first_release_monthly": initial["monthly"],
            "campaign_months": initial["campaign_months"],
            "first_release_month_one_units": month_one_units(review_tenths,
                                                               launch_awareness,
                                                               row["market_bp"]),
            "game2_launched": len(releases) > 1}


def pct(values: list[int], p: float) -> int:
    ordered = sorted(values)
    return ordered[min(len(ordered) - 1, math.floor((len(ordered) - 1) * p))]


def main(seed: int = 260927, per_cell: int = 150):
    assert month_one_units(70, 100, 10_000) == 750
    assert net_cents(750) == 524_475
    assert month_one_units(40, 325, 10_000) == 750
    assert later_units(70, 100, 10_000, 2)[0] == 125
    assert later_units(70, 100, 10_000, 2, 0)[0] == 150
    rng = random.Random(seed)
    rows = [prior.sample_run(target, policy, alignment, rng)
            for target in (7, 13, 19, 20, 21, 22, 23)
            for policy in ("conservative", "ordinary", "optimized")
            for alignment in (0, 1)
            for _ in range(per_cell)]
    # Preserve paired PRNG samples, action costs, Game 2, market, and alignment.
    # Synthetic Review anchors deliberately override the sampled low-Review launch.
    details = {}
    summary = {}
    staff_and_store = {}
    for label, review in REVIEWS.items():
        awareness = 325 if label == "matched_high_awareness_low_review" else 100
        records = []
        for i, row in enumerate(rows):
            no_single = simulate(row, review, awareness, "none_single")
            single = simulate(row, review, awareness, "single")
            no_repeat = simulate(row, review, awareness, "none_repeat")
            repeat = simulate(row, review, awareness, "repeat")
            no_dormant = simulate(row, review, awareness, "none_dormant")
            dormant = simulate(row, review, awareness, "dormant")
            # Omit the slot to express the cash timing cost of delaying Game 2.
            accelerated = simulate(row, review, awareness, "no_slots",
                                   insert_matched_slots=False)
            records.append({"sample": i, "alignment": row["alignment"],
                            "market_bp": row["market_bp"],
                            "studio_cash_cents": studio_cash_at_release(row),
                            "month_one_units": single["first_release_month_one_units"],
                            "dormant_month": first_dormant_month(review, awareness,
                                                                   row["market_bp"]),
                            "none_single_cash": [b["cash_cents"] for b in no_single["boundaries"]],
                            "single_cash": [b["cash_cents"] for b in single["boundaries"]],
                            "none_repeat_cash": [b["cash_cents"] for b in no_repeat["boundaries"]],
                            "repeat_cash": [b["cash_cents"] for b in repeat["boundaries"]],
                            "none_dormant_cash": [b["cash_cents"] for b in no_dormant["boundaries"]],
                            "dormant_cash": [b["cash_cents"] for b in dormant["boundaries"]],
                            "accelerated_cash": [b["cash_cents"] for b in accelerated["boundaries"]],
                            "single_spend_cents": single["campaign_spend_cents"],
                            "repeat_spend_cents": repeat["campaign_spend_cents"],
                            "repeat_accepted": repeat["campaign_accepted"],
                            "dormant_accepted": dormant["campaign_accepted"],
                            "repeat_campaign_profits_cents": [
                                net_cents(repeat["first_release_monthly"][m]["calculated_units"])
                                - net_cents(later_units(review, awareness, row["market_bp"], m)[0])
                                - CAMPAIGN_CENTS
                                for m in sorted(repeat["campaign_months"])],
                            "dormant_profit_cents": sum(
                                net_cents(dormant["first_release_monthly"][m]["calculated_units"])
                                - net_cents(later_units(review, awareness, row["market_bp"], m)[0])
                                - CAMPAIGN_CENTS
                                for m in dormant["campaign_months"]),
                            "single_shortfall": single["first_shortfall"],
                            "repeat_shortfall": repeat["first_shortfall"],
                            "none_single_shortfall": no_single["first_shortfall"],
                            "none_repeat_shortfall": no_repeat["first_shortfall"],
                            "dormant_shortfall": dormant["first_shortfall"],
                            "single_monthly": single["first_release_monthly"] if i == 0 else None,
                            "single_boundaries": single["boundaries"] if i == 0 else None,
                            "none_boundaries": no_single["boundaries"] if i == 0 else None})
        details[label] = records
        monthly = {}
        for j in range(HORIZON_BOUNDARIES):
            monthly[str(j + 1)] = {key: {"p10_cents": pct([r[key][j] for r in records], .1),
                                          "median_cents": int(statistics.median(r[key][j] for r in records)),
                                          "p90_cents": pct([r[key][j] for r in records], .9)}
                                     for key in ("none_single_cash", "single_cash", "none_repeat_cash",
                                                 "repeat_cash", "none_dormant_cash", "dormant_cash",
                                                 "accelerated_cash")}
        summary[label] = {"n": len(records), "review": review / 10,
                          "launch_awareness": awareness,
                          "month_one_units": {"p10": pct([r["month_one_units"] for r in records], .1),
                                              "median": int(statistics.median(r["month_one_units"] for r in records)),
                                              "p90": pct([r["month_one_units"] for r in records], .9)},
                          "dormant_month": {"p10": pct([r["dormant_month"] for r in records], .1),
                                            "median": int(statistics.median(r["dormant_month"] for r in records)),
                                            "p90": pct([r["dormant_month"] for r in records], .9)},
                          "monthly_boundary_cash": monthly,
                          "single_profit_cents": {"p10": pct([r["single_cash"][-1] - r["none_single_cash"][-1] for r in records], .1),
                                                  "median": int(statistics.median(r["single_cash"][-1] - r["none_single_cash"][-1] for r in records)),
                                                  "p90": pct([r["single_cash"][-1] - r["none_single_cash"][-1] for r in records], .9)},
                          "repeat_profit_cents": {"p10": pct([r["repeat_cash"][-1] - r["none_repeat_cash"][-1] for r in records], .1),
                                                  "median": int(statistics.median(r["repeat_cash"][-1] - r["none_repeat_cash"][-1] for r in records)),
                                                  "p90": pct([r["repeat_cash"][-1] - r["none_repeat_cash"][-1] for r in records], .9)},
                          "single_shortfall_pct": round(100 * sum(r["single_shortfall"] is not None for r in records) / len(records), 1),
                          "repeat_shortfall_pct": round(100 * sum(r["repeat_shortfall"] is not None for r in records) / len(records), 1),
                          "no_campaign_shortfall_pct": round(100 * sum(r["none_single_shortfall"] is not None for r in records) / len(records), 1),
                          "dormant_revived_pct": round(100 * sum(r["dormant_accepted"] > 0 for r in records) / len(records), 1),
                          "repeat_accepted_median": int(statistics.median(r["repeat_accepted"] for r in records))}
        summary[label]["profitable_repeat_after_first_pct"] = round(
            100 * sum(any(p > 0 for p in r["repeat_campaign_profits_cents"][1:])
                      for r in records) / len(records), 1)
        summary[label]["profitable_repeat_count_median"] = int(statistics.median(
            sum(p > 0 for p in r["repeat_campaign_profits_cents"]) for r in records))
        summary[label]["dormant_profit_cents"] = {
            "p10": pct([r["dormant_profit_cents"] for r in records], .1),
            "median": int(statistics.median(r["dormant_profit_cents"] for r in records)),
            "p90": pct([r["dormant_profit_cents"] for r in records], .9)}
        summary[label]["by_alignment"] = {
            str(a): {"n": len(group),
                     "month1_cash_median_cents": int(statistics.median(r["none_single_cash"][0] for r in group)),
                     "month2_cash_median_cents": int(statistics.median(r["single_cash"][1] for r in group)),
                     "month24_cash_median_cents": int(statistics.median(r["single_cash"][-1] for r in group)),
                     "single_shortfall_pct": round(100 * sum(r["single_shortfall"] is not None for r in group) / len(group), 1)}
            for a in (0, 1) for group in [[r for r in records if r["alignment"] == a]]}
        # Exact 25/cell stratified slice of the 150/cell default cohort.
        sensitivity_rows = rows[::6] if per_cell >= 6 else rows
        staff_and_store[label] = {}
        for employees, optional in ((0, False), (1, False), (2, False), (1, True)):
            controls = [simulate(r, review, awareness, "none_single",
                                 employees=employees, optional_node=optional)
                        for r in sensitivity_rows]
            campaigns = [simulate(r, review, awareness, "single",
                                  employees=employees, optional_node=optional)
                         for r in sensitivity_rows]
            staff_and_store[label][f"staff{employees}_node{int(optional)}"] = {
                "n": len(sensitivity_rows),
                "control_shortfall_pct": round(100 * sum(p["first_shortfall"] is not None for p in controls) / len(controls), 1),
                "campaign_shortfall_pct": round(100 * sum(p["first_shortfall"] is not None for p in campaigns) / len(campaigns), 1),
                "campaign_month24_cash_median_cents": int(statistics.median(p["boundaries"][-1]["cash_cents"] for p in campaigns)),
                "first_shortfall_stage_counts": dict(__import__("collections").Counter(
                    p["first_shortfall"]["stage"] for p in campaigns if p["first_shortfall"] is not None))}
    # Pure marginal economics at first dormancy, including repeat saturation.
    marginal = {}
    for label, review in REVIEWS.items():
        awareness = 325 if label == "matched_high_awareness_low_review" else 100
        month = first_dormant_month(review, awareness, 10_000)
        base = later_units(review, awareness, 10_000, month)[0]
        offers = []
        for n in range(6):
            extra = later_units(review, awareness, 10_000, month, n)[0] - base
            offers.append({"prior_campaigns": n, "extra_units": extra,
                           "incremental_net_cents": net_cents(extra),
                           "profit_after_100_cents": net_cents(extra) - CAMPAIGN_CENTS})
        marginal[label] = {"first_dormant_month": month, "offers": offers}
    # Sensitivities on the neutral-market, 100-Awareness Review 7 release.
    sensitivities = {}
    for reference in ("launch", "current"):
        for shift in (-500, 0, 500):
            for boost in (500, 1_000, 2_000):
                month = first_dormant_month(70, 100, 10_000)
                base = later_units(70, 100, 10_000, month,
                                   retention_shift_bp=shift)[0]
                boosted = later_units(70, 100, 10_000, month, 0, boost,
                                      reference, shift)[0]
                sensitivities[f"{reference}_retention_shift{shift}_boost{boost}"] = {
                    "month": month, "base_units": base, "boosted_units": boosted,
                    "incremental_net_cents": net_cents(boosted) - net_cents(base),
                    "profit_at_50_100_200_dollars_cents":
                        [net_cents(boosted) - net_cents(base) - x
                         for x in (5_000, 10_000, 20_000)]}
    output = {"seed": seed, "per_cell": per_cell, "n": len(rows),
              "source_commit": "b07a658", "horizon_boundaries": HORIZON_BOUNDARIES,
              "assumptions": "Month 2+ candidate uses current Awareness without Month 1's +200 baseline; Month 2 organic is half launch and later retention is 0.25+0.055*Review, floored to 4dp; campaign adds 10% launch Awareness/(1+prior) for one release-age month; exact integer units/cents; $75 bill and $100 salary/staff after settlement; no fan growth; market fixed per release; control slots are equally productive neutral actions; Game 2 and Contract from prior sampled policy model; no negative cash accepted as gameplay.",
              "summary": summary, "marginal_dormant": marginal,
              "staff_and_store_sensitivity": staff_and_store,
              "sensitivity": sensitivities, "first_sample": {
                  label: {"single_boundaries": records[0]["single_boundaries"],
                          "none_boundaries": records[0]["none_boundaries"],
                          "single_monthly": records[0]["single_monthly"]}
                  for label, records in details.items()}}
    raw = ROOT / "design-logs/post_launch_campaign_playtest_v1_results.json.gz"
    with gzip.open(raw, "wt", encoding="utf-8", compresslevel=9) as handle:
        json.dump({"summary": output, "paths": details}, handle, separators=(",", ":"))
    print(json.dumps(output, indent=2))


if __name__ == "__main__":
    main(int(sys.argv[1]) if len(sys.argv) > 1 else 260927,
         int(sys.argv[2]) if len(sys.argv) > 2 else 150)
