"""Summarize delayed Strategy purchase against prior native paired routes."""
from pathlib import Path
import csv
import gzip
import json

HERE = Path(__file__).resolve().parent
OLD = HERE.parent / "sim-v6"


def load(folder, seed, policy, arm, timing):
    name = f"route_early_strategy_{policy}_{arm}_{timing}_none_{seed}_0.json.gz"
    return json.loads(gzip.decompress((folder / name).read_bytes()))


def at_cycle(trace, cycle):
    states = [s for s in trace["live_cycles"] if s["cycle"] == cycle]
    return states[-1] if states else None


def settled(state, release_id):
    if state is None:
        return None
    return next((s["settled_cents"] for s in state["sales"] if s["release_id"] == release_id), 0)


rows = []
for seed in (1104, 4417):
    for policy in ("ordinary", "synergy"):
        traces = {
            "no_buy": load(OLD, seed, policy, "none", "fixed_after_game3"),
            "after_game3": load(OLD, seed, policy, "sub_areas", "fixed_after_game3"),
            "after_game4": load(HERE, seed, policy, "sub_areas", "fixed_after_game4"),
        }
        control = traces["no_buy"]
        delayed = traces["after_game4"]
        assert [(r["cycle"], r["final_review"], r["scope"]) for r in control["releases"][:4]] == [
            (r["cycle"], r["final_review"], r["scope"]) for r in delayed["releases"][:4]
        ], (seed, policy, "pre-purchase divergence")
        common_cycle = max(t["releases"][3]["cycle"] for t in traces.values() if len(t["releases"]) >= 4) + 4
        for arm, d in traces.items():
            decision = [a for a in d["purchases"] if a.get("id") == "sub_areas" and a.get("stage") == "timing decision" and a.get("game") == 4]
            buys = [a for a in d["purchases"] if a.get("id") == "sub_areas" and a.get("success")]
            plays = [a["game"] for a in d["actions"] if "sub_areas" in a.get("selected", [])]
            supply = [a["game"] for a in d["actions"] if "sub_areas" in a.get("eligible_supply", [])]
            draws = [a["game"] for a in d["actions"] if "sub_areas" in a.get("draw", [])]
            matched = at_cycle(d, common_cycle)
            game4 = d["releases"][3]
            age4 = at_cycle(d, game4["cycle"] + 4)
            rows.append({
                "seed": seed, "policy": policy, "arm": arm, "valid": d["valid"], "stop": d["stop"],
                "release_count": len(d["releases"]), "decision_cash_cents": decision[0]["cash_cents"] if decision else "",
                "bought": bool(buys), "quote_cents": buys[0]["quote"]["price_cents"] if buys else "",
                "after_buy_cash_cents": buys[0]["after"]["cash_cents"] if buys else "",
                "buy_cycle": buys[0]["after"]["cycle"] if buys else "",
                "supply_games": "/".join(map(str, supply)), "draw_games": "/".join(map(str, draws)),
                "played_games": "/".join(map(str, plays)),
                "game4_cycle": game4["cycle"], "game4_review": game4["final_review"],
                "game4_settled_at_age4_cents": settled(age4, game4["release_id"]),
                "common_cycle": common_cycle, "cash_common_cents": matched["cash_cents"] if matched else "",
                "game4_settled_common_cents": settled(matched, game4["release_id"]),
                "game5_cycle": d["releases"][4]["cycle"] if len(d["releases"]) >= 5 else "",
                "game5_review": d["releases"][4]["final_review"] if len(d["releases"]) >= 5 else "",
                "game5_scope": d["releases"][4]["scope"] if len(d["releases"]) >= 5 else "",
                "final_cash_cents": d["final"]["cash_cents"],
                "final_arrears_cents": d["final_finance_report"]["unpaid_rent_cents"],
                "final_credit": d["final_finance_report"]["credit"]["score"],
                "blockers": "/".join(b.get("reason", b.get("phase", "")) for b in d["blockers"]),
            })

with (HERE / "summary.csv").open("w", newline="", encoding="utf-8") as stream:
    writer = csv.DictWriter(stream, fieldnames=list(rows[0]))
    writer.writeheader()
    writer.writerows(rows)
for row in rows:
    print(row["seed"], row["policy"], row["arm"], "buy", row["bought"],
          "play", row["played_games"], "releases", row["release_count"],
          "game5", row["game5_review"], row["game5_cycle"],
          "cash", row["cash_common_cents"], row["final_cash_cents"],
          "arrears", row["final_arrears_cents"])
