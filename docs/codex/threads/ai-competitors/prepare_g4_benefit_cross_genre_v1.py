"""Generate the fully enumerated 48-case G4 benefit-choice follow-up."""
from __future__ import annotations

import argparse
import copy
import json
from pathlib import Path


GENRES = ("action", "adventure", "role_playing", "strategy", "simulation", "puzzle", "sports", "racing")
SEEDS = ("4417", "90210")
MODES = (("reference", "reference"), ("cheapest", "cheapest_quote"), ("benefit", "benefit_quote"))


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--base", type=Path, required=True)
    parser.add_argument("--output", type=Path, required=True)
    args = parser.parse_args()
    if args.output.exists():
        raise FileExistsError(args.output)
    base = json.loads(args.base.read_text(encoding="utf-8"))
    old_cases = {case["case_id"]: case for case in base["cases"]}
    cases = []
    for genre in GENRES:
        for seed in SEEDS:
            for suffix, mode in MODES:
                case = copy.deepcopy(old_cases[f"action-{seed}-{suffix}"])
                case["case_id"] = f"{genre}-{seed}-{suffix}"
                recipe = case["initial"]["recipe"]
                recipe["studio_id"] = f"g4-{genre}-{seed}"
                recipe["studio_name"] = f"G4 {genre.replace('_', ' ').title()} {seed}"
                recipe["specialty"] = genre
                config = case["policy"]["config"]
                config["mode"] = mode
                config["genre"] = genre
                config["name_prefix"] = f"G4 {genre.replace('_', ' ').title()}"
                if genre in ("action", "adventure"):
                    if case != old_cases[case["case_id"]]:
                        raise ValueError(f"Existing four-recipe case changed: {case['case_id']}")
                cases.append(case)
    if len(cases) != 48 or len({case["case_id"] for case in cases}) != 48:
        raise ValueError("Expected 48 distinct cases")
    args.output.write_text(json.dumps({"schema_version": "1", "policy": base["policy"], "cases": cases}, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    print(args.output.resolve())


if __name__ == "__main__":
    main()
