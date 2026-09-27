"""Paired, read-only QA Analyst experiment. Run: python analysis/qa_analyst_counterfactual_v1.py [seed] [n_per_cohort].

The existing fanbase playtest supplies sampled starter pools, production, Genre Fit,
Review and sales. This script replays the same Beta actions, variance and market
snapshot through four provisional perk states. It is not employee implementation.
"""
from __future__ import annotations

import json
import gzip
import math
import random
import statistics
import sys
from collections import Counter, defaultdict
from pathlib import Path

import fanbase_playtest_v1 as base

ROOT = Path(__file__).resolve().parents[1]
OUTPUT = ROOT / "design-logs/qa_analyst_counterfactual_v1_results.json.gz"
PERKS = ("none", "search", "debug", "both")
PRIORITIES = {"qa_low": {"qa": 20, "marketing": 50, "insider": 30},
              "qa_high": {"qa": 50, "marketing": 35, "insider": 15}}


def choices(pool, policy, hidden, known, rng):
    scored = []
    for i, card in enumerate(pool):
        category, ident = card["beta_category"], card["id"]
        if policy == "qa_first":
            value = (40 if ident == "search_for_bugs" and hidden else
                     35 if ident == "debug" and (known or hidden) else
                     12 if category == "marketing" else 0)
        elif policy == "marketing_first":
            value = 35 + card["beta_value"] if category == "marketing" else (
                18 if ident == "search_for_bugs" and hidden else
                16 if ident == "debug" and known else 0)
        else:
            value = (10 if ident == "search_for_bugs" and hidden else 0) + (
                10 if ident == "debug" and (known or hidden) else 0) + (
                card["beta_value"] if category == "marketing" else 0)
        scored.append((value + rng.random() * .0001, i))
    selected = [pool[i] for _, i in sorted(scored, reverse=True)[:4]]
    return selected


def schedule(initial_bugs, priority, budget, policy, rng):
    """One candidate/action transcript, shared unchanged by all four perk cases."""
    hidden, known, exhausted = initial_bugs, 0, set()
    hands = []
    for _ in range(budget):
        pool = base.draw_beta(exhausted, priority, rng)
        selected = choices(pool, policy, hidden, known, rng)
        hands.append(([c["id"] for c in pool], [c["id"] for c in selected]))
        preview = replay(initial_bugs, [x[1] for x in hands], "none")
        hidden, known = preview["hidden"], preview["known"]
        exhausted.update(c["id"] for c in selected if not c["renewable"])
    return hands


def replay(initial_bugs, actions, perk):
    hidden, known, marketing = initial_bugs, 0, 0
    discoveries = fixes = extra_discoveries = extra_fixes = 0
    productive_searches = 0
    second_search_hand = -1
    challenge_complete = False
    search_reward_used = debug_reward_used = False
    marketing_special_hands = 0
    for hand_number, ids in enumerate(actions):
        cards = [base.BY_ID[i] for i in ids]
        cats = Counter(c["beta_category"] for c in cards)
        qa_special = cats["qa"] == 4
        marketing_special = cats["marketing"] == 4
        balanced = not qa_special and not marketing_special and all(1 <= cats[x] <= 2 for x in ("qa", "marketing", "insider"))
        marketing_special_hands += marketing_special
        # Runtime resolves all Searches before all Debugs, regardless of selection order.
        for card in cards:
            if card["id"] != "search_for_bugs":
                continue
            value = card["beta_value"] * (1.5 if qa_special else 1)
            request = math.floor(1 + value + hidden * .15 * value)
            if balanced:
                request = math.ceil(request * 1.25)
            moved = min(request, hidden)
            extra = 0
            if perk in ("search", "both") and not search_reward_used and hidden > moved:
                extra = 1
                search_reward_used = True
            hidden -= moved + extra
            known += moved + extra
            discoveries += moved + extra
            extra_discoveries += extra
            if moved + extra:
                productive_searches += 1
                if productive_searches == 2:
                    second_search_hand = hand_number
        for card in cards:
            if card["id"] != "debug":
                continue
            value = card["beta_value"] * (1.5 if qa_special else 1)
            request = math.floor(1 + value)
            if balanced:
                request = math.ceil(request * 1.25)
            fixed = min(request, known)
            extra = 0
            if second_search_hand >= 0 and hand_number > second_search_hand:
                challenge_complete = True
            if (perk in ("debug", "both") and not debug_reward_used and
                    second_search_hand >= 0 and hand_number > second_search_hand and known > fixed):
                extra = 1
                debug_reward_used = True
            known -= fixed + extra
            fixes += fixed + extra
            extra_fixes += extra
        raw_marketing = sum(c["beta_value"] for c in cards if c["beta_category"] == "marketing")
        marketing += (math.floor(raw_marketing * 1.5) if marketing_special else
                      math.ceil(raw_marketing * 1.25) if balanced else raw_marketing)
    return {"hidden": hidden, "known": known, "remaining": hidden + known,
            "discoveries": discoveries, "fixes": fixes, "extra_discoveries": extra_discoveries,
            "extra_fixes": extra_fixes, "productive_searches": productive_searches,
            "challenge_complete": challenge_complete,
            "search_reward_used": search_reward_used, "debug_reward_used": debug_reward_used,
            "marketing": marketing, "marketing_special_hands": marketing_special_hands}


def percentile(values, fraction):
    ordered = sorted(values)
    return ordered[math.floor((len(ordered) - 1) * fraction)] if ordered else 0


def summarize(rows):
    if not rows:
        return {"n": 0}
    def mean(field):
        return round(statistics.mean(r[field] for r in rows), 3)
    return {"n": len(rows), "initial_hidden_mean": mean("initial_hidden"),
            "search_eligible_pct": round(100 * sum(r["search_eligible"] for r in rows) / len(rows), 1),
            "challenge_complete_pct": round(100 * sum(r["challenge_complete"] for r in rows) / len(rows), 1),
            "search_useful_pct": round(100 * sum(r["search_useful"] for r in rows) / len(rows), 1),
            "debug_useful_pct": round(100 * sum(r["debug_useful"] for r in rows) / len(rows), 1),
            "extra_discoveries_mean": mean("extra_discoveries"), "extra_fixes_mean": mean("extra_fixes"),
            "remaining_bugs_mean": mean("remaining"), "review_delta_mean": mean("review_delta"),
            "review_delta_median": statistics.median(r["review_delta"] for r in rows),
            "review_unchanged_pct": round(100 * sum(r["review_delta"] == 0 for r in rows) / len(rows), 1),
            "cross_5_up_pct": round(100 * sum(r["base_review"] < 5 <= r["review"] for r in rows) / len(rows), 2),
            "cross_7_up_pct": round(100 * sum(r["base_review"] < 7 <= r["review"] for r in rows) / len(rows), 2),
            "unit_delta_mean": mean("unit_delta"), "net_cents_delta_mean": mean("net_cents_delta"),
            "marketing_mean": mean("marketing"), "marketing_special_hands_mean": mean("marketing_special_hands"),
            "review_delta_p90": percentile([r["review_delta"] for r in rows], .9),
            "review_delta_histogram": dict(sorted(Counter(f'{r["review_delta"]:.1f}' for r in rows).items(), key=lambda pair: float(pair[0])))}


def verify_invariants():
    marketing_ids = ["sign_flippers", "posters", "press_release", "press_interview"]
    marketing_raw = sum(base.BY_ID[i]["beta_value"] for i in marketing_ids)
    all_marketing = replay(0, [marketing_ids], "both")
    assert all_marketing["marketing"] == math.floor(marketing_raw * 1.5)
    assert all_marketing["remaining"] == 0 and all_marketing["extra_fixes"] == 0
    assert replay(20, [["search_for_bugs", "debug"]], "debug")["extra_fixes"] == 0
    two_searches = [["search_for_bugs"], ["search_for_bugs"], ["debug"], ["debug"]]
    assert replay(20, two_searches, "debug")["extra_fixes"] == 1
    assert replay(0, two_searches, "both")["extra_discoveries"] == 0


def main(seed=260926, per_cohort=120):
    verify_invariants()
    rows = []
    genre_by_id = {g["id"]: g for g in base.GENRES}
    for cohort in ("first_20_23", "below_20_optin", "expanded"):
        for sample in range(per_cohort):
            rng = random.Random(seed + sample * 30011 + (0 if cohort == "first_20_23" else 1000003 if cohort == "below_20_optin" else 2000003))
            target = rng.choice([20, 21, 22, 23] if cohort == "first_20_23" else [7, 10, 13, 16, 19])
            owned, spent = (base.roster(target, rng) if cohort != "expanded" else ({c["id"] for c in base.FEATURES}, 0))
            policy = rng.choice(("conservative", "ordinary", "optimized"))
            scores, scope, initial_bugs, _, redraws, synergies, hands = base.production(
                owned, policy, rng, 5500 - spent if cohort != "expanded" else 100000)
            genre = base.choose_genre(owned, policy, rng)
            variance_roll = rng.randrange(100)
            market_bp = base.market(rng)
            for priority_name, priority in PRIORITIES.items():
                for budget in (2, 4):
                    for action_policy in ("fixed", "qa_first", "marketing_first"):
                        beta_rng = random.Random(seed + sample * 733 + budget * 59 + sum(ord(c) for c in priority_name + action_policy) + (0 if cohort == "first_20_23" else 100003 if cohort == "below_20_optin" else 200003))
                        hands_transcript = schedule(initial_bugs, priority, budget, action_policy, beta_rng)
                        actions = [x[1] for x in hands_transcript]
                        outcomes = {name: replay(initial_bugs, actions, name) for name in PERKS}
                        baseline = outcomes["none"]
                        baseline_review = base.review(scores, scope, baseline["remaining"], genre, rng, variance_roll)[0]
                        baseline_units = base.units(baseline_review, baseline["marketing"], 0, market_bp)
                        baseline_net = baseline_units * 999 * 70 // 100
                        for name, result in outcomes.items():
                            review = base.review(scores, scope, result["remaining"], genre, rng, variance_roll)[0]
                            sold = base.units(review, result["marketing"], 0, market_bp)
                            net = sold * 999 * 70 // 100
                            rows.append({"cohort": cohort, "sample": sample, "target_scope": target if cohort != "expanded" else sum(base.BY_ID[i]["scope"] for i in owned),
                                         "production_policy": policy, "priority": priority_name, "budget": budget,
                                         "action_policy": action_policy, "perk": name, "initial_hidden": initial_bugs,
                                         "hidden_band": "0" if initial_bugs == 0 else "1-2" if initial_bugs <= 2 else "3-4" if initial_bugs <= 4 else "5+",
                                         "search_eligible": any("search_for_bugs" in a for a in actions) and initial_bugs > 0,
                                         "challenge_complete": result["challenge_complete"],
                                         "search_useful": result["search_reward_used"], "debug_useful": result["debug_reward_used"],
                                         "extra_discoveries": result["extra_discoveries"], "extra_fixes": result["extra_fixes"],
                                         "productive_searches": result["productive_searches"], "remaining": result["remaining"],
                                         "base_review": baseline_review, "review": review,
                                         "review_delta": round(review - baseline_review, 1),
                                         "base_units": baseline_units, "units": sold, "unit_delta": sold - baseline_units,
                                         "base_net_cents": baseline_net, "net_cents": net, "net_cents_delta": net - baseline_net,
                                         "marketing": result["marketing"], "marketing_special_hands": result["marketing_special_hands"],
                                         "draws": [x[0] for x in hands_transcript], "actions": actions})
    groups = defaultdict(list)
    for r in rows:
        for key in ((r["cohort"], r["perk"]), (r["cohort"], r["perk"], r["hidden_band"]),
                    (r["cohort"], r["perk"], r["priority"], str(r["budget"]), r["action_policy"])):
            groups["|".join(key)].append(r)
        if r["perk"] == "both":
            groups["|".join((r["cohort"], "both", "extra_hidden_available", str(r["search_useful"])))].append(r)
            groups["|".join((r["cohort"], "both", "extra_known_available", str(r["debug_useful"])))].append(r)
    by_key = {(r["cohort"], r["sample"], r["priority"], r["budget"], r["action_policy"], r["perk"]): r for r in rows}
    interactions = {}
    for cohort in ("first_20_23", "below_20_optin", "expanded"):
        cases = [r for r in rows if r["cohort"] == cohort and r["perk"] == "both"]
        blocked = sum(by_key[(cohort, r["sample"], r["priority"], r["budget"], r["action_policy"], "none")]["productive_searches"] >= 2 and r["productive_searches"] < 2 for r in cases)
        interactions[cohort] = {"paired_cases": len(cases), "second_search_prevented_by_first_bonus": blocked,
                                "challenge_complete_but_no_extra_known_bug_pct": round(100 * sum(r["challenge_complete"] and not r["debug_useful"] for r in cases) / len(cases), 2)}
    policy_tradeoffs = {}
    for cohort in ("first_20_23", "below_20_optin", "expanded"):
        for priority in PRIORITIES:
            for budget in (2, 4):
                pairs = []
                for sample in range(per_cohort):
                    qa = by_key[(cohort, sample, priority, budget, "qa_first", "both")]
                    marketing = by_key[(cohort, sample, priority, budget, "marketing_first", "both")]
                    pairs.append((qa, marketing))
                def delta(field):
                    return round(statistics.mean(a[field] - b[field] for a, b in pairs), 2)
                policy_tradeoffs["|".join((cohort, priority, str(budget)))] = {
                    "n": len(pairs), "qa_minus_marketing_output": delta("marketing"),
                    "qa_minus_awareness": delta("marketing"), "qa_minus_month1_units": delta("units"),
                    "qa_minus_70pct_net_cents": delta("net_cents"), "qa_minus_review": delta("review"),
                    "qa_minus_remaining_bugs": delta("remaining"),
                    "elapsed_productive_cycles_each": budget}
    report = {"seed": seed, "samples_per_cohort": per_cohort,
              "method": "Paired Beta card draws/actions, Review variance and market snapshots across four perk cases; fanbase_playtest_v1 production model.",
              "summary": {key: summarize(value) for key, value in sorted(groups.items())},
              "interactions": interactions, "policy_tradeoffs": policy_tradeoffs, "rows": rows}
    with gzip.open(OUTPUT, "wt", encoding="utf-8") as out:
        json.dump(report, out, separators=(",", ":"))
    print(f"Wrote {OUTPUT}; {len(rows)} paired-case rows")
    for cohort in ("first_20_23", "below_20_optin", "expanded"):
        for perk in PERKS:
            key = cohort + "|" + perk
            print(key, report["summary"][key])


if __name__ == "__main__":
    main(int(sys.argv[1]) if len(sys.argv) > 1 else 260926,
         int(sys.argv[2]) if len(sys.argv) > 2 else 120)
