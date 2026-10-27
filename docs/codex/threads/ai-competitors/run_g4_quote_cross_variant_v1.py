"""Compare all current-hand quotes from frozen G4 v3 and v4 simulator bundles.

This analysis-only wrapper starts fresh legal Studios in each frozen project.
It never imports a checkpoint between source revisions or edits either project.
"""
from __future__ import annotations

import argparse
import hashlib
import importlib.util
import json
from pathlib import Path
from typing import Any


QUOTE_FIELDS = (
    "raw",
    "keys",
    "candidate_ids",
    "cost_cents",
    "cash_preflight_ok",
    "next_cash_cents",
    "settlement_cents",
    "bills_paid_cents",
)
STEP_FIELDS = (
    "step",
    "phase",
    "before_state",
    "before_rng",
    "choice_digest",
    "result_digest",
    "after_state",
    "after_rng",
    "accepted",
)


def _load_simulator(repo: Path) -> Any:
    spec = importlib.util.spec_from_file_location("patch_notes_simulate", repo / "tools" / "simulate.py")
    if spec is None or spec.loader is None:
        raise RuntimeError("Could not load isolated simulator runner")
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def _run_arm(sim: Any, label: str, bundle: Path, output: Path, godot: str,
             timeout: float, script: Path) -> dict[str, Any]:
    project = bundle / "project"
    if not (project / "project.godot").is_file():
        return {"ok": False, "bundle": str(bundle), "error": "Frozen project missing"}
    report_path = bundle / "run-report.json"
    if not report_path.is_file():
        return {"ok": False, "bundle": str(bundle), "error": "Frozen runner report missing"}
    try:
        source_report = json.loads(report_path.read_text(encoding="utf-8"))
    except (OSError, ValueError) as exc:
        return {"ok": False, "bundle": str(bundle), "error": f"Frozen runner report unreadable: {exc}"}
    if not source_report.get("frozen_source_identity"):
        return {"ok": False, "bundle": str(bundle), "error": "Frozen runner report lacks source identity"}
    arm_output = output / label
    arm_output.mkdir()
    capture_path = arm_output / "quotes.json"
    before = sim.source_hashes(project)
    current_identity = hashlib.sha256(json.dumps(before, sort_keys=True).encode()).hexdigest()
    if current_identity != source_report["frozen_source_identity"]:
        return {"ok": False, "bundle": str(bundle),
                "error": "Frozen project source differs from its runner report",
                "reported_source_identity": source_report["frozen_source_identity"],
                "current_source_identity": current_identity}
    environment = sim.isolated_environment(arm_output / "profile")
    environment["PN_G4_CROSS_QUOTE_OUTPUT"] = str(capture_path)
    errors: list[str] = []
    command: dict[str, Any] | None = None
    try:
        command = sim.run_process(
            f"g4-cross-quote-{label}",
            [str(sim.resolve_godot(godot)), "--headless", "--path", str(project),
             "--script", str(script)],
            arm_output, environment, timeout,
        )
    except Exception as exc:
        errors.append(f"Process failed: {type(exc).__name__}: {exc}")
    try:
        sim.check_snapshot(project, before)
    except Exception as exc:
        errors.append(f"Frozen source changed: {type(exc).__name__}: {exc}")
    capture: dict[str, Any] | None = None
    if capture_path.is_file():
        try:
            capture = json.loads(capture_path.read_text(encoding="utf-8"))
        except (OSError, ValueError) as exc:
            errors.append(f"Capture unreadable: {type(exc).__name__}: {exc}")
    else:
        errors.append("Capture was not written")
    if capture is not None and (capture.get("failures") != 0 or len(capture.get("cases", [])) != 4):
        errors.append("Capture reported failed checks or missing cases")
    return {
        "ok": not errors,
        "bundle": str(bundle),
        "frozen_source_identity": source_report["frozen_source_identity"],
        "source_run_ok": source_report.get("ok"),
        "variant_id": source_report.get("variant", {}).get("id"),
        "capture": str(capture_path),
        "process_exit": None if command is None else command.get("exit"),
        "elapsed_seconds": None if command is None else command.get("elapsed_seconds"),
        "source_unchanged": not any(error.startswith("Frozen source changed") for error in errors),
        "errors": errors,
        "data": capture,
    }


def _compare(v3: dict[str, Any], v4: dict[str, Any]) -> tuple[list[str], dict[str, Any]]:
    failures: list[str] = []
    summary: dict[str, Any] = {"cases": 0, "matched_steps": 0,
                               "matched_hands": 0, "matched_quotes": 0,
                               "unique_cost_counts": {}}
    cases3 = {case["case_id"]: case for case in v3.get("cases", [])}
    cases4 = {case["case_id"]: case for case in v4.get("cases", [])}
    if len(cases3) != 4 or cases3.keys() != cases4.keys():
        failures.append("Four case IDs do not match across frozen sources")
    for case_id in sorted(cases3.keys() & cases4.keys()):
        c3, c4 = cases3[case_id], cases4[case_id]
        summary["cases"] += 1
        for field in ("ok", "initial_state", "initial_rng", "accepted_commands", "release_count"):
            if c3.get(field) != c4.get(field):
                failures.append(f"{case_id}: {field} differs")
        steps3, steps4 = c3.get("steps", []), c4.get("steps", [])
        if len(steps3) != len(steps4):
            failures.append(f"{case_id}: step count differs ({len(steps3)} vs {len(steps4)})")
        for index, (s3, s4) in enumerate(zip(steps3, steps4)):
            summary["matched_steps"] += 1
            for field in STEP_FIELDS:
                if s3.get(field) != s4.get(field):
                    failures.append(f"{case_id} step {index}: {field} differs")
        hands3, hands4 = c3.get("hands", []), c4.get("hands", [])
        if len(hands3) != 4 or len(hands4) != 4:
            failures.append(f"{case_id}: expected four quoted hands in each source")
        summary["unique_cost_counts"][case_id] = []
        for index, (h3, h4) in enumerate(zip(hands3, hands4)):
            summary["matched_hands"] += 1
            for field in ("step", "phase", "hand_revision", "before_state", "before_rng",
                          "unique_cost_count", "invalid_cost_count"):
                if h3.get(field) != h4.get(field):
                    failures.append(f"{case_id} hand {index}: {field} differs")
            summary["unique_cost_counts"][case_id].append({
                "phase": h3.get("phase"), "hand_revision": h3.get("hand_revision"),
                "v3": h3.get("unique_cost_count"), "v4": h4.get("unique_cost_count"),
            })
            quotes3, quotes4 = h3.get("quotes", []), h4.get("quotes", [])
            if len(quotes3) != 35 or len(quotes4) != 35:
                failures.append(f"{case_id} hand {index}: expected 35 quotes in each source")
            if [q.get("candidate_ids") for q in quotes3] != [q.get("candidate_ids") for q in quotes4]:
                failures.append(f"{case_id} hand {index}: quote order differs")
            by_ids3 = {tuple(q["candidate_ids"]): q for q in quotes3}
            by_ids4 = {tuple(q["candidate_ids"]): q for q in quotes4}
            if len(by_ids3) != 35 or by_ids3.keys() != by_ids4.keys():
                failures.append(f"{case_id} hand {index}: quote ID sets differ or duplicate")
            for ids in sorted(by_ids3.keys() & by_ids4.keys()):
                q3, q4 = by_ids3[ids], by_ids4[ids]
                summary["matched_quotes"] += 1
                for field in QUOTE_FIELDS:
                    if q3.get(field) != q4.get(field):
                        failures.append(f"{case_id} hand {index} IDs {ids}: {field} differs")
                if q3.get("reason") != q4.get("reason"):
                    failures.append(f"{case_id} hand {index} IDs {ids}: reason differs")
                if not q4.get("cash_preflight_ok", False) and not q4.get("reason"):
                    summary["unavailable_without_reason"] = summary.get("unavailable_without_reason", 0) + 1
    return failures, summary


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--v3-bundle", type=Path, required=True)
    parser.add_argument("--v4-bundle", type=Path, required=True)
    parser.add_argument("--output", type=Path, required=True)
    parser.add_argument("--godot", required=True)
    parser.add_argument("--timeout", type=float, default=240)
    args = parser.parse_args()
    v3_bundle, v4_bundle = args.v3_bundle.resolve(), args.v4_bundle.resolve()
    output = args.output.resolve()
    if v3_bundle == v4_bundle:
        parser.error("Frozen v3 and v4 bundles must be distinct")
    if output.exists():
        parser.error("Output folder already exists")
    if output.is_relative_to(v3_bundle) or output.is_relative_to(v4_bundle):
        parser.error("Output folder must be outside both frozen bundles")
    if args.timeout <= 0:
        parser.error("Timeout must be positive")
    output.mkdir(parents=True)
    script = Path(__file__).with_name("verify_g4_quote_cross_variant_v1.gd").resolve()
    repo = Path(__file__).resolve().parents[4]
    sim = _load_simulator(repo)
    arms = {
        "v3": _run_arm(sim, "v3", v3_bundle, output, args.godot, args.timeout, script),
        "v4": _run_arm(sim, "v4", v4_bundle, output, args.godot, args.timeout, script),
    }
    failures: list[str] = []
    for label, arm in arms.items():
        failures.extend(f"{label}: {error}" for error in arm.get("errors", [arm.get("error", "Unknown arm error")]) if error)
    summary: dict[str, Any] = {}
    if all(arm.get("data") is not None for arm in arms.values()):
        comparison_failures, summary = _compare(arms["v3"]["data"], arms["v4"]["data"])
        failures.extend(comparison_failures)
    result = {
        "schema_version": 1,
        "ok": not failures,
        "script": str(script),
        "script_sha256": hashlib.sha256(script.read_bytes()).hexdigest(),
        "arms": {label: {key: value for key, value in arm.items() if key != "data"}
                 for label, arm in arms.items()},
        "comparison": summary,
        "failures": failures,
    }
    (output / "result.json").write_text(json.dumps(result, indent=2), encoding="utf-8")
    print(json.dumps({"ok": result["ok"], "output": str(output),
                      "comparison": summary, "failures": failures}))
    return 0 if result["ok"] else 1


if __name__ == "__main__":
    raise SystemExit(main())
