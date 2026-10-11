"""Prepare an explicit next experiment from a newly generated Studio artifact.

No game process is started; no saved player data or existing file is changed.
The resulting experiment still passes the simulator's source/runtime fences.
"""
import argparse
import hashlib
import json
from pathlib import Path


def read(path):
    return json.loads(path.read_text(encoding="utf-8-sig"))


def safe_id(value):
    if not value or len(value) > 100 or any(c not in "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_-" for c in value):
        raise ValueError("Case IDs must use 1-100 letters, numbers, underscores or hyphens")
    return value


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--bundle", type=Path, required=True)
    parser.add_argument("--case", required=True)
    parser.add_argument("--case-id", required=True)
    parser.add_argument("--target-release-count", type=int, required=True)
    parser.add_argument("--max-commands", type=int, required=True)
    parser.add_argument("--output", type=Path, required=True)
    args = parser.parse_args()
    bundle = args.bundle.resolve()
    case = bundle / "cases" / safe_id(args.case)
    result = read(case / "result.json")
    if not result.get("outcome", {}).get("in_studio") or result.get("artifacts", {}).get("studio_checkpoint") != "studio_checkpoint.json":
        raise ValueError("Selected case has no valid ending Studio checkpoint")
    if args.target_release_count <= result["final_release_count"] or args.target_release_count > 1000000000 or not 1 <= args.max_commands <= 1000000000:
        raise ValueError("Choose a larger absolute release target and explicit positive command bound")
    config = read(bundle / "inputs/experiment.json")
    selected = next(item for item in config["cases"] if item["case_id"] == args.case)
    resource = config["policy"]["script"]
    if not resource.startswith("res://") or ":" in resource[6:] or "\\" in resource or any(part in {"", ".", ".."} for part in resource[6:].split("/")):
        raise ValueError("Unsafe original policy path")
    policy_file = bundle / "project" / resource[6:]
    if hashlib.sha256(policy_file.read_bytes()).hexdigest() != config["policy"]["source_identity"]:
        raise ValueError("Original policy source changed")
    config["policy"]["script"] = str(policy_file)
    selected["case_id"] = safe_id(args.case_id)
    selected["initial"] = {"checkpoint": read(case / "studio_checkpoint.json")}
    selected["max_commands"] = args.max_commands
    selected["target_release_count"] = args.target_release_count
    config["cases"] = [selected]
    args.output.parent.mkdir(parents=True, exist_ok=True)
    with args.output.open("x", encoding="utf-8") as stream:
        json.dump(config, stream, ensure_ascii=False, allow_nan=False, indent=2)
        stream.write("\n")
    print(str(args.output.resolve()))


if __name__ == "__main__":
    main()
