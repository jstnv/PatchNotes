"""Read-only paired Review diagnostic. Python policies are approximations, not gameplay.

Usage: python analysis/first_game_review_calibration_v1.py [seed] [per_cell]
Outputs a summary and compressed per-run rows under design-logs/. Separately compares
the archived Godot trace output to the exact current Review formula.
"""
from __future__ import annotations

import gzip
import json
import random
import statistics
import sys
from collections import Counter, defaultdict
from pathlib import Path

sys.dont_write_bytecode = True
import fanbase_playtest_v1 as old
import publisher_cash_payroll_v1 as current

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "design-logs"
GENRES = {g["id"]: g for g in old.GENRES}
POLICIES = ("conservative", "ordinary", "optimized")


def distribution(rows):
    values = sorted(r["current_review"] for r in rows)
    count = len(values)
    if not count:
        return {}
    percentile = lambda p: values[int((count - 1) * p)]
    return {
        "n": count,
        "p10": percentile(.1), "median": statistics.median(values), "p90": percentile(.9),
        "below_5_pct": round(100 * sum(v < 5 for v in values) / count, 2),
        "at_5_pct": round(100 * sum(v == 5 for v in values) / count, 2),
        "above_5_pct": round(100 * sum(v > 5 for v in values) / count, 2),
        "mean_scope": round(statistics.mean(r["scope"] for r in rows), 2),
        "mean_bugs": round(statistics.mean(r["bugs"] for r in rows), 2),
        "mean_core": [round(statistics.mean(r["cores"][core] for r in rows), 2) for core in old.CORES],
        "histogram": dict(sorted(Counter(f"{v:.1f}" for v in values).items(), key=lambda kv: float(kv[0]))),
    }


def godot_parity():
    path = OUT / "first_game_review_godot_traces_v1.json"
    fixture = json.loads(path.read_text(encoding="utf-8"))
    diffs = []
    for row in fixture["traces"]:
        if not row["valid"]:
            diffs.append({"seed": row["seed"], "reason": row["errors"]})
            continue
        scores = dict(zip(old.CORES, row["core_scores"]))
        score, rating, completion, fit, deviation = old.review(
            scores, row["scope"], row["hidden_bugs"] + row["known_bugs"],
            GENRES[row["genre"]], random.Random(0), row["variance_roll"])
        for field, expected, actual in (
            ("final_review", row["final_review"], score),
            ("production_rating", row["production_rating"], rating),
            ("scope_completion", row["scope_completion"], completion),
            ("genre_fit", row["genre_fit"], fit),
            ("genre_deviation", row["genre_deviation"], deviation),
        ):
            if abs(expected - actual) > 1e-8:
                diffs.append({"seed": row["seed"], "field": field, "godot": expected, "model": actual})
    return {"traces": len(fixture["traces"]), "invalid": fixture["failures"], "review_component_differences": diffs}


def main(seed=260927, per_cell=250):
    OUT.mkdir(exist_ok=True)
    rows = []
    for cohort, scopes in (("standard", range(20, 24)), ("below_20_opt_in", (19,))):
        for target in scopes:
            for policy_index, policy in enumerate(POLICIES):
                for index in range(per_cell):
                    case_seed = seed * 100000 + target * 10000 + policy_index * 1000 + index
                    rng = random.Random(case_seed)
                    owned, spent = old.roster(target, rng)
                    cash_initial = 5500 - spent
                    scores, scope, production_bugs, cash, redraws, synergies, played = old.production(
                        owned, policy, rng, cash_initial)
                    beta_state = rng.getstate()
                    old_bugs, old_marketing, _ = old.beta_stage(production_bugs, policy, rng)
                    rng.setstate(beta_state)
                    bugs, marketing, old_marketing_v2, marketing_special_hands = current.beta_v2(
                        production_bugs, policy, rng)
                    genre = old.choose_genre(owned, policy, rng)
                    variance_roll = rng.randrange(100)
                    review, rating, completion, fit, deviation = old.review(
                        scores, scope, bugs, genre, rng, variance_roll)
                    old_review = old.review(scores, scope, old_bugs, genre, rng, variance_roll)[0]
                    no_bugs = old.review(scores, scope, 0, genre, rng, variance_roll)[0]
                    full_scope = old.review(scores, 30, bugs, genre, rng, variance_roll)[0]
                    b_core = old.review({core: max(33, scores[core]) for core in old.CORES}, scope, bugs, genre, rng, variance_roll)[0]
                    neutral_genre = min(10, max(0, rating * completion * max(.25, 1 - bugs / 30) +
                                                (-.5 if variance_roll < 10 else -.25 if variance_roll < 30 else 0 if variance_roll < 70 else .25 if variance_roll < 90 else .5)))
                    neutral_genre = old.rnd(neutral_genre * 10) / 10
                    rows.append({
                        "cohort": cohort, "target": target, "policy": policy, "seed": case_seed,
                        "owned": sorted(owned), "starter_spend_cents": spent * 100,
                        "genre": genre["id"], "scope": scope, "cores": scores,
                        "production_bugs": production_bugs, "bugs": bugs,
                        "marketing": marketing, "marketing_special_hands": marketing_special_hands,
                        "redraws": redraws, "synergies": synergies, "production_hands": played,
                        "cash_cents": cash * 100, "rating": rating, "scope_completion": completion,
                        "genre_fit": fit, "genre_deviation": deviation, "variance_roll": variance_roll,
                        "current_review": review, "older_review": old_review,
                        "old_beta_bugs": old_bugs, "old_marketing": old_marketing,
                        "old_marketing_v2": old_marketing_v2,
                        "no_bugs_review": no_bugs, "full_scope_review": full_scope,
                        "b_core_review": b_core, "neutral_genre_review": neutral_genre,
                    })
    grouped = defaultdict(list)
    for row in rows:
        grouped[f"{row['cohort']}_{row['target']}_{row['policy']}"].append(row)
    standard = [row for row in rows if row["cohort"] == "standard"]
    low = [row for row in rows if row["cohort"] == "below_20_opt_in"]
    summary = {
        "seed": seed, "per_cell": per_cell, "n": len(rows),
        "standard": distribution(standard), "below_20_opt_in": distribution(low),
        "by_cell": {key: distribution(group) for key, group in grouped.items()},
        "paired_old_current_differences": sum(r["current_review"] != r["older_review"] for r in rows),
        "paired_old_current_bug_differences": sum(r["bugs"] != r["old_beta_bugs"] for r in rows),
        "paired_old_current_marketing_differences": sum(r["marketing"] != r["old_marketing"] for r in rows),
        "standard_mean_counterfactual_gain": {
            key: round(statistics.mean(r[key] - r["current_review"] for r in standard), 3)
            for key in ("no_bugs_review", "full_scope_review", "b_core_review", "neutral_genre_review")
        },
        "godot_review_formula_parity": godot_parity(),
    }
    (OUT / "first_game_review_calibration_v1_summary.json").write_text(json.dumps(summary, indent=2) + "\n", encoding="utf-8")
    with gzip.open(OUT / "first_game_review_calibration_v1_raw.json.gz", "wt", encoding="utf-8") as output:
        json.dump(rows, output, separators=(",", ":"))
    print(json.dumps({key: value for key, value in summary.items() if key != "by_cell"}, indent=2))
    if summary["godot_review_formula_parity"]["review_component_differences"]:
        sys.exit(1)


if __name__ == "__main__":
    main(int(sys.argv[1]) if len(sys.argv) > 1 else 260927,
         int(sys.argv[2]) if len(sys.argv) > 2 else 250)
