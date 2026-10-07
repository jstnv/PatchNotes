"""Summarize native Sub-Areas parent/no-parent routes without changing source."""
from pathlib import Path
import csv
import gzip
import json

OUT = Path(__file__).resolve().parent
SPECIALTIES = ("action", "strategy")
SEEDS = (1104, 4417)
POLICIES = ("ordinary", "synergy")
ARMS = (("none", "none"), ("sub_areas", "levels"), ("sub_areas", "none"))


def trace_path(specialty, policy, arm, parent, seed):
    return OUT / f"route_early_{specialty}_{policy}_{arm}_fixed_after_game3_{parent}_{seed}_0.json.gz"


def cycle_state(trace, cycle):
    matches = [s for s in trace["live_cycles"] if s["cycle"] == cycle]
    return matches[-1] if matches else None


def settled(state, release_id):
    if state is None or not release_id:
        return None
    return next((s["settled_cents"] for s in state["sales"] if s["release_id"] == release_id), 0)


def join(values):
    return "/".join(map(str, values))


traces = {}
for specialty in SPECIALTIES:
    for seed in SEEDS:
        for policy in POLICIES:
            for arm, parent in ARMS:
                path = trace_path(specialty, policy, arm, parent, seed)
                traces[(specialty, seed, policy, arm, parent)] = json.loads(gzip.decompress(path.read_bytes()))

rows = []
for specialty in SPECIALTIES:
    for seed in SEEDS:
        for policy in POLICIES:
            group = [traces[(specialty, seed, policy, arm, parent)] for arm, parent in ARMS]
            common_cycle = max((d["releases"][3]["cycle"] for d in group if len(d["releases"]) >= 4), default=0) + 4
            for (arm, parent), d in zip(ARMS, group):
                purchases = [a for a in d["purchases"] if a.get("success")]
                parent_buys = [a for a in purchases if a.get("id") == "levels"]
                child_buys = [a for a in purchases if a.get("id") == "sub_areas"]
                attempts = [a for a in d["purchases"] if a.get("id") == "sub_areas" and a.get("stage") == "timing decision" and a.get("game") == 3]
                plays = [a for a in d["actions"] if "sub_areas" in a.get("selected", [])]
                supplies = [a["game"] for a in d["actions"] if "sub_areas" in a.get("eligible_supply", [])]
                draws = [a["game"] for a in d["actions"] if "sub_areas" in a.get("draw", [])]
                contract_hits = [a for a in d["actions"] if a.get("phase") == "contract" and
                                 ("sub_areas" in a.get("selected", []) or "sub_areas" in a.get("draw", []))]
                game4 = d["releases"][3] if len(d["releases"]) >= 4 else None
                matched = cycle_state(d, common_cycle) if common_cycle else None
                age4 = cycle_state(d, game4["cycle"] + 4) if game4 else None
                row = {
                    "specialty": specialty, "seed": seed, "policy": policy, "arm": arm, "parent_mode": parent,
                    "valid": d["valid"], "stop": d["stop"], "release_count": len(d["releases"]),
                    "starter_owns_levels": "levels" in d["owned_ids"],
                    "cash_at_shop_decision_cents": attempts[0]["cash_cents"] if attempts else "",
                    "parent_missing_at_decision": attempts[0]["parent_missing"] if attempts else "",
                    "initial_chain_quote_cents": attempts[0]["chain_cost_cents"] if attempts else "",
                    "parent_bought": bool(parent_buys), "parent_quote_cents": parent_buys[0]["quote"]["price_cents"] if parent_buys else "",
                    "parent_buy_cycle": parent_buys[0]["after"]["cycle"] if parent_buys else "",
                    "child_bought": bool(child_buys), "child_quote_cents": child_buys[0]["quote"]["price_cents"] if child_buys else "",
                    "child_discount_percent": child_buys[0]["quote"]["discount_percent"] if child_buys else "",
                    "child_buy_cycle": child_buys[0]["after"]["cycle"] if child_buys else "",
                    "supply_games": join(supplies), "draw_games": join(draws), "played_games": join(a["game"] for a in plays),
                    "contract_candidate_hits": len(contract_hits),
                    "release_cycles": join(r["cycle"] for r in d["releases"]),
                    "reviews": join(r["final_review"] for r in d["releases"]),
                    "scopes": join(r["scope"] for r in d["releases"]),
                    "common_cycle": common_cycle, "cash_common_cents": matched["cash_cents"] if matched else "",
                    "game4_settled_common_cents": settled(matched, game4["release_id"]) if game4 else "",
                    "game4_settled_age4_cents": settled(age4, game4["release_id"]) if game4 else "",
                    "cash_game5_launch_cents": d["final"]["cash_cents"] if len(d["releases"]) >= 5 else "",
                    "final_cash_cents": d["final"]["cash_cents"],
                    "final_unpaid_rent_cents": d["final_finance_report"]["unpaid_rent_cents"],
                    "final_credit": d["final_finance_report"]["credit"]["score"],
                    "blockers": join(b.get("reason", b.get("phase", "")) for b in d["blockers"]),
                    "errors": len(d["errors"]), "discrepancies": len(d["discrepancies"]),
                    "ledger_checks": d["ledger_checks"], "row_checks": d["row_checks"],
                }
                rows.append(row)

with (OUT / "summary.csv").open("w", newline="", encoding="utf-8") as stream:
    writer = csv.DictWriter(stream, fieldnames=list(rows[0]))
    writer.writeheader()
    writer.writerows(rows)
for row in rows:
    print(row["specialty"], row["seed"], row["policy"], row["arm"], row["parent_mode"],
          "releases", row["release_count"], "parent/child", row["parent_bought"], row["child_bought"],
          "quotes", row["parent_quote_cents"], row["child_quote_cents"], "plays", row["played_games"],
          "cash", row["cash_common_cents"], row["cash_game5_launch_cents"],
          "arrears", row["final_unpaid_rent_cents"])
