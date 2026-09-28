"""Audit fixed-input live Godot traces for the employee design follow-up.

This reads the SideStreet scene-control batch; no employee effect is applied.
It tests current transaction arithmetic, not Python/Godot PRNG parity.
"""

from __future__ import annotations

import gzip
import json
import statistics
from collections import Counter
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
LOGS = ROOT / "design-logs"
PRIMITIVE_IDS = {card["id"] for card in json.loads((ROOT / "data" / "card_ledger.json").read_text(encoding="utf-8"))}
LEDGER = {card["id"]: card for ledger_name in ("card_ledger.json", "feature_store_ledger.json")
          for card in json.loads((ROOT / "data" / ledger_name).read_text(encoding="utf-8"))}


def sales_delta(before: list[dict], after: list[dict]) -> int:
    old = {record["release_id"]: record["settled_cents"] for record in before}
    return sum(record["settled_cents"] - old.get(record["release_id"], 0) for record in after)


def card_cost(ids: list[str]) -> int:
    total = 0
    for identifier in ids:
        card = LEDGER[identifier]
        if card["type"] == "feature" and identifier in PRIMITIVE_IDS:
            total += 1000 * (card["primary_value"] + card["secondary_value"] + 2 * card["scope"])
    return total


def audit() -> dict:
    by_policy = {}
    for policy in ("cautious", "ordinary", "optimizer"):
        path = LOGS / f"sidestreet_acceptance_stress_v1_{policy}_final.json.gz"
        by_policy[policy] = json.load(gzip.open(path, "rt", encoding="utf-8"))["rows"]
    groups = {
        "legal_first_game": [row for policy in by_policy for row in by_policy[policy][:10]],
        "below_20_opt_in": [row for policy in by_policy for row in by_policy[policy][100:105]],
        "expanded_game_2": [row for policy in by_policy for row in by_policy[policy][:5]],
    }
    result = {"sample_counts": {name: len(rows) for name, rows in groups.items()},
              "fixed_input_checks": Counter(), "groups": {}}
    for name, rows in groups.items():
        assert len(rows) == (30 if name == "legal_first_game" else 15)
        releases = [row["game_2"] if name == "expanded_game_2" else row["game_1"] for row in rows]
        release_cycles = [row["after_release_2"]["cycle"] if name == "expanded_game_2" else row["after_release_1"]["cycle"] for row in rows]
        for row, release in zip(rows, releases):
            assert row["valid"] and release["released"]
            assert release["projected_gross_cents"] == release["month_1_units"] * 999
            assert release["projected_net_cents"] == release["projected_gross_cents"] * 70 // 100
            assert release["final_review"] == round(release["final_review"], 1)
            result["fixed_input_checks"]["release_sales_and_review"] += 1
            for action in row["actions"]:
                if action.get("phase") not in ("design", "alpha", "beta"):
                    continue
                if name == "expanded_game_2" and str(action.get("game")) != "2":
                    continue
                if name != "expanded_game_2" and str(action.get("game")) != "1":
                    continue
                assert len(action["draw"]) == 7 and len(action["selected"]) == 4
                before, after = action["before"], action["after"]
                assert after["cycle"] == before["cycle"] + 1
                expected_cost = card_cost(action["selected"]) if action["phase"] in ("design", "alpha") else 0
                assert action.get("cost_cents", 0) == expected_cost
                beta_rival_cash = action["selected"].count("playtest_rival_games") * 100000 if action["phase"] == "beta" else 0
                assert after["cash_cents"] - before["cash_cents"] == -expected_cost + beta_rival_cash + sales_delta(before["sales"], after["sales"]), (name, row["policy"], row["case"], action["phase"], after["cash_cents"] - before["cash_cents"], expected_cost, beta_rival_cash, sales_delta(before["sales"], after["sales"]))
                result["fixed_input_checks"]["seven_draw_four_play_exact_cost_and_cash"] += 1
            for label, budget, upfront in (("ironclad", 200000, 40000), ("sidestreet_1", 120000, 0)):
                contract = row[label]
                numerator = contract["completion"]["numerator"]
                assert contract["completion"]["payout_cents"] == upfront + budget * numerator // 96
                assert all(hand["cash_parity"] for hand in contract["hands"])
                result["fixed_input_checks"]["contract_exact_payout"] += 1
            if name == "expanded_game_2":
                contract = row["sidestreet_2"]
                assert contract["completion"]["payout_cents"] == 120000 * contract["completion"]["numerator"] // 96
                result["fixed_input_checks"]["second_release_offer"] += 1
        result["groups"][name] = {
            "release_cycle_parities": sorted({cycle % 2 for cycle in release_cycles}),
            "qa_mode_counts": dict(Counter(row["beta_mode"] for row in rows)),
            "policies": dict(Counter(row["policy"] for row in rows)),
            "review_min": min(release["final_review"] for release in releases),
            "review_median": statistics.median(release["final_review"] for release in releases),
            "review_max": max(release["final_review"] for release in releases),
            "awareness_median": statistics.median(release["awareness"] for release in releases),
            "month_1_units_median": statistics.median(release["month_1_units"] for release in releases),
            "cash_at_release_median_cents": statistics.median(release["cash_cents"] for release in releases),
        }
    assert all(row["store_purchase"]["before"]["cycle"] == row["store_purchase"]["after"]["cycle"] for row in groups["legal_first_game"])
    result["fixed_input_checks"]["later_store_zero_cycle"] = 30
    result["fixed_input_checks"] = dict(result["fixed_input_checks"])
    result["limits"] = [
        "No employees, course raises, bills, payroll, or proposed rewards are in these live traces.",
        "The archived employee Python paths do not share these actual draws and commits; this is fixed-input arithmetic parity, not PRNG-identical model parity.",
        "The sampled policy does not reproduce the player's above-9 later-game Review; do not infer a human ceiling.",
        "The current later Store node costs zero cycles; the queued design rule says one cycle.",
    ]
    destination = LOGS / "employee_followup_live_anchor_v2_summary.json"
    destination.write_text(json.dumps(result, indent=2) + "\n", encoding="utf-8")
    print(json.dumps(result, indent=2))
    return result


if __name__ == "__main__":
    audit()
