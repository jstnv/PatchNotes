"""Read-only exact checks for the new-source Sports/1106 SideStreet pair."""

import json
from pathlib import Path


HERE = Path(__file__).resolve().parent
BUNDLE = HERE / "pair-v6-run-01"


def read(path):
    return json.loads(path.read_text(encoding="utf-8"))


pair_input = read(HERE / "pair-v6.json")
comparison = read(HERE / "pair-v6-comparison-01" / "comparison.json")
prefix = read(HERE / "prefix-v5-run-01" / "cases" / "sports-1106-prefix-v5" / "result.json")
prefix_replay = read(HERE / "prefix-v5-1106-replay-01" / "replay-report.json")
assert pair_input["cases"][0]["initial"] == pair_input["cases"][1]["initial"]
assert prefix["ok"] and prefix_replay["ok"] and prefix_replay["final_state"] == prefix["final_state"]
assert comparison["both_cases_completed"] and comparison["provenance"]["initial_state"] == prefix["final_state"]
source = "62cfd4f1686a6cc6302616d98aab421f2db511971fc5655cf5b6d9e743f612c4"
assert comparison["provenance"]["source_identity"] == source

arms = {}
for arm in ("take", "skip"):
    result = read(BUNDLE / "cases" / f"sports-1106-{arm}-v6" / "result.json")
    checkpoint = read(BUNDLE / "cases" / f"sports-1106-{arm}-v6" / "studio_checkpoint.json")
    replay = read(HERE / f"pair-v6-{arm}-replay-01" / "replay-report.json")
    assert result["ok"] and result["source_identity"] == source and result["final_release_count"] == 4
    assert replay["ok"] and replay["telemetry_verified"] and replay["final_state"] == result["final_state"] and len(replay["steps"]) == result["commands"]
    assert result["outcome"]["finance"]["total_overdue_cents"] == 0
    run = checkpoint["studio_payload"]["run"]
    publishers = {x["value"]["publisher_id"]: x["value"] for x in run["publisher_offers"]}
    crown = publishers["crown_quill"]["state"]["result"]
    g3 = result["outcome"]["releases"][2]
    g4 = result["outcome"]["releases"][3]
    arms[arm] = {
        "commands": result["commands"],
        "game3_cycle": g3["metadata"]["release_cycle"],
        "game4_cycle": g4["metadata"]["release_cycle"],
        "game3_review": g3["metadata"]["review"]["final_review"],
        "game3_sales_settled_cents_at_age_18": g3["sales"]["settled_cents"],
        "game3_age_cycles": g3["sales"]["total_earned_cycles"],
        "portfolio_sales_settled_cents": sum(x["sales"]["settled_cents"] for x in result["outcome"]["releases"]),
        "crown_total_receipt_cents": int(crown["payout"]),
        "crown_promotion": int(crown["promotion"]),
        "sidestreet_result_count": len(run["sidestreet_results"]),
        "starwave_offer_present": "starwave" in publishers,
        "endpoint_cash_cents": result["outcome"]["cash_cents"],
        "endpoint_credit": result["outcome"]["finance"]["credit"]["score"],
        "replay_verified": True,
    }

assert arms["take"]["game3_cycle"] == 54 and arms["skip"]["game3_cycle"] == 52
assert arms["take"]["game4_cycle"] == 72 and arms["skip"]["game4_cycle"] == 70
assert arms["take"]["game3_review"] == arms["skip"]["game3_review"] == 7.7
assert arms["take"]["game3_age_cycles"] == arms["skip"]["game3_age_cycles"] == 18
assert arms["take"]["game3_sales_settled_cents_at_age_18"] == arms["skip"]["game3_sales_settled_cents_at_age_18"]
assert arms["take"]["crown_total_receipt_cents"] == arms["skip"]["crown_total_receipt_cents"] == 192000
assert arms["take"]["crown_promotion"] == arms["skip"]["crown_promotion"] == 12
assert arms["take"]["sidestreet_result_count"] == 1 and arms["skip"]["sidestreet_result_count"] == 0
assert arms["take"]["starwave_offer_present"] and not arms["skip"]["starwave_offer_present"]

calendar = {row["run_cycle"]: row for row in comparison["matched_calendar"]}
assert calendar[60]["delta_right_minus_left"]["cash_cents"] == "70598"
assert calendar[70]["delta_right_minus_left"]["cash_cents"] == "99214"

report = {"ok": True, "mechanics_identity": source, "prefix_state": prefix["final_state"], "arms": arms, "matched_cash_delta_take_minus_skip_cents": {str(c): int(calendar[c]["delta_right_minus_left"]["cash_cents"]) for c in (52, 56, 58, 60, 70)}, "prefix_replay_verified": True}
output = HERE / "audit-v6.json"
assert not output.exists(), f"Refusing to overwrite {output}"
output.write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
print(json.dumps({"ok": True, "output": str(output), "pair_replays": 2, "prefix_replay": 1}))
