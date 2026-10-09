"""Independent audit of the predeclared current-source Neon loan pressure route."""

import hashlib
import json
from pathlib import Path
import zipfile


HERE = Path(__file__).resolve().parent
MANIFEST = json.loads((HERE / "source-manifest.json").read_text(encoding="utf-8"))
COPY = Path(MANIFEST["analysis_copy"])
TRACE = "neon-loan-pressure.json"
MODES = ("pressure_neon", "pressure_pending", "baseline_neon", "baseline_pending")


def digest(data):
    return hashlib.sha256(data).hexdigest()


def trace():
    if (HERE / TRACE).is_file():
        return json.loads((HERE / TRACE).read_text(encoding="utf-8"))
    with zipfile.ZipFile(HERE / "native-traces.zip") as archive:
        return json.loads(archive.read(TRACE))


def contract(arm):
    found = [action for action in arm["actions"] if "neon_circuit" in str(action.get("offer_id", ""))]
    return found[0] if len(found) == 1 else None


def settled(arm, key):
    return sum(row["settled_cents"] for row in arm[key]["state"]["sales"])


def direct_total(arm, key, kind):
    return sum(action["direct_delta"] for action in arm[key]["state"]["finance"]["actions"] if action["kind"] == kind)


def endpoint(arm, key):
    state = arm[key]
    finance = state["finance_report"]
    loan = finance["bank_loans"][0]
    result = {
        "cycle": state["cycle"], "cash_cents": state["cash_cents"],
        "portfolio_settled_cents": settled(arm, key),
        "overdue_cents": finance["total_overdue_cents"],
        "unpaid_rent_cents": finance["unpaid_rent_cents"],
        "credit_score": finance["credit"]["score"],
        "loan_issued_installments": loan["issued"], "loan_closed": loan["closed"],
        "loan_principal_paid_cents": loan["principal_paid_cents"],
        "loan_interest_paid_cents": loan["interest_paid_cents"],
        "financially_blocked": finance["financially_blocked"],
        "research_queue_count": len(state["research_queue"]),
        "project_cycle": state["state"]["project_cycle"],
    }
    if "target_sales" in state:
        result["target_settled_cents"] = state["target_sales"]["settled_cents"]
    return result


def main():
    checks = {
        "source_copy_hashes_unchanged": (
            all(digest((COPY / path).read_bytes()) == expected for path, expected in MANIFEST["files"].items())
            if COPY.is_dir() else None
        ),
        "analysis_script_hash": digest((HERE / "neon_loan_pressure_v9.gd").read_bytes()) == MANIFEST["analysis_script_sha256"],
    }
    overlay = HERE / "dirty-source-overlay.zip"
    if overlay.is_file():
        with zipfile.ZipFile(overlay) as archive:
            names = [line[3:].replace("\\", "/")[len("patch-notes/"):] for line in MANIFEST["source_status_at_copy"]]
            checks["dirty_overlay_hashes"] = (archive.testzip() is None and sorted(archive.namelist()) == sorted(names)
                                               and all(digest(archive.read(name)) == MANIFEST["files"][name] for name in names))
    data = trace()
    arms = {arm["mode"]: arm for arm in data["arms"]}
    pressure_neon, pressure_pending, baseline_neon, baseline_pending = (arms[name] for name in MODES)
    foundation = data["foundation"]
    q = foundation["loan_quote_cycle16"]
    loan = foundation["bank_report"]["bank_loans"][0]
    pressure_contract = contract(pressure_neon)
    baseline_contract = contract(baseline_neon)
    endpoint_keys = ("cycle_34", "cycle_36", "cycle_38", "cycle_plus_2", "cycle_plus_4")
    cohort_checks = {
        "native_cohort_valid": data["valid"] and not data["errors"] and len(arms) == 4 and all(a["valid_observation"] and not a["errors"] and not a["stop"] and a["ledger_valid"] for a in arms.values()),
        "legal_neon_foundation": (len(foundation["releases"]) == 2 and foundation["releases"][-1]["cycle"] == 33
                                  and foundation["releases"][-1]["awareness"] >= 125
                                  and any("neon_circuit" in str(x) for x in foundation["pending_offers"])),
        "native_bank_acceptance": (foundation["loan_accepted"] and q["accepted"] and q["schedule"]["principal_cents"] == 50000
                                   and q["schedule"]["term_months"] == 12 and q["capacity_cents"] >= q["schedule"]["maximum_installment_cents"]
                                   and foundation["loan_cash_after"] - foundation["loan_cash_before"] == 50000),
        "active_loan_at_neon_choice": not loan["closed"] and loan["issued"] == 8 and loan["schedule"]["last_due_cycle"] == 40,
        "identical_prebranch_state": all(a["before"] == pressure_neon["before"] and a["pending_offers_before"] == pressure_neon["pending_offers_before"] for a in arms.values()),
        "same_within_policy_before_neon": pressure_neon["post_policy"] == pressure_pending["post_policy"] and baseline_neon["post_policy"] == baseline_pending["post_policy"],
        "legal_zero_cycle_store_admissions": all(
            [(str(x["feature_id"]), x["quote"]["down_cents"], x["accepted"]) for x in a["actions"] if x.get("phase") == "research admission"]
            == [("save_files", 110000, True), ("colored_text", 32500, True)]
            and a["post_policy"]["cycle"] == a["before"]["cycle"] == 33
            and a["before"]["cash_cents"] - a["post_policy"]["cash_cents"] == 142500
            and len(a["research_queue"]) == 2 and a["owned_before"] == a["owned_after_policy"]
            for a in (pressure_neon, pressure_pending)
        ),
        "baseline_no_store_spend": all(a["post_policy"]["cash_cents"] == a["before"]["cash_cents"] and not a["research_queue"] for a in (baseline_neon, baseline_pending)),
        "loan_and_low_cash_prechoice": pressure_neon["post_policy"]["cash_cents"] < 50000 and not pressure_neon["post_policy"]["finance_report"]["bank_loans"][0]["closed"],
        "same_neon_hands_and_result": (pressure_contract is not None and baseline_contract is not None
                                      and [(hand["draw"], hand["selected"]) for hand in pressure_contract["hands"]]
                                      == [(hand["draw"], hand["selected"]) for hand in baseline_contract["hands"]]
                                      and pressure_contract["result"] == baseline_contract["result"]
                                      and pressure_contract["result"]["cash"] == 145116
                                      and pressure_contract["result"]["promotion"] == 18),
        "legal_launch_and_promotion": (pressure_neon["launch"]["cycle"] == baseline_neon["launch"]["cycle"] == 53
                                       and pressure_pending["launch"]["cycle"] == baseline_pending["launch"]["cycle"] == 51
                                       and pressure_neon["launch_promotion"] == baseline_neon["launch_promotion"] == 18
                                       and pressure_pending["launch_promotion"] == baseline_pending["launch_promotion"] == 0),
        "matched_calendar_and_finance": all(
            all(a[key]["cycle"] == int(key.split("_")[-1]) if key.startswith("cycle_3") else a[key]["cycle"] == (55 if key == "cycle_plus_2" else 57)
                for key in endpoint_keys)
            and all(a[key]["finance_valid"] and a[key]["cash_cents"] >= 0 for key in endpoint_keys)
            for a in arms.values()
        ),
        "real_cycle34_settlement_covers_bills": all(
            a["cycle_34"]["finance_report"]["rows"][-2]["sales_settled_cents"] == 247552
            and a["cycle_34"]["finance_report"]["rows"][-2]["rent_paid_cents"] == 50000
            and a["cycle_34"]["finance_report"]["rows"][-2]["principal_paid_cents"] == 4166
            and a["cycle_34"]["finance_report"]["rows"][-2]["interest_paid_cents"] == 167
            for a in arms.values()
        ),
        "no_arrears_or_project_block": all(
            all(a[key]["finance_report"]["total_overdue_cents"] == 0 and not a[key]["finance_report"]["financially_blocked"] for key in endpoint_keys)
            and not a["blockers"] for a in arms.values()
        ),
        "all_loan_installments_paid_by_57": all(
            a["cycle_plus_4"]["finance_report"]["bank_loans"][0]["closed"]
            and a["cycle_plus_4"]["finance_report"]["bank_loans"][0]["closed_cycle"] == 40
            and a["cycle_plus_4"]["finance_report"]["bank_loans"][0]["issued"] == 12
            and a["cycle_plus_4"]["finance_report"]["bank_loans"][0]["principal_paid_cents"] == 50000
            and a["cycle_plus_4"]["finance_report"]["bank_loans"][0]["interest_paid_cents"] == 3250
            for a in arms.values()
        ),
        "same_policy_cost_at_all_endpoints": all(
            pressure_neon[key]["cash_cents"] + 142500 == baseline_neon[key]["cash_cents"]
            and pressure_pending[key]["cash_cents"] + 142500 == baseline_pending[key]["cash_cents"]
            and settled(pressure_neon, key) == settled(baseline_neon, key)
            and settled(pressure_pending, key) == settled(baseline_pending, key)
            for key in endpoint_keys
        ),
    }
    checks["neon-loan-pressure"] = cohort_checks
    results = {
        "foundation": {
            "game2_cycle": foundation["releases"][-1]["cycle"], "game2_awareness": foundation["releases"][-1]["awareness"],
            "bank_capacity_cents": q["capacity_cents"], "maximum_installment_cents": q["schedule"]["maximum_installment_cents"],
            "loan_accepted_cycle": q["schedule"]["accepted_cycle"], "loan_last_due_cycle": q["schedule"]["last_due_cycle"],
            "cash_before_policy_cents": pressure_neon["before"]["cash_cents"],
        },
        "arms": {mode: {
            "post_policy": endpoint(arm, "post_policy"),
            "cycle_34": endpoint(arm, "cycle_34"), "cycle_36": endpoint(arm, "cycle_36"),
            "cycle_38": endpoint(arm, "cycle_38"),
            "launch": {"cycle": arm["launch"]["cycle"], "review": arm["launch"]["final_review"],
                       "awareness": arm["launch"]["awareness"], "promotion": arm["launch_promotion"]},
            "L_plus_2": endpoint(arm, "cycle_plus_2"), "L_plus_4": endpoint(arm, "cycle_plus_4"),
            "contract": contract(arm)["result"] if contract(arm) else None,
            "stop": arm["stop"], "blockers": arm["blockers"],
        } for mode, arm in arms.items()},
    }
    results["pressure_neon_minus_pending"] = {
        "cash_cents_at_34": pressure_neon["cycle_34"]["cash_cents"] - pressure_pending["cycle_34"]["cash_cents"],
        "cash_cents_at_36": pressure_neon["cycle_36"]["cash_cents"] - pressure_pending["cycle_36"]["cash_cents"],
        "cash_cents_at_38": pressure_neon["cycle_38"]["cash_cents"] - pressure_pending["cycle_38"]["cash_cents"],
        "cash_cents_at_55": pressure_neon["cycle_plus_2"]["cash_cents"] - pressure_pending["cycle_plus_2"]["cash_cents"],
        "cash_cents_at_57": pressure_neon["cycle_plus_4"]["cash_cents"] - pressure_pending["cycle_plus_4"]["cash_cents"],
        "portfolio_settled_cents_at_57": settled(pressure_neon, "cycle_plus_4") - settled(pressure_pending, "cycle_plus_4"),
        "publisher_receipts_cents_at_57": direct_total(pressure_neon, "cycle_plus_4", "publisher_receipt") - direct_total(pressure_pending, "cycle_plus_4", "publisher_receipt"),
        "feature_play_spend_cents_at_57": -direct_total(pressure_neon, "cycle_plus_4", "feature_play") + direct_total(pressure_pending, "cycle_plus_4", "feature_play"),
    }
    delta = results["pressure_neon_minus_pending"]
    checks["neon-loan-pressure"]["matched_cash_reconciles"] = (
        delta["cash_cents_at_57"] == delta["portfolio_settled_cents_at_57"]
        + delta["publisher_receipts_cents_at_57"] - delta["feature_play_spend_cents_at_57"]
    )
    checks["neon-loan-pressure"]["policy_does_not_change_neon_choice_delta"] = all(
        pressure_neon[key]["cash_cents"] - pressure_pending[key]["cash_cents"]
        == baseline_neon[key]["cash_cents"] - baseline_pending[key]["cash_cents"]
        for key in endpoint_keys
    )
    output = {"branch": MANIFEST["branch"], "head": MANIFEST["head"], "script_sha256": MANIFEST["analysis_script_sha256"],
              "checks": checks, "results": results}
    (HERE / "audit-summary.json").write_text(json.dumps(output, indent=2), encoding="utf-8")
    for key, value in checks.items():
        print(key, value)
    print("pressure_neon_minus_pending", results["pressure_neon_minus_pending"])
    if not all((value is None or value) if not isinstance(value, dict) else all(value.values()) for value in checks.values()):
        raise SystemExit(1)


if __name__ == "__main__":
    main()
