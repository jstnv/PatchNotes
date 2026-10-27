"""Combine three independently generated Studio-only continuation configs."""
from __future__ import annotations

import argparse
import json
from pathlib import Path


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--output", type=Path, required=True)
    parser.add_argument("inputs", type=Path, nargs=3)
    args = parser.parse_args()
    records = [json.loads(path.read_text(encoding="utf-8")) for path in args.inputs]
    policy = records[0]["policy"]
    if any(item.get("schema_version") != "1" or item.get("policy") != policy or len(item.get("cases", [])) != 1 for item in records):
        raise ValueError("Continuation inputs must share one pinned policy and contain one case each")
    cases = [item["cases"][0] for item in records]
    if len({item["case_id"] for item in cases}) != 3:
        raise ValueError("Continuation case IDs must be distinct")
    if any(item.get("target_release_count") != 2 or item.get("max_commands") != 45 or "checkpoint" not in item.get("initial", {}) for item in cases):
        raise ValueError("Each case must retain the declared Studio checkpoint and horizon")
    args.output.parent.mkdir(parents=True, exist_ok=True)
    if args.output.exists():
        raise FileExistsError(args.output)
    args.output.write_text(json.dumps({"schema_version": "1", "policy": policy, "cases": cases}, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    print(args.output.resolve())


if __name__ == "__main__":
    main()
