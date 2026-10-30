"""Build declared v3 configs from each preceding retained Studio checkpoint."""

import argparse
import json
from pathlib import Path

HERE = Path(__file__).resolve().parent
IDS = {
    "control-4417": ["scripted_ai", "animated_sprites", "recorded_sounds"],
    "graduate-4417": ["scripted_ai", "animated_sprites", "recorded_sounds", "difficulty_levels"],
    "control-90210": ["scripted_ai", "animated_sprites", "recorded_sounds", "save_files", "difficulty_levels"],
    "graduate-90210": ["scripted_ai", "animated_sprites", "recorded_sounds", "save_files", "16_bit_music"],
}


def read_json(path: Path) -> dict:
    return json.loads(path.read_text(encoding="utf-8"))


def checkpoint(bundle: Path, case_id: str) -> dict:
    case_dir = bundle / "cases" / case_id
    result = read_json(case_dir / "result.json")
    expected = "completed" if bundle.name == "liquidity-first-run-v3" else "command_bound"
    assert result["status"] == expected, (case_id, result["status"], expected)
    assert result["final_release_count"] == 1
    assert result["final_run_cycle"] in (13, 16)
    return read_json(case_dir / "studio_checkpoint.json")


def make_case(case_id: str, cp: dict, commands: int, policy_config: dict) -> dict:
    return {
        "schema_version": "1", "case_id": case_id,
        "initial": {"checkpoint": cp}, "max_commands": commands,
        "target_release_count": 2, "telemetry": True,
        "policy": {"config": policy_config},
    }


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("stage", choices=["first", "studio", "admit", "pairs"])
    args = parser.parse_args()
    if args.stage == "first":
        config = read_json(HERE / "eligible-sales-first-release-v1.json")
        config["policy"]["id"] = "bank-liquidity-first-v3"
    else:
        previous = {
            "studio": HERE / "liquidity-first-run-v3",
            "admit": HERE / "liquidity-studio-run-v3",
            "pairs": HERE / "liquidity-admit-run-v3",
        }[args.stage]
        cases = []
        for cohort in IDS:
            if args.stage == "pairs":
                result = read_json(previous / "cases" / cohort / "result.json")
                if result["status"] != "command_bound":
                    print(f"Excluded {cohort}: declared admission status {result['status']}")
                    continue
            cp = checkpoint(previous, cohort)
            if args.stage == "studio":
                cases.append(make_case(cohort, cp, 5, {}))
            elif args.stage == "admit":
                cases.append(make_case(cohort, cp, len(IDS[cohort]), {"feature_ids": IDS[cohort]}))
            else:
                for amount, arm in [(0, "no-loan"), (50000, "borrow-500-12"), (100000, "borrow-1000-12")]:
                    c = make_case(f"{cohort}-{arm}", cp, 50, {
                        "genre": "action", "theme": "fantasy",
                        "name_prefix": "Graduate" if cohort.startswith("graduate") else "Control",
                        "selection": "visible_order", "hands": {"design": 4, "alpha": 4, "beta": 4},
                        "borrow_amount": amount,
                    })
                    c["study"] = {"pair_id": cohort + "-liquidity", "arm": arm}
                    cases.append(c)
        policy = {
            "studio": {"script": "eligible_sales_studio_policy_v1.gd", "id": "bank-liquidity-studio", "version": "1"},
            "admit": {"script": "liquidity_admit_policy_v1.gd", "id": "bank-liquidity-admit", "version": "1"},
            "pairs": {"script": "liquidity_pair_policy_v1.gd", "id": "bank-liquidity-pairs", "version": "1"},
        }[args.stage]
        config = {"schema_version": "1", "policy": policy, "cases": cases}
    path = HERE / f"liquidity-{args.stage}-v3.json"
    assert not path.exists(), path
    path.write_text(json.dumps(config, indent=2) + "\n", encoding="utf-8")
    print(path)


if __name__ == "__main__":
    main()
