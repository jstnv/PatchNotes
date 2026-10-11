"""Compare two explicitly paired, source-pinned simulation cases without Godot.

This is an observational report, not a balance verdict. Monetary and Fan values
remain decimal strings so downstream JSON readers cannot round signed int64s.
"""
from __future__ import annotations

import argparse
from decimal import Decimal
import hashlib
import importlib.util
import json
import math
from pathlib import Path
import re
import sys

_SPEC = importlib.util.spec_from_file_location("_simulation_runner", Path(__file__).with_name("simulate.py"))
simulate = importlib.util.module_from_spec(_SPEC)
_SPEC.loader.exec_module(simulate)

HASH = re.compile(r"[0-9a-f]{64}\Z")
CASE_ID = re.compile(r"[A-Za-z0-9_-]+\Z")
INTEGER = re.compile(r"(?:0|-?[1-9][0-9]*)\Z")
STATUSES = {"completed", "command_bound", "rejected_policy_action", "malformed_policy_decision", "invalid_policy", "artifact_write_failed"}
SAMPLING = "initial_and_after_each_executed_command"


def require(condition: bool, message: str) -> None:
    if not condition:
        raise ValueError(message)


def object_value(value: object, label: str) -> dict:
    require(isinstance(value, dict), label + " must be an object")
    return value


def integer(value: object, label: str) -> int:
    # Godot JSON companions occasionally spell integral counters as 1.0.
    valid = type(value) is int and 0 <= value < 2**63
    valid = valid or (type(value) is float and math.isfinite(value) and value.is_integer() and 0 <= value < 2**63)
    require(valid, label + " must be a nonnegative int64 counter")
    return int(value)


def decimal_integer(value: object, label: str) -> int:
    require(isinstance(value, str) and bool(INTEGER.fullmatch(value)), label + " must be a canonical decimal string")
    parsed = int(value)
    require(-(2**63) <= parsed < 2**63, label + " must fit signed int64")
    return parsed


def artifact(bundle: Path, relative: str) -> Path:
    path = bundle / simulate.safe_relative(relative)
    require(path.resolve().is_relative_to(bundle.resolve()), "Artifact escapes the bundle: " + relative)
    require(path.is_file(), "Missing artifact: " + relative)
    return path


def read(bundle: Path, relative: str) -> dict:
    return object_value(simulate.read_json(artifact(bundle, relative)), relative)


def mechanics_identity(manifest: dict) -> str:
    rows = [["res://" + key, manifest[key]] for key in sorted(manifest)
            if (key.startswith("scripts/") or key.startswith("data/"))
            and not key.startswith("scripts/debug/") and key.endswith((".gd", ".json"))]
    return hashlib.sha256(json.dumps(rows, ensure_ascii=False, separators=(",", ":")).encode()).hexdigest()


def load_bundle(bundle: Path) -> dict:
    report = read(bundle, "run-report.json")
    require(report.get("format") == simulate.FORMAT and report.get("mode") == "run", "Expected an isolated simulation run bundle")
    require(isinstance(report.get("ok"), bool), "Missing overall run status")
    manifest = read(bundle, "snapshot-manifest.json")
    require(bool(manifest), "Empty source manifest")
    for relative, digest in manifest.items():
        simulate.safe_relative(relative)
        require(isinstance(digest, str) and bool(HASH.fullmatch(digest)), "Invalid source manifest hash")
    simulate.check_snapshot(bundle / "project", manifest)
    frozen_identity = hashlib.sha256(json.dumps(manifest, sort_keys=True).encode()).hexdigest()
    require(report.get("frozen_source_identity") == frozen_identity, "Run/source manifest identity mismatch")
    for required in ("godot_sha256", "runner_sha256"):
        require(isinstance(report.get(required), str) and bool(HASH.fullmatch(report[required])), "Missing runtime/runner provenance")
    require(isinstance(report.get("godot_version"), str) and bool(report["godot_version"]), "Missing runtime version")
    require(simulate.sha(artifact(bundle, "runner.py")) == report["runner_sha256"], "Runner hash mismatch")
    hashes = object_value(report.get("input_hashes"), "input_hashes")
    require("experiment.json" in hashes and "requested.json" in hashes, "Missing input hashes")
    for name, digest in hashes.items():
        require(simulate.sha(artifact(bundle, "inputs/" + name)) == digest, "Input hash mismatch: " + name)
    config = read(bundle, "inputs/experiment.json")
    require(config.get("schema_version") == "1" and isinstance(config.get("cases"), list), "Malformed experiment configuration")
    declaration = object_value(config.get("policy"), "policy declaration")
    require(report.get("policy") == declaration, "Run policy declaration mismatch")
    require(isinstance(declaration.get("script"), str) and declaration["script"].startswith("res://"), "Missing frozen policy path")
    policy_path = artifact(bundle, "project/" + declaration["script"][6:])
    require(simulate.sha(policy_path) == declaration.get("source_identity"), "Frozen policy hash mismatch")
    summary = read(bundle, "experiment-report.json")
    require(isinstance(summary.get("results"), list), "Missing retained case results")
    return {"report": report, "config": config, "summary": summary, "source_identity": mechanics_identity(manifest), "manifest_identity": frozen_identity}


def validate_samples(telemetry: dict, result: dict) -> list[dict]:
    require(telemetry.get("schema_version") == "1" and telemetry.get("sampling") == SAMPLING, "Unsupported telemetry schema/sampling")
    for field in ("source_identity", "initial_state", "final_state"):
        require(telemetry.get(field) == result.get(field), "Telemetry/result mismatch: " + field)
    samples = telemetry.get("samples")
    commands = integer(result.get("commands"), "commands")
    require(isinstance(samples, list) and len(samples) == commands + 1, "Telemetry sample/command count mismatch")
    accepted = 0
    previous = None
    for index, sample in enumerate(samples):
        object_value(sample, "sample")
        require(integer(sample.get("step"), "step") == index, "Telemetry step is missing or duplicated")
        for field in ("sequence", "run_cycle", "release_count"):
            integer(sample.get(field), field)
        for field in ("cash_cents", "fans"):
            decimal_integer(sample.get(field), field)
        require(decimal_integer(sample["fans"], "fans") >= 0, "Fans cannot be negative")
        require(isinstance(sample.get("finance_available"), bool), "Missing finance availability")
        if sample["finance_available"]:
            require(decimal_integer(sample.get("overdue_cents"), "overdue_cents") >= 0, "Arrears cannot be negative")
        else:
            require(sample.get("overdue_cents") is None, "Unavailable finance must have null arrears")
        if "transaction_cash_low_cents" in sample:
            low = sample["transaction_cash_low_cents"]
            if low is not None:
                require(decimal_integer(low, "transaction_cash_low_cents") <= int(sample["cash_cents"]), "Transaction cash low exceeds boundary cash")
            if sample["finance_available"]:
                integer(sample.get("transaction_count"), "transaction_count")
                integer(sample.get("transactions_observed"), "transactions_observed")
                require(isinstance(sample.get("financially_blocked"), bool), "Missing financial blocked state")
            else:
                require(low is None and sample.get("financially_blocked") is None, "Unavailable finance has transaction observations")
        require(isinstance(sample.get("phase"), str) and isinstance(sample.get("in_studio"), bool), "Missing phase/Studio boundary")
        require(isinstance(sample.get("state_digest"), str) and bool(HASH.fullmatch(sample["state_digest"])), "Invalid sample state digest")
        require(isinstance(sample.get("owned_features"), list) and all(isinstance(value, str) for value in sample["owned_features"]), "Missing owned Features")
        require(isinstance(sample.get("research_queue"), list), "Missing research queue")
        require(isinstance(sample.get("command_type"), str) and isinstance(sample.get("error"), str), "Missing command/error labels")
        releases = sample.get("releases")
        require(isinstance(releases, list) and len(releases) == sample["release_count"], "Release count mismatch")
        for release in releases:
            object_value(release, "release")
            require(isinstance(release.get("id"), str) and bool(release["id"]), "Missing release ID")
            require(integer(release.get("release_cycle"), "release_cycle") <= sample["run_cycle"], "Release is in the future")
            review = release.get("review")
            require(not isinstance(review, bool) and isinstance(review, (int, float)) and math.isfinite(review) and 0 <= review <= 10, "Invalid Review")
        require(len({item["id"] for item in releases}) == len(releases), "Duplicate release ID")
        if index == 0:
            require(sample.get("accepted") is None and sample["command_type"] == "", "Initial sample cannot contain a command result")
        else:
            require(isinstance(sample.get("accepted"), bool), "Executed sample needs accepted boolean")
            require(bool(sample["command_type"]), "Executed sample needs a command type")
            request = object_value(sample.get("request"), "executed request")
            require(request.get("type") == sample["command_type"], "Request/type mismatch")
            accepted += sample["accepted"]
            require(previous["run_cycle"] <= sample["run_cycle"], "Calendar moved backwards")
            require(previous["sequence"] <= sample["sequence"], "Command sequence moved backwards")
            require(releases[:len(previous["releases"])] == previous["releases"], "Prior release history changed")
            if not sample["accepted"]:
                require(index == commands, "Commands continued after a rejection")
                require(sample["state_digest"] == previous["state_digest"], "Rejected command mutated canonical state")
        previous = sample
    require(accepted == integer(result.get("accepted_commands"), "accepted_commands"), "Accepted command count mismatch")
    for sample, prefix in ((samples[0], "initial"), (samples[-1], "final")):
        require(sample["state_digest"] == result[prefix + "_state"], "Telemetry endpoint digest mismatch")
        require(sample["run_cycle"] == result.get(prefix + "_run_cycle"), "Telemetry endpoint cycle mismatch")
        require(sample["release_count"] == result.get(prefix + "_release_count"), "Telemetry endpoint release count mismatch")
    require(commands <= result["max_commands"], "Command bound exceeded")
    status = result["status"]
    if status == "completed":
        require(samples[-1]["in_studio"] and samples[-1]["release_count"] >= result["target_release_count"], "Completed case has not reached its Studio target")
    if status == "command_bound":
        require(commands == result["max_commands"], "Command-bound status below declared bound")
    require((status == "rejected_policy_action") == any(sample.get("accepted") is False for sample in samples) or status == "artifact_write_failed", "Rejection/status mismatch")
    return samples


def load_case(bundle: Path, context: dict, case_id: str) -> dict:
    require(bool(CASE_ID.fullmatch(case_id)), "Unsafe case ID")
    prefix = "cases/" + case_id + "/"
    case = read(bundle, prefix + "case.json")
    result = read(bundle, prefix + "result.json")
    require(case.get("case_id") == case_id == result.get("case_id"), "Case ID mismatch")
    require(case.get("schema_version") == "1" and result.get("schema_version") == "1", "Unsupported case/result schema")
    matches = [item for item in context["config"]["cases"] if isinstance(item, dict) and item.get("case_id") == case_id]
    require(len(matches) == 1 and matches[0] == case, "Case differs from materialized experiment input")
    matches = [item for item in context["summary"]["results"] if isinstance(item, dict) and item.get("case_id") == case_id]
    require(len(matches) == 1 and matches[0] == result, "Case result differs from retained experiment report")
    require(result.get("source_identity") == context["source_identity"], "Case source identity differs from frozen mechanics")
    require(result.get("replayable") is True and result.get("status") in STATUSES, "Case has no usable initial state or unsupported termination")
    require(result.get("ok") is (result["status"] == "completed"), "Inconsistent case status")
    for field in ("max_commands", "target_release_count"):
        require(integer(case.get(field), field) == integer(result.get(field), field) and result[field] > 0, "Case/result horizon mismatch")
    require(case.get("telemetry") is True, "Case did not request boundary telemetry")
    study = object_value(case.get("study"), "study declaration")
    for field in ("pair_id", "arm"):
        require(isinstance(study.get(field), str) and bool(study[field]), "Explicit study pair_id/arm required")
    require(result.get("study") == study, "Case/result study declaration mismatch")
    for field in ("id", "version", "source_identity"):
        require(case.get("policy", {}).get(field) == result.get("policy", {}).get(field) == context["config"]["policy"].get(field), "Case/result policy identity mismatch")
    for field in ("engine_version", "rng_algorithm"):
        require(isinstance(result.get(field), str) and bool(result[field]), "Missing runtime/RNG identity")
    for field in ("initial_state", "final_state"):
        require(isinstance(result.get(field), str) and bool(HASH.fullmatch(result[field])), "Missing canonical state identity")
    require(isinstance(result.get("initial_rng"), dict) and bool(result["initial_rng"]), "Missing initial RNG state")
    name = result.get("artifacts", {}).get("telemetry")
    require(isinstance(name, str) and bool(name), "Missing telemetry artifact")
    telemetry_path = artifact(bundle, prefix + name)
    require(simulate.sha(telemetry_path) == result.get("telemetry_sha256"), "Telemetry hash mismatch")
    samples = validate_samples(object_value(simulate.read_json(telemetry_path), "telemetry"), result)
    return {"case": case, "result": result, "samples": samples, "hashes": {"case": simulate.sha(artifact(bundle, prefix + "case.json")), "result": simulate.sha(artifact(bundle, prefix + "result.json")), "telemetry": simulate.sha(telemetry_path)}}


def sample_values(sample: dict) -> dict:
    values = {key: sample[key] for key in ("step", "run_cycle", "cash_cents", "fans", "overdue_cents", "finance_available", "release_count", "phase", "in_studio", "owned_features", "research_queue")}
    values["financially_blocked"] = sample.get("financially_blocked")
    return values


def deltas(left: dict, right: dict) -> dict:
    output = {key: str(int(right[key]) - int(left[key])) for key in ("cash_cents", "fans")}
    output["overdue_cents"] = None if left["overdue_cents"] is None or right["overdue_cents"] is None else str(int(right["overdue_cents"]) - int(left["overdue_cents"]))
    output["release_count"] = right["release_count"] - left["release_count"]
    output["run_cycle"] = right["run_cycle"] - left["run_cycle"]
    return output


def arm_summary(loaded: dict) -> dict:
    result, samples = loaded["result"], loaded["samples"]
    cash_low = min(samples, key=lambda item: int(item["cash_cents"]))
    known_finance = [sample for sample in samples if sample["finance_available"]]
    arrears_peak = max(known_finance, key=lambda item: int(item["overdue_cents"])) if known_finance else None
    rejected = next((sample for sample in samples if sample.get("accepted") is False), None)
    transaction_samples = [sample for sample in samples if sample.get("transaction_cash_low_cents") is not None]
    transaction_low = min(transaction_samples, key=lambda sample: int(sample["transaction_cash_low_cents"])) if transaction_samples else None
    blocked = next((sample for sample in samples if sample.get("financially_blocked") is True), None)
    return {
        "case_id": result["case_id"],
        "arm": loaded["case"]["study"]["arm"],
        "status": result["status"],
        "completed": result["ok"],
        "censored": not result["ok"],
        "termination_error": result.get("error", ""),
        "commands": result["commands"],
        "accepted_commands": result["accepted_commands"],
        "target_release_count": result["target_release_count"],
        "unreached_release_count": max(0, result["target_release_count"] - result["final_release_count"]),
        "initial": sample_values(samples[0]),
        "endpoint": sample_values(samples[-1]),
        "command_boundary_cash_low_cents": cash_low["cash_cents"],
        "transaction_cash_low_cents": None if transaction_low is None else transaction_low["transaction_cash_low_cents"],
        "transaction_samples_observed": len(transaction_samples),
        "first_financially_blocked_sample": None if blocked is None else sample_values(blocked),
        "sampled_cash_low": {"cash_cents": cash_low["cash_cents"], "step": cash_low["step"], "run_cycle": cash_low["run_cycle"]},
        "sampled_arrears_peak": None if arrears_peak is None else {"overdue_cents": arrears_peak["overdue_cents"], "step": arrears_peak["step"], "run_cycle": arrears_peak["run_cycle"]},
        "finance_unavailable_samples": len(samples) - len(known_finance),
        "first_rejected_action": None if rejected is None else {key: rejected[key] for key in ("step", "run_cycle", "command_type", "request", "error")},
        "rejection_observation": "none observed" if rejected is None else "recorded command rejection; inspect its error, not every rejection is financial",
        "releases": samples[-1]["releases"],
    }


def compare(bundle: Path, left_id: str, right_id: str) -> dict:
    require(left_id != right_id, "Choose distinct cases")
    context = load_bundle(bundle)
    left, right = load_case(bundle, context, left_id), load_case(bundle, context, right_id)
    for field in ("source_identity", "engine_version", "rng_algorithm", "initial_state", "initial_rng", "max_commands", "target_release_count", "initial_run_cycle", "initial_release_count"):
        require(left["result"][field] == right["result"][field], "Paired case mismatch: " + field)
    require(left["case"]["initial"] == right["case"]["initial"], "Paired initial inputs differ")
    require(left["case"]["study"]["pair_id"] == right["case"]["study"]["pair_id"], "Study pair IDs differ")
    require(left["case"]["study"]["arm"] != right["case"]["study"]["arm"], "Study arms must be distinct")
    require(left["samples"][0] == right["samples"][0], "Initial telemetry differs despite matching initial state")
    by_cycle = [{sample["run_cycle"]: sample for sample in loaded["samples"]} for loaded in (left, right)]
    calendar = []
    for cycle in sorted(by_cycle[0].keys() & by_cycle[1].keys()):
        lhs, rhs = by_cycle[0][cycle], by_cycle[1][cycle]
        calendar.append({"run_cycle": cycle, "left": sample_values(lhs), "right": sample_values(rhs), "delta_right_minus_left": deltas(lhs, rhs)})
    initial_count = left["result"]["initial_release_count"]
    milestones = []
    common_count = min(left["result"]["final_release_count"], right["result"]["final_release_count"])
    for ordinal in range(initial_count + 1, common_count + 1):
        lhs, rhs = (next(sample for sample in loaded["samples"] if sample["release_count"] >= ordinal) for loaded in (left, right))
        lr, rr = lhs["releases"][ordinal - 1], rhs["releases"][ordinal - 1]
        delta = deltas(lhs, rhs)
        delta["review"] = str(Decimal(str(rr["review"])) - Decimal(str(lr["review"])))
        delta["release_cycle"] = rr["release_cycle"] - lr["release_cycle"]
        milestones.append({"release_ordinal": ordinal, "left": {"release": lr, "sample": sample_values(lhs)}, "right": {"release": rr, "sample": sample_values(rhs)}, "delta_right_minus_left": delta})
    return {
        "schema_version": "1",
        "kind": "paired_command_boundary_observations",
        "pair_id": left["case"]["study"]["pair_id"],
        "bundle": str(bundle.resolve()),
        "overall_run_ok": context["report"]["ok"],
        "both_cases_completed": left["result"]["ok"] and right["result"]["ok"],
        "provenance": {
            "frozen_source_identity": context["manifest_identity"],
            "source_identity": context["source_identity"],
            "engine_version": left["result"]["engine_version"],
            "rng_algorithm": left["result"]["rng_algorithm"],
            "initial_state": left["result"]["initial_state"],
            "initial_rng": left["result"]["initial_rng"],
            "godot_sha256": context["report"]["godot_sha256"],
            "comparison_tool_sha256": simulate.sha(Path(__file__)),
            "left_artifact_hashes": left["hashes"],
            "right_artifact_hashes": right["hashes"],
        },
        "conventions": {
            "delta": "right minus left",
            "sampling": SAMPLING,
            "cash_low": "Minimum among observed command-boundary samples, including the initial state; not transient cash inside a command",
            "transaction_cash_low": "Minimum of boundary cash and cash before/after newly appended ledger transactions. Excludes pre-study ledger history; does not infer unrecorded intermediate cash.",
            "calendar": "Last observed sample at each shared run_cycle; zero-cycle actions use their final observed boundary at that cycle. No interpolation, extrapolation or assumption of equal phase.",
            "release": "First post-command sample attaining each new release ordinal; compared launch milestones may occur at different calendar cycles",
            "censoring": "Failed/bounded cases retain their observed prefix. Missing releases are unobserved, never zero-valued. No rejected action means none observed, not proof of no financial blocker.",
            "integrity": "Local source/input/artifact consistency checks; no signatures or malicious-tampering guarantee. Variant tapes are not decoded here; use the separate exact replay command.",
            "scope": "Independent campaigns; no winner, balance approval, human feel or shared-world AI claim",
        },
        "left": arm_summary(left),
        "right": arm_summary(right),
        "initial_common_releases": left["samples"][0]["releases"],
        "matched_calendar": calendar,
        "matched_release_milestones": milestones,
    }


def money(cents: str | None) -> str:
    if cents is None:
        return "unavailable"
    value = int(cents)
    return ("-" if value < 0 else "") + "$" + str(abs(value) // 100) + "." + f"{abs(value) % 100:02d}"


def markdown(report: dict) -> str:
    def safe(value: object) -> str:
        return str(value).replace("|", "\\|").replace("\n", " ").replace("\r", " ")
    left, right = report["left"], report["right"]
    rows = ["# Paired simulation observations", "", f"Pair: **{safe(report['pair_id'])}**. Delta convention: **right minus left**.", "", "This is a bounded observation report. It does not select a winner or approve balance.", "", "## Case status and observed limits", "", "| Measure | Left | Right |", "|---|---|---|"]
    for label, a, b in (("Case / arm", left["case_id"] + " / " + left["arm"], right["case_id"] + " / " + right["arm"]), ("Termination", left["status"], right["status"]), ("Commands", left["commands"], right["commands"]), ("Final cycle", left["endpoint"]["run_cycle"], right["endpoint"]["run_cycle"]), ("Releases / target", f"{left['endpoint']['release_count']} / {left['target_release_count']}", f"{right['endpoint']['release_count']} / {right['target_release_count']}"), ("Cash low at sampled boundary", money(left["sampled_cash_low"]["cash_cents"]), money(right["sampled_cash_low"]["cash_cents"])), ("Peak sampled arrears", money(None if left["sampled_arrears_peak"] is None else left["sampled_arrears_peak"]["overdue_cents"]), money(None if right["sampled_arrears_peak"] is None else right["sampled_arrears_peak"]["overdue_cents"])), ("Final Fans", left["endpoint"]["fans"], right["endpoint"]["fans"]), ("Unavailable finance samples", left["finance_unavailable_samples"], right["finance_unavailable_samples"])):
        rows.append(f"| {label} | {safe(a)} | {safe(b)} |")
    rows += [f"| New-ledger-transaction cash low | {money(left['transaction_cash_low_cents'])} | {money(right['transaction_cash_low_cents'])} |", "", "Endpoint values can cover different calendars; use the matched-cycle table for calendar comparisons. Boundary cash low and arrears peak cover each arm's own observed prefix. Transaction cash low includes recorded cash before/after new ledger transactions and boundary cash; it excludes pre-study history and does not assert unrecorded intermediate values.", ""]
    for arm in (left, right):
        rejected = arm["first_rejected_action"]
        detail = "none observed" if rejected is None else f"step {rejected['step']}, cycle {rejected['run_cycle']}, {safe(rejected['command_type'])}: {safe(rejected['error'])}"
        rows += [f"- **{safe(arm['arm'])}:** {'censored/incomplete' if arm['censored'] else 'target completed'}; first rejected action: {detail}. Termination detail: {safe(arm['termination_error']) or 'none'}."]
    rows += ["", "A malformed policy or command bound is not evidence of a financial blocker. A command rejection must be interpreted from its recorded error and request.", "", "## Matched calendar", "", report["conventions"]["calendar"], "", "| Cycle | Left cash | Right cash | Δ cash | Left Fans | Right Fans | Δ Fans | Left arrears | Right arrears | Δ arrears |", "|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|"]
    for row in report["matched_calendar"]:
        lhs, rhs, delta = row["left"], row["right"], row["delta_right_minus_left"]
        rows.append(f"| {row['run_cycle']} | {money(lhs['cash_cents'])} | {money(rhs['cash_cents'])} | {money(delta['cash_cents'])} | {lhs['fans']} | {rhs['fans']} | {delta['fans']} | {money(lhs['overdue_cents'])} | {money(rhs['overdue_cents'])} | {money(delta['overdue_cents'])} |")
    rows += ["", "## Matched new release milestones", "", report["conventions"]["release"], "", "| Release ordinal | Left Review | Right Review | Δ Review | Left launch cycle | Right launch cycle | Δ launch cycle |", "|---|---:|---:|---:|---:|---:|---:|"]
    for row in report["matched_release_milestones"]:
        lhs, rhs, delta = row["left"]["release"], row["right"]["release"], row["delta_right_minus_left"]
        rows.append(f"| {row['release_ordinal']} | {lhs['review']} | {rhs['review']} | {delta['review']} | {lhs['release_cycle']} | {rhs['release_cycle']} | {delta['release_cycle']} |")
    if not report["matched_release_milestones"]:
        rows += ["", "No new release milestone was observed in both arms."]
    rows += ["", f"Initial common releases: {len(report['initial_common_releases'])}; retained separately in comparison.json. Unmatched releases are retained per arm, not imputed.", "", "## Provenance and limits", "", f"- Mechanics identity: `{report['provenance']['source_identity']}`", f"- Godot: {safe(report['provenance']['engine_version'])}", f"- Overall original run succeeded: {report['overall_run_ok']}. Retained failed cases are allowed in this report.", "- " + report["conventions"]["integrity"], "- " + report["conventions"]["scope"], "", "Full samples, exact requests, source manifest and replay artifacts remain in the original bundle. comparison.json retains milestone cash/Fans/arrears, Features, queue and artifact hashes.", ""]
    return "\n".join(rows)


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--bundle", type=Path, required=True)
    parser.add_argument("--left", required=True)
    parser.add_argument("--right", required=True)
    parser.add_argument("--output", type=Path, required=True, help="New directory outside the input bundle")
    args = parser.parse_args(argv)
    try:
        bundle, output = args.bundle.resolve(), args.output.resolve()
        require(not output.is_relative_to(bundle), "Output must be outside the input bundle")
        require(not output.exists(), "Output already exists")
        report = compare(bundle, args.left, args.right)
        output.mkdir(parents=True, exist_ok=False)
        simulate.write_json(output / "comparison.json", report)
        (output / "comparison.md").write_text(markdown(report), encoding="utf-8")
        print(json.dumps({"ok": True, "output": str(output), "both_cases_completed": report["both_cases_completed"]}))
        return 0
    except (OSError, ValueError, RuntimeError, KeyError, TypeError) as error:
        print(json.dumps({"ok": False, "error": str(error)}), file=sys.stderr)
        return 1


if __name__ == "__main__":
    sys.exit(main())
