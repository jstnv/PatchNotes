"""Audit and compress the live-scene SideStreet acceptance traces.

Run from the Godot project root with bundled Python:
  python analysis/sidestreet_acceptance_stress_analysis_v1.py
"""

from __future__ import annotations

import gzip
import json
from pathlib import Path
from statistics import median


ROOT = Path("design-logs")
POLICIES = ("cautious", "ordinary", "optimizer")


def percentile(values: list[float], fraction: float) -> float:
    ordered = sorted(values)
    position = (len(ordered) - 1) * fraction
    lower = int(position)
    upper = min(lower + 1, len(ordered) - 1)
    return ordered[lower] + (ordered[upper] - ordered[lower]) * (position - lower)


def analyze() -> dict:
    result: dict = {"policies": {}, "totals": {"first_games": 0, "two_game_runs": 0, "failures": 0}}
    for policy in POLICIES:
        source = ROOT / f"sidestreet_acceptance_stress_v1_{policy}_final.json"
        data = json.loads(source.read_text(encoding="utf-8"))
        rows = data["rows"]
        two = [row for row in rows if row.get("game_2", {}).get("released")]
        assert len(rows) == 110 and len(two) == 30 and data["failures"] == 0
        reviews = [float(row["game_1"]["final_review"]) for row in rows]
        contracts = [row["ironclad"] for row in rows]
        sides = [row["sidestreet_1"] for row in rows]
        for row in rows:
            assert row["valid"] and row["starter_summary"]["scope"] == row["starter_target"]
            assert row["starter_summary"]["spent_cents"] <= 400000
            assert row["ironclad"]["completion"]["payout_cents"] == row["ironclad"]["independent_payout_cents"]
            assert row["sidestreet_1"]["completion"]["payout_cents"] == row["sidestreet_1"]["independent_payout_cents"]
            for name in ("ironclad", "sidestreet_1", "sidestreet_2"):
                if name in row:
                    assert all(hand["cash_parity"] and hand["success"] for hand in row[name]["hands"])
                    assert row[name]["dismiss_passive"]
            if row in two:
                assert row["completed_contract_count"] == 3
                assert row["publishers_after_three_contracts"]["starwave"]["unlocked"]
                assert len(row["sidestreet_history"]) == 2
                assert len({row["sidestreet_1"]["offer_id"], row["sidestreet_2"]["offer_id"]}) == 2
                assert row["sidestreet_2"]["completion"]["payout_cents"] == row["sidestreet_2"]["independent_payout_cents"]
        summary = {
            "first_games": len(rows),
            "two_game_runs": len(two),
            "deferred_ironclad_two_game_runs": sum("deferred_ironclad" not in row.get("errors", []) and row["case"] % 2 == 1 for row in two),
            "legal_scope_20_23": sum(row["starter_target"] >= 20 for row in rows),
            "below_20_opt_in": sum(row["starter_target"] < 20 for row in rows),
            "review_p10": percentile(reviews, .1),
            "review_median": median(reviews),
            "review_p90": percentile(reviews, .9),
            "review_below_5_share": sum(v < 5 for v in reviews) / len(reviews),
            "review_at_least_7_share": sum(v >= 7 for v in reviews) / len(reviews),
            "ironclad_payout_median_cents": median(c["completion"]["payout_cents"] for c in contracts),
            "sidestreet_1_payout_median_cents": median(c["completion"]["payout_cents"] for c in sides),
            "sidestreet_2_payout_median_cents": median(row["sidestreet_2"]["completion"]["payout_cents"] for row in two),
            "cash_before_game_2_median_cents": median(row["cash_before_game_2_cents"] for row in two),
            "starwave_unlocks": sum(row["publishers_after_three_contracts"]["starwave"]["unlocked"] for row in two),
            "cash_parity_failures": 0,
            "exact_payout_failures": 0,
        }
        result["policies"][policy] = summary
        result["totals"]["first_games"] += len(rows)
        result["totals"]["two_game_runs"] += len(two)
        compressed = source.with_suffix(".json.gz")
        with gzip.open(compressed, "wt", encoding="utf-8", compresslevel=9) as output:
            json.dump(data, output, separators=(",", ":"))
        print(f"{policy}: {summary} compressed={compressed}")
    result["long_run"] = {}
    for label, source in (
        ("cautious_19_scope", ROOT / "sidestreet_acceptance_stress_v1_cautious_cheapest_batch_100.json"),
        ("ordinary_20_23_scope", ROOT / "sidestreet_acceptance_stress_v1_ordinary_normal_batch.json"),
    ):
        data = json.loads(source.read_text(encoding="utf-8"))
        rows = data["rows"]
        assert len(rows) == 5 and data["failures"] == 0
        margins = [item["marginal_cash_cents"] for row in rows for item in row["long_run"]]
        cycles = [item["marginal_cycles"] for row in rows for item in row["long_run"]]
        assert len(margins) == 20
        result["long_run"][label] = {
            "six_release_runs": len(rows), "game_3_to_6_releases": len(margins),
            "positive_marginal_cash": sum(value > 0 for value in margins),
            "median_marginal_cash_cents": median(margins),
            "minimum_marginal_cash_cents": min(margins),
            "maximum_marginal_cash_cents": max(margins),
            "median_marginal_cycles": median(cycles),
            "release_or_contract_blockers": sum(any("game_" in item for item in row["blockers"]) for row in rows),
        }
        with gzip.open(source.with_suffix(".json.gz"), "wt", encoding="utf-8", compresslevel=9) as output:
            json.dump(data, output, separators=(",", ":"))
    output = ROOT / "sidestreet_acceptance_stress_v1_summary.json"
    output.write_text(json.dumps(result, indent=2) + "\n", encoding="utf-8")
    return result


if __name__ == "__main__":
    analyze()
