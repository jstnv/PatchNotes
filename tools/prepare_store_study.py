"""Prepare a matched research-now/defer study from a completed Studio case.

This helper neither runs Godot nor edits a checkpoint. Every arm uses the exact
same starting state/RNG and explicit finite development configuration. Current
quotes and the simulator remain the authority for legality and affordability.
"""
from __future__ import annotations

import argparse
import copy
import hashlib
import json
from pathlib import Path
import re

from simulate import check_snapshot, read_json, safe_relative, sha

ROOT = Path(__file__).resolve().parents[1]
POLICY_RESOURCE = "res://scripts/debug/store_study_policy.gd"
POLICY_ID = "paired-store-study"
MAX_BOUND = 1_000_000_000


def safe_id(value: str) -> str:
    if not isinstance(value, str) or not re.fullmatch(r"[A-Za-z0-9_-]{1,100}", value):
        raise ValueError("Case IDs must use 1-100 letters, numbers, underscores or hyphens")
    return value


def canonical_sha(value: object) -> str:
    return hashlib.sha256(json.dumps(value, sort_keys=True, separators=(",", ":"), ensure_ascii=False, allow_nan=False).encode()).hexdigest()


def valid_development(config: object) -> bool:
    if not isinstance(config, dict):
        return False
    if any(not isinstance(config.get(field), str) or not config[field].strip() for field in ("genre", "theme", "name_prefix")):
        return False
    if config.get("selection") not in ("visible_order", "features_first"):
        return False
    hands = config.get("hands")
    return isinstance(hands, dict) and set(hands) == {"design", "alpha", "beta"} and all(type(value) is int and 1 <= value <= 1_000_000 for value in hands.values())


def prepare(bundle: Path, case_id: str, feature: str, target_release_count: int, max_commands: int, development_override: dict | None = None) -> dict:
    """Return an explicit study, rejecting unsafe or incomplete prefix evidence."""
    bundle = bundle.resolve()
    case_id = safe_id(case_id)
    safe_id(feature)
    if type(target_release_count) is not int or type(max_commands) is not int or not 1 <= target_release_count <= MAX_BOUND or not 1 <= max_commands <= MAX_BOUND:
        raise ValueError("Explicit positive release target and command bound required")
    manifest = read_json(bundle / "snapshot-manifest.json")
    if not isinstance(manifest, dict) or not manifest:
        raise ValueError("Missing frozen source manifest")
    for path in manifest:
        safe_relative(path)
    check_snapshot(bundle / "project", manifest)
    case = bundle / "cases" / case_id
    result = read_json(case / "result.json")
    if result.get("case_id") != case_id or result.get("ok") is not True or result.get("status") != "completed":
        raise ValueError("Prefix must be a successfully completed case")
    outcome = result.get("outcome", {})
    if outcome.get("in_studio") is not True or result.get("artifacts", {}).get("studio_checkpoint") != "studio_checkpoint.json":
        raise ValueError("Prefix must end at an existing Studio checkpoint")
    if type(result.get("final_release_count")) is not int or result["final_release_count"] < 1 or target_release_count <= result["final_release_count"]:
        raise ValueError("Choose a target after the prefix's existing releases")
    if not isinstance(outcome.get("research_queue"), list) or outcome["research_queue"]:
        raise ValueError("Matched single-Feature studies require an empty initial research queue")
    if not isinstance(outcome.get("owned_features"), list) or feature in outcome["owned_features"]:
        raise ValueError("The explicit target must be unowned")
    catalog = read_json(bundle / "project/data/feature_store_ledger.json") + read_json(bundle / "project/data/card_ledger.json")
    if not any(row.get("id") == feature and row.get("type") == "feature" and row.get("phase") in ("design", "alpha") for row in catalog):
        raise ValueError("Explicit target is absent from the frozen Store/Primitive Feature catalog")
    checkpoint_path = case / "studio_checkpoint.json"
    checkpoint = read_json(checkpoint_path)
    if checkpoint.get("kind") != "campaign_studio" or checkpoint.get("schema_version") != "1" or not checkpoint.get("integrity"):
        raise ValueError("Missing simulation Studio checkpoint envelope")
    for key in ("source_identity", "engine_version", "rng_algorithm"):
        if not checkpoint.get(key) or checkpoint[key] != result.get(key):
            raise ValueError("Checkpoint and prefix identities differ: " + key)
    experiment_path = bundle / "inputs/experiment.json"
    experiment = read_json(experiment_path)
    report = read_json(bundle / "run-report.json")
    if report.get("input_hashes", {}).get("experiment.json") != sha(experiment_path):
        raise ValueError("Prefix experiment input hash changed")
    selected = [item for item in experiment.get("cases", []) if item.get("case_id") == case_id]
    if len(selected) != 1:
        raise ValueError("Prefix case must occur exactly once in its experiment")
    declaration = experiment.get("policy", {})
    resource = declaration.get("script", "")
    if not isinstance(resource, str) or not resource.startswith("res://"):
        raise ValueError("Prefix policy must identify its frozen source")
    if sha(bundle / "project" / safe_relative(resource[6:])) != declaration.get("source_identity"):
        raise ValueError("Prefix policy source identity changed")
    if development_override is None:
        if declaration.get("id") != "finite-development-fixture" or declaration.get("version") != "1":
            raise ValueError("Use --development-config for a prefix that does not declare the finite fixture policy")
        development = selected[0].get("policy", {}).get("config")
    else:
        development = development_override
    if not valid_development(development):
        raise ValueError("Development config must explicitly supply genre/theme/name_prefix/selection and all three positive hand counts")
    # This policy is test-only and depends on the existing project fixture.
    # Pin its bytes explicitly; simulate.py verifies each case's declared hash.
    policy_sha = sha(ROOT / "patch-notes" / POLICY_RESOURCE[6:])
    base = {
        "kind": "store-research-vs-defer-v1", "feature": feature,
        "prefix_case_id": case_id, "prefix_final_state": result["final_state"],
        "prefix_source_identity": result["source_identity"],
        "checkpoint_sha256": sha(checkpoint_path),
        "checkpoint_content_sha256": canonical_sha(checkpoint),
        "prefix_result_sha256": sha(case / "result.json"),
        "prefix_experiment_sha256": sha(experiment_path),
        "development_config_sha256": canonical_sha(development),
        "development_config_overridden": development_override is not None,
        "target_release_count": target_release_count, "max_commands": max_commands,
        "policy_source_identity": policy_sha,
    }
    pair_id = "store-" + canonical_sha(base)[:24]
    cases = []
    for arm in ("research_now", "defer"):
        cases.append({
            "schema_version": "1", "case_id": pair_id + "-" + arm,
            "initial": {"checkpoint": copy.deepcopy(checkpoint)},
            "target_release_count": target_release_count, "max_commands": max_commands,
            "telemetry": True, "study": {**base, "pair_id": pair_id, "arm": arm},
            "policy": {"source_identity": policy_sha, "config": {"arm": arm, "feature": feature, "development": copy.deepcopy(development)}},
        })
    return {"schema_version": "1", "policy": {"script": POLICY_RESOURCE, "id": POLICY_ID, "version": "1"}, "cases": cases}


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--bundle", type=Path, required=True)
    parser.add_argument("--case", required=True)
    parser.add_argument("--feature", required=True)
    parser.add_argument("--target-release-count", type=int, required=True)
    parser.add_argument("--max-commands", type=int, required=True)
    parser.add_argument("--development-config", type=Path, help="Optional complete explicit replacement finite development config JSON")
    parser.add_argument("--output", type=Path, required=True, help="New experiment JSON file; never overwritten")
    args = parser.parse_args(argv)
    if args.output.exists():
        raise FileExistsError("Output must be new: " + str(args.output))
    if args.output.resolve().is_relative_to((ROOT / "patch-notes").resolve()) or args.output.resolve().is_relative_to(args.bundle.resolve()):
        raise ValueError("Write the study outside runtime source and its original evidence bundle")
    override = None if args.development_config is None else read_json(args.development_config)
    config = prepare(args.bundle, args.case, args.feature, args.target_release_count, args.max_commands, override)
    args.output.parent.mkdir(parents=True, exist_ok=True)
    with args.output.open("x", encoding="utf-8") as stream:
        json.dump(config, stream, indent=2, ensure_ascii=False, allow_nan=False)
        stream.write("\n")
    print(str(args.output.resolve()))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
