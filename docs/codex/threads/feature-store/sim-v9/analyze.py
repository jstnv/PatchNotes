"""Pair lower-price routes to native no-buy and $1700 controls."""
from collections import defaultdict
from pathlib import Path
import csv
import gzip
import json

OUT = Path(__file__).resolve().parent
OLD = OUT.parent / "sim-v8"


def load(folder, startup, seed, policy, arm, timing, price=None):
    stem = f"route_early_strategy_{policy}_{arm}_{timing}_none_{seed}_0_{startup}"
    if price is not None:
        stem += f"_{price}"
    return json.loads(gzip.decompress((folder / f"{stem}.json.gz").read_bytes()))


def state_at(trace, cycle):
    states = [state for state in trace["live_cycles"] if state["cycle"] == cycle]
    return states[-1] if states else None


def title_settled(state, release_id):
    if state is None:
        return None
    return next((s["settled_cents"] for s in state["sales"] if s["release_id"] == release_id), 0)


rows = []
for startup in ("trait", "legacy"):
    for seed in (1104, 4417, 2203):
        for policy in ("ordinary", "synergy"):
            control = load(OLD, startup, seed, policy, "none", "none")
            prior = load(OLD, startup, seed, policy, "sub_areas", "reserve_1000")
            for price in (120000, 145000):
                for timing in ("reserve_500", "reserve_1000"):
                    d = load(OUT, startup, seed, policy, "sub_areas", timing, price)
                    buys = [a for a in d["purchases"] if a.get("id") == "sub_areas" and a.get("success")]
                    decisions = [a for a in d["purchases"] if a.get("id") == "sub_areas" and a.get("stage") == "timing decision"]
                    plays = [a["game"] for a in d["actions"] if "sub_areas" in a.get("selected", [])]
                    supplies = [a["game"] for a in d["actions"] if "sub_areas" in a.get("eligible_supply", [])]
                    draws = [a["game"] for a in d["actions"] if "sub_areas" in a.get("draw", [])]
                    buy_game = buys[0]["game"] if buys else None
                    prefix_len = buy_game if buy_game else len(d["releases"])
                    assert [(r["cycle"], r["final_review"], r["scope"]) for r in d["releases"][:prefix_len]] == [
                        (r["cycle"], r["final_review"], r["scope"]) for r in control["releases"][:prefix_len]
                    ], (startup, seed, policy, price, timing, "pre-purchase divergence")
                    if not buys:
                        assert d["final"]["cash_cents"] == control["final"]["cash_cents"]
                    common_cycle = max((x["releases"][3]["cycle"] for x in (control, prior, d) if len(x["releases"]) >= 4), default=0) + 4
                    matched = state_at(d, common_cycle)
                    game4 = d["releases"][3] if len(d["releases"]) >= 4 else None
                    age4 = state_at(d, game4["cycle"] + 4) if game4 else None
                    arrears = d["final_finance_report"]["unpaid_rent_cents"]
                    control_arrears = control["final_finance_report"]["unpaid_rent_cents"]
                    rows.append({
                        "startup": startup, "seed": seed, "policy": policy, "price_cents": price, "floor_cents": 50000 if timing == "reserve_500" else 100000,
                        "release_count": len(d["releases"]), "stop": d["stop"],
                        "game3_decision_cash_cents": next((a["cash_cents"] for a in decisions if a["game"] == 3), ""),
                        "game4_decision_cash_cents": next((a["cash_cents"] for a in decisions if a["game"] == 4), ""),
                        "bought": bool(buys), "buy_game": buy_game or "",
                        "after_buy_cash_cents": buys[0]["after"]["cash_cents"] if buys else "",
                        "supply_games": "/".join(map(str, supplies)), "draw_games": "/".join(map(str, draws)),
                        "played_games": "/".join(map(str, plays)),
                        "game4_cycle": game4["cycle"] if game4 else "",
                        "game4_review": game4["final_review"] if game4 else "",
                        "game4_settled_age4_cents": title_settled(age4, game4["release_id"]) if game4 else "",
                        "common_cycle": common_cycle, "cash_common_cents": matched["cash_cents"] if matched else "",
                        "game4_settled_common_cents": title_settled(matched, game4["release_id"]) if game4 else "",
                        "game5_cycle": d["releases"][4]["cycle"] if len(d["releases"]) >= 5 else "",
                        "game5_review": d["releases"][4]["final_review"] if len(d["releases"]) >= 5 else "",
                        "game5_scope": d["releases"][4]["scope"] if len(d["releases"]) >= 5 else "",
                        "final_cash_cents": d["final"]["cash_cents"], "final_arrears_cents": arrears,
                        "control_final_cash_cents": control["final"]["cash_cents"],
                        "control_release_count": len(control["releases"]),
                        "extra_arrears_cents": max(0, arrears - control_arrears),
                        "earlier_block_than_control": len(d["releases"]) < len(control["releases"]),
                        "prior_1700_1000_bought": any(a.get("id") == "sub_areas" and a.get("success") for a in prior["purchases"]),
                        "final_credit": d["final_finance_report"]["credit"]["score"],
                        "blockers": "/".join(b.get("reason", b.get("phase", "")) for b in d["blockers"]),
                    })

with (OUT / "summary.csv").open("w", newline="", encoding="utf-8") as stream:
    writer = csv.DictWriter(stream, fieldnames=list(rows[0]))
    writer.writeheader()
    writer.writerows(rows)

groups = defaultdict(list)
for row in rows:
    groups[(row["startup"], row["price_cents"], row["floor_cents"])].append(row)
aggregate = []
for (startup, price, floor), group in sorted(groups.items()):
    buyers = [r for r in group if r["bought"]]
    played_buyers = [r for r in buyers if r["played_games"]]
    clean = [r for r in played_buyers if not r["extra_arrears_cents"] and not r["earlier_block_than_control"]]
    aggregate.append({"startup": startup, "price_cents": price, "floor_cents": floor,
                      "routes": len(group), "buyers": len(buyers), "played_buyers": len(played_buyers),
                      "clean_played_buyers": len(clean),
                      "extra_arrears_routes": sum(bool(r["extra_arrears_cents"]) for r in group),
                      "earlier_block_routes": sum(bool(r["earlier_block_than_control"]) for r in group),
                      "five_release_routes": sum(r["release_count"] == 5 for r in group),
                      "buy_after_game3": sum(r["buy_game"] == 3 for r in buyers),
                      "buy_after_game4": sum(r["buy_game"] == 4 for r in buyers)})
(OUT / "aggregate.json").write_text(json.dumps(aggregate, indent=2), encoding="utf-8")
for item in aggregate:
    print(item)
