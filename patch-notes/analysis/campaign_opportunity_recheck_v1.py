"""Read-only Task 9 analysis of current Godot Studio action captures.

Run from the patch-notes project root with Python 3:
  python analysis/campaign_opportunity_recheck_v1.py
No gameplay state or source file is modified by this analysis.
"""
import copy
import json
from collections import Counter
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "design-logs"
POLICIES = ("cautious", "ordinary", "optimizer")
ARMS = ("campaign", "store", "contract", "next_game")
PRICE_CENTS = 999
PLATFORM_PERCENT = 70


def net_cents(units):
    return units * PRICE_CENTS * PLATFORM_PERCENT // 100


def monthly_units(review_tenths, active_scaled, market_bp):
    return 500 * review_tenths * active_scaled * market_bp // (70 * 200 * 10000 * 10000)


def normalized_state(state):
    result = copy.deepcopy(state)
    for sale in result["sales"]:
        sale.pop("release_id", None)
    return result


def month_path(release, carryover_percent=15, campaign_ages=()):
    """Mirror the current integer Month 2+ trial using frozen live launch inputs."""
    review = round(release["final_review"] * 10)
    awareness = release["awareness"]
    market = release["forecast_bp"]
    organic = 0
    total = 0
    rows = []
    count = 0
    for age in range(2, 25):
        if age == 2:
            organic = awareness * 5000 + 200 * carryover_percent * 100
        else:
            organic = organic * (2500 + 55 * review) // 10000
        boost = (100000 // (count + 1)) if age in campaign_ages else 0
        active = organic + boost
        units = monthly_units(review, active, market)
        total += units
        rows.append({"age_month": age, "organic_scaled": organic, "boost_scaled": boost,
                     "units": units, "cumulative_later_units": total})
        if boost:
            count += 1
    return rows


def run():
    traces = {}
    for policy in POLICIES:
        for arm in ARMS:
            name = f"campaign_opportunity_capture_v1_{policy}_{arm}_task9_fixed.json"
            data = json.loads((OUT / name).read_text(encoding="utf-8"))
            assert data["failures"] == 0 and data["count"] == 4
            traces[policy, arm] = data["rows"]

    rows = []
    sensitivity = []
    matched = 0
    for policy in POLICIES:
        for case in range(4):
            arms = {arm: traces[policy, arm][case] for arm in ARMS}
            state = normalized_state(arms["campaign"]["shared_studio_before_action"])
            is_matched = all(normalized_state(arms[arm]["shared_studio_before_action"]) == state for arm in ARMS)
            matched += is_matched
            campaign = arms["campaign"]
            quote = campaign["campaign_quote_at_shared_state"]
            projection = campaign["campaign_projection_at_shared_state"]
            second = campaign["game_2"]
            before = campaign["shared_studio_before_action"]
            after = campaign["alternative_action_after"]
            success = after["cycle"] == before["cycle"] + 1 and bool(campaign["campaign_history_after"].get("campaign_months"))
            baseline = projection["projected_month_units"]
            boosted = projection["campaign_projected_month_units"]
            prior = before["sales"][1]["earned_units"]
            incremental_units = boosted - baseline
            incremental_net = net_cents(prior + boosted) - net_cents(prior + baseline)
            next_game = arms["next_game"]["alternative_action_after"]
            rows.append({"policy": policy, "case": case, "seed": campaign["seed"], "matched": is_matched,
                         "review": second["final_review"], "awareness": second["awareness"],
                         "market_bp": second["forecast_bp"], "studio_cycle": before["cycle"],
                         "studio_cash_cents": before["cash_cents"], "age_cycles": projection["total_earned_cycles"],
                         "eligible": quote["eligible"], "affordable": quote["affordable"], "success": success,
                         "month_units_no_campaign": baseline, "month_units_campaign": boosted,
                         "attributable_units": incremental_units, "attributable_net_cents": incremental_net,
                         "price_cents": 10000, "margin_cents": incremental_net - 10000,
                         "campaign_action_cash_delta_cents": after["cash_cents"] - before["cash_cents"],
                         "next_game_action_cash_delta_cents": next_game["cash_cents"] - before["cash_cents"],
                         "campaign_action_cycle": after["cycle"], "next_game_action_cycle": next_game["cycle"],
                         "store_action": arms["store"].get("alternative_store_id", "unavailable"),
                         "store_action_cycle": arms["store"].get("alternative_action_after", {}).get("cycle"),
                         "contract_available": "alternative_contract" in arms["contract"],
                         "contract_first_hand_cycle": arms["contract"].get("alternative_action_after", {}).get("cycle"),
                         "game3_release_cycles": {arm: arms[arm]["game_3"]["cycle"] for arm in ARMS},
                         "game3_release_cash_cents": {arm: arms[arm]["after_release_3"]["cash_cents"] for arm in ARMS},
                         "campaign_minus_next_game_cash_at_game3_release_cents":
                            arms["campaign"]["after_release_3"]["cash_cents"] - arms["next_game"]["after_release_3"]["cash_cents"],
                         "game3_release_sales": {arm: arms[arm]["after_release_3"]["sales"] for arm in ARMS}})
            for carry in (0, 15, 30):
                normal = month_path(second, carry)
                once = month_path(second, carry, (2,))
                repeat = month_path(second, carry, (2, 3))
                for age in (2, 3, 6, 12, 24):
                    idx = age - 2
                    plain = normal[idx]["units"]
                    first = once[idx]["units"]
                    twice = repeat[idx]["units"]
                    sensitivity.append({"policy": policy, "case": case, "review": second["final_review"],
                                        "carryover_percent": carry, "age_month": age,
                                        "normal_units": plain, "campaign2_units": first,
                                        "repeat3_units": twice,
                                        "first_campaign_incremental_units": first - plain if age == 2 else 0,
                                        "second_campaign_incremental_units": twice - plain if age == 3 else 0})

    assert matched == 12, f"Only {matched} of 12 Studio states match across arms"
    assert all(r["attributable_units"] >= 0 for r in rows)
    assert all(r["margin_cents"] < 0 for r in rows)
    high = []
    for review_tenths in (70, 91, 95):
        for awareness in (100, 150, 200):
            mock = {"final_review": review_tenths / 10, "awareness": awareness, "forecast_bp": 10000}
            normal = month_path(mock)
            once = month_path(mock, campaign_ages=(2,))
            repeat = month_path(mock, campaign_ages=(2, 3))
            for age in (2, 3):
                idx = age - 2
                boosted_month_units = (once if age == 2 else repeat)[idx]["units"]
                base_month_units = normal[idx]["units"]
                units = boosted_month_units - base_month_units
                # Synthetic frozen Month 1 total; cumulative rounding is retained.
                prior_units = 1000 + sum(x["units"] for x in normal[:idx])
                incremental_net = net_cents(prior_units + boosted_month_units) - net_cents(prior_units + base_month_units)
                high.append({"synthetic": True, "review": review_tenths / 10,
                             "awareness": awareness, "age_month": age, "boost_points": 10 if age == 2 else 5,
                             "synthetic_prior_units": prior_units,
                             "incremental_units": units, "attributable_net_cents": incremental_net,
                             "margin_cents": incremental_net - 10000})

    result = {"source": "current Godot scene captures at HEAD 606f011d0bfdaca27dc662062ec6498a5942627a",
              "cases": len(rows), "matched_studio_states": matched,
              "eligible": sum(x["eligible"] for x in rows), "affordable": sum(x["affordable"] for x in rows),
              "successful_campaigns": sum(x["success"] for x in rows),
              "successful_by_policy": dict(Counter(x["policy"] for x in rows if x["success"])),
              "actual_eligible_margins_cents": [x["margin_cents"] for x in rows if x["success"]],
              "actual_eligible_incremental_units": [x["attributable_units"] for x in rows if x["success"]],
              "synthetic_high_review": high,
              "notes": ["Month 2+ carryover sensitivities and high-Review examples are separate read-only calculations; no game values changed.",
                        "Only successful live campaign actions are counted as purchases; an unaffordable or wrong-timing button press is a rejected action."]}
    (OUT / "campaign_opportunity_recheck_v1_summary.json").write_text(json.dumps(result, indent=2), encoding="utf-8")
    (OUT / "campaign_opportunity_recheck_v1_raw.json").write_text(json.dumps({"live": rows, "sensitivity": sensitivity, "synthetic_high": high}, indent=2), encoding="utf-8")
    print(json.dumps(result, indent=2))


if __name__ == "__main__":
    run()
