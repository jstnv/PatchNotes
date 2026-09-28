"""Aggregate matched analysis-only Godot trial-card Game-2 traces.

Run: python -B analysis/feature_pair_game2_analysis_v1.py matched20
"""
from __future__ import annotations

import gzip
import json
import statistics
import sys
from collections import Counter
from pathlib import Path

import post_launch_campaign_playtest_v1 as sales

OUT = Path(__file__).resolve().parents[1] / "design-logs"
POLICIES = ("cautious", "ordinary", "optimizer")
ARMS = ("none", "control_background_music", "background_music",
        "control_sub_areas", "sub_areas", "control_pair", "pair", "existing_upgrade")
CONTROL = {"none":"none", "control_background_music":"control_background_music",
           "background_music":"control_background_music",
           "control_sub_areas":"control_sub_areas", "sub_areas":"control_sub_areas",
           "control_pair":"control_pair", "pair":"control_pair",
           "existing_upgrade":"none"}
TRIALS = {"background_music", "sub_areas"}
PRINTED = {x["id"]: x for x in json.loads((OUT.parent / "data/card_ledger.json").read_text())}
PRINTED.update({x["id"]: x for x in json.loads((OUT.parent / "data/feature_store_ledger.json").read_text())})
PRINTED.update({
    "background_music": {"primary_stat": "sound", "primary_value": 3,
                         "secondary_stat": "", "secondary_value": 0, "scope": 1},
    "sub_areas": {"primary_stat": "graphics", "primary_value": 3,
                  "secondary_stat": "design", "secondary_value": 2, "scope": 2},
})
CORE_INDEX = {"graphics": 0, "sound": 1, "technology": 2, "design": 3}
MARKET_BPS = tuple(x["launch_demand_basis_points"] for x in
                   json.loads((OUT.parent / "data/primitive_market_forecast_ledger.json").read_text()))


def market_bp(release):
    matches = [bp for bp in MARKET_BPS if sales.month_one_units(
        round(release["final_review"] * 10), release["awareness"], bp
    ) == release["month_1_units"]]
    if release["final_review"] == 0 and release["month_1_units"] == 0:
        return None
    assert len(matches) == 1, (release, matches)
    return matches[0]


def describe(values):
    v = sorted(values)
    return {"n": len(v), "p10": v[int((len(v)-1)*.1)], "median": statistics.median(v),
            "p90": v[int((len(v)-1)*.9)], "mean": statistics.mean(v)}


def card_events(row):
    actions = [a for a in row["actions"] if a.get("game") == 2 and a.get("phase") in ("design", "alpha")]
    redraws = [r for a in actions for r in a.get("redraws", [])]
    draws = [card for a in actions for card in a.get("draw", []) if card in TRIALS]
    draws += [r.get("to") for r in redraws if r.get("success") and r.get("to") in TRIALS]
    selected = [card for a in actions for card in a.get("selected", []) if card in TRIALS]
    assert all(n <= 1 for n in Counter(selected).values()), "Finite trial Feature replayed in one project"
    return {"draws": draws, "selected": selected,
            "drawn_by_id": dict(Counter(draws)), "selected_by_id": dict(Counter(selected)),
            "redraw_count": len(redraws),
            "pass_redraw_count": sum(str(r.get("from", "")).endswith("_pass") for r in redraws),
            "feature_redraw_count": sum(not str(r.get("from", "")).endswith("_pass") for r in redraws),
            "synergies": dict(Counter(a.get("synergy", "none") for a in actions))}


def game2_production(row):
    actions = [a for a in row["actions"] if a.get("game") == 2]
    printed_core = [0, 0, 0, 0]
    printed_scope = 0
    for action in actions:
        if action.get("phase") not in ("design", "alpha"):
            continue
        for card_id in action.get("selected", []):
            card = PRINTED[card_id]
            for label in ("primary", "secondary"):
                core = card[label + "_stat"]
                if core:
                    printed_core[CORE_INDEX[core]] += card[label + "_value"]
            printed_scope += card["scope"]
    beta = [a for a in actions if a.get("phase") == "beta"]
    return {"printed_core": printed_core, "printed_scope": printed_scope,
            "sound_specialization_hands": sum(a.get("synergy") == "sound specialization" for a in actions),
            "qa_specialization_hands": sum(a.get("synergy") == "QA specialization" for a in beta),
            "marketing_specialization_hands": sum(a.get("synergy") == "Marketing specialization" for a in beta),
            "beta_qa_cards": sum(c == "qa" for a in beta for c in a.get("categories", [])),
            "beta_marketing_cards": sum(c == "marketing" for a in beta for c in a.get("categories", []))}


def play_cost_shadow(row, prices):
    cumulative = 0
    first_failure = None
    for action in row["actions"]:
        if action.get("game") != 2 or action.get("phase") not in ("design", "alpha"):
            continue
        baseline_cost = 0
        trial_cost = 0
        for card_id in action.get("selected", []):
            card = PRINTED[card_id]
            if card_id in TRIALS:
                trial_cost += prices[card_id]
            elif card_id in {"colored_text", "animated_sprites", "8_color_palette", "recorded_sounds",
                             "16_bit_music", "save_files", "scripted_ai", "multi_directional_scrolling",
                             "branching_nodes", "difficulty_levels", "high_scores"}:
                pass  # Existing later-store play costs are still undefined.
            elif card["type"] == "feature":
                baseline_cost += 1000 * (card["primary_value"] + card["secondary_value"] + 2 * card["scope"])
        before = action["before"]
        if first_failure is None and before["cash_cents"] - cumulative < baseline_cost + trial_cost:
            first_failure = {"phase": action["phase"], "cycle": before["cycle"],
                             "shortfall_cents": baseline_cost + trial_cost - (before["cash_cents"] - cumulative)}
        cumulative += trial_cost
    return {"extra_cents": cumulative, "first_failure": first_failure}


def main():
    suffix = sys.argv[1] if len(sys.argv) > 1 else "matched20"
    by_key = {}
    for policy in POLICIES:
        for arm in ARMS:
            path = OUT / f"feature_pair_game2_trial_v1_{policy}_{arm}_{suffix}.json"
            data = json.loads(path.read_text())
            assert data["failures"] == 0 and data["policy"] == policy and data["arm"] == arm
            by_key[(policy, arm)] = {r["case"]: r for r in data["rows"]}
    keys = sorted(by_key[(POLICIES[0], ARMS[0])])
    assert all(set(rows) == set(keys) for rows in by_key.values())
    raw = []
    for policy in POLICIES:
        for case in keys:
            for arm in ARMS:
                control = by_key[(policy, CONTROL[arm])][case]
                row = by_key[(policy, arm)][case]
                assert row["seed"] == control["seed"] and row["starter_roster"] == control["starter_roster"]
                assert row["game_1"]["final_review"] == control["game_1"]["final_review"]
                reserve_match = (row["reserve_purchase"]["id"] == control["reserve_purchase"]["id"]
                                 and row["reserve_purchase"]["success"] == control["reserve_purchase"]["success"])
                assert all(card not in TRIALS for name in ("ironclad","sidestreet_1","sidestreet_2")
                           for hand in row.get(name,{}).get("hands",[])
                           for card in hand.get("draw",[])+hand.get("selected",[]))
                ev = card_events(row)
                production = game2_production(row)
                cost_shadows = {label: play_cost_shadow(row, prices) for label, prices in {
                    "current_zero": {"background_music": 0, "sub_areas": 0},
                    "primitive_analogue": {"background_music": 5000, "sub_areas": 9000},
                    "double_analogue": {"background_music": 10000, "sub_areas": 18000},
                }.items()}
                bought = [x["id"] for x in row["trial_purchases"] if x["bought"]]
                quotes = [{"id": x["id"], "unlocked": x["quote"]["unlocked"],
                           "price_cents": x["quote"]["price_cents"],
                           "discount_percent": x["quote"]["discount_percent"],
                           "bought": x["bought"]} for x in row["trial_purchases"]]
                g = row["game_2"]
                c = control["game_2"]
                if market_bp(g) is not None and market_bp(c) is not None:
                    assert market_bp(g) == market_bp(c), (policy, arm, case, market_bp(g), market_bp(c))
                ending = row["sidestreet_2"]["after_dismiss"]
                control_ending = control["sidestreet_2"]["after_dismiss"]
                raw.append({"policy": policy, "arm": arm, "case": case, "seed": row["seed"],
                            "starter_target": row["starter_target"], "focus": row["production_focus"],
                            "beta_mode": row["beta_mode"],
                            "contract_order": "early" if case % 2 == 0 else "deferred",
                            "bought": bought, "quotes": quotes,
                            "existing_store_bought": bool(row["store_purchase"]["success"]),
                            "reserve": row["reserve_purchase"],
                            "control_reserve_success": control["reserve_purchase"]["success"],
                            "reserve_match": reserve_match,
                            "events": ev,
                            "production": production,
                            "play_cost_shadows": cost_shadows,
                            "game2": g, "control_game2": c,
                            "review_delta_tenths": round((g["final_review"] - c["final_review"]) * 10),
                            "scope_delta": g["scope"] - c["scope"],
                            "cash_before_game2_delta_cents": row["cash_before_game_2_cents"] - control["cash_before_game_2_cents"],
                            "cash_release_delta_cents": row["after_release_2"]["cash_cents"] - control["after_release_2"]["cash_cents"],
                            "projected_month1_net_delta_cents": g["projected_net_cents"] - c["projected_net_cents"],
                            "cash_after_contract_delta_cents": ending["cash_cents"] - control_ending["cash_cents"],
                            "earned_net_cents": sum(s["entitlement_cents"] for s in ending["sales"]),
                            "settled_net_cents": sum(s["settled_cents"] for s in ending["sales"]),
                            "sidestreet_2_payout_delta_cents": row["sidestreet_2"]["independent_payout_cents"] - control["sidestreet_2"]["independent_payout_cents"]})
    summary = {}
    for policy in POLICIES:
        for arm in ARMS:
            group = [x for x in raw if x["policy"] == policy and x["arm"] == arm]
            paired = group if arm == "existing_upgrade" else [x for x in group if x["reserve_match"]]
            summary[policy + "|" + arm] = {
                "n": len(group), "any_trial_bought": sum(bool(x["bought"]) for x in group),
                "paired_reserve_n": len(paired),
                "reserve_mismatch_count": sum(not x["reserve_match"] for x in group),
                "both_trial_bought": sum(len(x["bought"]) == 2 for x in group),
                "existing_store_bought": sum(x["existing_store_bought"] for x in group),
                "reserve_bought": sum(x["reserve"]["success"] for x in group),
                "reserve_blocked_by_arm": sum(not x["reserve"]["success"] and x["control_reserve_success"] for x in group),
                "trial_quote_discounts":dict(Counter(q["discount_percent"] for x in group for q in x["quotes"] if q["bought"])),
                "any_trial_drawn": sum(bool(x["events"]["draws"]) for x in group),
                "any_trial_selected": sum(bool(x["events"]["selected"]) for x in group),
                "trial_play_count": sum(len(x["events"]["selected"]) for x in group),
                "trial_buy_by_contract_order": {order: {"n": sum(x["contract_order"] == order for x in group),
                                                  "any_bought": sum(x["contract_order"] == order and bool(x["bought"]) for x in group),
                                                  "both_bought": sum(x["contract_order"] == order and len(x["bought"]) == 2 for x in group)}
                                                for order in ("early", "deferred")},
                "review_tenths_delta": describe(x["review_delta_tenths"] for x in paired),
                "scope_delta": describe(x["scope_delta"] for x in paired),
                "cash_before_game2_delta_cents": describe(x["cash_before_game2_delta_cents"] for x in paired),
                "cash_release_delta_cents": describe(x["cash_release_delta_cents"] for x in paired),
                "projected_month1_net_delta_cents": describe(x["projected_month1_net_delta_cents"] for x in paired),
                "cash_after_contract_delta_cents": describe(x["cash_after_contract_delta_cents"] for x in paired),
                "earned_net_cents": describe(x["earned_net_cents"] for x in group),
                "settled_net_cents": describe(x["settled_net_cents"] for x in group),
                "sidestreet_2_payout_delta_cents": describe(x["sidestreet_2_payout_delta_cents"] for x in paired),
                "game2_review": describe(x["game2"]["final_review"] for x in group),
                "game2_scope": describe(x["game2"]["scope"] for x in group),
                "game2_core": {str(i): describe(x["game2"]["cores"][i] for x in group) for i in range(4)},
                "printed_core": {str(i): describe(x["production"]["printed_core"][i] for x in group) for i in range(4)},
                "printed_scope": describe(x["production"]["printed_scope"] for x in group),
                "sound_specialization_paths": sum(x["production"]["sound_specialization_hands"] > 0 for x in group),
                "qa_specialization_paths": sum(x["production"]["qa_specialization_hands"] > 0 for x in group),
                "marketing_specialization_paths": sum(x["production"]["marketing_specialization_hands"] > 0 for x in group),
                "beta_qa_cards": describe(x["production"]["beta_qa_cards"] for x in group),
                "beta_marketing_cards": describe(x["production"]["beta_marketing_cards"] for x in group),
                "fixed_bugs": describe(x["game2"]["fixed_bugs"] for x in group),
                "remaining_bugs": describe(x["game2"]["known_bugs"] + x["game2"]["hidden_bugs"] for x in group),
                "game2_awareness": describe(x["game2"]["awareness"] for x in group),
                "game2_units": describe(x["game2"]["month_1_units"] for x in group),
                "redraws": describe(x["events"]["redraw_count"] for x in group),
                "pass_redraws": describe(x["events"]["pass_redraw_count"] for x in group),
                "feature_redraws": describe(x["events"]["feature_redraw_count"] for x in group),
                "synergies": dict(Counter(k for x in group for k,v in x["events"]["synergies"].items() for _ in range(v))),
                "play_cost_sensitivity": {
                    label: {"extra_cents": describe(x["play_cost_shadows"][label]["extra_cents"] for x in group),
                            "first_hand_shortfall_count": sum(x["play_cost_shadows"][label]["first_failure"] is not None for x in group),
                            "release_cash_negative_count": sum(x["game2"]["cash_cents"] - x["play_cost_shadows"][label]["extra_cents"] < 0 for x in group)}
                    for label in ("current_zero", "primitive_analogue", "double_analogue")},
                "conditional_review_delta_tenths": {
                    label: describe(x["review_delta_tenths"] for x in selected) if selected else {"n":0}
                    for label,selected in (("none_bought",[x for x in paired if not x["bought"]]),
                                           ("one_bought",[x for x in paired if len(x["bought"])==1]),
                                           ("both_bought",[x for x in paired if len(x["bought"])==2]),
                                           ("trial_played",[x for x in paired if x["events"]["selected"]]))},
            }
    focus_summary={}
    for arm in ARMS:
        for focus in ("sound","mixed"):
            group=[x for x in raw if x["arm"]==arm and x["focus"]==focus
                   and (arm=="existing_upgrade" or x["reserve_match"])]
            if not group:
                continue
            focus_summary[arm+"|"+focus]={"n":len(group),
                "review_delta_tenths":describe(x["review_delta_tenths"] for x in group),
                "game2_sound_core":describe(x["game2"]["cores"][1] for x in group),
                "game2_scope":describe(x["game2"]["scope"] for x in group),
                "sound_synergy_hands":sum(v for x in group for k,v in x["events"]["synergies"].items() if "sound" in k.lower()),
                "sound_specialization_paths":sum(x["production"]["sound_specialization_hands"] > 0 for x in group),
                "printed_sound_core":describe(x["production"]["printed_core"][1] for x in group),
                "pass_redraws":sum(x["events"]["pass_redraw_count"] for x in group),
                "feature_redraws":sum(x["events"]["feature_redraw_count"] for x in group)}
    result = {"source_revision": "ba616515ed1b039fd0da7cf03f73288fd7ccd8e4",
              "suffix": suffix, "matched_cases_per_policy": len(keys), "continuations": len(raw),
              "summary": summary,"focus_summary":focus_summary,
              "limitations": ["Trial cards exist only by per-run injection in analysis harness",
                              "Store purchase uses current zero-cycle path; proposed one-cycle modeled separately",
                              "Trial Feature play cost is runtime zero because authoritative value is TBD; $50/$90 and double fixed-action shadows preflight each hand and do not adapt choices after a shortfall",
                              "Each candidate is compared to a no-candidate control with the same legal Primitive reserve strategy",
                              "A UI-derived fallback reserve can differ across arms in some seeds; paired candidate deltas exclude those seeds and counts are reported",
                              "Even cases take Ironclad and SideStreet before shopping; odd cases defer both until after Game 2, which is confounded with QA-versus-Marketing route in this fixed sample",
                              "Same seeds and first-game outcomes do not ensure same downstream RNG after candidate pool changes",
                              "No human action choices; automated policies only"]}
    (OUT / f"feature_pair_game2_trial_v1_{suffix}_summary.json").write_text(json.dumps(result, indent=2))
    with gzip.open(OUT / f"feature_pair_game2_trial_v1_{suffix}_paired.json.gz", "wt", encoding="utf-8") as f:
        json.dump(raw, f, separators=(",", ":"))
    for key in summary:
        s = summary[key]
        print(key, "buy", s["any_trial_bought"], "draw", s["any_trial_drawn"],
              "play", s["any_trial_selected"], "review_delta", s["review_tenths_delta"]["mean"])


if __name__ == "__main__":
    main()
