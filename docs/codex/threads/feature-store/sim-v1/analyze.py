"""Summarize paired native traces without changing them."""
from pathlib import Path
import csv
import gzip
import json

OUT = Path(__file__).resolve().parent
rows = []
for path in sorted(OUT.glob("route_*.json.gz")):
    d = json.loads(gzip.decompress(path.read_bytes()))
    if d.get("specialty") not in ("action", "adventure", "sports"):
        continue
    purchases = [p for p in d.get("purchases", []) if "success" in p]
    visits = d.get("studio_visits", [])
    finance = d.get("finance_observations", [])
    states = [d["initial"], d["final"]] + [v for v in visits if "cash_cents" in v]
    states += [a[k] for a in d.get("actions", []) for k in ("before", "after") if isinstance(a.get(k), dict)]
    cash = [s["cash_cents"] for s in states if isinstance(s.get("cash_cents"), (int, float))]
    cash += [f["snapshot"]["cash_cents"] for f in finance if "cash_cents" in f.get("snapshot", {})]
    releases = d.get("releases", [])
    candidate = {"sub_areas": "sub_areas", "background": "background_music"}.get(d["store_arm"])
    g2 = [a for a in d.get("actions", []) if a.get("game") == 2]
    supply = any(candidate in a.get("eligible_supply", []) for a in g2 if candidate)
    draws = sum(candidate in a.get("draw", []) or candidate in a.get("final_draw", [])
                for a in g2 if candidate)
    plays = sum(candidate in a.get("selected", []) for a in g2 if candidate)
    row = {"specialty": d["specialty"], "policy": d["policy"], "arm": d["store_arm"], "seed": d["seed"],
           "initial_cash_cents": d["initial"]["cash_cents"], "releases": len(releases), "stop": d["stop"],
           "final_cycle": d["final"]["cycle"], "final_cash_cents": d["final"]["cash_cents"],
           "cash_low_cents": min(cash), "release_cycles": "/".join(str(r["cycle"]) for r in releases),
           "review_scores": "/".join(str(r["final_review"]) for r in releases),
           "purchase_ids": "/".join(str(p["id"]) for p in purchases if p["success"]),
           "purchase_successes": sum(bool(p["success"]) for p in purchases),
           "purchase_failures": sum(not p["success"] for p in purchases),
           "candidate_game2_supply": supply, "candidate_game2_draw_hands": draws,
           "candidate_game2_play_hands": plays,
           "final_unpaid_rent_cents": d["final_finance_report"].get("unpaid_rent_cents"),
           "final_credit": d["final_finance_report"].get("credit", {}).get("score"),
           "discrepancies": len(d["discrepancies"]), "errors": len(d["errors"]),
           "block_cycle": d["blockers"][-1]["state"]["cycle"] if d.get("blockers") else None,
           "block_phase": d["blockers"][-1]["phase"] if d.get("blockers") else None,
           "block_reason": d["blockers"][-1]["reason"] if d.get("blockers") else None}
    rows.append(row)
with (OUT / "summary.csv").open("w", newline="", encoding="utf-8") as f:
    writer = csv.DictWriter(f, fieldnames=list(rows[0]))
    writer.writeheader()
    writer.writerows(rows)
for row in rows:
    print(row["specialty"], row["policy"], row["arm"], row["releases"], row["stop"],
          "low", row["cash_low_cents"], "final", row["final_cash_cents"],
          "cycles", row["release_cycles"], "reviews", row["review_scores"],
          "bought", row["purchase_ids"], "draw/play", row["candidate_game2_draw_hands"], row["candidate_game2_play_hands"],
          "arrears", row["final_unpaid_rent_cents"], "credit", row["final_credit"], "failed", row["purchase_failures"])
