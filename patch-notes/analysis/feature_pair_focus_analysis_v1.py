"""Paired Game-2 Sound versus mixed priorities on identical Game-1 paths."""
from __future__ import annotations

import gzip
import json
from pathlib import Path

from feature_pair_game2_analysis_v1 import card_events, describe, game2_production, market_bp

OUT = Path(__file__).resolve().parents[1] / "design-logs"
FOCI = ("sound", "mixed")
ARMS = ("control_background_music", "background_music")


def main() -> None:
    paths = {}
    for focus in FOCI:
        for arm in ARMS:
            path = OUT / f"feature_pair_focus_trial_v1_ordinary_{arm}_{focus}20.json"
            data = json.loads(path.read_text())
            assert data["failures"] == 0 and len(data["rows"]) == 20
            for row in data["rows"]:
                assert row["game2_focus"] == focus and row["production_focus"] == "sound"
                paths[(focus, arm, row["case"])] = row
    raw = []
    for case in range(20):
        base = paths[("sound", ARMS[0], case)]
        for focus in FOCI:
            for arm in ARMS:
                row = paths[(focus, arm, case)]
                assert row["starter_roster"] == base["starter_roster"] and row["seed"] == base["seed"]
                assert row["game_1"]["final_review"] == base["game_1"]["final_review"]
                assert row["reserve_purchase"]["id"] == base["reserve_purchase"]["id"]
                assert row["reserve_purchase"]["success"] == base["reserve_purchase"]["success"]
                if market_bp(row["game_2"]) is not None and market_bp(base["game_2"]) is not None:
                    assert market_bp(row["game_2"]) == market_bp(base["game_2"])
                ev = card_events(row)
                prod = game2_production(row)
                raw.append({"case": case, "seed": row["seed"], "focus": focus, "arm": arm,
                            "beta_mode": row["beta_mode"], "trial_bought": sum(x["bought"] for x in row["trial_purchases"]),
                            "trial_drawn": bool(ev["draws"]), "trial_played": bool(ev["selected"]),
                            "pass_redraw_count": ev["pass_redraw_count"],
                            "feature_redraw_count": ev["feature_redraw_count"],
                            "printed_core": prod["printed_core"], "resolved_core": row["game_2"]["cores"],
                            "scope": row["game_2"]["scope"], "sound_specialization_hands": prod["sound_specialization_hands"],
                            "fixed_bugs": row["game_2"]["fixed_bugs"],
                            "remaining_bugs": row["game_2"]["known_bugs"] + row["game_2"]["hidden_bugs"],
                            "review": row["game_2"]["final_review"], "awareness": row["game_2"]["awareness"],
                            "month1_units": row["game_2"]["month_1_units"],
                            "cash_after_contract_cents": row["sidestreet_2"]["after_dismiss"]["cash_cents"]})
    indexed = {(x["focus"], x["arm"], x["case"]): x for x in raw}
    summary = {}
    for focus in FOCI:
        for arm in ARMS:
            group = [indexed[(focus, arm, case)] for case in range(20)]
            summary[f"{focus}|{arm}"] = {"n": 20,
                "trial_bought": sum(x["trial_bought"] for x in group),
                "trial_drawn": sum(x["trial_drawn"] for x in group),
                "trial_played": sum(x["trial_played"] for x in group),
                "sound_specialization_paths": sum(x["sound_specialization_hands"] > 0 for x in group),
                "printed_sound": describe(x["printed_core"][1] for x in group),
                "resolved_sound": describe(x["resolved_core"][1] for x in group),
                "scope": describe(x["scope"] for x in group),
                "pass_redraws": sum(x["pass_redraw_count"] for x in group),
                "feature_redraws": sum(x["feature_redraw_count"] for x in group),
                "remaining_bugs": describe(x["remaining_bugs"] for x in group),
                "fixed_bugs": describe(x["fixed_bugs"] for x in group),
                "review": describe(x["review"] for x in group),
                "awareness": describe(x["awareness"] for x in group),
                "month1_units": describe(x["month1_units"] for x in group),
                "cash_after_contract_cents": describe(x["cash_after_contract_cents"] for x in group),
                "review_delta_to_same_focus_control_tenths": describe(round((x["review"] - indexed[(focus, ARMS[0], x["case"])]["review"]) * 10) for x in group),
                "review_delta_to_sound_same_arm_tenths": describe(round((x["review"] - indexed[("sound", arm, x["case"])]["review"]) * 10) for x in group)}
    result = {"source_revision": "ba616515ed1b039fd0da7cf03f73288fd7ccd8e4",
              "paired_cases": 20, "continuations": 80, "summary": summary,
              "limitations": ["Analysis-only Background Music card injection; no gameplay definition added",
                              "Production priority is the sole requested Game-2 focus change; live weighted draws can diverge thereafter",
                              "All Game-1 paths, reserve purchases, market rolls and Beta route labels are matched",
                              "Automated policies are not human playtest evidence"]}
    (OUT / "feature_pair_focus_trial_v1_summary.json").write_text(json.dumps(result, indent=2))
    with gzip.open(OUT / "feature_pair_focus_trial_v1_raw.json.gz", "wt", encoding="utf-8") as stream:
        json.dump(raw, stream, separators=(",", ":"))
    for key, stats in summary.items():
        print(key, stats["n"], stats["sound_specialization_paths"], stats["review"]["mean"])


if __name__ == "__main__":
    main()
