"""Read-only audit of v13 worlds, deduplicating repeated policy observations."""

import hashlib
import json
from pathlib import Path
from statistics import mean


HERE = Path(__file__).resolve().parent
OUTPUT = HERE / "sims" / "rival-forced-features-audit-20261024-v13-v2.json"
SOURCE = "e6e0d749bb3eed12c7a780547010f1fc00536c4d9ffbdc6ba65a8dfc3eccd1fa"


def load(path: Path):
    return json.loads(path.read_text(encoding="utf-8-sig"))


def digest(path: Path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def summarize(seed: str, arm: str):
    folder = HERE / "sims" / f"rival-forced-features-{seed}-{arm}-20261024-v13"
    report_path = folder / "world-report.json"
    run_path = folder / "world-run.json"
    report, run = load(report_path), load(run_path)
    assert run["ok"] and report["completed"] and report["failures"] == 0
    assert report["source_identity"] == SOURCE == run["expected_gameplay_source_identity"]
    assert report["seed"] == seed and report["arm"] == arm
    releases = report["rival_release_details"]
    choices = report["rival_choices"]
    feature_plays = []
    exits = []
    observed_actions = {}
    for row in choices:
        if row["phase"] not in ("design", "alpha"):
            continue
        key = (row["studio_id"], row["project_id"], row["sequence"], row["request"])
        if key in observed_actions:
            assert observed_actions[key] == row["selected_tokens"]
            continue
        observed_actions[key] = row["selected_tokens"]
        if row["request"] == "play":
            selected = set(row["selected_tokens"])
            used = [card for card in row["candidates"] if card["token"] in selected]
            assert len(used) == 4
            feature_plays.append({"studio": row["studio_id"], "project": row["project_id"],
                                  "cycle": row["cycle"], "phase": row["phase"],
                                  "visible_features": sum(card["type"] == "feature" for card in row["candidates"]),
                                  "played_features": sum(card["type"] == "feature" for card in used),
                                  "policy_wall_us": row["policy_wall_us"]})
        if row["request"] == "request_exit":
            exits.append({"studio": row["studio_id"], "project": row["project_id"],
                          "cycle": row["cycle"], "phase": row["phase"],
                          "scope": row["scope"], "cash_cents": row["cash_cents"],
                          "visible_features": sum(card["type"] == "feature" for card in row["candidates"])})
    assert all(item["played_features"] >= 1 for item in feature_plays) if arm == "B" else True
    if arm == "B":
        assert all(item["played_features"] == min(4, item["visible_features"])
                   for item in feature_plays)
        assert all(item["visible_features"] == 0 for item in exits)
    latest_player = {}
    player_id = report["recipe"]["studio_id"]
    for row in report["observations"]:
        if row["owner"] == player_id:
            latest_player[row["release"]] = row
    reviews = [row["review_tenths"] for row in releases]
    last_progress = {}
    for row in report["rival_progress"]:
        last_progress[row["studio_id"]] = row
    return {"source_identity": SOURCE, "report_sha256": digest(report_path),
            "run_sha256": digest(run_path), "initial_state_digest": report["initial_state_digest"],
            "initial_rng": report["initial_rng"], "final_digest": report["final"],
            "checks": report["checks"], "commands": report["commands"],
            "rival_release_count": len(releases), "rival_reviews_tenths": reviews,
            "mean_review": mean(reviews) / 10 if reviews else None,
            "review_6_plus": sum(value >= 60 for value in reviews),
            "scope_30_plus": sum(row["scope"] >= 30 for row in releases),
            "scopes": [row["scope"] for row in releases],
            "remaining_bugs": [row["remaining_bugs"] for row in releases],
            "release_cycles": [row["cycle"] for row in releases],
            "release_details": releases, "feature_plays": feature_plays,
            "deduplicated_observed_action_count": len(observed_actions),
            "design_alpha_exits": exits, "final_rival_progress": last_progress,
            "player_earned_units": sum(row["earned_units"] for row in latest_player.values()),
            "player_paid_cents": sum(row["settled_cents"] for row in latest_player.values()),
            "player_final_cash_cents": report["releases"][-1]["cash_cents"],
            "player_final_fans": report["releases"][-1]["fans"],
            "world_cpu_seconds": run["world_process"]["actual_process_cpu_seconds"],
            "checkpoint_bytes": (folder / "world-report.json.checkpoint.json").stat().st_size}


def main():
    if OUTPUT.exists():
        raise SystemExit(f"Refusing to overwrite {OUTPUT}")
    pairs = {}
    for seed in ("4417", "4418"):
        a, b = summarize(seed, "A"), summarize(seed, "B")
        assert a["initial_state_digest"] == b["initial_state_digest"]
        assert a["initial_rng"] == b["initial_rng"]
        pairs[seed] = {"A": a, "B": b}
    result = {"status": "COMPLETE_BOUND_EXPERIMENT", "source_identity": SOURCE,
              "paired_full_start_and_rng": True, "pairs": pairs}
    OUTPUT.write_text(json.dumps(result, indent=2, sort_keys=True), encoding="utf-8")
    for seed, pair in pairs.items():
        for arm, row in pair.items():
            print(seed, arm, "releases", row["rival_release_count"],
                  "mean", row["mean_review"], "6+", row["review_6_plus"],
                  "scope30", row["scope_30_plus"],
                  "player_units", row["player_earned_units"])


if __name__ == "__main__":
    main()
