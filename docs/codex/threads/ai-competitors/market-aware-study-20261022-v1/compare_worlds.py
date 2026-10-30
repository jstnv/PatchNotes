"""Read-only paired report summary. It makes no design or balance decision."""

from __future__ import annotations

import argparse
import json
from pathlib import Path


def read(path: Path) -> dict:
    value = json.loads(path.read_text(encoding="utf-8-sig"))
    if not isinstance(value, dict):
        raise ValueError(f"Expected JSON object: {path}")
    return value


def trace(report: dict) -> list[dict]:
    return [row for row in report.get("rival_choices", [])
            if row.get("request") == "play" and len(row.get("selected_tokens", [])) == 4]


def offered(row: dict) -> list[int]:
    return sorted(int(card["token"]) for card in row.get("candidates", []))


def hand_context(row: dict) -> dict:
    return {key: row.get(key) for key in
            ("studio_id", "project_id", "cycle", "phase", "hand_revision")}


def first_hand_difference(base: dict, candidate: dict) -> dict:
    left, right = trace(base), trace(candidate)
    for index, (old, new) in enumerate(zip(left, right)):
        aligned = hand_context(old) == hand_context(new) and offered(old) == offered(new)
        selected_equal = old.get("selected_tokens") == new.get("selected_tokens")
        if not aligned or not selected_equal:
            return {"index": index, "aligned_legal_hand": aligned,
                    "same_selected_tokens": selected_equal,
                    "baseline": {"context": hand_context(old), "offered_tokens": offered(old),
                                 "selected_tokens": old.get("selected_tokens"),
                                 "frozen_standards": old.get("frozen_standards"),
                                 "observed_standards": old.get("observed_standards")},
                    "candidate": {"context": hand_context(new), "offered_tokens": offered(new),
                                  "selected_tokens": new.get("selected_tokens"),
                                  "frozen_standards": new.get("frozen_standards"),
                                  "observed_standards": new.get("observed_standards")}}
    if len(left) != len(right):
        return {"index": min(len(left), len(right)), "aligned_legal_hand": False,
                "reason": "different number of rival play calls",
                "baseline_play_calls": len(left), "candidate_play_calls": len(right)}
    return {"reason": "all recorded four-card rival selections agree",
            "baseline_play_calls": len(left), "candidate_play_calls": len(right)}


def release_summary(report: dict) -> dict:
    progress = report.get("rival_progress", [])
    latest_by_project = {row["project_id"]: row for row in progress
                         if row.get("project_id") and row.get("cores")}
    by_studio: dict[str, list[dict]] = {}
    for event in report.get("rival_releases", []):
        project = latest_by_project.get(str(event.get("release_id")), {})
        cores = project.get("cores", [])
        standards = project.get("standards", [])
        deficit = [max(0, int(target) - int(score))
                   for target, score in zip(standards, cores)]
        by_studio.setdefault(str(event.get("studio_id")), []).append({
            "release_id": event.get("release_id"),
            "release_cycle": event.get("release_cycle", event.get("world_cycle")),
            "review_tenths": event.get("review_tenths"),
            "cash_cents": event.get("cash_cents"), "fans": event.get("fans"),
            "last_recorded_cores": cores, "frozen_standards": standards,
            "last_recorded_core_deficit": deficit})
    latest_cash: dict[str, dict] = {}
    for row in progress:
        latest_cash[str(row.get("studio_id"))] = {
            "cycle": row.get("cycle"), "cash_cents": row.get("cash_cents"),
            "outstanding": row.get("outstanding"),
            "release_count": row.get("release_count")}
    return {"by_studio": by_studio, "final_studio_finances": latest_cash,
            "published_count": sum(len(events) for events in by_studio.values())}


def player_summary(report: dict) -> dict:
    releases = [{"id": row.get("id"), "cycle": row.get("cycle"),
                 "frozen_standards": row.get("standards"),
                 "review_tenths": row.get("sales", {}).get("review_tenths"),
                 "earned_units": row.get("sales", {}).get("earned_units"),
                 "cash_cents": row.get("cash_cents")}
                for row in report.get("releases", [])]
    factors = [row.get("factor", {}) for row in report.get("observations", [])
               if row.get("owner") == report.get("recipe", {}).get("studio_id")
               and row.get("factor")]
    return {"releases": releases,
            "recorded_player_sales_factors": len(factors),
            "minimum_factor_bp": min((int(f.get("factor_bp", 10000)) for f in factors),
                                     default=None),
            "completed_pressured_player": report.get("coverage", {}).get(
                "completed_pressured_player")}


def process_summary(path: Path, report: dict) -> dict:
    run_path = path.parent / "world-run.json"
    run = read(run_path) if run_path.is_file() else {}
    process = run.get("world_process", {})
    checkpoints = [entry.get("checkpoint_bytes") for entry in report.get("timings", [])
                   if isinstance(entry.get("checkpoint_bytes"), int)]
    return {"run_report": str(run_path) if run else None,
            "harness_sha256": run.get("harness_sha256"),
            "bundle_manifest_sha256": run.get("bundle_snapshot_manifest_sha256"),
            "actual_process_cpu_seconds": process.get("actual_process_cpu_seconds"),
            "wall_seconds": process.get("elapsed_seconds"),
            "timed_out": process.get("timed_out"),
            "checkpoint_bytes_max": max(checkpoints, default=None),
            "peak_static_memory_bytes": max((int(row.get("peak_static_memory_bytes", 0))
                                             for row in report.get("timings", [])), default=None)}


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--baseline", type=Path, required=True)
    parser.add_argument("--candidate", type=Path, required=True)
    args = parser.parse_args()
    base_path, candidate_path = args.baseline.resolve(strict=True), args.candidate.resolve(strict=True)
    base, candidate = read(base_path), read(candidate_path)
    compatible = {
        "route_seed_recipe": all(base.get(key) == candidate.get(key)
                                 for key in ("route", "seed", "recipe")),
        "different_source_identities": base.get("source_identity") != candidate.get("source_identity"),
        "initial_state_digest": base.get("initial_state_digest") == candidate.get("initial_state_digest"),
        "initial_typed_rng": base.get("initial_rng") == candidate.get("initial_rng"),
        "record_arms": base.get("candidate_mode") is False
                       and candidate.get("candidate_mode") is True,
        "successful_complete_records": all(report.get("failures") == 0
                                           and report.get("completed") is True
                                           and report.get("source_drift") is False
                                           for report in (base, candidate)),
    }
    result = {"status": "COMPARABLE" if all(compatible.values()) else "BLOCKED",
              "comparison_checks": compatible,
              "baseline": {"path": str(base_path), "source_identity": base.get("source_identity"),
                           "checks": base.get("checks"), "failures": base.get("failures"),
                           "errors": base.get("errors"), "failure_reason": base.get("failure_reason"),
                           "rivals": release_summary(base), "player": player_summary(base),
                           "process": process_summary(base_path, base)},
              "candidate": {"path": str(candidate_path), "source_identity": candidate.get("source_identity"),
                            "checks": candidate.get("checks"), "failures": candidate.get("failures"),
                            "errors": candidate.get("errors"), "failure_reason": candidate.get("failure_reason"),
                            "rivals": release_summary(candidate), "player": player_summary(candidate),
                            "process": process_summary(candidate_path, candidate)},
              "first_rival_hand_difference": first_hand_difference(base, candidate)}
    print(json.dumps(result, indent=2, sort_keys=True))


if __name__ == "__main__":
    main()
