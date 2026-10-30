"""Build fresh legal v4 Banking prefixes and the fixed larger-offer pairs."""
import copy
import json
from pathlib import Path
import sys

root = Path(__file__).resolve().parent
cohorts = ("control-90210", "graduate-90210")
admissions = {
    "control-90210": ["scripted_ai", "animated_sprites", "recorded_sounds", "save_files", "difficulty_levels"],
    "graduate-90210": ["scripted_ai", "animated_sprites", "recorded_sounds", "save_files", "multi_directional_scrolling"],
}


def read(path):
    return json.loads(path.read_text(encoding="utf-8"))


def write(name, data):
    path = root / name
    if path.exists():
        raise SystemExit(f"Refusing to replace {path}")
    path.write_text(json.dumps(data, indent=2) + "\n", encoding="utf-8")
    print(path)


def checkpoint(stage, cohort):
    folder = root / f"larger-offer-{stage}-run-v1" / "cases" / cohort
    result = read(folder / "result.json")
    assert result["status"] == ("completed" if stage == "first" else "command_bound"), (stage, cohort, result["status"])
    assert result["final_release_count"] == 1
    assert result["final_run_cycle"] == (13 if stage == "first" else 16)
    return read(folder / "studio_checkpoint.json")


def case(cohort, cp, max_commands, config):
    return {"schema_version": "1", "case_id": cohort, "initial": {"checkpoint": cp},
            "max_commands": max_commands, "target_release_count": 2,
            "telemetry": True, "policy": {"config": config}}


stage = sys.argv[1]
if stage == "first":
    data = read(root / "eligible-sales-first-release-v1.json")
    data["cases"] = [copy.deepcopy(c) for c in data["cases"] if c["case_id"] in cohorts]
    assert len(data["cases"]) == 2
    data["policy"]["id"] = "bank-larger-first-v1"
elif stage == "studio":
    data = {"schema_version": "1", "policy": {"script": "eligible_sales_studio_policy_v1.gd", "id": "bank-larger-studio", "version": "1"},
            "cases": [case(cohort, checkpoint("first", cohort), 5, {}) for cohort in cohorts]}
elif stage == "admit":
    data = {"schema_version": "1", "policy": {"script": "liquidity_admit_policy_v1.gd", "id": "bank-larger-admit", "version": "1"},
            "cases": [case(cohort, checkpoint("studio", cohort), 5, {"feature_ids": admissions[cohort]}) for cohort in cohorts]}
elif stage == "pairs":
    cases = []
    for cohort in cohorts:
        cp = checkpoint("admit", cohort)
        for amount, arm in ((0, "no-loan"), (100000, "borrow-1000-12"), (250000, "borrow-2500-12")):
            c = case(cohort, cp, 50, {"genre": "action", "theme": "fantasy",
                "name_prefix": "Control" if cohort.startswith("control") else "Graduate",
                "selection": "visible_order", "hands": {"design": 4, "alpha": 4, "beta": 4},
                "borrow_amount": amount})
            c["case_id"] = f"{cohort}-{arm}"
            c["study"] = {"pair_id": f"{cohort}-larger-v1", "arm": arm}
            cases.append(c)
    data = {"schema_version": "1", "policy": {"script": "larger_offer_pair_policy_v1.gd", "id": "bank-larger-pairs", "version": "1"},
            "cases": cases}
else:
    raise SystemExit("usage: build_larger_offer_v1.py first|studio|admit|pairs")
write(f"larger-offer-{stage}-v1.json", data)
