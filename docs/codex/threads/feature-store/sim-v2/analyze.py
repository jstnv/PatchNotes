"""Regenerate the timing-pilot summary from compressed native traces."""
from pathlib import Path
import csv
import gzip
import json

OUT = Path(__file__).resolve().parent
rows = []
for path in sorted(OUT.glob("route_*.json.gz")):
    d = json.loads(gzip.decompress(path.read_bytes()))
    candidate = {"sub_areas": "sub_areas", "background": "background_music"}.get(d["store_arm"])
    purchases = [p for p in d["purchases"] if "success" in p]
    child = [p for p in purchases if p["id"] == candidate and p["success"]]
    decisions = [p for p in d["purchases"] if p.get("stage") == "timing decision"]
    actions = d["actions"]
    draws = [a for a in actions if candidate and (candidate in a.get("draw", []) or candidate in a.get("final_draw", []))]
    plays = [a for a in actions if candidate and candidate in a.get("selected", [])]
    releases = d["releases"]
    finance = d["final_finance_report"]
    cycle_cash = [(f["cycle"], f["snapshot"].get("cash_cents")) for f in d["finance_observations"]]
    cycle_cash = [(cycle, cash) for cycle, cash in cycle_cash if isinstance(cash, int)]
    low = min([d["initial"]["cash_cents"], d["final"]["cash_cents"]] + [cash for _, cash in cycle_cash])
    row = {"specialty": d["specialty"], "policy": d["policy"], "arm": d["store_arm"],
           "timing": d["timing_policy"], "seed": d["seed"], "initial_cash_cents": d["initial"]["cash_cents"],
           "releases": len(releases), "release_cycles": "/".join(str(r["cycle"]) for r in releases),
           "reviews": "/".join(str(r["final_review"]) for r in releases),
           "stop": d["stop"], "final_cycle": d["final"]["cycle"], "final_cash_cents": d["final"]["cash_cents"],
           "cash_low_cents": low, "unpaid_rent_cents": finance.get("unpaid_rent_cents"),
           "credit": finance.get("credit", {}).get("score"),
           "candidate_purchase_game": child[0]["game"] if child else "",
           "candidate_purchase_cycle": child[0]["after"]["cycle"] if child else "",
           "parent_purchase": "/".join(str(p["id"]) for p in purchases if p["id"] != candidate and p["success"]),
           "decision_chain_quotes_cents": "/".join(str(p["chain_cost_cents"]) for p in decisions),
           "decision_cash_cents": "/".join(str(p["cash_cents"]) for p in decisions),
           "decision_eligible": "/".join(str(p["eligible"]) for p in decisions),
           "settled_at_decisions_cents": "/".join(str(p["latest_release_settled_cents"]) for p in decisions),
           "candidate_draw_hands": len(draws), "candidate_play_hands": len(plays),
           "candidate_play_games": "/".join(str(a["game"]) for a in plays),
           "purchase_failures": sum(not p["success"] for p in purchases),
           "discrepancies": len(d["discrepancies"]), "errors": len(d["errors"]),
           "block_phase": d["blockers"][-1]["phase"] if d["blockers"] else ""}
    rows.append(row)
with (OUT / "summary.csv").open("w", newline="", encoding="utf-8") as f:
    writer = csv.DictWriter(f, fieldnames=list(rows[0]))
    writer.writeheader()
    writer.writerows(rows)
for r in rows:
    print(r["specialty"], r["policy"], r["arm"], r["timing"], "releases", r["releases"],
          "stop", r["stop"], "bought game", r["candidate_purchase_game"],
          "draw/play", r["candidate_draw_hands"], r["candidate_play_hands"],
          "rent", r["unpaid_rent_cents"], "cycles", r["release_cycles"])
