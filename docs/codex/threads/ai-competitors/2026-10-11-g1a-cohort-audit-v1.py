"""Audit the declared G1a cohort opening bundle and one Studio continuation."""

from __future__ import annotations

import json
from pathlib import Path
import sys


ROOT = Path(__file__).resolve().parents[4]
THREAD = ROOT / "docs/codex/threads/ai-competitors"
OPENING = THREAD / "sims/g1a-cohort-current-opening-v1"
CONTINUATION = THREAD / "sims/g1a-cohort-continue-adventure-4417-v1"
OUTPUT = THREAD / "sims/g1a-cohort-audit-v1.json"


def read(path: Path):
    return json.loads(path.read_text(encoding="utf-8"))


def check(condition: bool, label: str) -> None:
    if not condition:
        raise AssertionError(label)


def one_case(folder: Path, case_id: str, candidate: bool, expected_count: int, expected_titles: tuple[str, ...]) -> dict:
    case = folder / "cases" / case_id
    result = read(case / "result.json")
    telemetry = read(case / "telemetry.json")
    checkpoint = read(case / "studio_checkpoint.json")
    run = checkpoint["studio_payload"]["run"]
    samples = telemetry["samples"]
    initial, final = samples[0], samples[-1]
    archive = run["historical_titles"]
    archive_ids = tuple(row["id"] for row in archive)
    check(result["ok"] and result["status"] == "completed", f"{case_id}: incomplete")
    check(result["commands"] <= result["max_commands"] and result["commands"] == len(samples) - 1, f"{case_id}: command budget/telemetry")
    check(all(sample.get("accepted") is True for sample in samples[1:]), f"{case_id}: command rejection")
    check(initial["run_cycle"] == 0 and int(initial["cash_cents"]) == 585000 and int(initial["fans"]) == 20, f"{case_id}: legal opening resources")
    check(initial["release_count"] == 0 and not initial["research_queue"], f"{case_id}: pre-start live/queue state")
    check(len(initial["owned_features"]) == expected_count, f"{case_id}: owned count")
    check(result["final_release_count"] == 1 and final["release_count"] == 1 and final["phase"] == "studio", f"{case_id}: first live Studio release")
    check(int(final["overdue_cents"]) == 0 and final["run_cycle"] == 11, f"{case_id}: finance/calendar")
    check({"design", "alpha", "beta"}.issubset({s["phase"] for s in samples}), f"{case_id}: phases")
    check(samples[1]["command_type"] == "begin_development" and samples[-1]["command_type"] == "launch", f"{case_id}: actual legal development/launch")
    check(archive_ids == expected_titles, f"{case_id}: frozen archive IDs")
    check(len(run["released_games"]) == 1 and len(run["release_metadata"]) == 1, f"{case_id}: live ledger count")
    live_id = final["releases"][0]["id"]
    check(live_id.endswith(":project:1") and live_id not in archive_ids, f"{case_id}: live release identity")
    for name in ("released_games", "release_metadata", "studio_finance", "fanbase"):
        serialized = json.dumps(run[name], sort_keys=True)
        check(all(id_ not in serialized for id_ in archive_ids), f"{case_id}: archive leaked to {name}")
    if candidate:
        opening = run["opening_snapshot"]
        check(opening["cash_cents"] == "585000" and opening["fans"] == "20", f"{case_id}: opening snapshot resources")
        check(opening["research_queue_empty"] and opening["familiarity_empty"], f"{case_id}: opening queue/familiarity")
        check(len(opening["owned_features"]) == expected_count and opening["historical_title_count"] == "2", f"{case_id}: snapshot inventory/archive")
        check(all(int(row["year"]) < 1980 for row in archive), f"{case_id}: archive year")
    else:
        check(not archive and not run["opening_snapshot"], f"{case_id}: control has incumbent state")
    return {
        "case_id": case_id,
        "initial_state": result["initial_state"],
        "initial_rng": result["initial_rng"],
        "commands": result["commands"],
        "cycle": final["run_cycle"],
        "owned_at_start": len(initial["owned_features"]),
        "archive_count": len(archive),
        "live_review": final["releases"][0]["review"],
        "cash_cents": final["cash_cents"],
        "fans": final["fans"],
        "arrears_cents": final["overdue_cents"],
        "state_digest": result["final_state"],
    }


def main() -> int:
    rows = []
    for genre, free_count, titles in (
        ("action", 18, ("arcade-history-1977", "arcade-history-1979")),
        ("adventure", 19, ("wayfinder-history-1976", "wayfinder-history-1979")),
    ):
        for seed in ("4417", "90210"):
            control = one_case(OPENING, f"cohort-{genre}-control-{seed}", False, free_count, ())
            candidate = one_case(OPENING, f"cohort-{genre}-candidate-{seed}", True, free_count + 3, titles)
            check(control["initial_state"] != candidate["initial_state"], f"{genre}/{seed}: unequal states must remain visible")
            rows.extend((control, candidate))

    # Continue begins at a Studio checkpoint, so audit it separately from cycle-zero recipes.
    first = read(OPENING / "cases/cohort-adventure-candidate-4417/studio_checkpoint.json")["studio_payload"]["run"]
    case = CONTINUATION / "cases/cohort-adventure-candidate-4417-next"
    result = read(case / "result.json")
    telemetry = read(case / "telemetry.json")
    run = read(case / "studio_checkpoint.json")["studio_payload"]["run"]
    check(result["ok"] and result["status"] == "completed" and result["final_release_count"] == 2, "Adventure continuation completed")
    check(result["commands"] <= 60 and all(s.get("accepted") is True for s in telemetry["samples"][1:]), "Adventure continuation legal bound")
    check(run["historical_titles"] == first["historical_titles"] and run["opening_snapshot"] == first["opening_snapshot"], "Archive/opening snapshot changed on Continue")
    check(len(run["released_games"]) == 2 and len(run["release_metadata"]) == 2, "Continuation live ledger count")
    archive_ids = [row["id"] for row in run["historical_titles"]]
    for name in ("released_games", "release_metadata", "studio_finance", "fanbase"):
        check(all(id_ not in json.dumps(run[name], sort_keys=True) for id_ in archive_ids), f"Continuation archive leaked to {name}")
    report = {
        "status": "passed",
        "opening_bundle": str(OPENING.relative_to(ROOT)),
        "continuation_bundle": str(CONTINUATION.relative_to(ROOT)),
        "opening_cases": rows,
        "continuation": {
            "case_id": result["case_id"], "commands": result["commands"],
            "final_cycle": result["final_run_cycle"], "release_count": result["final_release_count"],
            "archive_unchanged": True, "review": telemetry["samples"][-1]["releases"][-1]["review"],
        },
        "scope": "independent campaigns and one Studio-only Continue; no simultaneous AI world or balance approval",
    }
    if OUTPUT.exists():
        raise FileExistsError(OUTPUT)
    OUTPUT.write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
    print(json.dumps({"status": report["status"], "cases": len(rows), "continuation": report["continuation"]}))
    return 0


if __name__ == "__main__":
    sys.exit(main())
