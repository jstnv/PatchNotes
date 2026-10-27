"""Read-only source/matched-state audit; retain incomplete C unchanged."""

import json
from pathlib import Path

SIMS = Path(__file__).resolve().parent / "sims"
OUTPUT = SIMS / "rival-store-after-first-audit-20261024-v1.json"
TARGETS = {"scripted_ai", "turn_based_combat", "save_files", "multi_directional_scrolling", "branching_nodes"}


def read(path):
    return json.loads(path.read_text(encoding="utf-8"))


def summarize(arm):
    path = SIMS / f"rival-store-after-first-4417-{arm}-20261024-v8"
    run = read(path / "world-run.json")
    report = read(path / "world-report.json")
    selected = []
    for hand in report["rival_choices"]:
        if hand["request"] != "play":
            continue
        for card in hand["candidates"]:
            if card["definition"] in TARGETS and card["token"] in hand["selected_tokens"]:
                selected.append({"studio_id": hand["studio_id"], "project_id": hand["project_id"],
                                 "cycle": hand["cycle"], "feature_id": card["definition"]})
    player = None
    checkpoint = path / "world-report.json.checkpoint.json"
    if checkpoint.exists():
        state = read(checkpoint)["player"]["run"]
        games = [item["value"] for item in state["released_games"]]
        player = {"earned_units": sum(int(x["earned_units"]) for x in games),
                  "paid_units": sum(int(x["total_units"]) for x in games),
                  "settled_cents": sum(int(x["settled_cents"]) for x in games),
                  "cash_cents": int(state["cash_cents"]),
                  "fans": int(state["fanbase"]["fans"]),
                  "reviews": [int(x["review_tenths"]) for x in games]}
    return {"ok": run["ok"], "error": run.get("error", ""), "completed": report["completed"],
            "commands": report["commands"], "checks": report["checks"], "failures": report["failures"],
            "failure_reason": report["failure_reason"], "source": report["source_identity"],
            "initial_state": report["initial_state_digest"], "initial_rng": report["initial_rng"],
            "rival_releases": report["rival_release_details"],
            "store_actions": [{"studio_id": x["studio_id"], "cycle": x["cycle"], "action": x["action"]}
                              for x in report["rival_choices"] if x["action"] in ("admit_research", "research")],
            "selected_purchased": selected, "player": player,
            "cpu_seconds": run.get("world_process", {}).get("actual_process_cpu_seconds")}


def main():
    if OUTPUT.exists():
        raise SystemExit(f"refusing overwrite: {OUTPUT}")
    rows = {arm: summarize(arm) for arm in "ABC"}
    a, b, c = (rows[x] for x in "ABC")
    same = {arm: rows[arm]["initial_state"] == a["initial_state"]
            and rows[arm]["initial_rng"] == a["initial_rng"]
            and rows[arm]["source"] == a["source"] for arm in "BC"}
    deltas = {key: b["player"][key] - a["player"][key]
              for key in ("earned_units", "paid_units", "settled_cents", "cash_cents", "fans")}
    checks = {"A_B_complete": all(x["ok"] and x["completed"] and x["failures"] == 0 and x["commands"] == 144
                                   for x in (a, b)),
              "all_matched_starts": all(same.values()),
              "C_retained_incomplete": not c["ok"] and not c["completed"] and c["failure_reason"] != ""}
    OUTPUT.write_text(json.dumps({"checks": checks, "rows": rows,
                                  "matched_starts": same, "B_minus_A_player": deltas}, indent=2, sort_keys=True) + "\n",
                      encoding="utf-8")
    print(json.dumps({"checks": checks, "B_minus_A_player": deltas,
                      "B_selected_purchased": len(b["selected_purchased"]),
                      "C_reason": c["failure_reason"]}, sort_keys=True))
    if not all(checks.values()):
        raise SystemExit(1)


if __name__ == "__main__":
    main()
