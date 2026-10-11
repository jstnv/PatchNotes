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
COPY = Path(r"C:\Users\64jus\Downloads\Patch Notes Design Folder\contracts-starwave-v10-source-copy")
PROFILES = Path(r"C:\Users\64jus\Downloads\Patch Notes Design Folder\contracts-starwave-v10-profiles")
GODOT = Path(r"C:\Users\64jus\Downloads\Godot_v4.7.1-stable_win64.exe\Godot_v4.7.1-stable_win64_console.exe")
SCRIPT = HERE / "starwave_timing_v10.gd"
SCRIPTS = (HERE / "crown_neon_chain_base_v10.gd", SCRIPT)
COHORTS = ("starwave-timing",)


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
        "analysis_scripts_sha256": {script.name: sha(script) for script in SCRIPTS},
    }
    (HERE / "source-manifest.json").write_text(json.dumps(record, indent=2), encoding="utf-8")
    print(f"Prepared {len(manifest)} project files from {branch} {head} in {COPY}", flush=True)
    install_scripts()


def install_scripts() -> None:
    if not COPY.is_dir() or not (COPY / "project.godot").is_file():
        raise RuntimeError("Prepared project copy missing")
    for script in SCRIPTS:
        destination = COPY / "scripts" / "debug" / script.name
        destination.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(script, destination)
        if sha(script) != sha(destination):
            raise RuntimeError(f"Analysis script hash mismatch: {script.name}")
        print(f"Installed {script.name} in copy: {sha(script)}", flush=True)
    manifest_path = HERE / "source-manifest.json"
    manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
    manifest["analysis_scripts_sha256"] = {script.name: sha(script) for script in SCRIPTS}
    manifest_path.write_text(json.dumps(manifest, indent=2), encoding="utf-8")


def execute(name: str, args: list[str], timeout: int) -> None:
    PROFILES.mkdir(parents=True, exist_ok=True)
    profile = Path(tempfile.mkdtemp(prefix=f"{name}-", dir=PROFILES))
    env = os.environ.copy()
    for key in ("APPDATA", "LOCALAPPDATA"):
        target = profile / key
        target.mkdir(parents=True, exist_ok=True)
        env[key] = str(target)
    env["PN_CHECKPOINT_TEST_PORT"] = "47618"
    command = [str(GODOT), "--headless", "--path", str(COPY), *args]
    log_path = HERE / f"{name}.log"
    with log_path.open("wb") as log:
        result = subprocess.run(command, cwd=COPY, env=env, stdout=log, stderr=subprocess.STDOUT, timeout=timeout)
    output = log_path.read_text(encoding="utf-8", errors="replace")
    errors = [line for line in output.splitlines()
              if ("SCRIPT ERROR" in line or line.startswith("ERROR:") or "FAIL:" in line)
              and "root certificate store" not in line]
    (HERE / f"{name}.command.json").write_text(
        json.dumps({"command": command, "exit": result.returncode,
                    "analysis_scripts_sha256": {script.name: sha(script) for script in SCRIPTS},
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
        install_scripts()
    elif action == "import":
        execute("import", ["--editor", "--import", "--quit"], 300)
    elif action in COHORTS:
        result = HERE / f"{action}.json"
        if result.exists():
            raise RuntimeError(f"Result already exists: {result}; refusing to overwrite it")
        execute(action, ["--script", "res://scripts/debug/starwave_timing_v10.gd", "--",
                         f"--cohort={action}", f"--out={result}"], 600)
    else:
        raise SystemExit("Usage: run.py prepare|install|import|starwave-timing")


if __name__ == "__main__":
    main()
