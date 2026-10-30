"""Compare actual player totals at Studio checkpoints after eight releases."""

import json
from pathlib import Path

SIMS = Path(__file__).resolve().parent.parent / "sims"
OUT = Path(__file__).resolve().parent / "player-final-comparison.json"


def player(seed: str, arm: str) -> dict:
    source = SIMS / f"richer-pool-action-fantasy-{seed}-{arm}-v1" / "world-report.json.checkpoint.json"
    return json.loads(source.read_text(encoding="utf-8"))["player"]["run"]


def totals(run: dict) -> dict:
    games = [row["value"] for row in run["released_games"]]
    return {"cash_cents": run["cash_cents"],
            "fans": run["fanbase"]["fans"],
            "earned_units": sum(int(game["earned_units"]) for game in games),
            "paid_units": sum(int(game["total_units"]) for game in games),
            "settled_cents": sum(int(game["settled_cents"]) for game in games),
            "review_tenths": [int(game["review_tenths"]) for game in games]}


result = {}
for seed in ("4417", "4418"):
    a, b, c = (player(seed, arm) for arm in ("A", "B", "C"))
    result[seed] = {"A": totals(a), "B": totals(b), "C": totals(c),
                    "A_B_equal": a == b, "A_C_totals_equal": totals(a) == totals(c),
                    "A_C_changed_run_fields": [key for key in a if a[key] != c[key]]}
    assert result[seed]["A_B_equal"] and result[seed]["A_C_totals_equal"]
assert not OUT.exists(), f"refusing overwrite: {OUT}"
OUT.write_text(json.dumps(result, indent=2, sort_keys=True) + "\n", encoding="utf-8")
print(json.dumps(result, sort_keys=True))
