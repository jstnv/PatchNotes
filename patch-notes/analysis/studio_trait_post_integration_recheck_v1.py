"""Read-only paired trait shortlist on fresh Godot two-release traces.

Run from patch-notes: python -B analysis/studio_trait_post_integration_recheck_v1.py
No gameplay state or trait rule is changed by this analysis.
"""
from __future__ import annotations

import gzip
import json
import statistics
from collections import Counter
from pathlib import Path

import post_launch_campaign_playtest_v1 as month_one
import studio_trait_followup_live_overlay_v1 as old
import studio_trait_choices_v1 as backgrounds

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "design-logs"
POLICIES = ("cautious", "ordinary", "optimizer")
SOURCE_FILES = tuple(OUT / f"sidestreet_acceptance_stress_v1_{p}_trait_task3_v1.json" for p in POLICIES)
LONG_FILES = tuple(OUT / f"sidestreet_acceptance_stress_v1_{p}_trait_task3_long_v1.json" for p in POLICIES)
BASELINE_SCENARIO = "no_trait"


def net(units: int) -> int:
    return units * 999 * 70 // 100


def age_units(release: dict, market_bp: int, cycle: int, awareness_delta: int = 0,
              campaign_months: dict[int, int] | None = None) -> int:
    """Exact integer arithmetic of the current ReleasedGameSales no-campaign path."""
    age = max(0, cycle - release["cycle"])
    if age == 0:
        return 0
    review = round(release["final_review"] * 10)
    awareness = max(0, release["awareness"] + awareness_delta)
    total = month_one.month_one_units(review, awareness, market_bp)
    earned = total // 2 if age == 1 else total
    organic = awareness * 5000 + 200 * 1500
    campaigns = campaign_months or {}
    for month in range(2, (age + 1) // 2 + 1):
        if month > 2:
            organic = organic * (2500 + 55 * review) // 10000
        active = organic + (100000 // (1 + campaigns[month]) if month in campaigns else 0)
        units = 500 * review * active * market_bp // (70 * 200 * 10000 * 10000)
        earned += units if age >= 2 * month else units // 2
    return earned


def load_rows() -> list[dict]:
    rows = []
    for path in SOURCE_FILES:
        doc = json.loads(path.read_text(encoding="utf-8"))
        assert doc["failures"] == 0 and doc["count"] == 4
        for row in doc["rows"]:
            assert row["valid"] and row["game_1"]["released"] and row["game_2"]["released"]
            for key in ("game_1", "game_2"):
                row[key]["market_bp"] = old.market(row[key])
            rows.append(row)
    return rows


def live_parity(rows: list[dict]) -> dict:
    checked = 0
    for row in rows:
        releases = {row[key]["release_id"]: row[key] for key in ("game_1", "game_2")}
        for _, snap in old.snapshots(row):
            for sales in snap.get("sales", []):
                rel = releases[sales["release_id"]]
                units = age_units(rel, rel["market_bp"], snap["cycle"])
                assert units == sales["earned_units"], (row["policy"], row["case"], snap["cycle"], rel["release_id"], units, sales)
                assert net(units) == sales["entitlement_cents"]
                assert sales["settled_cents"] <= sales["entitlement_cents"]
                checked += 1
        assert old.snapshots(row)[-1][1]["cash_cents"] == row["sidestreet_2"]["after_dismiss"]["cash_cents"]
        store = row["store_purchase"]
        if store["success"]:
            assert store["after"]["cycle"] == store["before"]["cycle"] + 1
    return {"runs": len(rows), "sales_snapshot_parity_checks": checked,
            "successful_one_cycle_stores": sum(r["store_purchase"]["success"] for r in rows)}


def scenario_delta_at(row: dict, cycle: int, awareness: tuple[int, int]) -> tuple[int, int]:
    settled = cycle - cycle % 2
    earned_delta = settled_delta = 0
    for idx, key in enumerate(("game_1", "game_2")):
        rel = row[key]
        original_earned = age_units(rel, rel["market_bp"], cycle)
        changed_earned = age_units(rel, rel["market_bp"], cycle, awareness[idx])
        original_settled = age_units(rel, rel["market_bp"], settled)
        changed_settled = age_units(rel, rel["market_bp"], settled, awareness[idx])
        earned_delta += net(changed_earned) - net(original_earned)
        settled_delta += net(changed_settled) - net(original_settled)
    return earned_delta, settled_delta


SCENARIOS = {
    "no_trait": {},
    "cash_conversion_4_points": {"cash_bonus": 20000},
    "student_loan_1p_5": {"cash_bonus": 5000, "loan_due": 500},
    "student_loan_2p_5": {"cash_bonus": 10000, "loan_due": 500},
    "student_loan_1p_10": {"cash_bonus": 5000, "loan_due": 1000},
    "student_loan_2p_10": {"cash_bonus": 10000, "loan_due": 1000},
    "student_loan_1p_15": {"cash_bonus": 5000, "loan_due": 1500},
    "student_loan_2p_15": {"cash_bonus": 10000, "loan_due": 1500},
    "unknown_2p_minus15_both": {"cash_bonus": 10000, "unknown": (15, 15)},
    "unknown_2p_minus10_first": {"cash_bonus": 10000, "unknown": (10, 0)},
    "resourceful_1p_100": {"cash_bonus": -5000, "resourceful": 10000},
    "lean_2p_10cap100": {"cash_bonus": -10000, "lean_pct": 10, "lean_cap": 10000},
    "buzz_1p_plus10": {"cash_bonus": -5000, "buzz": 10},
    "family_300": {"family": 30000},
    "cult_200": {"cult": 200},
    "publisher_15pct": {"publisher_pct": 15},
    "specialty_plus10": {"specialty": 10},
    "family_300_plus_loan_2p_10": {"family": 30000, "cash_bonus": 10000, "loan_due": 1000},
    "cult_200_plus_buzz": {"cult": 200, "cash_bonus": -5000, "buzz": 10},
}


def evaluate(row: dict, spec: dict) -> dict:
    awareness = tuple(spec.get("buzz", 0) + spec.get("specialty", 0)
                      + backgrounds.fan_awareness(spec.get("cult", 0))
                      - spec.get("unknown", (0, 0))[i] for i in (0, 1))
    store = row["store_purchase"]
    store_cycle = store["after"]["cycle"] if store["success"] else 10**9
    resourceful = min(spec.get("resourceful", 0), store["offer"]["price_cents"]) if store["success"] else 0
    iron = row["ironclad"]
    publisher_bonus = iron["completion"]["payout_cents"] * spec.get("publisher_pct", 0) // 100
    publisher_cycle = iron["after_dismiss"]["cycle"]
    first = None
    minimum = 10**18
    final = None
    earned_delta = 0
    settled_delta = 0
    for stage, snap in old.snapshots(row):
        cycle = snap["cycle"]
        earned_delta, settled_delta = scenario_delta_at(row, cycle, awareness)
        cash = (snap["cash_cents"] + spec.get("cash_bonus", 0) + spec.get("family", 0)
                + settled_delta - min(96, cycle // 2) * spec.get("loan_due", 0)
                - spec.get("bill_cents", 0) * (cycle // 2)
                - (spec.get("staff", 0) * 10000 + spec.get("courses", 0) * 2500)
                * max(0, cycle // 2 - row["game_1"]["cycle"] // 2)
                + (resourceful if cycle >= store_cycle else 0)
                + old.lean_savings(row, spec.get("lean_pct", 0), spec.get("lean_cap", 0), cycle)
                + (publisher_bonus if cycle >= publisher_cycle else 0))
        minimum = min(minimum, cash)
        if cash < 0 and first is None:
            first = {"cycle": cycle, "stage_diagnostic_only": stage, "shortfall_cents": -cash}
        final = {"cycle": cycle, "cash_cents": cash, "earned_delta_cents": earned_delta,
                 "settled_delta_cents": settled_delta}
    assert final is not None
    return {"first_infeasible": first, "minimum_cash_cents": minimum, "final": final,
            "awareness_deltas": awareness, "publisher_bonus_cents": publisher_bonus,
            "loan_paid_boundaries": min(96, final["cycle"] // 2),
            "game1_month1_units_delta": age_units(row["game_1"], row["game_1"]["market_bp"], row["game_1"]["cycle"] + 2, awareness[0]) - row["game_1"]["month_1_units"],
            "game2_month1_units_delta": age_units(row["game_2"], row["game_2"]["market_bp"], row["game_2"]["cycle"] + 2, awareness[1]) - row["game_2"]["month_1_units"]}


def campaign_probe(row: dict, key: str, age_month: int) -> dict:
    rel = row[key]
    cycle = rel["cycle"] + (age_month - 1) * 2
    organic_units = age_units(rel, rel["market_bp"], cycle + 2) - age_units(rel, rel["market_bp"], cycle)
    boosted_units = age_units(rel, rel["market_bp"], cycle + 2, 0, {age_month: 0}) - age_units(rel, rel["market_bp"], cycle)
    margin = (net(age_units(rel, rel["market_bp"], cycle + 2, 0, {age_month: 0}))
              - net(age_units(rel, rel["market_bp"], cycle + 2)) - 10000)
    return {"age_month": age_month, "organic_units": organic_units, "boosted_units": boosted_units,
            "incremental_units": boosted_units - organic_units, "net_margin_after_100_dollars_cents": margin}


def recorded_sales_snapshots(value) -> list[dict]:
    if isinstance(value, dict):
        found = [value] if isinstance(value.get("cycle"), int) and isinstance(value.get("sales"), list) else []
        for sub in value.values():
            found.extend(recorded_sales_snapshots(sub))
        return found
    if isinstance(value, list):
        return [snap for sub in value for snap in recorded_sales_snapshots(sub)]
    return []


def main() -> None:
    rows = load_rows()
    parity = live_parity(rows)
    raw = []
    summary = {"source_revision": "606f011d0bfdaca27dc662062ec6498a5942627a",
               "baseline_parity": parity, "sources": [str(p.relative_to(ROOT)) for p in SOURCE_FILES],
               "long_sources": [str(p.relative_to(ROOT)) for p in LONG_FILES],
               "scenarios": {}, "campaign_probe": {}, "loan_checkpoints": {}, "sensitivity": {}}
    long_rows = [json.loads(path.read_text(encoding="utf-8"))["rows"][0] for path in LONG_FILES]
    assert len(long_rows) == 3 and all(r["valid"] and len(r["long_run"]) == 4 for r in long_rows)
    summary["actual_long_continuation"] = {
        "count": len(long_rows),
        "release_age_checkpoint_coverage": {
            key: {str(month): sum(r["long_run"][-1]["after"]["cycle"] - r[key]["cycle"] >= month * 2 for r in long_rows)
                  for month in (6, 12, 24)} for key in ("game_1", "game_2")},
        "end_cycles": [r["long_run"][-1]["after"]["cycle"] for r in long_rows],
        "end_cash_cents": [r["long_run"][-1]["after"]["cash_cents"] for r in long_rows],
        "blockers": [r["blockers"] for r in long_rows]}
    exact_checkpoints = []
    for row in long_rows:
        for key in ("game_1", "game_2"):
            rel = row[key]
            for month in (6, 12, 24):
                cycle = rel["cycle"] + 2 * month
                if cycle > row["long_run"][-1]["after"]["cycle"]:
                    continue
                options = [sales for snap in recorded_sales_snapshots(row) if snap["cycle"] == cycle
                           for sales in snap["sales"] if sales["release_id"] == rel["release_id"]]
                assert options, (row["policy"], key, month, cycle)
                sales = max(options, key=lambda item: (item["earned_units"], item["settled_cents"]))
                exact_checkpoints.append({"policy": row["policy"], "release": key, "age_month": month,
                                          "cycle": cycle, "earned_units": sales["earned_units"],
                                          "entitlement_cents": sales["entitlement_cents"],
                                          "settled_cents": sales["settled_cents"]})
    summary["actual_long_continuation"]["exact_age_checkpoints"] = exact_checkpoints
    summary["store_cycles"] = [{"policy": r["policy"], "case": r["case"], "success": r["store_purchase"]["success"],
                                "quote_cents": r["store_purchase"]["offer"].get("price_cents", 0),
                                "cycle_delta": r["store_purchase"]["after"]["cycle"] - r["store_purchase"]["before"]["cycle"],
                                "cash_delta_cents": r["store_purchase"]["after"]["cash_cents"] - r["store_purchase"]["before"]["cash_cents"]}
                               for r in rows]
    for name, spec in SCENARIOS.items():
        outcomes = [evaluate(row, spec) for row in rows]
        for row, result in zip(rows, outcomes):
            raw.append({"scenario": name, "policy": row["policy"], "case": row["case"], "seed": row["seed"],
                        "review1": row["game_1"]["final_review"], "review2": row["game_2"]["final_review"],
                        "result": result})
        deltas = [result["final"]["cash_cents"] - row["sidestreet_2"]["after_dismiss"]["cash_cents"]
                  for row, result in zip(rows, outcomes)]
        summary["scenarios"][name] = {"n": len(rows), "first_infeasible_count": sum(x["first_infeasible"] is not None for x in outcomes),
                                      "paired_mean_cash_delta_cents": round(statistics.mean(deltas), 2),
                                      "paired_median_cash_delta_cents": statistics.median(deltas),
                                      "paired_positive_cash_count": sum(x > 0 for x in deltas),
                                      "median_game1_month1_units_delta": statistics.median(x["game1_month1_units_delta"] for x in outcomes),
                                      "median_game2_month1_units_delta": statistics.median(x["game2_month1_units_delta"] for x in outcomes),
                                      "first_infeasible_cycles": dict(Counter(str(x["first_infeasible"]["cycle"]) for x in outcomes if x["first_infeasible"]))}
    summary["hypothetical_expenses"] = {}
    for staff in (0, 1, 2):
        for loan in (0, 1000):
            spec = {"bill_cents": 7500, "staff": staff, "courses": 2 * staff,
                    "loan_due": loan, "cash_bonus": 10000 if loan else 0}
            outcomes = [evaluate(row, spec) for row in rows]
            summary["hypothetical_expenses"][f"staff{staff}_loan{loan}"] = {
                "n": len(rows), "first_infeasible_count": sum(x["first_infeasible"] is not None for x in outcomes),
                "median_cash_at_end_cents": statistics.median(x["final"]["cash_cents"] for x in outcomes),
                "first_infeasible_cycles": dict(Counter(str(x["first_infeasible"]["cycle"]) for x in outcomes if x["first_infeasible"]))}
    assert all(x["result"]["final"]["cash_cents"] == next(r for r in rows if r["policy"] == x["policy"] and r["case"] == x["case"])["sidestreet_2"]["after_dismiss"]["cash_cents"] for x in raw if x["scenario"] == BASELINE_SCENARIO)
    for age_month in (2, 6, 12, 24):
        values = [campaign_probe(row, "game_2", age_month) for row in rows]
        summary["campaign_probe"][str(age_month)] = {"n": len(values), "median_incremental_units": statistics.median(x["incremental_units"] for x in values),
                                                       "median_margin_cents": statistics.median(x["net_margin_after_100_dollars_cents"] for x in values),
                                                       "positive_margin_count": sum(x["net_margin_after_100_dollars_cents"] > 0 for x in values)}
    for payment in (500, 1000, 1500):
        for refund in (1, 2):
            bonus = refund * 5000
            summary["loan_checkpoints"][f"pay{payment}_refund{refund}"] = {str(month): bonus - payment * min(96, month) for month in (4, 12, 24, 96)}
    for review_tenths in (70, 91):
        values = []
        margins = {month: [] for month in (2, 6, 12, 24)}
        for row in rows:
            rel = dict(row["game_2"])
            rel["final_review"] = review_tenths / 10
            original = age_units(rel, rel["market_bp"], rel["cycle"] + 48)
            shifted = age_units(rel, rel["market_bp"], rel["cycle"] + 48, 10)
            values.append(net(shifted) - net(original))
            trial_row = dict(row)
            trial_row["game_2"] = rel
            for month in margins:
                margins[month].append(campaign_probe(trial_row, "game_2", month)["net_margin_after_100_dollars_cents"])
        summary["sensitivity"][f"synthetic_review_{review_tenths/10}_buzz10_month24_median_cents"] = statistics.median(values)
        summary["sensitivity"][f"synthetic_review_{review_tenths/10}_campaign_margin_median_cents"] = {
            str(month): statistics.median(items) for month, items in margins.items()}
    (OUT / "studio_trait_post_integration_recheck_v1_summary.json").write_text(json.dumps(summary, indent=2), encoding="utf-8")
    with gzip.open(OUT / "studio_trait_post_integration_recheck_v1_raw.json.gz", "wt", encoding="utf-8") as f:
        json.dump(raw, f)
    print(json.dumps({"parity": parity, "scenarios": len(SCENARIOS), "raw_rows": len(raw),
                      "summary": "design-logs/studio_trait_post_integration_recheck_v1_summary.json"}))


if __name__ == "__main__":
    main()
