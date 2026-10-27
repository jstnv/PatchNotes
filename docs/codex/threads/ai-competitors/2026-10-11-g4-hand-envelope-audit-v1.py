"""Audit the predeclared G4 finite-hand screen; retain every case outcome."""

from __future__ import annotations

import json
from pathlib import Path


ROOT = Path(__file__).resolve().parents[4]
THREAD = ROOT / "docs/codex/threads/ai-competitors"
BUNDLE = THREAD / "sims/g4-hand-envelope-v1"
OUTPUT = THREAD / "sims/g4-hand-envelope-audit-v1.json"


def read(path: Path):
    return json.loads(path.read_text(encoding="utf-8"))


def inspect(case_id: str) -> dict:
    path = BUNDLE / "cases" / case_id
    result = read(path / "result.json")
    samples = read(path / "telemetry.json")["samples"]
    row = {
        "case_id": case_id,
        "ok": result["ok"],
        "status": result["status"],
        "error": result["error"],
        "commands": result["commands"],
        "accepted_commands": result["accepted_commands"],
        "initial_state": result["initial_state"],
        "initial_rng": result["initial_rng"],
        "initial_cash_cents": int(samples[0]["cash_cents"]),
        "initial_fans": int(samples[0]["fans"]),
        "initial_owned": len(samples[0]["owned_features"]),
        "initial_queue_empty": not samples[0]["research_queue"],
        "initial_live_count": samples[0]["release_count"],
        "accepted_play_hands": {phase: 0 for phase in ("design", "alpha", "beta")},
        "phase_exits": {phase: 0 for phase in ("design", "alpha", "beta")},
        "rejected_steps": [s["step"] for s in samples[1:] if not s["accepted"]],
        "min_sample_cash_cents": min(int(s["cash_cents"]) for s in samples),
        "min_transaction_cash_cents": min(int(s["transaction_cash_low_cents"]) for s in samples if s["transaction_cash_low_cents"] is not None),
        "final_cash_cents": int(samples[-1]["cash_cents"]),
        "final_overdue_cents": int(samples[-1]["overdue_cents"]),
        "final_fans": int(samples[-1]["fans"]),
        "release_cycle": samples[-1]["run_cycle"],
        "final_phase": samples[-1]["phase"],
        "live_count": samples[-1]["release_count"],
    }
    for sample in samples[1:]:
        request = sample["request"]
        if request["type"] != "development":
            continue
        inner = request["payload"]["request"]
        if inner["type"] == "play" and sample["accepted"]:
            row["accepted_play_hands"][inner["phase"]] += 1
        if inner["type"] == "request_exit" and sample["accepted"]:
            row["phase_exits"][inner["phase"]] += 1
    if result["ok"] and result["status"] == "completed" and row["live_count"] == 1:
        release = result["outcome"]["releases"][0]
        review = release["metadata"]["review"]
        row.update({
            "review": review["final_review"],
            "cores": review["cores"],
            "scope": review["scope"],
            "required_scope": review["required_scope"],
            "bugs": review["remaining_bugs"],
        })
        run = read(path / "studio_checkpoint.json")["studio_payload"]["run"]
        archive_ids = [title["id"] for title in run["historical_titles"]]
        row["archive_ids"] = archive_ids
        row["archive_separate"] = (
            len(archive_ids) == 2
            and all(ident not in json.dumps(run[name], sort_keys=True)
                    for name in ("released_games", "release_metadata", "studio_finance", "fanbase")
                    for ident in archive_ids)
        )
        row["opening_snapshot_unchanged"] = (
            int(run["opening_snapshot"]["cash_cents"]) == 585000
            and int(run["opening_snapshot"]["fans"]) == 20
            and run["opening_snapshot"]["research_queue_empty"]
        )
    return row


def main() -> None:
    report = read(BUNDLE / "run-report.json")
    rows = []
    triples = []
    for genre in ("action", "adventure"):
        for seed in ("4417", "90210"):
            group = [inspect(f"cohort-{genre}-{plan}-{seed}")
                     for plan in ("baseline", "medium", "long")]
            rows.extend(group)
            triples.append({
                "genre": genre,
                "seed": seed,
                "equal_initial_state": len({r["initial_state"] for r in group}) == 1,
                "equal_initial_rng": len({json.dumps(r["initial_rng"], sort_keys=True) for r in group}) == 1,
                "equal_archive": len({tuple(r.get("archive_ids", [])) for r in group}) == 1,
                "reviews": [r.get("review") for r in group],
                "release_cycles": [r["release_cycle"] for r in group],
                "final_cash_cents": [r["final_cash_cents"] for r in group],
            })
    checks = {
        "twelve_declared_cases": len(rows) == 12 and report["case_count"] == 12,
        "same_initial_states_and_rng": all(t["equal_initial_state"] and t["equal_initial_rng"] for t in triples),
        "legal_opening": all(r["initial_cash_cents"] == 585000 and r["initial_fans"] == 20
                             and r["initial_queue_empty"] and r["initial_live_count"] == 0
                             for r in rows),
        "completed_without_rejection": all(r["ok"] and r["status"] == "completed"
                                           and not r["rejected_steps"] and r["commands"] <= 60
                                           for r in rows),
        "all_studio_releases": all(r["live_count"] == 1 and r["final_phase"] == "studio" for r in rows),
        "no_arrears_or_negative_cash": all(r["final_overdue_cents"] == 0
                                           and r["min_transaction_cash_cents"] >= 0 for r in rows),
        "archive_separate": all(r.get("archive_separate", False)
                                and r.get("opening_snapshot_unchanged", False) for r in rows),
        "same_archive_within_triples": all(t["equal_archive"] for t in triples),
    }
    output = {
        "status": "passed" if all(checks.values()) else "check_failed",
        "bundle": str(BUNDLE.relative_to(ROOT)),
        "frozen_source_identity": report["frozen_source_identity"],
        "requested_config_sha256": report["input_hashes"]["requested.json"],
        "checks": checks,
        "triples": triples,
        "cases": rows,
        "scope": "Independent first-release campaigns; no approval of hand counts or shared AI world",
    }
    if OUTPUT.exists():
        raise FileExistsError(OUTPUT)
    OUTPUT.write_text(json.dumps(output, indent=2) + "\n", encoding="utf-8")
    print(json.dumps({"status": output["status"], "checks": checks, "triples": triples}))


if __name__ == "__main__":
    main()
