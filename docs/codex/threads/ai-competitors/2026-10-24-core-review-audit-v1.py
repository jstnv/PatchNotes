"""Read-only Core/Review decomposition of four declared, matched live worlds.

Every release in this audit was produced by ordinary legal commands. The
same-Core perfect-Scope/zero-Bug column is an optimistic mathematical bound,
not an attainable hand policy or a gameplay recommendation.
"""

import json
import math
from pathlib import Path

SIMS = Path(__file__).resolve().parent / "sims"
OUT = SIMS / "rival-core-review-audit-20261024-v9.json"
STUDIOS = ("incumbent-arcade-foundry", "incumbent-wayfinder-works")
VARIANCE = (-0.5, -0.25, 0.0, 0.25, 0.5)


def read(path):
    return json.loads(path.read_text(encoding="utf-8"))


def round_review(value):
    return math.floor(min(10.0, max(0.0, value)) * 10.0 + 0.5)


def production(cores, standards):
    ratios = [min(1.25, max(0.0, c / s)) for c, s in zip(cores, standards)]
    mean = sum(ratios) / 4
    deviation = math.sqrt(sum((r - mean) ** 2 for r in ratios) / 4)
    return min(10.0, max(0.0, mean - deviation * 0.5) * 8), ratios


def score(prod, scope, bugs, modifier, required=30):
    scope_factor = min(1.0, max(0.0, scope / required))
    bug_factor = min(1.0, max(0.25, 1.0 - bugs / required))
    return round_review(prod * scope_factor * bug_factor + modifier)


def release_row(game, project):
    cores = [int(v) for v in game["cores"]]
    standards = [int(v) for v in project["standards"]]
    base = [int(v) for v in project["details"]["base"]]
    assert len(cores) == len(standards) == len(base) == 4
    scope = int(game["scope"])
    bugs = int(game["remaining_bugs"])
    review = int(game["review_tenths"])
    prod, ratios = production(cores, standards)
    base_prod, _ = production(cores, base)
    matching_variance = [v for v in VARIANCE if score(prod, scope, bugs, v) == review]
    assert matching_variance, f"review formula mismatch: {game['release_id']}"
    matched_no_bugs = [score(prod, scope, 0, v) for v in matching_variance]
    matched_full_scope = [score(prod, 30, bugs, v) for v in matching_variance]
    matched_base_targets = [score(base_prod, scope, bugs, v) for v in matching_variance]
    optimistic = score(prod, 30, 0, 0.5)
    return {
        "studio_id": game["studio_id"], "release_id": game["release_id"],
        "cycle": int(game["cycle"]), "review_tenths": review,
        "cores": cores, "standards": standards, "base": base,
        "target_lifts": [s-b for s, b in zip(standards, base)],
        "core_shortfalls": [max(0, s-c) for s, c in zip(standards, cores)],
        "ratios": ratios, "production_rating": prod,
        "scope": scope, "required_scope": 30, "remaining_bugs": bugs,
        "scope_factor": min(1.0, scope / 30),
        "bug_factor": max(0.25, 1.0 - bugs / 30),
        "variance_compatible": matching_variance,
        "same_core_no_bugs_tenths": [min(matched_no_bugs), max(matched_no_bugs)],
        "same_core_full_scope_tenths": [min(matched_full_scope), max(matched_full_scope)],
        "same_core_base_targets_tenths": [min(matched_base_targets), max(matched_base_targets)],
        "same_core_perfect_scope_qa_best_variance_tenths": optimistic,
        "core_alone_precludes_6_even_optimistically": optimistic < 60,
    }


def world(seed, arm):
    folder = SIMS / f"rival-core-review-audit-{seed}-{arm}-20261024-v9"
    run = read(folder / "world-run.json")
    report = read(folder / "world-report.json")
    saved = read(folder / "world-report.json.checkpoint.json")
    games = [x["value"] for x in saved["player"]["run"]["released_games"]]
    details = [x for x in report["rival_release_details"] if x["studio_id"] in STUDIOS]
    releases = [release_row(g, report["projects"][g["release_id"]]) for g in details]
    observed = [x for x in report["rival_choices"] if x["project_id"] and x["phase"] in ("design", "alpha", "beta")]
    player = {
        "review_tenths": [int(x["review_tenths"]) for x in games],
        "earned_units": sum(int(x["earned_units"]) for x in games),
        "paid_units": sum(int(x["total_units"]) for x in games),
        "settled_cents": sum(int(x["settled_cents"]) for x in games),
        "cash_cents": int(saved["player"]["run"]["cash_cents"]),
        "fans": int(saved["player"]["run"]["fanbase"]["fans"]),
    }
    return {
        "ok": bool(run["ok"]), "completed": bool(report["completed"]),
        "checks": int(report["checks"]), "failures": int(report["failures"]),
        "commands": int(report["commands"]),
        "source_identity": report["source_identity"],
        "initial_state_digest": report["initial_state_digest"],
        "initial_rng": report["initial_rng"],
        "cpu_seconds": run["world_process"]["actual_process_cpu_seconds"],
        "wall_seconds": run["world_process"]["elapsed_seconds"],
        "checkpoint_bytes": (folder / "world-report.json.checkpoint.json").stat().st_size,
        "rival_releases": releases,
        "rival_reviews_at_least_60": sum(x["review_tenths"] >= 60 for x in releases),
        "core_alone_optimistic_preclusions": sum(x["core_alone_precludes_6_even_optimistically"] for x in releases),
        "frozen_target_observations": sum(bool(x["observed_standards"]) for x in observed),
        "eligible_target_observations": len(observed),
        "player": player,
    }


def main():
    if OUT.exists():
        raise SystemExit(f"refusing overwrite: {OUT}")
    rows = {seed: {arm: world(seed, arm) for arm in "AB"} for seed in ("4417", "4418")}
    checks = {}
    comparisons = {}
    for seed, arms in rows.items():
        a, b = arms["A"], arms["B"]
        checks[f"{seed}_complete"] = all(x["ok"] and x["completed"] and x["failures"] == 0 and x["commands"] == 144 for x in (a, b))
        checks[f"{seed}_matched_start"] = a["source_identity"] == b["source_identity"] and a["initial_state_digest"] == b["initial_state_digest"] and a["initial_rng"] == b["initial_rng"]
        checks[f"{seed}_candidate_minimum_cycles"] = all(
            cycle >= 10 and (i == 0 or cycle - cycles[i-1] >= 10)
            for sid in STUDIOS for cycles in ([x["cycle"] for x in b["rival_releases"] if x["studio_id"] == sid],)
            for i, cycle in enumerate(cycles)
        )
        comparisons[seed] = {
            "rival_publication_delta": len(b["rival_releases"]) - len(a["rival_releases"]),
            "player_deltas": {k: b["player"][k] - a["player"][k] for k in ("earned_units", "paid_units", "settled_cents", "cash_cents", "fans")},
        }
    checks["both_seeds_source_equal"] = rows["4417"]["A"]["source_identity"] == rows["4418"]["A"]["source_identity"]
    OUT.write_text(json.dumps({"formula": "PrimitiveReviewCalculator current frozen v9 source; 4 Core ratio cap1.25, imbalance0.5, production x8, scope/30, max(0.25,1-bugs/30), variance [-0.5,-0.25,0,0.25,0.5]", "checks": checks, "comparisons": comparisons, "rows": rows}, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    print(json.dumps({"checks": checks, "comparisons": comparisons,
                      "summary": {seed: {arm: {"rival_releases": len(row["rival_releases"]), "review_6_plus": row["rival_reviews_at_least_60"], "core_preclusions": row["core_alone_optimistic_preclusions"], "target_exposed": f"{row['frozen_target_observations']}/{row['eligible_target_observations']}"} for arm, row in arms.items()} for seed, arms in rows.items()}}, sort_keys=True))
    if not all(checks.values()):
        raise SystemExit(1)


if __name__ == "__main__":
    main()
