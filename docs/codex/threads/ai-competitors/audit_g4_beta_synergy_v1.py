"""Audit first-release Beta choice against exact same-source and prior controls."""

import argparse
import json
from pathlib import Path


GENRES = ("action", "adventure", "puzzle", "sports")
SEEDS = ("4417", "90210")
MODES = ("reference", "synergy", "synergy_beta")


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
    case_ids = [f"{genre}-{seed}-{mode}" for genre in GENRES for seed in SEEDS for mode in MODES]
    log = (args.current / "experiment.log").read_text(encoding="utf-8")
    beta_audits = [json.loads(line[len("G4_BETA_AUDIT ") :]) for line in log.splitlines() if line.startswith("G4_BETA_AUDIT ")]
    checks = [("48 Beta audit rows", len(beta_audits) == 48)]
    by_case = {case_id: beta_audits[2 * index : 2 * index + 2] for index, case_id in enumerate(case_ids)}
    rows = []
    for genre in GENRES:
        for seed in SEEDS:
            results = {mode: read(args.current / "cases" / f"{genre}-{seed}-{mode}" / "result.json") for mode in MODES}
            checks.append((f"{genre}/{seed} all completed", all(results[m]["ok"] and results[m]["final_release_count"] == 1 for m in MODES)))
            checks.append((f"{genre}/{seed} initial full state", len({results[m]["initial_state"] for m in MODES}) == 1))
            checks.append((f"{genre}/{seed} initial RNG", results["reference"]["initial_rng"] == results["synergy"]["initial_rng"] == results["synergy_beta"]["initial_rng"]))
            for mode in ("reference", "synergy"):
                old = read(args.previous / "cases" / f"{genre}-{seed}-{mode}" / "result.json")
                for field in ("final_state", "final_rng", "outcome"):
                    checks.append((f"{genre}/{seed}/{mode} prior {field}", old[field] == results[mode][field]))
            for mode in MODES:
                case_id = f"{genre}-{seed}-{mode}"
                checks.append((f"{case_id} two Beta decisions", len(by_case[case_id]) == 2))
                checks.append((f"{case_id} no rejected commands", results[mode].get("rejected_commands", 0) == 0))
            reviews = {mode: results[mode]["outcome"]["releases"][0]["metadata"]["review"] for mode in MODES}
            candidate_audits = by_case[f"{genre}-{seed}-synergy_beta"]
            rows.append({
                "genre": genre,
                "seed": seed,
                "reviews": {mode: reviews[mode]["final_review"] for mode in MODES},
                "remaining_bugs": {mode: reviews[mode]["remaining_bugs"] for mode in MODES},
                "cores": {mode: reviews[mode]["cores"] for mode in MODES},
                "scope": {mode: reviews[mode]["scope"] for mode in MODES},
                "cash_cents": {mode: results[mode]["outcome"]["cash_cents"] for mode in MODES},
                "fans": {mode: results[mode]["outcome"]["fans"] for mode in MODES},
                "changed_beta_hands": sum(a["chosen"]["tokens"] != a["reference"]["tokens"] for a in candidate_audits),
                "chosen_beta_synergies": [a["chosen"]["kind"] for a in candidate_audits],
                "all_qa_opportunities": sum(a["all_qa_hands"] > 0 for a in candidate_audits),
                "all_marketing_opportunities": sum(a["all_marketing_hands"] > 0 for a in candidate_audits),
                "balanced_opportunities": sum(a["balanced_hands"] > 0 for a in candidate_audits),
                "robustly_useful_opportunities": sum(a["robustly_useful_hands"] > 0 for a in candidate_audits),
                "beta_audits": candidate_audits,
            })
    gains = sum(r["reviews"]["synergy_beta"] > r["reviews"]["synergy"] for r in rows)
    ties = sum(r["reviews"]["synergy_beta"] == r["reviews"]["synergy"] for r in rows)
    losses = sum(r["reviews"]["synergy_beta"] < r["reviews"]["synergy"] for r in rows)
    summary = {
        "checks_passed": sum(ok for _, ok in checks),
        "checks_total": len(checks),
        "failures": [label for label, ok in checks if not ok],
        "review_wins_ties_losses_vs_synergy": [gains, ties, losses],
        "review_mean_delta_vs_synergy": round(sum(r["reviews"]["synergy_beta"] - r["reviews"]["synergy"] for r in rows) / len(rows), 4),
        "changed_beta_hands": sum(r["changed_beta_hands"] for r in rows),
        "all_qa_opportunities": sum(r["all_qa_opportunities"] for r in rows),
        "all_marketing_opportunities": sum(r["all_marketing_opportunities"] for r in rows),
        "balanced_opportunities": sum(r["balanced_opportunities"] for r in rows),
        "robustly_useful_opportunities": sum(r["robustly_useful_opportunities"] for r in rows),
        "rows": rows,
    }
    args.output.mkdir(parents=True)
    (args.output / "audit.json").write_text(json.dumps(summary, indent=2) + "\n", encoding="utf-8")
    lines = [
        "# G4 Beta synergy choice audit", "",
        f"Checks: {summary['checks_passed']}/{summary['checks_total']}; Beta Review wins/ties/losses versus selection-only: {gains}/{ties}/{losses}; mean {summary['review_mean_delta_vs_synergy']:+.4f}.",
        f"Candidate changed {summary['changed_beta_hands']}/16 Beta hands; all-QA opportunities {summary['all_qa_opportunities']}/16; Balanced Operations {summary['balanced_opportunities']}/16; robustly useful {summary['robustly_useful_opportunities']}/16.",
        "", "| Genre | Seed | Current | Core synergy | Core + Beta synergy | Beta delta | Changed Beta | Bugs core / candidate |",
        "| --- | ---: | ---: | ---: | ---: | ---: | ---: | --- |",
    ]
    for r in rows:
        lines.append(f"| {r['genre']} | {r['seed']} | {r['reviews']['reference']:.1f} | {r['reviews']['synergy']:.1f} | {r['reviews']['synergy_beta']:.1f} | {r['reviews']['synergy_beta']-r['reviews']['synergy']:+.1f} | {r['changed_beta_hands']} | {r['remaining_bugs']['synergy']} / {r['remaining_bugs']['synergy_beta']} |")
    if summary["failures"]:
        lines += ["", "Failures: " + "; ".join(summary["failures"])]
    (args.output / "audit.md").write_text("\n".join(lines) + "\n", encoding="utf-8")
    print(json.dumps({key: value for key, value in summary.items() if key != "rows"}))
    if summary["failures"]:
        raise SystemExit(1)


if __name__ == "__main__":
    main()
