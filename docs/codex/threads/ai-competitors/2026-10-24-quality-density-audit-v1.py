"""Read-only audit of the declared seed-4417 A/B/C world screen."""

import json
from pathlib import Path

SIMS = Path(__file__).resolve().parent / "sims"
OUT = SIMS / "rival-quality-density-audit-20261024-v1.json"
STUDIOS = ("incumbent-arcade-foundry", "incumbent-wayfinder-works")


def read(path):
    return json.loads(path.read_text(encoding="utf-8"))


def row(arm):
    folder = SIMS / f"rival-quality-density-4417-{arm}-20261024-v1"
    run = read(folder / "world-run.json")
    report = read(folder / "world-report.json")
    saved = read(folder / "world-report.json.checkpoint.json")
    games = [x["value"] for x in saved["player"]["run"]["released_games"]]
    studios = {}
    for sid in STUDIOS:
        details = [x for x in report["rival_release_details"] if x["studio_id"] == sid]
        progress = [x for x in report["rival_progress"] if x["studio_id"] == sid]
        studios[sid] = {
            "cycles": [int(x["cycle"]) for x in details],
            "review_tenths": [int(x["review_tenths"]) for x in details],
            "scope": [int(x["scope"]) for x in details],
            "cores": [x["cores"] for x in details],
            "remaining_bugs": [int(x["remaining_bugs"]) for x in details],
            "min_cash_cents": min((int(x["cash_cents"]) for x in progress), default=None),
            "final_cash_cents": int(progress[-1]["cash_cents"]) if progress else None,
            "final_outstanding": progress[-1]["outstanding"] if progress else None,
        }
    player = {
        "review_tenths": [int(x["review_tenths"]) for x in games],
        "earned_units": sum(int(x["earned_units"]) for x in games),
        "paid_units": sum(int(x["total_units"]) for x in games),
        "settled_cents": sum(int(x["settled_cents"]) for x in games),
        "cash_cents": int(saved["player"]["run"]["cash_cents"]),
        "fans": int(saved["player"]["run"]["fanbase"]["fans"]),
    }
    return {
        "ok": run["ok"], "completed": report["completed"],
        "checks": report["checks"], "failures": report["failures"],
        "commands": report["commands"], "source": report["source_identity"],
        "initial_state": report["initial_state_digest"], "initial_rng": report["initial_rng"],
        "cpu_seconds": run["world_process"]["actual_process_cpu_seconds"],
        "wall_seconds": run["world_process"]["elapsed_seconds"],
        "checkpoint_bytes": (folder / "world-report.json.checkpoint.json").stat().st_size,
        "studios": studios, "player": player,
    }


def main():
    if OUT.exists():
        raise SystemExit(f"refusing overwrite: {OUT}")
    rows = {arm: row(arm) for arm in "ABC"}
    a = rows["A"]
    comparisons = {}
    for arm in "BC":
        b = rows[arm]
        comparisons[arm] = {
            "equal_initial_state": b["initial_state"] == a["initial_state"],
            "equal_initial_rng": b["initial_rng"] == a["initial_rng"],
            "equal_source": b["source"] == a["source"],
            "player_deltas": {k: b["player"][k] - a["player"][k]
                              for k in ("earned_units", "paid_units", "settled_cents", "cash_cents", "fans")},
            "rival_publication_delta": sum(len(x["cycles"]) for x in b["studios"].values())
                                       - sum(len(x["cycles"]) for x in a["studios"].values()),
        }
    checks = {
        "all_complete": all(x["ok"] and x["completed"] and x["failures"] == 0 and x["commands"] == 144
                            for x in rows.values()),
        "matched_starts": all(x["equal_initial_state"] and x["equal_initial_rng"] and x["equal_source"]
                              for x in comparisons.values()),
        "candidate_minimum_cycles": all(
            all(cycle >= 10 and (index == 0 or cycle - cycles[index - 1] >= 10)
                for index, cycle in enumerate(cycles))
            for arm in "BC" for studio in rows[arm]["studios"].values()
            for cycles in (studio["cycles"],)
        ),
    }
    OUT.write_text(json.dumps({"checks": checks, "rows": rows, "comparisons": comparisons}, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    print(json.dumps({"checks": checks, "comparisons": comparisons}, sort_keys=True))
    if not all(checks.values()):
        raise SystemExit(1)


if __name__ == "__main__":
    main()
