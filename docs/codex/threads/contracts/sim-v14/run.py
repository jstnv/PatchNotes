"""Replay six matched native Starwave arms and continue post-Game-5.

Only analysis files are installed in a disposable project copy. A failed legal
route is a recorded outcome; missing output, parser errors and source drift are
driver failures.
"""

from __future__ import annotations

import hashlib
import json
import os
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile


HERE = Path(__file__).resolve().parent
REPO = HERE.parents[4]
PIN = Path(r"C:\Users\64jus\Downloads\Patch Notes Design Folder\starwave-native-v3-pinned-source\patch-notes")
COPY = Path(r"C:\Users\64jus\Downloads\Patch Notes Design Folder\contracts-starwave-v14-source-copy")
PROFILES = Path(r"C:\Users\64jus\Downloads\Patch Notes Design Folder\contracts-starwave-v14-profiles")
GODOT = Path(r"C:\Users\64jus\Downloads\Godot_v4.7.1-stable_win64.exe\Godot_v4.7.1-stable_win64_console.exe")
PIN_MANIFEST = REPO / "docs/codex/findings/starwave-implementation-v1/source-manifest-v3.json"
PIN_RECOVERY = REPO / "docs/codex/findings/starwave-implementation-v1/source-pin-recovery-v3.json"
ROUTE = HERE / "post_game5_continuation.gd"
BASE = HERE / "cross_specialty_base.gd"
SCRIPTS = (BASE, ROUTE)
LOCAL_MANIFEST = HERE / "source-manifest.json"
V12 = HERE.parent / "sim-v12"
V13 = HERE.parent / "sim-v13" / "repair-v4"
COHORTS = {
    "action-1104": {"specialty": "action", "seed": 1104,
                    "sha256": "61f1c69c203c9e671e18fc749abac267b368ec3ac91e6b14139affa2db25d335"},
    "puzzle-4417": {"specialty": "puzzle", "seed": 4417,
                    "sha256": "8c7c42f0edc205eefda55959d7e67f66fd1da0208e4160abf60a4ba972f91381"},
    "racing-1104": {"specialty": "racing", "seed": 1104,
                    "sha256": "dde276dc491b4d5aff1b395f3db86776fae4839e5b98a28cef5ef3c6ce09559c"},
}
ARMS = ("starwave", "skip")
RUNTIME_PREFIXES = ("scripts/", "analysis/", "assets/", "data/", "resources/", "Scenes/", "scenes/")
RUNTIME_ROOTS = {"project.godot", "icon.svg", "icon.svg.import"}


def sha(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as stream:
        for chunk in iter(lambda: stream.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def pin_files() -> tuple[dict, dict[str, str]]:
    recovery = json.loads(PIN_RECOVERY.read_text(encoding="utf-8"))
    if not recovery.get("complete") or sha(PIN_MANIFEST) != recovery["source_manifest_sha256"]:
        raise RuntimeError("Native-v3 manifest/recovery provenance mismatch")
    manifest = json.loads(PIN_MANIFEST.read_text(encoding="utf-8"))
    selected = {}
    for name, digest in manifest["files"].items():
        if not name.startswith("patch-notes/"):
            continue
        relative = name[len("patch-notes/"):]
        if relative in RUNTIME_ROOTS or relative.startswith(RUNTIME_PREFIXES):
            selected[relative] = digest
    if not selected or "project.godot" not in selected:
        raise RuntimeError("No runtime project files in pin manifest")
    return manifest, selected


def verify_files(root: Path, files: dict[str, str]) -> list[str]:
    drift = []
    for relative, expected in files.items():
        path = root / relative
        if not path.is_file() or sha(path) != expected:
            drift.append(relative)
    return drift


def verify_snapshot() -> dict:
    if not LOCAL_MANIFEST.is_file():
        raise RuntimeError("Run prepare first")
    record = json.loads(LOCAL_MANIFEST.read_text(encoding="utf-8"))
    _, files = pin_files()
    if files != record["files"]:
        raise RuntimeError("Selected source manifest changed since prepare")
    return {
        "pin_drift": verify_files(PIN, files),
        "copy_drift": verify_files(COPY, files),
        "script_drift": [script.name for script in SCRIPTS
                         if sha(script) != record["analysis_scripts_sha256"][script.name]],
        "installed_script_drift": [script.name for script in SCRIPTS
                                   if sha(COPY / "scripts/debug" / script.name)
                                   != record["analysis_scripts_sha256"][script.name]],
        "input_drift": [cohort for cohort, spec in COHORTS.items()
                        if sha(HERE / "inputs" / f"{cohort}.payload.json") != spec["sha256"]],
        "reference_drift": [name for name, digest in record["v13_reference_sha256"].items()
                            if sha(V13 / name / "matched-route.json") != digest],
        "reference_audit_drift": sha(V13 / "audit-summary.json") != record["v13_audit_sha256"],
        "runner_drift": sha(Path(__file__)) != record["runner_sha256"],
    }


def require_clean_snapshot() -> dict:
    result = verify_snapshot()
    if any(result.values()):
        raise RuntimeError("Source or analysis drift: " + json.dumps(result))
    return result


def prepare() -> None:
    if COPY.exists() or LOCAL_MANIFEST.exists() or (HERE / "inputs").exists():
        raise RuntimeError("Prepared copy/manifest exists; refusing to overwrite")
    for cohort, spec in COHORTS.items():
        upstream = V12 / cohort
        attempt_result = json.loads((upstream / "attempt.json").read_text(encoding="utf-8"))
        if not attempt_result["native_valid"] or attempt_result["driver_failure"]:
            raise RuntimeError("v12 cohort is not a verified success: " + cohort)
        if sha(upstream / "before-starwave.payload.json") != spec["sha256"]:
            raise RuntimeError("v12 input hash mismatch: " + cohort)
    upstream_audit = json.loads((V13 / "audit-summary.json").read_text(encoding="utf-8"))
    if not upstream_audit.get("passed") or not upstream_audit.get("all_pairs_valid"):
        raise RuntimeError("v13 independent audit is not passed")
    references = {}
    for cohort in COHORTS:
        for arm in ARMS:
            name = f"{cohort}-{arm}"
            record = json.loads((V13 / name / "attempt.json").read_text(encoding="utf-8"))
            if not record["native_valid"] or record["driver_failure"]:
                raise RuntimeError("v13 reference arm not valid: " + name)
            references[name] = sha(V13 / name / "matched-route.json")
    pin_manifest, files = pin_files()
    before = verify_files(PIN, files)
    if before:
        raise RuntimeError("Pinned source drift before copy: " + str(before[:10]))
    for relative, expected in files.items():
        destination = COPY / relative
        destination.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(PIN / relative, destination)
        if sha(destination) != expected:
            raise RuntimeError("Copied file hash mismatch: " + relative)
    after = verify_files(PIN, files)
    if after:
        raise RuntimeError("Pinned source drift after copy: " + str(after[:10]))
    for script in SCRIPTS:
        installed = COPY / "scripts/debug" / script.name
        shutil.copy2(script, installed)
        if sha(installed) != sha(script):
            raise RuntimeError("Analysis script install hash mismatch: " + script.name)
    (HERE / "inputs").mkdir()
    for cohort, spec in COHORTS.items():
        destination = HERE / "inputs" / f"{cohort}.payload.json"
        shutil.copy2(V12 / cohort / "before-starwave.payload.json", destination)
        if sha(destination) != spec["sha256"]:
            raise RuntimeError("Copied input hash mismatch: " + cohort)
    record = {
        "source": str(PIN),
        "analysis_copy": str(COPY),
        "pinned_head": pin_manifest["head"],
        "original_manifest": str(PIN_MANIFEST),
        "original_manifest_sha256": sha(PIN_MANIFEST),
        "original_recovery": str(PIN_RECOVERY),
        "selected_file_count": len(files),
        "files": files,
        "inputs": {cohort: spec["sha256"] for cohort, spec in COHORTS.items()},
        "v13_reference_sha256": references,
        "v13_audit_sha256": sha(V13 / "audit-summary.json"),
        "pin_drift_before": before,
        "pin_drift_after": after,
        "analysis_scripts_sha256": {script.name: sha(script) for script in SCRIPTS},
        "runner_sha256": sha(Path(__file__)),
        "current_branch": subprocess.check_output(["git", "branch", "--show-current"], cwd=REPO, text=True).strip(),
        "current_head": subprocess.check_output(["git", "rev-parse", "HEAD"], cwd=REPO, text=True).strip(),
    }
    LOCAL_MANIFEST.write_text(json.dumps(record, indent=2), encoding="utf-8")
    (HERE / "prepare.command.json").write_text(json.dumps({
        "command": [sys.executable, str(Path(__file__)), "prepare"],
        "result": "copied",
        "source_manifest_sha256": record["original_manifest_sha256"],
        "runner_sha256": record["runner_sha256"],
        "analysis_scripts_sha256": record["analysis_scripts_sha256"],
    }, indent=2), encoding="utf-8")
    print("Prepared", len(files), "hash-matched runtime files", flush=True)


def godot_run(label: str, arguments: list[str], output_dir: Path, timeout: int) -> tuple[int, list[str]]:
    PROFILES.mkdir(parents=True, exist_ok=True)
    profile = Path(tempfile.mkdtemp(prefix=f"{label}-", dir=PROFILES))
    env = os.environ.copy()
    for key in ("APPDATA", "LOCALAPPDATA"):
        path = profile / key
        path.mkdir(parents=True, exist_ok=True)
        env[key] = str(path)
    env["PN_CHECKPOINT_TEST_PORT"] = "47972"
    command = [str(GODOT), "--headless", "--path", str(COPY), *arguments]
    log = output_dir / "godot.log"
    with log.open("wb") as stream:
        try:
            result = subprocess.run(command, cwd=COPY, env=env, stdout=stream,
                                    stderr=subprocess.STDOUT, timeout=timeout)
            exit_code = result.returncode
            timeout_hit = False
        except subprocess.TimeoutExpired:
            exit_code = -1
            timeout_hit = True
    lines = log.read_text(encoding="utf-8", errors="replace").splitlines()
    errors = [line for line in lines if
              ("SCRIPT ERROR" in line or line.startswith("ERROR:") or "FAIL:" in line)
              and "root certificate store" not in line]
    (output_dir / "command.json").write_text(json.dumps({
        "command": command, "exit": exit_code, "timeout": timeout_hit,
        "profile": str(profile), "errors": errors,
        "source_manifest_sha256": sha(LOCAL_MANIFEST),
        "runner_sha256": sha(Path(__file__)),
        "analysis_scripts_sha256": {script.name: sha(script) for script in SCRIPTS},
        "godot_sha256": sha(GODOT), "log": str(log),
    }, indent=2), encoding="utf-8")
    return exit_code, errors


def import_project() -> None:
    require_clean_snapshot()
    destination = HERE / "import"
    if destination.exists():
        raise RuntimeError("Import result exists; refusing to overwrite")
    destination.mkdir()
    exit_code, errors = godot_run("import", ["--editor", "--import", "--quit"], destination, 300)
    drift = verify_snapshot()
    (destination / "source-after.json").write_text(json.dumps(drift, indent=2), encoding="utf-8")
    if exit_code or errors or any(drift.values()):
        raise RuntimeError("Godot import/source gate failed")
    print("Import passed", flush=True)


def parse_check() -> None:
    require_clean_snapshot()
    destination = HERE / "parse-check"
    if destination.exists():
        raise RuntimeError("Parse-check result exists; refusing to overwrite")
    destination.mkdir()
    output = destination / "parse-result.json"
    arguments = ["--script", "res://scripts/debug/post_game5_continuation.gd", "--",
                 "--specialty=action", "--seed=1104", "--arm=invalid",
                 f"--input={HERE / 'inputs/action-1104.payload.json'}", f"--out={output}"]
    exit_code, errors = godot_run("parse-check", arguments, destination, 60)
    result = json.loads(output.read_text(encoding="utf-8")) if output.is_file() else {}
    drift = verify_snapshot()
    (destination / "source-after.json").write_text(json.dumps(drift, indent=2), encoding="utf-8")
    if exit_code != 1 or errors or result.get("stop") != "undeclared arm or specialty" or any(drift.values()):
        raise RuntimeError("Analysis script parse gate failed")
    print("Analysis script parse passed", flush=True)


def attempt(cohort: str, arm: str) -> None:
    if cohort not in COHORTS or arm not in ARMS:
        raise RuntimeError("Undeclared cohort or arm")
    require_clean_snapshot()
    import_command = HERE / "import/command.json"
    if not import_command.is_file():
        raise RuntimeError("Import gate missing")
    imported = json.loads(import_command.read_text(encoding="utf-8"))
    if imported["exit"] or imported["errors"]:
        raise RuntimeError("Import gate failed")
    if not (HERE / "parse-check/parse-result.json").is_file():
        raise RuntimeError("Analysis script parse gate missing")
    spec = COHORTS[cohort]
    source_input = HERE / "inputs" / f"{cohort}.payload.json"
    if sha(source_input) != spec["sha256"]:
        raise RuntimeError("Input checkpoint hash mismatch")
    destination = HERE / f"{cohort}-{arm}"
    if destination.exists():
        raise RuntimeError("Attempt exists; refusing to overwrite")
    destination.mkdir()
    native_path = destination / "post-game5-route.json"
    arguments = ["--script", "res://scripts/debug/post_game5_continuation.gd", "--",
                 f"--specialty={spec['specialty']}", f"--seed={spec['seed']}",
                 f"--arm={arm}", f"--input={source_input}",
                 f"--reference={V13 / f'{cohort}-{arm}' / 'matched-route.json'}",
                 f"--out={native_path}"]
    exit_code, errors = godot_run(f"{cohort}-{arm}", arguments, destination, 300)
    native_present = native_path.is_file()
    if native_present:
        native = json.loads(native_path.read_text(encoding="utf-8"))
    else:
        native = {"cohort": cohort, "arm": arm, "valid": False,
                  "stop": "native output missing", "actions": [], "releases": [],
                  "blockers": [], "errors": []}
        native_path.write_text(json.dumps(native, indent=2), encoding="utf-8")
    drift = verify_snapshot()
    (destination / "source-after.json").write_text(json.dumps(drift, indent=2), encoding="utf-8")
    driver_failure = (bool(errors) or exit_code not in (0, 1)
                      or not native_present or any(drift.values())
                      or (exit_code == 0) != bool(native.get("valid", False)))
    (destination / "attempt.json").write_text(json.dumps({
        "cohort": cohort, "specialty": spec["specialty"], "seed": spec["seed"],
        "arm": arm, "input_sha256": spec["sha256"], "native_valid": native.get("valid", False),
        "stop": native.get("stop", "missing stop reason"), "godot_exit": exit_code,
        "godot_errors": errors, "driver_failure": driver_failure,
        "source_after": drift,
        "native_result": str(native_path),
    }, indent=2), encoding="utf-8")
    print(cohort, arm, "valid=", native.get("valid", False),
          "stop=", native.get("stop"), "driver_failure=", driver_failure, flush=True)
    if driver_failure:
        raise RuntimeError("Driver failure; inspect attempt/command/log")


def main() -> None:
    if len(sys.argv) < 2:
        raise SystemExit("Usage: run.py prepare|import|parse|verify|attempt COHORT ARM")
    if sys.argv[1] == "prepare":
        prepare()
    elif sys.argv[1] == "import":
        import_project()
    elif sys.argv[1] == "parse":
        parse_check()
    elif sys.argv[1] == "verify":
        print(json.dumps(verify_snapshot(), indent=2))
    elif sys.argv[1] == "attempt" and len(sys.argv) == 4:
        attempt(sys.argv[2], sys.argv[3])
    else:
        raise SystemExit("Usage: run.py prepare|import|parse|verify|attempt COHORT ARM")


if __name__ == "__main__":
    main()
