"""Exact route-selection overlay for a full-chain affordability guard."""
from pathlib import Path
import csv
import gzip
import json

OUT = Path(__file__).resolve().parent
ROWS = list(csv.DictReader((OUT / "summary.csv").open(newline="")))
groups = {}
for row in ROWS:
    key = (row["specialty"], row["seed"], row["policy"])
    groups.setdefault(key, {})[(row["arm"], row["parent_mode"])] = row


def trace(row):
    name = (f'route_early_{row["specialty"]}_{row["policy"]}_{row["arm"]}_'
            f'fixed_after_game3_{row["parent_mode"]}_{row["seed"]}_0.json.gz')
    return json.loads(gzip.decompress((OUT / name).read_bytes()))


out = []
for (specialty, seed, policy), arms in groups.items():
    control = arms[("none", "none")]
    parent = arms[("sub_areas", "levels")]
    open_arm = arms[("sub_areas", "none")]
    native = {"control": trace(control), "parent": trace(parent), "open": trace(open_arm)}
    for d in native.values():
        assert len(d["releases"]) >= 3
    # Before the fixed post-Game-3 shopping choice, all three native routes match.
    prefix = lambda d: [(r["cycle"], r["final_review"], r["cash_cents"]) for r in d["releases"][:3]]
    assert prefix(native["control"]) == prefix(native["parent"]) == prefix(native["open"])
    assert parent["cash_at_shop_decision_cents"] == open_arm["cash_at_shop_decision_cents"]
    cash = int(parent["cash_at_shop_decision_cents"])
    chain = int(parent["initial_chain_quote_cents"])
    eligible = cash >= chain
    chosen = parent if eligible else control
    out.append({"specialty": specialty, "seed": seed, "policy": policy,
                "cash_at_shop_cents": cash, "parent_chain_quote_cents": chain,
                "full_chain_affordable": eligible,
                "guarded_parent_route": "parent" if eligible else "control (abstain)",
                "guarded_child_bought": chosen["child_bought"],
                "guarded_played_games": chosen["played_games"],
                "guarded_releases": chosen["release_count"],
                "guarded_unpaid_rent_cents": chosen["final_unpaid_rent_cents"],
                "open_child_bought": open_arm["child_bought"],
                "open_played_games": open_arm["played_games"],
                "open_releases": open_arm["release_count"],
                "open_unpaid_rent_cents": open_arm["final_unpaid_rent_cents"]})

with (OUT / "chain_guard.csv").open("w", newline="", encoding="utf-8") as stream:
    writer = csv.DictWriter(stream, fieldnames=list(out[0]))
    writer.writeheader()
    writer.writerows(out)
for row in out:
    print(row["specialty"], row["seed"], row["policy"],
          "cash/chain", row["cash_at_shop_cents"], row["parent_chain_quote_cents"],
          "guard", row["guarded_parent_route"], "open_bought", row["open_child_bought"])
