"""Read-only audit of the predeclared G4 benefit-choice simulator study.

Consumes one frozen ``simulate.py run`` bundle. Does not execute Godot, replay,
or reconstruct the simulator's lossless Variant tape. Missing and failed cases
remain visible in the report. All cash, Fans and sales integers are emitted as
decimal strings so downstream JSON readers cannot round large values.
"""
from __future__ import annotations

import argparse
import hashlib
import json
import re
import sys
from pathlib import Path


HERE = Path(__file__).resolve().parent
DEFAULT_STUDY = HERE / "2026-10-18-g4-benefit-choice-study-v1.json"
CASE_ID = re.compile(r"[A-Za-z0-9_-]+\Z")
SHA = re.compile(r"[0-9a-f]{64}\Z")
MARKER = "G4_CHOICE_AUDIT "
MODES = {"reference", "cheapest_quote", "benefit_quote"}


def read_json(path: Path) -> dict | None:
    if not path.is_file():
        return None
    value = json.loads(path.read_text(encoding="utf-8"))
    if not isinstance(value, dict):
        raise ValueError(f"Expected JSON object: {path}")
    return value


def sha(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def mechanics_identity(manifest: dict) -> str:
    # Matches the runner's case-level identity, which excludes debug policy code.
    rows = [["res://" + key, manifest[key]] for key in sorted(manifest)
            if (key.startswith("scripts/") or key.startswith("data/"))
            and not key.startswith("scripts/debug/") and key.endswith((".gd", ".json"))]
    return hashlib.sha256(json.dumps(rows, ensure_ascii=False, separators=(",", ":")).encode()).hexdigest()


def cents(value: object) -> str | None:
    # The readable outcome uses numeric JSON; retain exact decimal text on export.
    if isinstance(value, str) and re.fullmatch(r"-?(?:0|[1-9][0-9]*)", value):
        return value
    if type(value) is int:
        return str(value)
    return None


def sample_release(sample: dict, initial_count: int) -> dict | None:
    releases = sample.get("releases", [])
    if not isinstance(releases, list) or len(releases) <= initial_count:
        return None
    return releases[initial_count] if isinstance(releases[initial_count], dict) else None


def release_summary(result: dict, samples: list[dict]) -> dict | None:
    outcome = result.get("outcome", {})
    releases = outcome.get("releases", []) if isinstance(outcome, dict) else []
    initial_count = result.get("initial_release_count", 0)
    if not isinstance(initial_count, int) or not isinstance(releases, list) or len(releases) <= initial_count:
        return None
    release = releases[initial_count]
    if not isinstance(release, dict):
        return None
    metadata = release.get("metadata", {})
    review = metadata.get("review", {}) if isinstance(metadata, dict) else {}
    sales = release.get("sales", {})
    at_launch = next((sample for sample in samples if sample_release(sample, initial_count)), None)
    return {
        "id": release.get("id"),
        "release_cycle": metadata.get("release_cycle") if isinstance(metadata, dict) else None,
        "review": review.get("final_review") if isinstance(review, dict) else None,
        "cores": review.get("cores") if isinstance(review, dict) else None,
        "scope": review.get("scope") if isinstance(review, dict) else None,
        "required_scope": review.get("required_scope") if isinstance(review, dict) else None,
        "remaining_bugs": review.get("remaining_bugs") if isinstance(review, dict) else None,
        "cash_at_launch_cents": cents(at_launch.get("cash_cents")) if at_launch else None,
        "fans_at_launch": cents(at_launch.get("fans")) if at_launch else None,
        "projected_total_units_at_launch": cents(sales.get("total_units")) if isinstance(sales, dict) else None,
        "actual_earned_units_at_stop": cents(sales.get("earned_units")) if isinstance(sales, dict) else None,
        "actual_settled_cents_at_stop": cents(sales.get("settled_cents")) if isinstance(sales, dict) else None,
        "actual_entitlement_cents_at_stop": cents(sales.get("entitlement_cents")) if isinstance(sales, dict) else None,
    }


def policy_logs(bundle: Path, issues: list[str]) -> list[dict]:
    path = bundle / "experiment.log"
    if not path.is_file():
        issues.append("Missing experiment.log; hand quote evidence unavailable")
        return []
    records = []
    for line_number, line in enumerate(path.read_text(encoding="utf-8", errors="replace").splitlines(), 1):
        if MARKER not in line:
            continue
        try:
            record = json.loads(line.split(MARKER, 1)[1])
        except json.JSONDecodeError:
            issues.append(f"Malformed hand-choice log line {line_number}")
            continue
        if not isinstance(record, dict):
            issues.append(f"Hand-choice log line {line_number} is not an object")
            continue
        record["log_line"] = line_number
        records.append(record)
    return records


def expected_cases(study: dict) -> dict[str, dict]:
    cases = study.get("cases")
    if study.get("schema_version") != "1" or not isinstance(cases, list) or len(cases) != 12:
        raise ValueError("Expected the predeclared 12-case G4 study")
    output = {}
    for case in cases:
        if not isinstance(case, dict):
            raise ValueError("Malformed study case")
        case_id = case.get("case_id")
        if not isinstance(case_id, str) or not CASE_ID.fullmatch(case_id) or case_id in output:
            raise ValueError("Unsafe or repeated study case ID")
        output[case_id] = case
    return output


def main(bundle: Path, study_path: Path) -> dict:
    bundle = bundle.resolve()
    study = read_json(study_path)
    if study is None:
        raise ValueError(f"Missing study declaration: {study_path}")
    expected = expected_cases(study)
    issues: list[str] = []
    run = read_json(bundle / "run-report.json")
    if run is None or run.get("format") != "patch-notes-isolated-simulation-v1" or run.get("mode") != "run":
        raise ValueError("Input is not a frozen simulate.py run bundle")
    manifest = read_json(bundle / "snapshot-manifest.json")
    mechanics = None
    if manifest is None:
        issues.append("Missing snapshot manifest")
    else:
        identity = hashlib.sha256(json.dumps(manifest, sort_keys=True).encode()).hexdigest()
        mechanics = mechanics_identity(manifest)
        if identity != run.get("frozen_source_identity"):
            issues.append("Frozen source manifest identity mismatch")
        for relative, digest in manifest.items():
            parts = relative.split("/") if isinstance(relative, str) else []
            if not parts or any(part in ("", ".", "..") for part in parts) or "\\" in relative or not isinstance(digest, str) or not SHA.fullmatch(digest):
                issues.append(f"Invalid frozen source manifest entry: {relative}")
                continue
            source_file = bundle / "project" / Path(*parts)
            if not source_file.is_file() or sha(source_file) != digest:
                issues.append(f"Frozen source file/hash mismatch: {relative}")
        policy_decl = run.get("policy", {})
        policy_script = policy_decl.get("script") if isinstance(policy_decl, dict) else None
        if isinstance(policy_script, str) and policy_script.startswith("res://"):
            policy_file = bundle / "project" / policy_script[6:]
            if not policy_file.is_file() or sha(policy_file) != policy_decl.get("source_identity"):
                issues.append("Frozen policy file/hash mismatch")
        else:
            issues.append("Missing frozen policy declaration")
    if run.get("ok") is not True:
        issues.append("Run report is not successful; retained partial evidence follows")
    runner_file = bundle / "runner.py"
    if not runner_file.is_file() or sha(runner_file) != run.get("runner_sha256"):
        issues.append("Frozen runner file/hash mismatch")
    if run.get("case_count") != len(expected):
        issues.append(f"Run case_count {run.get('case_count')} differs from declared {len(expected)}")
    materialized = read_json(bundle / "inputs" / "experiment.json")
    if materialized is None:
        issues.append("Missing materialized experiment input")
        materialized_cases = {}
    else:
        materialized_cases = {item.get("case_id"): item for item in materialized.get("cases", []) if isinstance(item, dict)}
        if set(materialized_cases) != set(expected):
            issues.append("Materialized case IDs differ from declared study")
        hashes = run.get("input_hashes", {})
        if isinstance(hashes, dict):
            for name, digest in hashes.items():
                input_file = bundle / "inputs" / name
                if not input_file.is_file() or sha(input_file) != digest:
                    issues.append(f"Frozen input hash mismatch: {name}")
    experiment = read_json(bundle / "experiment-report.json")
    experiment_results = {item.get("case_id"): item for item in experiment.get("results", []) if isinstance(item, dict)} if experiment else {}
    run_results = {item.get("case_id"): item for item in run.get("results", []) if isinstance(item, dict)}
    logs = policy_logs(bundle, issues)
    cases: dict[str, dict] = {}
    for case_id, declared in expected.items():
        case_dir = bundle / "cases" / case_id
        result = read_json(case_dir / "result.json")
        telemetry = read_json(case_dir / "telemetry.json")
        metrics = read_json(case_dir / "metrics.json")
        actual_case = read_json(case_dir / "case.json")
        recipe = declared.get("initial", {}).get("recipe", {})
        config = declared.get("policy", {}).get("config", {})
        mode = config.get("mode")
        studio_id = recipe.get("studio_id")
        group_id = case_id.rsplit("-", 1)[0]
        arm: dict = {"group": group_id, "mode": mode, "status": "missing", "issues": [], "hands": []}
        cases[case_id] = arm
        if mode not in MODES or not isinstance(studio_id, str):
            arm["issues"].append("Malformed predeclared mode or Studio ID")
        if result is None:
            arm["status"] = run_results.get(case_id, {}).get("status", "missing_result")
            arm["issues"].append("Missing result.json; keep timeout or interrupted case")
            continue
        arm["status"] = result.get("status", "unknown")
        arm["ok"] = result.get("ok")
        arm["commands"] = result.get("commands")
        arm["accepted_commands"] = result.get("accepted_commands")
        arm["error"] = result.get("error")
        arm["initial_state"] = result.get("initial_state")
        arm["initial_rng"] = result.get("initial_rng")
        arm["initial_run_cycle"] = result.get("initial_run_cycle")
        arm["initial_release_count"] = result.get("initial_release_count")
        arm["source_identity"] = result.get("source_identity")
        arm["runtime"] = {"engine_version": result.get("engine_version"), "rng_algorithm": result.get("rng_algorithm"), "policy": result.get("policy")}
        outcome = result.get("outcome") if isinstance(result.get("outcome"), dict) else {}
        arm["final"] = {"cash_cents": cents(outcome.get("cash_cents")), "fans": cents(outcome.get("fans")), "run_cycle": result.get("final_run_cycle"), "release_count": result.get("final_release_count")}
        arm["policy_and_observation_us"] = metrics.get("policy_and_observation_us") if metrics else None
        if result.get("status") != "completed" or result.get("ok") is not True:
            arm["issues"].append("Case did not complete legally")
        if mechanics is not None and result.get("source_identity") != mechanics:
            arm["issues"].append("Case/source identity mismatch")
        run_policy = run.get("policy", {})
        case_policy = result.get("policy", {})
        if not isinstance(run_policy, dict) or not isinstance(case_policy, dict) or any(case_policy.get(key) != run_policy.get(key) for key in ("id", "version", "source_identity")):
            arm["issues"].append("Case/frozen policy identity mismatch")
        if case_id not in experiment_results:
            arm["issues"].append("Case missing from experiment-report retained results")
        elif experiment_results[case_id] != result:
            arm["issues"].append("Case differs from experiment-report retained result")
        if case_id in run_results and any(run_results[case_id].get(key) != result.get(key) for key in ("status", "commands", "final_run_cycle", "final_release_count")):
            arm["issues"].append("Case differs from run-report compact result")
        if actual_case is None or case_id not in materialized_cases or actual_case != materialized_cases[case_id]:
            arm["issues"].append("Case input differs from materialized input")
        elif actual_case.get("initial") != declared.get("initial") or actual_case.get("max_commands") != declared.get("max_commands") or actual_case.get("target_release_count") != declared.get("target_release_count") or actual_case.get("telemetry") != declared.get("telemetry") or actual_case.get("policy", {}).get("config") != config:
            arm["issues"].append("Materialized case differs from predeclared study")
        if result.get("max_commands") != declared.get("max_commands") or result.get("target_release_count") != declared.get("target_release_count"):
            arm["issues"].append("Result horizon differs from predeclared study")
        samples = telemetry.get("samples", []) if telemetry else []
        if not isinstance(samples, list):
            samples = []
        if telemetry is None:
            arm["issues"].append("Missing telemetry")
        else:
            if sha(case_dir / "telemetry.json") != result.get("telemetry_sha256"):
                arm["issues"].append("Telemetry SHA-256 mismatch")
            if telemetry.get("initial_state") != result.get("initial_state") or telemetry.get("final_state") != result.get("final_state"):
                arm["issues"].append("Telemetry endpoint digest mismatch")
            if samples and (samples[0].get("state_digest") != result.get("initial_state") or samples[-1].get("state_digest") != result.get("final_state")):
                arm["issues"].append("Telemetry sample endpoint digest mismatch")
            if len(samples) != result.get("commands", -1) + 1:
                arm["issues"].append("Telemetry sample count differs from command count")
        arm["release"] = release_summary(result, samples)
        cash_samples = [int(sample["cash_cents"]) for sample in samples if isinstance(sample, dict) and cents(sample.get("cash_cents")) is not None]
        arm["cash_low_cents"] = str(min(cash_samples)) if cash_samples else None
        overdue = [int(sample["overdue_cents"]) for sample in samples if isinstance(sample, dict) and cents(sample.get("overdue_cents")) is not None]
        arm["overdue_peak_cents"] = str(max(overdue)) if overdue else None
        finance = outcome.get("finance", {})
        rows = finance.get("rows", []) if isinstance(finance, dict) else []
        arm["finance_feature_play_total_cents"] = str(sum(int(row.get("feature_play_cents", 0)) for row in rows if isinstance(row, dict))) if isinstance(rows, list) else None
        if metrics is None:
            arm["issues"].append("Missing metrics")
        observed_plays = [sample for sample in samples if isinstance(sample, dict) and sample.get("command_type") == "development" and sample.get("request", {}).get("payload", {}).get("request", {}).get("type") == "play" and sample.get("request", {}).get("payload", {}).get("request", {}).get("phase") in ("design", "alpha")]
        matching_logs = [item for item in logs if item.get("mode") == mode and isinstance(item.get("project_id"), str) and item["project_id"].startswith(studio_id + ":project:")]
        if len(matching_logs) != len(observed_plays):
            arm["issues"].append(f"Logged Design/Alpha choices {len(matching_logs)} != executed plays {len(observed_plays)}")
        for index, sample in enumerate(observed_plays):
            request = sample["request"]["payload"]["request"]
            logged = matching_logs[index] if index < len(matching_logs) else {}
            quote_cost = cents(logged.get("cost_cents"))
            quote_cash = cents(logged.get("next_cash_cents"))
            requested_tokens = request.get("payload", {}).get("candidate_ids")
            quoted_tokens = logged.get("candidate_ids")
            same_tokens = isinstance(requested_tokens, list) and isinstance(quoted_tokens, list) and sorted(requested_tokens) == sorted(quoted_tokens)
            if logged and (logged.get("phase") != request.get("phase") or not same_tokens):
                arm["issues"].append(f"Hand choice log/request mismatch at play {index + 1}")
            if logged.get("run_cycle") is not None and logged.get("run_cycle") != request.get("run_cycle"):
                arm["issues"].append(f"Hand choice cycle mismatch at play {index + 1}")
            if quote_cash is not None and int(quote_cash) >= 0 and quote_cash != cents(sample.get("cash_cents")) and sample.get("accepted") is True:
                arm["issues"].append(f"Quote/actual after-cash mismatch at play {index + 1}")
            if quote_cost is None or int(quote_cost) < 0 or quote_cash is None or int(quote_cash) < 0:
                arm["issues"].append(f"Unavailable exact quote at play {index + 1}")
            arm["hands"].append({
                "phase": request.get("phase"), "run_cycle": request.get("run_cycle"),
                "tokens": requested_tokens, "quoted_candidate_ids": quoted_tokens,
                "ordered_tokens_match": requested_tokens == quoted_tokens,
                "accepted": sample.get("accepted"),
                "quoted_cost_cents": quote_cost,
                "quoted_next_cash_cents": quote_cash,
                "quoted_settlement_cents": cents(logged.get("settlement_cents")),
                "quoted_bills_paid_cents": cents(logged.get("bills_paid_cents")),
                "actual_after_cash_cents": cents(sample.get("cash_cents")),
                "proxy": logged.get("proxy"), "log_line": logged.get("log_line"),
            })
        if len(observed_plays) == len(matching_logs) and all(hand.get("quoted_cost_cents") is not None and int(hand["quoted_cost_cents"]) >= 0 for hand in arm["hands"]):
            quoted_total = sum(int(hand["quoted_cost_cents"]) for hand in arm["hands"])
            arm["quoted_hand_cost_total_cents"] = str(quoted_total)
            if arm["finance_feature_play_total_cents"] is not None and quoted_total != int(arm["finance_feature_play_total_cents"]):
                arm["issues"].append("Sum of hand quotes differs from finance Feature-play total")
    groups: dict[str, dict] = {}
    for case_id, arm in cases.items():
        group = groups.setdefault(arm["group"], {"case_ids": [], "initial_full_state_and_rng_equal": False, "issues": []})
        group["case_ids"].append(case_id)
    for group_id, group in groups.items():
        arms = [cases[case_id] for case_id in group["case_ids"]]
        if len(arms) != 3 or {arm["mode"] for arm in arms} != MODES:
            group["issues"].append("Expected one reference, cheapest and benefit arm")
        initials = [(arm.get("initial_state"), arm.get("initial_rng"), arm.get("initial_run_cycle"), arm.get("initial_release_count"), arm.get("source_identity"), arm.get("runtime", {}).get("engine_version"), arm.get("runtime", {}).get("rng_algorithm")) for arm in arms]
        if all(value[0] and isinstance(value[1], dict) and value[1] for value in initials) and all(value == initials[0] for value in initials[1:]):
            group["initial_full_state_and_rng_equal"] = True
        else:
            group["issues"].append("Initial full-state digest, RNG, horizon or runtime differs")
        by_mode = {arm["mode"]: arm for arm in arms}
        benefit = by_mode.get("benefit_quote", {})
        group["benefit_minus_controls"] = {}
        for control_mode in ("reference", "cheapest_quote"):
            control = by_mode.get(control_mode, {})
            left_release = control.get("release") or {}
            right_release = benefit.get("release") or {}
            comparison = {}
            for key in ("review", "cash_at_launch_cents", "fans_at_launch", "projected_total_units_at_launch", "actual_earned_units_at_stop", "actual_settled_cents_at_stop"):
                left, right = left_release.get(key), right_release.get(key)
                if left is None or right is None:
                    comparison[key] = None
                elif key == "review":
                    comparison[key] = round(float(right) - float(left), 4)
                else:
                    comparison[key] = str(int(right) - int(left))
            group["benefit_minus_controls"][control_mode] = comparison
    # Every marker must belong to one declared case, even if its case timed out.
    for item in logs:
        owners = [case_id for case_id, declared in expected.items() if item.get("mode") == declared.get("policy", {}).get("config", {}).get("mode") and isinstance(item.get("project_id"), str) and item["project_id"].startswith(str(declared.get("initial", {}).get("recipe", {}).get("studio_id")) + ":project:")]
        if len(owners) != 1:
            issues.append(f"Unowned or ambiguous choice log line {item['log_line']}")
    complete = len(groups) == 4 and all(arm.get("status") == "completed" and not arm["issues"] for arm in cases.values()) and all(group["initial_full_state_and_rng_equal"] and not group["issues"] for group in groups.values()) and not issues
    return {
        "format": "g4-benefit-choice-audit-v2", "bundle": str(bundle), "study": str(study_path.resolve()),
        "frozen_source_identity": run.get("frozen_source_identity"), "case_mechanics_identity": mechanics, "variant": run.get("variant"),
        "godot_version": run.get("godot_version"), "godot_sha256": run.get("godot_sha256"),
        "run_ok": run.get("ok"), "audit_complete": complete, "issues": issues,
        "groups": groups, "cases": cases,
        "limits": ["A matching digest and telemetry hash are file-consistency checks; fresh-process replay remains separate.", "The Variant tape is retained but not decoded by this helper.", "Feature-play finance rows aggregate by month; selected quote costs are checked against next cash and their aggregate, not a per-hand receipt field.", "Projected total units are launch forecasts. Actual earned units and settled cents are zero at the immediate first-release stop; later sales need the declared Studio continuation."],
    }


def markdown(report: dict) -> str:
    lines = ["# G4 benefit-choice bundle audit", "", f"Bundle: `{report['bundle']}`", f"Frozen source: `{report['frozen_source_identity']}`", f"Audit complete: **{report['audit_complete']}**", "", "| Group | Mode | Status | Review | Core | Scope | Bugs | Launch cash | Fans | Projected units | Earned units | Settled cents | Policy/obs μs |", "|---|---|---|---:|---|---|---:|---:|---:|---:|---:|---:|---:|---:|"]
    for case_id, arm in report["cases"].items():
        release = arm.get("release") or {}
        scope = f"{release.get('scope')}/{release.get('required_scope')}" if release.get("scope") is not None else "—"
        values = [arm["group"], arm["mode"], arm["status"], release.get("review"), release.get("cores"), scope, release.get("remaining_bugs"), release.get("cash_at_launch_cents"), release.get("fans_at_launch"), release.get("projected_total_units_at_launch"), release.get("actual_earned_units_at_stop"), release.get("actual_settled_cents_at_stop"), arm.get("policy_and_observation_us")]
        lines.append("| " + " | ".join(str(value) if value is not None else "—" for value in values) + " |")
    lines += ["", "## Integrity and coverage", ""]
    for group_id, group in report["groups"].items():
        lines.append(f"- {group_id}: initial full state/RNG equal = {group['initial_full_state_and_rng_equal']}; issues = {', '.join(group['issues']) or 'none'}")
        for control, delta in group.get("benefit_minus_controls", {}).items():
            lines.append(f"  - Benefit minus {control}: Review {delta['review']}, launch cash cents {delta['cash_at_launch_cents']}, projected units {delta['projected_total_units_at_launch']}, actual earned units {delta['actual_earned_units_at_stop']}")
    for case_id, arm in report["cases"].items():
        if arm["issues"]:
            lines.append(f"- {case_id}: " + "; ".join(arm["issues"]))
    for issue in report["issues"]:
        lines.append("- Bundle: " + issue)
    lines += ["", "## Limits", ""] + ["- " + limit for limit in report["limits"]]
    return "\n".join(lines) + "\n"


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--bundle", type=Path, required=True, help="Existing frozen simulate.py run output folder")
    parser.add_argument("--study", type=Path, default=DEFAULT_STUDY, help="Predeclared 12-case input JSON")
    parser.add_argument("--output", type=Path, help="New report folder; omitted prints compact JSON to stdout")
    args = parser.parse_args()
    try:
        audit = main(args.bundle, args.study)
        if args.output:
            args.output.mkdir(parents=True, exist_ok=False)
            (args.output / "audit.json").write_text(json.dumps(audit, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
            (args.output / "audit.md").write_text(markdown(audit), encoding="utf-8")
            print(args.output.resolve())
        else:
            print(json.dumps(audit, separators=(",", ":"), ensure_ascii=False))
        sys.exit(0 if audit["audit_complete"] else 1)
    except (OSError, ValueError, TypeError, KeyError) as exc:
        print(f"G4 audit error: {exc}", file=sys.stderr)
        sys.exit(2)
