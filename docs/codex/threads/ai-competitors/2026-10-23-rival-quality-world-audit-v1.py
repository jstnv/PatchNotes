"""Read-only matched accounting for the private interleaved world A/B study."""

import json
from pathlib import Path

THREAD = Path(__file__).resolve().parent
SIMS = THREAD / "sims"
OUTPUT = SIMS / "rival-quality-world-audit-20261023-v1.json"
STUDIOS = ("incumbent-arcade-foundry", "incumbent-wayfinder-works")


def read(path):
    return json.loads(path.read_text(encoding="utf-8"))


def summarize(seed, arm):
    folder = SIMS / f"rival-quality-world-{seed}-{arm}-v1"
    run = read(folder / "world-run.json")
    report = read(folder / "world-report.json") if (folder / "world-report.json").is_file() else {}
    row = {"seed": seed, "arm": arm, "ok": run["ok"], "error": run.get("error", ""),
           "source_identity": report.get("source_identity"),
           "initial_state": report.get("initial_state_digest"), "initial_rng": report.get("initial_rng"),
           "completed": report.get("completed"), "checks": report.get("checks"), "failures": report.get("failures"),
           "commands": report.get("commands"), "world_cycle": report.get("world_cycle"),
           "coverage": report.get("coverage"),
           "cpu_seconds": run.get("world_process", {}).get("actual_process_cpu_seconds"),
           "wall_seconds": run.get("world_process", {}).get("elapsed_seconds"),
           "studios": {}}
    for sid in STUDIOS:
        releases = [r for r in report.get("rival_releases", []) if r["studio_id"] == sid]
        details = [r for r in report.get("rival_release_details", []) if r["studio_id"] == sid]
        progress = [r for r in report.get("rival_progress", []) if r["studio_id"] == sid]
        row["studios"][sid] = {"count": len(releases),
                                "cycles": [int(r["world_cycle"]) for r in releases],
                                "review_tenths": [int(r["review_tenths"]) for r in releases],
                                "cores": [r["cores"] for r in details],
                                "scope": [r["scope"] for r in details],
                                "bugs": [r["remaining_bugs"] for r in details],
                                "min_cash_cents": min((int(r["cash_cents"]) for r in progress), default=None),
                                "final_cash_cents": int(progress[-1]["cash_cents"]) if progress else None,
                                "final_outstanding": progress[-1]["outstanding"] if progress else None}
    checkpoint = folder / "world-report.json.checkpoint.json"
    if checkpoint.is_file():
        run_state = read(checkpoint)["player"]["run"]
        games = [item["value"] for item in run_state["released_games"]]
        row["player"] = {"reviews": [int(g["review_tenths"]) for g in games],
                         "cash_cents": int(run_state["cash_cents"]),
                         "fans": int(run_state["fanbase"]["fans"]),
                         "earned_units": sum(int(g["earned_units"]) for g in games),
                         "paid_units": sum(int(g["total_units"]) for g in games),
                         "settled_cents": sum(int(g["settled_cents"]) for g in games)}
    return row


def main():
    assert not OUTPUT.exists(), f"refusing overwrite: {OUTPUT}"
    rows = {seed: {arm: summarize(seed, arm) for arm in ("A", "B")} for seed in ("4417", "4418")}
    comparisons = {}
    for seed, arms in rows.items():
        a, b = arms["A"], arms["B"]
        comparisons[seed] = {"equal_initial_state": a["initial_state"] == b["initial_state"],
                             "equal_initial_rng": a["initial_rng"] == b["initial_rng"],
                             "equal_source": a["source_identity"] == b["source_identity"],
                             "player_deltas": {k: b.get("player", {}).get(k, 0) - a.get("player", {}).get(k, 0)
                                               for k in ("cash_cents", "fans", "earned_units", "paid_units", "settled_cents")},
                             "rival_release_count_deltas": {sid: b["studios"][sid]["count"] - a["studios"][sid]["count"]
                                                            for sid in STUDIOS}}
    checks = {"four_complete_worlds": all(r["ok"] and r["completed"] and r["failures"] == 0 for x in rows.values() for r in x.values()),
              "matched_starts": all(c["equal_initial_state"] and c["equal_initial_rng"] and c["equal_source"] for c in comparisons.values())}
    OUTPUT.write_text(json.dumps({"checks": checks, "rows": rows, "comparisons": comparisons}, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    print(json.dumps({"checks": checks, "comparisons": comparisons}, sort_keys=True))
    if not all(checks.values()):
        raise SystemExit(1)


if __name__ == "__main__":
    main()
