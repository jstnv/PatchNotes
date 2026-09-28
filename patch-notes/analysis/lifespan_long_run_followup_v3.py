"""Read-only two-release Month 2+ / campaign sensitivity from Godot traces.

Run: python -B analysis/lifespan_long_run_followup_v3.py
This does not edit gameplay or claim later sales/campaigns are implemented.
"""
from __future__ import annotations

import gzip
import json
import statistics
import zipfile
from collections import Counter
from pathlib import Path

import post_launch_campaign_playtest_v1 as sales

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "design-logs"
TRACE_ARCHIVE = OUT / "overnight_current_playtest_v1_raw_traces.zip"
TRACE_NAMES = tuple(f"overnight_current_playtest_v1_{p}_second_batch_30.json"
                    for p in ("cautious", "ordinary", "optimizer"))
MARKETS = tuple(x["launch_demand_basis_points"] for x in
                json.loads((ROOT / "data/primitive_market_forecast_ledger.json").read_text()))
PRICE_CENTS = 999
SHARE_PERCENT = 70


def percentile(values, q):
    v = sorted(values)
    return v[int((len(v) - 1) * q)]


def stats(values):
    v = list(values)
    return {"n": len(v), "p10": percentile(v, .1), "median": statistics.median(v),
            "p90": percentile(v, .9), "min": min(v), "max": max(v)}


def market_for(release):
    review = round(release["final_review"] * 10)
    matches = [bp for bp in MARKETS if sales.month_one_units(review, release["awareness"], bp)
               == release["month_1_units"]]
    assert len(matches) == 1, (release["release_id"], matches)
    return matches[0]


def load_rows():
    with zipfile.ZipFile(TRACE_ARCHIVE) as archive:
        for name in TRACE_NAMES:
            doc = json.loads(archive.read(name))
            assert doc["failures"] == 0 and len(doc["rows"]) == 30
            for row in doc["rows"]:
                assert row["valid"] and row["game_1"]["released"] and row["game_2"]["released"]
                releases = [dict(row["game_1"]), dict(row["game_2"])]
                for rel in releases:
                    rel["market_bp"] = market_for(rel)
                    assert rel["projected_net_cents"] == sales.net_cents(rel["month_1_units"])
                yield row, releases


def monthly_units(rel, age_month, carry_bp, market_shift_bp=0,
                  campaign_count=None, awareness_shift=0):
    review = round(rel["final_review"] * 10)
    awareness = max(0, rel["awareness"] + awareness_shift)
    bp = max(1, rel["market_bp"] + market_shift_bp)
    if age_month == 1:
        return sales.month_one_units(review, awareness, bp)
    return sales.later_units(review, awareness, bp, age_month,
                             prior_campaigns=-1 if campaign_count is None else campaign_count,
                             discovery_carryover_bp=carry_bp,
                             boost_mode="fixed10")[0]


def simulate(releases, start_cash, carry_bp, horizon=48, campaigns=(),
             monthly_expense_cents=0, changing_market=False):
    """Replay 2 cycles/month, settled on the same even cycle as earned sales.

    Base cash is the observed Game-2 launch cash. We rebuild both sales ledgers
    from their actual release cycles, then subtract the Game-1 Month-1 amount
    already settled in that base cash. Candidate Month-2+ may therefore add
    money earned during Game-2 development. The intervening gameplay actions
    stay fixed; this is a sales overlay, not a new Godot run.
    """
    c1, c2 = (r["cycle"] for r in releases)
    assert c1 < c2
    assert start_cash >= 0
    campaign_map = {(x["cycle"], x["release"]): x for x in campaigns}
    campaign_counts = [0, 0]
    campaign_months = {}
    cumulative_units = [0, 0]
    pending = [0, 0]
    settled = [0, 0]
    spent = 0
    boundaries = []
    first_negative = None
    first_zero_age = [None, None]
    for cycle in range(c1 + 1, c2 + horizon + 1):
        for rid, rel in enumerate(releases):
            action = campaign_map.get((cycle, rid))
            if action:
                spent += action["cost_cents"]
                campaign_months[(rid, (cycle - rel["cycle"] - 1) // 2 + 1)] = campaign_counts[rid]
                campaign_counts[rid] += 1
            age_cycle = cycle - rel["cycle"]
            if age_cycle <= 0:
                continue
            age_month = (age_cycle - 1) // 2 + 1
            half = (age_cycle - 1) % 2 + 1
            shift = 0
            if changing_market and age_month >= 2:
                shift = 1500 if age_month % 2 == 0 else -1500
            units = monthly_units(rel, age_month, carry_bp, shift,
                                  campaign_months.get((rid, age_month)))
            if age_month >= 2 and units == 0 and first_zero_age[rid] is None:
                first_zero_age[rid] = age_month
            prior = units * (half - 1) // 2
            earned = units * half // 2 - prior
            assert earned >= 0
            cumulative_units[rid] += earned
            # Exact monthly net from cumulative units, so odd unit counts do
            # not lose a cent to independent half-cycle rounding.
            prior_net = prior * PRICE_CENTS * SHARE_PERCENT // 100
            current_net = (prior + earned) * PRICE_CENTS * SHARE_PERCENT // 100
            pending[rid] += current_net - prior_net
        if cycle % 2 == 0:
            for rid in range(2):
                settled[rid] += pending[rid]
                pending[rid] = 0
            if cycle >= c2:
                # The observed c2 cash already contains Game-1 Month-1
                # settlement; no Game-2 Month-1 cash is booked at launch.
                cash = (start_cash + sum(settled)
                        - releases[0]["projected_net_cents"]
                        - spent - monthly_expense_cents * ((cycle - c2 + 1) // 2))
                if cash < 0 and first_negative is None:
                    first_negative = cycle
                boundaries.append({"cycle": cycle, "cash_cents": cash,
                                   "settled_cents": settled.copy(),
                                   "units": cumulative_units.copy(),
                                   "campaigns": campaign_counts.copy()})
    return {"boundaries": boundaries, "final_cash_cents": boundaries[-1]["cash_cents"],
            "cumulative_units": cumulative_units,
            "settled_cents": settled, "first_zero_age_month": first_zero_age,
            "first_negative_cycle": first_negative, "campaign_spend_cents": spent}


def candidate_campaign(releases, which=0, cost=10_000, when="early"):
    rel = releases[which]
    age = 3 if when == "early" else 21
    return {"cycle": rel["cycle"] + age, "release": which, "cost_cents": cost}


def first_month_entitlement_at_boundary(rel, boundary_cycle, release_delay=0):
    earned_cycles = min(2, max(0, boundary_cycle - (rel["cycle"] + release_delay)))
    cumulative_units = rel["month_1_units"] * earned_cycles // 2
    # Earnings not yet settled before the next even boundary are excluded.
    return sales.net_cents(cumulative_units)


def opportunity_bounds(row, releases):
    """Explicit one-cycle alternatives; no campaign action exists in the build."""
    c1, c2 = (r["cycle"] for r in releases)
    contract = row.get("contract", {})
    contract_total = contract.get("completion", {}).get("payout_cents", 0)
    store = row.get("store_purchase", {})
    store_offer = store.get("offer", {})
    # Current Store node purchases are zero-cycle. This is a future one-cycle
    # rule sensitivity, not a currently legal competing action.
    store_price = store_offer.get("price_cents", None)
    boundary = c2 + (2 - c2 % 2)
    regular = first_month_entitlement_at_boundary(releases[1], boundary)
    delayed = first_month_entitlement_at_boundary(releases[1], boundary, 1)
    return {"ironclad_payout_cents": contract_total,
            "store_success": bool(store.get("success")),
            "store_price_cents": store_price,
            "live_store_cycle_cost": 0,
            "proposed_store_cycle_cost": 1,
            "game2_first_boundary_cycle": boundary,
            "game2_month1_settlement_delayed_cents": regular - delayed,
            "game2_month1_full_net_cents": releases[1]["projected_net_cents"]}


def main():
    sources = list(load_rows())
    assert len(sources) == 90
    raw = []
    for row, releases in sources:
        base_cash = row["after_release_2"]["cash_cents"]
        for carry in (0, 1500, 3000):
            control = simulate(releases, base_cash, carry)
            # Campaign interventions are separate scenario overlays, with
            # the same subsequent cycle count. The campaign's one-cycle
            # opportunity cost is evaluated as a bound below.
            for cost in (5000, 10000, 20000):
                one = simulate(releases, base_cash, carry,
                               campaigns=(candidate_campaign(releases, cost=cost),))
                raw.append({"policy": row["policy"], "seed": row["seed"],
                            "case": row["case"], "carry_bp": carry,
                            "campaign_cost_cents": cost,
                            "releases": [{k: rel[k] for k in ("release_id", "cycle", "final_review",
                                        "awareness", "market_bp", "month_1_units", "projected_net_cents")}
                                         for rel in releases],
                            "base_cash_cents": base_cash,
                            "control": control, "one_campaign": one,
                            "campaign_cash_delta_cents": one["final_cash_cents"] - control["final_cash_cents"]})
    by = {}
    for carry in (0, 1500, 3000):
        subset = [r for r in raw if r["carry_bp"] == carry and r["campaign_cost_cents"] == 10000]
        by[str(carry)] = {"n": len(subset),
                          "control_end_cash_cents": stats(x["control"]["final_cash_cents"] for x in subset),
                          "control_total_units": stats(sum(x["control"]["cumulative_units"]) for x in subset),
                          "game1_first_zero_age_month": stats((x["control"]["first_zero_age_month"][0] or 121) for x in subset),
                          "game2_first_zero_age_month": stats((x["control"]["first_zero_age_month"][1] or 121) for x in subset),
                          "campaign_end_cash_delta_cents": stats(x["campaign_cash_delta_cents"] for x in subset),
                          "campaign_profitable_pct": 100 * sum(x["campaign_cash_delta_cents"] > 0 for x in subset) / len(subset),
                          "first_negative_count": sum(x["control"]["first_negative_cycle"] is not None for x in subset)}
    opportunity = [opportunity_bounds(row, releases) for row, releases in sources]
    by_cost = {}
    for cost in (5000, 10000, 20000):
        subset = [r for r in raw if r["carry_bp"] == 1500 and r["campaign_cost_cents"] == cost]
        by_cost[str(cost)] = {"n": len(subset),
                              "delta_cents": stats(x["campaign_cash_delta_cents"] for x in subset),
                              "profitable_pct": round(100 * sum(x["campaign_cash_delta_cents"] > 0 for x in subset) / len(subset), 2)}
    # C: fixed near-zero/strong Review monotonicity, changing markets,
    # dormant revival, two attempts in one month, overlapping releases.
    checks = Counter()
    for row, releases in sources:
        for carry in (0, 1500, 3000):
            base = simulate(releases, row["after_release_2"]["cash_cents"], carry)
            variable = simulate(releases, row["after_release_2"]["cash_cents"], carry,
                                changing_market=True)
            checks["market_scenarios"] += 1
            assert all(x["cash_cents"] >= 0 for x in base["boundaries"])
            assert variable["cumulative_units"][0] >= 0
            for rel in releases:
                for age in range(2, 25):
                    low = dict(rel, final_review=0.1)
                    high = dict(rel, final_review=9.1)
                    assert monthly_units(high, age, carry) >= monthly_units(low, age, carry)
                    checks["review_monotonic_comparisons"] += 1
            # Same-age double campaign is a deliberate alternate scenario:
            # one $100 action after another within the same month.
            first = candidate_campaign(releases, cost=10000)
            second = dict(first, cycle=first["cycle"] + 1)
            pair = simulate(releases, row["after_release_2"]["cash_cents"], carry,
                            campaigns=(first, second))
            checks["stacking_scenarios"] += 1
            assert pair["campaign_spend_cents"] == 20000
    # Month-1 parity under both half-month alignments and exact net cents.
    for _, releases in sources:
        for rel in releases:
            assert sales.net_cents(rel["month_1_units"]) == rel["projected_net_cents"]
            checks["month1_parity"] += 1
    # C: bounded low/high Awareness and Review, dormant revival, repeat
    # returns, and two explicitly different same-month stacking assumptions.
    robustness = {}
    for review in (1, 50, 70, 91):
        for awareness in (25, 100, 325):
            rel = {"final_review": review / 10, "awareness": awareness, "market_bp": 10000,
                   "month_1_units": sales.month_one_units(review, awareness, 10000),
                   "cycle": 14, "projected_net_cents": sales.net_cents(sales.month_one_units(review, awareness, 10000))}
            for carry in (0, 1500, 3000):
                units = [monthly_units(rel, month, carry) for month in range(2, 121)]
                dormant = next((i + 2 for i, value in enumerate(units) if value == 0), None)
                assert dormant is not None
                revival = monthly_units(rel, dormant, carry, campaign_count=0)
                assert revival >= units[dormant - 2]
                attempts = []
                for age in range(2, 25):
                    baseline = monthly_units(rel, age, carry)
                    boosted = monthly_units(rel, age, carry, campaign_count=age - 2)
                    attempts.append(sales.net_cents(boosted) - sales.net_cents(baseline) - 10000)
                key = f"review{review}|awareness{awareness}|carry{carry}"
                robustness[key] = {"first_zero_age_month": dormant,
                                   "dormant_revival_units": revival,
                                   "first_campaign_delta_cents": attempts[0],
                                   "repeat_profitable_count": sum(x > 0 for x in attempts),
                                   "repeat_total_delta_cents": sum(attempts),
                                   "same_month_second_attempt_last_wins_units": monthly_units(rel, 2, carry, campaign_count=1),
                                   "same_month_additive_awareness_points": 15}
                assert all(value >= 0 for value in units)
                checks["robustness_scenarios"] += 1
    summary = {"source_revision": "ba616515ed1b039fd0da7cf03f73288fd7ccd8e4",
               "source": str(TRACE_ARCHIVE), "paired_godot_two_release_rows": len(sources),
               "scenario_rows": len(raw), "carryover": by,
               "campaign_cost_sensitivity_15pct": by_cost,
               "opportunity_bounds": {"game2_first_boundary_delay_cents": stats(x["game2_month1_settlement_delayed_cents"] for x in opportunity),
                                      "game2_full_month1_net_cents": stats(x["game2_month1_full_net_cents"] for x in opportunity),
                                      "store_success_count": sum(x["store_success"] for x in opportunity),
                                      "store_current_cycle_cost": 0,
                                      "ironclad_paid_payout_cents": stats(x["ironclad_payout_cents"] for x in opportunity),
                                      "campaign_100_dominates_ironclad_count": sum(x["ironclad_payout_cents"] < raw[i * 9 + 4]["campaign_cash_delta_cents"] for i, x in enumerate(opportunity))},
               "robustness": robustness, "checks": dict(checks),
               "limitations": ["Month 2+ and campaigns are proposed, not implemented",
                               "Actions and Game-2 launch date remain fixed after source traces",
                               "Market is inferred uniquely from actual Month-1 units among five live ledger values",
                               "No human post-first-game 9+ action trace; high-Review checks are synthetic",
                               "Bills, payroll, fanbase, and campaign one-cycle opportunity cost excluded from A cash; bounded separately"]}
    (OUT / "lifespan_long_run_followup_v3_summary.json").write_text(json.dumps(summary, indent=2))
    with gzip.open(OUT / "lifespan_long_run_followup_v3_raw.json.gz", "wt", encoding="utf-8") as f:
        json.dump({"paired_scenarios": raw, "opportunity_bounds": opportunity}, f, separators=(",", ":"))
    print(json.dumps(summary, indent=2))


if __name__ == "__main__":
    main()
