"""Audit the declared matched first-release synergy panel and retained logs."""

import argparse
import json
from pathlib import Path


GENRES = ("action", "adventure", "puzzle", "sports")
SEEDS = ("4417", "90210")


def read(path: Path) -> dict:
    return json.loads(path.read_text(encoding="utf-8"))


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--baseline", type=Path, required=True)
    parser.add_argument("--paired", type=Path, required=True)
    parser.add_argument("--output", type=Path, required=True)
    args = parser.parse_args()
    if args.output.exists():
        raise SystemExit(f"Refusing to overwrite {args.output}")

    audits = []
    for line in (args.paired / "experiment.log").read_text(encoding="utf-8").splitlines():
        if line.startswith("G4_SYNERGY_AUDIT "):
            audits.append(json.loads(line[len("G4_SYNERGY_AUDIT ") :]))
    expected_ids = [f"{g}-{s}-{m}" for g in GENRES for s in SEEDS for m in ("reference", "synergy")]
    audit_by_id = {}
    offset = 0
    for case_id in expected_ids:
        audit_by_id[case_id] = audits[offset : offset + 4]
        offset += 4

    rows = []
    checks = []
    for genre in GENRES:
        for seed in SEEDS:
            base_id = f"{genre}-{seed}-reference"
            candidate_id = f"{genre}-{seed}-synergy"
            old = read(args.baseline / "cases" / base_id / "result.json")
            ref = read(args.paired / "cases" / base_id / "result.json")
            cand = read(args.paired / "cases" / candidate_id / "result.json")
            ref_audits = audit_by_id[base_id]
            cand_audits = audit_by_id[candidate_id]
            old_review = old["outcome"]["releases"][0]["metadata"]["review"]
            ref_review = ref["outcome"]["releases"][0]["metadata"]["review"]
            cand_review = cand["outcome"]["releases"][0]["metadata"]["review"]
            old_metrics = read(args.baseline / "cases" / base_id / "metrics.json")
            ref_metrics = read(args.paired / "cases" / base_id / "metrics.json")
            cand_metrics = read(args.paired / "cases" / candidate_id / "metrics.json")
            checks += [
                (f"{genre}/{seed} both completed", ref["ok"] and cand["ok"] and old["ok"]),
                (f"{genre}/{seed} pair initial state", ref["initial_state"] == cand["initial_state"]),
                (f"{genre}/{seed} pair initial RNG", ref["initial_rng"] == cand["initial_rng"]),
                (f"{genre}/{seed} reference initial state", old["initial_state"] == ref["initial_state"]),
                (f"{genre}/{seed} reference initial RNG", old["initial_rng"] == ref["initial_rng"]),
                (f"{genre}/{seed} reference final state", old["final_state"] == ref["final_state"]),
                (f"{genre}/{seed} reference final RNG", old["final_rng"] == ref["final_rng"]),
                (f"{genre}/{seed} reference Review", old_review["final_review"] == ref_review["final_review"]),
                (f"{genre}/{seed} four audit rows each", len(ref_audits) == 4 and len(cand_audits) == 4),
            ]
            rows.append(
                {
                    "genre": genre,
                    "seed": seed,
                    "reference_review": ref_review["final_review"],
                    "synergy_review": cand_review["final_review"],
                    "review_delta": round(cand_review["final_review"] - ref_review["final_review"], 2),
                    "reference_core": ref_review["cores"],
                    "synergy_core": cand_review["cores"],
                    "reference_scope": ref_review["scope"],
                    "synergy_scope": cand_review["scope"],
                    "reference_remaining_bugs": ref_review["remaining_bugs"],
                    "synergy_remaining_bugs": cand_review["remaining_bugs"],
                    "reference_cash_cents": ref["outcome"]["cash_cents"],
                    "synergy_cash_cents": cand["outcome"]["cash_cents"],
                    "reference_fans": ref["outcome"]["fans"],
                    "synergy_fans": cand["outcome"]["fans"],
                    "reference_available_synergy_hands": sum(a["cost_screened_synergies"] > 0 for a in ref_audits),
                    "synergy_chosen_hands": sum(a["chosen"]["synergy"] != "none" for a in cand_audits),
                    "synergy_changed_hands": sum(a["chosen"]["tokens"] != a["reference"]["tokens"] for a in cand_audits),
                    "reference_policy_us": ref_metrics["policy_and_observation_us"],
                    "synergy_policy_us": cand_metrics["policy_and_observation_us"],
                    "baseline_policy_us": old_metrics["policy_and_observation_us"],
                    "reference_audits": ref_audits,
                    "candidate_audits": cand_audits,
                }
            )
    checks.append(("64 audit rows", len(audits) == 64))
    passed = sum(ok for _, ok in checks)
    exposure = sum(row["reference_available_synergy_hands"] for row in rows)
    changed = sum(row["synergy_changed_hands"] for row in rows)
    selected = sum(row["synergy_chosen_hands"] for row in rows)
    win = sum(row["review_delta"] > 0 for row in rows)
    tie = sum(row["review_delta"] == 0 for row in rows)
    loss = sum(row["review_delta"] < 0 for row in rows)
    summary = {
        "checks_passed": passed,
        "checks_total": len(checks),
        "failures": [name for name, ok in checks if not ok],
        "reference_available_synergy_hands": exposure,
        "candidate_changed_hands": changed,
        "candidate_chosen_synergy_hands": selected,
        "review_wins_ties_losses": [win, tie, loss],
        "review_delta_mean": round(sum(row["review_delta"] for row in rows) / len(rows), 4),
        "selection_exposure_sufficient": exposure >= 4,
        "rows": rows,
    }
    args.output.mkdir(parents=True)
    (args.output / "audit.json").write_text(json.dumps(summary, indent=2) + "\n", encoding="utf-8")
    lines = [
        "# G4 synergy choice audit",
        "",
        f"Checks: {passed}/{len(checks)}; reference synergy opportunities: {exposure}/32; candidate changed hands: {changed}; chosen synergies: {selected}.",
        f"Review wins/ties/losses: {win}/{tie}/{loss}; mean delta: {summary['review_delta_mean']:+.4f}.",
        "",
        "| Genre | Seed | Reference Review | Synergy Review | Delta | Changed hands | Chosen synergies |",
        "| --- | ---: | ---: | ---: | ---: | ---: | ---: |",
    ]
    for row in rows:
        lines.append(
            f"| {row['genre']} | {row['seed']} | {row['reference_review']:.1f} | {row['synergy_review']:.1f} | {row['review_delta']:+.1f} | {row['synergy_changed_hands']} | {row['synergy_chosen_hands']} |"
        )
    if summary["failures"]:
        lines += ["", "Failures: " + "; ".join(summary["failures"])]
    (args.output / "audit.md").write_text("\n".join(lines) + "\n", encoding="utf-8")
    print(json.dumps({key: value for key, value in summary.items() if key != "rows"}))
    if summary["failures"]:
        raise SystemExit(1)


if __name__ == "__main__":
    main()
