"""Audit four Studio-only G4 second-release continuations."""

from __future__ import annotations

import json
from pathlib import Path


ROOT = Path(__file__).resolve().parents[4]
THREAD = ROOT / "docs/codex/threads/ai-competitors"
OPENING = THREAD / "sims/g4-choice-policy-v1"
CONTINUATION = THREAD / "sims/g4-choice-continue-v2"
OUTPUT = THREAD / "sims/g4-choice-continue-audit-v1.json"


def read(path: Path):
    return json.loads(path.read_text(encoding="utf-8"))


def main() -> None:
    rows = []
    for genre in ("action", "adventure"):
        for arm in ("medium_ref", "adaptive_rank"):
            first_id = f"cohort-{genre}-{arm}-4417"
            next_id = first_id + "-next"
            first_path = OPENING / "cases" / first_id
            next_path = CONTINUATION / "cases" / next_id
            first = read(first_path / "result.json")
            result = read(next_path / "result.json")
            samples = read(next_path / "telemetry.json")["samples"]
            first_run = read(first_path / "studio_checkpoint.json")["studio_payload"]["run"]
            run = read(next_path / "studio_checkpoint.json")["studio_payload"]["run"]
            archive_ids = [item["id"] for item in run["historical_titles"]]
            rows.append({
                "case_id": next_id,
                "ok": result["ok"], "status": result["status"], "error": result["error"],
                "commands": result["commands"], "accepted_commands": result["accepted_commands"],
                "studio_source_rng_fence": (
                    first["final_state"] == result["initial_state"]
                    and first["final_rng"] == result["initial_rng"]
                    and first["source_identity"] == result["source_identity"]
                ),
                "start_cycle": result["initial_run_cycle"],
                "end_cycle": result["final_run_cycle"],
                "release_count": result["final_release_count"],
                "second_review": samples[-1]["releases"][-1]["review"] if samples[-1]["releases"] else None,
                "first_release_id_stable": samples[0]["releases"][0]["id"] == samples[-1]["releases"][0]["id"],
                "final_cash_cents": int(samples[-1]["cash_cents"]),
                "min_transaction_cash_cents": min(int(s["transaction_cash_low_cents"]) for s in samples if s["transaction_cash_low_cents"] is not None),
                "final_overdue_cents": int(samples[-1]["overdue_cents"]),
                "final_fans": int(samples[-1]["fans"]),
                "rejections": [s["step"] for s in samples[1:] if not s["accepted"]],
                "archive_unchanged": run["historical_titles"] == first_run["historical_titles"]
                                     and run["opening_snapshot"] == first_run["opening_snapshot"],
                "archive_separate": (
                    len(archive_ids) == 2
                    and all(ident not in json.dumps(run[name], sort_keys=True)
                            for ident in archive_ids
                            for name in ("released_games", "release_metadata", "studio_finance", "fanbase"))
                ),
            })
    checks = {
        "four_declared_cases": len(rows) == 4,
        "studio_source_rng_fence": all(r["studio_source_rng_fence"] for r in rows),
        "second_studio_release": all(r["ok"] and r["status"] == "completed"
                                     and r["release_count"] == 2 and r["commands"] <= 70
                                     and r["first_release_id_stable"] for r in rows),
        "no_rejection_or_arrears": all(not r["rejections"] and r["final_overdue_cents"] == 0
                                       and r["min_transaction_cash_cents"] >= 0 for r in rows),
        "archive_unchanged_and_separate": all(r["archive_unchanged"] and r["archive_separate"] for r in rows),
    }
    report = {
        "status": "passed" if all(checks.values()) else "check_failed",
        "opening_bundle": str(OPENING.relative_to(ROOT)),
        "continuation_bundle": str(CONTINUATION.relative_to(ROOT)),
        "checks": checks, "cases": rows,
        "scope": "Four Studio-only second releases; no shared world or AI policy approval",
    }
    if OUTPUT.exists():
        raise FileExistsError(OUTPUT)
    OUTPUT.write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
    print(json.dumps({"status": report["status"], "checks": checks, "cases": rows}))


if __name__ == "__main__":
    main()
