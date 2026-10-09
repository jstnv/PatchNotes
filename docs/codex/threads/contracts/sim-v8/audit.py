"""Audit the predeclared Crown→Neon Game-5 continuation."""

import hashlib
import json
from pathlib import Path
import zipfile

HERE = Path(__file__).resolve().parent
MANIFEST = json.loads((HERE / "source-manifest.json").read_text(encoding="utf-8"))
COPY = Path(MANIFEST["analysis_copy"])
COHORT = "crown-lease-chain"
MODES = ("chain", "crown_only", "crown_cash_only", "no_crown")
NEON = "neon_circuit"
CROWN = "crown_quill"
STARWAVE = "starwave"


def digest(value):
    return hashlib.sha256(value).hexdigest()


def load_trace():
    path = HERE / f"{COHORT}.json"
    if path.is_file():
        return json.loads(path.read_text(encoding="utf-8"))
    with zipfile.ZipFile(HERE / "native-traces.zip") as archive:
        return json.loads(archive.read(f"{COHORT}.json"))


def contract_action(arm, publisher):
    found = [action for action in arm["actions"] if publisher in str(action.get("offer_id", ""))]
    return found[0] if len(found) == 1 else None


def game_trace(arm, number):
    keys = ("phase", "game", "draw", "final_draw", "selected", "redraws", "rolls", "priorities")
    return [{key: action[key] for key in keys if key in action}
            for action in arm["actions"] if action.get("game") == number]


def endpoint(arm, name):
    snap = arm[name]
    finance = snap["state"]["finance_report"]
    actions = snap["state"]["finance"]["actions"]
    return {
        "cycle": snap["cycle"],
        "cash_cents": snap["cash_cents"],
        "portfolio_settled_cents": sum(int(row["settled_cents"]) for row in snap["state"]["sales"]),
        "game3_settled_cents": snap["game3_sales"]["settled_cents"],
        "game4_settled_cents": snap["game4_sales"]["settled_cents"],
        "game5_settled_cents": snap["game5_sales"]["settled_cents"],
        "total_overdue_cents": finance["total_overdue_cents"],
        "unpaid_rent_cents": finance["unpaid_rent_cents"],
        "credit_score": finance["credit"]["score"],
        "project_cycle": snap["state"]["project_cycle"],
        "financially_blocked": finance["financially_blocked"],
        "bank_loans": len(finance["bank_loans"]),
        "outstanding_expenses": len(finance["outstanding_expenses"]),
        "monthly_rent_cents": finance["monthly_rent_cents"],
        "monthly_payroll_cents": finance["monthly_payroll_cents"],
        "feature_play_cents": -sum(int(action["direct_delta"]) for action in actions if action["kind"] == "feature_play"),
        "publisher_receipts_cents": sum(int(action["direct_delta"]) for action in actions if action["kind"] == "publisher_receipt"),
        "completed_contracts": snap["completed_contracts"],
        "unlocked": snap["unlocked"],
        "pending_offers": snap["pending_offers"],
    }


def main():
    checks = {
        "copy_hashes_unchanged": (all(digest((COPY / rel).read_bytes()) == expected for rel, expected in MANIFEST["files"].items()) if COPY.exists() else None),
        "analysis_script_matches_manifest": digest((HERE / "crown_neon_game5_v8.gd").read_bytes()) == MANIFEST["analysis_script_sha256"],
    }
    overlay = HERE / "dirty-source-overlay.zip"
    if overlay.is_file():
        with zipfile.ZipFile(overlay) as archive:
            names = [line[3:].replace("\\", "/")[len("patch-notes/"):] for line in MANIFEST["source_status_at_copy"]]
            checks["dirty_overlay_matches_manifest"] = (
                archive.testzip() is None and sorted(archive.namelist()) == sorted(names)
                and all(digest(archive.read(name)) == MANIFEST["files"][name] for name in names)
            )
    data = load_trace()
    arms = {arm["mode"]: arm for arm in data["arms"]}
    chain, crown, cash, none = (arms[name] for name in MODES)
    first_neon = next(i for i, action in enumerate(chain["actions"]) if NEON in str(action.get("offer_id", "")))
    crown_results = [contract_action(arm, CROWN) for arm in (chain, crown, cash)]
    neon_action = contract_action(chain, NEON)
    G = chain["game5_launch"]["cycle"]
    checks[COHORT] = {
        "native_route_valid": data["valid"] and not data["errors"] and len(arms) == 4 and all(arm["success"] and not arm["errors"] for arm in arms.values()),
        "legal_crown_only_foundation": (data["foundation"]["releases"][-1]["final_review"] >= 7.0
                                        and data["foundation"]["releases"][-1]["awareness"] < 125
                                        and CROWN in data["foundation"]["unlocked_before"]
                                        and NEON not in data["foundation"]["unlocked_before"]),
        "identical_prebranch_state": all(arm["before"] == chain["before"] and arm["pending_before"] == chain["pending_before"] for arm in arms.values()),
        "crown_hands_and_results_identical": all(result is not None and result["hands"] == crown_results[0]["hands"] and result["result"] == crown_results[0]["result"] for result in crown_results),
        "crown_advance_and_full_cash": all(result["accepted"]["cash_cents"] - result["before"]["cash_cents"] == 15000 and result["result"]["cash"] == 192000 for result in crown_results),
        "same_chain_crown_prefix_through_game3": chain["actions"][:first_neon] == crown["actions"][:first_neon],
        "same_game3_launch_before_neon": chain["game3_launch"] == crown["game3_launch"] and chain["game3_promotion"] == crown["game3_promotion"] == 12,
        "neon_offer_pending_only_after_promoted_game3": (any(NEON in offer for offer in chain["pending_after_game3"])
                                                      and chain["pending_after_game3"] == crown["pending_after_game3"]
                                                      and not any(NEON in offer for offer in cash["pending_after_game3"] + none["pending_after_game3"])),
        "legal_neon_result": (neon_action is not None and chain["neon_offer_id"] == neon_action["offer_id"]
                              and neon_action["accepted"]["cash_cents"] == neon_action["before"]["cash_cents"]
                              and neon_action["result"]["cash"] == 145116 and neon_action["result"]["promotion"] == 18),
        "same_game4_cards_and_review": game_trace(chain, 4) == game_trace(crown, 4) and chain["game4_launch"]["final_review"] == crown["game4_launch"]["final_review"],
        "neon_promotion_on_game4_only": (chain["game4_promotion"] == 18 and all(arm["game4_promotion"] == 0 for arm in (crown, cash, none))
                                         and chain["game4_launch"]["awareness"] - crown["game4_launch"]["awareness"] == 18),
        "neon_costs_two_native_cycles": chain["game4_launch"]["cycle"] - crown["game4_launch"]["cycle"] == 2 and crown["game4_launch"]["cycle"] - none["game4_launch"]["cycle"] == 2,
        "game5_launched_legally": all(arm["game5_launch"]["cycle"] <= G and len(arm["releases"]) == 1 and arm["releases"][0] == arm["game5_launch"] and arm["game5_promotion"] == 0 for arm in arms.values()),
        "game5_two_cycle_strategy_delay": chain["game5_launch"]["cycle"] - crown["game5_launch"]["cycle"] == 2 and crown["game5_launch"]["cycle"] - none["game5_launch"]["cycle"] == 2,
        "matched_calendar_endpoints": all(arm["matched_G"]["cycle"] == G and arm["cycle_plus_2"]["cycle"] == G + 2 and arm["cycle_plus_4"]["cycle"] == G + 4 for arm in arms.values()),
        "two_actual_chain_game5_settlements": (chain["matched_G"]["game5_sales"]["settled_cents"] == 0
                                               and chain["cycle_plus_2"]["game5_sales"]["settled_cents"] > 0
                                               and chain["cycle_plus_4"]["game5_sales"]["settled_cents"] > chain["cycle_plus_2"]["game5_sales"]["settled_cents"]),
        "finance_valid_and_nonnegative": all(arm["ledger_valid"] and all(arm[key]["finance_valid"] and arm[key]["cash_cents"] >= 0 for key in ("matched_G", "cycle_plus_2", "cycle_plus_4")) for arm in arms.values()),
        "no_action_blockers": all(not arm["blockers"] and arm["game6_development_completed"] for arm in arms.values()),
        "project_access_and_two_cycle_gap": all(not arm["cycle_plus_4"]["state"]["finance_report"]["financially_blocked"] for arm in arms.values()) and chain["cycle_plus_4"]["state"]["project_cycle"] + 2 == crown["cycle_plus_4"]["state"]["project_cycle"],
        "no_overdue_at_endpoint": all(arm["cycle_plus_4"]["state"]["finance_report"]["total_overdue_cents"] == 0 for arm in arms.values()),
        "no_active_bank_or_outstanding_bill": all(not arm["cycle_plus_4"]["state"]["finance_report"]["bank_loans"] and not arm["cycle_plus_4"]["state"]["finance_report"]["outstanding_expenses"] for arm in arms.values()),
        "third_contract_unlocks_starwave_profile_only_in_chain": STARWAVE in chain["game4_unlocked"] and all(STARWAVE not in arm["game4_unlocked"] for arm in (crown, cash, none)),
    }
    results = {
        "foundation": {"release_cycles": [item["cycle"] for item in data["foundation"]["releases"]],
                       "last_review": data["foundation"]["releases"][-1]["final_review"],
                       "last_awareness": data["foundation"]["releases"][-1]["awareness"],
                       "cash_cents_before": data["foundation"]["pre_target"]["cash_cents"],
                       "monthly_rent_cents": data["foundation"]["initial"]["finance_report"]["monthly_rent_cents"],
                       "loan_quote": data["foundation"].get("loan_quote"), "hire": data["foundation"].get("hire")},
        "arms": {name: {
            "game3": {"cycle": arm["game3_launch"]["cycle"], "review": arm["game3_launch"]["final_review"],
                      "awareness": arm["game3_launch"]["awareness"], "month_1_units": arm["game3_launch"]["month_1_units"],
                      "promotion": arm["game3_promotion"], "unlocked": arm["game3_unlocked"],
                      "pending_offers": arm["pending_after_game3"]},
            "game4": {"cycle": arm["game4_launch"]["cycle"], "review": arm["game4_launch"]["final_review"],
                      "awareness": arm["game4_launch"]["awareness"], "month_1_units": arm["game4_launch"]["month_1_units"],
                      "promotion": arm["game4_promotion"], "unlocked": arm["game4_unlocked"]},
            "game5": {"cycle": arm["game5_launch"]["cycle"], "review": arm["game5_launch"]["final_review"],
                      "awareness": arm["game5_launch"]["awareness"], "month_1_units": arm["game5_launch"]["month_1_units"],
                      "promotion": arm["game5_promotion"]},
            "contracts": [action["result"] for action in arm["actions"] if "offer_id" in action],
            "matched_G": endpoint(arm, "matched_G"), "G_plus_2": endpoint(arm, "cycle_plus_2"),
            "G_plus_4": endpoint(arm, "cycle_plus_4"),
            "game6_development_completed": arm.get("game6_development_completed"),
        } for name, arm in arms.items()},
    }
    results["chain_minus_crown_only"] = {
        "cash_cents_at_G": chain["matched_G"]["cash_cents"] - crown["matched_G"]["cash_cents"],
        "cash_cents_at_G_plus_2": chain["cycle_plus_2"]["cash_cents"] - crown["cycle_plus_2"]["cash_cents"],
        "cash_cents_at_G_plus_4": chain["cycle_plus_4"]["cash_cents"] - crown["cycle_plus_4"]["cash_cents"],
        "portfolio_settled_cents_at_G_plus_4": results["arms"]["chain"]["G_plus_4"]["portfolio_settled_cents"] - results["arms"]["crown_only"]["G_plus_4"]["portfolio_settled_cents"],
        "game5_settled_cents_at_G_plus_4": chain["cycle_plus_4"]["game5_sales"]["settled_cents"] - crown["cycle_plus_4"]["game5_sales"]["settled_cents"],
        "feature_play_spend_cents_at_G_plus_4": results["arms"]["chain"]["G_plus_4"]["feature_play_cents"] - results["arms"]["crown_only"]["G_plus_4"]["feature_play_cents"],
        "publisher_receipts_cents_at_G_plus_4": results["arms"]["chain"]["G_plus_4"]["publisher_receipts_cents"] - results["arms"]["crown_only"]["G_plus_4"]["publisher_receipts_cents"],
    }
    delta = results["chain_minus_crown_only"]
    checks[COHORT]["matched_cash_reconciles"] = (
        delta["cash_cents_at_G_plus_4"] == delta["portfolio_settled_cents_at_G_plus_4"]
        + delta["publisher_receipts_cents_at_G_plus_4"] - delta["feature_play_spend_cents_at_G_plus_4"]
    )
    output = {"branch": MANIFEST["branch"], "head": MANIFEST["head"], "analysis_script_sha256": MANIFEST["analysis_script_sha256"],
              "checks": checks, "results": results}
    (HERE / "audit-summary.json").write_text(json.dumps(output, indent=2), encoding="utf-8")
    for name, value in checks.items():
        print(name, value)
    print("chain_minus_crown_only", results["chain_minus_crown_only"])
    if not all((value is None or value) if not isinstance(value, dict) else all(value.values()) for value in checks.values()):
        raise SystemExit(1)


if __name__ == "__main__":
    main()

