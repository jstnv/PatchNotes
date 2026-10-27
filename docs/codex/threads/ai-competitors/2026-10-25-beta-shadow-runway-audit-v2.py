"""Audit private Beta finance telemetry against unchanged frozen world controls."""

from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path


SOURCE = "5da7bc70f45fc63d33e6f5293e77338992038810b84a2c964ff47aff7a2b1a64"
PAIRS = (
    (4417, "rival-proportional-beta-control-4417-20261024-v1", "rival-beta-shadow-4417-20261025-v1"),
    (4418, "rival-two-hand-qa-4418-control-20261025-v1", "rival-beta-shadow-4418-20261025-v1"),
)
GAMEPLAY_KEYS = (
    "initial_state_digest", "initial_rng", "first_boundary_digest", "first_boundary_rng", "final",
    "rival_progress", "rival_publications", "rival_releases", "rival_release_details", "releases",
    "projects", "observations", "store_records", "strong_status",
)


def sha(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--output", type=Path, required=True)
    args = parser.parse_args()
    owner = Path(__file__).resolve().parent
    evidence: list[dict] = []
    errors: list[str] = []
    rows: list[dict] = []
    selected_insider_hands = 0
    accepted_beta_hands = 0
    for seed, control_dir, shadow_dir in PAIRS:
        control_path = owner / "sims" / control_dir / "world-report.json"
        shadow_path = owner / "sims" / shadow_dir / "world-report.json"
        control = json.loads(control_path.read_text(encoding="utf-8"))
        shadow = json.loads(shadow_path.read_text(encoding="utf-8"))
        checks = {key: control.get(key) == shadow.get(key) for key in GAMEPLAY_KEYS}
        control_choices = [{k: v for k, v in row.items() if k != "policy_wall_us"}
                           for row in control.get("rival_choices", [])]
        shadow_choices = [{k: v for k, v in row.items() if k not in ("policy_wall_us", "beta_shadow")}
                          for row in shadow.get("rival_choices", [])]
        checks["all_choices_without_new_telemetry"] = control_choices == shadow_choices
        checks["same_gameplay_source"] = control.get("source_identity") == shadow.get("source_identity") == SOURCE
        checks["world_complete"] = control.get("completed") is True and shadow.get("completed") is True
        checks["zero_world_failures"] = control.get("failures") == shadow.get("failures") == 0
        if not all(checks.values()):
            errors.append(f"seed {seed}: mismatched {sorted(k for k, ok in checks.items() if not ok)}")
        exits = [row for row in shadow.get("rival_choices", []) if row.get("beta_shadow") is not None]
        if len(exits) != 10:
            errors.append(f"seed {seed}: expected ten telemetry exits; got {len(exits)}")
        for row in exits:
            finance = row["beta_shadow"]
            run_cycle = finance.get("run_cycle")
            next_due = finance.get("next_due_cycle")
            expected_next_due = (run_cycle // 2 + 1) * 2 if isinstance(run_cycle, int) else None
            if (not isinstance(run_cycle, int) or run_cycle != row.get("cycle") + 1
                    or finance.get("cash_cents") != row.get("cash_cents")
                    or next_due != expected_next_due or finance.get("monthly_rent_cents") != 50000
                    or finance.get("monthly_payroll_cents") != 0
                    or finance.get("total_overdue_cents") != 0
                    or finance.get("outstanding_expenses") != []
                    or finance.get("bank_loans") != []):
                errors.append(f"seed {seed}: inconsistent exit finance at {row.get('project_id')}")
            due_next_hand = 50000 if next_due == run_cycle + 1 else 0
            cards = row.get("candidates", [])
            ops = {card.get("qa_operation") for card in cards}
            rows.append({"seed": seed, "studio_id": row.get("studio_id"),
                         "project_id": row.get("project_id"), "world_cycle": row.get("cycle"),
                         "rival_run_cycle": run_cycle, "cash_cents": row.get("cash_cents"),
                         "next_due_cycle": next_due, "next_hand_rent_due_cents": due_next_hand,
                         "total_overdue_cents": finance.get("total_overdue_cents"),
                         "monthly_payroll_cents": finance.get("monthly_payroll_cents"),
                         "bank_loan_count": len(finance.get("bank_loans", [])),
                         "visible_search_and_debug": "search" in ops and "debug" in ops,
                         "known_bugs_public": row.get("known_bugs"),
                         "cash_after_next_rent_cents": row.get("cash_cents", 0) - due_next_hand})
        exit_sequence = {row["project_id"]: row["sequence"] for row in exits}
        seen_hands: set[tuple] = set()
        for choice in shadow.get("rival_choices", []):
            if (choice.get("phase") != "beta" or choice.get("request") != "play"
                    or choice.get("project_id") not in exit_sequence
                    or choice.get("sequence", -1) >= exit_sequence[choice["project_id"]]):
                continue
            key = (choice.get("studio_id"), choice.get("project_id"), choice.get("sequence"))
            if key in seen_hands:
                continue
            seen_hands.add(key)
            accepted_beta_hands += 1
            by_token = {card.get("token"): card for card in choice.get("candidates", [])}
            if any(by_token.get(token, {}).get("definition") == "playtest_rival_games"
                   for token in choice.get("selected_tokens", [])):
                selected_insider_hands += 1
        if len(seen_hands) != len(exits) * 2:
            errors.append(f"seed {seed}: expected two accepted Beta hands per completed project")
        evidence.append({"seed": seed, "control_report": str(control_path.relative_to(owner)),
                         "control_sha256": sha(control_path),
                         "shadow_report": str(shadow_path.relative_to(owner)),
                         "shadow_sha256": sha(shadow_path), "checks": checks,
                         "control_checks": control.get("checks"), "shadow_checks": shadow.get("checks")})
    if len(rows) != 20:
        errors.append(f"expected 20 exit rows total; got {len(rows)}")
    summary = {
        "exit_count": len(rows),
        "next_hand_rent_due_count": sum(row["next_hand_rent_due_cents"] == 50000 for row in rows),
        "cash_range_cents": [min((row["cash_cents"] for row in rows), default=None),
                             max((row["cash_cents"] for row in rows), default=None)],
        "next_rent_plus_reserve_pass_counts": {
            str(reserve): sum(row["cash_after_next_rent_cents"] >= reserve for row in rows)
            for reserve in (50000, 100000, 200000)
        },
        "visible_search_and_debug_count": sum(row["visible_search_and_debug"] for row in rows),
        "accepted_beta_hands": accepted_beta_hands,
        "accepted_beta_hands_selecting_insider_payout": selected_insider_hands,
    }
    result = {"status": "PASS" if not errors else "FAIL", "source_identity": SOURCE,
              "evidence": evidence, "summary": summary, "exit_rows": rows, "errors": errors,
              "limitations": ["The telemetry validates no-choice-change for two legal debt-free incumbent worlds only",
                              "No low-cash or active-loan Beta fixture was run",
                              "Next legal four-card hand, QA value, future sales and post-launch reserve remain unestimated"]}
    if args.output.exists():
        raise SystemExit(f"Refusing overwrite: {args.output}")
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(json.dumps(result, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    print(json.dumps({"status": result["status"], "summary": summary, "errors": errors}, sort_keys=True))
    return 0 if not errors else 1


if __name__ == "__main__":
    raise SystemExit(main())
