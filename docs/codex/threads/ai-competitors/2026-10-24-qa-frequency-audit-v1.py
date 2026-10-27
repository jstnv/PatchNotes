"""Read-only source/start/release/market audit of v15's declared A/B/C worlds."""

import json
from pathlib import Path

THREAD = Path(__file__).resolve().parent
SIMS = THREAD / "sims"
OUT = SIMS / "rival-qa-frequency-audit-20261024-v15.json"
ARMS = "ABC"
SEEDS = ("4417", "4418")
ORIGINAL = {"incumbent-arcade-foundry", "incumbent-wayfinder-works"}
ADDED = {"candidate-puzzle-pier", "candidate-strategy-forge"}


def read(path):
    return json.loads(path.read_text(encoding="utf-8"))


def row(seed, arm):
    folder = SIMS / f"rival-qa-frequency-{seed}-{arm}-20261024-v15"
    run = read(folder / "world-run.json")
    report = read(folder / "world-report.json")
    saved = read(folder / "world-report.json.checkpoint.json")
    games = [entry["value"] for entry in saved["player"]["run"]["released_games"]]
    rivals = report["rival_release_details"]
    redraws = {(choice["studio_id"], choice["project_id"], choice["sequence"])
               for choice in report["rival_choices"] if choice["request"] == "redraw"}
    redraw_projects = {}
    for studio, project, _ in redraws:
        key = f"{studio}/{project}"
        redraw_projects[key] = redraw_projects.get(key, 0) + 1
    releases = [{"id": item["release_id"], "studio": item["studio_id"],
                 "cycle": int(item["cycle"]), "review_tenths": int(item["review_tenths"]),
                 "scope": int(item["scope"]), "bugs": int(item["remaining_bugs"]),
                 "cores": item["cores"]} for item in rivals]
    return {
        "ok": run["ok"], "completed": report["completed"],
        "failures": report["failures"], "checks": report["checks"],
        "commands": report["commands"], "source": report["source_identity"],
        "initial_state": report["initial_state_digest"],
        "initial_rng": report["initial_rng"],
        "releases": releases, "release_count": len(releases),
        "six_plus": sum(item["review_tenths"] >= 60 for item in releases),
        "seven_plus": sum(item["review_tenths"] >= 70 for item in releases),
        "review_sum_tenths": sum(item["review_tenths"] for item in releases),
        "bugs_sum": sum(item["bugs"] for item in releases),
        "redraw_count": len(redraws), "redraw_projects": redraw_projects,
        "studios_publishing": sorted({item["studio"] for item in releases}),
        "player": {
            "earned_units": sum(int(game["earned_units"]) for game in games),
            "paid_units": sum(int(game["total_units"]) for game in games),
            "settled_cents": sum(int(game["settled_cents"]) for game in games),
            "cash_cents": int(saved["player"]["run"]["cash_cents"]),
            "fans": int(saved["player"]["run"]["fanbase"]["fans"]),
        },
        "cpu_seconds": run["world_process"]["actual_process_cpu_seconds"],
        "checkpoint_bytes": (folder / "world-report.json.checkpoint.json").stat().st_size,
        "minimum_observed_rival_cash_cents": min(int(item["cash_cents"])
            for item in report["rival_progress"]),
    }


def main():
    if OUT.exists():
        raise SystemExit(f"Refusing overwrite: {OUT}")
    rows = {seed: {arm: row(seed, arm) for arm in ARMS} for seed in SEEDS}
    checks = {}
    for seed, arms in rows.items():
        a, b, c = (arms[x] for x in ARMS)
        checks[f"{seed}_all_complete"] = all(x["ok"] and x["completed"]
            and x["failures"] == 0 and x["commands"] == 144 for x in arms.values())
        checks[f"{seed}_same_source"] = len({x["source"] for x in arms.values()}) == 1
        checks[f"{seed}_QA_equal_start_rng"] = (a["initial_state"] == b["initial_state"]
            and a["initial_rng"] == b["initial_rng"])
        checks[f"{seed}_population_start_differs"] = c["initial_state"] != a["initial_state"]
        checks[f"{seed}_QA_same_publication_dates"] = [
            (x["id"], x["cycle"]) for x in a["releases"]] == [
            (x["id"], x["cycle"]) for x in b["releases"]]
        checks[f"{seed}_QA_redraw_limit"] = (a["redraw_count"] == 0
            and all(count <= 1 for count in b["redraw_projects"].values())
            and all(count <= 1 for count in c["redraw_projects"].values()))
        checks[f"{seed}_population_actual_titles"] = (
            set(a["studios_publishing"]) == ORIGINAL
            and set(b["studios_publishing"]) == ORIGINAL
            and set(c["studios_publishing"]) == ORIGINAL | ADDED)
    output = {"checks": checks, "rows": rows,
              "comparison": {seed: {
                  "QA_B_minus_A": {"six_plus": rows[seed]["B"]["six_plus"] - rows[seed]["A"]["six_plus"],
                      "review_sum_tenths": rows[seed]["B"]["review_sum_tenths"] - rows[seed]["A"]["review_sum_tenths"],
                      "bugs_sum": rows[seed]["B"]["bugs_sum"] - rows[seed]["A"]["bugs_sum"],
                      "player_earned_units": rows[seed]["B"]["player"]["earned_units"] - rows[seed]["A"]["player"]["earned_units"]},
                  "population_C_minus_B": {"release_count": rows[seed]["C"]["release_count"] - rows[seed]["B"]["release_count"],
                      "player_earned_units": rows[seed]["C"]["player"]["earned_units"] - rows[seed]["B"]["player"]["earned_units"],
                      "player_cash_cents": rows[seed]["C"]["player"]["cash_cents"] - rows[seed]["B"]["player"]["cash_cents"]}
                  } for seed in SEEDS}}
    OUT.write_text(json.dumps(output, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    print(json.dumps({"checks": checks, "comparison": output["comparison"]}, sort_keys=True))
    if not all(checks.values()):
        raise SystemExit(1)


if __name__ == "__main__":
    main()
