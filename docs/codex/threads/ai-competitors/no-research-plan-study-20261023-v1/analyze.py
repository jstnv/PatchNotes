"""Read-only matched accounting for the predeclared no-Research A/B/C worlds."""

from __future__ import annotations

import json
from pathlib import Path

STUDY = Path(__file__).resolve().parent
SIMS = STUDY.parent / "sims"
OUT = STUDY / "analysis-v2.json"
SEEDS = ("4417", "4418")
ARMS = ("A", "B", "C")
STUDIOS = ("incumbent-arcade-foundry", "incumbent-wayfinder-works")


def read(path: Path) -> dict:
    return json.loads(path.read_text(encoding="utf-8"))


def player_totals(checkpoint: dict) -> dict:
    run = checkpoint["player"]["run"]
    games = [item["value"] for item in run["released_games"]]
    return {"cash_cents": int(run["cash_cents"]), "fans": int(run["fanbase"]["fans"]),
            "earned_units": sum(int(g["earned_units"]) for g in games),
            "paid_units": sum(int(g["total_units"]) for g in games),
            "settled_cents": sum(int(g["settled_cents"]) for g in games),
            "review_tenths": [int(g["review_tenths"]) for g in games]}


def summarize(seed: str, arm: str) -> dict:
    folder = SIMS / f"no-research-plan-{seed}-{arm}-v1"
    report = read(folder / "world-report.json")
    run = read(folder / "world-run.json")
    checkpoint = read(folder / "world-report.json.checkpoint.json")
    assert run["ok"] and report["completed"] and report["failures"] == 0
    studios = {}
    for studio_id in STUDIOS:
        releases = [r for r in report["rival_releases"] if r["studio_id"] == studio_id]
        progress = [r for r in report["rival_progress"] if r["studio_id"] == studio_id]
        # The tracer may observe the same legal rival command before and after
        # a player boundary. Count the actual unique project/phase/sequence.
        play_keys = {(r["project_id"], r["phase"], r["sequence"])
                     for r in report["rival_choices"] if r["studio_id"] == studio_id
                     and r["request"] == "play" and r["hand_revision"] == 3}
        studios[studio_id] = {
            "release_count": len(releases),
            "review_tenths": [int(r["review_tenths"]) for r in releases],
            "release_cycles": [int(r["world_cycle"]) for r in releases],
            "review_sum_tenths": sum(int(r["review_tenths"]) for r in releases),
            "best_review_tenths": max((int(r["review_tenths"]) for r in releases), default=0),
            "third_hands_by_phase": {phase: sum(key[1] == phase for key in play_keys)
                                     for phase in ("design", "alpha", "beta")},
            "final_cash_cents": progress[-1]["cash_cents"],
            "final_fans": progress[-1]["fans"],
            "final_outstanding": progress[-1]["outstanding"],
            "min_observed_cash_cents": min(int(r["cash_cents"]) for r in progress),
        }
    return {"seed": seed, "arm": arm, "source_identity": report["source_identity"],
            "initial_state_digest": report["initial_state_digest"],
            "initial_rng": report["initial_rng"], "final_state_digest": report["final"],
            "checks": report["checks"], "commands": report["commands"],
            "coverage": report["coverage"], "studios": studios,
            "player": player_totals(checkpoint),
            "world_cpu_seconds": run["world_process"]["actual_process_cpu_seconds"],
            "world_wall_seconds": run["world_process"]["elapsed_seconds"]}


def main() -> None:
    records = {seed: {arm: summarize(seed, arm) for arm in ARMS} for seed in SEEDS}
    comparison = {}
    for seed, arms in records.items():
        a = arms["A"]
        assert len({arms[arm]["initial_state_digest"] for arm in ARMS}) == 1
        assert all(arms[arm]["initial_rng"] == a["initial_rng"] for arm in ARMS)
        assert len({arms[arm]["source_identity"] for arm in ARMS}) == 1
        comparison[seed] = {}
        for arm in ("B", "C"):
            b = arms[arm]
            comparison[seed][arm] = {
                "player_total_deltas": {key: b["player"][key] - a["player"][key]
                                        for key in ("cash_cents", "fans", "earned_units", "paid_units", "settled_cents")},
                "player_review_deltas": [x-y for x, y in zip(b["player"]["review_tenths"], a["player"]["review_tenths"])],
                "studio_deltas": {sid: {
                    "release_count": b["studios"][sid]["release_count"] - a["studios"][sid]["release_count"],
                    "review_sum_tenths": b["studios"][sid]["review_sum_tenths"] - a["studios"][sid]["review_sum_tenths"],
                    "best_review_tenths": b["studios"][sid]["best_review_tenths"] - a["studios"][sid]["best_review_tenths"],
                    "final_cash_cents": b["studios"][sid]["final_cash_cents"] - a["studios"][sid]["final_cash_cents"],
                } for sid in STUDIOS}}
    control = read(SIMS / "no-research-plan-4417-control-v1" / "world-report.json")
    assert control["initial_state_digest"] == records["4417"]["A"]["initial_state_digest"]
    assert control["initial_rng"] == records["4417"]["A"]["initial_rng"]
    assert control["final"] == records["4417"]["A"]["final_state_digest"]
    assert not OUT.exists(), f"refusing overwrite: {OUT}"
    OUT.write_text(json.dumps({"status": "private DESIGN/OPEN", "records": records,
                               "comparison": comparison, "control_candidate_A_parity": True},
                              indent=2, sort_keys=True) + "\n", encoding="utf-8")
    print(json.dumps(comparison, sort_keys=True))


if __name__ == "__main__":
    main()
