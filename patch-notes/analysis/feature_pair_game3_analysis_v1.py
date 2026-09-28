"""Aggregate staged later-card Game-3 Godot scene-control bounds.

Run: python -B analysis/feature_pair_game3_analysis_v1.py
"""
from __future__ import annotations

import gzip
import json
import statistics
from collections import Counter
from pathlib import Path

from feature_pair_game2_analysis_v1 import market_bp

OUT=Path(__file__).resolve().parents[1]/"design-logs"
POLICIES=("cautious","ordinary","optimizer")
ARMS=("none","background_music","pair","staged_pair")
BANDS=(("controlledsound",0),("controlledmixed",24))
TRIALS={"background_music","sub_areas"}


def describe(v):
    x=sorted(v)
    return {"n":len(x),"p10":x[int((len(x)-1)*.1)],"median":statistics.median(x),
            "p90":x[int((len(x)-1)*.9)],"mean":statistics.mean(x)}


def main():
    paths={}
    for policy in POLICIES:
        for arm in ARMS:
            for band,start in BANDS:
                suffix=f"_{start}" if start else ""
                p=OUT/f"feature_pair_game3_trial_v1_{policy}_{arm}_{band}{suffix}.json"
                d=json.loads(p.read_text())
                assert d["failures"]==0 and len(d["rows"])==10
                for r in d["rows"]:
                    assert len(r.get("long_run",[]))==1 and r["long_run"][0]["release"]["released"]
                    paths[(policy,arm,r["case"])]=r
    raw=[]
    for policy in POLICIES:
        for band,start in BANDS:
            for case in range(start,start+10):
                baseline=paths[(policy,"none",case)]
                bg=paths[(policy,"background_music",case)]
                for arm in ARMS:
                    r=paths[(policy,arm,case)]
                    assert r["game_2_forecast_id"]==baseline["game_2_forecast_id"], (policy,case,arm)
                    assert r["game_2_controlled_rolls"]==baseline["game_2_controlled_rolls"]
                    if arm=="staged_pair":
                        assert (all(r["game_2"][k]==bg["game_2"][k] for k in
                                    ("final_review","scope","cores","awareness","month_1_units","cash_cents"))), (policy,case,r["game_2"],bg["game_2"])
                    rel=r["long_run"][0]["release"]
                    comparison_bp=market_bp(baseline["long_run"][0]["release"])
                    observed_bp=market_bp(rel)
                    if comparison_bp is not None and observed_bp is not None:
                        assert observed_bp==comparison_bp, (policy,case,arm,observed_bp,comparison_bp)
                    g2=r["game_2"]
                    selected=[c for a in r["actions"] if a.get("game")==3 for c in a.get("selected",[]) if c in TRIALS]
                    drawn=[c for a in r["actions"] if a.get("game")==3 for c in a.get("draw",[]) if c in TRIALS]
                    staged=r.get("staged_purchase",{})
                    gate=r.get("character_classes_economics_gate",{})
                    cash_before=r["long_run"][0]["before"]["cash_cents"]
                    save=gate.get("save_files_quote",{})
                    raw.append({"policy":policy,"band":band,"arm":arm,"case":case,"seed":r["seed"],
                                "game2_review":g2["final_review"],"game2_review_matches_bg":g2["final_review"]==bg["game_2"]["final_review"],
                                "game3":rel,"cash_before_game3_cents":cash_before,
                                "cash_after_game3_contract_cents":r["long_run"][0]["after"]["cash_cents"],
                                "game3_review_delta_to_bg_tenths":round((rel["final_review"]-bg["long_run"][0]["release"]["final_review"])*10),
                                "game3_review_delta_to_none_tenths":round((rel["final_review"]-baseline["long_run"][0]["release"]["final_review"])*10),
                                "trial_drawn":drawn,"trial_selected":selected,
                                "staged_levels_bought":staged.get("levels",{}).get("bought"),
                                "staged_sub_areas_bought":staged.get("sub_areas",{}).get("bought"),
                                "staged_sub_areas_quote":staged.get("sub_areas",{}).get("quote"),
                                "save_files_quote":save,"character_classes_requires_general_combat_owned":gate.get("owns_general_combat"),
                                "save_files_plus_trial_character_classes_cents":(save.get("price_cents",0) if not save.get("owned",False) else 0)+170000 if gate else None})
    summary={}
    for arm in ARMS:
        group=[x for x in raw if x["arm"]==arm]
        summary[arm]={"n":len(group),"game3_review":describe(x["game3"]["final_review"] for x in group),
                      "game3_scope":describe(x["game3"]["scope"] for x in group),
                      "game3_month1_units":describe(x["game3"]["month_1_units"] for x in group),
                      "game3_review_delta_to_bg_tenths":describe(x["game3_review_delta_to_bg_tenths"] for x in group),
                      "cash_before_game3_cents":describe(x["cash_before_game3_cents"] for x in group),
                      "cash_after_game3_contract_cents":describe(x["cash_after_game3_contract_cents"] for x in group),
                      "trial_drawn_paths":sum(bool(x["trial_drawn"]) for x in group),
                      "trial_played_paths":sum(bool(x["trial_selected"]) for x in group),
                      "stage_levels_bought":sum(x["staged_levels_bought"] is True for x in group),
                      "stage_sub_areas_bought":sum(x["staged_sub_areas_bought"] is True for x in group),
                      "stage_quote_discount_counts":dict(Counter(x["staged_sub_areas_quote"]["discount_percent"] for x in group if x["staged_sub_areas_bought"])),
                      "save_files_plus_character_classes_price_gate":sum(x["cash_before_game3_cents"]>=x["save_files_plus_trial_character_classes_cents"] for x in group if x["save_files_plus_trial_character_classes_cents"] is not None)}
    result={"source_revision":"ba616515ed1b039fd0da7cf03f73288fd7ccd8e4",
            "matched_cases":60,"total_continuations":len(raw),"summary":summary,
            "limitations":["Card injection is analysis-only; no production ledger/Store changed",
                           "Staged Sub-Areas path may also buy Levels reserve, so the two effects are a compound legal path",
                           "Current Store trial purchases use zero cycles; later card play cost remains TBD/$0 in live path",
                           "Game 3 sales are only projected Month 1 at release; SideStreet paid through current live actions",
                           "Character Classes gate is quote-only because multi-parent Store and three-Core schema gaps remain"]}
    (OUT/"feature_pair_game3_trial_v1_summary.json").write_text(json.dumps(result,indent=2))
    with gzip.open(OUT/"feature_pair_game3_trial_v1_paired.json.gz","wt",encoding="utf-8") as f:
        json.dump(raw,f,separators=(",",":"))
    for arm,s in summary.items():
        print(arm,s["n"],s["stage_sub_areas_bought"],s["game3_review_delta_to_bg_tenths"]["mean"])


if __name__=="__main__":
    main()
