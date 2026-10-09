"""Audit and summarize the predeclared native Contracts branches."""

import hashlib
import json
from pathlib import Path
import zipfile

HERE = Path(__file__).resolve().parent
MANIFEST = json.loads((HERE / "source-manifest.json").read_text(encoding="utf-8"))
COPY = Path(MANIFEST["analysis_copy"])


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def sha_bytes(value):
    return hashlib.sha256(value).hexdigest()


def load_trace(cohort):
    direct = HERE / f"{cohort}.json"
    if direct.is_file():
        return json.loads(direct.read_text(encoding="utf-8"))
    with zipfile.ZipFile(HERE / "native-traces.zip") as archive:
        return json.loads(archive.read(f"{cohort}.json"))


def choice_trace(arm):
    keys = ("phase", "game", "draw", "final_draw", "selected", "redraws", "rolls", "priorities")
    return [{key: action[key] for key in keys if key in action} for action in arm["actions"][1:]]


def sales_totals(snapshot):
    records = snapshot["state"]["sales"]
    return {
        "portfolio_earned_cents": sum(int(r["entitlement_cents"]) for r in records),
        "portfolio_settled_cents": sum(int(r["settled_cents"]) for r in records),
    }


def summarize(arm):
    endpoint = arm["cycle_plus_4"]
    report = endpoint["state"]["finance_report"]
    sales = endpoint["target_sales"]
    launch = arm["launch"]
    out = {
        "mode": arm["mode"],
        "offer_id": arm["offer_id"],
        "contract": arm["actions"][0]["result"] if arm["mode"] != "no_offer" else None,
        "launch_cycle": launch["cycle"],
        "launch_review": launch["final_review"],
        "launch_awareness": launch["awareness"],
        "launch_promotion": arm["launch_promotion"],
        "month_1_units": launch["month_1_units"],
        "month_1_projected_net_cents": launch["projected_net_cents"],
        "target_settled_cents_L_plus_2": arm["cycle_plus_2"]["target_sales"]["settled_cents"],
        "target_settled_cents_L_plus_4": sales["settled_cents"],
        "target_earned_cents_L_plus_4": sales["entitlement_cents"],
        "target_total_units_L_plus_4": sales["total_units"],
        "portfolio_earned_cents_L_plus_4": sales_totals(endpoint)["portfolio_earned_cents"],
        "portfolio_settled_cents_L_plus_4": sales_totals(endpoint)["portfolio_settled_cents"],
        "cash_cents_L_plus_4": endpoint["cash_cents"],
        "total_overdue_cents_L_plus_4": report["total_overdue_cents"],
        "unpaid_rent_cents_L_plus_4": report["unpaid_rent_cents"],
        "credit_score_L_plus_4": report["credit"]["score"],
        "outstanding_expenses_L_plus_4": report["outstanding_expenses"],
        "unlocked_L_plus_4": endpoint["unlocked"],
        "finance_valid_L_plus_2": arm["cycle_plus_2"]["finance_valid"],
        "finance_valid_L_plus_4": endpoint["finance_valid"],
    }
    return out


def main():
    checks = {}
    checks["copy_hashes_unchanged"] = (all(sha(COPY / rel) == expected for rel, expected in MANIFEST["files"].items())
                                         if COPY.exists() else None)
    checks["analysis_script_matches_manifest"] = sha(HERE / "promotion_balance_v5.gd") == MANIFEST["analysis_script_sha256"]
    with zipfile.ZipFile(HERE / "dirty-source-overlay.zip") as archive:
        checks["dirty_overlay_matches_manifest"] = archive.testzip() is None and all(
            sha_bytes(archive.read(name)) == MANIFEST["files"][name] for name in archive.namelist())
    results = {}
    for cohort in ("neon-current", "neon-lease", "crown-lease"):
        data = load_trace(cohort)
        arms = {arm["mode"]: arm for arm in data["arms"]}
        trial, cash, none = (arms[k] for k in ("trial", "cash_only", "no_offer"))
        local = {
            "valid_native_route": data["valid"] and not data["errors"] and all(a["success"] for a in arms.values()),
            "identical_prebranch_state": trial["before"] == cash["before"] == none["before"],
            "identical_prebranch_pending_awards": trial["pending_before"] == cash["pending_before"] == none["pending_before"],
            "same_target_offer": trial["offer_id"] == cash["offer_id"] == none["offer_id"],
            "same_contract_result_and_hands": trial["actions"][0]["result"] == cash["actions"][0]["result"] and trial["actions"][0]["hands"] == cash["actions"][0]["hands"],
            "same_contract_accepted_state": trial["after_contract"] == cash["after_contract"],
            "same_postcontract_card_choices": choice_trace(trial) == choice_trace(cash),
            "same_trial_cash_launch_cycle": trial["launch"]["cycle"] == cash["launch"]["cycle"],
            "same_trial_cash_unpromoted_review": trial["launch"]["final_review"] == cash["launch"]["final_review"],
            "trial_consumed_only_target_award": trial["launch_promotion"] == trial["actions"][0]["result"]["promotion"] and trial["cycle_plus_4"]["pending_promotion"] == 0,
            "cash_suppressed_target_award": cash["launch_promotion"] == 0 and cash["suppressed_award"] == trial["launch_promotion"],
            "matched_L_plus_2_and_L_plus_4": all(a["cycle_plus_2"]["cycle"] == trial["launch"]["cycle"] + 2 and a["cycle_plus_4"]["cycle"] == trial["launch"]["cycle"] + 4 for a in arms.values()),
            "finance_valid": all(a["ledger_valid"] and a["cycle_plus_2"]["finance_valid"] and a["cycle_plus_4"]["finance_valid"] for a in arms.values()),
            "cash_nonnegative": all(a["cycle_plus_4"]["cash_cents"] >= 0 for a in arms.values()),
        }
        checks[cohort] = local
        results[cohort] = {
            "foundation_release_cycles": [r["cycle"] for r in data["foundation"]["releases"]],
            "foundation_pending_offers": data["foundation"]["pending_offers"],
            "arms": {key: summarize(value) for key, value in arms.items()},
            "delta_trial_minus_cash": {
                "awareness": trial["launch"]["awareness"] - cash["launch"]["awareness"],
                "month_1_units": trial["launch"]["month_1_units"] - cash["launch"]["month_1_units"],
                "target_settled_cents_L_plus_4": trial["cycle_plus_4"]["target_sales"]["settled_cents"] - cash["cycle_plus_4"]["target_sales"]["settled_cents"],
                "cash_cents_L_plus_4": trial["cycle_plus_4"]["cash_cents"] - cash["cycle_plus_4"]["cash_cents"],
            },
        }
    output = {"source_head": MANIFEST["head"], "source_branch": MANIFEST["branch"], "analysis_script_sha256": MANIFEST["analysis_script_sha256"], "checks": checks, "results": results}
    (HERE / "audit-summary.json").write_text(json.dumps(output, indent=2), encoding="utf-8")
    for key, value in checks.items():
        print(key, value)
    for cohort, value in results.items():
        print(cohort, value["delta_trial_minus_cash"])
    if not all((v is None or v) if not isinstance(v, dict) else all(v.values()) for v in checks.values()):
        raise SystemExit(1)


if __name__ == "__main__":
    main()
