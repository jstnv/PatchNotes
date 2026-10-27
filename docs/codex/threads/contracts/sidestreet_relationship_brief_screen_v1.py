"""Read-only combinatorial screen for a proposed one-hand SideStreet Brief.

This is not a game simulator. It never mutates the authoritative project.
"""

from __future__ import annotations

import csv
import hashlib
import itertools
import json
from pathlib import Path


HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[3]
EXPECTED_HASHES = {
    "patch-notes/scripts/studio_specialties.gd": "D617066C2585DA1AB9C59D0C3CE3EBB20406A3136EFFCA337231EEFA01FFEBDF",
    "patch-notes/scripts/cards/feature_store_catalog.gd": "12487E4C089E102D8A47C008D94B9B6223A1AF3D00A9297ABAA0F51BC1F5425E",
    "patch-notes/data/card_ledger.json": "0F093B0BA907043120C3E6E529511322E6E0B99358ADF6D69C80D5C174CFC83C",
    "patch-notes/scripts/contracts/contract_challenges.gd": "6BE5F579DB1CC556522FFD00D772FCCD3EE1282A9EEF0D423448AF6BF54114A9",
    "patch-notes/scripts/contracts/contract_state.gd": "7178F7011C0780000885CB774CC83C7B05FE988BAB8A7F31969EB32C78A80375",
}
for relative, expected in EXPECTED_HASHES.items():
    observed = hashlib.sha256((ROOT / relative).read_bytes()).hexdigest().upper()
    if observed != expected:
        raise RuntimeError(f"Source drift: {relative}: {observed}")

ledger = json.loads((ROOT / "patch-notes/data/card_ledger.json").read_text(encoding="utf-8"))
cards = {entry["id"]: entry for entry in ledger}
common = {
    "text", "4_color_palette", "8_bit_sound", "keyboard_and_mouse", "controller", "controls"
}
rules = {
    "action": ({"graphics", "technology"}, {"general_combat"}),
    "adventure": ({"design"}, {"exploration", "maps"}),
    "role_playing": ({"design"}, {"menu_system", "maps"}),
    "strategy": ({"technology"}, {"score_system", "lives_system", "general_combat"}),
    "simulation": ({"technology"}, {"local_leaderboards", "score_system"}),
    "puzzle": ({"design"}, {"menu_system", "scrolling"}),
    "sports": ({"technology"}, {"music"}),
    "racing": ({"technology"}, {"sprites", "levels"}),
}
features = [
    item for item in ledger
    if item["type"] == "feature" and item["phase"] in ("design", "alpha")
]
passes = [cards[name] for name in ("graphics_pass", "sound_pass", "technology_pass", "design_pass")]
if len(features) != 27 or len(passes) != 4 or any(x["type"] != "pass" for x in passes):
    raise RuntimeError("Primitive/pass inventory differs from the declared source reconstruction")
if any(not 1 <= int(x["scope"]) <= 3 for x in features) or any(int(x["scope"]) != 0 for x in passes):
    raise RuntimeError("Unexpected one-hand Scope bound")

core_index = {name: index for index, name in enumerate(("graphics", "sound", "technology", "design"))}
thresholds = {"current_12_4": (12, 4), "A_4_4": (4, 4), "B_5_3": (5, 3), "C_6_2": (6, 2)}


def roster_for(specialty: str) -> list[dict]:
    core_names, signatures = rules[specialty]
    owned = []
    for card in features:
        included = card["id"] in common or card["id"] in signatures
        included |= any(
            card[f"{prefix}_stat"] in core_names and int(card[f"{prefix}_value"]) > 0
            for prefix in ("primary", "secondary")
        )
        if included:
            owned.append(card)
    if not common.issubset({x["id"] for x in owned}) or not signatures.issubset({x["id"] for x in owned}):
        raise RuntimeError(f"Incomplete starter roster: {specialty}")
    return owned


def hand_score(hand: tuple[dict, ...]) -> tuple[int, int]:
    scope = sum(int(card["scope"]) for card in hand)
    same_primary = len({card["primary_stat"] for card in hand}) == 1
    multiplier = 3 if same_primary else 2
    half_cores = [0, 0, 0, 0]
    for card in hand:
        for prefix in ("primary", "secondary"):
            stat = card[f"{prefix}_stat"]
            if stat:
                half_cores[core_index[stat]] += multiplier * int(card[f"{prefix}_value"])
    numerator = 4 * min(scope, 6) + sum(min(value, 6) for value in half_cores)
    completion_bp = 10000 * numerator // 48
    if not 0 <= completion_bp <= 10000 or not 0 <= scope <= 9:
        raise RuntimeError("Scope or completion outside declared bound")
    return scope, completion_bp


rows = []
witnesses = {}
for specialty in rules:
    owned = roster_for(specialty)
    by_threshold = {
        name: {
            "full": 0, "partial": 0, "miss": 0, "both_at_least_5000": 0,
            "both_full": 0, "combined_max_bp": 0, "max_completion_when_promise_full_bp": 0,
            "completion_min_bp": 10000, "completion_max_bp": 0,
            "scope_max": 0, "scope_min": 9, "count": 0,
        }
        for name in thresholds
    }
    witness = {name: {"full": None, "partial": None, "miss": None} for name in thresholds}
    witness["all_pass"] = None
    witness["max_scope"] = None
    for feature_count in range(5):
        for chosen_features in itertools.combinations(owned, feature_count):
            for chosen_passes in itertools.combinations_with_replacement(passes, 4 - feature_count):
                hand = chosen_features + chosen_passes
                scope, completion = hand_score(hand)
                ids = [card["id"] for card in hand]
                if feature_count == 0 and witness["all_pass"] is None:
                    witness["all_pass"] = {"ids": ids, "scope": scope, "completion_bp": completion}
                if witness["max_scope"] is None or scope > witness["max_scope"]["scope"]:
                    witness["max_scope"] = {"ids": ids, "scope": scope, "completion_bp": completion}
                for name, (maximum, fade) in thresholds.items():
                    excess = max(0, scope - maximum)
                    grade = max(0, 10000 - 10000 * excess // fade)
                    classification = "full" if grade == 10000 else "miss" if grade == 0 else "partial"
                    result = by_threshold[name]
                    result[classification] += 1
                    result["count"] += 1
                    result["completion_min_bp"] = min(result["completion_min_bp"], completion)
                    result["completion_max_bp"] = max(result["completion_max_bp"], completion)
                    result["scope_min"] = min(result["scope_min"], scope)
                    result["scope_max"] = max(result["scope_max"], scope)
                    if min(completion, grade) >= 5000:
                        result["both_at_least_5000"] += 1
                    if completion == 10000 and grade == 10000:
                        result["both_full"] += 1
                    result["combined_max_bp"] = max(result["combined_max_bp"], min(completion, grade))
                    if grade == 10000:
                        result["max_completion_when_promise_full_bp"] = max(
                            result["max_completion_when_promise_full_bp"], completion
                        )
                    if witness[name][classification] is None:
                        witness[name][classification] = {
                            "ids": ids, "scope": scope, "completion_bp": completion, "promise_grade_bp": grade
                        }
    for name, result in by_threshold.items():
        if result["full"] + result["partial"] + result["miss"] != result["count"]:
            raise RuntimeError("Grade classification accounting failure")
        rows.append({"specialty": specialty, "roster_size": len(owned), "candidate": name, **result})
    witnesses[specialty] = {"roster": [x["id"] for x in owned], "witnesses": witness}

csv_path = HERE / "SIDESTREET-RELATIONSHIP-BRIEF-SCREEN-2026-10-18-v1.csv"
with csv_path.open("w", newline="", encoding="utf-8") as output:
    writer = csv.DictWriter(output, fieldnames=list(rows[0]))
    writer.writeheader()
    writer.writerows(rows)
json_path = HERE / "SIDESTREET-RELATIONSHIP-BRIEF-WITNESSES-2026-10-18-v1.json"
json_path.write_text(json.dumps({"source_hashes": EXPECTED_HASHES, "witnesses": witnesses}, indent=2) + "\n", encoding="utf-8")
print(f"PASS {len(rules)} specialties, {len(rows)} summary rows")
for row in rows:
    print("{specialty:12} {candidate:12} roster={roster_size:2} choices={count:5} "
          "scope_max={scope_max} full={full:5} partial={partial:5} miss={miss:5} "
          "both50={both_at_least_5000:5} both_full={both_full:4} combined_max={combined_max_bp:5}"
          .format(**row))
print(csv_path)
print(json_path)
