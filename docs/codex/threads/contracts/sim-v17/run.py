"""Confirm a bounded slow-first Crown gate screen from the native-v3 pin.

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
COPY = Path(r"C:\Users\64jus\Downloads\Patch Notes Design Folder\contracts-slow-first-v17-source-copy")
PROFILES = Path(r"C:\Users\64jus\Downloads\Patch Notes Design Folder\contracts-slow-first-v17-profiles")
GODOT = Path(r"C:\Users\64jus\Downloads\Godot_v4.7.1-stable_win64.exe\Godot_v4.7.1-stable_win64_console.exe")
PIN_MANIFEST = REPO / "docs/codex/findings/starwave-implementation-v1/source-manifest-v3.json"
PIN_RECOVERY = REPO / "docs/codex/findings/starwave-implementation-v1/source-pin-recovery-v3.json"
ROUTE = HERE / "slow_first_route.gd"
LOCAL_MANIFEST = HERE / "source-manifest.json"
SPECIALTIES = ("adventure", "role_playing", "strategy", "simulation", "sports")
SEEDS = (1104, 4417)
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
        "route_drift": sha(ROUTE) != record["analysis_route_sha256"],
        "runner_drift": sha(Path(__file__)) != record["runner_sha256"],
    }


def require_clean_snapshot() -> dict:
    result = verify_snapshot()
    if result["pin_drift"] or result["copy_drift"] or result["route_drift"] or result["runner_drift"]:
        raise RuntimeError("Source or analysis drift: " + json.dumps(result))
    return result


def prepare() -> None:
    if COPY.exists() or LOCAL_MANIFEST.exists():
        raise RuntimeError("Prepared copy/manifest exists; refusing to overwrite")
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
    installed = COPY / "scripts/debug/slow_first_route.gd"
    shutil.copy2(ROUTE, installed)
    if sha(installed) != sha(ROUTE):
        raise RuntimeError("Analysis route install hash mismatch")
    record = {
        "source": str(PIN),
        "analysis_copy": str(COPY),
        "pinned_head": pin_manifest["head"],
        "original_manifest": str(PIN_MANIFEST),
        "original_manifest_sha256": sha(PIN_MANIFEST),
        "original_recovery": str(PIN_RECOVERY),
        "selected_file_count": len(files),
        "files": files,
        "pin_drift_before": before,
        "pin_drift_after": after,
        "analysis_route_sha256": sha(ROUTE),
        "runner_sha256": sha(Path(__file__)),
        "installed_route_sha256": sha(installed),
        "current_branch": subprocess.check_output(["git", "branch", "--show-current"], cwd=REPO, text=True).strip(),
        "current_head": subprocess.check_output(["git", "rev-parse", "HEAD"], cwd=REPO, text=True).strip(),
    }
    LOCAL_MANIFEST.write_text(json.dumps(record, indent=2), encoding="utf-8")
    (HERE / "prepare.command.json").write_text(json.dumps({
        "command": [sys.executable, str(Path(__file__)), "prepare"],
        "result": "copied",
        "source_manifest_sha256": record["original_manifest_sha256"],
        "runner_sha256": record["runner_sha256"],
        "route_sha256": record["analysis_route_sha256"],
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
        "runner_sha256": sha(Path(__file__)), "route_sha256": sha(ROUTE),
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


def attempt(specialty: str, seed: int) -> None:
    if specialty not in SPECIALTIES or seed not in SEEDS:
        raise RuntimeError("Undeclared specialty or seed")
    require_clean_snapshot()
    import_command = HERE / "import/command.json"
    if not import_command.is_file():
        raise RuntimeError("Import gate missing")
    imported = json.loads(import_command.read_text(encoding="utf-8"))
    if imported["exit"] or imported["errors"]:
        raise RuntimeError("Import gate failed")
    if seed == 4417:
        primary = HERE / f"{specialty}-1104/native-route.json"
        if not primary.is_file() or json.loads(primary.read_text(encoding="utf-8")).get("valid"):
            raise RuntimeError("Fallback seed allowed only after failed primary route")
    destination = HERE / f"{specialty}-{seed}"
    if destination.exists():
        raise RuntimeError("Attempt exists; refusing to overwrite")
    destination.mkdir()
    arguments = ["--script", "res://scripts/debug/slow_first_route.gd", "--",
                 f"--specialty={specialty}", f"--seed={seed}", f"--directory={destination}"]
    exit_code, errors = godot_run(f"{specialty}-{seed}", arguments, destination, 300)
    native_path = destination / "native-route.json"
    native_present = native_path.is_file()
    if native_present:
        native = json.loads(native_path.read_text(encoding="utf-8"))
    else:
        native = {"specialty": specialty, "seed": seed, "valid": False,
                  "stop": "native output missing", "actions": [], "releases": [],
                  "blockers": [], "errors": []}
        native_path.write_text(json.dumps(native, indent=2), encoding="utf-8")
    drift = verify_snapshot()
    (destination / "source-after.json").write_text(json.dumps(drift, indent=2), encoding="utf-8")
    driver_failure = (bool(errors) or exit_code not in (0, 1)
                      or not native_present or any(drift.values())
                      or (exit_code == 0) != bool(native.get("valid", False)))
    (destination / "attempt.json").write_text(json.dumps({
        "specialty": specialty, "seed": seed, "native_valid": native.get("valid", False),
        "stop": native.get("stop", "missing stop reason"), "godot_exit": exit_code,
        "godot_errors": errors, "driver_failure": driver_failure,
        "source_after": drift,
        "native_result": str(native_path),
    }, indent=2), encoding="utf-8")
    print(specialty, seed, "valid=", native.get("valid", False),
          "stop=", native.get("stop"), "driver_failure=", driver_failure, flush=True)
    if driver_failure:
        raise RuntimeError("Driver failure; inspect attempt/command/log")


def main() -> None:
    if len(sys.argv) < 2:
        raise SystemExit("Usage: run.py prepare|import|verify|attempt SPECIALTY SEED")
    if sys.argv[1] == "prepare":
        prepare()
    elif sys.argv[1] == "import":
        import_project()
    elif sys.argv[1] == "verify":
        print(json.dumps(verify_snapshot(), indent=2))
    elif sys.argv[1] == "attempt" and len(sys.argv) == 4:
        attempt(sys.argv[2], int(sys.argv[3]))
    else:
        raise SystemExit("Usage: run.py prepare|import|verify|attempt SPECIALTY SEED")


if __name__ == "__main__":
    main()
