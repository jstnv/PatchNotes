"""Read-only paired audit of the current-source visible-Feature exit study."""

import hashlib
import json
from pathlib import Path
from statistics import mean


HERE = Path(__file__).resolve().parent
SOURCE = "0749046f8ae3d111ec703dc5906d4bab111da9c2ec53549ae7026000ff9d6c12"
OUT = HERE / "sims" / "rival-feature-maximal-current-audit-20261024-v19.json"


def read(path):
    return json.loads(path.read_text(encoding="utf-8-sig"))


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def summarize(seed, arm):
    folder = HERE / "sims" / f"rival-feature-maximal-{seed}-{arm}-20261024-v19"
    report_path = folder / "world-report.json"
    run_path = folder / "world-run.json"
    report, run = read(report_path), read(run_path)
    assert run["ok"] and report["completed"] and report["failures"] == 0
    assert report["source_identity"] == run["expected_gameplay_source_identity"] == SOURCE
    assert report["seed"] == seed and report["arm"] == arm
    assert report["commands"] == 144 and report["source_drift"] is False
    releases = report["rival_release_details"]
    feature_hands = []
    exits = []
    observed = {}
    for row in report["rival_choices"]:
        if row["phase"] not in ("design", "alpha"):
            continue
        key = (row["studio_id"], row["project_id"], row["sequence"], row["request"])
        if key in observed:
            assert observed[key] == row["selected_tokens"]
            continue
        observed[key] = row["selected_tokens"]
        visible = sum(card["type"] == "feature" for card in row["candidates"])
        if row["request"] == "play":
            selected = set(row["selected_tokens"])
            used = [card for card in row["candidates"] if card["token"] in selected]
            assert len(used) == len(selected) == 4
            feature_hands.append({"studio": row["studio_id"], "project": row["project_id"],
                                  "cycle": row["cycle"], "phase": row["phase"],
                                  "visible_features": visible,
                                  "played_features": sum(card["type"] == "feature" for card in used),
                                  "policy_wall_us": row["policy_wall_us"]})
        elif row["request"] == "request_exit":
            exits.append({"studio": row["studio_id"], "project": row["project_id"],
                          "cycle": row["cycle"], "phase": row["phase"], "scope": row["scope"],
                          "cash_cents": row["cash_cents"], "visible_features": visible})
    if arm == "B":
        assert feature_hands and exits
        assert all(row["played_features"] == min(4, row["visible_features"]) and row["played_features"] >= 1 for row in feature_hands)
        assert all(row["visible_features"] == 0 for row in exits)
    latest_player = {}
    player_id = report["recipe"]["studio_id"]
    for row in report["observations"]:
        if row["owner"] == player_id:
            latest_player[row["release"]] = row
    reviews = [row["review_tenths"] for row in releases]
    return {"report_sha256": sha(report_path), "run_sha256": sha(run_path),
            "initial_state_digest": report["initial_state_digest"], "initial_rng": report["initial_rng"],
            "checks": report["checks"], "commands": report["commands"],
            "rival_release_count": len(releases), "reviews_tenths": reviews,
            "mean_review": mean(reviews) / 10 if reviews else None,
            "review_6_plus": sum(value >= 60 for value in reviews),
            "scope_30_plus": sum(row["scope"] >= 30 for row in releases),
            "release_cycles": [row["cycle"] for row in releases],
            "player_earned_units": sum(row["earned_units"] for row in latest_player.values()),
            "player_paid_cents": sum(row["settled_cents"] for row in latest_player.values()),
            "player_final_cash_cents": report["releases"][-1]["cash_cents"],
            "player_final_fans": report["releases"][-1]["fans"],
            "feature_hands": feature_hands, "design_alpha_exits": exits,
            "world_cpu_seconds": run["world_process"]["actual_process_cpu_seconds"],
            "world_elapsed_seconds": run["world_process"]["elapsed_seconds"],
            "checkpoint_bytes": (folder / "world-report.json.checkpoint.json").stat().st_size}


def main():
    if OUT.exists():
        raise SystemExit(f"Refusing to overwrite {OUT}")
    pairs = {}
    for seed in ("4417", "4418"):
        a, b = summarize(seed, "A"), summarize(seed, "B")
        assert a["initial_state_digest"] == b["initial_state_digest"]
        assert a["initial_rng"] == b["initial_rng"]
        pairs[seed] = {"A": a, "B": b}
    result = {"status": "COMPLETE_BOUNDED_STUDY", "source_identity": SOURCE,
              "equal_full_start_and_typed_rng": True, "pairs": pairs}
    OUT.write_text(json.dumps(result, indent=2, sort_keys=True), encoding="utf-8")
    for seed, arms in pairs.items():
        for arm, row in arms.items():
            print(seed, arm, "titles", row["rival_release_count"], "mean", row["mean_review"],
                  "six_plus", row["review_6_plus"], "scope30", row["scope_30_plus"],
                  "player_units", row["player_earned_units"])


if __name__ == "__main__":
    main()
