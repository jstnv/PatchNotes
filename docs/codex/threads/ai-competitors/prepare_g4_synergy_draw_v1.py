"""Write the declared three-arm draw-priority panel."""

import argparse
import json
from pathlib import Path

from prepare_g4_synergy_study_v1 import GENRES, SEEDS, case


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--output", type=Path, required=True)
    args = parser.parse_args()
    if args.output.exists():
        raise SystemExit(f"Refusing to overwrite {args.output}")
    config = {
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
            for mode in ("reference", "synergy", "synergy_focus")
        ],
    }
    args.output.write_text(json.dumps(config, indent=2) + "\n", encoding="utf-8")
    print(f"Wrote {len(config['cases'])} draw-priority cases")


if __name__ == "__main__":
    main()
