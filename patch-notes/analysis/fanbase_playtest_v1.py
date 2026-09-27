"""Read-only Patch Notes draw-by-draw fanbase balance experiment.

Uses committed JSON ledgers and ports the cited Godot rules. This is an
analysis policy model, not a gameplay implementation or a human-skill model.
Run with bundled Python: python analysis/fanbase_playtest_v1.py [seed] [n].
"""
from __future__ import annotations

import itertools
import json
import math
import random
import statistics
import sys
from collections import Counter, defaultdict
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
CARDS = json.loads((ROOT / "data/card_ledger.json").read_text(encoding="utf-8"))
GENRES = json.loads((ROOT / "data/primitive_predevelopment.json").read_text(encoding="utf-8"))["genres"]
MARKETS = json.loads((ROOT / "data/primitive_market_forecast_ledger.json").read_text(encoding="utf-8"))
FEATURES = [c for c in CARDS if c["type"] == "feature" and c["phase"] in ("design", "alpha")]
PASSES = [c for c in CARDS if c["type"] == "pass"]
BETA = [c for c in CARDS if c["phase"] == "beta"]
BY_ID = {c["id"]: c for c in CARDS}
CORES = ("graphics", "sound", "technology", "design")
START = {"text", "4_color_palette", "8_bit_sound", "keyboard_and_mouse", "controller", "controls"}
OPTIONAL = [c for c in FEATURES if c["id"] not in START]
SCOPE_START = sum(BY_ID[x]["scope"] for x in START)


def rnd(x: float) -> int:
    return math.floor(x + 0.5)


def weighted(items, weights, rng):
    total = sum(weights)
    target = rng.random() * total
    acc = 0.0
    for item, weight in zip(items, weights):
        acc += weight
        if target < acc:
            return item
    return items[-1]


def price(card):
    return (card["scope"] + 1) * 150


def roster(target, rng):
    if target == 7:
        return set(START), 0
    for _ in range(3000):
        options = OPTIONAL.copy()
        rng.shuffle(options)
        chosen = set(START)
        scope, spent = SCOPE_START, 0
        for card in options:
            cost = price(card)
            if scope + card["scope"] <= target and spent + cost <= 4000 and rng.random() < 0.88:
                chosen.add(card["id"])
                scope += card["scope"]
                spent += cost
            if scope == target:
                return chosen, spent
    raise RuntimeError(f"No sampled legal roster for Scope {target}")


def card_weight(card, priority):
    return priority[card["primary_stat"]] * card["primary_value"] + (
        priority[card["secondary_stat"]] * card["secondary_value"] if card.get("secondary_stat") else 0
    )


def draw_production(phase, owned, exhausted, priority, rng):
    available = [c for c in FEATURES if c["phase"] == phase and c["id"] in owned and c["id"] not in exhausted]
    pool = []
    for _ in range(7):
        options = sorted(available + PASSES, key=lambda c: c["id"])
        card = weighted(options, [card_weight(c, priority) for c in options], rng)
        pool.append(card)
        if card["type"] == "feature":
            available.remove(card)
    return pool


def redraw_production(pool, position, owned, exhausted, priority, rng):
    old = pool[position]
    if old["type"] == "feature":
        options = [c for c in FEATURES if c["phase"] == old["phase"] and c["id"] in owned
                   and c["id"] not in exhausted and c["id"] not in {p["id"] for p in pool}]
    else:
        options = [c for c in PASSES if c["id"] != old["id"]]
    if not options:
        return False
    options.sort(key=lambda c: c["id"])
    pool[position] = weighted(options, [card_weight(c, priority) for c in options], rng)
    return True


def printed(card):
    return card["primary_value"] + card["secondary_value"]


def hand_output(hand, scores):
    base = {k: 0 for k in CORES}
    scope = 0
    pressure = 0.0
    has_feature = False
    for c in hand:
        base[c["primary_stat"]] += c["primary_value"]
        if c.get("secondary_stat"):
            base[c["secondary_stat"]] += c["secondary_value"]
        scope += c["scope"]
        if c["type"] == "feature":
            has_feature = True
            pressure += printed(c) * c["scope"] / 18.0
    projected = [scores[k] + base[k] for k in CORES]
    mean = sum(projected) / 4
    balanced = has_feature and all(mean * 0.8 <= x <= mean * 1.2 for x in projected)
    specialized = len({c["primary_stat"] for c in hand}) == 1
    multiplier = 1.5 if specialized else 1.2 if balanced else 1.0
    added = {k: rnd(base[k] * multiplier) for k in CORES}
    return added, scope, pressure, specialized, balanced


def choose_hand(pool, scores, scope, policy, rng):
    if policy == "conservative":
        return rng.sample(range(7), 4)
    candidates = []
    for indices in itertools.combinations(range(7), 4):
        hand = [pool[i] for i in indices]
        additions, gained_scope, _, specialized, balanced = hand_output(hand, scores)
        after = [scores[k] + additions[k] for k in CORES]
        if policy == "ordinary":
            value = 3.5 * min(gained_scope, max(0, 30 - scope)) + sum(additions.values()) + (3 if specialized else 2 if balanced else 0)
        else:
            mean = sum(after) / 4
            deviation = math.sqrt(sum((x - mean) ** 2 for x in after) / 4)
            value = 5 * min(gained_scope, max(0, 30 - scope)) + sum(additions.values()) - 0.7 * deviation
        candidates.append((value + rng.random() * 0.00001, indices))
    return list(max(candidates)[1])


def bug_final(pressure, rng, perfect=False):
    if perfect:
        pressure *= 0.8
    base = math.floor(pressure)
    base += rng.random() < pressure - base
    r = rng.random()
    variance = -2 if r < .08 else -1 if r < .25 else 0 if r < .75 else 1 if r < .92 else 2
    return max(0, base + variance)


def production(owned, policy, rng, starting_cash):
    scores = {k: 0 for k in CORES}
    scope = 0
    bugs = 0
    cash = starting_cash
    priority = {k: 25 for k in CORES}
    redrawn = 0
    synergy = 0
    played = 0
    for phase, hands in (("design", 2 if policy != "optimized" else 3),
                         ("alpha", 2 if policy == "conservative" else 3 if policy == "ordinary" else 4)):
        exhausted = set()
        pressure = 0.0
        redraws = 4
        for _ in range(hands):
            pool = draw_production(phase, owned, exhausted, priority, rng)
            attempts = 0 if policy == "conservative" else 1 if policy == "ordinary" else 2
            for _ in range(attempts):
                if redraws <= 0:
                    break
                utility = [printed(c) + 2 * c["scope"] for c in pool]
                index = min(range(7), key=lambda i: utility[i])
                if redraw_production(pool, index, owned, exhausted, priority, rng):
                    redraws -= 1
                    redrawn += 1
            indices = choose_hand(pool, scores, scope, policy, rng)
            hand = [pool[i] for i in indices]
            cost = sum(10 * (printed(c) + 2 * c["scope"]) for c in hand if c["type"] == "feature")
            if cost > cash:
                break
            cash -= cost
            additions, gained_scope, bug_pressure, specialized, balanced = hand_output(hand, scores)
            for k in CORES:
                scores[k] += additions[k]
            scope += gained_scope
            pressure += bug_pressure
            synergy += specialized or balanced
            played += 1
            exhausted.update(c["id"] for c in hand if c["type"] == "feature")
            redraws = min(4, redraws + 1)
        mean = sum(scores.values()) / 4
        perfect = phase == "design" and all(mean * .95 <= x <= mean * 1.05 for x in scores.values())
        bugs += bug_final(pressure, rng, perfect)
    return scores, scope, bugs, cash, redrawn, synergy, played


def draw_beta(exhausted, priority, rng):
    available = {cat: [c for c in BETA if c["beta_category"] == cat and c["id"] not in exhausted]
                 for cat in ("qa", "marketing", "insider")}
    pool = []
    for _ in range(7):
        cats = [cat for cat in ("qa", "marketing", "insider") if available[cat]]
        cat = weighted(cats, [priority[cat] for cat in cats], rng)
        choices = sorted(available[cat], key=lambda c: c["id"])
        card = weighted(choices, [2 if c["id"] == "debug" else 1 for c in choices], rng)
        pool.append(card)
        if not card["renewable"]:
            available[cat].remove(card)
    return pool


def beta_stage(bugs, policy, rng):
    if policy == "conservative":
        return bugs, 0, 0
    hidden, known = bugs, 0
    marketing = 0
    exhausted = set()
    hands = 2 if policy == "ordinary" else 4
    priority = {"qa": 35, "marketing": 35, "insider": 30} if policy == "ordinary" else {"qa": 50, "marketing": 35, "insider": 15}
    qa_cards = 0
    for _ in range(hands):
        pool = draw_beta(exhausted, priority, rng)
        ranked = sorted(range(7), key=lambda i: (
            (10 if pool[i]["id"] == "search_for_bugs" and hidden else 0)
            + (10 if pool[i]["id"] == "debug" and (known or hidden) else 0)
            + (pool[i]["beta_value"] * (2 if policy == "optimized" else 1) if pool[i]["beta_category"] == "marketing" else 0)
            + rng.random() * .01), reverse=True)
        chosen = [pool[i] for i in ranked[:4]]
        qa_special = all(c["beta_category"] == "qa" for c in chosen)
        counts = Counter(c["beta_category"] for c in chosen)
        balanced = not qa_special and all(1 <= counts[x] <= 2 for x in ("qa", "marketing", "insider"))
        for c in chosen:
            if c["id"] == "search_for_bugs":
                value = c["beta_value"] * (1.5 if qa_special else 1)
                request = math.floor(1 + value + hidden * .15 * value)
                if balanced: request = math.ceil(request * 1.25)
                moved = min(request, hidden)
                hidden -= moved
                known += moved
                qa_cards += 1
            elif c["id"] == "debug":
                value = c["beta_value"] * (1.5 if qa_special else 1)
                request = math.floor(1 + value)
                if balanced: request = math.ceil(request * 1.25)
                known -= min(request, known)
                qa_cards += 1
            elif c["beta_category"] == "marketing":
                marketing += c["beta_value"]
            if not c["renewable"]:
                exhausted.add(c["id"])
        if balanced:
            # Runtime multiplies the hand's total Marketing gain before commit.
            raw = sum(c["beta_value"] for c in chosen if c["beta_category"] == "marketing")
            marketing += math.ceil(raw * 1.25) - raw
    return hidden + known, marketing, qa_cards


def choose_genre(owned, policy, rng):
    if policy != "optimized":
        return rng.choice(GENRES)
    potential = [sum(c["primary_value"] * (c["primary_stat"] == stat) + c["secondary_value"] * (c.get("secondary_stat") == stat)
                     for c in FEATURES if c["id"] in owned) for stat in CORES]
    total = sum(potential)
    return min(GENRES, key=lambda g: sum(abs(100 * potential[i] / total - g["ratios"][i]) for i in range(4)))


def review(scores, scope, bugs, genre, rng, variance_roll=None):
    ratios = [min(scores[k] / 33, 1.25) for k in CORES]
    average = statistics.mean(ratios)
    deviation = statistics.pstdev(ratios)
    production_rating = min(10, max(0, (average - .5 * deviation) * 8))
    scope_completion = min(scope / 30, 1)
    bug_multiplier = max(.25, 1 - bugs / 30)
    roll = rng.randrange(100) if variance_roll is None else variance_roll
    variance = -.5 if roll < 10 else -.25 if roll < 30 else 0 if roll < 70 else .25 if roll < 90 else .5
    pregenre = min(10, max(0, production_rating * scope_completion * bug_multiplier + variance))
    total = sum(scores.values())
    genre_deviation = sum(abs(100 * scores[k] / total - genre["ratios"][i]) for i, k in enumerate(CORES)) / 2 if total else 0
    fit = max(.75, 1 - .01 * max(0, genre_deviation - 6))
    final = math.floor(min(10, max(0, pregenre * fit)) * 10 + .5) / 10
    return final, production_rating, scope_completion, fit, genre_deviation


def units(review_score, marketing, fan_awareness, market_bp):
    return 500 * rnd(review_score * 10) * (300 + marketing + fan_awareness) * market_bp // (70 * 200 * 10000)


def market(rng):
    return weighted(MARKETS, [x["selection_weight"] for x in MARKETS], rng)["launch_demand_basis_points"]


def fan_delta(fans, review_score, sold, marketing, market_bp, curve):
    fan_awareness = math.floor(150 * fans / (fans + 300)) if fans else 0
    if review_score > 5:
        t = (review_score - 5) / 2
        rate = .08 * min(1.5, math.sqrt(t) if curve == "sqrt" else t)
        return math.floor(sold * rate), 0
    if review_score == 5:
        return 0, 0
    neutral_reach = 500 * (300 + marketing + fan_awareness) * market_bp // (200 * 10000)
    loss = math.floor(min(fans, neutral_reach) * .15 * (5 - review_score))
    return 0, min(fans, loss)


def summarize(rows):
    values = sorted(r["review"] for r in rows)
    n = len(values)
    pct = lambda p: values[min(n - 1, math.floor((n - 1) * p))]
    hist = Counter(f"{x:.1f}" for x in values)
    return {"n": n, "p10": pct(.1), "median": pct(.5), "p90": pct(.9),
            "below5_pct": round(100 * sum(x < 5 for x in values) / n, 1),
            "at5_pct": round(100 * sum(x == 5 for x in values) / n, 1),
            "above5_pct": round(100 * sum(x > 5 for x in values) / n, 1),
            "mean_scope": round(statistics.mean(r["scope"] for r in rows), 2),
            "mean_bugs": round(statistics.mean(r["bugs"] for r in rows), 2),
            "mean_core": [round(statistics.mean(r["scores"][k] for r in rows), 1) for k in CORES],
            "mean_fit": round(statistics.mean(r["fit"] for r in rows), 3),
            "mean_units": round(statistics.mean(r["units"] for r in rows), 1),
            "histogram": dict(sorted(hist.items(), key=lambda kv: float(kv[0])))}


def main(seed=260926, per_cell=250):
    rng = random.Random(seed)
    assert SCOPE_START == 7 and len(FEATURES) == 27 and len(PASSES) == 4
    # Anchor parity with the committed Review examples.
    anchor = {k: x for k, x in zip(CORES, [27, 30, 36, 36])}
    assert review(anchor, 30, 0, {"ratios": [30, 20, 30, 20]}, rng, 50)[0] == 7.0
    groups = defaultdict(list)
    for cohort, targets in (("first", [20, 21, 22, 23]), ("low_optin", [7, 10, 13, 16, 19]), ("expanded", [39])):
        for target in targets:
            for policy in ("conservative", "ordinary", "optimized"):
                for _ in range(per_cell):
                    owned, spent = (roster(target, rng) if cohort != "expanded" else ({c["id"] for c in FEATURES}, 0))
                    scores, scope, bugs, cash_after_play, redrawn, synergy, hands = production(owned, policy, rng, 5500 - spent if cohort != "expanded" else 100000)
                    bugs_after, marketing, qa_cards = beta_stage(bugs, policy, rng)
                    genre = choose_genre(owned, policy, rng)
                    variance_roll = rng.randrange(100)
                    score, rating, completion, fit, deviation = review(scores, scope, bugs_after, genre, rng, variance_roll)
                    bp = market(rng)
                    sold = units(score, marketing, 0, bp)
                    row = {"cohort": cohort, "target": target, "policy": policy, "review": score,
                           "scores": scores, "scope": scope, "bugs": bugs_after, "preqa_bugs": bugs,
                           "cash_after_play": cash_after_play if cohort != "expanded" else None,
                           "redraws": redrawn, "synergies": synergy, "hands": hands, "qa_cards": qa_cards,
                           "genre": genre["id"], "fit": fit, "deviation": deviation, "variance_roll": variance_roll,
                           "marketing": marketing, "market_bp": bp, "units": sold}
                    groups[(cohort, target, policy)].append(row)
    first = [r for (cohort, _, _), rows in groups.items() if cohort == "first" for r in rows]
    expanded = [r for (cohort, _, _), rows in groups.items() if cohort == "expanded" for r in rows]
    genre_by_id = {g["id"]: g for g in GENRES}
    qa_sensitivity = {}
    for cohort, source in (("first", first), ("expanded", expanded)):
        for label, bug_field in (("before_qa", "preqa_bugs"), ("after_policy_qa", "bugs")):
            counterfactual = [review(r["scores"], r["scope"], r[bug_field], genre_by_id[r["genre"]], rng, r["variance_roll"])[0] for r in source]
            qa_sensitivity[f"{cohort}_{label}"] = {"median": statistics.median(counterfactual), "above5_pct": round(100 * sum(x > 5 for x in counterfactual) / len(counterfactual), 1)}
        clean = [review(r["scores"], r["scope"], 0, genre_by_id[r["genre"]], rng, r["variance_roll"])[0] for r in source]
        qa_sensitivity[f"{cohort}_all_bugs_fixed"] = {"median": statistics.median(clean), "above5_pct": round(100 * sum(x > 5 for x in clean) / len(clean), 1)}
    gain = {}
    for curve in ("linear", "sqrt"):
        for marketing in (0, 100):
            for cohort, source in (("first", first), ("expanded", expanded)):
                gains = [fan_delta(0, r["review"], units(r["review"], marketing, 0, r["market_bp"]), marketing, r["market_bp"], curve)[0] for r in source]
                gain[f"{cohort}_{curve}_m{marketing}"] = {"mean": round(statistics.mean(gains), 1), "median": statistics.median(gains),
                                               "p90": sorted(gains)[math.floor(.9 * (len(gains) - 1))], "zero_pct": round(100 * sum(x == 0 for x in gains) / len(gains), 1)}
    compounding = {}
    for curve in ("linear", "sqrt"):
        for marketing in (0, 100):
            trajectories = []
            weak_recovery = []
            for _ in range(250):
                fans = 0
                history = []
                for release in range(20):
                    row = rng.choice(first if release == 0 else expanded)
                    awareness = math.floor(150 * fans / (fans + 300)) if fans else 0
                    sold = units(row["review"], marketing, awareness, row["market_bp"])
                    gained, lost = fan_delta(fans, row["review"], sold, marketing, row["market_bp"], curve)
                    fans = max(0, fans + gained - lost)
                    history.append(fans)
                trajectories.append(history)
                # Real low-Review sample, then sampled expanded-pool releases.
                poor = [r for r in first if r["review"] < 5]
                if poor:
                    prior = history[8]
                    row = rng.choice(poor)
                    awareness = math.floor(150 * prior / (prior + 300)) if prior else 0
                    sold = units(row["review"], marketing, awareness, row["market_bp"])
                    gained, lost = fan_delta(prior, row["review"], sold, marketing, row["market_bp"], curve)
                    recovered = max(0, prior + gained - lost)
                    after_weak = recovered
                    for _ in range(3):
                        row = rng.choice(expanded)
                        awareness = math.floor(150 * recovered / (recovered + 300)) if recovered else 0
                        sold = units(row["review"], marketing, awareness, row["market_bp"])
                        gained, lost = fan_delta(recovered, row["review"], sold, marketing, row["market_bp"], curve)
                        recovered = max(0, recovered + gained - lost)
                    weak_recovery.append((prior, after_weak, recovered))
            compounding[f"{curve}_m{marketing}"] = {
                "fans_after_10_median": statistics.median(x[9] for x in trajectories),
                "fans_after_20_p10": sorted(x[19] for x in trajectories)[24],
                "fans_after_20_median": statistics.median(x[19] for x in trajectories),
                "fans_after_20_p90": sorted(x[19] for x in trajectories)[224],
                "weak_release_mean_loss": round(statistics.mean(a - b for a, b, _ in weak_recovery), 1) if weak_recovery else None,
                "recovered_prior_after_three_pct": round(100 * sum(after >= prior for prior, _, after in weak_recovery) / len(weak_recovery), 1) if weak_recovery else None,
            }
    report = {"seed": seed, "per_cell": per_cell, "first_n": len(first), "expanded_n": len(expanded),
              "low_optin_n": sum(len(rows) for (cohort, _, _), rows in groups.items() if cohort == "low_optin"),
              "first": summarize(first), "expanded": summarize(expanded),
              "by_cell": {f"{c}_{t}_{p}": summarize(rows) for (c, t, p), rows in groups.items()},
              "fan_gain_zero_start": gain, "qa_sensitivity": qa_sensitivity, "compounding": compounding,
              "genre": {g["id"]: summarize([r for r in first if r["genre"] == g["id"]]) for g in GENRES}}
    print(json.dumps(report, indent=2))


if __name__ == "__main__":
    main(int(sys.argv[1]) if len(sys.argv) > 1 else 260926,
         int(sys.argv[2]) if len(sys.argv) > 2 else 250)
