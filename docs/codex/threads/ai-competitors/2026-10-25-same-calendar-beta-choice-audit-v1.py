"""Read-only paired audit of the frozen public-QA Beta choice study."""

from __future__ import annotations

import json
from pathlib import Path


ROOT = Path(__file__).resolve().parent
SIMS = ROOT / "sims"
OUT = SIMS / "rival-beta-public-qa-audit-20261025-v1.json"
NAMES = {
    "4417": ("rival-beta-shadow-4417-20261025-v1", "rival-beta-public-qa-4417-20261025-v1"),
    "4418": ("rival-beta-shadow-4418-20261025-v1", "rival-beta-public-qa-4418-20261025-v1"),
}


def read(name: str) -> tuple[dict, dict]:
    folder = SIMS / name
    return (json.loads((folder / "world-report.json").read_text(encoding="utf-8")),
            json.loads((folder / "world-run.json").read_text(encoding="utf-8")))


def earned_at_boundary(report: dict, owner: str) -> dict:
    latest: dict[str, dict] = {}
    for item in report["observations"]:
        if item["owner"] == owner and item["cycle"] <= 56:
            key = item["release"]
            if key not in latest or item["cycle"] >= latest[key]["cycle"]:
                latest[key] = item
    return {
        "earned_units": sum(int(item["earned_units"]) for item in latest.values()),
        "settled_cents": sum(int(item["settled_cents"]) for item in latest.values()),
    }


def beta_cards(report: dict) -> dict:
    totals = {"hands": 0, "search": 0, "debug": 0, "marketing_cards": 0,
              "insider_cards": 0, "marketing_output_proxy": 0, "playtest_payout_cards": 0}
    for choice in report["rival_choices"]:
        if choice["phase"] != "beta" or choice["request"] != "play":
            continue
        selected = set(choice["selected_tokens"])
        cards = [card for card in choice["candidates"] if card["token"] in selected]
        assert len(cards) == 4 and len(selected) == 4
        totals["hands"] += 1
        qa = [card for card in cards if card["beta_category"] == "qa"]
        marketing = [card for card in cards if card["beta_category"] == "marketing"]
        insider = [card for card in cards if card["beta_category"] == "insider"]
        totals["search"] += sum(card["qa_operation"] == "search" for card in qa)
        totals["debug"] += sum(card["qa_operation"] == "debug" for card in qa)
        totals["marketing_cards"] += len(marketing)
        totals["insider_cards"] += len(insider)
        totals["playtest_payout_cards"] += sum(card["definition"] == "playtest_rival_games" for card in cards)
        raw = sum(int(card["beta_value"]) for card in marketing)
        if len(marketing) == 4:
            raw = int(raw * 1.5)
        elif len(qa) == 2 and len(marketing) == 1 and len(insider) == 1:
            raw = (raw * 5 + 3) // 4
        totals["marketing_output_proxy"] += raw
    return totals


def summary(report: dict, run: dict) -> dict:
    rivals = [row for row in report["rival_release_details"] if row["cycle"] <= 56]
    release_index = {row["release_id"]: row for row in rivals}
    player = report["recipe"]["studio_id"]
    owners = sorted({row["studio_id"] for row in rivals})
    return {
        "ok": bool(run["ok"]) and bool(report["completed"]) and report["failures"] == 0,
        "source_identity": report["source_identity"],
        "checks": report["checks"],
        "commands": report["commands"],
        "initial_state_digest": report["initial_state_digest"],
        "initial_rng": report["initial_rng"],
        "releases": {key: {"cycle": row["cycle"], "review_tenths": row["review_tenths"],
                           "remaining_bugs": row["remaining_bugs"]} for key, row in release_index.items()},
        "release_count": len(rivals),
        "review_6_count": sum(row["review_tenths"] >= 60 for row in rivals),
        "review_7_count": sum(row["review_tenths"] >= 70 for row in rivals),
        "review_tenths_sum": sum(row["review_tenths"] for row in rivals),
        "remaining_bugs_sum": sum(row["remaining_bugs"] for row in rivals),
        "player": earned_at_boundary(report, player),
        "rivals": {owner: earned_at_boundary(report, owner) for owner in owners},
        "beta": beta_cards(report),
        "player_market": {row["id"]: row["market_details"] for row in report["releases"]},
        "checkpoint_bytes": (SIMS / run["output"]).stat().st_size if "output" in run else None,
        "wall_seconds": run.get("elapsed_seconds"),
        "process_cpu_seconds": run.get("actual_process_cpu_seconds"),
    }


def main() -> None:
    rows = {}
    integrity = True
    improved_six = 0
    no_count_loss = True
    no_player_unit_increase = True
    for seed, names in NAMES.items():
        control, control_run = read(names[0])
        candidate, candidate_run = read(names[1])
        a, b = summary(control, control_run), summary(candidate, candidate_run)
        same_start = a["initial_state_digest"] == b["initial_state_digest"] and a["initial_rng"] == b["initial_rng"]
        same_dates = (set(a["releases"]) == set(b["releases"]) and
                      all(a["releases"][key]["cycle"] == b["releases"][key]["cycle"] for key in a["releases"]))
        same_market = a["player_market"] == b["player_market"]
        integrity &= a["ok"] and b["ok"] and same_start and same_dates and a["commands"] == b["commands"]
        improved_six += b["review_6_count"] - a["review_6_count"]
        no_count_loss &= b["release_count"] >= a["release_count"]
        no_player_unit_increase &= b["player"]["earned_units"] <= a["player"]["earned_units"]
        for record in (a, b):
            record.pop("initial_rng")
            record.pop("player_market")
        rows[seed] = {"same_start_state_and_rng": same_start, "same_publication_dates": same_dates,
                      "same_player_market_snapshots": same_market, "control": a, "candidate": b}
    result = {"integrity_pass": integrity,
              "exploratory_screen_pass": integrity and improved_six >= 1 and no_count_loss and no_player_unit_increase,
              "additional_review_6_titles": improved_six, "seeds": rows}
    OUT.write_text(json.dumps(result, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    print(json.dumps({"output": str(OUT), "integrity_pass": result["integrity_pass"],
                      "exploratory_screen_pass": result["exploratory_screen_pass"],
                      "additional_review_6_titles": improved_six}))
    if not integrity:
        raise SystemExit(1)


if __name__ == "__main__":
    main()
