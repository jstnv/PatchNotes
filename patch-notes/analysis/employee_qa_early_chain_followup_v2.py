"""Read-only QA timing counterfactual. No employee or Beta gameplay is changed.

Run: python -B analysis/employee_qa_early_chain_followup_v2.py
The archived 600 paired paths supply a fixed-action control. Fresh policy-model
paths supply a bounded adaptive comparison; they are not Godot PRNG parity.
"""
from __future__ import annotations

import gzip
import hashlib
import json
import math
import random
import statistics
from collections import Counter, defaultdict
from pathlib import Path

import employee_three_specialist_trial_v1 as archived
import fanbase_playtest_v1 as base
import qa_analyst_counterfactual_v1 as prior

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "design-logs"
SEED = 26092784
COHORTS = {"legal": 1000, "below_20": 250, "expanded": 250}
BUDGETS = (2, 3, 4, 6)
POLICIES = ("qa_first", "marketing_first", "mixed")
PRIORITIES = {
    "qa_first": {"qa": 50, "marketing": 35, "insider": 15},
    "marketing_first": {"qa": 20, "marketing": 50, "insider": 30},
    "mixed": {"qa": 35, "marketing": 35, "insider": 30},
}
VARIANTS = ("none", "archived", "early_0", "early_1", "early_2")


def early_replay(initial_hidden, actions, extra_fix):
    """Resolve Searches before Debugs using current Beta arithmetic and caps."""
    assert extra_fix in (-1, 0, 1, 2)  # -1 is the reward-free control.
    hidden, known, marketing = initial_hidden, 0, 0
    trained = False
    debug_reward_attempted = False
    extra_found = extra_fixed = ordinary_found = ordinary_fixed = 0
    marketing_special_hands = 0
    qa_hands = 0
    events = []
    for hand_index, ids in enumerate(actions):
        cards = [base.BY_ID[i] for i in ids]
        cats = Counter(c["beta_category"] for c in cards)
        qa_special = len(cards) >= 2 and cats["qa"] == len(cards)
        marketing_special = len(cards) >= 2 and cats["marketing"] == len(cards)
        balanced = not qa_special and not marketing_special and len(cards) == 4 and all(
            1 <= cats[x] <= 2 for x in ("qa", "marketing", "insider"))
        marketing_special_hands += int(marketing_special)
        qa_hands += int(cats["qa"] > 0)
        search_ordinary = debug_ordinary = search_bonus = debug_bonus = 0
        for card in cards:
            if card["id"] != "search_for_bugs":
                continue
            value = card["beta_value"] * (1.5 if qa_special else 1)
            requested = math.floor(1 + value + hidden * .15 * value)
            if balanced:
                requested = math.ceil(requested * 1.25)
            found = min(requested, hidden)
            hidden -= found
            known += found
            search_ordinary += found
        if not trained and search_ordinary:
            trained = True
            search_bonus = min(1, hidden) if extra_fix >= 0 else 0
            hidden -= search_bonus
            known += search_bonus
            extra_found += search_bonus
        for card in cards:
            if card["id"] != "debug":
                continue
            value = card["beta_value"] * (1.5 if qa_special else 1)
            requested = math.floor(1 + value)
            if balanced:
                requested = math.ceil(requested * 1.25)
            fixed = min(requested, known)
            known -= fixed
            debug_ordinary += fixed
        if trained and not debug_reward_attempted and debug_ordinary:
            debug_reward_attempted = True
            debug_bonus = min(max(0, extra_fix), known)
            known -= debug_bonus
            extra_fixed += debug_bonus
        raw = sum(c["beta_value"] for c in cards if c["beta_category"] == "marketing")
        marketing += (math.floor(raw * 1.5) if marketing_special else
                      math.ceil(raw * 1.25) if balanced else raw)
        ordinary_found += search_ordinary
        ordinary_fixed += debug_ordinary
        events.append({"hand": hand_index, "cards": ids, "search_ordinary": search_ordinary,
                       "search_bonus": search_bonus, "debug_ordinary": debug_ordinary,
                       "debug_bonus": debug_bonus, "hidden_after": hidden, "known_after": known,
                       "marketing_special": marketing_special})
    return {"hidden": hidden, "known": known, "remaining": hidden + known,
            "marketing": marketing, "trained": trained,
            "debug_opportunity": debug_reward_attempted, "extra_found": extra_found,
            "extra_fixed": extra_fixed, "ordinary_found": ordinary_found,
            "ordinary_fixed": ordinary_fixed, "marketing_special_hands": marketing_special_hands,
            "qa_hands": qa_hands, "events": events}


def outcome(initial_bugs, actions, variant):
    if variant == "archived":
        old = archived.qa_replay(initial_bugs, actions, True)
        return {"hidden": old["hidden"], "known": old["known"],
                "remaining": old["remaining_bugs"], "marketing": old["marketing"],
                "trained": old["first_search_hand"] is not None,
                "debug_opportunity": old["award_hand"] is not None,
                "extra_found": old["extra_found"], "extra_fixed": old["extra_fixes"],
                "marketing_special_hands": old["marketing_special_hands"], "events": []}
    return early_replay(initial_bugs, actions, -1 if variant == "none" else int(variant[-1]))


def action_schedule(initial_hidden, budget, policy, seed, variant, adaptive):
    rng = random.Random(seed)
    hidden, known, exhausted = initial_hidden, 0, set()
    candidate_pools, hands = [], []
    for _ in range(budget):
        pool = base.draw_beta(exhausted, PRIORITIES[policy], rng)
        selected = prior.choices(pool, policy, hidden, known, rng)
        ids = [c["id"] for c in selected]
        candidate_pools.append([c["id"] for c in pool])
        hands.append(ids)
        # Fixed controls use the no-staff state; adaptive variants may change
        # later choices but never alter the draw or action rules themselves.
        preview = outcome(initial_hidden, hands, variant if adaptive else "none")
        hidden, known = preview["hidden"], preview["known"]
        exhausted.update(c["id"] for c in selected if not c["renewable"])
    return candidate_pools, hands


def review_and_cash(scores, scope, genre, roll, market_bp, result):
    review = base.review(scores, scope, result["remaining"], genre, random.Random(0), roll)[0]
    units = base.units(review, result["marketing"], 0, market_bp)
    return review, units, units * 999 * 70 // 100


def metrics(rows):
    if not rows:
        return {"n": 0}
    n = len(rows)
    return {"n": n, "training_pct": round(100 * sum(r["trained"] for r in rows) / n, 2),
            "debug_opportunity_pct": round(100 * sum(r["debug_opportunity"] for r in rows) / n, 2),
            "useful_search_pct": round(100 * sum(r["extra_found"] > 0 for r in rows) / n, 2),
            "useful_debug_pct": round(100 * sum(r["extra_fixed"] > 0 for r in rows) / n, 2),
            "extra_found_mean": round(statistics.mean(r["extra_found"] for r in rows), 4),
            "extra_fixed_mean": round(statistics.mean(r["extra_fixed"] for r in rows), 4),
            "remaining_bug_delta_mean": round(statistics.mean(r["remaining_delta"] for r in rows), 4),
            "review_delta_mean": round(statistics.mean(r["review_delta"] for r in rows), 4),
            "review_changed_pct": round(100 * sum(r["review_delta"] != 0 for r in rows) / n, 2),
            "cross_5_up": sum(r["base_review"] < 5 <= r["review"] for r in rows),
            "cross_7_up": sum(r["base_review"] < 7 <= r["review"] for r in rows),
            "awareness_delta_mean": round(statistics.mean(r["awareness_delta"] for r in rows), 4),
            "month1_unit_delta_mean": round(statistics.mean(r["unit_delta"] for r in rows), 4),
            "month1_net_delta_mean_cents": round(statistics.mean(r["net_delta_cents"] for r in rows), 2),
            "specialization_hands_mean": round(statistics.mean(r["marketing_special_hands"] for r in rows), 3),
            "salary_75_adjusted_delta_mean_cents": round(statistics.mean(r["salary_75_adjusted_delta_cents"] for r in rows), 2)}


def record(case, budget, policy, variant, base_result, result, base_fin, fin,
           source, draws, actions, sample_index):
    review, units, net = fin
    baseline_review, baseline_units, baseline_net = base_fin
    # Equal budgets: salary is a counterfactual expense; it is not in runtime.
    due_count = (case["alignment"] + budget + 2) // 2
    return {"source": source, "cohort": case["cohort"], "sample": sample_index,
            "seed": case["seed"], "initial_hidden": case["bugs"],
            "hidden_band": "0" if case["bugs"] == 0 else "1-2" if case["bugs"] <= 2 else "3-4" if case["bugs"] <= 4 else "5+",
            "budget": budget, "policy": policy, "variant": variant,
            "trained": result["trained"], "debug_opportunity": result["debug_opportunity"],
            "extra_found": result["extra_found"], "extra_fixed": result["extra_fixed"],
            "remaining": result["remaining"], "remaining_delta": result["remaining"] - base_result["remaining"],
            "base_review": baseline_review, "review": review,
            "review_delta": round(review - baseline_review, 1),
            "base_units": baseline_units, "units": units,
            "unit_delta": units - baseline_units,
            "base_net_cents": baseline_net, "net_cents": net,
            "net_delta_cents": net - baseline_net,
            "awareness": 100 + result["marketing"],
            "awareness_delta": result["marketing"] - base_result["marketing"],
            "marketing_special_hands": result["marketing_special_hands"],
            "salary_75_adjusted_delta_cents": net - baseline_net - due_count * 7500,
            "shadow_salary_due_count": due_count,
            "draws": draws, "actions": actions,
            "reward_events": result.get("events", [])}


def fresh_case(cohort, index):
    seed = SEED + index * 7919 + {"legal": 0, "below_20": 1000003, "expanded": 2000003}[cohort]
    rng = random.Random(seed)
    policy = ("conservative", "ordinary", "optimized")[index % 3]
    target = rng.choice((20, 21, 22, 23) if cohort == "legal" else (7, 10, 13, 16, 19))
    owned, spent = (base.roster(target, rng) if cohort != "expanded" else
                    ({c["id"] for c in base.FEATURES}, 0))
    scores, scope, bugs, _, _, _, _ = base.production(
        owned, policy, rng, 5500 - spent if cohort != "expanded" else 100000)
    genre = base.choose_genre(owned, policy, rng)
    roll, market_bp = rng.randrange(100), base.market(rng)
    return {"cohort": cohort, "seed": seed, "scores": scores, "scope": scope,
            "bugs": bugs, "genre": genre, "roll": roll, "market_bp": market_bp,
            "alignment": index % 2}


def archived_case(row, game):
    item = row["item"]
    trace = item["game1" if game == 1 else "game2"]
    return {"cohort": item["cohort"], "seed": SEED + item["index"],
            "scores": trace["scores"], "scope": trace["scope"], "bugs": trace["bugs"],
            "genre": item["genre"], "roll": item["variance"],
            "market_bp": item["market_bp"], "alignment": item["alignment"]}


def verify():
    # Same-hand Search must resolve before Debug; the bonus is clamped.
    a = early_replay(8, [["search_for_bugs", "debug"]], 2)
    assert a["trained"] and a["debug_opportunity"]
    assert a["extra_found"] == 1 and a["extra_fixed"] <= 2
    assert early_replay(0, [["search_for_bugs", "debug"]], 2)["extra_found"] == 0
    assert early_replay(1, [["search_for_bugs", "debug"]], 2)["extra_found"] == 0
    assert early_replay(8, [["search_for_bugs", "debug"]], 2)["remaining"] >= 0
    four = ["sign_flippers", "posters", "press_release", "press_interview"]
    result = early_replay(5, [four], 2)
    assert result["marketing_special_hands"] == 1 and not result["trained"]
    assert result["marketing"] == math.floor(sum(base.BY_ID[i]["beta_value"] for i in four) * 1.5)


def main():
    verify()
    fixed, adaptive = [], []
    source_path = OUT / "employee_three_specialist_trial_v1_raw.json.gz"
    archived_rows = json.load(gzip.open(source_path, "rt", encoding="utf-8"))
    for index, row in enumerate(archived_rows):
        for game in (1, 2):
            case = archived_case(row, game)
            actions = row["item"]["actions1" if game == 1 else "actions2"]
            base_result = outcome(case["bugs"], actions, "none")
            archived_control = archived.qa_replay(case["bugs"], actions, False)
            assert (base_result["remaining"], base_result["marketing"]) == (
                archived_control["remaining_bugs"], archived_control["marketing"])
            base_fin = review_and_cash(case["scores"], case["scope"], case["genre"],
                                       case["roll"], case["market_bp"], base_result)
            for variant in VARIANTS:
                result = outcome(case["bugs"], actions, variant)
                fin = review_and_cash(case["scores"], case["scope"], case["genre"],
                                      case["roll"], case["market_bp"], result)
                fixed.append(record(case, len(actions), "archived_fixed", variant,
                                    base_result, result, base_fin, fin, f"archived_game{game}",
                                    [], actions, index))
    for cohort, count in COHORTS.items():
        for index in range(count):
            case = fresh_case(cohort, index)
            for budget in BUDGETS:
                for policy in POLICIES:
                    action_seed = case["seed"] + budget * 1009 + POLICIES.index(policy) * 100003
                    base_draws, base_actions = action_schedule(case["bugs"], budget, policy,
                                                               action_seed, "none", False)
                    base_result = outcome(case["bugs"], base_actions, "none")
                    base_fin = review_and_cash(case["scores"], case["scope"], case["genre"],
                                               case["roll"], case["market_bp"], base_result)
                    for variant in VARIANTS:
                        draws, actions = (base_draws, base_actions) if variant in ("none", "archived") else (
                            action_schedule(case["bugs"], budget, policy, action_seed, variant, True))
                        result = outcome(case["bugs"], actions, variant)
                        fin = review_and_cash(case["scores"], case["scope"], case["genre"],
                                              case["roll"], case["market_bp"], result)
                        adaptive.append(record(case, budget, policy, variant,
                                               base_result, result, base_fin, fin,
                                               "fresh_model", draws, actions, index))
    groups = defaultdict(list)
    for row in fixed + adaptive:
        if row["variant"] == "none":
            continue
        keys = ["|".join((row["source"], row["cohort"], row["variant"])),
                "|".join((row["source"], row["cohort"], row["variant"], row["hidden_band"])),
                "|".join((row["source"], row["cohort"], row["variant"], str(row["budget"]), row["policy"]))]
        for key in keys:
            groups[key].append(row)
    summary = {"status": "read-only shadow candidate; no gameplay implementation",
               "source_revision": "ba616515ed1b039fd0da7cf03f73288fd7ccd8e4",
               "seed": SEED, "fresh_model_paths": COHORTS,
               "fixed_archived_paths": {"game1": 600, "game2": 600},
               "fixed_rows": len(fixed), "adaptive_rows": len(adaptive),
               "archived_source_sha256": hashlib.sha256(source_path.read_bytes()).hexdigest(),
               "groups": {key: metrics(value) for key, value in sorted(groups.items())}}
    with gzip.open(OUT / "employee_qa_early_chain_followup_v2_raw.json.gz", "wt", encoding="utf-8") as f:
        json.dump({"summary": summary, "fixed": fixed, "adaptive": adaptive}, f, separators=(",", ":"))
    (OUT / "employee_qa_early_chain_followup_v2_summary.json").write_text(
        json.dumps(summary, indent=2), encoding="utf-8")
    print(json.dumps({"fresh_model_paths": COHORTS, "fixed_rows": len(fixed),
                      "adaptive_rows": len(adaptive),
                      "legal_early1": summary["groups"]["fresh_model|legal|early_1"],
                      "legal_archived": summary["groups"]["fresh_model|legal|archived"]}, indent=2))


if __name__ == "__main__":
    main()
