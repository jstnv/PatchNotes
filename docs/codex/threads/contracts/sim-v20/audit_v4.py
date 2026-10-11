"""Read-only assertions for the declared SideStreet v4 bundle."""

import json
from pathlib import Path


HERE = Path(__file__).resolve().parent
BUNDLE = HERE / "study-v4-run-01"
CASES = BUNDLE / "cases"


def read(path: Path):
    return json.loads(path.read_text(encoding="utf-8"))


old_pair = read(HERE / "pair-v3-run-01" / "run-report.json")
new_pair = read(BUNDLE / "run-report.json")
comparison = read(HERE / "study-v4-comparison-01" / "comparison.json")
assert old_pair["results"][0]["ok"] and old_pair["results"][1]["ok"]
assert new_pair["git"]["head"] == old_pair["git"]["head"]
assert comparison["both_cases_completed"] is True
assert comparison["provenance"]["source_identity"] == "13980fdeb9efabaeb070c8dddddcd8137982e3e073aa43ab87f7fdd1a57c4c4f"
assert comparison["left"]["initial"]["cash_cents"] == comparison["right"]["initial"]["cash_cents"] == "168282"
assert comparison["provenance"]["initial_state"] == "1811386e9b18d0d5bdc09c035411b706c79c5ee7eeb5264907c98f864f1e7fe2"

outcomes = {}
for arm in ("take", "skip"):
    name = f"sports-1104-{arm}-v4"
    result = read(CASES / name / "result.json")
    trace = read(CASES / name / "telemetry.json")
    previous = read(HERE / "pair-v3-run-01" / "cases" / f"sports-1104-{arm}" / "result.json")
    replay = read(HERE / f"study-v4-{name}-replay-01" / "replay-report.json")
    checkpoint = read(CASES / name / "studio_checkpoint.json")
    run = checkpoint["studio_payload"]["run"]
    game3 = next(sample for sample in trace["samples"] if sample["release_count"] == 3)
    assert game3["state_digest"] == previous["final_state"]
    assert result["ok"] and result["final_release_count"] == 4 and result["source_identity"] == comparison["provenance"]["source_identity"]
    assert replay["ok"] and replay["telemetry_verified"] and replay["final_state"] == result["final_state"]
    assert len(replay["steps"]) == result["commands"]
    assert result["outcome"]["finance"]["total_overdue_cents"] == 0
    publishers = {item["value"]["publisher_id"]: item["value"] for item in run["publisher_offers"]}
    crown = publishers["crown_quill"]["state"]["result"]
    game3_sales = result["outcome"]["releases"][2]["sales"]
    assert game3_sales["total_earned_cycles"] >= 4 and game3_sales["settled_cents"] > 0
    outcomes[arm] = {
        "commands": result["commands"],
        "game3_cycle": game3["run_cycle"],
        "game4_cycle": result["final_run_cycle"],
        "final_cash_cents": result["outcome"]["cash_cents"],
        "final_credit": result["outcome"]["finance"]["credit"]["score"],
        "game3_settled_cents_at_same_age_18": game3_sales["settled_cents"],
        "game3_total_earned_cycles": game3_sales["total_earned_cycles"],
        "portfolio_settled_cents": sum(x["sales"]["settled_cents"] for x in result["outcome"]["releases"]),
        "crown_payout_cents": int(crown["payout"]),
        "crown_promotion": int(crown["promotion"]),
        "sidestreet_result_count": len(run["sidestreet_results"]),
        "starwave_offer_present": "starwave" in publishers,
        "replay_verified": True,
    }

assert outcomes["take"]["game3_cycle"] == 54 and outcomes["skip"]["game3_cycle"] == 52
assert outcomes["take"]["game4_cycle"] == 72 and outcomes["skip"]["game4_cycle"] == 70
assert outcomes["take"]["sidestreet_result_count"] == 1 and outcomes["skip"]["sidestreet_result_count"] == 0
assert outcomes["take"]["starwave_offer_present"] and not outcomes["skip"]["starwave_offer_present"]
assert outcomes["take"]["game3_total_earned_cycles"] == outcomes["skip"]["game3_total_earned_cycles"] == 18

shared = {row["run_cycle"]: row for row in comparison["matched_calendar"]}
assert shared[60]["delta_right_minus_left"]["cash_cents"] == "25625"
assert shared[70]["delta_right_minus_left"]["cash_cents"] == "41850"
assert outcomes["take"]["game3_settled_cents_at_same_age_18"] - outcomes["skip"]["game3_settled_cents_at_same_age_18"] == -12587

adventure = read(CASES / "adventure-1104-prefix-v4" / "result.json")
adventure_replay = read(HERE / "study-v4-adventure-1104-prefix-v4-replay-01" / "replay-report.json")
assert adventure["ok"] and adventure["final_release_count"] == 2 and adventure_replay["ok"]
assert adventure_replay["final_state"] == adventure["final_state"]
assert adventure["outcome"]["releases"][1]["metadata"]["review"]["final_review"] == 6.6

sports = read(CASES / "sports-4417-prefix-v4" / "result.json")
reduction = read(HERE / "study-v4-4417-reduction-02" / "reduction-run.json")
assert sports["status"] == "rejected_policy_action" and sports["error"] == "The run calendar cannot advance safely."
assert sports["outcome"]["cash_cents"] == 0 and sports["outcome"]["finance"]["total_overdue_cents"] == 8000
assert reduction["ok"] and reduction["fresh_process_confirmation"]

report = {
    "ok": True,
    "mechanics_identity": comparison["provenance"]["source_identity"],
    "pair": outcomes,
    "matched_cash_delta_take_minus_skip_cents": {str(cycle): int(shared[cycle]["delta_right_minus_left"]["cash_cents"]) for cycle in (52, 56, 58, 60, 70)},
    "adventure_1104": {"status": adventure["status"], "game2_review": 6.6, "qualifies_for_crown": False, "replay_verified": True},
    "sports_4417": {"status": sports["status"], "cash_cents": 0, "overdue_cents": 8000, "reduced_commands": reduction["reduction"]["reduced_commands"], "fresh_process_confirmation": True},
}
destination = HERE / "audit-v4.json"
assert not destination.exists(), f"Refusing to overwrite {destination}"
destination.write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
print(json.dumps({"ok": True, "output": str(destination), "pair_replays": 2, "access_replays": 1, "reduced_rejection": True}))
