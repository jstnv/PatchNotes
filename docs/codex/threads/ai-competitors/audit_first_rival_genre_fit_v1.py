"""Retrospective first-release Genre/Core arithmetic; never an AI policy."""
import argparse
import json
import math
from pathlib import Path

TARGETS = {
    "action": [40, 26, 40, 26], "adventure": [33, 26, 20, 53],
    "role_playing": [20, 26, 40, 46], "strategy": [20, 13, 53, 46],
    "simulation": [20, 20, 59, 33], "puzzle": [20, 13, 40, 59],
    "sports": [33, 33, 40, 26], "racing": [40, 33, 46, 13],
}
SPECIALTY = {"incumbent-arcade-foundry": "action", "incumbent-wayfinder-works": "adventure"}


def production(cores, targets):
    ratios = [min(1.25, max(0.0, c / t)) for c, t in zip(cores, targets)]
    mean = sum(ratios) / 4
    deviation = math.sqrt(sum((r - mean) ** 2 for r in ratios) / 4)
    return min(10.0, max(0.0, (mean - 0.5 * deviation) * 8))


def rounded_review(prod, row, variance):
    scope = min(1, row["scope"] / row["required_scope"])
    bug_factor = max(0.25, min(1, 1 - row["remaining_bugs"] / row["required_scope"]))
    value = min(10, max(0, prod * scope * bug_factor + variance))
    return math.floor(value * 10 + 0.5) / 10


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--input", type=Path, required=True)
    parser.add_argument("--output", type=Path, required=True)
    args = parser.parse_args()
    source = json.loads(args.input.read_text(encoding="utf-8"))
    rows = [r for r in source["rows"] if r["release_id"].endswith(":project:1")]
    if len(rows) != 8 or len({(r["seed"], r["rival"]) for r in rows}) != 8:
        raise ValueError("Expected exactly eight distinct first releases")
    output = []
    for row in rows:
        specialty = SPECIALTY[row["rival"]]
        if row["standards"] != TARGETS[specialty] or len(row["variance_matches"]) != 1:
            raise ValueError(f"Non-base or ambiguous actual row: {row['release_id']}")
        variance = row["variance_matches"][0]
        scores = {genre: production(row["cores"], targets) for genre, targets in TARGETS.items()}
        actual = scores[specialty]
        if abs(actual - row["production_rating"]) > 1e-9 or rounded_review(actual, row, variance) != row["review"]:
            raise ValueError(f"Actual formula mismatch: {row['release_id']}")
        rank = sorted(TARGETS, key=lambda genre: (-scores[genre], genre))
        best = rank[0]
        output.append({
            "seed": row["seed"], "rival": row["rival"], "cores": row["cores"],
            "actual_genre": specialty, "actual_review": row["review"],
            "specialty_rank_by_production": rank.index(specialty) + 1,
            "best_genre": best, "best_production": round(scores[best], 5),
            "actual_production": round(actual, 5),
            "best_minus_actual_production": round(scores[best] - actual, 5),
            "formula_only_best_review": rounded_review(scores[best], row, variance),
            "genre_productions": {g: round(s, 5) for g, s in scores.items()},
        })
    result = {"schema_version": 1, "source_identity": source["source_identity"], "method": "retrospective formula-only, no legal alternate projects", "rows": output}
    args.output.write_text(json.dumps(result, indent=2) + "\n", encoding="utf-8")
    print(json.dumps({"rows": len(output), "best_not_specialty": sum(r["best_genre"] != r["actual_genre"] for r in output), "output": str(args.output)}))


if __name__ == "__main__":
    main()
