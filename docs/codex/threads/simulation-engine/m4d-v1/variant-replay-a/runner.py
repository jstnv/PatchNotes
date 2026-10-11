"""Run source-pinned, isolated headless campaign experiments and exact replays.

Python 3.10+ standard library only. No editor cache, player saves, export, or
computer control is used. See docs/codex/threads/simulation-engine/USAGE.md.
"""
from __future__ import annotations

import argparse
import datetime as dt
import hashlib
import importlib.util
import json
import os
from pathlib import Path
import shutil
import subprocess
import sys
import time

ROOT = Path(__file__).resolve().parents[1]
SOURCE_ROOTS = {"scripts", "scenes", "data", "assets", "resources", "autoload"}
SOURCE_SUFFIXES = {".gd", ".uid", ".tscn", ".tres", ".res", ".json", ".png", ".svg", ".jpg", ".jpeg", ".webp", ".ogg", ".wav", ".mp3", ".ttf", ".otf", ".gdshader", ".gdshaderinc", ".import", ".txt", ".md", ".csv", ".bin"}
ROOT_FILES = {"project.godot", "icon.svg", "icon.svg.import"}
FORMAT = "patch-notes-isolated-simulation-v1"


def sha(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as stream:
        for block in iter(lambda: stream.read(1024 * 1024), b""):
            digest.update(block)
    return digest.hexdigest()


def write_json(path: Path, value: object) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(value, indent=2, ensure_ascii=False, allow_nan=False) + "\n", encoding="utf-8")


def read_json(path: Path) -> object:
    return json.loads(path.read_text(encoding="utf-8-sig"), parse_constant=lambda value: (_ for _ in ()).throw(ValueError("Nonfinite JSON: " + value)))


def safe_relative(value: str) -> Path:
    # Manifest/resource paths always use forward slashes on every host.
    if not isinstance(value, str) or not value or value.startswith("/") or any(character in value for character in '\\:<>"|?*\0'):
        raise ValueError("Unsafe artifact path: " + str(value))
    path = Path(value)
    if path.is_absolute() or any(part in {"..", ".", ""} or part.rstrip(" .") != part for part in value.split("/")):
        raise ValueError("Unsafe artifact path: " + value)
    return path


def reject_links(path: Path) -> None:
    """Reject links before resolve() loses their spelling (including Windows junctions)."""
    for item in (path.absolute(), *path.absolute().parents):
        if item.is_symlink() or getattr(item, "is_junction", lambda: False)():
            raise ValueError("Linked source/output paths are unsupported: " + str(item))


def source_files(project: Path) -> dict[str, Path]:
    reject_links(project)
    result: dict[str, Path] = {}
    for name in sorted(ROOT_FILES):
        path = project / name
        reject_links(path)
        if path.is_file():
            result[name] = path
    for root in sorted(SOURCE_ROOTS):
        base = project / root
        reject_links(base)
        if not base.exists():
            continue
        for directory, directories, files in os.walk(base, followlinks=False):
            directories[:] = sorted(name for name in directories if not name.startswith("."))
            for name in directories + files:
                path = Path(directory) / name
                if path.is_symlink() or getattr(path, "is_junction", lambda: False)() or not path.resolve().is_relative_to(project.resolve()):
                    raise ValueError("Source links outside the project are unsupported: " + str(path))
            for name in sorted(files):
                path = Path(directory) / name
                if not name.startswith(".") and path.suffix.lower() in SOURCE_SUFFIXES:
                    result[path.relative_to(project).as_posix()] = path
    if "project.godot" not in result:
        raise ValueError("Missing project.godot")
    return result


def source_hashes(project: Path) -> dict[str, str]:
    return {relative: sha(path) for relative, path in source_files(project).items()}


def copy_snapshot(project: Path, destination: Path) -> dict[str, str]:
    """Copy working files, then fence every source byte and the source inventory."""
    reject_links(destination)
    files = source_files(project)
    before = {relative: sha(path) for relative, path in files.items()}
    destination.mkdir(parents=True, exist_ok=False)
    for relative, path in files.items():
        target = destination / relative
        target.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(path, target)
        if sha(target) != before[relative]:
            raise RuntimeError("Source changed while copying: " + relative)
    if source_hashes(project) != before:
        raise RuntimeError("Source changed while taking the snapshot; retry into a new output directory")
    return before


def check_snapshot(project: Path, expected: dict[str, str]) -> None:
    if source_hashes(project) != expected:
        raise RuntimeError("Frozen source snapshot changed or is incomplete")


def isolated_environment(profile: Path) -> dict[str, str]:
    environment = {key: value for key, value in os.environ.items() if not key.startswith("PN_")}
    for key in ("APPDATA", "LOCALAPPDATA", "HOME", "USERPROFILE", "XDG_DATA_HOME", "XDG_CONFIG_HOME", "XDG_CACHE_HOME", "TMP", "TEMP", "TMPDIR"):
        target = profile / key
        target.mkdir(parents=True, exist_ok=True)
        environment[key] = str(target)
    return environment


def resolve_godot(explicit: str | None) -> Path:
    requested = explicit or os.environ.get("GODOT_BIN")
    if requested:
        found = shutil.which(requested) or requested
    else:
        found = next((value for name in ("godot", "godot4", "Godot") if (value := shutil.which(name))), None)
    if not found or not Path(found).is_file():
        raise ValueError("Set --godot <executable>, GODOT_BIN, or put Godot on PATH")
    return Path(found).resolve()


def run_process(label: str, argv: list[str], output: Path, environment: dict[str, str], timeout: float) -> dict:
    started = time.monotonic()
    command = {"argv": argv, "cwd": str(output), "timeout_seconds": timeout, "started_utc": dt.datetime.now(dt.timezone.utc).isoformat(), "headless": "--headless" in argv}
    write_json(output / (label + ".command.json"), command)
    flags = subprocess.CREATE_NO_WINDOW if os.name == "nt" else 0
    process = subprocess.Popen(argv, cwd=output, env=environment, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, creationflags=flags)
    try:
        data, _ = process.communicate(timeout=timeout)
        status: int | str = process.returncode
    except subprocess.TimeoutExpired:
        process.kill()
        data, _ = process.communicate()
        status = "timeout"
    (output / (label + ".log")).write_bytes(data)
    lines = data.decode("utf-8", errors="replace").splitlines()
    errors = [line for line in lines if any(marker in line for marker in ("SCRIPT ERROR", "Parse Error", "FAIL:", "Assertion failed")) or line.startswith("ERROR:")]
    ignored = [line for line in errors if "root certificate store" in line]
    errors = [line for line in errors if line not in ignored]
    command.update(exit=status, elapsed_seconds=time.monotonic() - started, errors=errors, ignored_environment_errors=ignored)
    write_json(output / (label + ".command.json"), command)
    if status != 0 or errors:
        raise RuntimeError(f"{label} failed ({status}); see {label}.log and {label}.command.json")
    return command


def git_provenance(repo: Path) -> dict:
    result = {}
    for label, arguments in (("branch", ["branch", "--show-current"]), ("head", ["rev-parse", "HEAD"]), ("status", ["status", "--porcelain=v1", "--untracked-files=all"]), ("diff", ["diff", "--binary", "HEAD", "--", "patch-notes", "tools/simulate.py"])):
        try:
            process = subprocess.run(["git", *arguments], cwd=repo, capture_output=True, timeout=30)
            result[label] = process.stdout.decode("utf-8", errors="replace").strip() if process.returncode == 0 else {"error": process.stderr.decode("utf-8", errors="replace")}
        except (OSError, subprocess.TimeoutExpired) as error:
            result[label] = {"error": str(error)}
    result["dirty"] = bool(result["status"]) if isinstance(result["status"], str) else None
    return result


def materialize_experiment(config_path: Path, project: Path, inputs: Path) -> dict:
    """Resolve the explicitly chosen trusted policy; never select one implicitly."""
    requested_bytes = config_path.read_bytes()
    config = json.loads(requested_bytes.decode("utf-8-sig"), parse_constant=lambda value: (_ for _ in ()).throw(ValueError("Nonfinite JSON: " + value)))
    if not isinstance(config, dict) or config.get("schema_version") != "1" or not isinstance(config.get("policy"), dict) or not isinstance(config.get("cases"), list) or not config["cases"]:
        raise ValueError("Experiment requires schema_version '1', policy, and nonempty explicit cases")
    declaration = config["policy"]
    for field in ("script", "id", "version"):
        if not isinstance(declaration.get(field), str) or not declaration[field]:
            raise ValueError("Explicit policy script, id and version are required")
    requested = declaration["script"]
    if requested.startswith("res://"):
        relative = safe_relative(requested[6:])
        policy_path = project / relative
        if not policy_path.is_file():
            raise ValueError("Policy is absent from frozen project: " + requested)
        script = requested
    else:
        supplied = Path(requested)
        supplied = supplied.resolve() if supplied.is_absolute() else (config_path.parent / supplied).resolve()
        if not supplied.is_file() or supplied.suffix.lower() != ".gd":
            raise ValueError("External policy must be one existing .gd file")
        # debug is excluded from mechanics identity; this testing policy does not
        # create a different rules revision or invalidate Studio checkpoints.
        script = "res://scripts/debug/experiment_policy/supplied_policy.gd"
        policy_path = project / script[6:]
        if policy_path.exists():
            raise ValueError("Reserved external policy destination already exists")
        policy_path.parent.mkdir(parents=True, exist_ok=True)
        before = sha(supplied)
        shutil.copy2(supplied, policy_path)
        if sha(supplied) != before or sha(policy_path) != before:
            raise RuntimeError("Supplied policy changed during copy")
    digest = sha(policy_path)
    for case in config["cases"]:
        if not isinstance(case, dict) or not isinstance(case.get("policy"), dict):
            raise ValueError("Each case requires an explicit policy configuration")
        policy = case["policy"]
        for field in ("id", "version"):
            if policy.get(field, declaration[field]) != declaration[field]:
                raise ValueError("Case policy identity does not match experiment declaration")
            policy[field] = declaration[field]
        if policy.get("source_identity", digest) != digest:
            raise ValueError("Case policy hash does not match frozen policy source")
        policy["source_identity"] = digest
        if not isinstance(policy.get("config"), dict):
            raise ValueError("Each policy config must be an object")
    config["policy"] = {"script": script, "id": declaration["id"], "version": declaration["version"], "source_identity": digest}
    inputs.mkdir(parents=True, exist_ok=True)
    (inputs / "requested.json").write_bytes(requested_bytes)
    write_json(inputs / "experiment.json", config)
    return config


def import_project(godot: Path, project: Path, output: Path, environment: dict, timeout: float) -> dict[str, str]:
    before = source_hashes(project)
    run_process("import", [str(godot), "--headless", "--path", str(project), "--editor", "--import", "--quit"], output, environment, timeout)
    after = source_hashes(project)
    # A clean import can generate UID files and refresh .import descriptors.
    # It must never rewrite source code, data, scenes, or original assets.
    changes = sorted(key for key in before.keys() | after.keys() if before.get(key) != after.get(key))
    if any(not key.endswith((".uid", ".import")) for key in changes):
        raise RuntimeError("Import unexpectedly changed frozen source: " + ", ".join(changes))
    write_json(output / "import-source-changes.json", changes)
    write_json(output / "snapshot-manifest.json", after)
    return after


def execute_run(args: argparse.Namespace, output: Path, godot: Path, environment: dict, report: dict) -> None:
    reject_links(args.repo / "patch-notes")
    source = (args.repo / "patch-notes").resolve()
    project = output / "project"
    provenance = git_provenance(args.repo)
    diff = provenance.pop("diff")
    (output / "source.diff.patch").write_text(diff if isinstance(diff, str) else json.dumps(diff), encoding="utf-8")
    write_json(output / "git-provenance.json", provenance)
    report["git"] = {key: provenance[key] for key in ("branch", "head", "dirty")}
    if getattr(args, "variant", None):
        variant_tool = load_variant_tool()
        before, variant = variant_tool.freeze_for_run(args.variant, source, project, output)
        report["variant"] = variant
    else:
        before = copy_snapshot(source, project)
    write_json(output / "workspace-source-manifest.json", before)
    config = materialize_experiment(args.config.resolve(), project, output / "inputs")
    report["policy"] = config["policy"]
    report["case_count"] = len(config["cases"])
    report["input_hashes"] = {path.name: sha(path) for path in (output / "inputs").iterdir()}
    frozen = import_project(godot, project, output, environment, args.timeout)
    report["frozen_source_identity"] = hashlib.sha256(json.dumps(frozen, sort_keys=True).encode()).hexdigest()
    try:
        run_process("experiment", [str(godot), "--headless", "--path", str(project), "--script", "res://scripts/debug/campaign_experiment_cli.gd", "--", "--config=" + str(output / "inputs/experiment.json"), "--output-dir=" + str(output / "cases"), "--output=" + str(output / "experiment-report.json")], output, environment, args.timeout)
    finally:
        check_snapshot(project, frozen)
    summary = read_json(output / "experiment-report.json")
    if not isinstance(summary, dict) or not summary.get("ok"):
        raise RuntimeError("Experiment did not report success; retained cases include failure evidence")
    report["results"] = [{key: item[key] for key in ("case_id", "ok", "status", "commands", "final_run_cycle", "final_release_count") if key in item} for item in summary["results"]]


def execute_replay(args: argparse.Namespace, output: Path, godot: Path, environment: dict, report: dict) -> None:
    bundle = args.bundle.resolve()
    expected = read_json(bundle / "snapshot-manifest.json")
    if not isinstance(expected, dict) or not expected:
        raise ValueError("Missing original frozen-source manifest")
    for relative in expected:
        safe_relative(relative)
    check_snapshot(bundle / "project", expected)
    if not args.case or any(character not in "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_-" for character in args.case):
        raise ValueError("Invalid case id")
    case = bundle / "cases" / args.case
    previous = read_json(case / "result.json")
    if not isinstance(previous, dict) or not previous.get("replayable"):
        raise ValueError("This case has no replayable initial state")
    project = output / "project"
    copied = copy_snapshot(bundle / "project", project)
    if copied != expected:
        raise RuntimeError("Original bundle changed while copying")
    inputs = output / "inputs"
    inputs.mkdir()
    for name, destination in (("case.variant.json", "case.variant.json"), ("replay.tape.json", "replay.tape.json"), ("result.json", "original-result.json")):
        before = sha(case / name)
        shutil.copy2(case / name, inputs / destination)
        if sha(case / name) != before or sha(inputs / destination) != before:
            raise RuntimeError("Original case artifact changed during copy: " + name)
    telemetry_arguments = []
    if previous.get("artifacts", {}).get("telemetry"):
        if previous["artifacts"]["telemetry"] != "telemetry.json" or sha(case / "telemetry.json") != previous.get("telemetry_sha256"):
            raise ValueError("Original telemetry artifact hash mismatch")
        shutil.copy2(case / "telemetry.json", inputs / "telemetry.json")
        if sha(inputs / "telemetry.json") != previous["telemetry_sha256"]:
            raise RuntimeError("Original telemetry changed while copying")
        telemetry_arguments = ["--telemetry=" + str(inputs / "telemetry.json")]
    frozen = import_project(godot, project, output, environment, args.timeout)
    report["original_bundle"] = str(bundle)
    report["original_case"] = args.case
    report["original_status"] = previous.get("status")
    report["replay_scope"] = "Recorded commands only; malformed policy decisions or a timeout are not reconstructed by command replay"
    report["input_hashes"] = {path.name: sha(path) for path in inputs.iterdir()}
    try:
        run_process("replay", [str(godot), "--headless", "--path", str(project), "--script", "res://scripts/debug/campaign_replay_cli.gd", "--", "--case=" + str(inputs / "case.variant.json"), "--tape=" + str(inputs / "replay.tape.json"), "--output=" + str(output / "replay-report.json"), *telemetry_arguments], output, environment, args.timeout)
    finally:
        check_snapshot(project, frozen)
    summary = read_json(output / "replay-report.json")
    if not isinstance(summary, dict) or not summary.get("ok"):
        raise RuntimeError("Replay did not match")
    if summary.get("final_state") != previous.get("final_state") or len(summary.get("steps", [])) != previous.get("commands"):
        raise RuntimeError("Replay final state or command count differs from the original case result")
    if telemetry_arguments and summary.get("telemetry_verified") is not True:
        raise RuntimeError("Replay did not verify recorded telemetry")
    report["replay"] = summary


def parser() -> argparse.ArgumentParser:
    result = argparse.ArgumentParser(description=__doc__)
    modes = result.add_subparsers(dest="mode", required=True)
    for name in ("run", "replay"):
        mode = modes.add_parser(name)
        mode.add_argument("--godot", help="Executable path; otherwise GODOT_BIN then PATH")
        mode.add_argument("--output", type=Path, required=True, help="New directory; existing paths are rejected")
        mode.add_argument("--timeout", type=float, default=240, help="Wall-clock seconds for each import/simulation process")
        if name == "run":
            mode.add_argument("--repo", type=Path, default=ROOT)
            mode.add_argument("--variant", type=Path, help="Editable candidate version created by simulator_variant.py; canonical remains unchanged")
            mode.add_argument("--config", type=Path, required=True)
        else:
            mode.add_argument("--bundle", type=Path, required=True)
            mode.add_argument("--case", required=True)
    return result


def main(argv: list[str] | None = None) -> int:
    args = parser().parse_args(argv)
    reject_links(args.output)
    output = args.output.resolve()
    if args.timeout <= 0 or not args.timeout < float("inf"):
        raise ValueError("--timeout must be a finite positive number")
    source = (args.repo / "patch-notes") if args.mode == "run" else args.bundle
    reject_links(source)
    source = source.resolve()
    if output.is_relative_to(source):
        raise ValueError("Output must be outside the source project or original bundle")
    if args.mode == "run" and args.variant:
        reject_links(args.variant)
        if output.is_relative_to(args.variant.resolve()):
            raise ValueError("Output must be outside the editable variant")
    output.mkdir(parents=True, exist_ok=False)
    (output / ".gdignore").touch()
    shutil.copy2(Path(__file__), output / "runner.py")
    if args.mode == "run" and args.variant:
        shutil.copy2(Path(__file__).with_name("simulator_variant.py"), output / "simulator_variant.py")
    report = {"format": FORMAT, "mode": args.mode, "ok": False, "created_utc": dt.datetime.now(dt.timezone.utc).isoformat(), "runner_sha256": sha(Path(__file__)), "python": sys.version, "scope": "Independent scene-free campaign simulation; not human/audible/UI acceptance or approved rival AI", "output": str(output)}
    write_json(output / "run-report.json", report)
    try:
        godot = resolve_godot(args.godot)
        report["godot_executable"] = str(godot)
        report["godot_sha256"] = sha(godot)
        environment = isolated_environment(output / "profile")
        run_process("godot-version", [str(godot), "--headless", "--version"], output, environment, min(args.timeout, 30))
        report["godot_version"] = (output / "godot-version.log").read_text(encoding="utf-8", errors="replace").strip()
        if args.mode == "run":
            execute_run(args, output, godot, environment, report)
        else:
            execute_replay(args, output, godot, environment, report)
        report["ok"] = True
    except (OSError, ValueError, RuntimeError, KeyError) as error:
        report["error"] = str(error)
    write_json(output / "run-report.json", report)
    print(json.dumps({key: report[key] for key in ("ok", "mode", "output", "error", "results", "replay") if key in report}, ensure_ascii=False))
    return 0 if report["ok"] else 1


def load_variant_tool():
    spec = importlib.util.spec_from_file_location("patch_notes_simulator_variant", Path(__file__).with_name("simulator_variant.py"))
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


if __name__ == "__main__":
    sys.exit(main())
