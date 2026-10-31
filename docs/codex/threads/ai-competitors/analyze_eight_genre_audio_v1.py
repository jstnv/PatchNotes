"""Audit the retained current-Audio rival career cohorts without changing them."""

from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path

THREAD = Path(__file__).resolve().parent
REPO = THREAD.parents[3]
SIMS = THREAD / "sims"
GENRES = ("action", "adventure", "role_playing", "strategy", "simulation", "puzzle", "sports", "racing")
SEEDS = (5607, 5613)
RETIRED = {"music", "sound_effects", "8_bit_music", "16_bit_music"}
AUDIO_NEW = ("16_bit_sound", "main_theme", "multiple_soundtracks", "instrumental_sounds", "dynamic_sequencing")
FOLDERS = {
    "v1_old_audio": "rival-eight-cyclezero-careers-20261029-v1",
    "v2_active_primitive": "rival-eight-cyclezero-audio-careers-20261029-v2",
    "v3_paid_audio": "rival-eight-cyclezero-audio-store-careers-20261029-v3",
}


def read(path: Path) -> dict | list:
    return json.loads(path.read_text(encoding="utf-8"))


def digest(value: object) -> str:
    return hashlib.sha256(json.dumps(value, sort_keys=True, separators=(",", ":")).encode()).hexdigest()


def cohort(label: str, folder: str) -> dict:
    root = SIMS / folder
    batch = read(root / "batch-report.json")
    assert batch["ok"] and len(batch["cases"]) == 16
    rows = []
    for seed in SEEDS:
        for genre in GENRES:
            case_id = f"{genre}-{seed}"
            case = next(c for c in batch["cases"] if c["case_id"] == case_id)
            assert case["ok"] and case["final_cycle"] == 72 and case["tape_saved"]
            assert all(case["source_checks"].get(key) for key in ("available", "valid", "early_rejected", "tamper_rejected", "sales_neutral"))
            data = read(root / "cases" / case_id / "prelude.json")
            assert not data["issue"] and data["final_cycle"] == 72 and data["january_boundary"]["cycle"] == 72
            reviews = [int(release["review_tenths"]) / 10 for release in data["releases"]]
            assert reviews
            assert all(release["metadata"]["review"]["scope"] >= release["metadata"]["review"]["required_scope"]
                       and release["metadata"]["review"]["remaining_bugs"] == 0 for release in data["releases"])
            paid_audio = [entry["feature_id"] for entry in data["research_entries"] if entry["feature_id"] in AUDIO_NEW
                          and len(entry["payments"]) == entry["actions"]]
            if label != "v1_old_audio":
                assert not RETIRED.intersection(data["initial"]["future_supply"])
                assert not RETIRED.intersection(data["january_boundary"]["future_supply"])
            if label == "v3_paid_audio":
                assert data["final_owned_scope"] >= 35 and "main_theme" in paid_audio
                assert genre == "sports" or "multiple_soundtracks" in paid_audio
            rows.append({"case_id": case_id, "genre": genre, "seed": seed,
                         "initial_scope": data["initial"]["owned_scope"], "january_future_scope": data["final_owned_scope"],
                         "reviews": reviews, "releases": len(reviews), "eight_plus": sum(score >= 8 for score in reviews),
                         "first_eight_cycle": next((release["cycle"] for release in data["releases"]
                                                    if release["review_tenths"] >= 80), None),
                         "cash_cents": data["final_cash_cents"], "fans": data["final_fans"],
                         "january_phase": data["january_boundary"]["phase"],
                         "paid_audio": paid_audio, "audio_owned": [feature for feature in data["final_owned_features"]
                                                              if feature in AUDIO_NEW or feature == "recorded_sounds"],
                         "loans": sum(action["type"] == "bank_borrow" for action in data["actions"]),
                         "source_identity": data["source_identity"]})
    seeds = {}
    for seed in SEEDS:
        group = [row for row in rows if row["seed"] == seed]
        games = [score for row in group for score in row["reviews"]]
        seeds[str(seed)] = {"titles": len(games), "eight_plus_titles": sum(score >= 8 for score in games),
                            "eight_plus_studios": sum(row["eight_plus"] > 0 for row in group),
                            "all_mean": round(sum(games) / len(games), 3),
                            "first_mean": round(sum(row["reviews"][0] for row in group) / len(group), 3)}
    return {"batch": folder, "batch_ok": batch["ok"], "seed_summary": seeds,
            "source_identities": sorted(set(row["source_identity"] for row in rows)), "rows": rows}


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output", type=Path, required=True)
    args = parser.parse_args()
    output = args.output.resolve()
    assert output.parent == SIMS.resolve() and not output.exists()
    current = {row["id"]: row for row in read(REPO / "patch-notes/data/feature_store_ledger.json")}
    variants = {}
    for label, folder in (("v2_active_primitive", "rival-eight-cyclezero-audio-20261029-v2"),
                          ("v3_paid_audio", "rival-eight-cyclezero-audio-store-20261029-v3")):
        rows = {row["id"]: row for row in read(THREAD / "simulators" / folder / "project/data/feature_store_ledger.json")}
        assert all(rows[feature] == current[feature] for feature in AUDIO_NEW + ("recorded_sounds",))
        variants[label] = {"candidate_audio_rows_sha256": digest([rows[feature] for feature in AUDIO_NEW + ("recorded_sounds",)]),
                           "matches_current_audio_rows": True}
    result = {"format": "ai-eight-genre-audio-comparison-v1", "source_audio_rows_sha256":
              digest([current[feature] for feature in AUDIO_NEW + ("recorded_sounds",)]),
              "variant_audio": variants,
              "cohorts": {label: cohort(label, folder) for label, folder in FOLDERS.items()}}
    output.write_text(json.dumps(result, indent=2) + "\n", encoding="utf-8")
    for label, data in result["cohorts"].items():
        print(label, data["seed_summary"])
    print("PASS: current Audio rows, 48 legal careers, 16 paid Audio paths and release/supply assertions")


if __name__ == "__main__":
    main()
