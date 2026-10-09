"""Run declared Contracts balance arms against an isolated copy of this worktree."""

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
PROJECT = REPO / "patch-notes"
COPY = Path(r"C:\Users\64jus\Downloads\Patch Notes Design Folder\contracts-threshold-v6-source-copy")
PROFILES = Path(r"C:\Users\64jus\Downloads\Patch Notes Design Folder\contracts-threshold-v6-profiles")
GODOT = Path(r"C:\Users\64jus\Downloads\Godot_v4.7.1-stable_win64.exe\Godot_v4.7.1-stable_win64_console.exe")
SCRIPT = HERE / "crown_neon_threshold_v6.gd"
COHORTS = ("crown-current", "crown-lease")


def sha(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def prepare() -> None:
    if COPY.exists():
        raise RuntimeError(f"Copy already exists: {COPY}; refusing to overwrite it")
    tracked = subprocess.check_output(
        ["git", "ls-files", "-co", "--exclude-standard", "-z", "--", "patch-notes"],
        cwd=REPO,
    ).split(b"\0")
    names = sorted({os.fsdecode(name) for name in tracked if name})
    manifest = {}
    for name in names:
        source = REPO / name
        if not source.is_file():
            continue
        relative = source.relative_to(PROJECT)
        destination = COPY / relative
        destination.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(source, destination)
        if sha(source) != sha(destination):
            raise RuntimeError(f"Copy hash mismatch: {name}")
        manifest[str(relative).replace("\\", "/")] = sha(source)
    head = subprocess.check_output(["git", "rev-parse", "HEAD"], cwd=REPO, text=True).strip()
    branch = subprocess.check_output(["git", "branch", "--show-current"], cwd=REPO, text=True).strip()
    status = subprocess.check_output(["git", "status", "--porcelain=v1", "--", "patch-notes"], cwd=REPO, text=True)
    record = {
        "branch": branch,
        "head": head,
        "source_project": str(PROJECT),
        "analysis_copy": str(COPY),
        "file_count": len(manifest),
        "files": manifest,
        "source_status_at_copy": status.splitlines(),
        "analysis_script_sha256": sha(SCRIPT),
    }
    (HERE / "source-manifest.json").write_text(json.dumps(record, indent=2), encoding="utf-8")
    print(f"Prepared {len(manifest)} project files from {branch} {head} in {COPY}", flush=True)
    install_script()


def install_script() -> None:
    destination = COPY / "scripts" / "debug" / SCRIPT.name
    if not COPY.is_dir() or not (COPY / "project.godot").is_file():
        raise RuntimeError("Prepared project copy missing")
    destination.parent.mkdir(parents=True, exist_ok=True)
    shutil.copy2(SCRIPT, destination)
    if sha(SCRIPT) != sha(destination):
        raise RuntimeError("Analysis script hash mismatch")
    print(f"Installed analysis script in copy: {sha(SCRIPT)}", flush=True)


def execute(name: str, args: list[str], timeout: int) -> None:
    PROFILES.mkdir(parents=True, exist_ok=True)
    profile = Path(tempfile.mkdtemp(prefix=f"{name}-", dir=PROFILES))
    env = os.environ.copy()
    for key in ("APPDATA", "LOCALAPPDATA"):
        target = profile / key
        target.mkdir(parents=True, exist_ok=True)
        env[key] = str(target)
    env["PN_CHECKPOINT_TEST_PORT"] = "47613"
    command = [str(GODOT), "--headless", "--path", str(COPY), *args]
    log_path = HERE / f"{name}.log"
    with log_path.open("wb") as log:
        result = subprocess.run(command, cwd=COPY, env=env, stdout=log, stderr=subprocess.STDOUT, timeout=timeout)
    output = log_path.read_text(encoding="utf-8", errors="replace")
    errors = [line for line in output.splitlines()
              if ("SCRIPT ERROR" in line or line.startswith("ERROR:") or "FAIL:" in line)
              and "root certificate store" not in line]
    (HERE / f"{name}.command.json").write_text(
        json.dumps({"command": command, "exit": result.returncode, "script_sha256": sha(SCRIPT),
                    "log": str(log_path), "errors": errors}, indent=2), encoding="utf-8"
    )
    print(name, "exit", result.returncode, "errors", len(errors), flush=True)
    if result.returncode or errors:
        print(output[-3000:], flush=True)
        raise RuntimeError(f"Godot {name} failed; see {log_path}")


def main() -> None:
    action = sys.argv[1] if len(sys.argv) > 1 else ""
    if action == "prepare":
        prepare()
    elif action == "install":
        install_script()
    elif action == "import":
        execute("import", ["--editor", "--import", "--quit"], 300)
    elif action in COHORTS:
        result = HERE / f"{action}.json"
        if result.exists():
            raise RuntimeError(f"Result already exists: {result}; refusing to overwrite it")
        execute(action, ["--script", "res://scripts/debug/crown_neon_threshold_v6.gd", "--",
                         f"--cohort={action}", f"--out={result}"], 600)
    else:
        raise SystemExit("Usage: run.py prepare|install|import|crown-current|crown-lease")


if __name__ == "__main__":
    main()
