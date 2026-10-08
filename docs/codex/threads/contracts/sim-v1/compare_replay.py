"""Audit the one matched legacy/current Contracts replay, without simulating advances."""

from __future__ import annotations

import json
from pathlib import Path


HERE = Path(__file__).resolve().parent
HISTORICAL = HERE.parents[4] / "patch-notes/design-logs/task32-v1/strong_probe.json"


def load(path: Path) -> dict:
    return json.loads(path.read_text(encoding="utf-8"))


def release_signature(route: dict) -> list[tuple]:
    return [
        tuple(release.get(key) for key in ("final_review", "scope", "awareness", "cycle", "cash_cents"))
        for release in route["releases"]
    ]


def action_signature(action: dict) -> tuple:
    return (
        action.get("phase"),
        action.get("game"),
        action.get("success"),
        action.get("before", {}).get("cycle"),
        action.get("after", {}).get("cycle"),
    )


def check_cash_journal(route: dict) -> None:
    transactions = route["final"]["finance"]["transactions"]
    cash = 0
    for transaction in transactions:
        assert transaction["cash_before_cents"] == cash
        cash += transaction["cash_delta_cents"]
        assert cash >= 0 and transaction["cash_after_cents"] == cash
    assert cash == route["final"]["cash_cents"]


def summarize(route: dict) -> dict:
    return {
        "valid": route["valid"],
        "stop": route["stop"],
        "initial_cash_cents": route["initial"]["cash_cents"],
        "releases": release_signature(route),
        "final_cycle": route["final"]["cycle"],
        "final_cash_cents": route["final"]["cash_cents"],
        "final_arrears_cents": route["final_finance_report"]["unpaid_rent_cents"],
        "final_credit": route["final_finance_report"]["credit"]["score"],
        "errors": route["errors"],
        "discrepancies": route["discrepancies"],
        "first_blocker": route["blockers"][0]["phase"] if route["blockers"] else None,
    }


def main() -> None:
    historical = load(HISTORICAL)
    legacy = load(HERE / "legacy-strong-probe.json")
    trait = load(HERE / "trait-strong-probe.json")
    for route in (historical, legacy, trait):
        assert route["valid"] and not route["errors"] and not route["discrepancies"]
        check_cash_journal(route)
    historical_actions = [action_signature(action) for action in historical["actions"]]
    legacy_actions = [action_signature(action) for action in legacy["actions"]]
    trait_actions = [action_signature(action) for action in trait["actions"]]
    assert historical_actions == legacy_actions
    assert release_signature(historical) == release_signature(legacy)
    assert legacy["initial"]["cash_cents"] == 550000
    assert trait["initial"]["cash_cents"] == 570000
    assert trait["creation"]["traits"]["point_cash_cents"] == 20000
    assert trait["creation"]["traits"]["effects_mode"] == "selection_only_preview"
    assert any(
        transaction["kind"] == "financing_in"
        and transaction["amount_cents"] == 20000
        and transaction["source_id"] == "studio_trait_unspent_points_v1"
        for transaction in trait["initial"]["finance"]["transactions"]
    )
    first_divergence = next(
        (
            index + 1,
            legacy_actions[index],
            trait_actions[index],
        )
        for index in range(min(len(legacy_actions), len(trait_actions)))
        if legacy_actions[index] != trait_actions[index]
    )
    assert first_divergence[0] == 35
    finance_fields = ("cycle", "direct_delta", "kind", "productive", "sales_earned", "settled")
    legacy_finance = legacy["final"]["finance"]["actions"]
    trait_finance = [
        action
        for action in trait["final"]["finance"]["actions"]
        if not (action["kind"] == "financing_in" and action["cycle"] == 0)
    ]
    assert len(legacy_finance) == 33
    assert [tuple(action[key] for key in finance_fields) for action in legacy_finance] == [
        tuple(action[key] for key in finance_fields) for action in trait_finance[:33]
    ]

    def rent_16(route: dict) -> dict:
        payments = [
            transaction
            for transaction in route["final"]["finance"]["transactions"]
            if transaction["kind"] == "rent_payment" and transaction["cycle"] == 32
        ]
        assert len(payments) == 1
        payment = payments[0]
        return {
            "cash_before_payment_cents": payment["cash_before_cents"],
            "payment_cents": payment["amount_cents"],
            "cash_after_payment_cents": payment["cash_after_cents"],
        }
    report = {
        "historical": summarize(historical),
        "current_legacy": summarize(legacy),
        "current_trait": summarize(trait),
        "historical_current_legacy_action_signatures_equal": True,
        "historical_current_legacy_release_signatures_equal": True,
        "matched_finance_actions_through_cycle_32": 33,
        "rent_16": {"legacy": rent_16(legacy), "trait": rent_16(trait)},
        "first_legacy_trait_action_divergence": first_divergence,
        "before_action_35": {
            name: {
                "cycle": route["actions"][34]["before"]["cycle"],
                "cash_cents": route["actions"][34]["before"]["cash_cents"],
                "arrears_cents": route["actions"][34]["before"]["finance_report"]["unpaid_rent_cents"],
                "credit": route["actions"][34]["before"]["finance_report"]["credit"]["score"],
            }
            for name, route in (("legacy", legacy), ("trait", trait))
        },
    }
    (HERE / "REPLAY-SUMMARY.json").write_text(json.dumps(report, indent=2), encoding="utf-8")
    print(json.dumps(report, indent=2))


if __name__ == "__main__":
    main()
