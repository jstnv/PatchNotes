"""Audit the declared three-arm draw-priority first-release panel."""

import argparse
import json
from pathlib import Path


GENRES = ("action", "adventure", "puzzle", "sports")
SEEDS = ("4417", "90210")
MODES = ("reference", "synergy", "synergy_focus")


def read(path: Path) -> dict:
    return json.loads(path.read_text(encoding="utf-8"))


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--previous", type=Path, required=True)
    parser.add_argument("--current", type=Path, required=True)
    parser.add_argument("--output", type=Path, required=True)
    args = parser.parse_args()
    if args.output.exists():
        raise SystemExit(f"Refusing to overwrite {args.output}")
    ordered_ids = [f"{genre}-{seed}-{mode}" for genre in GENRES for seed in SEEDS for mode in MODES]
    synergy_audits = []
    priority_audits = []
    for line in (args.current / "experiment.log").read_text(encoding="utf-8").splitlines():
        if line.startswith("G4_SYNERGY_AUDIT "):
            synergy_audits.append(json.loads(line[len("G4_SYNERGY_AUDIT ") :]))
        elif line.startswith("G4_PRIORITY_AUDIT "):
            priority_audits.append(json.loads(line[len("G4_PRIORITY_AUDIT ") :]))
    audits = {case_id: synergy_audits[4 * index : 4 * index + 4] for index, case_id in enumerate(ordered_ids)}
    # The focus policy observes Alpha twice: before and after its free priority command.
    checks = [("96 synergy audit rows", len(synergy_audits) == 96), ("24 priority observations", len(priority_audits) == 24)]
    rows = []
    for genre in GENRES:
        for seed in SEEDS:
            results = {mode: read(args.current / "cases" / f"{genre}-{seed}-{mode}" / "result.json") for mode in MODES}
            reviews = {mode: results[mode]["outcome"]["releases"][0]["metadata"]["review"] for mode in MODES}
            checks.append((f"{genre}/{seed} all completed", all(results[mode]["ok"] and results[mode]["final_release_count"] == 1 for mode in MODES)))
            checks.append((f"{genre}/{seed} matched initial state", len({results[mode]["initial_state"] for mode in MODES}) == 1))
            checks.append((f"{genre}/{seed} matched initial RNG", results["reference"]["initial_rng"] == results["synergy"]["initial_rng"] == results["synergy_focus"]["initial_rng"]))
            for mode in ("reference", "synergy"):
                old = read(args.previous / "cases" / f"{genre}-{seed}-{mode}" / "result.json")
                checks.append((f"{genre}/{seed}/{mode} prior final state", old["final_state"] == results[mode]["final_state"]))
                checks.append((f"{genre}/{seed}/{mode} prior final RNG", old["final_rng"] == results[mode]["final_rng"]))
                checks.append((f"{genre}/{seed}/{mode} prior outcome", old["outcome"] == results[mode]["outcome"]))
            focus_id = f"{genre}-{seed}-synergy_focus"
            focus_audits = audits[focus_id]
            checks.append((f"{genre}/{seed} four focus hand audits", len(focus_audits) == 4))
            focus_priority_rows = [a for a in priority_audits if a["run_id"] == f"g4-synergy-{genre}-{seed}"]
            checks.append((f"{genre}/{seed} three focus priority observations", len(focus_priority_rows) == 3))
            rows.append(
                {
                    "genre": genre,
                    "seed": seed,
                    "reviews": {mode: reviews[mode]["final_review"] for mode in MODES},
                    "focus_delta_vs_reference": round(reviews["synergy_focus"]["final_review"] - reviews["reference"]["final_review"], 2),
                    "focus_delta_vs_synergy": round(reviews["synergy_focus"]["final_review"] - reviews["synergy"]["final_review"], 2),
                    "cores": {mode: reviews[mode]["cores"] for mode in MODES},
                    "scopes": {mode: reviews[mode]["scope"] for mode in MODES},
                    "bugs": {mode: reviews[mode]["remaining_bugs"] for mode in MODES},
                    "cash_cents": {mode: results[mode]["outcome"]["cash_cents"] for mode in MODES},
                    "fans": {mode: results[mode]["outcome"]["fans"] for mode in MODES},
                    "available_synergy_hands": sum(a["cost_screened_synergies"] > 0 for a in focus_audits),
                    "chosen_synergy_hands": sum(a["chosen"]["synergy"] != "none" for a in focus_audits),
                    "changed_hands": sum(a["chosen"]["tokens"] != a["reference"]["tokens"] for a in focus_audits),
                    "focus_commands": results["synergy_focus"]["accepted_commands"],
                    "priority_plans": focus_priority_rows,
                }
            )
    passed = sum(ok for _, ok in checks)
    gains = sum(row["focus_delta_vs_reference"] > 0 for row in rows)
    ties = sum(row["focus_delta_vs_reference"] == 0 for row in rows)
    losses = sum(row["focus_delta_vs_reference"] < 0 for row in rows)
    summary = {
        "checks_passed": passed,
        "checks_total": len(checks),
        "failures": [label for label, ok in checks if not ok],
        "focus_review_wins_ties_losses_vs_reference": [gains, ties, losses],
        "focus_review_mean_delta_vs_reference": round(sum(row["focus_delta_vs_reference"] for row in rows) / len(rows), 4),
        "focus_available_synergy_hands": sum(row["available_synergy_hands"] for row in rows),
        "focus_chosen_synergy_hands": sum(row["chosen_synergy_hands"] for row in rows),
        "focus_changed_hands": sum(row["changed_hands"] for row in rows),
        "rows": rows,
    }
    args.output.mkdir(parents=True)
    (args.output / "audit.json").write_text(json.dumps(summary, indent=2) + "\n", encoding="utf-8")
    lines = [
        "# G4 synergy draw-priority audit",
        "",
        f"Checks: {passed}/{len(checks)}; focus Review wins/ties/losses vs current: {gains}/{ties}/{losses}; mean delta {summary['focus_review_mean_delta_vs_reference']:+.4f}.",
        f"Focus available synergies: {summary['focus_available_synergy_hands']}/32; chosen synergies: {summary['focus_chosen_synergy_hands']}; changed hands: {summary['focus_changed_hands']}.",
        "",
        "| Genre | Seed | Current | Selection only | Selection + focus | Focus delta | Focus combos |",
        "| --- | ---: | ---: | ---: | ---: | ---: | ---: |",
    ]
    for row in rows:
        lines.append(f"| {row['genre']} | {row['seed']} | {row['reviews']['reference']:.1f} | {row['reviews']['synergy']:.1f} | {row['reviews']['synergy_focus']:.1f} | {row['focus_delta_vs_reference']:+.1f} | {row['chosen_synergy_hands']} |")
    if summary["failures"]:
        lines += ["", "Failures: " + "; ".join(summary["failures"])]
    (args.output / "audit.md").write_text("\n".join(lines) + "\n", encoding="utf-8")
    print(json.dumps({key: value for key, value in summary.items() if key != "rows"}))
    if summary["failures"]:
        raise SystemExit(1)


if __name__ == "__main__":
    main()
