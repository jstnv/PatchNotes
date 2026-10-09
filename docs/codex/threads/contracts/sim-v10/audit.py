"""Independently audit the declared Starwave shadow timing screen.

The synthetic cycles and fixed rewards are analysis inputs, never a playable
Starwave Contract or evidence that three card hands can be completed.
"""

from __future__ import annotations

from collections import defaultdict
import hashlib
import json
from pathlib import Path
import zipfile


HERE = Path(__file__).resolve().parent
MANIFEST = json.loads((HERE / "source-manifest.json").read_text(encoding="utf-8"))
COPY = Path(MANIFEST["analysis_copy"])
TRACE = "starwave-timing.json"
SPECS = {
    "pending": (0, 0, 0),
    "delay_only": (3, 0, 0),
    "cash2240_p0": (3, 224000, 0),
    "cash2240_p6": (3, 224000, 6),
    "cash2240_p14": (3, 224000, 14),
    "cash3000_p6": (3, 300000, 6),
}
ENDPOINTS = ("matched_L", "cycle_plus_2", "cycle_plus_4")
SHADOW_ID = "analysis_starwave_timing_v10"


def sha(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def load_trace() -> dict:
    if (HERE / TRACE).is_file():
        return json.loads((HERE / TRACE).read_text(encoding="utf-8"))
    with zipfile.ZipFile(HERE / "native-traces.zip") as archive:
        if archive.testzip() is not None or archive.namelist() != [TRACE]:
            raise AssertionError("Trace ZIP integrity or contents failed")
        return json.loads(archive.read(TRACE))


def direct_by_kind(endpoint: dict) -> dict[str, int]:
    totals: dict[str, int] = defaultdict(int)
    for action in endpoint["finance_snapshot"]["actions"]:
        totals[action["kind"]] += action["direct_delta"]
    return dict(totals)


def action_signature(arm: dict, game: int) -> list:
    return [
        (action.get("phase"), action.get("draw"), action.get("selected"))
        for action in arm["actions"]
        if action.get("game") == game
    ]


def compact_endpoint(endpoint: dict) -> dict:
    finance = endpoint["finance"]
    return {
        "cycle": endpoint["cycle"],
        "cash_cents": endpoint["cash_cents"],
        "portfolio_settled_cents": endpoint["portfolio_settled_cents"],
        "game4_settled_cents": endpoint["game4_sales"].get("settled_cents", 0),
        "project_cycle": endpoint["state"]["project_cycle"],
        "credit_score": finance["credit"]["score"],
        "overdue_cents": finance["total_overdue_cents"],
        "unpaid_rent_cents": finance["unpaid_rent_cents"],
        "feature_play_direct_cents": direct_by_kind(endpoint).get("feature_play", 0),
        "publisher_receipt_direct_cents": direct_by_kind(endpoint).get("publisher_receipt", 0),
    }


def main() -> None:
    checks: dict[str, object] = {}
    checks["source_copy_hashes_unchanged"] = (
        all((COPY / name).is_file() and sha((COPY / name).read_bytes()) == expected
            for name, expected in MANIFEST["files"].items())
        if COPY.is_dir() else None
    )
    checks["analysis_script_hashes"] = all(
        sha((HERE / name).read_bytes()) == expected
        for name, expected in MANIFEST["analysis_scripts_sha256"].items()
    )
    with zipfile.ZipFile(HERE / "dirty-source-overlay.zip") as archive:
        dirty = [line[3:].replace("\\", "/")[len("patch-notes/"):]
                 for line in MANIFEST["source_status_at_copy"]]
        checks["dirty_overlay_hashes"] = (
            archive.testzip() is None
            and sorted(archive.namelist()) == sorted(dirty)
            and all(sha(archive.read(name)) == MANIFEST["files"][name] for name in dirty)
        )
    commands = [json.loads((HERE / f"{name}.command.json").read_text(encoding="utf-8"))
                for name in ("import", "starwave-timing")]
    checks["native_commands_passed"] = all(c["exit"] == 0 and not c["errors"] for c in commands)

    data = load_trace()
    arms = {arm["mode"]: arm for arm in data["arms"]}
    chain = data["starwave_chain"]
    foundation = data["foundation"]
    reference = data["reference_cycle"]
    before = arms["pending"]["before"]
    chain_contracts = [action for action in chain["actions"] if "offer_id" in action]
    checks["native_cohort_valid"] = (data["valid"] and not data["errors"]
                                     and len(data["arms"]) == len(SPECS)
                                     and set(arms) == set(SPECS)
                                     and all(a["success"] and not a["errors"] and not a["blockers"]
                                             and a["ledger_valid"] for a in arms.values()))
    checks["legal_profile_foundation"] = (
        len(foundation["releases"]) == 2
        and foundation["releases"][-1]["final_review"] >= 7.0
        and foundation["releases"][-1]["awareness"] < 125
        and chain["game3_launch"]["awareness"] == 126
        and chain["game3_promotion"] == 12
        and len(chain_contracts) == 2
        and "crown_quill" in chain_contracts[0]["offer_id"]
        and "neon_circuit" in chain_contracts[1]["offer_id"]
        and chain_contracts[0]["result"]["cash"] == 192000
        and chain_contracts[1]["result"]["cash"] == 145116
        and chain["completed_contracts"] == 3
        and "starwave" in chain["unlocked"]
        and chain["pending_offers"] == []
        and list(chain["pending_promotion"].values()) == [18]
        and chain["after_neon"]["cycle"] == before["cycle"]
        and chain["after_neon"]["cash_cents"] == before["cash_cents"]
    )
    checks["identical_post_neon_branch"] = all(a["before"] == before for a in arms.values())
    checks["declared_placeholder_arithmetic"] = all(
        (a["spec"]["cycles"], a["spec"]["cash_cents"], a["spec"]["extra_promotion"]) == SPECS[mode]
        and len(a["placeholders"]) == SPECS[mode][0]
        and all(p["analysis_only"] and p["success"] and p["number"] == index + 1
                and p["before"]["cycle"] == before["cycle"] + index
                and p["after"]["cycle"] == before["cycle"] + index + 1
                and p["receipt_cents"] == (SPECS[mode][1] if index == 2 else 0)
                and p["after"]["completed_contracts"] == 3
                for index, p in enumerate(a["placeholders"]))
        and a.get("after_placeholders", a["before"])["pending_promotion"] == 18 + SPECS[mode][2]
        and a.get("after_placeholders", a["before"])["completed_contracts"] == 3
        for mode, a in arms.items()
    )
    checks["no_playable_starwave_or_scored_hands"] = all(
        not any("starwave" in str(action.get("offer_id", "")) for action in a["actions"])
        and not any("selected" in p for p in a["placeholders"])
        for a in arms.values()
    )
    checks["matched_calendar_and_native_game4"] = (
        reference == 75
        and arms["pending"]["game4_launch"]["cycle"] == reference - 3
        and all(a["game4_launch"]["cycle"] == (reference - 3 if mode == "pending" else reference)
                and a["game4_launch"]["final_review"] == 8.1
                and a["game4_launch"]["scope"] == 29
                and a["game4_promotion"] == 18 + SPECS[mode][2]
                and a["game4_launch"]["awareness"] == 132 + SPECS[mode][2]
                and all(a[key]["cycle"] == reference + 2 * i for i, key in enumerate(ENDPOINTS))
                for mode, a in arms.items())
        and all(action_signature(a, 4) == action_signature(arms["pending"], 4)
                for a in arms.values())
    )
    checks["promotion_once_and_stack"] = all(
        a["game4_consumed_awards"].get(SHADOW_ID) == a["game4_launch"]["release_id"]
        if SPECS[mode][2] > 0 else SHADOW_ID not in a["game4_consumed_awards"]
        for mode, a in arms.items()
    ) and all(
        not a["cycle_plus_4"]["pending_promotion_awards"] for a in arms.values()
    )
    checks["finance_and_access"] = all(
        all(a[key]["finance_valid"] and a[key]["finance_snapshot"]["cash_cents"] == a[key]["cash_cents"]
            and a[key]["finance"]["total_overdue_cents"] == 0
            and a[key]["finance"]["unpaid_rent_cents"] == 0
            and not a[key]["finance"]["financially_blocked"]
            for key in ENDPOINTS)
        and a["game5_development_completed"]
        for a in arms.values()
    )
    checks["fixed_receipt_is_once_only"] = all(
        sum(x["direct_delta"] for x in a["cycle_plus_4"]["finance_snapshot"]["actions"]
            if x["source_id"] == SHADOW_ID and x["kind"] == "publisher_receipt") == SPECS[mode][1]
        for mode, a in arms.items()
    )
    checks["cash_and_sales_reconcile"] = all(
        a[key]["cash_cents"] - arms["pending"][key]["cash_cents"]
        == a[key]["portfolio_settled_cents"] - arms["pending"][key]["portfolio_settled_cents"]
        + sum(direct_by_kind(a[key]).values()) - sum(direct_by_kind(arms["pending"][key]).values())
        for a in arms.values() for key in ENDPOINTS
    )
    checks["fixed_cash_and_promotion_isolation"] = all(
        arms["cash2240_p0"][key]["cash_cents"] - arms["delay_only"][key]["cash_cents"] == 224000
        and arms["cash3000_p6"][key]["cash_cents"] - arms["cash2240_p6"][key]["cash_cents"] == 76000
        and arms["cash2240_p0"][key]["portfolio_settled_cents"] == arms["delay_only"][key]["portfolio_settled_cents"]
        and arms["cash3000_p6"][key]["portfolio_settled_cents"] == arms["cash2240_p6"][key]["portfolio_settled_cents"]
        for key in ENDPOINTS
    )

    results = {
        "foundation": {"game2_cycle": foundation["releases"][-1]["cycle"],
                       "game2_review": foundation["releases"][-1]["final_review"],
                       "game2_awareness": foundation["releases"][-1]["awareness"],
                       "game3_cycle": chain["game3_launch"]["cycle"],
                       "post_neon_cycle": before["cycle"], "post_neon_cash_cents": before["cash_cents"],
                       "pending_neon_promotion": before["pending_promotion"],
                       "completed_contracts": before["completed_contracts"]},
        "reference_cycle": reference,
        "arms": {mode: {"game4_launch": {key: a["game4_launch"][key]
                                          for key in ("cycle", "final_review", "awareness", "month_1_units")},
                        "game4_promotion": a["game4_promotion"],
                        "endpoints": {key: compact_endpoint(a[key]) for key in ENDPOINTS}}
                 for mode, a in arms.items()},
    }
    results["versus_pending_at_L_plus_4"] = {
        mode: {
            "cash_cents": a["cycle_plus_4"]["cash_cents"] - arms["pending"]["cycle_plus_4"]["cash_cents"],
            "portfolio_settled_cents": a["cycle_plus_4"]["portfolio_settled_cents"] - arms["pending"]["cycle_plus_4"]["portfolio_settled_cents"],
            "publisher_receipt_direct_cents": direct_by_kind(a["cycle_plus_4"]).get("publisher_receipt", 0)
            - direct_by_kind(arms["pending"]["cycle_plus_4"]).get("publisher_receipt", 0),
            "feature_play_direct_cents": direct_by_kind(a["cycle_plus_4"]).get("feature_play", 0)
            - direct_by_kind(arms["pending"]["cycle_plus_4"]).get("feature_play", 0),
            "project_cycle_delta": a["cycle_plus_4"]["state"]["project_cycle"]
            - arms["pending"]["cycle_plus_4"]["state"]["project_cycle"],
        }
        for mode, a in arms.items() if mode != "pending"
    }
    summary = {"branch": MANIFEST["branch"], "head": MANIFEST["head"],
               "project_file_count": MANIFEST["file_count"],
               "dirty_project_path_count": len(MANIFEST["source_status_at_copy"]),
               "analysis_scripts_sha256": MANIFEST["analysis_scripts_sha256"],
               "checks": checks, "results": results}
    (HERE / "audit-summary.json").write_text(json.dumps(summary, indent=2), encoding="utf-8")
    for key, value in checks.items():
        print(key, value)
    print("L_plus_4_deltas", results["versus_pending_at_L_plus_4"])
    if any(value is False for value in checks.values()):
        raise SystemExit(1)


if __name__ == "__main__":
    main()
