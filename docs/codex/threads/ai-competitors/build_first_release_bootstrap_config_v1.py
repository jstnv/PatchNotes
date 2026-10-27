"""Build the predeclared eight-Genre, two-seed legal first-release fixture."""

from __future__ import annotations

import json
from pathlib import Path


THREAD = Path(__file__).resolve().parent
OUTPUT = THREAD / "first-release-bootstrap-config-20261026-v1.json"
GENRES = (
    "action", "adventure", "role_playing", "strategy", "simulation",
    "puzzle", "sports", "racing",
)
SEEDS = ("4417", "4423")


def main() -> None:
    if OUTPUT.exists():
        raise SystemExit(f"Preserve existing config: {OUTPUT}")
    cases = []
    for seed in SEEDS:
        for genre in GENRES:
            case_id = f"bootstrap-{genre}-{seed}"
            cases.append({
                "schema_version": "1",
                "case_id": case_id,
                "initial": {"recipe": {
                    "schema_version": 1,
                    "studio_id": case_id,
                    "studio_name": f"Bootstrap {genre} {seed}",
                    "specialty": genre,
                    "traits": [],
                    "seed": seed,
                }},
                "max_commands": 50,
                "target_release_count": 1,
                "policy": {"config": {
                    "genre": genre,
                    "theme": "fantasy",
                    "name_prefix": "First",
                    "selection": "features_first",
                    "hands": {"design": 2, "alpha": 2, "beta": 2},
                }},
            })
    config = {
        "schema_version": "1",
        "policy": {
            "script": "res://scripts/simulation/finite_fixture_policy.gd",
            "id": "first-release-bootstrap-proxy",
            "version": "1",
        },
        "cases": cases,
    }
    OUTPUT.write_text(json.dumps(config, indent=2) + "\n", encoding="utf-8")
    print(json.dumps({"output": str(OUTPUT), "cases": len(cases), "seeds": SEEDS, "genres": GENRES}))


if __name__ == "__main__":
    main()
