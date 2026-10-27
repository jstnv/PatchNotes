"""Audit the declared G4 four-arm opening study and its older fixture reference."""

from __future__ import annotations

import json
from pathlib import Path


ROOT = Path(__file__).resolve().parents[4]
THREAD = ROOT / "docs/codex/threads/ai-competitors"
BUNDLE = THREAD / "sims/g4-choice-policy-v2"
OLDER = THREAD / "sims/g4-hand-envelope-v1"
OUTPUT = THREAD / "sims/g4-choice-policy-audit-v2.json"
ARMS = ("medium_ref", "medium_rank", "long_rank", "adaptive_rank")


def read(path: Path):
    return json.loads(path.read_text(encoding="utf-8"))


def case_row(case_id: str) -> dict:
    path = BUNDLE / "cases" / case_id
    result = read(path / "result.json")
    samples = read(path / "telemetry.json")["samples"]
    plays = {phase: 0 for phase in ("design", "alpha", "beta")}
    exits = {phase: 0 for phase in plays}
    for sample in samples[1:]:
        request = sample["request"]
        if request["type"] != "development":
            continue
        inner = request["payload"]["request"]
        if inner["type"] == "play" and sample["accepted"]:
            plays[inner["phase"]] += 1
        if inner["type"] == "request_exit" and sample["accepted"]:
            exits[inner["phase"]] += 1
    row = {
        "case_id": case_id,
        "ok": result["ok"],
        "status": result["status"],
        "error": result["error"],
        "commands": result["commands"],
        "accepted_commands": result["accepted_commands"],
        "initial_state": result["initial_state"],
        "initial_rng": result["initial_rng"],
        "final_state": result["final_state"],
        "initial_cash_cents": int(samples[0]["cash_cents"]),
        "initial_fans": int(samples[0]["fans"]),
        "initial_queue_empty": not samples[0]["research_queue"],
        "initial_release_count": samples[0]["release_count"],
        "plays": plays,
        "phase_exits": exits,
        "rejections": [sample["step"] for sample in samples[1:] if not sample["accepted"]],
        "release_cycle": samples[-1]["run_cycle"],
        "final_phase": samples[-1]["phase"],
        "release_count": samples[-1]["release_count"],
        "final_cash_cents": int(samples[-1]["cash_cents"]),
        "min_transaction_cash_cents": min(int(s["transaction_cash_low_cents"]) for s in samples if s["transaction_cash_low_cents"] is not None),
        "final_overdue_cents": int(samples[-1]["overdue_cents"]),
        "final_fans": int(samples[-1]["fans"]),
    }
    if result["ok"] and row["release_count"] == 1:
        review = result["outcome"]["releases"][0]["metadata"]["review"]
        row.update({"review": review["final_review"], "cores": review["cores"],
                    "scope": review["scope"], "required_scope": review["required_scope"],
                    "bugs": review["remaining_bugs"]})
        run = read(path / "studio_checkpoint.json")["studio_payload"]["run"]
        archive_ids = [item["id"] for item in run["historical_titles"]]
        row["archive_ids"] = archive_ids
        row["archive_separate"] = (
            len(archive_ids) == 2
            and all(ident not in json.dumps(run[name], sort_keys=True)
                    for ident in archive_ids
                    for name in ("released_games", "release_metadata", "studio_finance", "fanbase"))
        )
    return row


def main() -> None:
    run_report = read(BUNDLE / "run-report.json")
    groups = []
    rows = []
    parity = []
    for genre in ("action", "adventure"):
        for seed in ("4417", "90210"):
            group = [case_row(f"cohort-{genre}-{arm}-{seed}") for arm in ARMS]
            rows.extend(group)
            groups.append({
                "genre": genre, "seed": seed,
                "equal_initial_state": len({row["initial_state"] for row in group}) == 1,
                "equal_initial_rng": len({json.dumps(row["initial_rng"], sort_keys=True) for row in group}) == 1,
                "review_by_arm": {arm: row.get("review") for arm, row in zip(ARMS, group)},
                "release_cash_by_arm": {arm: row["final_cash_cents"] for arm, row in zip(ARMS, group)},
            })
            old = read(OLDER / "cases" / f"cohort-{genre}-medium-{seed}" / "result.json")
            reference = group[0]
            parity.append({
                "genre": genre, "seed": seed,
                "exact_initial": old["initial_state"] == reference["initial_state"] and old["initial_rng"] == reference["initial_rng"],
                "exact_final": old["final_state"] == reference["final_state"] and old["commands"] == reference["commands"],
            })
    checks = {
        "sixteen_declared": len(rows) == 16 and run_report["case_count"] == 16,
        "equal_opening_state_rng": all(g["equal_initial_state"] and g["equal_initial_rng"] for g in groups),
        "previous_medium_fixture_exact": all(p["exact_initial"] and p["exact_final"] for p in parity),
        "legal_openings": all(r["initial_cash_cents"] == 585000 and r["initial_fans"] == 20
                              and r["initial_queue_empty"] and r["initial_release_count"] == 0 for r in rows),
        "completed_without_rejection": all(r["ok"] and r["status"] == "completed" and not r["rejections"]
                                           and r["commands"] <= 60 for r in rows),
        "studio_releases": all(r["release_count"] == 1 and r["final_phase"] == "studio" for r in rows),
        "ordinary_phase_exits": all(r["phase_exits"] == {"design": 1, "alpha": 1, "beta": 1} for r in rows),
        "no_arrears_or_negative_cash": all(r["final_overdue_cents"] == 0 and r["min_transaction_cash_cents"] >= 0 for r in rows),
        "archive_separate": all(r.get("archive_separate", False) for r in rows),
    }
    report = {
        "status": "passed" if all(checks.values()) else "check_failed",
        "bundle": str(BUNDLE.relative_to(ROOT)),
        "frozen_source_identity": run_report["frozen_source_identity"],
        "requested_config_sha256": run_report["input_hashes"]["requested.json"],
        "checks": checks, "groups": groups, "parity": parity, "cases": rows,
        "scope": "Independent first-release policy trials; no numerical AI or balance approval",
    }
    if OUTPUT.exists():
        raise FileExistsError(OUTPUT)
    OUTPUT.write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
    print(json.dumps({"status": report["status"], "checks": checks, "groups": groups}))


if __name__ == "__main__":
    main()
