"""Read-only matched-world audit of the private v10 Beta redraw study."""

import json
from pathlib import Path

SIMS = Path(__file__).resolve().parent / "sims"
OUT = SIMS / "rival-beta-redraw-audit-20261024-v10.json"
STUDIOS = ("incumbent-arcade-foundry", "incumbent-wayfinder-works")


def read(path):
    return json.loads(path.read_text(encoding="utf-8"))


def row(seed, arm):
    folder = SIMS / f"rival-beta-redraw-{seed}-{arm}-20261024-v10"
    run = read(folder / "world-run.json")
    report = read(folder / "world-report.json")
    saved = read(folder / "world-report.json.checkpoint.json")
    games = [x["value"] for x in saved["player"]["run"]["released_games"]]
    rival = [x for x in report["rival_release_details"] if x["studio_id"] in STUDIOS]
    redraws = [x for x in report["rival_choices"] if x["request"] == "redraw"]
    return {
        "ok": bool(run["ok"]), "completed": bool(report["completed"]),
        "checks": int(report["checks"]), "failures": int(report["failures"]),
        "commands": int(report["commands"]),
        "source": report["source_identity"],
        "initial_state": report["initial_state_digest"],
        "initial_rng": report["initial_rng"],
        "rival_releases": [{"studio_id": x["studio_id"], "cycle": int(x["cycle"]),
                            "review_tenths": int(x["review_tenths"]),
                            "cores": x["cores"], "scope": int(x["scope"]),
                            "bugs": int(x["remaining_bugs"])} for x in rival],
        "reviews_at_least_60": sum(int(x["review_tenths"]) >= 60 for x in rival),
        "review_sum_tenths": sum(int(x["review_tenths"]) for x in rival),
        "redraw_actions": len(redraws),
        "redraw_projects": sorted({x["project_id"] for x in redraws}),
        "player": {
            "earned_units": sum(int(x["earned_units"]) for x in games),
            "paid_units": sum(int(x["total_units"]) for x in games),
            "settled_cents": sum(int(x["settled_cents"]) for x in games),
            "cash_cents": int(saved["player"]["run"]["cash_cents"]),
            "fans": int(saved["player"]["run"]["fanbase"]["fans"]),
        },
        "cpu_seconds": run["world_process"]["actual_process_cpu_seconds"],
        "wall_seconds": run["world_process"]["elapsed_seconds"],
        "checkpoint_bytes": (folder / "world-report.json.checkpoint.json").stat().st_size,
    }


def main():
    if OUT.exists():
        raise SystemExit(f"refusing overwrite: {OUT}")
    rows = {seed: {arm: row(seed, arm) for arm in "AB"} for seed in ("4417", "4418")}
    checks, comparisons = {}, {}
    for seed, arms in rows.items():
        a, b = arms["A"], arms["B"]
        checks[f"{seed}_complete"] = all(x["ok"] and x["completed"] and x["failures"] == 0 and x["commands"] == 144 for x in (a, b))
        checks[f"{seed}_matched_start"] = a["source"] == b["source"] and a["initial_state"] == b["initial_state"] and a["initial_rng"] == b["initial_rng"]
        checks[f"{seed}_matched_cadence"] = [(x["studio_id"], x["cycle"]) for x in a["rival_releases"]] == [(x["studio_id"], x["cycle"]) for x in b["rival_releases"]]
        comparisons[seed] = {
            "rival_review_6_plus_delta": b["reviews_at_least_60"] - a["reviews_at_least_60"],
            "rival_review_sum_tenths_delta": b["review_sum_tenths"] - a["review_sum_tenths"],
            "player_deltas": {k: b["player"][k] - a["player"][k] for k in ("earned_units", "paid_units", "settled_cents", "cash_cents", "fans")},
        }
    checks["source_equal_across_seeds"] = rows["4417"]["A"]["source"] == rows["4418"]["A"]["source"]
    OUT.write_text(json.dumps({"checks": checks, "comparisons": comparisons, "rows": rows}, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    print(json.dumps({"checks": checks, "comparisons": comparisons,
                      "summary": {seed: {arm: {"review_6_plus": row["reviews_at_least_60"], "review_sum_tenths": row["review_sum_tenths"], "redraws": row["redraw_actions"], "cpu_seconds": row["cpu_seconds"]} for arm, row in arms.items()} for seed, arms in rows.items()}}, sort_keys=True))
    if not all(checks.values()):
        raise SystemExit(1)


if __name__ == "__main__":
    main()
