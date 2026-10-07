"""Compare legal five-release Sub-Areas follow-through at milestones and common cycles."""
from pathlib import Path
import csv
import gzip
import json

OUT = Path(__file__).resolve().parent
traces = {}
for path in sorted(OUT.glob("route_*.json.gz")):
    d = json.loads(gzip.decompress(path.read_bytes()))
    traces[(d["seed"], d["policy"], d["store_arm"])] = d


def cycle_state(d, cycle):
    matches = [x for x in d["live_cycles"] if x["cycle"] == cycle]
    return matches[-1] if matches else None


def settled_for(state, release_id):
    if state is None:
        return None
    return next((x["settled_cents"] for x in state["sales"] if x["release_id"] == release_id), 0)


rows = []
for seed in (1104, 4417):
    for policy in ("ordinary", "synergy"):
        control = traces[(seed, policy, "none")]
        trial = traces[(seed, policy, "sub_areas")]
        assert len(control["releases"]) == len(trial["releases"]) == 5
        common_cycle = max(control["releases"][3]["cycle"], trial["releases"][3]["cycle"]) + 4
        base_state = cycle_state(control, common_cycle)
        trial_state = cycle_state(trial, common_cycle)
        buys = [x for x in trial["purchases"] if x.get("id") == "sub_areas" and x.get("success")]
        plays = [x["game"] for x in trial["actions"] if "sub_areas" in x.get("selected", [])]
        row = {"seed": seed, "policy": policy, "bought": bool(buys),
               "purchase_game": buys[0]["game"] if buys else "",
               "purchase_cycle": buys[0]["after"]["cycle"] if buys else "",
               "purchase_quote_cents": buys[0]["quote"]["price_cents"] if buys else "",
               "played_games": "/".join(map(str, plays)),
               "control_reviews": "/".join(str(x["final_review"]) for x in control["releases"]),
               "trial_reviews": "/".join(str(x["final_review"]) for x in trial["releases"]),
               "control_release_cycles": "/".join(str(x["cycle"]) for x in control["releases"]),
               "trial_release_cycles": "/".join(str(x["cycle"]) for x in trial["releases"]),
               "matched_cycle": common_cycle,
               "control_cash_matched_cents": base_state["cash_cents"] if base_state else "",
               "trial_cash_matched_cents": trial_state["cash_cents"] if trial_state else "",
               "control_game4_settled_matched_cents": settled_for(base_state, control["releases"][3]["release_id"]),
               "trial_game4_settled_matched_cents": settled_for(trial_state, trial["releases"][3]["release_id"]),
               "control_game4_settled_age4_cents": settled_for(cycle_state(control, control["releases"][3]["cycle"] + 4), control["releases"][3]["release_id"]),
               "trial_game4_settled_age4_cents": settled_for(cycle_state(trial, trial["releases"][3]["cycle"] + 4), trial["releases"][3]["release_id"]),
               "control_game4_final_settled_cents": control["sales_records"][3]["settled_cents"],
               "trial_game4_final_settled_cents": trial["sales_records"][3]["settled_cents"],
               "control_cash_game5_launch_cents": control["final"]["cash_cents"],
               "trial_cash_game5_launch_cents": trial["final"]["cash_cents"],
               "control_arrears_cents": control["final_finance_report"]["unpaid_rent_cents"],
               "trial_arrears_cents": trial["final_finance_report"]["unpaid_rent_cents"],
               "control_credit": control["final_finance_report"]["credit"]["score"],
               "trial_credit": trial["final_finance_report"]["credit"]["score"]}
        rows.append(row)

with (OUT / "summary.csv").open("w", newline="", encoding="utf-8") as f:
    writer = csv.DictWriter(f, fieldnames=list(rows[0]))
    writer.writeheader()
    writer.writerows(rows)
for r in rows:
    print(r["seed"], r["policy"], "bought", r["bought"], "played", r["played_games"],
          "reviews", r["control_reviews"], "=>", r["trial_reviews"],
          "cycles", r["control_release_cycles"], "=>", r["trial_release_cycles"],
          "matched", r["matched_cycle"], r["control_cash_matched_cents"], r["trial_cash_matched_cents"],
          "G4 settled", r["control_game4_settled_matched_cents"], r["trial_game4_settled_matched_cents"],
          "G5 launch cash", r["control_cash_game5_launch_cents"], r["trial_cash_game5_launch_cents"])
