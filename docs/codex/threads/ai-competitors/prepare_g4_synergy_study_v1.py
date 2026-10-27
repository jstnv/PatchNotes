"""Write the predeclared first-release case panels without changing case bounds."""

import argparse
import json
from pathlib import Path


GENRES = ("action", "adventure", "puzzle", "sports")
SEEDS = ("4417", "90210")
HANDS = {"design": 2, "alpha": 2, "beta": 2}


def recipe(genre: str, seed: str) -> dict:
    return {
        "schema_version": 1,
        "studio_id": f"g4-synergy-{genre}-{seed}",
        "studio_name": f"G4 Synergy {genre.title()} {seed}",
        "specialty": genre,
        "traits": ["family_funding", "cult_following"],
        "seed": seed,
    }


def case(genre: str, seed: str, mode: str, paired: bool) -> dict:
    policy_config = {
        "genre": genre,
        "theme": "fantasy",
        "name_prefix": f"G4 Synergy {genre.title()}",
        "selection": "features_first",
        "hands": HANDS.copy(),
    }
    if paired:
        policy_config["mode"] = mode
    return {
        "schema_version": "1",
        "case_id": f"{genre}-{seed}-{mode}",
        "initial": {"recipe": recipe(genre, seed)},
        "max_commands": 45,
        "target_release_count": 1,
        "telemetry": True,
        "policy": {"config": policy_config},
    }


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--baseline", type=Path, required=True)
    parser.add_argument("--paired", type=Path, required=True)
    args = parser.parse_args()
    for path in (args.baseline, args.paired):
        if path.exists():
            raise SystemExit(f"Refusing to overwrite {path}")

    baseline = {
        "schema_version": "1",
        "policy": {
            "script": "res://scripts/simulation/finite_fixture_policy.gd",
            "id": "finite-development-fixture",
            "version": "1",
        },
        "cases": [case(genre, seed, "reference", False) for genre in GENRES for seed in SEEDS],
    }
    paired = {
        "schema_version": "1",
        "policy": {
            "script": "res://scripts/debug/g4_synergy_policy.gd",
            "id": "g4-synergy-choice-study",
            "version": "1",
        },
        "cases": [
            case(genre, seed, mode, True)
            for genre in GENRES
            for seed in SEEDS
            for mode in ("reference", "synergy")
        ],
    }
    args.baseline.write_text(json.dumps(baseline, indent=2) + "\n", encoding="utf-8")
    args.paired.write_text(json.dumps(paired, indent=2) + "\n", encoding="utf-8")
    print(f"Wrote {len(baseline['cases'])} baseline and {len(paired['cases'])} paired cases")


if __name__ == "__main__":
    main()
