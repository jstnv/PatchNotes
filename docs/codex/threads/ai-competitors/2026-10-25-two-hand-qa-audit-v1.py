"""Read-only public-card audit of frozen rival Beta choices, seed 4417."""

import itertools
import json
import math
from pathlib import Path

THREAD = Path(__file__).resolve().parent
WORLD = THREAD / "sims/rival-proportional-beta-control-4417-20261024-v1/world-report.json"
OUTPUT = THREAD / "sims/rival-two-hand-qa-audit-4417-20261025-v1.json"


def assess(cards):
    if len(cards) != 4 or any(c.get("type") != "beta" for c in cards):
        return None
    counts = {"qa": 0, "marketing": 0, "insider": 0}
    search, debug, marketing, payout, finite = [], [], 0, 0, set()
    for card in cards:
        definition = card.get("definition", "")
        if not card.get("renewable", True):
            if definition in finite:
                return None
            finite.add(definition)
        category = card.get("beta_category", "")
        value = card.get("beta_value", -1)
        if category not in counts or value < 0:
            return None
        counts[category] += 1
        if category == "qa":
            if card.get("qa_operation") == "search":
                search.append(value)
            elif card.get("qa_operation") == "debug":
                debug.append(value)
            else:
                return None
        elif category == "marketing":
            marketing += value
        elif definition == "playtest_rival_games":
            payout += 100000
    kind = ("qa" if counts["qa"] == 4 else
            "marketing" if counts["marketing"] == 4 else
            "balanced" if counts == {"qa": 2, "marketing": 1, "insider": 1}
            else "none")
    if kind == "marketing":
        marketing = math.floor(marketing * 1.5)
    elif kind == "balanced":
        marketing = math.ceil(marketing * 1.25)
    return {"tokens": sorted(c["token"] for c in cards), "kind": kind,
            "search": search, "debug": debug, "marketing": marketing,
            "payout_cents": payout}


def remaining(hand, known, hidden):
    hidden_left, known_left = hidden, known
    for value in hand["search"]:
        effective = value * (1.5 if hand["kind"] == "qa" else 1.0)
        requested = math.floor(1 + effective + hidden_left * 0.15 * effective)
        if hand["kind"] == "balanced":
            requested = math.ceil(requested * 1.25)
        found = min(requested, hidden_left)
        hidden_left -= found
        known_left += found
    for value in hand["debug"]:
        effective = value * (1.5 if hand["kind"] == "qa" else 1.0)
        requested = math.floor(1 + effective)
        if hand["kind"] == "balanced":
            requested = math.ceil(requested * 1.25)
        known_left -= min(requested, known_left)
    return hidden_left + known_left


def current_pick(cards, known, upper):
    reference = assess(cards[:4])
    best, best_improvement = None, -1
    for combo in itertools.combinations(cards, 4):
        hand = assess(combo)
        if hand is None or hand["kind"] not in ("qa", "balanced") or not hand["search"] or not hand["debug"]:
            continue
        differences = [remaining(reference, known, hidden) - remaining(hand, known, hidden)
                       for hidden in range(upper + 1)]
        if min(differences) < 0 or max(differences) <= 0:
            continue
        improvement = sum(differences)
        tie = (hand["marketing"], hand["payout_cents"], [-t for t in hand["tokens"]])
        if best is None or (improvement, tie) > (best_improvement, best[1]):
            best, best_improvement = (hand, tie), improvement
    return best[0] if best else reference


def audit():
    if OUTPUT.exists():
        raise SystemExit(f"Refusing to replace {OUTPUT}")
    world = json.loads(WORLD.read_text(encoding="utf-8"))
    if world["source_identity"] != "5da7bc70f45fc63d33e6f5293e77338992038810b84a2c964ff47aff7a2b1a64":
        raise SystemExit("Unexpected frozen source")
    distinct = {}
    for row in world["rival_choices"]:
        if row["phase"] == "beta" and row["request"] == "play" and row["hand_revision"] in (1, 2):
            key = (row["project_id"], row["sequence"])
            if key in distinct and (row["candidates"], row["selected_tokens"]) != (distinct[key]["candidates"], distinct[key]["selected_tokens"]):
                raise SystemExit(f"Duplicate accepted sequence disagrees: {key}")
            distinct[key] = row
    results = []
    for row in distinct.values():
        cards = sorted(row["candidates"], key=lambda c: c["token"])
        known, upper = row["known_bugs"], 30  # PrimitivePredevelopment.REQUIRED_SCOPE in this frozen source.
        selected = assess([c for c in cards if c["token"] in row["selected_tokens"]])
        mirrored = current_pick(cards, known, upper)
        if selected is None or selected["tokens"] != mirrored["tokens"]:
            raise SystemExit(f"Current selector mirror mismatch: {row['project_id']} seq {row['sequence']}")
        reference_values = [remaining(selected, known, hidden) for hidden in range(upper + 1)]
        alternatives = []
        for combo in itertools.combinations(cards, 4):
            hand = assess(combo)
            if hand is None or hand["kind"] not in ("qa", "balanced") or not hand["search"] or not hand["debug"]:
                continue
            values = [remaining(hand, known, hidden) for hidden in range(upper + 1)]
            if sum(values) >= sum(reference_values):
                continue
            alternatives.append({"tokens": hand["tokens"], "kind": hand["kind"],
                                 "sum_remaining": sum(values), "marketing": hand["marketing"],
                                 "payout_cents": hand["payout_cents"],
                                 "dominated_some_hidden": any(a > b for a, b in zip(values, reference_values))})
        alternatives.sort(key=lambda a: (a["sum_remaining"], -a["marketing"], -a["payout_cents"], a["tokens"]))
        results.append({"project": row["project_id"], "sequence": row["sequence"],
                        "world_cycle": row["cycle"], "hand_revision": row["hand_revision"],
                        "known_bugs": known, "selected": selected,
                        "selected_sum_remaining": sum(reference_values),
                        "qa_card_count": sum(c["beta_category"] == "qa" for c in cards),
                        "eligible_better_qa_count": len(alternatives),
                        "best_better_qa": alternatives[0] if alternatives else None})
    results.sort(key=lambda r: (r["world_cycle"], r["project"], r["hand_revision"]))
    summary = {"distinct_first_two_hands": len(results),
               "selected_search_debug": sum(bool(r["selected"]["search"] and r["selected"]["debug"]) for r in results),
               "missed_better_qa": sum(r["best_better_qa"] is not None for r in results),
               "missed_due_to_dominance_some_hidden": sum(bool(r["best_better_qa"] and r["best_better_qa"]["dominated_some_hidden"]) for r in results)}
    output = {"world": str(WORLD.relative_to(THREAD)), "source_identity": world["source_identity"],
              "public_proxy_hidden_range": [0, 30], "summary": summary, "hands": results}
    OUTPUT.write_text(json.dumps(output, indent=2) + "\n", encoding="utf-8")
    print(json.dumps(summary))


if __name__ == "__main__":
    audit()
