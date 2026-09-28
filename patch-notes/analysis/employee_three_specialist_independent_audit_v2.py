"""Independent aggregation of the archived 600-path employee trial raw rows.

The raw audit below does not import the original generator. Timing sensitivity
explicitly reuses its finance model and is labeled separately in the output.
"""

from __future__ import annotations

import gzip
import hashlib
import json
import statistics
import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
LOGS = ROOT / "design-logs"
RAW = LOGS / "employee_three_specialist_trial_v1_raw.json.gz"
SUMMARY = LOGS / "employee_three_specialist_trial_v1_summary.json"
LEDGER = ROOT / "data" / "card_ledger.json"
ARMS = ("none", "production", "qa", "contracts", "combined")


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as source:
        for chunk in iter(lambda: source.read(65536), b""):
            digest.update(chunk)
    return digest.hexdigest()


def production_savings(events: list[dict], ledger: dict[str, dict]) -> tuple[bool, int]:
    trigger = None
    permanent = temporary = 0
    for event in events:
        cards = [ledger[identifier] for identifier in event["cards"]]
        pass_stats = {card["primary_stat"] for card in cards if card["type"] == "pass"}
        costs = []
        if event["phase"] == "design":
            for card in cards:
                if card["type"] != "feature":
                    continue
                if pass_stats.intersection((card["primary_stat"], card.get("secondary_stat", ""))):
                    costs.append(10 * (card["primary_value"] + card["secondary_value"] + 2 * card["scope"]))
        if trigger is None and costs:
            trigger = event["cycle"]
            permanent = min(60, max(costs) * 50 // 100)
        elif trigger is not None and event["cycle"] - trigger <= 6:
            temporary += min(80 - temporary, event["cost_dollars"] * 20 // 100)
    return trigger is not None, permanent + temporary


def percentage(count: int, total: int) -> float:
    return round(100 * count / total, 2)


def audit() -> dict:
    rows = json.load(gzip.open(RAW, "rt", encoding="utf-8"))
    archived = json.loads(SUMMARY.read_text(encoding="utf-8"))
    ledger = {card["id"]: card for card in json.loads(LEDGER.read_text(encoding="utf-8"))}
    assert len(rows) == archived["n"] == 600
    cohorts = {name: [row for row in rows if row["item"]["cohort"] == name] for name in ("legal", "below_20", "expanded")}
    assert all(len(group) == 200 for group in cohorts.values())
    legal = cohorts["legal"]
    recomputed = [production_savings(row["item"]["game1"]["events"], ledger) for row in legal]
    assert all(found == row["standard"]["production"]["production1"]["trained"] and
               savings == row["standard"]["production"]["production1"]["savings_dollars"]
               for (found, savings), row in zip(recomputed, legal))
    monthly_arithmetic_checks = 0
    payout_checks = 0
    for row in rows:
        for scenario in row["finance"].values():
            for boundary in scenario["boundaries"]:
                assert boundary["after_cents"] == boundary["before_cents"] + boundary["sales_cents"] - boundary["bill_cents"] - boundary["payroll_cents"] - boundary["extra_cents"]
                monthly_arithmetic_checks += 1
            numerator = row["standard"]["none"]["contract"]["numerator"]
            assert scenario["upfront_cents"] == 40000
            assert scenario["remainder_cents"] == 200000 * numerator // 96
            assert scenario["total_reward_cents"] == scenario["upfront_cents"] + scenario["remainder_cents"]
            payout_checks += 1
    production_opportunities = sum(found for found, _ in recomputed)
    production_savings_mean = statistics.mean(savings for _, savings in recomputed)
    qa_challenges = sum(row["standard"]["qa"]["qa1"]["award_hand"] is not None for row in legal)
    qa_extra_fixes = sum(row["standard"]["qa"]["qa1"]["extra_fixes"] for row in legal)
    qa_extra_found = sum(row["standard"]["qa"]["qa1"]["extra_found"] for row in legal)
    qa_remaining_bug_delta = statistics.mean(row["standard"]["qa"]["qa1"]["remaining_bugs"] - row["standard"]["none"]["qa1"]["remaining_bugs"] for row in legal)
    qa_review_delta = statistics.mean(row["standard"]["qa"]["review1"] - row["standard"]["none"]["review1"] for row in legal)
    ordinary_contract_opportunities = sum(row["standard"]["contracts"]["contract"]["first_mixed"] and row["standard"]["contracts"]["contract"]["used_redraws"][0] >= 2 for row in legal)
    deliberate_contract_opportunities = sum(row["deliberate_contract"]["2"]["contract"]["first_mixed"] and row["deliberate_contract"]["2"]["contract"]["used_redraws"][0] >= 2 for row in legal)
    deliberate_payout_delta = statistics.mean(row["deliberate_contract"]["2"]["contract"]["total_payout_cents"] - row["deliberate_contract"]["0"]["contract"]["total_payout_cents"] for row in legal)
    shortfalls = {}
    for arm in ARMS:
        paths = [row["finance"][f"{arm}|courses2|node1"] for row in legal]
        assert all((path["minimum_cents"] < 0) == (path["first_shortfall"] is not None) for path in paths)
        shortfalls[arm] = percentage(sum(path["minimum_cents"] < 0 for path in paths), len(paths))
        assert shortfalls[arm] == archived["summary"][f"legal|{arm}"]["finance_courses2_node1"]["shortfall_pct"]
    assert production_opportunities == 121 and production_savings_mean == 64.06
    assert qa_challenges == 81 and qa_extra_fixes == 15 and qa_extra_found == 0
    assert ordinary_contract_opportunities == 0 and deliberate_contract_opportunities == 25

    # This is a paired finance-model sensitivity, not an independent Godot result.
    sys.path.insert(0, str(ROOT / "analysis"))
    import ironclad_guarantee_cashflow_v1 as finance

    timing = {}
    for arm in ARMS:
        staff = 0 if arm == "none" else 3 if arm == "combined" else 1
        next_bill = [finance.run_path(row["standard"][arm]["row"], 40000, staff, 2, True,
                                      studio_hire_cycle=False, raise_boundary="next") for row in legal]
        live_store_zero_cycle = [finance.run_path(row["standard"][arm]["row"], 40000, staff, 2, True,
                                                  studio_hire_cycle=False, store_cycle=0) for row in legal]
        timing[arm] = {"archived_same_bill_one_cycle_store_shortfall_pct": shortfalls[arm],
                       "next_bill_raise_one_cycle_store_shortfall_pct": percentage(sum(path["minimum_cents"] < 0 for path in next_bill), 200),
                       "same_bill_zero_cycle_store_shortfall_pct": percentage(sum(path["minimum_cents"] < 0 for path in live_store_zero_cycle), 200)}
    result = {
        "status": "independent raw aggregation; finance timing sensitivity reuses archived model",
        "cohort_counts": {name: len(group) for name, group in cohorts.items()},
        "source_sha256": {path.name: sha256(path) for path in (RAW, SUMMARY, LEDGER)},
        "production_legal_opportunities": production_opportunities,
        "production_legal_savings_mean_dollars": production_savings_mean,
        "qa_legal_challenges": qa_challenges,
        "qa_legal_extra_fixes": qa_extra_fixes,
        "qa_legal_extra_found": qa_extra_found,
        "qa_legal_remaining_bug_delta_mean": qa_remaining_bug_delta,
        "qa_legal_review_delta_mean": qa_review_delta,
        "contract_ordinary_legal_opportunities": ordinary_contract_opportunities,
        "contract_deliberate_legal_opportunities": deliberate_contract_opportunities,
        "contract_deliberate_payout_delta_mean_cents": deliberate_payout_delta,
        "optional_node_two_course_shortfall_pct": shortfalls,
        "checked_monthly_boundaries": monthly_arithmetic_checks,
        "checked_ironclad_payouts": payout_checks,
        "timing_sensitivity_model_only": timing,
    }
    destination = LOGS / "employee_three_specialist_independent_audit_v2_summary.json"
    destination.write_text(json.dumps(result, indent=2) + "\n", encoding="utf-8")
    print(json.dumps(result, indent=2))
    return result


if __name__ == "__main__":
    audit()
