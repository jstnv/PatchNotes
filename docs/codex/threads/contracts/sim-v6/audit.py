"""Audit the two predeclared native Crown-before-Neon routes."""

import hashlib
import json
from pathlib import Path
import zipfile

HERE = Path(__file__).resolve().parent
MANIFEST = json.loads((HERE / "source-manifest.json").read_text(encoding="utf-8"))
COPY = Path(MANIFEST["analysis_copy"])
COHORTS = ("crown-current", "crown-lease")
NEON = "neon_circuit"
CROWN = "crown_quill"


def digest(value):
    return hashlib.sha256(value).hexdigest()


def trace(cohort):
    path = HERE / f"{cohort}.json"
    if path.is_file():
        return json.loads(path.read_text(encoding="utf-8"))
    with zipfile.ZipFile(HERE / "native-traces.zip") as archive:
        return json.loads(archive.read(f"{cohort}.json"))


def choices(arm):
    keys = ("phase", "game", "draw", "final_draw", "selected", "redraws", "rolls", "priorities")
    return [{key: action[key] for key in keys if key in action} for action in arm["actions"][1:]]


def summary(arm):
    endpoint = arm["cycle_plus_4"]
    finance = endpoint["state"]["finance_report"]
    return {
        "mode": arm["mode"],
        "contract_result": arm["actions"][0]["result"] if arm["mode"] != "no_offer" else None,
        "launch_cycle": arm["launch"]["cycle"],
        "launch_review": arm["launch"]["final_review"],
        "launch_awareness": arm["launch"]["awareness"],
        "launch_promotion": arm["launch_promotion"],
        "month_1_units": arm["launch"]["month_1_units"],
        "neon_unlocked_at_launch": NEON in arm["launch_unlocked"],
        "launch_unlocked": arm["launch_unlocked"],
        "target_settled_cents_L_plus_2": arm["cycle_plus_2"]["target_sales"]["settled_cents"],
        "target_settled_cents_L_plus_4": endpoint["target_sales"]["settled_cents"],
        "target_earned_cents_L_plus_4": endpoint["target_sales"]["entitlement_cents"],
        "portfolio_settled_cents_L_plus_4": sum(int(row["settled_cents"]) for row in endpoint["state"]["sales"]),
        "cash_cents_L_plus_4": endpoint["cash_cents"],
        "total_overdue_cents_L_plus_4": finance["total_overdue_cents"],
        "unpaid_rent_cents_L_plus_4": finance["unpaid_rent_cents"],
        "credit_score_L_plus_4": finance["credit"]["score"],
        "outstanding_expenses_L_plus_4": finance["outstanding_expenses"],
    }


def main():
    checks = {
        "copy_hashes_unchanged": (all(digest((COPY / rel).read_bytes()) == expected for rel, expected in MANIFEST["files"].items()) if COPY.exists() else None),
        "analysis_script_matches_manifest": digest((HERE / "crown_neon_threshold_v6.gd").read_bytes()) == MANIFEST["analysis_script_sha256"],
    }
    overlay = HERE / "dirty-source-overlay.zip"
    if overlay.is_file():
        with zipfile.ZipFile(overlay) as archive:
            names = [line[3:].replace("\\", "/")[len("patch-notes/"):] for line in MANIFEST["source_status_at_copy"]]
            checks["dirty_overlay_matches_manifest"] = (
                archive.testzip() is None and sorted(archive.namelist()) == sorted(names)
                and all(digest(archive.read(name)) == MANIFEST["files"][name] for name in names)
            )
    results = {}
    for cohort in COHORTS:
        data = trace(cohort)
        arms = {arm["mode"]: arm for arm in data["arms"]}
        trial, cash, none = (arms[name] for name in ("trial", "cash_only", "no_offer"))
        foundation = data["foundation"]
        last = foundation["releases"][-1]
        earned = trial["actions"][0]["result"]["promotion"]
        local = {
            "native_route_valid": data["valid"] and not data["errors"] and all(arm["success"] for arm in arms.values()),
            "prebranch_review_qualifies_crown": last["final_review"] >= 7.0,
            "prebranch_awareness_below_neon": last["awareness"] < 125,
            "prebranch_crown_only": CROWN in foundation["unlocked_before"] and NEON not in foundation["unlocked_before"],
            "prebranch_crown_offer_pending": any(CROWN in offer for offer in foundation["pending_offers"]),
            "identical_branch_state": trial["before"] == cash["before"] == none["before"],
            "identical_contract_hands_and_result": trial["actions"][0]["hands"] == cash["actions"][0]["hands"] and trial["actions"][0]["result"] == cash["actions"][0]["result"],
            "identical_accepted_state": trial["after_contract"] == cash["after_contract"],
            "approved_crown_advance_and_total": trial["actions"][0]["accepted"]["cash_cents"] - trial["actions"][0]["before"]["cash_cents"] == 15000 and trial["actions"][0]["result"]["cash"] == 192000,
            "identical_native_card_choices": choices(trial) == choices(cash),
            "matched_trial_cash_launch": trial["launch"]["cycle"] == cash["launch"]["cycle"] and trial["launch"]["final_review"] == cash["launch"]["final_review"],
            "exact_awareness_delta": trial["launch"]["awareness"] - cash["launch"]["awareness"] == earned == trial["launch_promotion"] and cash["launch_promotion"] == 0,
            "trial_award_consumed_once": trial["cycle_plus_4"]["pending_promotion"] == 0 and cash["suppressed_award"] == earned,
            "no_offer_launches_earlier": none["launch"]["cycle"] < trial["launch"]["cycle"],
            "matched_endpoints": all(arm["cycle_plus_2"]["cycle"] == trial["launch"]["cycle"] + 2 and arm["cycle_plus_4"]["cycle"] == trial["launch"]["cycle"] + 4 for arm in arms.values()),
            "valid_finance": all(arm["ledger_valid"] and arm["cycle_plus_2"]["finance_valid"] and arm["cycle_plus_4"]["finance_valid"] for arm in arms.values()),
            "nonnegative_cash": all(arm["cycle_plus_4"]["cash_cents"] >= 0 for arm in arms.values()),
            "zero_overdue_at_endpoint": all(arm["cycle_plus_4"]["state"]["finance_report"]["total_overdue_cents"] == 0 for arm in arms.values()),
            "unlock_matches_threshold": all((NEON in arm["launch_unlocked"]) == (arm["launch"]["awareness"] >= 125) for arm in arms.values()),
        }
        checks[cohort] = local
        results[cohort] = {
            "foundation": {"release_cycles": [r["cycle"] for r in foundation["releases"]],
                           "last_review": last["final_review"], "last_awareness": last["awareness"],
                           "unlocked_before": foundation["unlocked_before"],
                           "pending_offers": foundation["pending_offers"],
                           "cash_cents_before": foundation["pre_target"]["cash_cents"],
                           "monthly_rent_cents": foundation["initial"]["finance_report"]["monthly_rent_cents"]},
            "arms": {name: summary(arm) for name, arm in arms.items()},
            "trial_minus_cash": {"settled_target_cents_L_plus_4": trial["cycle_plus_4"]["target_sales"]["settled_cents"] - cash["cycle_plus_4"]["target_sales"]["settled_cents"],
                                 "cash_cents_L_plus_4": trial["cycle_plus_4"]["cash_cents"] - cash["cycle_plus_4"]["cash_cents"]},
        }
    output = {"branch": MANIFEST["branch"], "head": MANIFEST["head"], "analysis_script_sha256": MANIFEST["analysis_script_sha256"], "checks": checks, "results": results}
    (HERE / "audit-summary.json").write_text(json.dumps(output, indent=2), encoding="utf-8")
    for name, value in checks.items():
        print(name, value)
    for name, value in results.items():
        print(name, "pre", value["foundation"]["last_review"], value["foundation"]["last_awareness"],
              "Neon unlocks", [value["arms"][arm]["neon_unlocked_at_launch"] for arm in ("trial", "cash_only", "no_offer")],
              "settled delta", value["trial_minus_cash"]["settled_target_cents_L_plus_4"])
    if not all((value is None or value) if not isinstance(value, dict) else all(value.values()) for value in checks.values()):
        raise SystemExit(1)


if __name__ == "__main__":
    main()
