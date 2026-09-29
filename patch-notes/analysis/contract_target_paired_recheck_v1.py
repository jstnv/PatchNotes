"""Task 15 read-only matched rescore and fresh legal-pool draw analysis.

python -B analysis/contract_target_paired_recheck_v1.py
Proposed offers remain absent from gameplay; model draws use Python's PRNG.
"""
from __future__ import annotations

import gzip
import json
import statistics
from collections import Counter
from pathlib import Path

import remaining_publisher_contracts_rebaseline_v1 as base

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "design-logs"
CORES = base.CORES
CROWN_SCOPES = (8, 9, 10, 12)
CROWN_CORES = (3, 4, 5, 6)
NEON_SCOPES = (9, 10, 11, 12)
NEON_FOCUS_CORES = (8, 9, 10)


def score(name, scope, half, focus, target_scope, target_core):
    if name == "crown":
        cap = target_core * 2
        values = [min(half[c], cap) for c in CORES]
        return 2 * min(scope, target_scope) + sum(values) + 2 * min(values), 2 * target_scope + 6 * cap
    assert name == "neon"
    cap = target_core * 2
    return (2 * min(scope, target_scope) + 3 * min(half[focus], cap)
            + sum(min(half[c], 4) for c in CORES if c != focus),
            2 * target_scope + 3 * cap + 12)


def limiting(name, offer, target_scope, target_core):
    missing = {"scope": max(0, target_scope - offer["scope"])}
    for c in CORES:
        target_half = target_core * 2 if name == "crown" or c == offer["focus"] else 4
        missing[c] = max(0, target_half - offer["half_core"][c])
    return missing


def rescore(offer, target_scope, target_core, group, policy, case, seed, live_unlocked):
    name = offer["name"]
    n, d = score(name, offer["scope"], offer["half_core"], offer["focus"], target_scope, target_core)
    cash_cap, promo_cap = base.CAPS[name]
    limits = limiting(name, offer, target_scope, target_core)
    return {"group": group, "policy": policy, "case": case, "seed": seed, "offer": name,
            "live_unlocked": live_unlocked, "target_scope": target_scope, "target_core": target_core,
            "denominator": d, "numerator": n, "completion_percent": 100 * n / d,
            "cash_cents": cash_cap * n // d, "promotion_points": promo_cap * n // d,
            "full": n == d, "limiting": limits, "focus": offer["focus"],
            "owned_primitive_count": len(offer["owned_at_accept"]), "scope": offer["scope"],
            "half_core": offer["half_core"], "cycles": offer["cycles"],
            "contract_specializations": sum(bool(h["specialization"]) for h in offer["hands"])}


def add_variants(out, offer, group, policy, case, seed, live_unlocked):
    grids = ((CROWN_SCOPES, CROWN_CORES) if offer["name"] == "crown" else
             (NEON_SCOPES, NEON_FOCUS_CORES))
    for target_scope in grids[0]:
        for target_core in grids[1]:
            out.append(rescore(offer, target_scope, target_core, group, policy, case, seed, live_unlocked))


def stats(values):
    if not values:
        return {"n": 0}
    ordered = sorted(values)
    return {"n": len(ordered), "min": ordered[0], "p10": ordered[int((len(ordered)-1)*.1)],
            "median": statistics.median(ordered), "p90": ordered[int((len(ordered)-1)*.9)], "max": ordered[-1]}


def summarize(rows):
    output = []
    for group in ("exact_task7_hands", "fresh_godot_owned_pools_python_draws"):
        for name in ("crown", "neon"):
            subset = [r for r in rows if r["group"] == group and r["offer"] == name]
            for target_scope, target_core in sorted({(r["target_scope"], r["target_core"]) for r in subset}):
                group_rows = [r for r in subset if r["target_scope"] == target_scope and r["target_core"] == target_core]
                output.append({"group": group, "offer": name, "scope_target": target_scope,
                               "core_target": target_core, "denominator": group_rows[0]["denominator"],
                               "n": len(group_rows), "live_unlocked_route_count": len({(r["policy"],r["case"]) for r in group_rows if r["live_unlocked"]}),
                               "full_count": sum(r["full"] for r in group_rows),
                               "full_fraction": sum(r["full"] for r in group_rows)/len(group_rows),
                               "completion_percent": stats([r["completion_percent"] for r in group_rows]),
                               "cash_cents": stats([r["cash_cents"] for r in group_rows]),
                               "promotion_points": stats([r["promotion_points"] for r in group_rows]),
                               "limiting_counts": dict(Counter(key for r in group_rows for key,val in r["limiting"].items() if val > 0)),
                               "contract_specializations": sum(r["contract_specializations"] for r in group_rows),
                               "cycles": stats([r["cycles"] for r in group_rows])})
    return output


def load_fresh():
    rows = []
    for policy in ("ordinary", "optimizer"):
        path = OUT / f"sidestreet_acceptance_stress_v1_{policy}_task15_fresh_30.json"
        batch = json.loads(path.read_text(encoding="utf-8"))
        assert batch["count"] == 50 and batch["failures"] == 0
        assert all(r["valid"] and r["game_2"]["released"] for r in batch["rows"])
        rows += batch["rows"]
    return rows


def load_synergy():
    path = OUT / "contract_synergy_first_capture_v1_synergy_task15_matched.json"
    batch = json.loads(path.read_text(encoding="utf-8"))
    assert batch["failures"] == 0
    return batch["rows"]


def production_result(row):
    return {"policy": row["policy"], "case": row["case"], "seed": row["seed"],
            "starter_roster": row["starter_roster"], "owned_primitive": sorted(base.owned_features(row)),
            "reviews": [row[f"game_{i}"]["final_review"] for i in (1,2)],
            "awareness": [row[f"game_{i}"]["awareness"] for i in (1,2)],
            "crown_unlocked": base.elig(row)["crown"], "neon_unlocked": base.elig(row)["neon"],
            "games": [{"game": i, "release": row[f"game_{i}"],
                       "plays": [{"phase": a["phase"], "draw": a["draw"], "redraws": a.get("redraws", []),
                                  "selected": a["selected"], "synergy": a["synergy"], "printed_scope": a["printed_scope"],
                                  "printed_core": a["printed_core"], "cost_cents": a["cost_cents"],
                                  "before_cycle": a["before"]["cycle"], "after_cycle": a["after"]["cycle"]}
                                 for a in row["actions"] if a.get("game") == i and a["phase"] in ("design","alpha")],
                       "priority_commits": [a for a in row["actions"] if a.get("game") == i and a["phase"] in ("design_priority","alpha_priority")]} for i in (1,2)]}


def promotion_shadow(route, promo):
    # Frozen Game-2 profile is used only as a hypothetical next release.
    release = dict(route["game_2"])
    release["cycle"] += 12
    market = release["market_bp"] if "market_bp" in release else base.sales.old.market(release)
    stages = {}
    for label, offset in (("month1",2),("month2",4),("month3",6)):
        cycle = release["cycle"] + offset
        base_units = base.sales.age_units(release, market, cycle)
        promo_units = base.sales.age_units(release, market, cycle, promo)
        stages[label] = {"cycle": cycle, "unit_delta": promo_units-base_units,
                         "earned_net_delta_cents": base.sales.net(promo_units)-base.sales.net(base_units),
                         "settled_net_delta_cents": base.sales.net(base.sales.age_units(release,market,cycle-cycle%2,promo))
                         -base.sales.net(base.sales.age_units(release,market,cycle-cycle%2))}
    return stages


def main():
    old = json.load(gzip.open(OUT / "remaining_publisher_contracts_rebaseline_v1_raw.json.gz", "rt", encoding="utf-8"))
    assert len(old) == 90
    frozen = []
    for row in old:
        original_crown = row["synthetic_crown"]
        assert score("crown", original_crown["scope"], original_crown["half_core"], None, 12, 6) == (original_crown["numerator"], 96)
        add_variants(frozen, row["synthetic_crown"], "exact_task7_hands", row["policy"], row["case"], row["seed"], False)
        if "neon" in row["candidates"]:
            original_neon = row["candidates"]["neon"]
            assert score("neon", original_neon["scope"], original_neon["half_core"], original_neon["focus"], 12, 10) == (original_neon["numerator"], 96)
            add_variants(frozen, row["candidates"]["neon"], "exact_task7_hands", row["policy"], row["case"], row["seed"], True)
    fresh_routes = load_fresh()
    fresh = []
    fresh_draws = []
    for route in fresh_routes:
        owned = base.owned_features(route)
        focus = ("sound" if route["policy"] == "ordinary" else
                 max(CORES, key=lambda c: sum(base.LEDGER[i]["primary_value"] for i in owned if base.LEDGER[i]["primary_stat"] == c)))
        eligibility = base.elig(route)
        redraws = route["sidestreet_2"]["hands"][-1]["after"]["redraws"]
        for draw_index in range(20):
            seed = route["seed"] + 100003 + draw_index*1009
            crown = base.simulate_offer(route, "crown", owned, seed+71, redraws, focus)
            fresh_draws.append({"policy":route["policy"],"case":route["case"],"seed":seed+71,"offer":crown})
            add_variants(fresh, crown, "fresh_godot_owned_pools_python_draws", route["policy"], route["case"], seed, False)
            if eligibility["neon"]:
                neon = base.simulate_offer(route, "neon", owned, seed+73, redraws, focus)
                fresh_draws.append({"policy":route["policy"],"case":route["case"],"seed":seed+73,"offer":neon})
                add_variants(fresh, neon, "fresh_godot_owned_pools_python_draws", route["policy"], route["case"], seed, True)
    synergy_routes = load_synergy()
    old_live = [production_result(r) for r in base.rows()]
    synergy_live = [production_result(r) for r in synergy_routes]
    model = frozen + fresh
    summary = {"revision": base.REVISION, "task7_exact_routes": len(old), "fresh_current_godot_routes": len(fresh_routes),
               "fresh_neon_eligible_routes": sum(base.elig(r)["neon"] for r in fresh_routes),
               "fresh_crown_eligible_routes": sum(base.elig(r)["crown"] for r in fresh_routes),
               "fresh_python_model_draws_per_route": 20,
               "synergy_godot_routes": len(synergy_routes),
               "policy_unlocks": {policy: {"n": len(rows), "crown": sum(x["crown_unlocked"] for x in rows),
                                            "neon": sum(x["neon_unlocked"] for x in rows),
                                            "reviews": stats([max(x["reviews"]) for x in rows]),
                                            "production_synergies": sum(a["synergy"] != "none" for x in rows for g in x["games"] for a in g["plays"])}
                                  for policy,rows in ((p,[x for x in old_live if x["policy"]==p]) for p in ("cautious","ordinary","optimizer"))}
                                 | {"synergy": {"n": len(synergy_live), "crown": sum(x["crown_unlocked"] for x in synergy_live),
                                                 "neon": sum(x["neon_unlocked"] for x in synergy_live),
                                                 "reviews": stats([max(x["reviews"]) for x in synergy_live]),
                                                 "production_synergies": sum(a["synergy"] != "none" for x in synergy_live for g in x["games"] for a in g["plays"]) }},
               "variants": summarize(model),
               "promotion_shadow": {"low_review": [], "synthetic_9_1": []}}
    for route in [r for r in fresh_routes if base.elig(r)["neon"]][:8]:
        # Fixed caps, candidate completions; only target is varied.
        row = next((x for x in model if x["group"]=="fresh_godot_owned_pools_python_draws" and x["policy"]==route["policy"] and x["case"]==route["case"] and x["offer"]=="neon" and x["target_scope"]==10 and x["target_core"]==9), None)
        if row is None:
            continue
        summary["promotion_shadow"]["low_review"].append({"policy":route["policy"],"case":route["case"],
                    "review":route["game_2"]["final_review"],"points":row["promotion_points"],
                    "stages":promotion_shadow(route,row["promotion_points"])})
        synthetic = dict(route, game_2=dict(route["game_2"],final_review=9.1,
                market_bp=base.sales.old.market(route["game_2"])))
        summary["promotion_shadow"]["synthetic_9_1"].append({"policy":route["policy"],"case":route["case"],
                    "review":9.1,"points":row["promotion_points"],
                    "stages":promotion_shadow(synthetic,row["promotion_points"])})
    raw = {"exact_task7_rescores": frozen,"fresh_paired_model_rescores": fresh,
           "fresh_model_draws":fresh_draws,
           "fresh_godot_routes": [{"policy":r["policy"],"case":r["case"],"seed":r["seed"],
                                   "owned_primitive":sorted(base.owned_features(r)),
                                   "focus":r["production_focus"],"reviews":[r["game_1"]["final_review"],r["game_2"]["final_review"]],
                                   "awareness":[r["game_1"]["awareness"],r["game_2"]["awareness"]],
                                   "cash_cents":r["sidestreet_2"]["after_dismiss"]["cash_cents"]} for r in fresh_routes],
           "task7_production_policies":old_live,"synergy_first_current_godot":synergy_live}
    with gzip.open(OUT / "contract_target_paired_recheck_v1_raw.json.gz", "wt", encoding="utf-8") as f:
        json.dump(raw,f,separators=(",",":"))
    (OUT / "contract_target_paired_recheck_v1_summary.json").write_text(json.dumps(summary,indent=2),encoding="utf-8")
    print(json.dumps({"fresh_routes":len(fresh_routes),"fresh_neon":summary["fresh_neon_eligible_routes"],
                      "synergy_routes":len(synergy_routes),"variants":len(summary["variants"])},indent=2))


if __name__ == "__main__":
    main()
