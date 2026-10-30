"""Materialize the predeclared Banking reserve-route configurations."""
import copy
import json
import pathlib
import sys

ROOT = pathlib.Path(__file__).resolve().parent
COHORTS = ("control-90210", "graduate-90210")


def write(name, data):
    path = ROOT / name
    if path.exists():
        raise SystemExit(f"Refusing to replace {path}")
    path.write_text(json.dumps(data, indent=2) + "\n", encoding="utf-8")
    print(path)


if __name__ == "__main__":
    stage = sys.argv[1]
    if stage == "admit":
        old = json.loads((ROOT / "liquidity-admit-v3.json").read_text(encoding="utf-8"))
        cases = [copy.deepcopy(c) for c in old["cases"] if c["case_id"] in COHORTS]
        assert len(cases) == 2
        graduate = next(c for c in cases if c["case_id"] == "graduate-90210")
        assert graduate["policy"]["config"]["feature_ids"][-1] == "16_bit_music"
        graduate["policy"]["config"]["feature_ids"][-1] = "multi_directional_scrolling"
        old["cases"] = cases
        old["policy"] = {"script": "liquidity_admit_policy_v1.gd", "id": "bank-reserve-admit", "version": "1"}
        write("reserve-admit-v1.json", old)
    elif stage == "pairs":
        bundle = ROOT / "reserve-admit-run-v1" / "cases"
        cases = []
        for cohort in COHORTS:
            result = json.loads((bundle / cohort / "result.json").read_text(encoding="utf-8"))
            assert result["status"] == "command_bound", (cohort, result["status"])
            checkpoint = json.loads((bundle / cohort / "studio_checkpoint.json").read_text(encoding="utf-8"))
            for amount, arm in ((0, "no-loan"), (50000, "borrow-500-12"), (100000, "borrow-1000-12")):
                cases.append({
                    "schema_version": "1",
                    "case_id": f"{cohort}-{arm}",
                    "initial": {"checkpoint": checkpoint},
                    "max_commands": 35,
                    "target_release_count": 2,
                    "telemetry": True,
                    "policy": {"config": {
                        "genre": "action", "theme": "fantasy",
                        "name_prefix": "Control" if cohort.startswith("control") else "Graduate",
                        "selection": "visible_order",
                        "hands": {"design": 1, "alpha": 1, "beta": 1},
                        "borrow_amount": amount,
                    }},
                    "study": {"pair_id": f"{cohort}-reserve-v1", "arm": arm},
                })
        write("reserve-pairs-v1.json", {
            "schema_version": "1",
            "policy": {"script": "reserve_pair_policy_v1.gd", "id": "bank-reserve-pairs", "version": "1"},
            "cases": cases,
        })
    else:
        raise SystemExit("usage: build_reserve_route_v1.py admit|pairs")
