"""Run one historical Contracts route in the ignored, isolated Godot copy."""

from __future__ import annotations

import hashlib
import json
import os
from pathlib import Path
import shutil
import subprocess
import sys


HERE = Path(__file__).resolve().parent
PROJECT = HERE / "project"
REPO = HERE.parents[4]
SOURCE = REPO / "patch-notes"
GODOT = Path(
    r"C:\Users\64jus\Downloads\Godot_v4.7.1-stable_win64.exe"
    r"\Godot_v4.7.1-stable_win64_console.exe"
)
MANIFEST = json.loads((HERE / "SOURCE-MANIFEST.json").read_text(encoding="utf-8-sig"))


def sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest().upper()


def check_source() -> None:
    changed = [
        item["path"]
        for item in MANIFEST["files"]
        if sha256(SOURCE / item["path"]) != item["source_sha256"]
    ]
    if changed:
        raise RuntimeError(f"Original source changed since snapshot: {changed[:8]}")


def run(name: str, arguments: list[str], timeout: int) -> dict:
    profile = HERE / "profile"
    app_data = profile / "APPDATA"
    local_app_data = profile / "LOCALAPPDATA"
    app_data.mkdir(parents=True, exist_ok=True)
    local_app_data.mkdir(parents=True, exist_ok=True)
    environment = os.environ.copy()
    environment["APPDATA"] = str(app_data)
    environment["LOCALAPPDATA"] = str(local_app_data)
    command = [str(GODOT), "--headless", "--path", str(PROJECT), *arguments]
    try:
        result = subprocess.run(
            command,
            cwd=PROJECT,
            env=environment,
            capture_output=True,
            timeout=timeout,
            check=False,
        )
        exit_code: int | str = result.returncode
        output = result.stdout + result.stderr
    except subprocess.TimeoutExpired as error:
        exit_code = "timeout"
        output = (error.stdout or b"") + (error.stderr or b"")
    (HERE / f"{name}.log").write_bytes(output)
    record = {"command": command, "exit": exit_code, "log": f"{name}.log"}
    (HERE / f"{name}.command.json").write_text(
        json.dumps(record, indent=2), encoding="utf-8"
    )
    print(json.dumps(record), flush=True)
    return record


def main() -> int:
    startup_mode = sys.argv[1] if len(sys.argv) > 1 else "trait"
    if startup_mode not in {"trait", "legacy"}:
        raise ValueError(f"unsupported startup mode: {startup_mode}")
    check_source()
    imported = run(f"isolated-import-{startup_mode}", ["--editor", "--import"], 120)
    if imported["exit"] != 0:
        return 1
    check_source()
    replay = run(
        f"{startup_mode}-strong-probe",
        ["--script", "res://analysis/task32_strong_probe_v1.gd", "--", f"--startup={startup_mode}"],
        180,
    )
    source_output = PROJECT / f"task34-{startup_mode}-strong-probe.json"
    if source_output.exists():
        shutil.copy2(source_output, HERE / f"{startup_mode}-strong-probe.json")
    check_source()
    return 0 if replay["exit"] == 0 and source_output.exists() else 1


if __name__ == "__main__":
    sys.exit(main())
