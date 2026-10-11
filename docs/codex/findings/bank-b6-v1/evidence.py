"""Source and upstream-acceptance checks for the pinned B6 experiment."""
from pathlib import Path
import hashlib
import json

HERE = Path(__file__).resolve().parent
REPO = HERE.parents[3]
ROUTES = [(c, p, b, s) for c in ("legacy", "current")
          for p in ("ordinary", "synergy") for b in ("early", "late")
          for s in (1104, 4417)]
ANALYSIS_FILES = ("b6.gd", "run.py", "audit.py", "evidence.py", "runner_support.py", "PLAN.md")


def sha(path):
    return hashlib.sha256(Path(path).read_bytes()).hexdigest()


def read(path):
    return json.loads(Path(path).read_text(encoding="utf-8"))


def write(path, value):
    Path(path).write_text(json.dumps(value, indent=2) + "\n", encoding="utf-8")


def digest(value):
    return hashlib.sha256(json.dumps(value, sort_keys=True, separators=(",", ":")).encode()).hexdigest()


def need(condition, message):
    if not condition:
        raise RuntimeError(message)


def runtime_files(files):
    result = {}
    for original, value in files.items():
        name = original.replace("\\", "/").casefold()
        selected = (name == "icon.svg" or name.startswith(("data/", "scenes/", "resources/", "assets/"))
                    or (name.startswith("scripts/") and not name.startswith("scripts/debug/")))
        if selected:
            need(name not in result, "Duplicate Windows runtime path: " + original)
            result[name] = value
    return result


def source_context():
    manifest = read(HERE / "source-manifest.json")
    copy = Path(manifest["analysis_copy"])
    for name, value in manifest["files"].items():
        need((copy / name).is_file() and sha(copy / name) == value, "Pinned source changed: " + name)
    for name, value in manifest["analysis_scripts_sha256"].items():
        need(sha(HERE / name) == value, "Analysis script changed without install: " + name)
        need(sha(copy / "scripts/debug" / name) == value, "Installed analysis script differs: " + name)
    bundle = {name: sha(HERE / name) for name in ANALYSIS_FILES}
    bundle["../queue-completion-v1/finance_audit.py"] = sha(HERE.parent / "queue-completion-v1/finance_audit.py")
    return {
        "source_manifest_sha256": sha(HERE / "source-manifest.json"),
        "runtime_source_sha256": digest(runtime_files(manifest["files"])),
        "analysis_bundle_sha256": digest(bundle),
        "analysis_files_sha256": bundle,
    }


def reference(record, key):
    ref = record[key]
    path = Path(ref["path"])
    if not path.is_absolute():
        path = REPO / path
    need(path.is_file() and sha(path) == ref["sha256"], "Missing or changed acceptance evidence: " + key)
    return read(path)


def upstream_context(context):
    path = HERE / "upstream-acceptance.json"
    need(path.is_file(), "Task11 repaired-export acceptance record is required; no B6 routes may run")
    record = read(path)
    need(record.get("schema_version") == 1 and record.get("repaired_export_pass") is True,
         "Repaired-export acceptance is not complete")
    for key in ("source_manifest_sha256", "runtime_source_sha256"):
        need(record.get(key) == context[key], "Acceptance source differs from pinned B6 source: " + key)
    need(bool(record.get("accepted_at")), "Acceptance date is missing")
    gate = reference(record, "automated_gate")
    need(gate.get("automated_pass") is True, "Automated acceptance failed")
    ui = reference(record, "exported_ui_audit")
    need(ui.get("pass") is True and "second-continue" in ui.get("captured_boundaries", []),
         "Exported two-game/Continue accounting acceptance is incomplete")
    pinned = runtime_files(read(HERE / "source-manifest.json")["files"])
    for key in ("automated_build_manifest", "build_manifest"):
        build = reference(record, key)
        included = build["included"]
        for name, value in runtime_files(included).items():
            need(pinned.get(name) == value, key + " differs from B6 runtime: " + name)
        need({"scripts/run_state.gd", "scenes/gameplay.tscn", "data/card_ledger.json"} <= included.keys(),
             "Incomplete build source manifest")
    package = reference(record, "package_audit")
    need(package.get("all_payload_md5_valid") is True and not package.get("missing_runtime_files")
         and not package.get("unexpected_files"), "Exported package inspection is incomplete")
    for suffix in ("exe", "pck"):
        artifact = record["artifacts"][suffix]
        need(sha(Path(artifact["path"])) == artifact["sha256"], "Accepted artifact changed: " + suffix)
        need(build["artifacts"]["Patch Notes Demo." + suffix]["sha256"] == artifact["sha256"],
             "Accepted artifact is not the source-bound export: " + suffix)
    checks = record.get("repaired_ui_checks", {})
    for key in ("studio_footer", "store_navigation", "store_detached_refresh", "payoff_dialog"):
        need(checks.get(key) is True, "Repaired exported UI check remains open: " + key)
    diagnostics = record.get("diagnostics", {})
    need(diagnostics.get("errors") == [] and diagnostics.get("reviewed") is True,
         "Repaired exported runtime diagnostics are not clean/reviewed")
    reference(record, "interaction_record")
    context = dict(context)
    context["upstream_acceptance_sha256"] = sha(path)
    return context


def validate_route(name, spec, context):
    receipt = read(HERE / (name + ".result-manifest.json"))
    need(receipt["provenance"] == context, "Archived route has different source/config/acceptance: " + name)
    need(receipt["route"] == list(spec), "Archived route specification mismatch: " + name)
    for suffix, key in ((".json.gz", "archive_sha256"), (".command.json", "command_sha256"), (".log", "log_sha256")):
        need(sha(HERE / (name + suffix)) == receipt[key], "Archived route evidence changed: " + name + suffix)
    command = read(HERE / (name + ".command.json"))
    need(command.get("provenance") == context and command.get("route") == list(spec), "Command provenance mismatch")
    need(command["analysis_scripts_sha256"] == read(HERE / "source-manifest.json")["analysis_scripts_sha256"],
         "Command ran another analysis script")
    need(command["exit"] == 0 and not command["errors"], "Native process failed: " + name)
    return receipt
