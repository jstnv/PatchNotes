"""Counterfactual cash overlay on verified sim-v4 native traces; no game files change."""
from pathlib import Path
import csv
import gzip
import hashlib
import json
import subprocess

OUT = Path(__file__).resolve().parent
V4 = OUT.parent / "sim-v4"
REPO = OUT.parents[4]
PROJECT = REPO / "patch-notes"
FEES = (0, 5000, 9000)


def read_trace(result):
    specialty, policy, arm, timing, seed = result["job"]
    path = V4 / f"route_early_{specialty}_{policy}_{arm}_{timing}_{seed}_0.json.gz"
    raw = gzip.decompress(path.read_bytes())
    assert hashlib.sha256(raw).hexdigest() == result["trace_sha256"], path
    trace = json.loads(raw)
    assert result["exit"] == 0 and trace["valid"] and len(trace["releases"]) == 5
    assert trace["final_finance_report"]["unpaid_rent_cents"] == 0
    return trace


def main():
    plan = json.loads((V4 / "predeclaration.json").read_text())
    report = json.loads((V4 / "run-report.json").read_text())
    assert plan["head"] == report["head_before"] == report["head_after"]
    assert subprocess.check_output(["git", "rev-parse", "HEAD"], cwd=REPO).decode().strip() == plan["head"]
    assert hashlib.sha256((V4 / "driver.gd").read_bytes()).hexdigest() == plan["driver_sha256"]
    assert report["source_changes"] == []
    for name, expected in plan["source_before"].items():
        assert hashlib.sha256((PROJECT / name).read_bytes()).hexdigest() == expected, name
    assert len(report["results"]) == 8
    traces = {tuple(r["job"]): read_trace(r) for r in report["results"]}
    with (V4 / "summary.csv").open(newline="") as stream:
        paired = list(csv.DictReader(stream))
    assert len(paired) == 4

    rows = []
    for pair in paired:
        seed, policy = int(pair["seed"]), pair["policy"]
        trial = traces[("action", policy, "sub_areas", "stronger_settled", seed)]
        control = traces[("action", policy, "none", "immediate", seed)]
        plays = [(i, a) for i, a in enumerate(trial["actions"])
                 if "sub_areas" in a.get("selected", [])]
        assert [a["game"] for _, a in plays] == [4, 5]
        assert len([a for a in trial["purchases"] if a.get("id") == "sub_areas" and a.get("success")]) == 1
        assert all(a["before"]["cash_cents"] >= a["cost_cents"] for _, a in plays)
        assert all(a["before"]["cycle"] < a["after"]["cycle"] for _, a in plays)
        first_index, first = plays[0]
        after_first_cash = [state["cash_cents"] for action in trial["actions"][first_index:]
                            for state in (action.get("before", {}), action.get("after", {}))
                            if "cash_cents" in state]
        after_first_cash += [state["cash_cents"] for state in trial["live_cycles"]
                             if state["cycle"] >= first["after"]["cycle"]]
        after_first_cash += [state["cash_cents"] for state in trial["studio_visits"]
                             if state["cycle"] >= first["after"]["cycle"]]
        after_first_cash += [observation["report"]["cash_cents"]
                             for observation in trial["finance_observations"]
                             if observation["cycle"] >= first["after"]["cycle"]]
        after_first_cash.append(trial["final"]["cash_cents"])
        min_after_first = min(after_first_cash)
        assert int(pair["matched_cycle"]) > first["after"]["cycle"]
        assert int(pair["matched_cycle"]) < plays[1][1]["before"]["cycle"]
        assert int(pair["trial_cash_game5_launch_cents"]) == trial["final"]["cash_cents"]
        assert int(pair["control_cash_game5_launch_cents"]) == control["final"]["cash_cents"]
        for fee in FEES:
            # A deliberately conservative lower bound treats both fees as paid
            # immediately after the first candidate play.
            cash_floor = min_after_first - 2 * fee
            assert cash_floor > 0
            rows.append({
                "seed": seed, "policy": policy, "fee_per_play_cents": fee,
                "plays": len(plays), "play_games": "4/5",
                "first_play_pre_cash_cents": plays[0][1]["before"]["cash_cents"],
                "second_play_pre_cash_cents": plays[1][1]["before"]["cash_cents"],
                "min_recorded_cash_after_first_cents": min_after_first,
                "conservative_cash_floor_cents": cash_floor,
                "matched_cycle": int(pair["matched_cycle"]),
                "control_cash_matched_cents": int(pair["control_cash_matched_cents"]),
                "trial_cash_matched_overlay_cents": int(pair["trial_cash_matched_cents"]) - fee,
                "paired_cash_matched_delta_cents": int(pair["trial_cash_matched_cents"]) - fee - int(pair["control_cash_matched_cents"]),
                "control_cash_game5_launch_cents": int(pair["control_cash_game5_launch_cents"]),
                "trial_cash_game5_launch_overlay_cents": int(pair["trial_cash_game5_launch_cents"]) - 2 * fee,
                "paired_cash_game5_launch_delta_cents": int(pair["trial_cash_game5_launch_cents"]) - 2 * fee - int(pair["control_cash_game5_launch_cents"]),
                "control_credit": int(pair["control_credit"]), "native_trial_credit": int(pair["trial_credit"]),
            })
    path = OUT / "summary.csv"
    with path.open("w", newline="", encoding="utf-8") as stream:
        writer = csv.DictWriter(stream, fieldnames=list(rows[0]))
        writer.writeheader()
        writer.writerows(rows)
    result = {"source_branch": plan["branch"], "source_head": plan["head"],
              "source_file_count": len(plan["source_before"]), "v4_driver_sha256": plan["driver_sha256"],
              "overlay_script_sha256": hashlib.sha256(Path(__file__).read_bytes()).hexdigest(),
              "v4_trace_sha256": {"|".join(map(str, r["job"])): r["trace_sha256"] for r in report["results"]},
              "method": "Static cents overlay on actual selected-card commits. One fee before common cycle 73; two before Game 5 launch. Other route events held fixed; no native fee implementation.",
              "fees_cents": list(FEES), "rows": len(rows),
              "summary_sha256": hashlib.sha256(path.read_bytes()).hexdigest()}
    (OUT / "run-report.json").write_text(json.dumps(result, indent=2), encoding="utf-8")
    print("PASS: stable source and 8 trace hashes; 4 pairs x 3 fee arms; two actual plays each; positive conservative cash floors")


if __name__ == "__main__":
    main()
